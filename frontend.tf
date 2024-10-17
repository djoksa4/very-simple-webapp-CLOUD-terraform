
#### S3 Bucket for frontent static files ########################################################
resource "aws_s3_bucket" "this" {
  bucket        = "static-frontend-uihdfs87ytf764gh"
  force_destroy = true # delete objects on destroy
}


#### S3 Bucket CORS config
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


#### S3 Bucket Policy (allow CloudFront to access files)
resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "cloudfront.amazonaws.com"
        },
        Action   = "s3:GetObject",
        Resource = "${aws_s3_bucket.this.arn}/*",
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.this.arn
          }
        }
      }
    ]
  })
}


#### CloudFront #################################################################################
resource "aws_cloudfront_distribution" "this" {
  enabled             = true
  default_root_object = "index.html"
  is_ipv6_enabled     = true
  wait_for_deployment = true
  price_class         = "PriceClass_100"

  default_cache_behavior {
    allowed_methods        = ["HEAD", "DELETE", "POST", "GET", "OPTIONS", "PUT", "PATCH"]
    cached_methods         = ["HEAD", "GET", "OPTIONS"]
    cache_policy_id        = aws_cloudfront_cache_policy.custom_cache_policy.id
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

  # logging to a bucket separate from frontend files
  logging_config {
    bucket          = "troubleshooting-logs-8375807834058309458.s3.amazonaws.com"
    include_cookies = false
  }
}


#### CloudFront Origin Access Control (OAC)
resource "aws_cloudfront_origin_access_control" "this" {
  name                              = "s3-cloudfront-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}


#### Custom CloudFront cache policy
resource "aws_cloudfront_cache_policy" "custom_cache_policy" {
  name    = "custom-cache-policy-with-cors"
  comment = "Custom cache policy with CORS headers"

  default_ttl = 86400    # 1 day (same as CachingOptimized)
  max_ttl     = 31536000 # 1 year (same as CachingOptimized)
  min_ttl     = 60       # 1 minute (same as CachingOptimized)

  # CORS config for cache
  parameters_in_cache_key_and_forwarded_to_origin {
    headers_config {
      header_behavior = "whitelist"
      headers {
        items = ["Origin", "Access-Control-Request-Headers", "Access-Control-Request-Method"]
      }
    }

    cookies_config {
      cookie_behavior = "none"
    }

    query_strings_config {
      query_string_behavior = "none"
    }
  }
}


