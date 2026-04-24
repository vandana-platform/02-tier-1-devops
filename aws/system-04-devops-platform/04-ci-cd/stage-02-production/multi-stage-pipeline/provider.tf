provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = var.project_name
      ManagedBy = "Terraform"
      Tier      = "tier-2"
      Stage     = "stage-02-production"
    }
  }
}
