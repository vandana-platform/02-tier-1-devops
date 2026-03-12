# Interview Questions — S3 Bucket Baseline

DevOps-level interview questions covering the concepts demonstrated in this project. Questions are grouped by topic and progress from foundational to advanced.

---

## Terraform Core Concepts

**Q1. What is the purpose of `terraform init` and what does it do under the hood?**

`terraform init` initialises the working directory by downloading provider plugins defined in `versions.tf`, setting up the backend, and creating the `.terraform.lock.hcl` file. It must be run before any other Terraform command. The lock file pins exact provider binary checksums so that every subsequent `init` on any machine installs the identical provider version.

---

**Q2. What is the difference between `terraform plan` and `terraform apply`?**

`terraform plan` performs a dry run — it reads current state and queries the AWS API to compute what changes would be made, but makes no modifications. `terraform apply` executes those changes. Running `plan -out=tfplan` followed by `apply tfplan` guarantees that exactly what was reviewed gets applied, which is critical in CI/CD pipelines.

---

**Q3. What does `~> 5.0` mean in the AWS provider version constraint?**

The `~>` (pessimistic constraint) operator allows only patch and minor version upgrades within the specified minor version. `~> 5.0` permits `5.0.x`, `5.1.x`, `5.99.x`, but not `6.0.0`. This prevents breaking changes from a major version bump while still receiving bug fixes automatically.

---

**Q4. What is the `.terraform.lock.hcl` file and should it be committed to version control?**

It records the exact provider versions and SHA-256 checksums selected by `terraform init`. **Yes, it should be committed.** Committing it ensures all developers and CI pipelines use the identical provider binary, preventing "works on my machine" issues caused by provider version drift.

---

**Q5. What is Terraform state and why is it important?**

Terraform state (`terraform.tfstate`) maps your configuration resources to real-world infrastructure. Terraform uses it to determine what exists, what needs to change, and what should be destroyed. Without state, Terraform cannot track drift or perform incremental updates — it would attempt to recreate all resources on every apply.

---

**Q6. Why is it recommended to use a remote backend for Terraform state in a team environment?**

A local state file cannot be shared, provides no locking (allowing two engineers to apply simultaneously and corrupt state), and is lost if the machine is destroyed. A remote backend — such as S3 + DynamoDB — solves all three: state is centralised, DynamoDB provides distributed locking, and S3 provides durability and versioning for the state file itself.

---

**Q7. What is `terraform output` used for?**

It reads and displays the values declared in `outputs.tf` from the current state file. Outputs allow downstream Terraform modules, CI/CD pipelines, or application configuration scripts to consume infrastructure values (such as a bucket name or ARN) without hard-coding them.

---

## S3 Bucket Provisioning

**Q8. Why does the project use four separate Terraform resources instead of a single `aws_s3_bucket` block with inline sub-resources?**

AWS provider v4 deprecated inline sub-resource blocks (e.g., `versioning {}`, `server_side_encryption_configuration {}`) to resolve configuration conflicts when the same bucket is managed by multiple configurations. Separate resources follow the single-responsibility principle, allow Terraform to plan each concern independently, and produce cleaner pull request diffs.

---

**Q9. How does Terraform know the order in which to create the four S3 resources?**

Through implicit dependencies. `aws_s3_bucket_versioning`, `aws_s3_bucket_server_side_encryption_configuration`, and `aws_s3_bucket_public_access_block` all reference `aws_s3_bucket.platform_baseline_bucket.id`. Terraform builds a dependency graph and ensures the base bucket is created first before applying the sub-configurations.

---

**Q10. What is the `force_destroy` attribute on `aws_s3_bucket` and when would you use it?**

`force_destroy = true` instructs Terraform to delete all objects (including all versions and delete markers) before destroying the bucket. Without it, Terraform will fail to destroy a non-empty bucket. It is appropriate in non-production or demo environments but should be absent in production to prevent accidental data loss.

---

## Bucket Versioning

**Q11. What does enabling S3 versioning mean for object storage behaviour?**

Once enabled, every `PUT` operation creates a new version of the object rather than overwriting it. A `DELETE` operation inserts a delete marker instead of permanently removing the object. All previous versions remain accessible by specifying the `VersionId`. Versioning cannot be fully disabled once enabled — it can only be suspended, which stops creating new versions but retains existing ones.

---

**Q12. What are the storage cost implications of enabling versioning, and how can they be managed?**

Every version of every object consumes storage and incurs costs. Over time, accumulated versions can significantly increase the bill. This is managed via **S3 Lifecycle policies** that expire non-current versions after a defined number of days or limit the number of retained non-current versions.

---

**Q13. What is the difference between versioning `Enabled`, `Suspended`, and never-enabled?**

