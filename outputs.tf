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

output "cloudfront_dist_id" {
  value = aws_cloudfront_distribution.app.id
  description = "The CloudFront Distribution ID. Useful for automated invalidations."
}

output "cloudfront_dist_arn" {
  value = aws_cloudfront_distribution.app.arn
  description = "The CloudFront Distribution ARN. Useful for a variety of operations."
}
