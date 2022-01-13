#################################################
# Route53 - DNS Settings
#################################################

data "aws_route53_zone" "public" {
  name = local.app_domain_root
}

resource "aws_route53_record" "sub" {
  count = local.use_subdom ? 1 : 0

  type    = "A"
  ttl     = "300"
  zone_id = data.aws_route53_zone.public.zone_id
  name    = local.app_domain
  records = ["10.1.1.1"]

  allow_overwrite = true
}

resource "aws_route53_record" "auth" {
  type    = "A"
  zone_id = data.aws_route53_zone.public.zone_id
  name    = aws_cognito_user_pool_domain.app.domain

  alias {
    zone_id                = "Z2FDTNDATAQYW2" # This zone_id is static for Cognito
    name                   = aws_cognito_user_pool_domain.app.cloudfront_distribution_arn
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "api" {
  type    = "A"
  zone_id = data.aws_route53_zone.public.zone_id
  name    = aws_apigatewayv2_domain_name.app.domain_name

  alias {
    name                   = aws_apigatewayv2_domain_name.app.domain_name_configuration[0].target_domain_name
    zone_id                = aws_apigatewayv2_domain_name.app.domain_name_configuration[0].hosted_zone_id
    evaluate_target_health = false
  }
}
