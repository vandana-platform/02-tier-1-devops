output "secret_arn" {
  description = "ARN of the Secrets Manager secret"
  value       = aws_secretsmanager_secret.db_credentials.arn
}

output "secret_name" {
  description = "Name of the Secrets Manager secret"
  value       = aws_secretsmanager_secret.db_credentials.name
}

output "consumer_role_arn" {
  description = "ARN of the IAM role that can read the secret"
  value       = aws_iam_role.secret_consumer.arn
}

output "consumer_role_name" {
  description = "Name of the IAM role that can read the secret"
  value       = aws_iam_role.secret_consumer.name
}
