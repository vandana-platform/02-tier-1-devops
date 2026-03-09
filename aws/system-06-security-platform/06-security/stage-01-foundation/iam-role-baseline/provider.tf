/*
File: provider.tf

Purpose:
Configures the AWS provider used by Terraform to interact with
Amazon Web Services.

The provider uses credentials configured locally via AWS CLI
or environment variables.
*/

provider "aws" {
  region = var.aws_region
}
