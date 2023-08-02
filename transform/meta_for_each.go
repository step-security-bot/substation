package transform

import (
	"context"
	gojson "encoding/json"
	"fmt"

	"github.com/brexhq/substation/config"
	"github.com/brexhq/substation/internal/errors"
	"github.com/brexhq/substation/internal/json"
	mess "github.com/brexhq/substation/message"
)

type metaForEachConfig struct {
	// Key retrieves a value from an object for processing.
	//
	// This is optional for transforms that support processing non-object data.
	Key string `json:"key"`
	// SetKey inserts a processed value into an object.
	//
	// This is optional for transforms that support processing non-object data.
	SetKey string `json:"set_key"`
	// Transform is the transform that is applied to each item in the array.
	Transform config.Config `json:"transform"`
}

type metaForEach struct {
	conf metaForEachConfig

	transform    Transformer
	transformCfg config.Config
}

func newMetaForEach(ctx context.Context, cfg config.Config) (*metaForEach, error) {
	conf := metaForEachConfig{}
	if err := config.Decode(cfg.Settings, &conf); err != nil {
		return nil, err
	}

	// Validate required options.
	if conf.Key == "" || conf.SetKey == "" {
		return nil, fmt.Errorf("transform: meta_for_each: key %s set_key %s: %v", conf.Key, conf.SetKey, errInvalidDataPattern)
	}

	if conf.Transform.Type == "" {
		return nil, fmt.Errorf("transform: meta_for_each: type: %v", errors.ErrMissingRequiredOption)
	}

	tformConf, err := gojson.Marshal(conf.Transform)
	if err != nil {
		return nil, err
	}

	inputKey := conf.Transform.Type
	if innerKey, ok := conf.Transform.Settings["key"].(string); ok && innerKey != "" {
		inputKey = conf.Transform.Type + "." + innerKey
	}
	tformConf, _ = json.Set(tformConf, "settings.key", inputKey)

	outputKey := conf.Transform.Type
	if innerKey, ok := conf.Transform.Settings["set_key"].(string); ok && innerKey != "" {
		outputKey = conf.Transform.Type + "." + innerKey
	}
	tformConf, _ = json.Set(tformConf, "settings.set_key", outputKey)

	meta := metaForEach{
		conf: conf,
	}

	if err := gojson.Unmarshal(tformConf, &meta.transformCfg); err != nil {
		return nil, err
	}

	t, err := NewTransformer(ctx, meta.transformCfg)
	if err != nil {
		return nil, fmt.Errorf("process: for_each: %v", err)
	}
	meta.transform = t

	return &meta, nil
}

func (t *metaForEach) String() string {
	b, _ := gojson.Marshal(t.conf)
	return string(b)
}

func (*metaForEach) Close(context.Context) error {
	return nil
}

func (t *metaForEach) Transform(ctx context.Context, messages ...*mess.Message) ([]*mess.Message, error) {
	var output []*mess.Message

	for _, message := range messages {
		// Skip control messages.
		if message.IsControl() {
			output = append(output, message)
			continue
		}

		result := message.Get(t.conf.Key)
		if !result.IsArray() {
			output = append(output, message)
			continue
		}

		for _, res := range result.Array() {
			msg, err := mess.New()
			if err != nil {
				return nil, fmt.Errorf("transform: meta_for_each: %v", err)
			}

			if err := msg.Set(t.transformCfg.Type, res); err != nil {
				return nil, fmt.Errorf("transform: meta_for_each: %v", err)
			}

			msgs, err := t.transform.Transform(ctx, msg)
			if err != nil {
				return nil, fmt.Errorf("transform: meta_for_each: %v", err)
			}

			for _, m := range msgs {
				v := m.Get(t.transformCfg.Type)
				if err := message.Set(t.conf.SetKey, v); err != nil {
					return nil, fmt.Errorf("transform: meta_for_each: %v", err)
				}
			}
		}

		output = append(output, message)
	}

	return output, nil
}
