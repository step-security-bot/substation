module "lambda_sink_dynamodb" {
  source        = "../../../../build/terraform/aws/lambda"
  kms = module.kms
  appconfig = aws_appconfig_application.substation

  config = {
    name = "substation_sink_dynamodb"
    description = "Writes data to DynamoDB"
    image_uri = "${module.ecr_substation.url}:latest"
    architectures = ["arm64"]

    env = {
      "SUBSTATION_CONFIG" : "http://localhost:2772/applications/substation/environments/prod/configurations/substation_sink_dynamodb"
      "SUBSTATION_HANDLER" : "AWS_KINESIS_DATA_STREAM"
      "SUBSTATION_DEBUG" : true
    }
  }

  tags = {
    owner = "example"
  }

  depends_on = [
    aws_appconfig_application.substation,
    module.ecr_autoscaling.url,
  ]
}

resource "aws_lambda_event_source_mapping" "lambda_esm_dynamodb_sink" {
  event_source_arn                   = module.kinesis_processed.arn
  function_name                      = module.lambda_sink_dynamodb.arn
  maximum_batching_window_in_seconds = 30
  batch_size                         = 100
  parallelization_factor             = 1
  starting_position                  = "LATEST"
}
