#################################################
# Route53 - DNS Settings
#################################################

data "aws_route53_zone" "public" {
  name = local.app_domain_root
}

resource "aws_route53_record" "sub" {
  count = local.use_subdom ? 1 : 0

  type    = "A"
  zone_id = data.aws_route53_zone.public.zone_id
  name    = local.app_domain

  alias {
    zone_id                = aws_cloudfront_distribution.app.hosted_zone_id
    name                   = aws_cloudfront_distribution.app.domain_name
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "root" {
  count = local.use_subdom ? 0 : 1

  type    = "A"
  zone_id = data.aws_route53_zone.public.zone_id
  name    = local.app_domain

  alias {
    zone_id                = aws_cloudfront_distribution.app.hosted_zone_id
    name                   = aws_cloudfront_distribution.app.domain_name
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "web_apps" {
  for_each = local.web_apps

  type    = "A"
  zone_id = data.aws_route53_zone.public.zone_id
  name    = "${each.key}.${local.app_domain}"

  alias {
    zone_id                = aws_cloudfront_distribution.app.hosted_zone_id
    name                   = aws_cloudfront_distribution.app.domain_name
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "auth" {
  count = local.is_anon ? 0 : 1

  type    = "A"
  zone_id = data.aws_route53_zone.public.zone_id
  name    = aws_cognito_user_pool_domain.app[0].domain

  alias {
    zone_id                = "Z2FDTNDATAQYW2" # This zone_id is static for Cognito
    name                   = aws_cognito_user_pool_domain.app[0].cloudfront_distribution_arn
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "api" {
  type    = "A"
  zone_id = data.aws_route53_zone.public.zone_id
  name    = aws_apigatewayv2_domain_name.app.domain_name

  alias {
    zone_id                = aws_apigatewayv2_domain_name.app.domain_name_configuration[0].hosted_zone_id
    name                   = aws_apigatewayv2_domain_name.app.domain_name_configuration[0].target_domain_name
    evaluate_target_health = false
  }
}
