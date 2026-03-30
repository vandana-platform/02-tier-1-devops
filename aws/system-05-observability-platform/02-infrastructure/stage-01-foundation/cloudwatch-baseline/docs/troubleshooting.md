# Troubleshooting — CloudWatch Baseline

Common issues encountered when working with this Terraform module and their solutions.

---

## 1. Terraform Initialization Errors

### `Failed to install provider`

**Symptom:**

```
Error: Failed to install provider
Could not retrieve the list of available versions for provider hashicorp/aws.
```

**Cause:** No internet access, or a corporate proxy is blocking the Terraform Registry.

**Fix:**
- Verify connectivity: `curl -I https://registry.terraform.io`
- If behind a proxy, set the proxy environment variables:
  ```bash
  export HTTPS_PROXY=http://proxy.example.com:8080
  export HTTP_PROXY=http://proxy.example.com:8080
  ```
- Alternatively, use a locally mirrored provider with `terraform init -plugin-dir=/path/to/providers`.

---

### `Lock file conflict after provider upgrade`

**Symptom:**

```
Error: Inconsistent dependency lock file
The lock file does not contain a suitable checksum for provider "hashicorp/aws".
```

**Cause:** The `.terraform.lock.hcl` file was committed with checksums for a different OS or architecture.

**Fix:**
```bash
terraform providers lock \
  -platform=linux_amd64 \
  -platform=darwin_amd64 \
  -platform=windows_amd64 \
  registry.terraform.io/hashicorp/aws
```

---

## 2. AWS Permission Errors

### `AuthFailure` — Invalid AWS Credentials

**Symptom:**

```
Error: configuring Terraform AWS Provider: no valid credential sources found
```

**Cause:** Terraform cannot locate valid AWS credentials. This occurs when no credentials file, environment variables, or IAM role are configured.

**Fix:**
```bash
aws configure
aws sts get-caller-identity  # verify credentials are active
```

Ensure one of the following credential sources is available:
- `~/.aws/credentials` with a valid profile
- `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` environment variables
- An attached IAM instance profile (if running on EC2)

---

### `ExpiredToken` or `InvalidClientTokenId`

**Symptom:**

```
Error: operation error CloudWatch Logs: ..., ExpiredTokenException
```

**Cause:** Temporary credentials (STS / SSO session) have expired.

**Fix:**
```bash
# For AWS SSO
aws sso login --profile <profile-name>

# For MFA-based sessions, re-generate the token
aws sts get-session-token --serial-number arn:aws:iam::ACCOUNT:mfa/USER --token-code 123456
```

---

### `AccessDenied` on CloudWatch or Logs operations

**Symptom:**

```
Error: creating CloudWatch Log Group: AccessDeniedException: User is not authorized
to perform: logs:CreateLogGroup on resource: arn:aws:logs:us-east-1:...
```

**Cause:** The IAM identity executing Terraform lacks the required CloudWatch Logs or CloudWatch permissions.

**Fix:**
1. Confirm which identity is in use:
   ```bash
   aws sts get-caller-identity
   ```
2. Attach or inline a policy that includes at minimum:
   ```json
   {
     "Effect": "Allow",
     "Action": [
       "logs:CreateLogGroup",
       "logs:DeleteLogGroup",
       "logs:DescribeLogGroups",
       "logs:PutRetentionPolicy",
       "cloudwatch:PutMetricAlarm",
       "cloudwatch:DeleteAlarms",
       "cloudwatch:DescribeAlarms"
     ],
     "Resource": "*"
   }
   ```

---

## 3. CloudWatch Log Group Errors

### `ResourceAlreadyExistsException` — Log Group Already Exists

**Symptom:**

```
Error: creating CloudWatch Log Group (/platform/application):
ResourceAlreadyExistsException: The specified log group already exists
```

**Cause:** A log group with the same name exists in the account and region but is not tracked in Terraform state (e.g., created manually or from a previous partial apply).

**Fix:** Import the existing log group into Terraform state:
```bash
terraform import aws_cloudwatch_log_group.platform /platform/application
```

Or delete the orphaned log group if it has no data worth preserving:
```bash
aws logs delete-log-group --log-group-name /platform/application
terraform apply
```

---

### `InvalidParameterInput` — Invalid Retention Period

**Symptom:**

```
Error: updating CloudWatch Log Group (/platform/application) Retention Policy:
InvalidParameterException: The following retention policy is not valid:
Invalid value for retentionInDays specified: 10
```

**Cause:** CloudWatch Logs only accepts a specific set of allowed retention values. `10` is not in the allowed list.

**Fix:** Update `retention_days` in `variables.tf` or pass it at apply time to one of the accepted values:

```bash
terraform apply -var="retention_days=14"
```

Accepted values: `1`, `3`, `5`, `7`, `14`, `30`, `60`, `90`, `120`, `150`, `180`, `365`, `400`, `545`, `731`, `1096`, `1827`, `2192`, `2557`, `2922`, `3288`, `3653`.

---

