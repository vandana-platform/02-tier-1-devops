# IAM Role Baseline

Provisions a baseline AWS IAM role and policy using Terraform as part of the **Security Platform foundation**.

The purpose of this project is to demonstrate how AWS identities and permissions can be managed using **Infrastructure as Code (IaC)**.

---

## Platform Context

| Field | Value |
|---|---|
| Repository Layer | Tier-1 DevOps Platform Systems |
| Cloud Provider | AWS |
| Platform System | system-06 — Security Platform |
| Capability Layer | 06-security |
| Infrastructure Stage | stage-01-foundation |

This project represents a **foundation-level identity capability** for the Security Platform.

---

## Resources Created

| Resource | Description |
|---|---|
| `aws_iam_role` | IAM role for EC2 (`ec2-baseline-role`) with an EC2 service trust policy |
| `aws_iam_policy` | Customer-managed IAM policy granting read-only access to EC2 resources (`ec2:Describe*`) |
| `aws_iam_role_policy_attachment` | Attaches the EC2 read-only policy to the IAM role |

---

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) `>= 1.5.0`
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) configured with valid credentials
- AWS provider `~> 5.0`

---

## Project Structure

```
iam-role-baseline/
├── versions.tf   # Terraform and provider version constraints
├── provider.tf   # AWS provider configuration
├── variables.tf  # Input variable definitions
├── main.tf       # IAM role, policy, and attachment resources
├── outputs.tf    # Output values (role name, role ARN, policy ARN)
└── README.md
```

---

## Input Variables

| Variable | Type | Default | Description |
|---|---|---|---|
| `aws_region` | `string` | `us-east-1` | AWS region for the provider configuration |
| `role_name` | `string` | `ec2-baseline-role` | Name of the IAM role to be created |
| `policy_name` | `string` | `ec2-read-only-policy` | Name of the IAM policy to create and attach |

---

## Terraform Workflow

**Initialize**
```bash
terraform init
```

**Review the execution plan**
```bash
terraform plan
```

**Deploy infrastructure**
```bash
terraform apply
```

**Destroy infrastructure**
```bash
terraform destroy
```

> IAM roles, policies, and attachments are free resources. Destroying the stack keeps the account clean and avoids IAM quota exhaustion (AWS enforces limits on the number of roles and customer-managed policies per account).

---

## Outputs

After a successful `terraform apply`, the following values are returned:

| Output | Description |
|---|---|
| `iam_role_name` | The name of the provisioned IAM role |
| `iam_role_arn` | The ARN of the provisioned IAM role |
| `policy_arn` | The ARN of the customer-managed IAM policy |

Example:
```
iam_role_name = "ec2-baseline-role"
iam_role_arn  = "arn:aws:iam::123456789012:role/ec2-baseline-role"
policy_arn    = "arn:aws:iam::123456789012:policy/ec2-read-only-policy"
```

---

## Troubleshooting

**`EntityAlreadyExists` — IAM role or policy name already exists**

An IAM role or policy with the same name exists in the account but is not in Terraform state. Import the existing resource or override `role_name` / `policy_name` with a unique value.

**`AccessDenied` on `iam:CreateRole`**

The caller lacks the required IAM permissions. Attach a policy that includes `iam:CreateRole`, `iam:CreatePolicy`, `iam:AttachRolePolicy`, and related read permissions.

---

## Learning Outcomes

- IAM role creation and trust policy configuration with Terraform
- Customer-managed IAM policy definition using inline `jsonencode`
- Policy attachment via `aws_iam_role_policy_attachment`
- Understanding the IAM principal model — who can assume a role and what they can do
- Terraform lifecycle management (`init` → `plan` → `apply` → `destroy`)
- Verifying IAM resources via AWS CLI and AWS Console
