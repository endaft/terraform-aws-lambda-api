#################################################
# S3 - Website Bucket
#################################################

resource "aws_s3_bucket" "app" {
  bucket = local.web_app_domain
  acl    = "private"
  tags   = local.default_tags

  versioning {
    enabled = true
  }
}

resource "aws_s3_bucket_object" "app_files" {
  for_each = fileset(local.web_app_path, "**")

  key          = each.value
  bucket       = aws_s3_bucket.app.bucket
  source       = "${local.web_app_path}/${each.value}"
  etag         = filemd5("${local.web_app_path}/${each.value}")
  content_type = lookup(local.mime_map, reverse(split(".", each.value))[0], "application/octet-stream")
}

resource "aws_s3_bucket_policy" "app" {
  bucket = aws_s3_bucket.app.id
  policy = data.aws_iam_policy_document.s3_app_policy_doc.json
}

data "aws_iam_policy_document" "s3_app_policy_doc" {
  version = "2008-10-17"

  statement {
    sid       = "AllowPublicRead"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.app.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.app.iam_arn]
    }
  }
}
