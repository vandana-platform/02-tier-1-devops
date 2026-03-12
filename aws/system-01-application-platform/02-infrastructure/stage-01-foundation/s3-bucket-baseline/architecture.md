# Architecture — S3 Bucket Baseline

## Overview

This module provisions a secure, versioned S3 bucket as part of the foundational infrastructure layer for the Tier-1 AWS Application Platform. It sits at **stage-01-foundation**, establishing a compliant storage baseline that subsequent platform stages can build upon.

---

## Repository Structure

```
Tier-1 DevOps
└── system-01-application-platform
    └── 02-infrastructure
        └── stage-01-foundation
            └── s3-bucket-baseline
```

---

## Infrastructure Components

```
AWS Account (us-east-1)
└── S3 Bucket: tier1-platform-baseline-demo-bucket
    ├── Versioning: Enabled
    ├── Encryption: AES-256 (SSE-S3)
    └── Public Access Block: All four vectors blocked
```

---

## Terraform File Responsibilities

| File | Purpose |
|------|---------|
| `versions.tf` | Pins Terraform CLI (`>= 1.5.0`) and AWS provider (`~> 5.0`) versions to ensure reproducible runs |
| `provider.tf` | Configures the AWS provider; region is driven by the `aws_region` variable (default `us-east-1`) |
| `variables.tf` | Declares all input variables; currently exposes `aws_region` to allow region overrides without code changes |
| `main.tf` | Declares the four AWS resources that constitute the S3 baseline (see below) |
| `outputs.tf` | Exports `s3_bucket_name` so downstream modules or CI pipelines can reference the bucket without hard-coding its name |

---

## Resource Architecture

The baseline is composed of four tightly scoped Terraform resources. Each resource controls a single concern of the bucket, following the **separation of concerns** principle introduced in AWS provider v4+.

```
aws_s3_bucket  "platform_baseline_bucket"
        │
        ├── aws_s3_bucket_versioning
        │       └── Retains all object versions; enables recovery and audit
        │
        ├── aws_s3_bucket_server_side_encryption_configuration
        │       └── Enforces AES-256 (SSE-S3) encryption at rest for every object
        │
        └── aws_s3_bucket_public_access_block
                └── Blocks all four public-access vectors at the bucket level
```

### `aws_s3_bucket`

The root resource. Declares the bucket name (`tier1-platform-baseline-demo-bucket`).

### `aws_s3_bucket_versioning`

Attached to the bucket via `bucket = aws_s3_bucket.platform_baseline_bucket.id`. Sets `versioning_configuration.status = "Enabled"`. Once enabled, every `PUT` and `DELETE` operation creates a new object version rather than overwriting or permanently deleting the current one.

### `aws_s3_bucket_server_side_encryption_configuration`

Configures a default encryption rule using the `aws:kms` or `AES256` algorithm. All objects uploaded without an explicit encryption header inherit this rule automatically. No client-side changes are required.

### `aws_s3_bucket_public_access_block`

Sets all four block flags to `true`:

| Flag | Effect |
|------|--------|
| `block_public_acls` | Rejects `PUT` requests that include a public ACL |
| `ignore_public_acls` | Ignores any existing public ACLs on the bucket or objects |
| `block_public_policy` | Rejects bucket policies that grant public access |
| `restrict_public_buckets` | Restricts access to principals within the AWS account |

---

## Data Flow

```
Terraform CLI
     │
     │  terraform init / plan / apply
     ▼
AWS Provider (hashicorp/aws ~> 5.0)
     │
     ├── Creates    → aws_s3_bucket
     ├── Configures → aws_s3_bucket_versioning
     ├── Configures → aws_s3_bucket_server_side_encryption_configuration
     └── Configures → aws_s3_bucket_public_access_block
                              │
                              ▼
                     S3 Bucket (us-east-1)
                     tier1-platform-baseline-demo-bucket
                              │
                              ▼
                     Output: s3_bucket_name
```

---

## Tagging Strategy

All resources share consistent tags applied to `aws_s3_bucket`:

| Tag | Value |
|-----|-------|
| `Name` | `tier1-platform-baseline` |
| `Environment` | `foundation` |
| `Project` | `tier1-devops-platform` |

Tags are used for cost allocation, resource grouping, and future policy targeting.

---

## State Management

Terraform state is currently stored locally (`terraform.tfstate`). For team or production use, the state file should be migrated to a remote backend (e.g., S3 + DynamoDB lock table) to prevent concurrent modification and enable state sharing across pipelines.

---

## Region

All resources are deployed to `us-east-1` by default. The region is parameterised via `var.aws_region` and can be overridden at plan/apply time:

```bash
terraform apply -var="aws_region=eu-west-1"
```
