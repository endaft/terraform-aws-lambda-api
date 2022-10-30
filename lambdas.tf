#################################################
# AWS Lambda - Basic Function Template
#################################################

resource "aws_lambda_function" "handler" {
  for_each = var.lambda_configs

  runtime          = each.value.runtime
  description      = each.value.description
  memory_size      = each.value.memory
  timeout          = each.value.timeout
  filename         = each.value.file
  handler          = each.value.handler
  architectures    = [each.value.architecture]
  function_name    = "${local.app_slug}-${local.env_prefix}${each.key}"
  source_code_hash = filebase64sha256(each.value.file)

  role    = aws_iam_role.lambda_exec_role.arn
  publish = true

  depends_on = [
    aws_cloudwatch_log_group.lambda_logs
  ]
}

resource "aws_lambda_function" "cloudfront" {
  count = local.web_apps_count > 1 ? 1 : 0

  runtime          = "nodejs16.x"
  description      = "The CloudFront subdomain routing lambda."
  memory_size      = "128"
  timeout          = 30
  filename         = "lambda-gateway.zip"
  handler          = "index.handler"
  function_name    = local.lambdas_cloudfront_name
  source_code_hash = length(data.external.cloudfront_lambda_zip.result) > 0 ? filebase64sha256("${path.module}/lambda-gateway.zip") : "" # This make the update depend on the downloaded file hash

  role    = aws_iam_role.lambda_exec_role.arn
  publish = true
}
