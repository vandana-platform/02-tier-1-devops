# Setup Guide — S3 Static Site

Step-by-step instructions to deploy, verify, and tear down the S3 Static Site module using Terraform.

This module creates an S3 bucket with static website hosting enabled and a public read policy. It demonstrates object storage as web hosting within the Tier-1 DevOps Data Platform foundation.

---

## Prerequisites

| Requirement | Version / Notes |
|-------------|----------------|
| Terraform CLI | `>= 1.0` — [install guide](https://developer.hashicorp.com/terraform/install) |
| AWS CLI | `>= 2.x` — [install guide](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) |
| AWS credentials | Configured via `aws configure`, environment variables, or an IAM role |
| IAM permissions (typical) | `s3:CreateBucket`, `s3:DeleteBucket`, `s3:PutBucketWebsite`, `s3:GetBucketWebsite`, `s3:PutBucketPolicy`, `s3:GetBucketPolicy`, `s3:DeleteBucketPolicy`, `s3:PutBucketPublicAccessBlock`, `s3:GetBucketPublicAccessBlock`, `s3:PutObject`, `s3:GetObject`, `s3:ListBucket`, `s3:DeleteObject` (for uploads and emptying before destroy) |

---

## 1. Clone / Navigate to the Project

```bash
cd 02-tier-1-devops/aws/system-03-data-platform/02-infrastructure/stage-01-foundation/s3-static-site
```

---

## 2. Configure AWS Credentials

Verify that the correct AWS account and region are active:

```bash
aws configure list
aws sts get-caller-identity
```

Expected output from `get-caller-identity` includes `Account`, `UserId`, and `Arn`:

```json
{
    "UserId": "AIDA...",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/..."
}
```

If the identity is wrong, re-run `aws configure` or set environment variables:

```bash
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-east-1"
```

> Choose a bucket name that is **globally unique** before the next steps. Names must be DNS-compliant and not already taken.

---

## 3. Initialize Terraform

Downloads the AWS provider plugin and sets up the working directory:

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

> If provider installation fails, check network access to `https://registry.terraform.io` or configure registry mirrors.

---

## 4. Validate the Configuration

```bash
terraform validate
```

Expected output:

```
Success! The configuration is valid.
```

---

## 5. Review the Execution Plan

You must supply `bucket_name` (required variable with no default):

```bash
terraform plan -var="bucket_name=your-company-demo-static-001"
```

Review the plan. You should see **4 resources to add**:

```
Plan: 4 to add, 0 to change, 0 to destroy.
```

The resources are:

- `aws_s3_bucket.static_site`
- `aws_s3_bucket_website_configuration.static_site`
- `aws_s3_bucket_public_access_block.static_site`
- `aws_s3_bucket_policy.static_site`

Optional: set environment and region:

```bash
terraform plan \
  -var="bucket_name=your-company-demo-static-001" \
  -var="environment=foundation" \
  -var="aws_region=us-east-1"
```

Save a plan file:

```bash
terraform plan -out=tfplan -var="bucket_name=your-company-demo-static-001"
```

---

## 6. Apply the Infrastructure

```bash
terraform apply -var="bucket_name=your-company-demo-static-001"
```

Terraform prompts for confirmation:

```
Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes
```

Non-interactive apply with a saved plan:

```bash
terraform apply tfplan
```

Expected output (values will differ):

```
Apply complete! Resources: 4 added, 0 changed, 0 destroyed.

Outputs:

bucket_name = "your-company-demo-static-001"
website_endpoint = "your-company-demo-static-001.s3-website-us-east-1.amazonaws.com"
```

---

## 7. Upload Sample Site Objects (Optional but Recommended)

The website configuration expects `index.html` at the bucket root. Without objects, the endpoint may return errors when you browse:

```bash
echo '<html><body><h1>Hello from S3</h1></body></html>' > index.html
echo '<html><body><h1>Error</h1></body></html>' > error.html

aws s3 cp index.html s3://your-company-demo-static-001/index.html
aws s3 cp error.html s3://your-company-demo-static-001/error.html
```

---

## 8. Verify the Bucket and Website in AWS

### Via AWS CLI

```bash
BUCKET="your-company-demo-static-001"

aws s3api head-bucket --bucket "$BUCKET"

aws s3api get-bucket-website --bucket "$BUCKET" \
  --query "{Index:IndexDocument,Error:ErrorDocument}" \
  --output json

aws s3api get-public-access-block --bucket "$BUCKET" \
  --query "{BlockPublicAcls:PublicAccessBlockConfiguration.BlockPublicAcls,BlockPublicPolicy:PublicAccessBlockConfiguration.BlockPublicPolicy}" \
  --output table

terraform output -raw website_endpoint
```

Fetch the home page over HTTP (use `http://`, not `https://` for the raw website endpoint):

```bash
ENDPOINT=$(terraform output -raw website_endpoint)
curl -sS "http://${ENDPOINT}/" | head -5
```

### Via AWS Console

1. Open the [S3 console](https://s3.console.aws.amazon.com/s3/).
2. Open the bucket named like your `bucket_name`.
3. Under **Properties**, confirm **Static website hosting** is enabled and shows `index.html` / `error.html`.
4. Under **Permissions**, review **Bucket policy** and **Block public access** (all off for this module).
5. Open the **Bucket website endpoint** link if shown, or build the URL from the website endpoint output.

### Via Terraform Output

```bash
terraform output bucket_name
terraform output website_endpoint
```

---

## 9. Review Terraform State

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

Removes managed resources. **If the bucket contains objects, destroy may fail** until the bucket is empty (S3 does not delete non-empty buckets by default in this configuration).

```bash
# Empty the bucket first if you uploaded test objects
aws s3 rm s3://your-company-demo-static-001/ --recursive

terraform destroy -var="bucket_name=your-company-demo-static-001"
```

Confirm when prompted:

```
Do you really want to destroy all resources?
  Only 'yes' will be accepted to confirm.

  Enter a value: yes
```

Expected output:

```
Destroy complete! Resources: 4 destroyed.
```

> **Cost control:** S3 charges for storage, requests, and data transfer. For a tiny demo bucket, monthly cost is usually **cents** or less; standard storage in `us-east-1` is on the order of **$0.023 per GB-month** (pricing changes — verify current [S3 pricing](https://aws.amazon.com/s3/pricing/)). Destroying the bucket stops ongoing storage charges for those objects.

---

## Optional: Variable Overrides and `terraform.tfvars`

CLI overrides:

```bash
terraform apply \
  -var="bucket_name=my-unique-bucket" \
  -var="environment=staging" \
  -var="aws_region=eu-west-1"
```

Example `terraform.tfvars` (do not commit secrets; bucket name is still non-secret but unique):

```hcl
bucket_name = "my-unique-bucket"
environment = "foundation"
aws_region  = "us-east-1"
```

Apply with:

```bash
terraform apply
```

Terraform auto-loads `terraform.tfvars` when present in the working directory.
