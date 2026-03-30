# S3 Static Site

Hosts a static website using **Amazon S3 static website hosting** with a bucket policy that allows public read access to objects. Terraform provisions the bucket, website configuration, public access settings, and IAM policy in a single module.

The purpose of this project is to demonstrate how **object storage** can serve static content over HTTP as part of the **Data Platform infrastructure foundation**, using **Infrastructure as Code (IaC)**.

---

## Platform Context

| Field | Value |
|---|---|
| Repository Layer | Tier-1 DevOps Platform Systems |
| Cloud Provider | AWS |
| Platform System | system-03 — Data Platform |
| Capability Layer | 02-infrastructure |
| Infrastructure Stage | stage-01-foundation |

This project represents a **foundation-level static content capability** for the Data Platform.

---

## Resources Created

| Resource | Description |
|---|---|
| `aws_s3_bucket` | S3 bucket named via `bucket_name`; tagged with environment and ownership |
| `aws_s3_bucket_website_configuration` | Static website: `index.html` as index, `error.html` as error document |
| `aws_s3_bucket_public_access_block` | All public access block settings set to `false` so the bucket can be public |
| `aws_s3_bucket_policy` | Allows `s3:GetObject` for all principals on `arn:.../*` (public read of objects) |

---

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) `>= 1.0` (per `versions.tf`)
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) configured with valid credentials
- AWS provider `~> 5.0`
- A **globally unique** S3 bucket name (S3 bucket names are global across all AWS accounts)

---

## Project Structure

```
s3-static-site/
├── versions.tf   # Terraform and provider version constraints
├── provider.tf   # AWS provider configuration
├── variables.tf  # Input variable definitions
├── main.tf       # S3 bucket, website, public access block, bucket policy
├── outputs.tf    # Output values (bucket name, website endpoint)
└── README.md
```

---

## Input Variables

| Variable | Type | Default | Description |
|---|---|---|---|
| `aws_region` | `string` | `us-east-1` | AWS region for resource deployment |
| `bucket_name` | `string` | *(required)* | Globally unique S3 bucket name for the static site |
| `environment` | `string` | `dev` | Environment name (stored in tags) |

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

> Destroying infrastructure removes the bucket and its configuration. If the bucket still contains objects, `terraform destroy` may fail until the bucket is empty or you add force-destroy behaviour. After destroy, you avoid ongoing S3 storage and request charges for that bucket.

---

## Outputs

After a successful `terraform apply`, the following values are returned:

| Output | Description |
|---|---|
| `bucket_name` | The S3 bucket name (same as `var.bucket_name` after create) |
| `website_endpoint` | The S3 website endpoint hostname (e.g. `bucket-name.s3-website-us-east-1.amazonaws.com`) |

Example:
```
bucket_name       = "my-demo-static-site-12345"
website_endpoint  = "my-demo-static-site-12345.s3-website-us-east-1.amazonaws.com"
```

---

## Troubleshooting

**`BucketAlreadyExists` — bucket name taken globally**

The chosen `bucket_name` is already owned by another AWS account or region configuration. Pick a different globally unique name and pass it with `-var="bucket_name=..."`.

**`AccessDenied` when applying bucket policy**

The IAM principal running Terraform needs `s3:PutBucketPolicy`, `s3:GetBucketPolicy`, and related bucket management permissions. Confirm with `aws sts get-caller-identity` and attach an appropriate policy.

**Website URL returns 404 after upload**

The website endpoint serves objects at the root of the bucket; ensure `index.html` exists at the bucket root and that you are using the **website endpoint** (not the REST API endpoint `s3.amazonaws.com`).

---

## Learning Outcomes

- Infrastructure provisioning with Terraform for S3 static website hosting
- Relationship between `aws_s3_bucket`, website configuration, public access block, and bucket policy
- Why bucket policies and public access block must align for a public static site
- Terraform lifecycle management (`init` → `plan` → `apply` → `destroy`)
- Verifying a static site via AWS CLI, Console, and `terraform output`
