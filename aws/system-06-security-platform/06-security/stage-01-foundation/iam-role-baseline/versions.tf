/*
File: versions.tf

Purpose:
Defines the Terraform version and required provider versions
for this infrastructure configuration.

This ensures consistent Terraform behavior across environments
and prevents incompatible provider versions from being used.
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
