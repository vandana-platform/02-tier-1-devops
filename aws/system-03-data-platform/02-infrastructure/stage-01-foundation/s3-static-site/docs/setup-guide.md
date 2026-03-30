# Setup Guide — S3 Static Site

Step-by-step instructions to deploy, verify, and tear down the S3 Static Site module using Terraform.

This module creates an S3 bucket with static website hosting enabled, all public access block settings disabled, and a bucket policy that grants anonymous read access to all objects. It demonstrates S3-based static content delivery as part of the Tier-1 DevOps Data Platform engineering foundation.

---

## Prerequisites

| Requirement | Version / Notes |
|-------------|----------------|
| Terraform CLI | `>= 1.0` — [install guide](https://developer.hashicorp.com/terraform/install) |
| AWS CLI | `>= 2.x` — [install guide](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) |
| AWS credentials | Configured via `aws configure`, environment variables, or an IAM role |
| IAM permissions | `s3:CreateBucket`, `s3:DeleteBucket`, `s3:PutBucketWebsite`, `s3:GetBucketWebsite`, `s3:PutBucketPolicy`, `s3:GetBucketPolicy`, `s3:DeleteBucketPolicy`, `s3:PutBucketPublicAccessBlock`, `s3:GetBucketPublicAccessBlock`, `s3:PutObject`, `s3:GetObject`, `s3:DeleteObject`, `s3:ListBucket` |

---

## 1. Clone / Navigate to the Project

```bash
cd 02-tier-1-devops/aws/system-03-data-platform/02-infrastructure/stage-01-foundation/s3-static-site
```

---

## 2. Configure AWS Credentials

Verify that the correct AWS account and region are active before proceeding:

```bash
aws configure list
aws sts get-caller-identity
```

Expected output includes your `Account`, `UserId`, and `Arn`:

```json
{
    "UserId": "AIDA...",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/your-user"
}
```

If the output is wrong, re-run `aws configure` or export the appropriate environment variables:

```bash
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-east-1"
```

> Choose a bucket name that is **globally unique** before proceeding. Names must be lowercase, DNS-compliant, and not already in use by any AWS account worldwide.

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

`bucket_name` is a required variable with no default — you must supply it on every plan and apply:

```bash
terraform plan -var="bucket_name=your-company-static-demo-001"
```

Review the plan output carefully. You should see **4 resources to add**:

```
Plan: 4 to add, 0 to change, 0 to destroy.
```

The four resources are:

- `aws_s3_bucket.static_site`
- `aws_s3_bucket_website_configuration.static_site`
- `aws_s3_bucket_public_access_block.static_site`
- `aws_s3_bucket_policy.static_site`

To override the default region or environment tag:

```bash
terraform plan \
  -var="bucket_name=your-company-static-demo-001" \
  -var="environment=foundation" \
  -var="aws_region=us-east-1"
```

To save the plan for use in the apply step:

```bash
terraform plan -out=tfplan -var="bucket_name=your-company-static-demo-001"
```

---

## 6. Apply the Infrastructure

Provisions all four resources in AWS:

```bash
terraform apply -var="bucket_name=your-company-static-demo-001"
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

bucket_name      = "your-company-static-demo-001"
website_endpoint = "your-company-static-demo-001.s3-website-us-east-1.amazonaws.com"
```

---

## 7. Upload Sample Site Content

The website endpoint requires at least an `index.html` object at the bucket root. Without it, requests to the website URL will return a `404` or `403` error:

```bash
echo '<html><body><h1>Hello from S3</h1></body></html>' > /tmp/index.html
echo '<html><body><h1>404 — Page not found</h1></body></html>' > /tmp/error.html

aws s3 cp /tmp/index.html s3://your-company-static-demo-001/index.html
aws s3 cp /tmp/error.html s3://your-company-static-demo-001/error.html
```

---

## 8. Verify the Bucket and Website in AWS

### Via AWS CLI

```bash
BUCKET="your-company-static-demo-001"

# Confirm the bucket exists
aws s3api head-bucket --bucket "$BUCKET"

# Confirm website hosting is enabled and documents are set
aws s3api get-bucket-website \
  --bucket "$BUCKET" \
  --query "{IndexSuffix:IndexDocument.Suffix,ErrorKey:ErrorDocument.Key}" \
  --output table

# Confirm all public access block settings are false
aws s3api get-public-access-block \
  --bucket "$BUCKET" \
  --query "PublicAccessBlockConfiguration" \
  --output table

# Confirm the bucket policy is in place
aws s3api get-bucket-policy \
  --bucket "$BUCKET" \
  --query Policy \
  --output text
```

Fetch the website over HTTP to confirm it is publicly reachable:

```bash
ENDPOINT=$(terraform output -raw website_endpoint)
curl -sS "http://${ENDPOINT}/" | head -5
```

### Via AWS Console

1. Open the [S3 Console](https://s3.console.aws.amazon.com/s3/).
2. Open the bucket with the name matching `var.bucket_name`.
3. Under **Properties**, confirm **Static website hosting** is **Enabled** and shows `index.html` / `error.html`.
4. Under **Permissions**, confirm **Block public access** shows all four settings as **Off**.
5. Under **Permissions → Bucket policy**, confirm the `PublicReadGetObject` statement is present.
6. Click the **Bucket website endpoint** link from the Properties tab to verify the site loads in a browser.

### Via Terraform Output

```bash
terraform output bucket_name
terraform output website_endpoint
```

---

## 9. Review Terraform State

Inspect the local state to confirm all four resources are tracked:

```bash
terraform state list
```

Expected output:

```
aws_s3_bucket.static_site
aws_s3_bucket_policy.static_site
aws_s3_bucket_public_access_block.static_site
aws_s3_bucket_website_configuration.static_site
```

---

## 10. Destroy the Infrastructure

Removes all provisioned resources. **S3 will not delete a non-empty bucket** — empty the bucket before running destroy:

```bash
# Remove all objects first
aws s3 rm s3://your-company-static-demo-001/ --recursive

# Then destroy the infrastructure
terraform destroy -var="bucket_name=your-company-static-demo-001"
```

Terraform will prompt for confirmation:

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

> **Cost control:** S3 charges for storage ($0.023/GB-month for Standard in `us-east-1`), requests, and data transfer out. An empty bucket costs nothing, but objects uploaded during testing will accrue charges. Always destroy unused stacks and empty the bucket to stop all charges. Verify current pricing at [aws.amazon.com/s3/pricing](https://aws.amazon.com/s3/pricing/).

---

## Optional: Targeting a Specific Region or Environment

All commands support the `-var` flag to override defaults:

```bash
terraform apply \
  -var="bucket_name=your-company-static-demo-001" \
  -var="environment=staging" \
  -var="aws_region=eu-west-1"
```

Alternatively, create a `terraform.tfvars` file (Terraform loads it automatically):

```hcl
bucket_name = "your-company-static-demo-001"
environment = "staging"
aws_region  = "eu-west-1"
```
