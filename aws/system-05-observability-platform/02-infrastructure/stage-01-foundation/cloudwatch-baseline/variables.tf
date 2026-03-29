variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "log_group_name" {
  description = "CloudWatch log group name"
  type        = string
  default     = "/platform/application"
}

variable "retention_days" {
  description = "Log retention in days"
  type        = number
  default     = 7
}
