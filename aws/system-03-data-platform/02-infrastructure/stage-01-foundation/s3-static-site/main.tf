resource "aws_s3_bucket" "static_site" {
  bucket = var.bucket_name
  tags = {
    Name        = var.bucket_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_s3_bucket_website_configuration" "static_site" {
  bucket = aws_s3_bucket.static_site.id
  index_document { suffix = "index.html" }
  error_document { key    = "error.html" }
}

resource "aws_s3_bucket_public_access_block" "static_site" {
  bucket                  = aws_s3_bucket.static_site.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "static_site" {
  bucket = aws_s3_bucket.static_site.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "PublicReadGetObject"
      Effect    = "Allow"
      Principal = "*"
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.static_site.arn}/*"
    }]
  })
  depends_on = [aws_s3_bucket_public_access_block.static_site]
}
