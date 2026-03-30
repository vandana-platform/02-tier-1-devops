# Design Decisions — S3 Static Site

This document records the key design decisions made during implementation of the S3 Static Site module, including rationale, trade-offs, and when to evolve the design.

---

## 1. Single-File Resource Strategy (`main.tf`)

**Decision:** All four S3 resources are defined in one `main.tf` file.

**Rationale:**
- The module is small and single-purpose: one bucket and its website, access, and policy settings.
- Colocating resources keeps the dependency between the bucket policy and public access block visible in one screen.
- Reviewers can trace the full static-site pattern without jumping between files.

**Trade-offs:**

| Benefit | Cost |
|---------|------|
| Low navigation overhead for a foundation demo | Larger `main.tf` if CloudFront, logging, or replication are added later |
| Clear linear reading order | Less modular than splitting `s3_bucket.tf` / `policy.tf` at scale |

**Recommended next step:** If you add CloudFront, ACM, Route 53, or WAF, split by concern (`cdn.tf`, `dns.tf`) or extract a child module.

---

## 2. Public Read Bucket Policy with `Principal: "*"`

**Decision:** The bucket policy allows `s3:GetObject` for all principals on `arn:aws:s3:::bucket/*`.

**Rationale:**
- A **public** static site requires world-readable objects; this is the standard pattern for S3 website hosting without authenticated readers.
- Scoped to object keys (`/*`), not `Put` or `Delete`, so anonymous users cannot modify content through this statement alone.

**Trade-offs:**

| Benefit | Cost |
|---------|------|
| Simple HTTP access for static assets | Anyone can read any object in the bucket if they guess or know the key |
| No signing or cookies required | Sensitive objects must never be stored in the same bucket |

**Production mitigations (in order of preference):**
1. **Amazon CloudFront** in front of the bucket with OAI/OAC so the bucket stays private and only CloudFront serves content.
2. **Separate buckets** for public web assets versus private data; never mix datasets.
3. **Least-privilege object layout** and lifecycle rules; avoid listing enabled if not required (website hosting does not require list for root page, but discovery of keys can still be a concern).

---

## 3. All Public Access Block Settings Set to `false`

**Decision:** `block_public_acls`, `block_public_policy`, `ignore_public_acls`, and `restrict_public_buckets` are all `false`.

**Rationale:**
- AWS Account-level and bucket-level public access blocks can prevent a public bucket policy from taking effect.
- For an intentionally public static website at foundation stage, disabling these four on the bucket aligns the bucket with the public policy in `aws_s3_bucket_policy`.

**Trade-offs:**

| Benefit | Cost |
|---------|------|
| Public website behaviour works without fighting default safeguards | Weakens “safety rails” that teams rely on to prevent accidental exposure |

**When to change:** In production, prefer **private bucket + CloudFront OAC** and enable public access block on the bucket (keeping it non-public to the internet directly).

---

## 4. Explicit `depends_on` from Bucket Policy to Public Access Block

**Decision:** `aws_s3_bucket_policy.static_site` uses `depends_on = [aws_s3_bucket_public_access_block.static_site]`.

**Rationale:**
- Terraform can create resources in an order that triggers an error if the policy is evaluated while public access is still blocked.
- The explicit dependency ensures the public access block resource is applied before the policy attachment is finalised, avoiding intermittent apply failures.

**Trade-offs:**

| Benefit | Cost |
|---------|------|
| More reliable applies across provider and API timing edge cases | Slightly constrains parallelism for this tiny graph |

**When to change:** If you move to a private bucket and remove the public policy, you may drop the dependency or replace the policy resource entirely.

---

## 5. Fixed `index.html` and `error.html` in Website Configuration

**Decision:** Website configuration uses `index_document.suffix = "index.html"` and `error_document.key = "error.html"` with no variables.

**Rationale:**
- Matches common static site conventions and keeps the module minimal.
- Callers upload `index.html` at the root; `error.html` serves error pages for the website endpoint behaviour.

**Trade-offs:**

| Benefit | Cost |
|---------|------|
| Predictable behaviour documented in one place | Single-page apps or custom error paths need overrides or a different module |

**Recommended next step:** Introduce optional variables `index_document` and `error_document` if multiple teams need different entrypoints.

---

## 6. No CloudFront, Custom Domain, or TLS in This Module

**Decision:** Traffic is served only via the **S3 website endpoint** (HTTP), not CloudFront or `https://`.

**Rationale:**
- Foundation scope focuses on S3 primitives and Terraform wiring, not a full edge or DNS stack.
- Avoids ACM certificates, Route 53 records, and CloudFront distributions that increase apply time and cost.

**Comparison — direct website endpoint vs CloudFront:**

| Approach | TLS | Custom domain | Caching | Complexity |
|----------|-----|----------------|---------|------------|
| S3 website endpoint | No (HTTP only from S3 website host) | Awkward (CNAME caveats) | None at edge | Low |
| CloudFront + OAC | Yes (ACM) | Yes | Yes | High |

**Trade-offs:**

| Benefit | Cost |
|---------|------|
| Fast to provision and destroy | No HTTPS from S3 website host name alone |
| Minimal monthly cost for tiny sites | Higher latency globally vs edge caching |

**When to change:** Add CloudFront with OAC and (optionally) `A`/`AAAA` alias records when you need TLS, custom domains, or DDoS/WAF at the edge.

---

## 7. Required `bucket_name` Variable (Globally Unique)

**Decision:** `bucket_name` has no default and must be supplied by the operator.

**Rationale:**
- S3 bucket names are **globally unique**; a default would almost always collide or encode an account-specific guess.
- Forcing an explicit value encourages intentional naming (for example including account or org prefix).

**Trade-offs:**

| Benefit | Cost |
|---------|------|
| No accidental applies with an unusable name | Every apply requires `-var` or `tfvars` |

**Recommended next step:** In a pipeline, derive `bucket_name` from `terraform.workspace`, account ID, and a short slug using locals or an external naming module.

---

## 8. Version Constraints in `versions.tf`

**Decision:** Terraform `>= 1.0` and AWS provider `~> 5.0` are declared in `versions.tf`.

**Rationale:**
- `>= 1.0` keeps the barrier low for foundation exercises while staying on a modern CLI line.
- `~> 5.0` avoids unintentional adoption of a future v6 provider until upgrades are tested.

**Trade-offs:**

| Benefit | Cost |
|---------|------|
| Reproducible provider line with lock file | Deliberate effort needed to adopt new major provider versions |

**Mitigation:** Commit `.terraform.lock.hcl` and run `terraform providers lock` for all platforms used in CI.

---

## Honest Note on Foundation-Stage Risk

This module **intentionally** creates a world-readable bucket suitable for learning and demos. It is **not** a pattern for sensitive or authenticated content. Treat any future extension to production as a redesign around private buckets, CloudFront, TLS, logging, and least-privilege IAM for deployers rather than anonymous readers.
