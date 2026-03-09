/*
File: main.tf

Purpose:
Defines infrastructure resources for the EC2 Terraform project.

Resources created:
1. Security Group for SSH access
2. EC2 instance using the security group

This project demonstrates basic compute provisioning using Terraform
as part of the Tier-1 DevOps platform engineering roadmap.
*/

# Security Group for EC2 SSH access
resource "aws_security_group" "ec2_security_group" {

  name        = "tier1-ec2-sg"
  description = "Allow SSH access for Tier1 EC2 instance"

  ingress {
    description = "SSH Access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "tier1-ec2-sg"
    Environment = "foundation"
    Project     = "tier1-devops-platform"
  }
}


# EC2 Instance
resource "aws_instance" "tier1_ec2_instance" {

  ami           = "ami-0c02fb55956c7d316"
  instance_type = var.instance_type

  vpc_security_group_ids = [
    aws_security_group.ec2_security_group.id
  ]

  tags = {
    Name        = "tier1-ec2-instance"
    Environment = "foundation"
    Project     = "tier1-devops-platform"
  }
}
