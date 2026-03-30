# Design Decisions — S3 Static Site

This document records the key design decisions made during the implementation of the S3 Static Site module, along with the rationale and trade-offs considered.

---

## 1. Single-File Resource Strategy (`main.tf`)

**Decision:** All four S3 resources are defined in a single `main.tf` file.

**Rationale:**
- The module is small and single-purpose: one bucket and its three dependent configuration resources.
- Keeping all resources in one file makes the `depends_on` relationship between the bucket policy and public access block visible in a single screen — context-switching between files would obscure this critical ordering.
- Follows the principle of simplicity at foundation stage; a flat structure is easier to review end-to-end in a pull request.

**Trade-offs:**

| Benefit | Cost |
|---------|------|
| Minimal file count — easy to review at a glance | As complexity grows (CloudFront, logging, replication), `main.tf` becomes harder to scan |
| Dependency chain visible in one place | Does not scale cleanly once CDN, DNS, or WAF resources are introduced |
| Follows the principle of simplicity at foundation stage | May require a refactor into `cdn.tf`, `dns.tf` before promoting to a shared module |

**Recommended next step:** If CloudFront, ACM certificates, or Route 53 records are added, extract resources into dedicated files by concern (`cdn.tf`, `dns.tf`) following standard Terraform module conventions.

---

## 2. Public `s3:GetObject` with `Principal: "*"`

**Decision:** The bucket policy grants `s3:GetObject` to all principals (`"*"`) on every object key in the bucket (`arn:aws:s3:::bucket/*`).

**Rationale:**
- A public static website requires world-readable objects — this is the standard pattern for S3 website hosting without authenticated readers.
- The policy is scoped to `GetObject` only; anonymous callers cannot `Put`, `Delete`, or `List` objects through this statement.
- For a foundation-stage demo, explicit public access is acceptable and intentionally documented as a known trade-off.

**Trade-offs:**

| Benefit | Cost |
|---------|------|
| Simple HTTP access for static assets with no auth required | Anyone who knows or guesses an object key can read it |
| No signing, tokens, or cookies required for browsers | Sensitive files must never be stored in the same bucket |
| Standard pattern — well understood and well documented | Would fail a security review for any workload beyond static assets |

**Production mitigations (in order of preference):**
1. **Amazon CloudFront with Origin Access Control (OAC)** — keeps the bucket private; only CloudFront can read objects; HTTPS included.
2. **Separate buckets** — isolate public web assets from any private data; never mix datasets in a publicly readable bucket.
3. **Least-privilege object layout** — avoid `s3:ListBucket` on the bucket; ensure no lifecycle rule or application process lands sensitive data in a public bucket.

---

## 3. All Four Public Access Block Settings Set to `false`

**Decision:** `block_public_acls`, `block_public_policy`, `ignore_public_acls`, and `restrict_public_buckets` are all set to `false`.

**Rationale:**
- AWS enables all four public access block settings by default on new buckets to prevent accidental exposure. A public bucket policy will be rejected by AWS while `block_public_policy` or `restrict_public_buckets` remain `true`.
- For an intentionally public static website at foundation stage, all four must be disabled at the bucket level so the public `GetObject` policy can take effect.
- The intent is to document this explicitly as a known trade-off rather than obscure it.

**Comparison — public access block combinations:**

| block_public_policy | restrict_public_buckets | Public policy accepted? |
|--------------------|------------------------|------------------------|
| `true` | any | No — policy rejected by AWS |
| `false` | `true` | No — bucket restricted even with valid policy |
| `false` | `false` | Yes — public policy applies |

**Trade-offs:**

| Benefit | Cost |
|---------|------|
| Public website behaviour works as expected | Disables AWS safety rails that prevent accidental data exposure |
| Intentional and visible in Terraform state | A misconfigured upload could expose unexpected files |

**When to change:** In production, keep the bucket **private** (all four block settings `true`) and use **CloudFront with OAC** so the bucket is never directly reachable from the internet.

---

## 4. Explicit `depends_on` from Bucket Policy to Public Access Block

**Decision:** `aws_s3_bucket_policy.static_site` declares `depends_on = [aws_s3_bucket_public_access_block.static_site]`.

**Rationale:**
- Terraform builds its dependency graph from resource attribute references. Both the public access block and the bucket policy reference `aws_s3_bucket.static_site.id`, but there is no direct attribute reference between them.
- Without an explicit dependency, Terraform may attempt to apply the bucket policy concurrently with or before the public access block, causing an `AccessDenied` or `public policies are blocked` error on some runs.
- The `depends_on` enforces the correct API sequence: block settings first, policy second.

**Trade-offs:**

| Benefit | Cost |
|---------|------|
| Reliable applies — eliminates a class of intermittent timing errors | Slightly constrains parallelism for this small graph |
| Intent is documented in code — future maintainers understand the ordering requirement | Adds a line of Terraform that newcomers may question without context |

