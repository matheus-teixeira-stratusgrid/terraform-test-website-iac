#Setup bucket
resource "aws_s3_bucket" "website" {
  bucket        = var.bucket_name
  acl           = "private"
  force_destroy = true
  tags          = local.tags

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  website {
    index_document = "index.html"
    error_document = "404.html"
  }
}

resource "aws_s3_bucket_public_access_block" "s3block" {
  bucket                  = aws_s3_bucket.website.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

#Cloudfron distrubution config
resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "OAI for ${var.endpoint}"
}

resource "aws_cloudfront_distribution" "cf" {
  enabled             = true
  default_root_object = "index.html"

  origin {
    domain_name = aws_s3_bucket.website.bucket_regional_domain_name
    origin_id   = aws_s3_bucket.website.bucket_regional_domain_name
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    target_origin_id       = aws_s3_bucket.website.bucket_regional_domain_name
    viewer_protocol_policy = "redirect-to-https"
    forwarded_values {
      headers      = []
      query_string = true
      cookies {
        forward = "none"
      }
    }
    min_ttl                = 0
    max_ttl                = 0
    default_ttl            = 0
  }

  ordered_cache_behavior {
    path_pattern     = "images/*.jpg"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = aws_s3_bucket.website.bucket_regional_domain_name
        viewer_protocol_policy = "redirect-to-https"
    forwarded_values {
      query_string   = false
      headers        = []
      cookies {
        forward      = "none"
      }
    }
    min_ttl = 1800
    default_ttl = 1800
    max_ttl = 1800
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = local.tags
}


resource "aws_s3_bucket_policy" "s3policy" {
  bucket = aws_s3_bucket.website.id
  policy = data.aws_iam_policy_document.s3policy.json
}

# Codestar
resource "aws_codestarconnections_connection" "GitHub" {
  name          = "GitHub-connection"
  provider_type = "GitHub"
  tags          = local.tags
}

# Codepipeline setup
resource "aws_iam_role" "codepipeline_role" {
    name = "website-codepipeline-role"
    assume_role_policy = "${data.aws_iam_policy_document.codepipeline_assume_policy.json}"
}

resource "aws_iam_role_policy" "attach_codepipeline_policy" {
    name    = "website-codepipeline-policy"
    role    = "${aws_iam_role.codepipeline_role.id}"
    policy  = data.aws_iam_policy_document.codepipeline_policy.json
}

resource "aws_codepipeline" "codepipeline" {
    name     = "website-codepipeline"
    role_arn = aws_iam_role.codepipeline_role.arn

    artifact_store {
      location = aws_s3_bucket.website.id
      type     = "S3"
    }

    stage {
      name = "Source"
      action {
        name              = "Source"
        category          = "Source"
        owner             = "AWS"
        provider          = "CodeStarSourceConnection"
        version           = "1"
        output_artifacts  = ["source_output"]
        configuration = {
          ConnectionArn    = aws_codestarconnections_connection.GitHub.arn               
          FullRepositoryId = "matheus-teixeira-stratusgrid/terraform-test-website"
          BranchName       = "main"
        }
      }
    }

    stage {
      name = "Deploy"
      action {
        name     = "Deploy"
        category = "Deploy"
        owner    = "AWS"
        provider = "S3"
        role_arn = aws_iam_role.codepipeline_role.arn
        input_artifacts = ["source_output"]
        version = "1"
        configuration = {
          BucketName = var.bucket_name
          Extract    = "true"
        }
      }
    }

    tags = local.tags
}