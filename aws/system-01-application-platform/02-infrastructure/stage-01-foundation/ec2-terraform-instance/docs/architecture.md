# Architecture

## Overview

This project provisions a single Amazon EC2 instance with an associated security group using Terraform. It serves as the **foundation-level compute capability** for the Application Platform (`system-01`, `stage-01-foundation`).

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

## Resource Relationships

| Resource | Type | Depends On |
|---|---|---|
| `ec2_security_group` | `aws_security_group` | — |
| `tier1_ec2_instance` | `aws_instance` | `ec2_security_group` |

---

## Terraform File Layout

| File | Responsibility |
|---|---|
| `versions.tf` | Terraform `>= 1.5.0`, AWS provider `~> 5.0` constraints |
| `provider.tf` | AWS provider region configuration |
| `variables.tf` | Input variables (`aws_region`, `instance_type`) |
| `main.tf` | Security group and EC2 instance resource definitions |
| `outputs.tf` | Exposes `instance_id` and `public_ip` post-apply |

---

## Tagging Strategy

All resources share consistent tags:

| Tag | Value |
|---|---|
| `Name` | Resource-specific name |
| `Environment` | `foundation` |
| `Project` | `tier1-devops-platform` |
