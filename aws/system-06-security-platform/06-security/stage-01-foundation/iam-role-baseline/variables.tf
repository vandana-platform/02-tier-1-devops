/*
File: variables.tf

Purpose:
Defines input variables used by the Terraform configuration.

Using variables allows infrastructure configurations to be reusable
and configurable without modifying the core infrastructure code.
*/

variable "aws_region" {
  description = "AWS region where IAM resources will be created"
  type        = string
  default     = "us-east-1"
}

variable "role_name" {
  description = "Name of the IAM role to be created"
  type        = string
  default     = "ec2-baseline-role"
}

variable "policy_name" {
  description = "Name of the IAM policy to attach to the role"
  type        = string
  default     = "ec2-read-only-policy"
}
