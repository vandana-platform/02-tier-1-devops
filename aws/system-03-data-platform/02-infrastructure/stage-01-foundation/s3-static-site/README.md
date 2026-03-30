# S3 Static Site

Provisions an Amazon S3 bucket configured for **static website hosting** as part of the **Data Platform infrastructure foundation**.

The purpose of this project is to demonstrate how object storage can serve static content over HTTP using **Infrastructure as Code (IaC)**, including bucket policy authoring, public access configuration, and resource dependency ordering with `depends_on`.

---

## Platform Context

| Field | Value |
|---|---|
| Repository Layer | Tier-1 DevOps Platform Systems |
| Cloud Provider | AWS |
| Platform System | system-03 — Data Platform |
| Capability Layer | 02-infrastructure |
| Infrastructure Stage | stage-01-foundation |

This project represents a **foundation-level static content delivery capability** for the Data Platform.

---

## Resources Created

| Resource | Description |
|---|---|
| `aws_s3_bucket` | S3 bucket named via `var.bucket_name` (`us-east-1`) |
| `aws_s3_bucket_website_configuration` | Enables static website hosting with `index.html` as the index document and `error.html` as the error document |
| `aws_s3_bucket_public_access_block` | Disables all four public access block settings to allow public object reads |
| `aws_s3_bucket_policy` | Grants anonymous `s3:GetObject` to all objects in the bucket |

---

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) `>= 1.0`
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) configured with valid credentials
- AWS provider `~> 5.0`
- A **globally unique** S3 bucket name (bucket names are shared across all AWS accounts and regions)

---

## Project Structure

```
s3-static-site/
├── versions.tf   # Terraform and provider version constraints
├── provider.tf   # AWS provider configuration
├── variables.tf  # Input variable definitions
├── main.tf       # S3 bucket, website configuration, public access block, and bucket policy
├── outputs.tf    # Output values (bucket_name, website_endpoint)
└── README.md
```

---

## Input Variables

| Variable | Type | Default | Description |
|---|---|---|---|
| `aws_region` | `string` | `us-east-1` | AWS region for resource deployment |
| `bucket_name` | `string` | *(required)* | Globally unique S3 bucket name for the static site |
| `environment` | `string` | `dev` | Environment name applied as a resource tag |

---

## Terraform Workflow

**Initialize**
```bash
terraform init
```

**Review the execution plan**
```bash
terraform plan -var="bucket_name=your-unique-bucket-name"
```

**Deploy infrastructure**
```bash
terraform apply -var="bucket_name=your-unique-bucket-name"
```

**Destroy infrastructure**
```bash
terraform destroy -var="bucket_name=your-unique-bucket-name"
```

> Destroying infrastructure removes the bucket and all associated configuration. **Empty the bucket before running destroy** — S3 will not delete a non-empty bucket and `terraform destroy` will fail with `BucketNotEmpty`. Always destroy unused stacks to prevent ongoing S3 storage and request charges.

---

## Outputs

After a successful `terraform apply`, the following values are returned:

| Output | Description |
|---|---|
| `bucket_name` | The name of the provisioned S3 bucket |
| `website_endpoint` | The S3 static website endpoint URL |

Example:
```
bucket_name      = "my-demo-static-site-12345"
website_endpoint = "my-demo-static-site-12345.s3-website-us-east-1.amazonaws.com"
```

---

## Troubleshooting

**`BucketAlreadyExists` — bucket name taken globally**

S3 bucket names are globally unique across all AWS accounts and regions. Choose a name that includes a project prefix, account ID, or random suffix to avoid collisions with other accounts.

**`AccessDenied` when attaching the bucket policy**

The public access block must be fully applied before the bucket policy is evaluated. The module enforces this with `depends_on`, but if a previous apply was interrupted mid-run, re-run `terraform apply` to complete the sequence. Also confirm the IAM identity has `s3:PutBucketPolicy` and `s3:PutBucketPublicAccessBlock` permissions.

**`BucketNotEmpty` during `terraform destroy`**

Terraform cannot delete an S3 bucket that contains objects. Run `aws s3 rm s3://BUCKET_NAME/ --recursive` before retrying `terraform destroy`.

---

## Learning Outcomes

- S3 static website hosting configuration with Terraform
- Relationship between public access block settings, bucket policy, and the website endpoint
- Bucket policy authoring using `jsonencode` in HCL
- Terraform resource dependency ordering with `depends_on`
- Terraform lifecycle management (`init` → `plan` → `apply` → `destroy`)
- Verifying infrastructure via AWS CLI, AWS Console, and Terraform output
