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

data "external" "cloudfront_lambda_zip" {
  program     = ["bash", "lambda.sh"]
  working_dir = path.module
}
