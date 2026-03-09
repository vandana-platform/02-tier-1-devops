/*
File: provider.tf

Purpose:
Configures the AWS provider used by Terraform to interact with AWS services.

This provider block specifies which AWS region the infrastructure
resources will be created in.

Authentication is handled using AWS CLI credentials configured
locally in the environment.
*/

provider "aws" {
  region = var.aws_region
}
