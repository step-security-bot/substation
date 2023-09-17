################################################
# Lambda
################################################

module "microservice" {
  source = "../../../../build/terraform/aws/lambda"
  # These are always required for all Lambda.
  kms   = module.kms
  appconfig = aws_appconfig_application.substation

  config = {
    name = "microservice"
    description = "Provides a microservice interface to Substation"
    image_uri = "${module.ecr_substation.url}:latest"
    architectures = ["arm64"]
    memory = 128
    timeout     = 10
    env = {
      "SUBSTATION_CONFIG" : "http://localhost:2772/applications/substation/environments/prod/configurations/microservice"
      "SUBSTATION_HANDLER" : "AWS_LAMBDA_SYNC"
      "SUBSTATION_DEBUG" : true
    }
  }

  tags = {
    owner = "example"
  }

  depends_on = [
    aws_appconfig_application.substation,
    module.ecr_substation.url,
  ]
}

resource "aws_lambda_function_url" "substation_microservice" {
  function_name      = module.microservice.name
  authorization_type = "NONE"
}
