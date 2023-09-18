# var.map[*] is a convenience function for handling empty maps.
locals {
  env = var.config.env[*]
}

resource "aws_lambda_function" "lambda_function" {
  function_name = var.config.name
  description   = var.config.description

  # Runtime settings.
  role        = aws_iam_role.role.arn
  kms_key_arn = var.kms.arn
  timeout     = var.config.timeout
  memory_size = var.config.memory

  # Architecture settings.
  package_type  = "Image" # Only container images are supported.
  image_uri     = var.config.image_uri
  architectures = var.config.image_arm ? ["arm64"] : ["x86_64"]


  # Network settings.
  vpc_config {
    subnet_ids         = var.config.vpc_config.subnet_ids
    security_group_ids = var.config.vpc_config.security_group_ids
  }

  # Tracing settings.
  tracing_config {
    mode = "Active"
  }

  # Environment settings.
  # Required for avoiding errors due to missing environment variables.
  dynamic "environment" {
    for_each = local.env
    content {
      variables = environment.value
    }
  }

  tags = var.tags
}

resource "aws_iam_role" "role" {
  name               = var.config.name
  assume_role_policy = data.aws_iam_policy_document.service_policy_document.json

  tags = var.tags
}

data "aws_iam_policy_document" "service_policy_document" {
  statement {
    sid    = "AssumeRole"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_appconfig_configuration_profile" "config" {
  application_id = var.appconfig.id
  description    = "Configuration profile for the ${var.config.name} Lambda"
  name           = var.config.name
  location_uri   = "hosted"

  tags = var.tags
}

# Optional secrets creation.
resource "aws_secretsmanager_secret" "secret" {
  count      = var.config.secret ? 1 : 0
  name       = var.config.name
  kms_key_id = var.kms.id
  tags       = var.tags
}

################################################
# Default Policies
################################################

resource "aws_iam_role_policy_attachment" "lambda_basic_execution_role" {
  role       = aws_iam_role.role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_vpc_access_execution_role" {
  role       = aws_iam_role.role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}


resource "aws_iam_role_policy_attachment" "xray_write_only_access" {
  role       = aws_iam_role.role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXrayWriteOnlyAccess"
}

################################################
# Custom Policies
################################################

resource "aws_iam_role_policy_attachment" "custom_policy_attachment" {
  role       = aws_iam_role.role.name
  policy_arn = aws_iam_policy.custom_policy.arn
}

resource "aws_iam_policy" "custom_policy" {
  name        = var.config.name
  description = "Policy for the ${var.config.name} Lambda."
  policy      = data.aws_iam_policy_document.custom_policy_document.json
}

data "aws_iam_policy_document" "custom_policy_document" {
  statement {
    sid = "AppConfig"

    effect = "Allow"
    actions = [
      "appconfig:GetConfiguration",
      "appconfig:GetLatestConfiguration",
      "appconfig:StartConfigurationSession",
    ]

    resources = [
      "${var.appconfig.arn}/*"
    ]
  }

  statement {
    sid = "KMS"

    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey"
    ]

    // Access the KMS key.
    resources = [
      var.kms.arn,
    ]
  }

  // Add additional statements provided as a variable.
  dynamic "statement" {
    for_each = var.config.iam_statements
    content {
      effect    = "Allow"
      actions   = statement.value.actions
      resources = statement.value.resources
    }
  }
}

################################################
# Access Policies
################################################

resource "aws_iam_role_policy_attachment" "access" {
  for_each   = toset(var.access)
  role       = each.value
  policy_arn = aws_iam_policy.access.arn
}

resource "aws_iam_policy" "access" {
  name        = "sub-lambda-${var.config.name}"
  description = "Policy for the ${var.config.name} Lambda."
  policy      = data.aws_iam_policy_document.access.json
}

data "aws_iam_policy_document" "access" {
  statement {
    sid = "KMS"

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
    sid = "Lambda"

    effect = "Allow"
    actions = [
      "lambda:InvokeAsync",
      "lambda:InvokeFunction",
    ]

    resources = [
      aws_lambda_function.lambda_function.arn,
    ]
  }
}
