# Design Decisions — S3 Bucket Baseline

This document records the key design decisions made during the implementation of the S3 Bucket Baseline module, along with the rationale and trade-offs considered.

---

## 1. Bucket Versioning Enabled

**Decision:** `aws_s3_bucket_versioning` is configured with `status = "Enabled"`.

**Rationale:**
- Protects against accidental deletion and overwrites by retaining all historical object versions.
- Required for S3 Cross-Region Replication and S3 Object Lock if either is added in a future stage.
- Provides a recoverable audit trail for any objects stored in the bucket.

**Trade-offs:**

| Benefit | Cost |
|---------|------|
| Object recovery without external backup | Storage costs increase as versions accumulate |
| Required prerequisite for replication | Old versions must be managed via lifecycle rules |
| Enables MFA Delete for critical buckets | Slightly more complex object management |

**Mitigation:** S3 Lifecycle policies should be added in a follow-on stage to expire non-current versions after a defined retention period, keeping storage costs predictable.

---

## 2. Server-Side Encryption Configured

**Decision:** `aws_s3_bucket_server_side_encryption_configuration` enforces encryption at rest for all objects.

**Rationale:**
- Satisfies baseline security posture for AWS Well-Architected Framework (Security Pillar).
- AWS S3 now enables SSE-S3 (AES-256) by default on all new buckets, but explicitly declaring it in Terraform ensures the configuration is version-controlled and enforceable via policy as code.
- Prevents drift — if the default were ever changed at the account or bucket level, Terraform would detect and correct it.

**Algorithm choice — SSE-S3 (AES-256) vs SSE-KMS:**

| Option | Use When |
|--------|---------|
| SSE-S3 (AES-256) | General-purpose baseline; no regulatory key-management requirements |
| SSE-KMS | Audit trails per object, cross-account access, or compliance mandates (HIPAA, PCI) |

This baseline uses SSE-S3 for simplicity. Upgrading to SSE-KMS is a non-breaking change and is recommended before storing sensitive workload data.

---

## 3. Public Access Block Enabled on All Four Flags

**Decision:** All four `aws_s3_bucket_public_access_block` settings are set to `true`.

**Rationale:**
- S3 buckets that are inadvertently made public are one of the most common causes of cloud data breaches.
- Enabling all four flags provides defence-in-depth: even if a bucket policy or ACL misconfiguration occurs, the block layer prevents public exposure.
- Aligns with the CIS AWS Foundations Benchmark and AWS Foundational Security Best Practices standard.

**Trade-offs:**

| Benefit | Cost |
|---------|------|
| Prevents accidental public exposure | Static website hosting requires this to be relaxed |
| Satisfies compliance controls out of the box | Public CDN origin scenarios require explicit policy exceptions |

**When to relax:** If the bucket is used as a CloudFront origin for a public website, `block_public_acls` and `block_public_policy` can be set to `false` while keeping `restrict_public_buckets = true` and relying on OAC/OAI policies for access control.

---

## 4. Bucket Configuration Split into Separate Resources

**Decision:** Versioning, encryption, and public access block are each declared as standalone Terraform resources rather than inline blocks inside `aws_s3_bucket`.

**Rationale:**
- AWS deprecated inline sub-resources in AWS provider v4 to prevent conflicts when multiple configurations manage the same bucket.
- Separate resources allow Terraform to plan and apply each concern independently, reducing the blast radius of a single change.
- Easier to review in pull requests — a change to encryption is isolated in its own resource block.
- Enables conditional configuration: a variable flag can enable or disable a specific sub-resource without modifying the core bucket resource.

**Trade-offs:**

| Benefit | Cost |
|---------|------|
| Cleaner diffs and review | More resource blocks to manage |
| No provider deprecation warnings | Requires understanding resource dependencies (`depends_on` or implicit references) |
| Fine-grained `terraform plan` output | More verbose configuration file |

---

## 5. Region Parameterised via Variable

**Decision:** `aws_region` is exposed as an input variable with a default of `us-east-1`.

**Rationale:**
- Avoids hard-coding region in `provider.tf`, making the module reusable across environments and regions without code changes.
- The default is set to `us-east-1` as the primary AWS region for this platform tier; overrides are passed at apply time or via `terraform.tfvars`.

---

## 6. Local Terraform State (Current Baseline Scope)

**Decision:** State is stored locally for this foundational/demo stage.

**Rationale:**
- Appropriate for a single-developer learning and portfolio context where remote backend infrastructure does not yet exist.
- Keeps the bootstrap complexity low — a remote S3 backend would require a chicken-and-egg solution (a bucket must exist before the state can be stored in one).

**Trade-offs:**

| Benefit | Cost |
|---------|------|
| No additional infrastructure required | State cannot be shared across team members |
| Fast iteration for development/learning | Risk of state loss if the local file is deleted |

**Recommended next step:** Migrate to an S3 + DynamoDB remote backend once this foundational bucket is provisioned, using the bucket created here as the state backend for subsequent stages.

---

## 7. Explicit Provider Version Pinning

**Decision:** `versions.tf` pins Terraform to `>= 1.5.0` and the AWS provider to `~> 5.0`.

**Rationale:**
- `~> 5.0` allows patch and minor updates within the v5 major line, preventing breaking changes from a v6 upgrade while still receiving bug fixes.
- `>= 1.5.0` ensures HCL features used in this configuration (such as `check` blocks and `import` blocks) are available.
- The `.terraform.lock.hcl` file records the exact provider hash, ensuring every team member and CI pipeline uses the identical binary.
