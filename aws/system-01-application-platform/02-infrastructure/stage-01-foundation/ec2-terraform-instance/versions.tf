/*
File: versions.tf

Purpose:
Defines Terraform and provider version constraints for this project.

Why this is important:
Ensures consistent infrastructure builds across different environments
by preventing incompatible Terraform or provider versions from being used.
*/

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
