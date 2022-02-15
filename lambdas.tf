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
  function_name    = "${local.env_prefix}${each.key}"
  source_code_hash = filebase64sha256(each.value.file)

  dynamic "environment" {
    for_each = (each.value.environment == null ? [] : [each.value.environment])
    content {
      variables = { for k, v in each.value.environment : k => contains(local.token_keys, v) ? coalesce(local.token_map[v], v) : v }
    }
  }

  role    = aws_iam_role.lambda_exec_role.arn
  publish = true

  depends_on = [
    aws_cloudwatch_log_group.lambda_logs
  ]
}