**When to change:** If the bucket is made private and the public policy removed, the `depends_on` can be dropped. If the bucket policy is replaced with an OAC-based policy for CloudFront, restructure the dependency accordingly.

---

## 5. Fixed `index.html` and `error.html` — Not Parameterised

**Decision:** The website configuration hardcodes `index_document.suffix = "index.html"` and `error_document.key = "error.html"` rather than exposing them as variables.

**Rationale:**
- `index.html` and `error.html` are the near-universal conventions for static website hosting — the majority of static site generators and deployment tools produce files with these names.
- Introducing variables for document names adds surface area (two more inputs) with no practical benefit at foundation stage.
- Callers deploying non-standard entrypoints are better served by a separate module definition rather than a proliferation of optional variables.

**Trade-offs:**

| Benefit | Cost |
|---------|------|
| Predictable behaviour documented in one place | Single-page apps with custom routing or error handling require a modified or separate module |
| No optional variable overhead | Cannot serve a different entrypoint (e.g., `app.html`) without editing `main.tf` |

**Recommended next step:** If multiple teams need different document names, introduce optional `index_document` and `error_document` input variables with defaults of `index.html` and `error.html`.

---

## 6. No CloudFront, Custom Domain, or TLS in This Module

**Decision:** The module serves content only via the **S3 website endpoint** (HTTP). No CloudFront distribution, ACM certificate, or Route 53 record is included.

**Rationale:**
- Foundation scope focuses on S3 primitives and Terraform wiring, not a full edge or DNS stack.
- CloudFront, ACM, and Route 53 each introduce meaningful additional apply time, cost, and configuration complexity that is outside the learning scope of this module.
- The website endpoint is sufficient to verify that static website hosting, public access, and bucket policy are all wired correctly.

**Comparison — S3 website endpoint vs CloudFront:**

| Approach | HTTPS | Custom domain | Edge caching | Complexity |
|----------|-------|--------------|-------------|------------|
| S3 website endpoint (this module) | No — HTTP only | Awkward (CNAME caveats apply) | None | Low |
| CloudFront + OAC | Yes (ACM) | Yes (Route 53 alias) | Yes | High |

**Trade-offs:**

| Benefit | Cost |
|---------|------|
| Fast to provision and destroy for demos | No HTTPS — browser security warnings in modern contexts |
| Minimal ongoing cost for a small site | Higher latency globally; no DDoS protection or WAF |

**When to change:** Add CloudFront with OAC and an ACM certificate when HTTPS, a custom domain, DDoS protection, or edge caching is required. This is the expected production pattern for any externally reachable site.

---

## 7. `bucket_name` Has No Default Value

**Decision:** `bucket_name` is declared as a required variable with no `default`.

**Rationale:**
- S3 bucket names are **globally unique** across all AWS accounts and regions. Any hardcoded default would collide with an existing bucket or require encoding account-specific knowledge into the module.
- Forcing an explicit value at every `plan` and `apply` invocation encourages intentional naming — for example including an account ID, project prefix, or environment slug.
- A missing default surfaces the requirement immediately at the CLI (`Error: No value for required variable`) rather than silently using a name that will fail at the AWS API level.

**Trade-offs:**

| Benefit | Cost |
|---------|------|
| No accidental applies with an ambiguous or colliding name | Every plan and apply requires `-var` or a `tfvars` file |
| Makes the global uniqueness requirement explicit and visible | Slight friction for quick demos |

**Recommended next step:** In a multi-environment pipeline, derive `bucket_name` from a local expression combining workspace, account ID, and a short service slug rather than passing it at every invocation.

---

## 8. Version Constraints in `versions.tf`

**Decision:** Terraform `>= 1.0` and AWS provider `~> 5.0` are pinned in a dedicated `versions.tf` file.

**Rationale:**
- `~> 5.0` permits minor and patch updates within the v5 major line, protecting against breaking changes introduced in a future v6 release while still receiving bug fixes and new resource support.
- `>= 1.0` sets a low barrier for a foundation-stage module while ensuring a modern HCL runtime. The `depends_on` meta-argument and `jsonencode` function used in this module are available from Terraform 0.13+, so `>= 1.0` is a safe lower bound.
- Separating version constraints into `versions.tf` follows standard Terraform module conventions and makes them easy to locate and update independently of resource definitions.
- The `.terraform.lock.hcl` file records the exact provider binary hash, ensuring every developer and CI pipeline runs against the identical provider regardless of when `terraform init` is run.

**Trade-offs:**

| Benefit | Cost |
|---------|------|
| Reproducible provider across machines and CI pipelines | Must be updated deliberately when upgrading provider major versions |
| `~> 5.0` prevents silent adoption of a v6 breaking change | Will not receive v6 improvements without an intentional constraint update |
| Lock file provides cryptographic guarantee of provider integrity | Lock file conflicts can arise when teammates run `terraform init` on different platforms |

**Mitigation:** Commit `.terraform.lock.hcl` and regenerate it for all target platforms using `terraform providers lock -platform=linux_amd64 -platform=darwin_amd64`.
