output "ec2_public_ip" {
  description = "EC2 public IP"
  value       = aws_instance.main.public_ip
}

output "ec2_instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.main.id
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "deploy_url" {
  description = "URL to check nginx after deploy"
  value       = "http://${aws_instance.main.public_ip}"
}
