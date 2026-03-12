# outputs.tf
# Defines outputs that Terraform will display after resources are created

output "s3_bucket_name" {
  description = "Name of the S3 bucket created for the platform baseline"
  value       = aws_s3_bucket.platform_baseline_bucket.bucket
}
