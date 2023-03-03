
# S3 Allow Public read access as data object
data "aws_iam_policy_document" "allow_public_s3_read" {
  statement {
    sid    = "PublicReadGetObject"
    effect = "Allow"

    actions = [
      "s3:GetObject",
    ]

    principals {
      type        = "AWS"
      identifiers = "*"
    }

    resources = [
      "arn:aws:s3:::${var.bucket_name}/*"
    ]
  }
}

# S3 bucket for website.
resource "aws_s3_bucket" "website_bucket" {
  bucket = "${var.bucket_name}"
  acl    = "public-read"
  policy = data.aws_iam_policy_document.allow_public_s3_read.json

  cors_rule {
    allowed_headers = ["Authorization", "Content-Length"]
    allowed_methods = ["GET", "POST"]
    allowed_origins = ["https://${var.bucket_name}.s3.amazonaws.com"]
    max_age_seconds = 3000
  }

  website {
    index_document = "index.html"
    error_document = "404.html"
  }

  versioning = {
    enabled = true
  }

  tags = var.common_tags
}