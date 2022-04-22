#################################################
# AWS CloudWatch - Logging
#################################################

resource "aws_cloudwatch_log_group" "lambda_logs" {
  for_each = var.lambda_configs

  name              = "/aws/lambda/${local.env_prefix}${each.key}"
  retention_in_days = var.log_retention_days
}

resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "/aws/api_gw/${aws_apigatewayv2_api.app.name}"
  retention_in_days = var.log_retention_days
}

resource "aws_cloudwatch_log_group" "cf_lambda_logs" {
  count = local.web_apps_count > 1 ? 1 : 0

  name              = "/aws/lambda/${aws_lambda_function.cloudfront[0].function_name}"
  retention_in_days = var.log_retention_days
}
