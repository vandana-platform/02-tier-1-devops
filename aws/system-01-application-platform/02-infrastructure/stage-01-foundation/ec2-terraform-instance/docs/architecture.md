# Architecture — EC2 Terraform Instance

## Overview

This project provisions a single Amazon EC2 instance with an associated security group using Terraform. It serves as the **foundation-level compute capability** for the Application Platform (`system-01`, `stage-01-foundation`).

```
Tier-1 DevOps
└── system-01-application-platform
    └── 02-infrastructure
        └── stage-01-foundation
            └── ec2-terraform-instance
```

---

## Infrastructure Components

```
AWS Account (us-east-1)
└── Default VPC
    ├── Security Group: tier1-ec2-sg
    │   ├── Inbound:  TCP port 22 (SSH) — 0.0.0.0/0
    │   └── Outbound: All traffic allowed
    └── EC2 Instance: tier1-ec2-instance
        ├── AMI:  ami-0c02fb55956c7d316 (Amazon Linux 2, us-east-1)
        ├── Type: t3.micro
        └── SG:   tier1-ec2-sg
```

---

## Terraform File Responsibilities

| File | Purpose |
|------|---------|
| `versions.tf` | Pins Terraform CLI (`>= 1.5.0`) and AWS provider (`~> 5.0`) versions to ensure reproducible runs |
| `provider.tf` | Configures the AWS provider; region is driven by the `aws_region` variable (default `us-east-1`) |
| `variables.tf` | Declares all input variables; exposes `aws_region` and `instance_type` to allow configuration overrides without modifying core infrastructure code |
| `main.tf` | Declares the two AWS resources that constitute the EC2 baseline: a security group and an EC2 instance (see below) |
| `outputs.tf` | Exports `instance_id` and `public_ip` so downstream modules or CI pipelines can reference the instance without hard-coding its values |

---

## Resource Architecture

The baseline is composed of two tightly scoped Terraform resources. Each resource controls a single concern of the compute layer, following the **separation of concerns** principle.

```
aws_security_group  "ec2_security_group"
        │
        └── aws_instance  "tier1_ec2_instance"
                └── Launched into the Default VPC with the security group attached
```

### `aws_security_group`

Controls network access to the instance. Named `tier1-ec2-sg`, it permits inbound SSH on port 22 and allows all outbound traffic:

| Direction | Protocol | Port | CIDR |
|-----------|----------|------|------|
| Inbound | TCP | 22 (SSH) | `0.0.0.0/0` |
| Outbound | All | All | `0.0.0.0/0` |

### `aws_instance`

The root compute resource. References the security group via `vpc_security_group_ids` and uses the instance type driven by `var.instance_type`:

| Attribute | Value |
|-----------|-------|
| AMI | `ami-0c02fb55956c7d316` (Amazon Linux 2, us-east-1) |
| Instance type | `t3.micro` (default, overridable) |
| Security group | `tier1-ec2-sg` |

---

## Data Flow

```
Terraform CLI
     │
     │  terraform init / plan / apply
     ▼
AWS Provider (hashicorp/aws ~> 5.0)
     │
     ├── Creates  → aws_security_group
     └── Creates  → aws_instance
                          │
                          ▼
                 EC2 Instance (us-east-1)
                 tier1-ec2-instance
                          │
                          ▼
                 Outputs: instance_id, public_ip
```

---

## Tagging Strategy

All resources share a consistent tag set applied at the resource level in `main.tf`:

| Tag | Value |
|-----|-------|
| `Name` | Resource-specific name |
| `Environment` | `foundation` |
| `Project` | `tier1-devops-platform` |

Tags are used for cost allocation, resource grouping, and future policy targeting.

---

## State Management

Terraform state is currently stored locally (`terraform.tfstate`). For team or production use, the state file should be migrated to a remote backend (e.g., S3 + DynamoDB lock table) to prevent concurrent modification and enable state sharing across pipelines.

---

## Region

All resources are deployed to `us-east-1` by default. The region is parameterised via `var.aws_region` and can be overridden at plan/apply time:

```bash
terraform apply -var="aws_region=eu-west-1"
```
