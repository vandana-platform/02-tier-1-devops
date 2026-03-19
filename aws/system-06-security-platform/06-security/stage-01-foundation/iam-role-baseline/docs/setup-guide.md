# Setup Guide — IAM Role Baseline

Step-by-step instructions to deploy, verify, and tear down the IAM Role Baseline using Terraform.

This module provisions an IAM role trusted by the EC2 service, a customer-managed read-only EC2 policy, and a policy attachment in AWS. It demonstrates how identity and permission resources are managed as Infrastructure as Code as part of the Security Platform foundation.

---

## Prerequisites

| Requirement | Version / Notes |
|-------------|----------------|
| Terraform CLI | `>= 1.5.0` — [install guide](https://developer.hashicorp.com/terraform/install) |
| AWS CLI | `>= 2.x` — [install guide](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) |
| AWS credentials | Configured via `aws configure`, environment variables, or an IAM role |
| IAM permissions | `iam:CreateRole`, `iam:DeleteRole`, `iam:GetRole`, `iam:CreatePolicy`, `iam:DeletePolicy`, `iam:GetPolicy`, `iam:GetPolicyVersion`, `iam:AttachRolePolicy`, `iam:DetachRolePolicy`, `iam:ListAttachedRolePolicies` |

---

## 1. Navigate to the Project

Navigate to the module directory:

```bash
cd 02-tier-1-devops/aws/system-06-security-platform/06-security/stage-01-foundation/iam-role-baseline
```

---

## 2. Configure AWS Credentials

Verify that the correct AWS account is active before proceeding:

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

> IAM is a global service — the region set here is used by the Terraform AWS provider but does not determine where the role or policy is created.

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

Review the plan output carefully. You should see **3 resources to add**:

```
Plan: 3 to add, 0 to change, 0 to destroy.
```

The three resources are:

- `aws_iam_role.ec2_role`
- `aws_iam_policy.ec2_read_policy`
- `aws_iam_role_policy_attachment.attach_policy`

To override the default role or policy name:

```bash
terraform plan -var="role_name=dev-ec2-role" -var="policy_name=dev-ec2-read-policy"
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
Apply complete! Resources: 3 added, 0 changed, 0 destroyed.

Outputs:

iam_role_name = "ec2-baseline-role"
iam_role_arn  = "arn:aws:iam::123456789012:role/ec2-baseline-role"
policy_arn    = "arn:aws:iam::123456789012:policy/ec2-read-only-policy"
```

---

## 7. Verify the Resources in AWS

### Via AWS CLI

```bash
# Confirm the IAM role exists and review its trust policy
aws iam get-role \
  --role-name ec2-baseline-role \
  --query "Role.{Name:RoleName,ARN:Arn,Created:CreateDate}" \
  --output table

# Confirm the policy is attached to the role
aws iam list-attached-role-policies \
  --role-name ec2-baseline-role \
  --query "AttachedPolicies[*].{Name:PolicyName,ARN:PolicyArn}" \
  --output table

# Review the policy document
aws iam get-policy-version \
  --policy-arn $(terraform output -raw policy_arn) \
  --version-id v1 \
  --query "PolicyVersion.Document"
```

### Via AWS Console

1. Open the [IAM Console](https://console.aws.amazon.com/iam/home).
2. Navigate to **Roles** and search for `ec2-baseline-role`.
3. Confirm the role exists and the **Trust relationships** tab shows `ec2.amazonaws.com` as the trusted service principal.
4. Select the **Permissions** tab and confirm `ec2-read-only-policy` is listed under attached policies.
5. Navigate to **Policies**, search for `ec2-read-only-policy`, and open the **JSON** tab to review the permission statement.

### Via Terraform Output

```bash
terraform output iam_role_name
terraform output iam_role_arn
terraform output policy_arn
```

---

## 8. Review Terraform State

Inspect the local state to confirm all resources are tracked:

```bash
terraform state list
```

Expected output:

```
aws_iam_policy.ec2_read_policy
aws_iam_role.ec2_role
aws_iam_role_policy_attachment.attach_policy
```

---

## 9. Destroy the Infrastructure

Removes all provisioned resources. **This is irreversible and will delete the IAM role and policy.**

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
Destroy complete! Resources: 3 destroyed.
```

> **Cost control:** IAM roles, policies, and attachments are free — there is no hourly cost. Destroying the stack ensures the account stays clean and avoids hitting IAM quotas (1,000 roles and 1,500 customer-managed policies per account by default).

---

## Optional: Overriding Role and Policy Names

All commands support the `-var` flag to override defaults:

```bash
terraform apply \
  -var="role_name=dev-ec2-role" \
  -var="policy_name=dev-ec2-read-policy"
```

Alternatively, create a `terraform.tfvars` file:

```hcl
role_name   = "dev-ec2-role"
policy_name = "dev-ec2-read-policy"
```
