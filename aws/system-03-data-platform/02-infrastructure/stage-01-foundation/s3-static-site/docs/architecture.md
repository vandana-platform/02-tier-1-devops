# Architecture — S3 Static Site

## Overview

This project provisions an Amazon S3 bucket configured for **static website hosting**, with public read access enforced through a bucket policy and relaxed public access block settings. It serves as the **foundation-level static content delivery capability** for the Data Platform (`system-03`, `stage-01-foundation`).

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
AWS Account (us-east-1)
└── S3
    └── Bucket: <var.bucket_name>
        ├── Website configuration
        │   ├── Index document: index.html
        │   └── Error document: error.html
        ├── Public access block
        │   ├── block_public_acls:       false
        │   ├── block_public_policy:     false
        │   ├── ignore_public_acls:      false
        │   └── restrict_public_buckets: false
        └── Bucket policy
            └── Statement: Allow s3:GetObject, Principal "*", Resource <arn>/*
```

---

## Terraform File Responsibilities

| File | Purpose |
|------|---------|
| `versions.tf` | Pins Terraform CLI (`>= 1.0`) and AWS provider (`~> 5.0`) to ensure reproducible runs |
| `provider.tf` | Configures the AWS provider; region is driven by the `aws_region` variable (default `us-east-1`) |
| `variables.tf` | Declares all input variables: `aws_region`, `bucket_name` (required), and `environment` |
| `main.tf` | Declares the four S3 resources that constitute the static site baseline (see below) |
| `outputs.tf` | Exports `bucket_name` and `website_endpoint` so downstream modules and scripts can consume them without hard-coding values |

---

## Resource Architecture

Website hosting and public readability require a precise creation order. The bucket must exist before any child resources are attached; the bucket policy must wait for the public access block to take effect before AWS will accept a public policy statement.

```
aws_s3_bucket  "static_site"
        │
        ├── aws_s3_bucket_website_configuration  "static_site"
        │       └── References bucket.id (implicit dependency)
        │
        ├── aws_s3_bucket_public_access_block  "static_site"
        │       └── References bucket.id (implicit dependency)
        │
        └── aws_s3_bucket_policy  "static_site"
                ├── References bucket.id and bucket.arn (implicit dependency)
                └── depends_on → aws_s3_bucket_public_access_block.static_site
```

### `aws_s3_bucket`

The root storage resource. Its ID and ARN are referenced by all three child resources.

| Attribute | Value |
|-----------|-------|
| Bucket name | `var.bucket_name` |
| Tag: Name | `var.bucket_name` |
| Tag: Environment | `var.environment` |
| Tag: ManagedBy | `terraform` |

### `aws_s3_bucket_website_configuration`

Activates the S3 **website endpoint** (distinct from the REST API endpoint). The website endpoint maps directory-style paths to the index document and serves the error document for missing keys.

| Setting | Value |
|---------|-------|
| Index document suffix | `index.html` |
| Error document key | `error.html` |

### `aws_s3_bucket_public_access_block`

AWS enables public access blocks by default on new buckets to prevent accidental data exposure. All four settings are disabled here to allow the public bucket policy to take effect.

| Setting | Value |
|---------|-------|
| `block_public_acls` | `false` |
| `block_public_policy` | `false` |
| `ignore_public_acls` | `false` |
| `restrict_public_buckets` | `false` |

### `aws_s3_bucket_policy`

Grants unauthenticated `s3:GetObject` on all object keys under the bucket ARN. The `depends_on` ensures the public access block is fully applied before this policy is evaluated by AWS.

| Statement attribute | Value |
|--------------------|-------|
| Sid | `PublicReadGetObject` |
| Effect | `Allow` |
| Principal | `*` |
| Action | `s3:GetObject` |
| Resource | `${aws_s3_bucket.static_site.arn}/*` |

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
                 S3 bucket with website endpoint
                 <bucket>.s3-website-<region>.amazonaws.com
                          │
                          ▼
                 Outputs: bucket_name, website_endpoint
```

---

## Tagging Strategy

Tags are applied at the bucket level in `main.tf`. Child resources (`website_configuration`, `public_access_block`, `bucket_policy`) are not independently taggable — they inherit bucket context.

| Tag | Value |
|-----|-------|
| `Name` | `var.bucket_name` |
| `Environment` | `var.environment` |
| `ManagedBy` | `terraform` |

Tags are used for cost allocation, resource grouping, and environment-scoped automation.

---

## State Management

Terraform state is currently stored locally (`terraform.tfstate`). For team or production use, migrate state to a remote backend (e.g., S3 + DynamoDB lock table) to prevent concurrent modification, enable state sharing across pipelines, and provide durability for the state file itself.

---

## Region

All resources are deployed to `us-east-1` by default. The region is parameterised via `var.aws_region` and can be overridden at plan/apply time:

```bash
terraform apply -var="aws_region=eu-west-1" -var="bucket_name=your-unique-bucket-name"
```

Note: the website endpoint hostname includes the region (e.g., `s3-website-eu-west-1.amazonaws.com`), so the output value will differ from the default.
