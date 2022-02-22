#################################################
# AWS API Gateway v2 - API Endpoint Integration
#################################################

resource "aws_apigatewayv2_api" "app" {
  name                         = local.api_gateway.name
  description                  = local.api_gateway.description
  protocol_type                = "HTTP"
  disable_execute_api_endpoint = true

  cors_configuration {
    allow_credentials = true
    allow_headers     = ["*"]
    allow_methods     = ["GET", "HEAD", "POST", "OPTIONS", "DELETE"]
    allow_origins = distinct(concat(
      [local.dev_endpoint],                                          // Supports local development
      [for d in local.cert_sans : "https://${replace(d, "*.", "")}"] // Supports all supported domains
    ))
  }
}

resource "aws_apigatewayv2_domain_name" "app" {
  domain_name = local.api_domain

  domain_name_configuration {
    certificate_arn = aws_acm_certificate.app.arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }
}

resource "aws_apigatewayv2_stage" "app" {
  api_id      = aws_apigatewayv2_api.app.id
  name        = local.api_gateway.stage
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway.arn
    format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      protocol                = "$context.protocol"
      httpMethod              = "$context.httpMethod"
      resourcePath            = "$context.resourcePath"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
      }
    )
  }

  lifecycle {
    ignore_changes = [deployment_id]
  }
}

resource "aws_apigatewayv2_api_mapping" "app" {
  stage       = aws_apigatewayv2_stage.app.id
  api_id      = aws_apigatewayv2_api.app.id
  domain_name = aws_apigatewayv2_domain_name.app.id
}

resource "aws_apigatewayv2_integration" "app" {
  for_each           = local.lambda_endpoints
  api_id             = aws_apigatewayv2_api.app.id
  integration_uri    = aws_lambda_function.handler[each.key].invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
  request_parameters = merge(var.request_params, { for k, v in each.value.environment :
    "X-Env-${k}" => contains(local.token_keys, v) ? coalesce(local.token_map[v], v) : v
  })

  depends_on = [
    aws_lambda_function.handler,
    aws_apigatewayv2_api.app
  ]
}

resource "aws_apigatewayv2_authorizer" "app" {
  count            = local.is_anon ? 0 : 1
  api_id           = aws_apigatewayv2_api.app.id
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]
  name             = local.cognito.authorizer_name

  jwt_configuration {
    audience = ["public"]
    issuer   = "https://${aws_cognito_user_pool.app[0].endpoint}"
  }
}

resource "aws_apigatewayv2_route" "app_auth" {
  for_each = local.lambda_routes_auth

  api_id    = aws_apigatewayv2_api.app.id
  route_key = "${each.value.method} ${each.value.path}"
  target    = "integrations/${aws_apigatewayv2_integration.app[each.value.lambda].id}"

  authorizer_id      = aws_apigatewayv2_authorizer.app[0].id
  authorization_type = each.value.auth
}

resource "aws_apigatewayv2_route" "app_anon" {
  for_each = local.lambda_routes_anon

  api_id    = aws_apigatewayv2_api.app.id
  route_key = "${each.value.method} ${each.value.path}"
  target    = "integrations/${aws_apigatewayv2_integration.app[each.value.lambda].id}"
}

resource "aws_lambda_permission" "app" {
  for_each = local.lambda_endpoints

  action        = "lambda:InvokeFunction"
  principal     = "apigateway.amazonaws.com"
  statement_id  = "AllowExecutionFromAPIGateway"
  function_name = aws_lambda_function.handler[each.key].function_name
  source_arn    = "${aws_apigatewayv2_api.app.execution_arn}/*/*"

  depends_on = [
    aws_lambda_function.handler,
    aws_apigatewayv2_api.app
  ]
}
