#################################################
# AWS IAM - Roles and Policies
#################################################

resource "aws_iam_role" "lambda_exec_role" {
  name               = local.roles.lambda_exec
  assume_role_policy = data.aws_iam_policy_document.lambda_arp_doc.json
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AWSLambdaExecute",
  ]
}

resource "aws_iam_role_policy" "billing_policy" {
  name_prefix = local.roles.billing_access
  role        = aws_iam_role.lambda_exec_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "budget:*",
          "ce:*",
          "cur:*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

data "aws_iam_policy_document" "lambda_arp_doc" {
  version = "2012-10-17"

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com", "edgelambda.amazonaws.com"]
    }
  }
}
