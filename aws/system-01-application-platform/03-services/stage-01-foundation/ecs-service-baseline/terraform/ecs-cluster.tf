# This file creates the ECS cluster that acts as the container runtime environment
# for platform workloads. The cluster provides the orchestration layer responsible
# for running and managing containerized services.

resource "aws_ecs_cluster" "cluster" {
  name = var.cluster_name
}
