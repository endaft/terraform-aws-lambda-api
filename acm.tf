#################################################
# AWS ACM - Wildcard SSL Certificate Settings
#################################################

resource "aws_acm_certificate" "app" {
  domain_name               = local.app_domain
  validation_method         = "DNS"
  subject_alternative_names = local.cert_sans
  provider                  = aws.cert_provider
  lifecycle {
    create_before_destroy = true
    ignore_changes        = [subject_alternative_names]
  }
}

resource "aws_route53_record" "cert_validations" {
  count           = length(local.cert_sans) + 1
  zone_id         = data.aws_route53_zone.public.zone_id
  allow_overwrite = true
  name            = element(aws_acm_certificate.app.domain_validation_options.*.resource_record_name, count.index)
  type            = element(aws_acm_certificate.app.domain_validation_options.*.resource_record_type, count.index)
  records         = [element(aws_acm_certificate.app.domain_validation_options.*.resource_record_value, count.index)]
  ttl             = 300
}

resource "aws_acm_certificate_validation" "cert_validation" {
  certificate_arn         = aws_acm_certificate.app.arn
  validation_record_fqdns = aws_route53_record.cert_validations.*.fqdn
  timeouts {
    create = "120m"
  }
}
