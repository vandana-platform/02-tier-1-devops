# CloudWatch Baseline

Provisions a foundational Amazon CloudWatch observability stack using Terraform as part of the **Observability Platform infrastructure foundation**.

The purpose of this project is to demonstrate how monitoring infrastructure — log ingestion and metric-based alerting — can be provisioned and managed using **Infrastructure as Code (IaC)**.

---

## Platform Context

| Field | Value |
|---|---|
| Repository Layer | Tier-1 DevOps Platform Systems |
| Cloud Provider | AWS |
| Platform System | system-05 — Observability Platform |
| Capability Layer | 02-infrastructure |
| Infrastructure Stage | stage-01-foundation |

This project represents a **foundation-level observability capability** for the Observability Platform.

---

## Resources Created

| Resource | Description |
|---|---|
| `aws_cloudwatch_log_group` | CloudWatch Log Group (`/platform/application`, 7-day retention, `us-east-1`) |
| `aws_cloudwatch_metric_alarm` | Metric alarm that triggers when EC2 average CPU exceeds 80% for two consecutive 2-minute periods |

---

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) `>= 1.0`
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) configured with valid credentials
- AWS provider `~> 5.0`

---

## Project Structure

```
cloudwatch-baseline/
├── versions.tf   # Terraform and provider version constraints
├── provider.tf   # AWS provider configuration
├── variables.tf  # Input variable definitions
├── main.tf       # CloudWatch log group and metric alarm resources
├── outputs.tf    # Output values (log group name, ARN, alarm name)
└── README.md
```

---

## Input Variables

| Variable | Type | Default | Description |
|---|---|---|---|
| `aws_region` | `string` | `us-east-1` | AWS region for resource deployment |
| `environment` | `string` | `dev` | Environment name (used in resource naming and tags) |
| `log_group_name` | `string` | `/platform/application` | CloudWatch log group name |
| `retention_days` | `number` | `7` | Number of days log data is retained before automatic deletion |

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

> Destroying infrastructure ensures the environment can be recreated cleanly and prevents unused cloud resources from incurring costs. CloudWatch Log Groups with stored log data may incur charges until destroyed.

---

## Outputs

After a successful `terraform apply`, the following values are returned:

| Output | Description |
|---|---|
| `log_group_name` | The name of the provisioned CloudWatch Log Group |
| `log_group_arn` | The ARN of the provisioned CloudWatch Log Group |
| `alarm_name` | The name of the provisioned CloudWatch metric alarm |

Example:
```
log_group_name = "/platform/application"
log_group_arn  = "arn:aws:logs:us-east-1:123456789012:log-group:/platform/application"
alarm_name     = "dev-high-cpu"
```

---

## Troubleshooting

**`ResourceAlreadyExistsException` — Log Group already exists**

A log group with the same name exists in the account but is not tracked in Terraform state. Import it with `terraform import aws_cloudwatch_log_group.platform /platform/application` or destroy the orphaned group via the AWS CLI before applying.

**`InvalidParameterInput` — Invalid retention period**

CloudWatch only accepts specific retention values. Valid options are `1`, `3`, `5`, `7`, `14`, `30`, `60`, `90`, `120`, `150`, `180`, `365`, `400`, `545`, `731`, `1096`, `1827`, `2192`, `2557`, `2922`, `3288`, and `3653`. Update `retention_days` in `variables.tf` to one of these values.

---

## Learning Outcomes

- Observability infrastructure provisioning with Terraform
- AWS CloudWatch Log Group creation and retention configuration
- AWS CloudWatch metric alarm setup for EC2 CPU monitoring
- Terraform lifecycle management (`init` → `plan` → `apply` → `destroy`)
- Verifying observability resources via AWS CLI and AWS Console
- Troubleshooting CloudWatch provisioning errors
