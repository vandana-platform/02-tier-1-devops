# Architecture — CloudWatch Baseline

## Overview

This project provisions a CloudWatch Log Group and a CPU utilisation metric alarm using Terraform. It serves as the **foundation-level observability capability** for the Observability Platform (`system-05`, `stage-01-foundation`).

```
Tier-1 DevOps
└── system-05-observability-platform
    └── 02-infrastructure
        └── stage-01-foundation
            └── cloudwatch-baseline
```

---

## Infrastructure Components

```
AWS Account (us-east-1)
└── CloudWatch (regional service)
    ├── Log Group: /platform/application
    │   ├── Retention:  7 days
    │   └── Tags:       Environment=dev, ManagedBy=terraform
    └── Metric Alarm: dev-high-cpu
        ├── Namespace:   AWS/EC2
        ├── Metric:      CPUUtilization
        ├── Statistic:   Average
        ├── Threshold:   > 80%
        ├── Period:      120 seconds
        ├── Evaluations: 2 consecutive periods
        └── Tags:        Environment=dev, ManagedBy=terraform
```

---

## Terraform File Responsibilities

| File | Purpose |
|------|---------|
| `versions.tf` | Pins Terraform CLI (`>= 1.0`) and AWS provider (`~> 5.0`) versions to ensure reproducible runs |
| `provider.tf` | Configures the AWS provider; region is driven by the `aws_region` variable (default `us-east-1`) |
| `variables.tf` | Declares all input variables; exposes `aws_region`, `environment`, `log_group_name`, and `retention_days` to allow configuration overrides without modifying core infrastructure code |
| `main.tf` | Declares the two AWS resources that constitute the CloudWatch baseline: a log group and a metric alarm (see below) |
| `outputs.tf` | Exports `log_group_name`, `log_group_arn`, and `alarm_name` so downstream modules or CI pipelines can reference the observability resources without hard-coding their values |

---

## Resource Architecture

The baseline is composed of two independently scoped Terraform resources. Each resource controls a single concern of the observability layer, following the **separation of concerns** principle.

```
aws_cloudwatch_log_group  "platform"
        │
        │   (independent — no direct Terraform dependency)
        │
aws_cloudwatch_metric_alarm  "high_cpu"
        └── Monitors AWS/EC2 CPUUtilization across the account
```

### `aws_cloudwatch_log_group`

Stores application and platform log streams. Named `/platform/application`, it enforces a 7-day retention policy so log data is automatically purged after the configured window:

| Attribute | Value |
|-----------|-------|
| Name | `/platform/application` (default, overridable) |
| Retention | `7` days (default, overridable) |
| Tags | `Environment`, `ManagedBy=terraform` |

### `aws_cloudwatch_metric_alarm`

Monitors EC2 CPU utilisation across the account. The alarm evaluates the average `CPUUtilization` metric in the `AWS/EC2` namespace over two consecutive 2-minute periods and transitions to `ALARM` state when the value exceeds 80%:

| Attribute | Value |
|-----------|-------|
| Alarm name | `${var.environment}-high-cpu` (e.g., `dev-high-cpu`) |
| Namespace | `AWS/EC2` |
| Metric | `CPUUtilization` |
| Statistic | `Average` |
| Threshold | `80` (%) |
| Comparison | `GreaterThanThreshold` |
| Period | `120` seconds |
| Evaluation periods | `2` |
| Tags | `Environment`, `ManagedBy=terraform` |

---

## Data Flow

```
Terraform CLI
     │
     │  terraform init / plan / apply
     ▼
AWS Provider (hashicorp/aws ~> 5.0)
     │
     ├── Creates  → aws_cloudwatch_log_group
     │                    │
     │                    ▼
     │           Log Group: /platform/application
     │           (receives log streams from application agents)
     │
     └── Creates  → aws_cloudwatch_metric_alarm
                          │
                          ▼
                 Evaluates AWS/EC2 CPUUtilization
                 every 120s across the account
                          │
                          ▼
                 Outputs: log_group_name, log_group_arn, alarm_name
```

---

## Tagging Strategy

All resources share a consistent tag set applied at the resource level in `main.tf`:

| Tag | Value |
|-----|-------|
| `Environment` | Driven by `var.environment` (default `dev`) |
| `ManagedBy` | `terraform` |

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
