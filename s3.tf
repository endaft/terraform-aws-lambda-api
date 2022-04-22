#################################################
# S3 - Website Bucket
#################################################

resource "aws_s3_bucket" "app" {
  bucket = local.app_domain
}

resource "aws_s3_bucket_acl" "app" {
  bucket = aws_s3_bucket.app.id
  acl    = "private"
}

resource "aws_s3_bucket_website_configuration" "app" {
  bucket = aws_s3_bucket.app.bucket

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_object" "app_files" {
  for_each     = local.web_apps_files
  key          = "sites/${each.key}"
  source       = each.value
  etag         = filemd5(each.value)
  bucket       = aws_s3_bucket.app.bucket
  content_type = lookup(local.mime_map, reverse(split(".", each.value))[0], "application/octet-stream")
}

resource "aws_s3_bucket_policy" "app" {
  bucket = aws_s3_bucket.app.id
  policy = data.aws_iam_policy_document.s3_app_policy_doc.json
}

data "aws_iam_policy_document" "s3_app_policy_doc" {
  version = "2008-10-17"

  statement {
    effect    = "Allow"
    sid       = "AllowPublicVisible"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.app.arn]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.app.iam_arn]
    }
  }

  statement {
    effect    = "Allow"
    sid       = "AllowPublicRead"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.app.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.app.iam_arn]
    }
  }
}
