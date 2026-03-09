/*
File: outputs.tf

Purpose:
Defines output values generated after Terraform deployment.

Outputs allow users to easily retrieve important infrastructure
information such as IAM role names and ARNs.
*/

output "iam_role_name" {
  description = "Name of the IAM role created"
  value       = aws_iam_role.ec2_role.name
}

output "iam_role_arn" {
  description = "ARN of the IAM role created"
  value       = aws_iam_role.ec2_role.arn
}

output "policy_arn" {
  description = "ARN of the IAM policy created"
  value       = aws_iam_policy.ec2_read_policy.arn
}
