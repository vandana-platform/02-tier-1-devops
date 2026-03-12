# main.tf
# Defines core infrastructure resources for the container platform baseline

resource "aws_s3_bucket" "platform_baseline_bucket" {
  bucket = "tier1-platform-baseline-demo-bucket"

  tags = {
    Name        = "tier1-platform-baseline"
    Environment = "foundation"
    Project     = "tier1-devops-platform"
  }
}
