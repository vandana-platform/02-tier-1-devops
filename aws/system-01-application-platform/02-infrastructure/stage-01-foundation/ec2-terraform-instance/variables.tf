/*
File: variables.tf

Purpose:
Defines input variables used by the Terraform configuration.

Using variables allows infrastructure configurations to be reusable
and configurable without modifying the core infrastructure code.
*/

variable "aws_region" {
  description = "AWS region where infrastructure resources will be deployed"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type to launch"
  type        = string
  default     = "t3.micro"
}
