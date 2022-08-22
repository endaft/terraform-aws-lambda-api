#################################################
# Main Definitions and Settings
#################################################

provider "aws" {
  region = local.region

  default_tags {
    tags = local.default_tags
  }
}

# Certificates are ALWAYS from "us-east-1"
provider "aws" {
  alias  = "cert_provider"
  region = "us-east-1"

  default_tags {
    tags = local.default_tags
  }
}

resource "null_resource" "cloudfront_lambda_zip" {
  count = local.web_apps_count > 1 ? 1 : 0

  triggers = {
    always_run = "${timestamp()}"
  }

  provisioner "local-exec" {
    command = "curl -LJO https://github.com/endaft/aws-cloudfront-gateway/raw/dev/dist/lambda-gateway.zip"
  }
}
