
# IAM Role Baseline

This project provisions a baseline AWS IAM role and policy using Terraform as part of the Security Platform foundation layer.

The configuration demonstrates how infrastructure teams define identity and access control using Infrastructure as Code (IaC).

This project belongs to the Tier-1 DevOps Platform repository and represents the initial IAM identity setup for cloud services.

# Platform Architecture Context

This component is part of the Security Platform System.

02-tier-1-devops
└── aws
    └── system-06-security-platform
        └── 06-security
            └── stage-01-foundation
                └── iam-role-baseline

| Layer | Description |
|------|-------------|
| System | Security Platform |
| Capability | Security |
| Stage | Foundation |
| Component | IAM Role Baseline |

# Resources Created

Terraform creates the following AWS IAM resources:

| Resource | Description |
|--------|-------------|
| IAM Role | Role assumed by EC2 instances |
| IAM Policy | Defines read-only EC2 permissions |
| Role Policy Attachment | Attaches policy to the IAM role |

The role uses a trust relationship allowing EC2 to assume the role.

# Purpose

The goal of this project is to demonstrate:

- IAM role creation using Terraform
- IAM policy definition
- Role-policy attachment
- Basic AWS service trust relationships
- Infrastructure as Code practices for identity management

This forms the foundation layer of identity access management in cloud platforms.

# Terraform Files

| File | Purpose |
|-----|--------|
| versions.tf | Defines Terraform and provider version requirements |
| provider.tf | Configures AWS provider |
| variables.tf | Defines reusable input variables |
| main.tf | Creates IAM role, policy, and attachment |
| outputs.tf | Outputs IAM resource identifiers |
| README.md | Project documentation |

# Project Structure

iam-role-baseline
├── versions.tf
├── provider.tf
├── variables.tf
├── main.tf
├── outputs.tf
└── README.md

# Terraform Workflow

Initialize Terraform:

terraform init

Validate configuration:

terraform validate

Preview infrastructure changes:

terraform plan

Apply infrastructure:

terraform apply

# Example Outputs

After deployment Terraform returns:

iam_role_name = ec2-baseline-role  
iam_role_arn  = arn:aws:iam::<account-id>:role/ec2-baseline-role  
policy_arn    = arn:aws:iam::<account-id>:policy/ec2-read-only-policy  

# Cleanup

To remove the resources:

terraform destroy

# Key Concepts Demonstrated

- Infrastructure as Code (Terraform)
- AWS IAM Role creation
- IAM Policy management
- Policy attachment
- Cloud identity baseline configuration
