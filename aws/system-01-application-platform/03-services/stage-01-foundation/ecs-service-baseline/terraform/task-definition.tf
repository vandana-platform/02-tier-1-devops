# This file defines the ECS task definition which represents the runtime
# specification for the containerized workload. It includes container image,
# compute allocation, networking mode, and port mappings required to run
# the FastAPI service.

resource "aws_ecs_task_definition" "task" {
  family                   = "fastapi-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"

  cpu    = var.task_cpu
  memory = var.task_memory

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "fastapi-container"
      image     = "${aws_ecr_repository.fastapi_repo.repository_url}:latest"
      essential = true

      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "APP_ENV"
          value = "dev"
        },
        {
          name  = "POSTGRES_HOST"
          value = "localhost"
        },
        {
          name  = "POSTGRES_PORT"
          value = "5432"
        },
        {
          name  = "POSTGRES_USER"
          value = "test"
        },
        {
          name  = "POSTGRES_PASSWORD"
          value = "test"
        },
        {
          name  = "POSTGRES_DB"
          value = "test"
        },
        {
          name  = "JWT_SECRET_KEY"
          value = "testsecret"
        }
      ]
    }
  ])
}
