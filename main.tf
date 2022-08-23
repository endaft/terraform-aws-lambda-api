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

data "external" "lambda_hash" {
  program = ["curl -s -H \"Accept: application/vnd.github+json\" https://api.github.com/repos/endaft/aws-cloudfront-gateway/contents/dist | jq '.[0] | { sha: .sha }'"]
}

resource "null_resource" "cloudfront_lambda_zip" {
  count = local.web_apps_count > 1 ? 1 : 0

  triggers = {
    lambda_hash = data.external.lambda_hash
  }

  provisioner "local-exec" {
    command = "curl -LJO https://github.com/endaft/aws-cloudfront-gateway/raw/dev/dist/lambda-gateway.zip"
  }

  depends_on = [
    data.external.lambda_hash
  ]
}
