# This file defines configurable variables used across the platform infrastructure.
# These variables allow the ECS service deployment to remain reusable and environment-agnostic.

variable "aws_region" {
  default = "us-east-1"
}

variable "cluster_name" {
  default = "tier1-ecs-cluster"
}

variable "service_name" {
  default = "fastapi-service"
}

variable "task_cpu" {
  default = "256"
}

variable "task_memory" {
  default = "512"
}

variable "container_port" {
  default = 8000
}
