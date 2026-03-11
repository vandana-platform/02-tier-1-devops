# EC2 Terraform Instance

Provisions a basic Amazon EC2 instance using Terraform as part of the **Application Platform infrastructure foundation**.

The purpose of this project is to demonstrate how compute infrastructure can be provisioned and managed using **Infrastructure as Code (IaC)**.

---

## Platform Context

| Field | Value |
|---|---|
| Repository Layer | Tier-1 DevOps Platform Systems |
| Cloud Provider | AWS |
| Platform System | system-01 — Application Platform |
| Capability Layer | 02-infrastructure |
| Infrastructure Stage | stage-01-foundation |

This project represents a **foundation-level compute capability** for the Application Platform.

---

## Resources Created

| Resource | Description |
|---|---|
| `aws_instance` | Amazon EC2 instance (`t3.micro`, `us-east-1`) |
| `aws_security_group` | Security group allowing inbound SSH (port 22) and all outbound traffic |

---

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) `>= 1.5.0`
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) configured with valid credentials
- AWS provider `~> 5.0`

---

## Project Structure

```
ec2-terraform-instance/
├── versions.tf   # Terraform and provider version constraints
├── provider.tf   # AWS provider configuration
├── variables.tf  # Input variable definitions
├── main.tf       # EC2 instance and security group resources
├── outputs.tf    # Output values (instance ID, public IP)
└── README.md
```

---

## Input Variables

| Variable | Type | Default | Description |
|---|---|---|---|
| `aws_region` | `string` | `us-east-1` | AWS region for resource deployment |
| `instance_type` | `string` | `t3.micro` | EC2 instance type |

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

> Destroying infrastructure ensures the environment can be recreated cleanly and prevents unused cloud resources from incurring costs.

---

## Outputs

After a successful `terraform apply`, the following values are returned:

| Output | Description |
|---|---|
| `instance_id` | The ID of the provisioned EC2 instance |
| `public_ip` | The public IP address of the instance |

Example:
```
instance_id = "i-07e76ca4a6776b7c7"
public_ip   = "44.210.102.31"
```

---

## Troubleshooting

**`InvalidParameterCombination` — instance type not eligible for Free Tier**

The selected EC2 instance type was not Free Tier eligible. Resolved by updating the instance type to `t3.micro` in `variables.tf`.

---

## Learning Outcomes

- Infrastructure provisioning with Terraform
- AWS EC2 instance deployment
- Security group configuration
- Terraform lifecycle management (`init` → `plan` → `apply` → `destroy`)
- Troubleshooting cloud provisioning errors
- Verifying infrastructure via AWS CLI and AWS Console
