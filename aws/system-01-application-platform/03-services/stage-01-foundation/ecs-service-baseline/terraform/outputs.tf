# This file defines Terraform outputs that expose key platform resources
# created during the ECS service deployment. These outputs help operators
# quickly identify important infrastructure values such as the ECS cluster
# name and service name after provisioning.

output "ecs_cluster_name" {
  description = "Name of the ECS cluster hosting the application service"
  value       = aws_ecs_cluster.cluster.name
}

output "ecs_service_name" {
  description = "Name of the ECS service responsible for running the FastAPI workload"
  value       = aws_ecs_service.service.name
}

output "ecs_task_definition_arn" {
  description = "ARN of the ECS task definition used by the service"
  value       = aws_ecs_task_definition.task.arn
}
