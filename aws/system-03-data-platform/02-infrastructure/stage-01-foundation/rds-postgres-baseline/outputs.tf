output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "db_instance_id" {
  description = "RDS instance ID"
  value       = aws_db_instance.main.id
}

output "db_endpoint" {
  description = "RDS endpoint"
  value       = aws_db_instance.main.endpoint
}

output "db_port" {
  description = "RDS port"
  value       = aws_db_instance.main.port
}

output "db_subnet_group_name" {
  description = "DB subnet group name"
  value       = aws_db_subnet_group.main.name
}
