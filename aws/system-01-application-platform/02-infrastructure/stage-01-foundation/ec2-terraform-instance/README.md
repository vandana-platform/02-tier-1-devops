# EC2 Terraform Instance

This project provisions a basic Amazon EC2 instance using Terraform as part of the **Application Platform infrastructure foundation**.

The purpose of this project is to demonstrate how compute infrastructure can be provisioned and managed using **Infrastructure as Code (IaC)**.

Terraform is used to define, create, and manage the EC2 instance and its associated security group.

--------------------------------------------------

Platform Context

Repository Layer  
Tier-1 DevOps Platform Systems

Cloud Provider  
AWS

Platform System  
system-01 — Application Platform

Capability Layer  
02-infrastructure

Infrastructure Stage  
stage-01-foundation

This project represents a **foundation-level compute capability** for the Application Platform.

--------------------------------------------------

Capability Implemented

Provision a basic compute instance using Terraform.

Resources created:

• Amazon EC2 Instance  
• AWS Security Group allowing SSH access

The security group is attached to the EC2 instance to allow secure administrative access.

--------------------------------------------------

Project Structure

ec2-terraform-instance/

versions.tf  
Defines required Terraform version and provider constraints.

provider.tf  
Configures the AWS provider used for infrastructure provisioning.

variables.tf  
Defines input variables such as the instance type.

main.tf  
Defines the infrastructure resources including the EC2 instance and security group.

outputs.tf  
Defines Terraform outputs including instance ID and public IP.

README.md  
Project documentation.

--------------------------------------------------

Terraform Workflow

Initialize Terraform

terraform init

Review the execution plan

terraform plan

Create the infrastructure

terraform apply

Destroy the infrastructure

terraform destroy

Destroying infrastructure ensures the environment can be recreated cleanly and prevents unused cloud resources from consuming credits.

--------------------------------------------------

Outputs

After successful deployment Terraform returns outputs including:

instance_id  
public_ip

Example output:

instance_id = i-07e76ca4a6776b7c7  
public_ip   = 44.210.102.31

These outputs allow engineers to quickly identify and access the deployed instance.

--------------------------------------------------

Error Encountered During Deployment

During the initial deployment Terraform returned the following error:

InvalidParameterCombination  
The specified instance type is not eligible for Free Tier.

Cause

The selected EC2 instance type was not eligible for AWS Free Tier.

Resolution

The instance type was updated to a Free Tier eligible instance type:

t3.micro

After updating the instance type, Terraform successfully created the EC2 instance.

--------------------------------------------------

Learning Outcomes

This project demonstrates the following DevOps capabilities:

• Infrastructure provisioning using Terraform  
• AWS EC2 instance deployment  
• Security group configuration  
• Terraform lifecycle management (init → plan → apply → destroy)  
• Troubleshooting cloud provisioning errors  
• Verifying infrastructure using AWS CLI and AWS Console