| State | Behaviour |
|-------|-----------|
| Never enabled | Single version per key; overwrites and deletes are permanent |
| Enabled | All versions retained; deletes create delete markers |
| Suspended | No new versions created; existing versions remain; new objects get a `null` version ID |

---

## Server-Side Encryption

**Q14. What is the difference between SSE-S3, SSE-KMS, and SSE-C?**

| Type | Key management | Use case |
|------|---------------|---------|
| SSE-S3 (AES-256) | AWS manages keys entirely | General baseline; no compliance key requirements |
| SSE-KMS | AWS KMS manages CMKs; customer controls key policy | Audit trails, cross-account access, HIPAA/PCI |
| SSE-C | Customer provides key per request | Customer retains full key ownership; no AWS key storage |

---

**Q15. If a bucket has a default encryption rule set, what happens when a client uploads an object with a different encryption header?**

The client-specified header takes precedence. The default encryption rule applies only when no encryption header is included in the `PUT` request. This means a well-configured application can use SSE-KMS with a specific CMK even if the bucket default is SSE-S3.

---

**Q16. Does enabling server-side encryption affect how you read objects from S3?**

No. Decryption is transparent — S3 decrypts the object automatically when it is downloaded by an authorised principal. The client does not need to provide a decryption key (for SSE-S3 and SSE-KMS). Only SSE-C requires the client to supply the key on every read request.

---

## Public Access Block

**Q17. What are the four public access block settings and what does each one control?**

| Setting | Controls |
|---------|---------|
| `block_public_acls` | Rejects PUT requests that include a public ACL on the bucket or its objects |
| `ignore_public_acls` | Makes S3 ignore any existing public ACLs; does not remove them |
| `block_public_policy` | Prevents bucket policies that grant public access |
| `restrict_public_buckets` | Blocks public and cross-account access to the bucket when a public policy is in effect |

---

**Q18. Can you still grant cross-account access to a bucket with all four public access block settings enabled?**

Yes. The public access block settings restrict **public** (anonymous internet) access, not all cross-account access. An explicit bucket policy or IAM policy that grants access to a specific AWS account or IAM principal in another account will still function normally. Only policies that use `"Principal": "*"` (wildcard) are blocked.

---

**Q19. At what levels can the public access block be configured in AWS?**

It can be configured at two levels:
1. **Account level** — applies to all buckets in the account via the S3 Console "Block Public Access" account setting.
2. **Bucket level** — applies to a specific bucket, as provisioned by `aws_s3_bucket_public_access_block`.

Bucket-level settings can be more restrictive than the account-level setting but cannot be more permissive.

---

## Infrastructure Best Practices

**Q20. What is infrastructure as code (IaC) and why is Terraform preferred for AWS over writing CloudFormation directly?**

IaC means declaring infrastructure in version-controlled configuration files rather than clicking through consoles. Terraform is provider-agnostic (supports AWS, Azure, GCP, and hundreds of others), uses a declarative HCL syntax that is generally considered more readable than CloudFormation JSON/YAML, supports a plan/apply workflow that CloudFormation lacks, and has a large ecosystem of community modules.

---

**Q21. What is configuration drift and how does Terraform detect and correct it?**

Drift occurs when the actual state of a resource in AWS diverges from what is recorded in Terraform state — typically caused by manual console changes. `terraform plan` detects drift by comparing the desired configuration against a live AWS API refresh. Running `terraform apply` corrects drift by bringing the real resource back into alignment with the configuration.

---

**Q22. What is the AWS Well-Architected Framework Security Pillar principle most relevant to this project?**

**"Protect data at rest"** — enforced here through SSE encryption, bucket versioning (enables recovery from destructive operations), and the public access block (prevents unauthorised data exposure). The principle also calls for controlling who has access via IAM, which would be the natural next security layer to add.

---

**Q23. How would you promote this S3 baseline configuration to a reusable Terraform module?**

Extract the resources into a `modules/s3-baseline/` directory, expose input variables for the bucket name, region, tags, and optional KMS key ARN, and output the bucket ID and ARN. Callers instantiate the module with:

```hcl
module "app_bucket" {
  source      = "../../modules/s3-baseline"
  bucket_name = "my-app-bucket"
  aws_region  = "us-east-1"
}
```

This allows the same security baseline to be applied consistently across all buckets in the platform without duplicating resource definitions.

---

**Q24. What is the principle of least privilege and how should it be applied to S3 bucket access?**

Grant only the minimum IAM permissions necessary for a given role or service to perform its function. For an S3 bucket, this means scoping policies to specific actions (`s3:GetObject` for readers, `s3:PutObject` for writers), specific resources (bucket ARN + object prefix), and specific conditions (e.g., `aws:SourceVpc` to restrict to a VPC endpoint). Avoid using `s3:*` on `*` except for administrative automation roles.
