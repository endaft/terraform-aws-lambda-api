#################################################
# Available Output Values
#################################################

output "lambda_exec_role_arn" {
  value = aws_iam_role.lambda_exec_role.arn
  description = "The Lambda Execution Role ARN. Useful for granting additional permission like data access."
}

output "lambda_exec_role_id" {
  value = aws_iam_role.lambda_exec_role.id
  description = "The Lambda Execution Role ID (role name). Useful for granting additional permission like data access."
}
