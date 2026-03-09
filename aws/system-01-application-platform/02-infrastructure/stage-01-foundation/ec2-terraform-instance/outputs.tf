/*
File: outputs.tf

Purpose:
Defines output values that Terraform will display after infrastructure
is successfully provisioned.

These outputs provide useful information about created resources
such as instance ID and public IP address.
*/

output "instance_id" {
  description = "ID of the EC2 instance created by Terraform"
  value       = aws_instance.tier1_ec2_instance.id
}

output "public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.tier1_ec2_instance.public_ip
}
