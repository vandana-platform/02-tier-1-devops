variable "aws_region" {
  description = "AWS region for the pipeline"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name prefix for all resources"
  type        = string
  default     = "tier2-multi-stage-pipeline"
}

variable "artifact_retention_days" {
  description = "Days to retain old artifact versions in S3"
  type        = number
  default     = 30
}

variable "source_object_key" {
  description = "S3 object key for the source artifact zip (pipeline trigger)"
  type        = string
  default     = "source/source.zip"
}
