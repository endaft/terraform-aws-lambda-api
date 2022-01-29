# terraform-aws-lambda-api

The `terraform-aws-lambda-api` is an AWS Lambda API Gateway module used by endaft for Terraform deployments.

## Variables

The variables are as strongly-typed as permitted by Terraform. You shouldn't need to worry about them beyond ensuring your IAC setup passes them all thru to the module. The actual values are generated into a `.tfvars` file by the `endaft` CLI.

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| env | `string` | `"dev"` | The deployment environment or stage. Use `"production"` to eliminate environment prefixes and set the API Gateway Stage to production. |
| tags | `map(string)` | `{}` | The default tgs to assign the created resources. |
| app_name | `string` |  | The app name |
| app_domain | `string` |  | The app domain name |
| log_retention_days | `number` | `14` | The number of days to retain log files. |
| local_dev_endpoint | `string` | `"http://localhost:19006"` | The local development server endpoint, like http://localhost:19006. Used for CORS access. |
| cognito_logo_path | `string` |  | The path to a logo file for Cognito. Ideally, 350px wide. MUST not exceed 100kb. |
| cognito_css_path | `string` |  | The path to a CSS file for Cognito. See schema comments for help. |
| request_params | `map(string)` | `{}` | The request parameter mapping for the lambda integration. |
| identity_providers | `list(object(...))` | `[]` | The user pool identity providers to be connected. |
| token_validity | `object(...)` | `id_token: 30 days`, `access_token: 1 hour`, `refresh_token: 1 hour` | The token validity durations used by the user pool. |
| password_rules | `object(...)` | `minimum_length = 10`, `require_lowercase = true`, `require_numbers = true`, `require_symbols = true`, `require_uppercase = true` | The password complexity rules used by the user pool during sign up. |
| lambda_configs | `map(object(...))` |  | A map of name-keyed maps of lambda configurations. |

```hcl
#################################################
# Input Configuration Values
#################################################

variable "env" {
  type        = string
  default     = "dev"
  description = "The deployment environment or stage. Use 'production' to eliminate environment prefixes and set the API Gateway Stage to production."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "The default tgs to assign the created resources."
}

variable "app_name" {
  type        = string
  description = "The app name"
}

variable "app_domain" {
  type        = string
  description = "The app domain name"
}

variable "log_retention_days" {
  type        = number
  default     = 14
  description = "The number of days to retain log files. Default: 14"
}

variable "local_dev_endpoint" {
  type        = string
  default     = "http://localhost:19006"
  description = "The local development server endpoint, like http://localhost:19006. Defaults to: http://localhost:19006"
}

variable "cognito_logo_path" {
  type        = string
  description = "The path to a logo file for Cognito. Ideally, 350px wide. MUST not exceed 100kb."
}

variable "cognito_css_path" {
  type        = string
  description = "The path to a CSS file for Cognito. See schema comments for help."
}

variable "request_params" {
  type        = map(string)
  default     = {}
  description = "The request parameter mapping for the lambda integration."
}

variable "identity_providers" {
  type = list(object({
    name    = string
    type    = string
    mapping = map(string)
    details = map(string)
  }))
  default     = []
  description = "The user pool identity providers to be connected."
}

variable "token_validity" {
  type = object({
    id_token = object({
      duration = number
      units    = string
    })
    access_token = object({
      duration = number
      units    = string
    })
    refresh_token = object({
      duration = number
      units    = string
    })
  })
  default = {
    id_token = {
      duration = 30
      units    = "days"
    }
    access_token = {
      duration = 1
      units    = "hours"
    }
    refresh_token = {
      duration = 1
      units    = "hours"
    }
  }
  description = "The password complexity rules used by the user pool."
}

variable "password_rules" {
  type = object({
    minimum_length    = number
    require_numbers   = bool
    require_symbols   = bool
    require_lowercase = bool
    require_uppercase = bool
  })
  default = {
    minimum_length    = 10
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
    require_uppercase = true
  }
  description = "The password complexity rules used by the user pool."
}

variable "lambda_configs" {
  type = map(object({
    runtime     = string,
    memory      = number,
    timeout     = number,
    file        = string,
    handler     = string,
    description = string,
    anonymous   = bool,
    environment = map(string),
    routes = set(object({
      method = string,
      path   = string
    }))
  }))
  description = "A map of name-keyed map of lambda configurations."
}
```
