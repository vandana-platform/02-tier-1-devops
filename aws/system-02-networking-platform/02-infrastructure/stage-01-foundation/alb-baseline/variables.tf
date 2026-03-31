variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}
variable "project_name" {
  description = "Project name prefix"
  type        = string
  default     = "tier2-alb-baseline"
}
variable "vpc_id" {
  description = "VPC ID where ALB will be deployed"
  type        = string
}
variable "public_subnet_ids" {
  description = "List of public subnet IDs for ALB"
  type        = list(string)
}
