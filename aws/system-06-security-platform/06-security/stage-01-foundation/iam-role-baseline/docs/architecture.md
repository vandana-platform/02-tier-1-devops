# Architecture — IAM Role Baseline

## Overview

This project provisions an AWS IAM role, a customer-managed IAM policy, and a policy attachment using Terraform. It serves as the **foundation-level identity capability** for the Security Platform (`system-06`, `stage-01-foundation`).

```
Tier-1 DevOps
└── system-06-security-platform
    └── 06-security
        └── stage-01-foundation
            └── iam-role-baseline
```

---

## Infrastructure Components

```
AWS Account (Global — IAM is not region-scoped)
└── IAM
    ├── Role: ec2-baseline-role
    │   ├── Trust Policy: Principal = ec2.amazonaws.com
    │   ├── Action:       sts:AssumeRole
    │   └── Attached:     ec2-read-only-policy
    └── Policy: ec2-read-only-policy
        └── Statement: Effect=Allow, Action=ec2:Describe*, Resource=*
```

---

## Terraform File Responsibilities

| File | Purpose |
|------|---------|
| `versions.tf` | Pins Terraform CLI (`>= 1.5.0`) and AWS provider (`~> 5.0`) versions to ensure reproducible runs |
| `provider.tf` | Configures the AWS provider; region is driven by the `aws_region` variable (default `us-east-1`) — required by the provider even though IAM is a global service |
| `variables.tf` | Declares all input variables; exposes `aws_region`, `role_name`, and `policy_name` to allow configuration without modifying core infrastructure code |
| `main.tf` | Declares the three AWS resources that constitute the IAM baseline: a role, a customer-managed policy, and a policy attachment |
| `outputs.tf` | Exports `iam_role_name`, `iam_role_arn`, and `policy_arn` so downstream modules or CI pipelines can reference these identifiers without hard-coding |

---

## Resource Architecture

The baseline is composed of three tightly scoped Terraform resources. The policy attachment binds the role and policy together, creating an implicit dependency chain that Terraform resolves automatically.

```
aws_iam_role  "ec2_role"
        │
        └── aws_iam_role_policy_attachment  "attach_policy"
                │
                └── aws_iam_policy  "ec2_read_policy"
```

### `aws_iam_role`

The identity resource. Defines who can assume this role via a trust policy (the assume role policy). Named `ec2-baseline-role`, it trusts the EC2 service principal:

| Attribute | Value |
|-----------|-------|
| Name | `ec2-baseline-role` (default, overridable) |
| Trusted principal | `ec2.amazonaws.com` |
| Trust action | `sts:AssumeRole` |
| Policy format | Inline `jsonencode` |

### `aws_iam_policy`

The permissions resource. Defines what the role is allowed to do once assumed. Named `ec2-read-only-policy`:

| Attribute | Value |
|-----------|-------|
| Name | `ec2-read-only-policy` (default, overridable) |
| Description | `Read-only access to EC2 resources` |
| Effect | `Allow` |
| Actions | `ec2:Describe*` |
| Resource scope | `*` |

### `aws_iam_role_policy_attachment`

The binding resource. References both `aws_iam_role.ec2_role.name` and `aws_iam_policy.ec2_read_policy.arn`, establishing an implicit Terraform dependency on both resources. The attachment is created last and destroyed first during `terraform destroy`.

---

## Data Flow

```
Terraform CLI
     │
     │  terraform init / plan / apply
     ▼
AWS Provider (hashicorp/aws ~> 5.0)
     │
     ├── Creates  → aws_iam_role
     │                    │
     ├── Creates  → aws_iam_policy
     │                    │
     └── Creates  → aws_iam_role_policy_attachment
                          │ (binds role + policy)
                          ▼
               IAM Role: ec2-baseline-role
               (with ec2-read-only-policy attached)
                          │
                          ▼
     Outputs: iam_role_name, iam_role_arn, policy_arn
```

---

## Tagging Strategy

IAM roles and policies support tags, but tagging is not implemented at this foundation stage. Resource naming (`ec2-baseline-role`, `ec2-read-only-policy`) is the primary identification mechanism.

For production, consistent tags (`Environment`, `Project`, `ManagedBy`) should be applied via a `tags` block on each resource or enforced account-wide through the `default_tags` block in the provider configuration.

---

## State Management

Terraform state is currently stored locally (`terraform.tfstate`). For team or production use, the state file should be migrated to a remote backend (e.g., S3 + DynamoDB lock table) to prevent concurrent modification and enable state sharing across pipelines.

---

## Region

IAM is a global AWS service — roles and policies exist at the account level and are not scoped to a region. The `aws_region` variable is required by the Terraform AWS provider but does not affect where IAM resources are created. All resources are accessible across all regions in the account.

The region can be overridden at plan or apply time:

```bash
terraform apply -var="aws_region=eu-west-1"
```
