# S3 Bucket Baseline

Provisions a baseline Amazon S3 bucket using Terraform as part of the **Application Platform infrastructure foundation**.

The purpose of this project is to demonstrate how storage infrastructure can be provisioned and secured using **Infrastructure as Code (IaC)**.

---

## Platform Context

| Field | Value |
|---|---|
| Repository Layer | Tier-1 DevOps Platform Systems |
| Cloud Provider | AWS |
| Platform System | system-01 — Application Platform |
| Capability Layer | 02-infrastructure |
| Infrastructure Stage | stage-01-foundation |

This project represents a **foundation-level storage capability** for the Application Platform.

---

## Resources Created

| Resource | Description |
|---|---|
| `aws_s3_bucket` | Amazon S3 bucket with project tags (`us-east-1`) |
| `aws_s3_bucket_versioning` | Enables object versioning on the bucket |
| `aws_s3_bucket_server_side_encryption_configuration` | Applies AES-256 server-side encryption (SSE-S3) |
| `aws_s3_bucket_public_access_block` | Blocks all public access to the bucket |

---

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) `>= 1.5.0`
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) configured with valid credentials
- AWS provider `~> 5.0`

---

## Project Structure

```
s3-bucket-baseline/
├── versions.tf   # Terraform and provider version constraints
├── provider.tf   # AWS provider configuration
├── variables.tf  # Input variable definitions
├── main.tf       # S3 bucket and security configuration resources
├── outputs.tf    # Output values (bucket name)
└── README.md
```

---

## Input Variables

| Variable | Type | Default | Description |
|---|---|---|---|
| `aws_region` | `string` | `us-east-1` | AWS region for resource deployment |

---

## Terraform Workflow

**Initialize**
```bash
terraform init
```

**Review the execution plan**
```bash
terraform plan
```

**Deploy infrastructure**
```bash
terraform apply
```

**Destroy infrastructure**
```bash
terraform destroy
```

> Destroying infrastructure ensures the environment can be recreated cleanly and prevents unused cloud resources from incurring costs.

---

## Outputs

After a successful `terraform apply`, the following values are returned:

| Output | Description |
|---|---|
| `s3_bucket_name` | The name of the provisioned S3 bucket |

Example:
```
s3_bucket_name = "tier1-platform-baseline-demo-bucket"
```

---

## Troubleshooting

**`BucketAlreadyExists` — bucket name is not globally unique**

S3 bucket names must be globally unique across all AWS accounts. Resolved by updating the bucket name in `main.tf` to use a unique identifier (e.g., appending an account ID or random suffix).

---

## Learning Outcomes

- Infrastructure provisioning with Terraform
- AWS S3 bucket deployment
- Bucket security configuration (versioning, encryption, public access block)
- Terraform lifecycle management (`init` → `plan` → `apply` → `destroy`)
- Troubleshooting S3 naming constraints
- Verifying infrastructure via AWS CLI and AWS Console
