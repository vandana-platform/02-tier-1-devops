output "bucket_name" {
  description = "S3 bucket name"
  value       = aws_s3_bucket.static_site.id
}

output "website_endpoint" {
  description = "S3 static website endpoint"
  value       = aws_s3_bucket_website_configuration.static_site.website_endpoint
}
