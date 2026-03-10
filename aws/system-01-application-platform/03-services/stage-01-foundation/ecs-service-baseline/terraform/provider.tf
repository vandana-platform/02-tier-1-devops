# This file configures the AWS provider used by Terraform to interact with
# the target cloud environment. It defines the region where platform resources
# such as ECS clusters and services will be provisioned.

provider "aws" {
  region = var.aws_region
}
