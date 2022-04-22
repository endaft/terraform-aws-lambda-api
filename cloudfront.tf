#################################################
# CloudFront - Website Access
#################################################

resource "aws_cloudfront_origin_access_identity" "app" {
  comment = "The origin access identity for ${local.web_app_domain}"
}

resource "aws_cloudfront_distribution" "app" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  price_class         = "PriceClass_All"
  comment             = "The public access point for ${local.web_app_domain}"
  aliases             = concat([local.app_domain, local.web_app_domain], local.web_app_cnames)

  logging_config {
    include_cookies = false
    bucket          = "${aws_s3_bucket.app.bucket}.s3.amazonaws.com"
    prefix          = "logs"
  }

  origin {
    domain_name = aws_s3_bucket.app.bucket_regional_domain_name
    origin_id   = local.s3w_origin_id
    origin_path = "sites"

    custom_header {
      name  = "X-Base-Host"
      value = local.app_domain
    }

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.app.cloudfront_access_identity_path
    }
  }

  default_cache_behavior {
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = local.s3w_origin_id
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 3600
    default_ttl            = 7200
    max_ttl                = 86400
    compress               = true

    forwarded_values {
      query_string = false
      headers      = ["Host"]

      cookies {
        forward = "none"
      }

    }

    dynamic "lambda_function_association" {
      for_each = [aws_lambda_function.cloudfront]

      content {
        event_type   = "origin-request"
        lambda_arn   = aws_lambda_function.cloudfront[lambda_function_association.key].qualified_arn
        include_body = true
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
