#################################################
# CloudFront - Website Access
#################################################

resource "aws_cloudfront_origin_access_identity" "app" {
  comment = "The origin access identity for ${local.web_app_domain}"
}

data "aws_cloudfront_cache_policy" "app" {
  name = "Managed-CachingOptimized"
}

data "aws_cloudfront_origin_request_policy" "app" {
  name = "Managed-AllViewer"
}

data "aws_cloudfront_response_headers_policy" "app" {
  name = "Managed-CORS-with-preflight-and-SecurityHeadersPolicy"
}

resource "aws_cloudfront_origin_request_policy" "app" {
  name    = "${local.app_slug}-${local.env_prefix}RequestPolicy"
  comment = "Origin request policy for ${local.app_domain}"
  cookies_config {
    cookie_behavior = "all"
  }
  headers_config {
    header_behavior = "allViewer"
  }
  query_strings_config {
    query_string_behavior = "all"
  }
}

resource "aws_cloudfront_cache_policy" "app" {
  name        = "${local.app_slug}-${local.env_prefix}CachePolicy"
  comment     = "Cache policy for ${local.app_domain}"
  default_ttl = data.aws_cloudfront_cache_policy.app.default_ttl
  max_ttl     = data.aws_cloudfront_cache_policy.app.max_ttl
  min_ttl     = data.aws_cloudfront_cache_policy.app.min_ttl

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"
    }
    query_strings_config {
      query_string_behavior = "none"
    }
    headers_config {
      header_behavior = "whitelist"
      headers {
        items = ["Host"]
      }
    }
  }
}

resource "aws_cloudfront_origin_access_control" "app" {
  name                              = "${local.web_app_domain}-oac"
  description                       = "The origin access control policy for ${local.web_app_domain}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "app" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  price_class         = "PriceClass_All"
  comment             = "The public access point for ${local.web_app_domain}"
  aliases             = concat([local.app_domain, local.web_app_domain], local.web_app_cnames)
  http_version        = "http2and3"

  logging_config {
    include_cookies = false
    bucket          = "${aws_s3_bucket.app.bucket}.s3.amazonaws.com"
    prefix          = "logs"
  }

  origin {
    domain_name              = aws_s3_bucket.app.bucket_regional_domain_name
    origin_id                = local.s3w_origin_id
    origin_path              = "/sites"
    origin_access_control_id = aws_cloudfront_origin_access_control.app.id

    custom_header {
      name  = "X-Base-Host"
      value = local.app_domain
    }

    dynamic "custom_header" {
      for_each = local.web_app_origins

      content {
        name  = "X-Origin-${upper(custom_header.key)}"
        value = "https://${regex("^.*//([^:/]*).*$", custom_header.value)[0]}${trimsuffix(regex("^.*//[^:/]+:?(/[^{]*).*$", custom_header.value)[0], "/")}"
      }
    }
  }

  dynamic "origin" {
    for_each = local.web_app_origins

    content {
      domain_name = regex("^.*//([^:/]*).*$", origin.value)[0]
      origin_id   = "${origin.key}-origin"
      origin_path = trimsuffix(regex("^.*//[^:/]+:?(/[^{]*).*$", origin.value)[0], "/")

      custom_origin_config {
        origin_protocol_policy = "https-only"
        origin_ssl_protocols   = ["TLSv1.1", "TLSv1.2"]
        https_port             = 443
        http_port              = 80
      }

      custom_header {
        name  = "X-Base-Host"
        value = local.app_domain
      }
    }
  }

  dynamic "origin_group" {
    for_each = [length(local.web_app_origin_groups) > 0 ? 1 : 0]

    content {
      origin_id = "S3OriginFailover"

      failover_criteria {
        status_codes = [403, 404, 500, 502]
      }

      member {
        origin_id = local.s3w_origin_id
      }

      dynamic "member" {
        for_each = local.web_app_origin_groups
        content {
          origin_id = "${member.key}-origin"
        }
      }
    }
  }

  default_cache_behavior {
    allowed_methods            = ["GET", "HEAD", "OPTIONS"]
    cached_methods             = ["GET", "HEAD"]
    target_origin_id           = length(local.web_app_origin_groups) > 0 ? "S3OriginFailover" : local.s3w_origin_id
    viewer_protocol_policy     = "redirect-to-https"
    compress                   = true
    cache_policy_id            = aws_cloudfront_cache_policy.app.id
    origin_request_policy_id   = data.aws_cloudfront_origin_request_policy.app.id
    response_headers_policy_id = data.aws_cloudfront_response_headers_policy.app.id

    dynamic "lambda_function_association" {
      for_each = [aws_lambda_function.cloudfront]

      content {
        event_type   = "origin-request"
        lambda_arn   = aws_lambda_function.cloudfront[lambda_function_association.key].qualified_arn
        include_body = false
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    minimum_protocol_version = "TLSv1.2_2021"
    ssl_support_method       = "sni-only"
    acm_certificate_arn      = aws_acm_certificate.app.arn
  }
}
