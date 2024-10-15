
# S3 Bucket
resource "aws_s3_bucket" "this" {
  bucket        = "static-frontend-uihdfs87ytf764gh"
  force_destroy = true # delete objects on destroy
}

resource "aws_s3_bucket_cors_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "POST", "HEAD"]
    allowed_origins = ["*"]
    expose_headers  = []
    max_age_seconds = 3000
  }
}




# CloudFront Distribution
resource "aws_cloudfront_distribution" "this" {
  enabled             = true
  default_root_object = "index.html"
  is_ipv6_enabled     = true
  wait_for_deployment = true
  price_class         = "PriceClass_100"

  default_cache_behavior {
    allowed_methods        = ["HEAD", "DELETE", "POST", "GET", "OPTIONS", "PUT", "PATCH"]
    cached_methods         = ["HEAD", "GET", "OPTIONS"]
    cache_policy_id        = "658327ea-f89d-4fab-a63d-7e88639e58f6" # AWS managed cache policy (CachingOptimized)
    target_origin_id       = aws_s3_bucket.this.bucket
    viewer_protocol_policy = "allow-all" # allow-all, https-only or redirect-to-https

    response_headers_policy_id = "60669652-455b-4ae9-85a4-c4c02393f86c"
  }

  origin {
    domain_name              = aws_s3_bucket.this.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.this.id # OAC defined below
    origin_id                = aws_s3_bucket.this.bucket
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}


# CloudFront Origin Access Control (OAC)
resource "aws_cloudfront_origin_access_control" "this" {
  name                              = "s3-cloudfront-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}


# Data to be applied to S3 Bucket Policy
data "aws_iam_policy_document" "cloudfront_oac_access" {
  statement {

    principals {
      identifiers = ["cloudfront.amazonaws.com"]
      type        = "Service"
    }

    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.this.arn}/*"]

    condition {
      test     = "StringEquals"
      values   = [aws_cloudfront_distribution.this.arn]
      variable = "AWS:SourceArn"
    }
  }
}


# S3 Bucket Policy
resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.cloudfront_oac_access.json
}
