#################################################
# Main Definitions and Settings
#################################################

terraform {
  backend "s3" {
    encrypt = true
    region  = "us-east-1"
    bucket  = "gio-infrastructure"
    key     = "sites/my-great.app/terraform.tfstate"
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

provider "aws" {
  region = local.region

  default_tags {
    tags = local.default_tags
  }
}
