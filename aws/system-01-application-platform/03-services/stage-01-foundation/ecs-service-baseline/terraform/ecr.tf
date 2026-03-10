# This file provisions the Amazon Elastic Container Registry (ECR) repository
# used by the platform to store container images for application workloads.
# The repository acts as the container image registry from which ECS tasks
# pull container images during service deployment.

resource "aws_ecr_repository" "fastapi_repo" {
  name = "fastapi-ecs-repo"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Project = "tier1-ecs-service-baseline"
    ManagedBy = "Terraform"
  }
}
