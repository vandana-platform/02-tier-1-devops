# variables.tf
# Defines input variables used by the container platform baseline infrastructure

variable "aws_region" {
  description = "AWS region where resources will be deployed"
  type        = string
  default     = "us-east-1"
}
