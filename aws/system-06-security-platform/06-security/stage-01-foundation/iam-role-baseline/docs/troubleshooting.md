# Troubleshooting — IAM Role Baseline

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

### `AccessDenied` on IAM Operations

**Symptom:**

```
Error: creating IAM Role: AccessDenied: User: arn:aws:iam::123456789012:user/developer
  is not authorized to perform: iam:CreateRole on resource: *
```

**Cause:** The IAM identity executing Terraform lacks the required IAM permissions.

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
       "iam:CreateRole",
       "iam:DeleteRole",
       "iam:GetRole",
       "iam:CreatePolicy",
       "iam:DeletePolicy",
       "iam:GetPolicy",
       "iam:GetPolicyVersion",
       "iam:AttachRolePolicy",
       "iam:DetachRolePolicy",
       "iam:ListAttachedRolePolicies"
     ],
     "Resource": "*"
   }
   ```

---

### `ExpiredToken` or `InvalidClientTokenId`

**Symptom:**

```
Error: operation error IAM: CreateRole, ..., ExpiredTokenException
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

## 3. IAM Resource Creation Failures

### `EntityAlreadyExists` — IAM Role Already Exists

**Symptom:**

```
Error: creating IAM Role (ec2-baseline-role): EntityAlreadyExists:
  Role with name ec2-baseline-role already exists.
```

**Cause:** An IAM role with the same name exists in the account but is not tracked in Terraform state (e.g., created manually or from a previous partial apply).

**Fix:** Import the existing role into Terraform state:
```bash
terraform import aws_iam_role.ec2_role ec2-baseline-role
```

Or use a different role name to avoid the conflict:
```bash
terraform apply -var="role_name=ec2-baseline-role-v2"
```

---

### `EntityAlreadyExists` — IAM Policy Already Exists

**Symptom:**

```
Error: creating IAM Policy (ec2-read-only-policy): EntityAlreadyExists:
  A policy called ec2-read-only-policy already exists. Duplicate names are not allowed.
```

**Cause:** A customer-managed policy with the same name exists in the account and is not tracked in Terraform state.

**Fix:** Find the policy ARN and import it into state:
```bash
# Find the policy ARN
aws iam list-policies \
  --scope Local \
  --query "Policies[?PolicyName=='ec2-read-only-policy'].Arn" \
  --output text

# Import into Terraform state
terraform import aws_iam_policy.ec2_read_policy <policy-arn>
```

---

### `MalformedPolicyDocument` — Invalid Trust Policy JSON

**Symptom:**

```
Error: creating IAM Role: MalformedPolicyDocument:
  This policy contains invalid Json
```

**Cause:** The `assume_role_policy` JSON is malformed. This can occur if `jsonencode` is used incorrectly or if the HCL map structure does not produce valid JSON.

**Fix:** Validate the policy document locally before applying:
```bash
terraform plan | grep -A 20 assume_role_policy
```

Ensure the trust policy structure in `main.tf` is correct:
```hcl
assume_role_policy = jsonencode({
  Version = "2012-10-17"
  Statement = [
    {
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }
  ]
})
```

---

### `LimitExceeded` — IAM Role or Policy Quota Reached

**Symptom:**

```
Error: creating IAM Role: LimitExceeded: Cannot exceed quota for RolesPerAccount: 1000
```

**Cause:** The AWS account has reached the default IAM quota for roles (1,000) or customer-managed policies (1,500).

**Fix:**
1. Check current usage against quota:
   ```bash
   aws iam get-account-summary \
     --query "SummaryMap.{Roles:Roles,RoleQuota:RolesQuota,Policies:Policies,PolicyQuota:PoliciesQuota}"
   ```
2. Delete unused roles or policies to free up quota, or request a quota increase via AWS Service Quotas:
   ```bash
   aws service-quotas request-service-quota-increase \
     --service-code iam \
     --quota-code L-FE177D64 \
     --desired-value 2000
   ```

---

## 4. Policy Attachment Issues

### `NoSuchEntity` on Policy Attachment

**Symptom:**

```
Error: attaching IAM Policy to IAM Role: NoSuchEntityException:
  Policy arn:aws:iam::123456789012:policy/ec2-read-only-policy does not exist or is not attachable.
```

**Cause:** The policy ARN referenced in the attachment does not match the policy that was created, or the policy was deleted between apply steps.

**Fix:**
1. Confirm the policy exists:
   ```bash
   aws iam get-policy \
     --policy-arn $(terraform output -raw policy_arn)
   ```
2. Refresh state to sync with the live account:
   ```bash
   terraform apply -refresh-only
   ```
3. Re-apply to recreate any missing resources:
   ```bash
   terraform apply
   ```

---

### Policy Manually Detached — Drift on Attachment Resource

**Symptom:**

```
Error: detaching IAM Policy from IAM Role: NoSuchEntityException:
  Policy is not attached to role
```

**Cause:** The policy was manually detached from the role outside of Terraform, but Terraform state still records the attachment.

**Fix:** Refresh state to detect the drift, then re-apply to restore the attachment:
```bash
terraform apply -refresh-only
terraform apply
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
- If the IAM resources still exist in AWS, re-import all three resources:
  ```bash
  # Import the role
  terraform import aws_iam_role.ec2_role ec2-baseline-role

  # Find the policy ARN
  POLICY_ARN=$(aws iam list-policies --scope Local \
    --query "Policies[?PolicyName=='ec2-read-only-policy'].Arn" \
    --output text)

  # Import the policy
  terraform import aws_iam_policy.ec2_read_policy $POLICY_ARN

  # Import the attachment (format: role-name/policy-arn)
  terraform import aws_iam_role_policy_attachment.attach_policy \
    ec2-baseline-role/$POLICY_ARN
  ```
- If a backup exists, restore it:
  ```bash
  cp terraform.tfstate.backup terraform.tfstate
  ```

---

### Resource already exists in AWS but not in state

**Symptom:** `terraform plan` shows resources will be created, but the apply fails with an `EntityAlreadyExists` error.

**Cause:** Resources were created outside of Terraform or from a previous run that lost its state file.

**Fix:** Import all three resources before re-applying:
```bash
# Import the role
terraform import aws_iam_role.ec2_role ec2-baseline-role

# Import the policy
POLICY_ARN=$(aws iam list-policies --scope Local \
  --query "Policies[?PolicyName=='ec2-read-only-policy'].Arn" \
  --output text)
terraform import aws_iam_policy.ec2_read_policy $POLICY_ARN

# Import the attachment
terraform import aws_iam_role_policy_attachment.attach_policy \
  ec2-baseline-role/$POLICY_ARN
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

**Cause:** The installed Terraform binary is older than `>= 1.5.0` as required by `versions.tf`.

**Fix:** Upgrade Terraform:
```bash
# Using tfenv (recommended)
tfenv install 1.9.0
tfenv use 1.9.0

# Verify
terraform version
```

---

### `Unsupported argument` — IAM Resource Attribute Renamed

**Symptom:**

```
Error: Unsupported argument
An argument named "permissions_boundary_arn" is not expected here.
```

**Cause:** Certain IAM resource arguments were renamed or moved between AWS provider versions.

**Fix:** Check the [AWS provider changelog](https://github.com/hashicorp/terraform-provider-aws/blob/main/CHANGELOG.md) for the relevant breaking change and update the resource block. Verify your provider version:
```bash
terraform version
terraform providers
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
