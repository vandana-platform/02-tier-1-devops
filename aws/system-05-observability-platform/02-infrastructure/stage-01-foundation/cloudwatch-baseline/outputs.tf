output "log_group_name" {
  description = "CloudWatch log group name"
  value       = aws_cloudwatch_log_group.platform.name
}

output "log_group_arn" {
  description = "CloudWatch log group ARN"
  value       = aws_cloudwatch_log_group.platform.arn
}

output "alarm_name" {
  description = "CloudWatch alarm name"
  value       = aws_cloudwatch_metric_alarm.high_cpu.alarm_name
}
