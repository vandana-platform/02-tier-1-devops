# Setup Guide — CloudWatch Baseline

Step-by-step instructions to deploy, verify, and tear down the CloudWatch Baseline using Terraform.

This module provisions a CloudWatch Log Group with a 7-day retention policy and a CPU utilisation metric alarm in AWS. It demonstrates foundation-level observability infrastructure provisioning as part of the Tier-1 DevOps platform engineering foundation.

---

## Prerequisites

| Requirement | Version / Notes |
|-------------|----------------|
| Terraform CLI | `>= 1.0` — [install guide](https://developer.hashicorp.com/terraform/install) |
| AWS CLI | `>= 2.x` — [install guide](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) |
| AWS credentials | Configured via `aws configure`, environment variables, or an IAM role |
| IAM permissions | `logs:CreateLogGroup`, `logs:DeleteLogGroup`, `logs:DescribeLogGroups`, `logs:PutRetentionPolicy`, `cloudwatch:PutMetricAlarm`, `cloudwatch:DeleteAlarms`, `cloudwatch:DescribeAlarms` |

---

## 1. Clone / Navigate to the Project

```bash
cd 02-tier-1-devops/aws/system-05-observability-platform/02-infrastructure/stage-01-foundation/cloudwatch-baseline
```

---

## 2. Configure AWS Credentials

Verify that the correct AWS account and region are active before proceeding:

```bash
aws configure list
aws sts get-caller-identity
```

Expected output includes your `Account`, `UserId`, and `Arn`. If the output is wrong, re-run `aws configure` or export the appropriate environment variables:

```bash
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-east-1"
```

---

## 3. Initialize Terraform

Downloads the AWS provider plugin and sets up the local backend:

```bash
terraform init
```

Expected output:

```
Initializing the backend...
Initializing provider plugins...
- Finding hashicorp/aws versions matching "~> 5.0"...
- Installing hashicorp/aws v5.x.x...

Terraform has been successfully initialized!
```

> If you see provider download errors, check your internet connection or configure a private Terraform registry mirror.

---

## 4. Validate the Configuration

Checks syntax and internal consistency without contacting AWS:

```bash
terraform validate
```

Expected output:

```
Success! The configuration is valid.
```

---

## 5. Review the Execution Plan

Generates a diff of what Terraform will create, change, or destroy:

```bash
terraform plan
```

Review the plan output carefully. You should see **2 resources to add**:

```
Plan: 2 to add, 0 to change, 0 to destroy.
```

The two resources are:

- `aws_cloudwatch_log_group.platform`
- `aws_cloudwatch_metric_alarm.high_cpu`

To override the default environment or log group name:

```bash
terraform plan -var="environment=staging" -var="log_group_name=/platform/staging"
```

To save the plan for use in the apply step:

```bash
terraform plan -out=tfplan
```

---

## 6. Apply the Infrastructure

Provisions all resources in AWS:

```bash
terraform apply
```

Terraform will display the plan again and prompt for confirmation:

```
Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes
```

Type `yes` and press Enter.

To apply a saved plan without an interactive prompt (useful in CI/CD):

```bash
terraform apply tfplan
```

Expected output after completion:

```
Apply complete! Resources: 2 added, 0 changed, 0 destroyed.

Outputs:

log_group_name = "/platform/application"
log_group_arn  = "arn:aws:logs:us-east-1:123456789012:log-group:/platform/application"
alarm_name     = "dev-high-cpu"
```

---

## 7. Verify the Resources in AWS

### Via AWS CLI

```bash
# Confirm the log group exists and check its retention setting
aws logs describe-log-groups \
  --log-group-name-prefix "/platform/application" \
  --query "logGroups[*].{Name:logGroupName,Retention:retentionInDays,ARN:arn}" \
  --output table

# Confirm the metric alarm exists and check its state
aws cloudwatch describe-alarms \
  --alarm-names "dev-high-cpu" \
  --query "MetricAlarms[*].{Name:AlarmName,State:StateValue,Threshold:Threshold,Metric:MetricName}" \
  --output table
```

### Via AWS Console

1. Open the [CloudWatch Console](https://console.aws.amazon.com/cloudwatch/home).
2. Navigate to **Log groups** and confirm `/platform/application` appears with a **7 day** retention policy.
3. Navigate to **Alarms → All alarms** and confirm `dev-high-cpu` is listed.
4. Click the alarm to verify: metric `CPUUtilization`, namespace `AWS/EC2`, threshold `> 80`, evaluation periods `2`.

### Via Terraform Output

```bash
terraform output log_group_name
terraform output log_group_arn
terraform output alarm_name
```

---

## 8. Review Terraform State

Inspect the local state to confirm all resources are tracked:

```bash
terraform state list
```

Expected output:

```
aws_cloudwatch_log_group.platform
aws_cloudwatch_metric_alarm.high_cpu
```

---

## 9. Destroy the Infrastructure

Removes all provisioned resources. **This is irreversible and will delete the log group and any stored log data.**

```bash
terraform destroy
```

Terraform will display the destroy plan and prompt for confirmation:

```
Do you really want to destroy all resources?
  Terraform will destroy all your managed infrastructure, as shown above.
  There is no undo. Only 'yes' will be accepted to confirm.

  Enter a value: yes
```

Expected output:

```
Destroy complete! Resources: 2 destroyed.
```

> **Cost control:** CloudWatch Log Groups incur charges for ingested and stored log data ($0.50/GB ingested, $0.03/GB/month archived in `us-east-1`). CloudWatch metric alarms cost $0.10/alarm/month after the free tier (10 alarms). Always destroy this stack when it is no longer needed to avoid unexpected AWS costs.

---

## Optional: Targeting a Specific Environment or Log Group

All commands support the `-var` flag to override defaults:

```bash
terraform apply \
  -var="environment=prod" \
  -var="log_group_name=/platform/prod" \
  -var="retention_days=90"
```

Alternatively, create a `terraform.tfvars` file:

```hcl
environment    = "prod"
log_group_name = "/platform/prod"
retention_days = 90
```
