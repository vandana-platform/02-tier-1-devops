# provider.tf
# Configures the AWS provider used by Terraform.
# This defines which AWS region Terraform will deploy resources into.

provider "aws" {
  region = var.aws_region
}
