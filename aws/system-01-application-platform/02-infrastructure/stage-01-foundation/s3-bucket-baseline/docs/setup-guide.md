# Setup Guide — S3 Bucket Baseline

Step-by-step instructions to deploy, verify, and tear down the S3 Bucket Baseline using Terraform.

---

## Prerequisites

| Requirement | Version / Notes |
|-------------|----------------|
| Terraform CLI | `>= 1.5.0` — [install guide](https://developer.hashicorp.com/terraform/install) |
| AWS CLI | `>= 2.x` — [install guide](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) |
| AWS credentials | Configured via `aws configure`, environment variables, or an IAM role |
| IAM permissions | `s3:CreateBucket`, `s3:PutBucketVersioning`, `s3:PutEncryptionConfiguration`, `s3:PutBucketPublicAccessBlock`, `s3:DeleteBucket` |

---

## 1. Clone / Navigate to the Project

```bash
cd 02-tier-1-devops/aws/system-01-application-platform/02-infrastructure/stage-01-foundation/s3-bucket-baseline
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

Review the plan output carefully. You should see **4 resources to add**:

```
Plan: 4 to add, 0 to change, 0 to destroy.
```

The four resources are:
- `aws_s3_bucket.platform_baseline_bucket`
- `aws_s3_bucket_versioning.platform_baseline_versioning`
- `aws_s3_bucket_server_side_encryption_configuration.platform_baseline_encryption`
- `aws_s3_bucket_public_access_block.platform_baseline_public_access`

To override the default region:

```bash
terraform plan -var="aws_region=eu-west-1"
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
Apply complete! Resources: 4 added, 0 changed, 0 destroyed.

Outputs:

s3_bucket_name = "tier1-platform-baseline-demo-bucket"
```

---

## 7. Verify the Bucket in AWS

### Via AWS CLI

```bash
# Confirm the bucket exists
aws s3 ls | grep tier1-platform-baseline-demo-bucket

# Check versioning status
aws s3api get-bucket-versioning \
  --bucket tier1-platform-baseline-demo-bucket

# Check encryption configuration
aws s3api get-bucket-encryption \
  --bucket tier1-platform-baseline-demo-bucket

# Check public access block settings
aws s3api get-public-access-block \
  --bucket tier1-platform-baseline-demo-bucket
```

### Via AWS Console

1. Open the [S3 Console](https://s3.console.aws.amazon.com/s3/home).
2. Search for `tier1-platform-baseline-demo-bucket`.
3. Navigate to the **Properties** tab to verify versioning and encryption.
4. Navigate to the **Permissions** tab and confirm "Block all public access" shows **On**.

### Via Terraform Output

```bash
terraform output s3_bucket_name
```

---

## 8. Review Terraform State

Inspect the local state to confirm all resources are tracked:

```bash
terraform state list
```

Expected output:

```
aws_s3_bucket.platform_baseline_bucket
aws_s3_bucket_public_access_block.platform_baseline_public_access
aws_s3_bucket_server_side_encryption_configuration.platform_baseline_encryption
aws_s3_bucket_versioning.platform_baseline_versioning
```

---

## 9. Destroy the Infrastructure

Removes all provisioned resources. **This is irreversible for any objects stored in the bucket.**

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
Destroy complete! Resources: 4 destroyed.
```

> **Note:** Terraform cannot destroy a versioned bucket that contains objects. Empty and delete all object versions first, or set `force_destroy = true` on the `aws_s3_bucket` resource before running destroy.

---

## Optional: Targeting a Specific Region

All commands support the `-var` flag to override the default region:

```bash
terraform apply -var="aws_region=ap-southeast-1"
```

Alternatively, create a `terraform.tfvars` file:

```hcl
aws_region = "ap-southeast-1"
```