### Log Group Created but Retention Not Applied

**Symptom:** The log group exists in the CloudWatch Console but shows **Never expire** as the retention policy instead of the configured value.

**Cause:** The `retention_in_days` update failed silently due to an eventual-consistency delay, or a subsequent manual console change overrode the Terraform-managed setting.

**Fix:** Run a targeted apply to force the retention policy to be re-applied:
```bash
terraform apply -target=aws_cloudwatch_log_group.platform
```

Verify the result:
```bash
aws logs describe-log-groups \
  --log-group-name-prefix "/platform/application" \
  --query "logGroups[*].{Name:logGroupName,Retention:retentionInDays}" \
  --output table
```

---

## 4. CloudWatch Metric Alarm Errors

### `InvalidParameterInput` — Invalid Alarm Period

**Symptom:**

```
Error: creating CloudWatch Metric Alarm (dev-high-cpu): ValidationError:
The value of Period must be 10, 30, or a multiple of 60.
```

**Cause:** The `period` attribute must be `10`, `30`, or a multiple of `60`. A value like `90` or `100` is rejected.

**Fix:** Update the `period` value in `main.tf` to a valid option:
```hcl
period = 120  # 2 minutes — multiple of 60
```

---

### Alarm Stuck in `INSUFFICIENT_DATA` State

**Symptom:** After apply, the alarm shows `INSUFFICIENT_DATA` in the CloudWatch Console and never transitions.

**Cause:** The `AWS/EC2 CPUUtilization` metric has no data because no EC2 instances are running in the account, or because no `dimensions` filter is set to a specific instance emitting the metric.

**Fix:** This is expected behaviour when no EC2 instances are running. The alarm will transition to `OK` or `ALARM` once instances emit `CPUUtilization` data into the `AWS/EC2` namespace. To verify the alarm configuration is correct:
```bash
aws cloudwatch describe-alarms \
  --alarm-names "dev-high-cpu" \
  --query "MetricAlarms[*].{State:StateValue,Reason:StateReason}" \
  --output table
```

To test alarm evaluation manually with synthetic data:
```bash
aws cloudwatch put-metric-data \
  --namespace "AWS/EC2" \
  --metric-name "CPUUtilization" \
  --value 90 \
  --unit Percent
```

---

### Alarm Name Conflict

**Symptom:**

```
Error: creating CloudWatch Metric Alarm (dev-high-cpu): InvalidParameterInput:
Alarm dev-high-cpu already exists.
```

**Cause:** An alarm with the same name exists in the account and region but is not tracked in Terraform state.

**Fix:** Import the existing alarm into Terraform state:
```bash
terraform import aws_cloudwatch_metric_alarm.high_cpu dev-high-cpu
```

Verify the import succeeded:
```bash
terraform plan  # should show no changes if the remote resource matches the config
```

---

## 5. Terraform State Problems

### State file missing or corrupted

**Symptom:**

```
Error: No state file was found!
```

or Terraform plans to recreate resources that already exist in AWS.

**Cause:** `terraform.tfstate` was deleted, moved, or corrupted.

**Fix:**
- If the resources still exist in AWS, re-import each resource:
  ```bash
  terraform import aws_cloudwatch_log_group.platform /platform/application
  terraform import aws_cloudwatch_metric_alarm.high_cpu dev-high-cpu
  ```
- If a backup exists, restore it:
  ```bash
  cp terraform.tfstate.backup terraform.tfstate
  ```

---

### Resource already exists in AWS but not in state

**Symptom:** `terraform plan` shows resources will be created, but the apply fails with a duplicate resource error.

**Cause:** Resources were created outside of Terraform (manually or from a previous run that lost its state file).

**Fix:** Import the orphaned resources into state before re-applying:
```bash
# Log group
terraform import aws_cloudwatch_log_group.platform /platform/application

# Metric alarm
terraform import aws_cloudwatch_metric_alarm.high_cpu dev-high-cpu
```

Then run `terraform plan` to confirm the state matches the live infrastructure before applying further changes.

---

## 6. Provider Version Issues

### `Required Terraform version not met`

**Symptom:**

```
Error: Unsupported Terraform Core version
This configuration does not support Terraform version X.Y.Z.
```

**Cause:** The installed Terraform binary is older than `>= 1.0` as required by `versions.tf`.

**Fix:** Upgrade Terraform:
```bash
# Using tfenv (recommended)
tfenv install 1.9.0
tfenv use 1.9.0

# Verify
terraform version
```

---

## 7. Outputs Not Visible After Apply

**Symptom:** After a successful `terraform apply`, no output values are printed.

**Cause:** Outputs are only printed when they change. If the infrastructure already existed and no changes were made, outputs may not be re-displayed.

**Fix:** Query outputs explicitly:
```bash
terraform output
```

Or refresh state without making changes:
```bash
terraform apply -refresh-only
```

---

## Issues Faced During Implementation

*This section documents real issues encountered while building this module as a personal reference.*

<!-- To be completed -->
