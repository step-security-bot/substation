// This example samples data by aggregating events into an array, then
// selecting the first event in the array as a sample. The sampling rate
// is 1/N, where N is the count of events in the buffer.
local sub = import '../../../../../../build/config/substation.libsonnet';

{
  concurrency: 1,
  transforms: [
    // Events are aggregated into an array. This example has a sample
    // rate of up to 1/10. By default, the sample rate will be lower if
    // fewer than 10 events are processed by Substation.
    sub.tf.aggregate.to.array(
      settings={ object: { set_key: 'sample' }, buffer: { count: 10 } }
    ),
    // A strict sample rate can be enforced by dropping any events that
    // contain the `sample` key, but do not have a length of 10.
    sub.tf.meta.switch(settings={ switch: [
      {
        condition: sub.cnd.any(sub.cnd.num.len.eq(settings={ object: { key: 'sample' }, length: 10 })),
        transform: sub.tf.object.copy(settings={ object: { key: 'sample.0' } }),
      },
      {
        condition: sub.cnd.any(sub.cnd.num.len.gt(settings={ object: { key: 'sample' }, length: 0 })),
        transform: sub.tf.util.drop(),
      },
    ] }),
    sub.tf.send.stdout(),
  ],
}
