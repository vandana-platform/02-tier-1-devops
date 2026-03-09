/*
File: main.tf

Purpose:
Defines the core infrastructure resources for the IAM baseline role.

This file creates:
- IAM role
- IAM policy
- Policy attachment

These resources establish a baseline identity configuration
for AWS services such as EC2.
*/

resource "aws_iam_role" "ec2_role" {

  name = var.role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "ec2_read_policy" {

  name = var.policy_name

  description = "Read-only access to EC2 resources"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:Describe*"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_policy" {

  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.ec2_read_policy.arn

}
