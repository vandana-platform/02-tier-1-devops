# Architecture — S3 Static Site

## Overview

This project provisions a single Amazon S3 bucket configured for **static website hosting**, with public read access enforced through the bucket policy and relaxed public access block settings. It serves as a **foundation-level static content capability** for the Data Platform (`system-03`, `stage-01-foundation`).

```
Tier-1 DevOps
└── system-03-data-platform
    └── 02-infrastructure
        └── stage-01-foundation
            └── s3-static-site
```

---

## Infrastructure Components

```
AWS Account (region from var.aws_region, default us-east-1)
└── S3
    └── Bucket: <var.bucket_name>
        ├── Website configuration
        │   ├── Index document: index.html
        │   └── Error document: error.html
        ├── Public access block: all four settings = false (allows public ACLs/policy)
        └── Bucket policy: Allow s3:GetObject, Principal "*", Resource "arn:aws:s3:::bucket/*"
```

---

## Terraform File Responsibilities

| File | Purpose |
|------|---------|
| `versions.tf` | Pins Terraform CLI (`>= 1.0`) and AWS provider (`~> 5.0`) for reproducible runs |
| `provider.tf` | Configures the AWS provider; region is driven by the `aws_region` variable (default `us-east-1`) |
| `variables.tf` | Declares `aws_region`, `bucket_name`, and `environment` for configuration without editing resource blocks |
| `main.tf` | Declares the four S3 resources: bucket, website configuration, public access block, and bucket policy |
| `outputs.tf` | Exports `bucket_name` and `website_endpoint` for callers, scripts, and documentation |

---

## Resource Architecture

Website hosting and public readability depend on a **fixed order**: the bucket must exist before website settings, public access block, and policy; the bucket policy explicitly `depends_on` the public access block so AWS accepts a public policy after block settings are applied.

```
aws_s3_bucket  "static_site"
        │
        ├── aws_s3_bucket_website_configuration  "static_site"
        │
        ├── aws_s3_bucket_public_access_block  "static_site"
        │           │
        │           └── (must complete before public policy)
        │
        └── aws_s3_bucket_policy  "static_site"
                    └── depends_on → aws_s3_bucket_public_access_block.static_site
```

### `aws_s3_bucket`

The storage resource. Name comes from `var.bucket_name`; tags include `Name`, `Environment`, and `ManagedBy`.

| Attribute | Value / source |
|-----------|----------------|
| Bucket name | `var.bucket_name` |
| Tags | `Name`, `Environment`, `ManagedBy = "terraform"` |

### `aws_s3_bucket_website_configuration`

Enables the **website endpoint** (distinct from the S3 REST endpoint).

| Setting | Value |
|---------|--------|
| Index suffix | `index.html` |
| Error document key | `error.html` |

### `aws_s3_bucket_public_access_block`

AWS defaults new buckets toward blocking public access. For this foundation module, all four flags are `false` so a public bucket policy is allowed.

| Setting | Value |
|---------|--------|
| `block_public_acls` | `false` |
| `block_public_policy` | `false` |
| `ignore_public_acls` | `false` |
| `restrict_public_buckets` | `false` |

### `aws_s3_bucket_policy`

JSON policy allowing anonymous `s3:GetObject` on object keys under the bucket ARN. `Principal` is `"*"` (any caller).

| Statement | Effect | Action | Resource |
|-----------|--------|--------|----------|
| PublicReadGetObject | Allow | `s3:GetObject` | `arn:aws:s3:::<bucket>/*` |

---

## Data Flow

```
Terraform CLI
     │
     │  terraform init / plan / apply
     ▼
AWS Provider (hashicorp/aws ~> 5.0)
     │
     ├── Creates  → aws_s3_bucket
     ├── Creates  → aws_s3_bucket_website_configuration
     ├── Creates  → aws_s3_bucket_public_access_block
     └── Creates  → aws_s3_bucket_policy
                          │
                          ▼
                 S3 bucket (website endpoint URL)
                          │
                          ▼
                 Outputs: bucket_name, website_endpoint
```

---

## Tagging Strategy

Tags are applied on the bucket in `main.tf`:

| Tag | Value |
|-----|-------|
| `Name` | `var.bucket_name` |
| `Environment` | `var.environment` |
| `ManagedBy` | `terraform` |

Tags support cost allocation, inventory, and future automation that scopes resources by environment.

---

## State Management

Terraform state is currently stored locally (`terraform.tfstate`). For team or production use, migrate state to a remote backend (for example S3 with a DynamoDB lock table) to avoid concurrent updates and to share state with CI pipelines.

---

## Region

Resources are created in `us-east-1` by default. Override at plan/apply time:

```bash
terraform apply -var="aws_region=eu-west-1" -var="bucket_name=your-globally-unique-name"
```

Remember: the **website endpoint hostname** includes the region (for example `s3-website-eu-west-1.amazonaws.com`).
