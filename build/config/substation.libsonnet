{
  // Mirrors interfaces from the condition package.
  condition: {
    // Operators.
    all(i): { operator: 'all', inspectors: $.helpers.make_array(i) },
    any(i): { operator: 'any', inspectors: $.helpers.make_array(i) },
    none(i): { operator: 'none', inspectors: $.helpers.make_array(i) },
    // Inspectors.
    format: {
      content(settings=null): {
        local default = $.config.object { type: null },

        type: 'format_content',
        settings: std.mergePatch(default, settings),
      },
      json(settings=null): {
        type: 'format_json',
      },
    },
    logic: {
      len: {
        equal_to(settings=null): {
          local default = $.confg.object { length: null, measurement: 'byte' },

          type: 'logic_len_equal_to',
          settings: std.mergePatch(default, settings),
        },
        greater_than(settings=null): {
          local default = $.confg.object { length: null, measurement: 'byte' },

          type: 'logic_len_greater_than',
          settings: std.mergePatch(default, settings),
        },
        less_than(settings=null): {
          local default = $.confg.object { length: null, measurement: 'byte' },

          type: 'logic_len_less_than',
          settings: std.mergePatch(default, settings),
        },
      },
    },
    meta: {
      condition(settings=null): {
        local default = { condition: null },

        type: 'meta_condition',
        settings: std.mergePatch(default, settings),
      },
      for_each(settings=null): {
        local default = $.confg.object { type: null, inspector: null },

        type: 'meta_for_each',
        settings: std.mergePatch(default, settings),
      },
      negate(settings=null): {
        local default = { inspector: null },

        type: 'meta_negate',
        settings: std.mergePatch(default, settings),
      },
    },
    network: {
      ip: {
        valid(settings=null): {
          local default = $.config.object,

          type: 'network_ip_valid',
          settings: std.mergePatch(default, settings),
        },
        private(settings=null): {
          local default = $.config.object,

          type: 'network_ip_private',
          settings: std.mergePatch(default, settings),
        },
        public(settings=null): {
          local default = $.config.object,

          type: 'network_ip_public',
          settings: std.mergePatch(default, settings),
        },
      },
    },
    string: {
      contains(settings=null): {
        local default = $.config.object { string: null },

        type: 'string_contains',
        settings: std.mergePatch(default, settings),
      },
      equal_to(settings=null): {
        local default = $.config.object { string: null },

        type: 'string_equal_to',
        settings: std.mergePatch(default, settings),
      },
      starts_with(settings=null): {
        local default = $.config.object { string: null },

        type: 'string_starts_with',
        settings: std.mergePatch(default, settings),
      },
      ends_with(settings=null): {
        local default = $.config.object { string: null },

        type: 'string_ends_with',
        settings: std.mergePatch(default, settings),
      },
      pattern(settings=null): {
        local default = $.config.object { pattern: null },

        type: 'string_pattern',
        settings: std.mergePatch(default, settings),
      },
    },
    utility: {
      random(settings=null): {
        type: 'utility_random',
      },
    },
  },
  // Mirrors interfaces from the transform package.
  transform: {
    aggregate: {
      from: {
        array(settings=null): {
          local default = $.config.object + $.config.buffer,

          type: 'aggregate_from_array',
          settings: std.mergePatch(default, settings),
        },
        str(settings=null): {
          local default = $.config.buffer { separator: null },

          type: 'aggregate_from_str',
          settings: std.mergePatch(default, settings),
        },
      },
      to: {
        array(settings=null): {
          local default = $.config.object + $.config.buffer,

          type: 'aggregate_to_array',
          settings: std.mergePatch(default, settings),
        },
        str(settings=null): {
          local default = $.config.buffer { separator: null },

          type: 'aggregate_to_str',
          settings: std.mergePatch(default, settings),
        },
      },
    },
    array: {
      group(settings=null): {
        local default = $.config.object { group_keys: null },

        type: 'array_group',
        settings: std.mergePatch(default, settings),
      },
      join(settings=null): {
        local default = $.config.object { separator: null },

        type: 'array_join',
        settings: std.mergePatch(default, settings),
      },
    },
    compress: {
      from_gzip(settings=null): {
        type: 'compress_from_gzip',
      },
      to_gzip(settings=null): {
        type: 'compress_to_gzip',
      },
    },
    enrich: {
      aws: {
        dynamodb(settings=null): {
          local default = $.config.object + $.config.aws + $.config.retry { table: null, partition_key: null, sort_key: null, key_condition_expression: null, limit: 1, scan_index_forward: false },

          type: 'enrich_aws_dynamodb',
          settings: std.mergePatch(default, settings),
        },
        lambda(settings=null): {
          local default = $.config.object + $.config.aws + $.config.retry { function_name: null },

          type: 'enrich_aws_lambda',
          settings: std.mergePatch(default, settings),
        },
      },
      dns: {
        domain_lookup(settings=null): {
          local default = $.config.object + $.config.request { type: null },

          type: 'enrich_dns_domain_lookup',
          settings: std.mergePatch(default, settings),
        },
        ip_lookup(settings=null): {
          local default = $.config.object + $.config.request { type: null },

          type: 'enrich_dns_ip_lookup',
          settings: std.mergePatch(default, settings),
        },
        txt_lookup(settings=null): {
          local default = $.config.object + $.config.request { type: null },

          type: 'enrich_dns_txt_lookup',
          settings: std.mergePatch(default, settings),
        },
      },
      http: {
        get(settings=null): {
          local default = $.config.object + $.config.request { url: null, headers: null },

          type: 'enrich_http_get',
          settings: std.mergePatch(default, settings),
        },
        post(settings=null): {
          local default = $.config.object + $.config.request { url: null, headers: null, body_key: null },

          type: 'enrich_http_post',
          settings: std.mergePatch(default, settings),
        },
      },
      kv_store: {
        get(settings=null): {
          local default = $.config.object { prefix: null, kv_store: null, close_kv_store: false },

          type: 'enrich_kv_store_get',
          settings: std.mergePatch(default, settings),
        },
        set(settings=null): {
          local default = $.config.object { prefix: null, ttl_key: null, ttl_offset: null, kv_store: null, close_kv_store: false },

          type: 'enrich_kv_store_set',
          settings: std.mergePatch(default, settings),
        },
      },
    },
    external: {
      jq(settings=null): {
        local default = { query: null },

        type: 'external_jq',
        settings: std.mergePatch(default, settings),
      },
    },
    format: {
      from_base64(settings=null): {
        local default = $.config.object,

        type: 'format_from_base64',
        settings: std.mergePatch(default, settings),
      },
      from_pretty_print(settings=null): {
        type: 'format_from_pretty_print',
      },
      to_base64(settings=null): {
        local default = $.config.object,

        type: 'format_to_base64',
        settings: std.mergePatch(default, settings),
      },
    },
    hash: {
      md5(settings=null): {
        local default = $.config.object,

        type: 'hash_md5',
        settings: std.mergePatch(default, settings),
      },
      sha256(settings=null): {
        local default = $.config.object,

        type: 'hash_sha256',
        settings: std.mergePatch(default, settings),
      },
    },
    logic: {
      num: {
        add(settings=null): {
          local default = $.config.object,

          type: 'logic_num_add',
          settings: std.mergePatch(default, settings),
        },
      },
      subtract(settings=null): {
        local default = $.config.object,

        type: 'logic_num_subtract',
        settings: std.mergePatch(default, settings),
      },
      multiply(settings=null): {
        local default = $.config.object,

        type: 'logic_num_multiply',
        settings: std.mergePatch(default, settings),
      },
      divide(settings=null): {
        local default = $.config.object,

        type: 'logic_num_divide',
        settings: std.mergePatch(default, settings),
      },
    },
    meta: {
      for_each(settings=null): {
        local default = $.transform.object { transform: null },

        type: 'meta_for_each',
        settings: std.mergePatch(default, settings),
      },
      pipeline(settings=null): {
        local default = $.transform.object { transforms: null },

        type: 'meta_pipeline',
        settings: std.mergePatch(default, settings),
      },
      switch(settings=null): {
        local default = { switch: null },

        type: 'meta_switch',
        settings: settings,
      },
    },
    network: {
      domain: {
        registered_domain(settings=null): {
          local default = $.config.object,

          type: 'network_domain_registered_domain',
          settings: std.mergePatch(default, settings),
        },
        subdomain(settings=null): {
          local default = $.config.object,

          type: 'network_domain_subdomain',
          settings: std.mergePatch(default, settings),
        },
        top_level_domain(settings=null): {
          local default = $.config.object,

          type: 'network_domain_top_level_domain',
          settings: std.mergePatch(default, settings),
        },
      },
    },
    object: {
      copy(settings=null): {
        local default = $.config.object,

        type: 'object_copy',
        settings: std.mergePatch(default, settings),
      },
      delete(settings=null): {
        local default = $.config.object,

        type: 'object_delete',
        settings: std.mergePatch(default, settings),
      },
      insert(settings=null): {
        local default = $.config.object { value: null },

        type: 'object_insert',
        settings: std.mergePatch(default, settings),
      },
      to: {
        bool(settings=null): {
          local default = $.config.object,

          type: 'object_to_bool',
          settings: std.mergePatch(default, settings),
        },
        float(settings=null): {
          local default = $.config.object,

          type: 'object_to_float',
          settings: std.mergePatch(default, settings),
        },
        int(settings=null): {
          local default = $.config.object,

          type: 'object_to_int',
          settings: std.mergePatch(default, settings),
        },
        str(settings=null): {
          local default = $.config.object,

          type: 'object_to_str',
          settings: std.mergePatch(default, settings),
        },
        uint(settings=null): {
          local default = $.config.object,

          type: 'object_to_uint',
          settings: std.mergePatch(default, settings),
        },
      },
    },
    send: {
      aws: {
        dynamodb(settings=null): {
          local default =
            $.config.aws + $.config.retry { table: null, partition_key: null, sort_key: null, ttl: null },

          type: 'send_aws_dynamodb',
          settings: std.mergePatch(default, settings),
        },
        kinesis_data_firehose(settings=null): {
          local default =
            $.config.aws + $.config.buffer + $.config.retry { stream: null },

          type: 'send_aws_kinesis_data_firehose',
          settings: std.mergePatch(default, settings),
        },
        kinesis_data_stream(settings=null): {
          local default =
            $.config.aws + $.config.buffer + $.config.retry { stream: null, partition: null, partition_key: null, shard_redistribution: false },

          type: 'send_aws_kinesis_data_stream',
          settings: std.mergePatch(default, settings),
        },
        s3(settings=null): {
          local default =
            $.config.aws + $.config.buffer + $.config.retry { bucket: null, file_path: null, file_format: null, file_compression: null },

          type: 'send_aws_s3',
          settings: std.mergePatch(default, settings),
        },
        sns(settings=null): {
          local default =
            $.config.aws + $.config.buffer + $.config.retry { topic: null },

          type: 'send_aws_sns',
          settings: std.mergePatch(default, settings),
        },
        sqs(settings=null): {
          local default =
            $.config.aws + $.config.buffer + $.config.retry { queue: null },

          type: 'send_aws_sqs',
          settings: std.mergePatch(default, settings),
        },
      },
      file(settings=null): {
        local default =
          $.config.buffer
          {
            file_path: $.file_path,
            file_format: { type: 'json' },
            file_compression: { type: 'gzip' },
          },

        type: 'send_file',
        settings: std.mergePatch(default, settings),
      },
      http(settings=null): {
        local default = { url: null, headers: null, headers_key: null },

        type: 'send_http',
        settings: std.mergePatch(default, settings),
      },
      stdout(settings=null): {
        type: 'send_stdout',
      },
      sumologic(settings=null): {
        local default =
          $.config.buffer
          { url: null, category: null, category_key: null },

        type: 'send_sumologic',
        settings: std.mergePatch(default, settings),
      },
    },
    string: {
      pattern: {
        find_all(settings=null): {
          local default = $.config.object { pattern: null },

          type: 'string_pattern_find_all',
          settings: std.mergePatch(default, settings),
        },
        find(settings=null): {
          local default = $.config.object { pattern: null },

          type: 'string_pattern_find',
          settings: std.mergePatch(default, settings),
        },
        named_group(settings=null): {
          local default = $.config.object { pattern: null },

          type: 'string_pattern_named_group',
          settings: std.mergePatch(default, settings),
        },
      },
      replace(settings=null): {
        local default = $.config.object { old: null, new: null, count: -1 },

        type: 'string_replace',
        settings: std.mergePatch(default, settings),
      },
      split(settings=null): {
        local default = $.config.object { separator: null },

        type: 'string_split',
        settings: std.mergePatch(default, settings),
      },
      to: {
        lower(settings=null): {
          type: 'string_to_lower',
        },
        upper(settings=null): {
          type: 'string_to_upper',
        },
        snake(settings=null): {
          type: 'string_to_snake',
        },
      },
    },
    time: {
      from_str(settings=null): {
        local default = $.config.object { format: null, location: null },

        type: 'time_from_str',
        settings: std.mergePatch(default, settings),
      },
      from_unix(settings=null): {
        local default = $.config.object,

        type: 'time_from_unix',
        settings: std.mergePatch(default, settings),
      },
      now(settings=null): {
        local default = $.config.object,

        type: 'time_now',
        settings: std.mergePatch(default, settings),
      },
      to_str(settings=null): {
        local default = $.config.object { format: null, location: null },

        type: 'time_to_str',
        settings: std.mergePatch(default, settings),
      },
      to_unix(settings=null): {
        local default = $.config.object,

        type: 'time_to_unix',
        settings: std.mergePatch(default, settings),
      },
    },
    utility: {
      delay(settings=null): {
        local default = $.config.object { duration: null },

        type: 'util_delay',
        settings: std.mergePatch(default, settings),
      },
      drop(settings=null): {
        type: 'util_drop',
      },
      err(settings=null): {
        local default = $.config.object { message: null },

        type: 'util_error',
        settings: std.mergePatch(default, settings),
      },
    },
  },
  // Mirrors interfaces from the internal/kv_store package.
  kv_store: {
    aws_dynamodb(settings=null): {
      local default = { table: null, attributes: { partition_key: null, sort_key: null, value: null, ttl: null } },

      type: 'aws_dynamodb',
      settings: std.mergePatch(default, settings),
    },
    csv_file(settings=null): {
      local default = { file: null, column: null, delimiter: ',', header: null },

      type: 'csv_file',
      settings: std.mergePatch(default, settings),
    },
    json_file(settings=$.defaults.kv_store.json_file.settings): {
      local default = { file: null, is_lines: false },

      type: 'json_file',
      settings: std.mergePatch(default, settings),
    },
    memory(settings=null): {
      local default = { capacity: 1024 },

      type: 'memory',
      settings: std.mergePatch(default, settings),
    },
    mmdb(settings=null): {
      local default = { file: null },

      type: 'mmdb',
      settings: std.mergePatch(default, settings),
    },
    text_file(settings=null): {
      local default = { file: null },

      type: 'text_file',
      settings: std.mergePatch(default, settings),
    },
  },
  // Mirrors structs from the internal/config package.
  config: {
    aws: { region: null, assume_role: null },
    buffer: { count: 1000, size: 100000, interval: '5m', key: null },
    object: { key: null, set_key: null },
    request: { timeout: '1s' },
    retry: { count: 3 },
  },
  // Mirrors config from the internal/aggregate package.
  aggregate: {
    max_count: 0,
    max_size: 0,
    max_interval: 0,
    key: null,
  },
  // Mirrors config from the internal/file package.
  file_path: {
    prefix: null,
    prefix_key: null,
    time_format: '2006/01/02',
    extension: true,
  },
  helpers: {
    // If the input is not an array, then this returns it as an array.
    make_array(i): if !std.isArray(i) then [i] else i,
    key: {
      // If key is foo and arr is bar, then result is foo.bar.
      // If key is foo and arr is [bar, baz], then result is foo.bar.baz.
      append(key, arr): std.join('.', $.helpers.make_array(key) + $.helpers.make_array(arr)),
      // if key is foo, then result is foo.-1
      append_array(key): key + '.-1',
      // if key is foo and e is 0, then result is foo.0
      get_element(key, e=0): std.join('.', [key, if std.isNumber(e) then std.toString(e) else e]),
    },
  },
  patterns: {
    condition: {
      insp: {
        // Negates any inspector.
        negate(inspector): std.mergePatch(inspector, { settings: { negate: true } }),
        ip: {
          // Checks if an IP address is private.
          //
          // Use with the ANY operator to match private IP addresses.
          // Use with the NONE operator to match public IP addresses.
          private(key=null): [
            $.condition.insp.ip(settings={ key: key, type: 'loopback' }),
            $.condition.insp.ip(settings={ key: key, type: 'multicast' }),
            $.condition.insp.ip(settings={ key: key, type: 'multicast_link_local' }),
            $.condition.insp.ip(settings={ key: key, type: 'private' }),
            $.condition.insp.ip(settings={ key: key, type: 'unicast_link_local' }),
            $.condition.insp.ip(settings={ key: key, type: 'unspecified' }),
          ],
        },
        length: {
          // Checks if data is equal to zero.
          //
          // Use with the ANY / ALL operator to match empty data.
          // Use with the NONE operator to match non-empty data.
          eq_zero(key=null):
            $.condition.insp.length(settings={ key: key, type: 'equals', length: 0 }),
          // checks if data is greater than zero.
          //
          // use with the ANY / ALL operator to match non-empty data.
          // use with the NONE operator to match empty data.
          gt_zero(key=null):
            $.condition.insp.length(settings={ key: key, type: 'greater_than', length: 0 }),
        },
        string: {
          contains(string, key=null):
            $.condition.insp.string(settings={ key: key, type: 'contains', string: string }),
          equals(string, key=null):
            $.condition.insp.string(settings={ key: key, type: 'equals', string: string }),
          starts_with(string, key=null):
            $.condition.insp.string(settings={ key: key, type: 'starts_with', string: string }),
          ends_with(string, key=null):
            $.condition.insp.string(settings={ key: key, type: 'ends_with', string: string }),
        },
      },
    },
    transform: {
      // Conditional applies a transform when a single condition is met.
      conditional(transform, condition): {
        type: 'meta_switch',
        settings: { switch: [{ condition: condition, transform: transform }] },
      },
    },
  },
}
