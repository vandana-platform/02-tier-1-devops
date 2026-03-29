variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "S3 bucket name for static website"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}
