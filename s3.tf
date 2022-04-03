#################################################
# S3 - Website Bucket
#################################################

resource "aws_s3_bucket" "app" {
  bucket = local.web_app_domain
}

resource "aws_s3_bucket_versioning" "versioning_example" {
  bucket = aws_s3_bucket.app.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_website_configuration" "example" {
  bucket = aws_s3_bucket.app.bucket

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_object" "app_files" {
  for_each     = local.web_apps_files
  key          = each.key
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
