resource "aws_dynamodb_table" "table" {
  name           = var.config.name
  billing_mode   = "PROVISIONED"
  read_capacity  = var.config.read_capacity.min
  write_capacity = var.config.write_capacity.min
  hash_key       = var.config.hash_key
  range_key      = var.config.range_key

  # Services can opt in to use TTL functionality at runtime:
  # https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/TTL.html.
  ttl {
    attribute_name = "TTL"
    enabled        = true
  }
  point_in_time_recovery {
    enabled = true
  }
  server_side_encryption {
    enabled     = true
    kms_key_arn = var.kms.arn
  }
  lifecycle {
    ignore_changes = [read_capacity, write_capacity]
  }

  # Streams are only charged for read operations and reads from AWS Lambda are free:
  # https://aws.amazon.com/dynamodb/pricing/.
  stream_enabled   = true
  stream_view_type = var.config.stream_view_type

  dynamic "attribute" {
    for_each = var.config.attributes

    content {
      name = attribute.value.name
      type = attribute.value.type
    }
  }

  tags = var.tags
}

# Applies the policy to each role in the access list.
resource "aws_iam_role_policy_attachment" "access" {
  count      = length(var.access)
  role       = var.access[count.index]
  policy_arn = aws_iam_policy.access.arn
}

resource "aws_iam_policy" "access" {
  name        = "sub-dynamodb-${var.config.name}"
  description = "Policy for the ${var.config.name} DynamoDB table."
  policy      = data.aws_iam_policy_document.access.json
}

data "aws_iam_policy_document" "access" {
  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey"
    ]

    resources = [
      var.kms.arn,
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      # Read actions
      "dynamodb:GetItem",
      "dynamodb:Query",
      # Write actions
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
    ]

    resources = [
      aws_dynamodb_table.table.arn,
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      # Read actions
      "dynamodb:DescribeStream",
      "dynamodb:GetRecords",
      "dynamodb:GetShardIterator",
      "dynamodb:ListStreams",
    ]

    resources = [
      aws_dynamodb_table.table.stream_arn,
    ]
  }
}

# read autoscaling
resource "aws_appautoscaling_target" "read_target" {
  max_capacity       = var.config.read_capacity.max != null ? var.config.read_capacity.max : 1000
  min_capacity       = var.config.read_capacity.min != null ? var.config.read_capacity.min : 5
  resource_id        = "table/${aws_dynamodb_table.table.name}"
  scalable_dimension = "dynamodb:table:ReadCapacityUnits"
  service_namespace  = "dynamodb"
}

resource "aws_appautoscaling_policy" "read_policy" {
  name               = "DynamoDBReadCapacityUtilization:${aws_appautoscaling_target.read_target.resource_id}"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.read_target.resource_id
  scalable_dimension = aws_appautoscaling_target.read_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.read_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBReadCapacityUtilization"
    }

    target_value = var.config.read_capacity.target != null ? var.config.read_capacity.target : 70
  }
}

# write autoscaling
resource "aws_appautoscaling_target" "write_target" {
  max_capacity       = var.config.write_capacity.max != null ? var.config.write_capacity.max : 1000
  min_capacity       = var.config.write_capacity.min != null ? var.config.write_capacity.min : 5
  resource_id        = "table/${aws_dynamodb_table.table.name}"
  scalable_dimension = "dynamodb:table:WriteCapacityUnits"
  service_namespace  = "dynamodb"
}

resource "aws_appautoscaling_policy" "write_policy" {
  name               = "DynamoDBWriteCapacityUtilization:${aws_appautoscaling_target.write_target.resource_id}"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.write_target.resource_id
  scalable_dimension = aws_appautoscaling_target.write_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.write_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBWriteCapacityUtilization"
    }

    target_value = var.config.write_capacity.target != null ? var.config.write_capacity.target : 70
  }
}
