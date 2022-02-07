# terraform-aws-lambda-api

The `terraform-aws-lambda-api` is an AWS Lambda API Gateway module used by endaft for Terraform deployments.

## Variables

The variables are as strongly-typed as permitted by Terraform. You shouldn't need to worry about them beyond ensuring your IAC setup passes them all thru to the module. The actual values are generated into a `.tfvars` file by the `endaft` CLI. For more detailed info, please review the [variables.tf](variables.tf) file.

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| env | `string` | `"dev"` | The deployment environment or stage. Use `"production"` to eliminate environment prefixes and set the API Gateway Stage to production. |
| tags | `map(string)` | `{}` | The default tgs to assign the created resources. |
| app_name | `string` |  | The app name |
| app_domain | `string` |  | The app domain name |
| web_app_path | `string` |  | The local path to the web app deployment files. For a Flutter app called 'app' this might be 'app/build/web'. |
| log_retention_days | `number` | `14` | The number of days to retain log files. |
| local_dev_endpoint | `string` | `"http://localhost:19006"` | The local development server endpoint, like http://localhost:19006. Used for CORS access. |
| cognito_logo_path | `string` |  | The path to a logo file for Cognito. Ideally, 350px wide. MUST not exceed 100kb. |
| cognito_css_path | `string` |  | The path to a CSS file for Cognito. See schema comments for help. |
| request_params | `map(string)` | `{}` | The request parameter mapping for the lambda integration. |
| token_map | `map(string)` | `{}` | The token mapping for the lambda environment variable integration. |
| identity_providers | `list(object(...))` | `[]` | The user pool identity providers to be connected. |
| token_validity | `object(...)` | `id_token: 30 days`,<br />`access_token: 1 hour`,<br />`refresh_token: 1 hour` | The token validity durations used by the user pool. |
| password_rules | `object(...)` | `minimum_length: 10`,<br />`require_lowercase: true`,<br />`require_numbers: true`,<br />`require_symbols: true`,<br />`require_uppercase: true`<br /> | The password complexity rules used by the user pool during sign up. |
| lambda_configs | `map(object(...))` |  | A map of name-keyed maps of lambda configurations. |

## Outputs

These values are output from the deployment for use in deployment customization.

| Name | Type | Description |
| --- | --- | --- |
| lambda_exec_role_arn | `string` | The Lambda Execution Role ARN. Useful for granting additional permission like data access. |
| lambda_exec_role_id | `string` | The Lambda Execution Role ID (role name). Useful for granting additional permission like data access. |
