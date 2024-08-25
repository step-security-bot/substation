package transform

import (
	"context"
	"encoding/json"
	"fmt"
	"strconv"
	"strings"
	"sync"

	"github.com/aws/aws-sdk-go-v2/service/sqs"
	"github.com/aws/aws-sdk-go-v2/service/sqs/types"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/google/uuid"

	"github.com/brexhq/substation/v2/config"
	"github.com/brexhq/substation/v2/message"

	"github.com/brexhq/substation/v2/internal/aggregate"
	iaws "github.com/brexhq/substation/v2/internal/aws"
	iconfig "github.com/brexhq/substation/v2/internal/config"
)

// Records greater than 256 KB in size cannot be
// put into an SQS queue.
const sendSQSMessageSizeLimit = 1024 * 1024 * 256

// errSendSQSMessageSizeLimit is returned when data exceeds the SQS msg
// size limit. If this error occurs, then conditions or transforms
// should be applied to either drop or reduce the size of the data.
var errSendSQSMessageSizeLimit = fmt.Errorf("data exceeded size limit")

type sendAWSSQSConfig struct {
	// AuxTransforms are applied to batched data before it is sent.
	AuxTransforms []config.Config `json:"auxiliary_transforms"`

	ID     string         `json:"id"`
	Object iconfig.Object `json:"object"`
	Batch  iconfig.Batch  `json:"batch"`
	AWS    iconfig.AWS    `json:"aws"`
}

func (c *sendAWSSQSConfig) Decode(in interface{}) error {
	return iconfig.Decode(in, c)
}

func (c *sendAWSSQSConfig) Validate() error {
	if c.AWS.ARN == "" {
		return fmt.Errorf("aws.arn: %v", iconfig.ErrMissingRequiredOption)
	}

	return nil
}

func newSendAWSSQS(ctx context.Context, cfg config.Config) (*sendAWSSQS, error) {
	conf := sendAWSSQSConfig{}
	if err := conf.Decode(cfg.Settings); err != nil {
		return nil, fmt.Errorf("transform send_aws_sqs: %v", err)
	}

	if conf.ID == "" {
		conf.ID = "send_aws_sqs"
	}

	if err := conf.Validate(); err != nil {
		return nil, fmt.Errorf("transform %s: %v", conf.ID, err)
	}

	// arn:aws:sqs:region:account_id:queue_name
	arn := strings.Split(conf.AWS.ARN, ":")
	tf := sendAWSSQS{
		conf: conf,
		queueURL: fmt.Sprintf(
			"https://sqs.%s.amazonaws.com/%s/%s",
			arn[3],
			arn[4],
			arn[5],
		),
	}

	// Setup the AWS client.
	awsCfg, err := iaws.New(ctx, iaws.Config{
		Region:  iaws.ParseRegion(conf.AWS.ARN),
		RoleARN: conf.AWS.AssumeRoleARN,
	})
	if err != nil {
		return nil, fmt.Errorf("transform %s: %v", conf.ID, err)
	}

	tf.client = sqs.NewFromConfig(awsCfg)

	agg, err := aggregate.New(aggregate.Config{
		// SQS limits batch operations to 10 messages.
		Count: 10,
		// SQS limits batch operations to 256 KB.
		Size:     sendSQSMessageSizeLimit,
		Duration: conf.Batch.Duration,
	})
	if err != nil {
		return nil, err
	}
	tf.agg = agg

	if len(conf.AuxTransforms) > 0 {
		tf.tforms = make([]Transformer, len(conf.AuxTransforms))
		for i, c := range conf.AuxTransforms {
			t, err := New(context.Background(), c)
			if err != nil {
				return nil, fmt.Errorf("transform %s: %v", conf.ID, err)
			}

			tf.tforms[i] = t
		}
	}

	return &tf, nil
}

type sendAWSSQS struct {
	conf     sendAWSSQSConfig
	queueURL string
	client   *sqs.Client

	mu     sync.Mutex
	agg    *aggregate.Aggregate
	tforms []Transformer
}

func (tf *sendAWSSQS) Transform(ctx context.Context, msg *message.Message) ([]*message.Message, error) {
	tf.mu.Lock()
	defer tf.mu.Unlock()

	if msg.IsControl() {
		for key := range tf.agg.GetAll() {
			if tf.agg.Count(key) == 0 {
				continue
			}

			if err := tf.send(ctx, key); err != nil {
				return nil, fmt.Errorf("transform %s: %v", tf.conf.ID, err)
			}
		}

		tf.agg.ResetAll()
		return []*message.Message{msg}, nil
	}

	if len(msg.Data()) > sendSQSMessageSizeLimit {
		return nil, fmt.Errorf("transform %s: %v", tf.conf.ID, errSendSQSMessageSizeLimit)
	}

	// If this value does not exist, then all data is batched together.
	key := msg.GetValue(tf.conf.Object.BatchKey).String()
	if ok := tf.agg.Add(key, msg.Data()); ok {
		return []*message.Message{msg}, nil
	}

	if err := tf.send(ctx, key); err != nil {
		return nil, fmt.Errorf("transform %s: %v", tf.conf.ID, err)
	}

	// If data cannot be added after reset, then the batch is misconfgured.
	tf.agg.Reset(key)
	if ok := tf.agg.Add(key, msg.Data()); !ok {
		return nil, fmt.Errorf("transform %s: %v", tf.conf.ID, errSendBatchMisconfigured)
	}
	return []*message.Message{msg}, nil
}

func (tf *sendAWSSQS) String() string {
	b, _ := json.Marshal(tf.conf)
	return string(b)
}

func (tf *sendAWSSQS) send(ctx context.Context, key string) error {
	data, err := withTransforms(ctx, tf.tforms, tf.agg.Get(key))
	if err != nil {
		return err
	}

	ctx = context.WithoutCancel(ctx)
	return tf.sendMessages(ctx, data)
}

func (tf *sendAWSSQS) sendMessages(ctx context.Context, data [][]byte) error {
	mgid := uuid.New().String()

	entries := make([]types.SendMessageBatchRequestEntry, 0, len(data))
	for idx, d := range data {
		entry := types.SendMessageBatchRequestEntry{
			Id:          aws.String(strconv.Itoa(idx)),
			MessageBody: aws.String(string(d)),
		}

		if strings.HasSuffix(tf.queueURL, ".fifo") {
			entry.MessageGroupId = aws.String(mgid)
		}

		entries = append(entries, entry)
	}

	input := &sqs.SendMessageBatchInput{
		Entries:  entries,
		QueueUrl: aws.String(tf.queueURL),
	}

	resp, err := tf.client.SendMessageBatch(ctx, input)
	if resp.Failed != nil {
		var retry [][]byte
		for _, r := range resp.Failed {
			idx, err := strconv.Atoi(aws.StringValue(r.Id))
			if err != nil {
				return err
			}

			retry = append(retry, data[idx])
		}

		if len(retry) > 0 {
			return tf.sendMessages(ctx, retry)
		}
	}

	if err != nil {
		return err
	}

	return nil
}
