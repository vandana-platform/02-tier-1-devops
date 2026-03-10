# This file creates the ECS service responsible for running and maintaining
# the FastAPI container workload. The service ensures the desired number
# of tasks remain running within the cluster and manages task lifecycle.

resource "aws_ecs_service" "service" {
  name            = var.service_name
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets = [
      "subnet-094de3decc218310f",
      "subnet-07f214faf94ae442e"
    ]

    assign_public_ip = true
  }
}
