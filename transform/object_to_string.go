package transform

import (
	"context"
	"encoding/json"
	"fmt"

	"github.com/brexhq/substation/config"
	iconfig "github.com/brexhq/substation/internal/config"
	"github.com/brexhq/substation/internal/errors"
	"github.com/brexhq/substation/message"
)

type objectToStringConfig struct {
	Object iconfig.Object `json:"object"`
}

func (c *objectToStringConfig) Decode(in interface{}) error {
	return iconfig.Decode(in, c)
}

func (c *objectToStringConfig) Validate() error {
	if c.Object.Key == "" && c.Object.SetKey != "" {
		return fmt.Errorf("object_key: %v", errors.ErrMissingRequiredOption)
	}

	if c.Object.Key != "" && c.Object.SetKey == "" {
		return fmt.Errorf("object_set_key: %v", errors.ErrMissingRequiredOption)
	}

	return nil
}

func newObjectToString(_ context.Context, cfg config.Config) (*objectToString, error) {
	conf := objectToStringConfig{}
	if err := conf.Decode(cfg.Settings); err != nil {
		return nil, fmt.Errorf("transform: object_to_string: %v", err)
	}

	tf := objectToString{
		conf: conf,
	}

	return &tf, nil
}

type objectToString struct {
	conf objectToStringConfig
}

func (tf *objectToString) Transform(ctx context.Context, msg *message.Message) ([]*message.Message, error) {
	if msg.IsControl() {
		return []*message.Message{msg}, nil
	}

	value := msg.GetValue(tf.conf.Object.Key)
	if !value.Exists() {
		return []*message.Message{msg}, nil
	}

	if err := msg.SetValue(tf.conf.Object.SetKey, value.String()); err != nil {
		return nil, fmt.Errorf("transform: object_to_string: %v", err)
	}

	return []*message.Message{msg}, nil
}

func (tf *objectToString) String() string {
	b, _ := json.Marshal(tf.conf)
	return string(b)
}
