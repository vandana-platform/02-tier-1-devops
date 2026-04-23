# Random password generated for the secret payload
resource "random_password" "db_password" {
  length           = 20
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Secret container
resource "aws_secretsmanager_secret" "db_credentials" {
  name                    = "${var.project_name}-db-credentials"
  description             = "Database credentials managed by Terraform for ${var.project_name}"
  recovery_window_in_days = var.secret_recovery_window_days
}

# Secret value (JSON payload with username and password)
resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db_password.result
  })
}

# IAM role that an EC2 / ECS / Lambda consumer would assume to read the secret
resource "aws_iam_role" "secret_consumer" {
  name = "${var.project_name}-consumer-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# Least-privilege policy scoped to this specific secret ARN
resource "aws_iam_policy" "secret_read" {
  name        = "${var.project_name}-secret-read"
  description = "Allow read-only access to the db credentials secret"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
      Resource = aws_secretsmanager_secret.db_credentials.arn
    }]
  })
}

resource "aws_iam_role_policy_attachment" "secret_read" {
  role       = aws_iam_role.secret_consumer.name
  policy_arn = aws_iam_policy.secret_read.arn
}
