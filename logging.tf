# S3 bucket for logs
resource "aws_s3_bucket" "troubleshooting_logs" {
  bucket        = "troubleshooting-logs-8375807834058309458"
  force_destroy = true # delete objects on destroy

  tags = {
    Name = "troubleshooting-logs-8375807834058309458"
  }
}

resource "aws_s3_bucket_policy" "troubleshooting_logs_policy" {
  bucket = aws_s3_bucket.troubleshooting_logs.bucket

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::127311923021:root"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.troubleshooting_logs.arn}/AWSLogs/241533135907/*"
      }
    ]
  })
}
