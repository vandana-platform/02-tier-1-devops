# Design Decisions — IAM Role Baseline

This document records the key design decisions made during the implementation of the IAM Role Baseline module, along with the rationale and trade-offs considered.

---

## 1. Single-File Resource Strategy (`main.tf`)

**Decision:** All three resources (IAM role, IAM policy, policy attachment) are defined in a single `main.tf` file.

**Rationale:**
- This is a minimal, single-purpose module with a narrow resource footprint — three closely related IAM resources.
- The three resources have a strict dependency chain: the attachment cannot exist without both the role and the policy. Keeping them in one file makes this chain immediately visible without context-switching.
- Splitting resources across multiple files at this scale adds navigation overhead without improving clarity or maintainability.
- Keeping all resources in one file makes the module easier to review end-to-end in a pull request.

**Trade-offs:**

| Benefit | Cost |
|---------|------|
| Minimal file count — dependency chain visible at a glance | As the module grows (instance profiles, multiple policies), `main.tf` becomes harder to scan |
| No ambiguity about where resources are declared | Does not scale well once additional roles or service-linked roles are introduced |
| Follows the principle of simplicity at foundation stage | May require a refactor before promoting to a shared module |

**Recommended next step:** As the module grows to include `aws_iam_instance_profile`, additional policy attachments, or service-linked roles, extract resources into dedicated files (`roles.tf`, `policies.tf`) following standard Terraform module conventions.

---

## 2. Trust Policy as Inline `jsonencode`

**Decision:** The IAM role trust policy (assume role policy) is written inline using Terraform's `jsonencode` function rather than stored in a separate `.json` file referenced via `file()` or defined via a `data "aws_iam_policy_document"` block.

**Rationale:**
- `jsonencode` produces valid JSON from native HCL maps, which means Terraform validates the structure at plan time rather than at apply time.
- Keeping the trust policy inline makes the principal (`ec2.amazonaws.com`) immediately visible when reading the role resource — no context-switching to a separate file.
- For a single-statement trust policy with no templating requirements, a separate file or data source provides no benefit.

**Trust policy approach comparison:**

| Approach | Validation | Readability | Templating |
|----------|-----------|-------------|------------|
| Inline `jsonencode` | Plan-time | Visible alongside resource | HCL variable interpolation |
| `file("trust.json")` | Apply-time (JSON parse error) | Requires separate file | No variable substitution |
| `data "aws_iam_policy_document"` | Plan-time | Structured HCL blocks | Full variable and condition support |

**Trade-offs:**

| Benefit | Cost |
|---------|------|
| Plan-time validation catches JSON structure errors early | Verbose for complex multi-statement policies with conditions |
| No file dependency — the module is fully self-contained | Mixes policy logic into the resource block |
| Native HCL variable interpolation works without string templates | Harder to diff against raw AWS policy JSON exported from the console |

**Recommended next step:** For complex policies with multiple statements, condition keys, or dynamic principal sets, migrate to `data "aws_iam_policy_document"` which offers structured HCL blocks, better readability, and policy merging capabilities.

---

## 3. Customer-Managed Policy Over AWS Managed Policy

**Decision:** A customer-managed IAM policy (`aws_iam_policy`) is created and attached rather than using the AWS-managed policy `AmazonEC2ReadOnlyAccess`.

**Rationale:**
- Customer-managed policies are fully visible and auditable in Terraform state and source control — their exact permissions are declared in the repository.
- AWS-managed policies are controlled by AWS and can have new actions added at any time without notice, which can silently expand the permissions granted to the role.
- Creating a customer-managed policy with exactly the required actions (`ec2:Describe*`) produces a provably minimal permission set that passes security reviews and compliance scans.

**Policy type comparison:**

| Type | Visibility | Control | Silent Drift Risk | Maintenance |
|------|-----------|---------|-------------------|-------------|
| Customer-managed | Full — declared in Terraform | Complete | None | Must update manually for new APIs |
| AWS-managed | Partial — AWS controls content | None | High — AWS can add actions | Zero — AWS maintains it |

**Trade-offs:**

| Benefit | Cost |
|---------|------|
| Exact permissions are visible in source code | Must manually add new `ec2:Describe*` actions if the application requires them |
| No risk of silent permission expansion by AWS | Adds a managed resource to the account (policy versions count against IAM quotas) |
| Supports least-privilege enforcement and audit | Duplicates effort for widely-used standard permission sets |

**When to change:** If the policy scope needs to automatically track AWS additions to the EC2 API (e.g., for a general tooling role), switching to `AmazonEC2ReadOnlyAccess` is acceptable. Always document this decision explicitly and accept the associated drift risk.

---

## 4. Read-Only Scope (`ec2:Describe*`) as the Baseline Permission Set

**Decision:** The IAM policy grants only `ec2:Describe*` actions, which covers all EC2 read and list operations.

**Rationale:**
- `ec2:Describe*` is the minimal permission set needed for an EC2 instance or tool to query its own metadata, list instances, inspect security groups, and perform observability tasks.
- A read-only foundation scope is the safest starting point: it is trivial to expand permissions upward, but difficult to reduce them once a service depends on broader access.
- Keeping the baseline permission narrow enforces the principle of least privilege from the start of the platform, ensuring security controls are established before operational needs drive scope creep.

**Trade-offs:**

| Benefit | Cost |
|---------|------|
| Minimal blast radius — a compromised identity cannot modify or destroy EC2 resources | Must add new permissions explicitly when an application requires write access |
| Passes security reviews and compliance scans by default | `ec2:Describe*` is broad — it allows reading all EC2 resource metadata in the account |
| Documents the intended use of the role in the permission scope itself | Write actions (`RunInstances`, `TerminateInstances`) require a separate policy when needed |

**When to change:** When the attached workload requires write operations (e.g., instance creation, tagging, security group modification), create a separate policy with the minimum required write actions and attach it alongside this read-only baseline.

---

## 5. Wildcard Resource Scope for the Read-Only Policy

**Decision:** The policy resource scope is set to `"*"` (all EC2 resources in the account) rather than a specific resource ARN.

**Rationale:**
- EC2 `Describe*` API calls do not support resource-level restrictions — AWS ignores the resource ARN in the policy for most describe actions and requires `*` for them to function.
- Attempting to scope `ec2:Describe*` to a specific resource ARN produces a policy that silently fails the describe calls at runtime, which is worse than a clear permissions error.
- AWS IAM documentation explicitly notes that many EC2 read operations require `Resource: *`.

**Trade-offs:**

| Benefit | Cost |
|---------|------|
| Policy functions as intended — describe calls succeed | All EC2 resource metadata in the account is readable by the role |
| Matches AWS API behaviour — `Describe*` inherently returns account-wide results | Appears permissive in automated policy analysis tools like IAM Access Analyzer |
| No runtime permission errors from incorrect resource scoping | Cannot scope to specific instance IDs or VPC IDs at the IAM policy level |

**Production mitigations (in order of preference):**
1. **Scope write policies tightly** — while `Describe*` must use `*`, write operations (`ec2:TerminateInstances`, `ec2:StopInstances`) can and should be scoped to specific resource ARNs or tag conditions (`ec2:ResourceTag/Environment`).
2. **Use IAM condition keys** — restrict using `aws:RequestedRegion` or resource tag conditions where the EC2 API supports them.
3. **Pair with SCP** — use AWS Organizations Service Control Policies to enforce account-wide read boundaries independent of IAM policies.

---

## 6. Role and Policy Names as Input Variables

**Decision:** `role_name` and `policy_name` are exposed as input variables with sensible defaults rather than hardcoded in `main.tf`.

**Rationale:**
- IAM resource names must be unique within an AWS account. Parameterising names allows the same module to be applied multiple times with different names for different environments or workloads.
- Variables make the module self-documenting: the caller can see what is configurable without reading `main.tf`.
- Defaults (`ec2-baseline-role`, `ec2-read-only-policy`) are descriptive enough to identify the resource's purpose in the AWS console without any additional context.

**Trade-offs:**

| Benefit | Cost |
|---------|------|
| Module is reusable across environments with different naming conventions | A caller can accidentally reuse an existing name, causing `EntityAlreadyExists` errors |
| Avoids hardcoded names that conflict in multi-environment accounts | Default names may not match an organisation's enforced naming policy |
| Defaults make the module apply immediately without any variable input | Name changes after initial apply cause resource replacement (destroy + create), not in-place updates |

**When to change:** If the organisation enforces a naming convention (e.g., `{env}-{service}-{resource}-role`), override the defaults via `-var` or `tfvars` and document the convention in the module README.

---

## 7. Version Constraints in `versions.tf`

**Decision:** Terraform `>= 1.5.0` and AWS provider `~> 5.0` are pinned in a dedicated `versions.tf` file.

**Rationale:**
- `~> 5.0` permits minor and patch updates within the v5 major line, protecting against breaking changes introduced in a future v6 release while still receiving bug fixes and improvements.
- `>= 1.5.0` ensures that HCL features available from that release (such as `check` blocks and `import` blocks) are accessible.
- Separating version constraints into `versions.tf` follows standard Terraform module conventions and makes them easy to locate and update.
- The `.terraform.lock.hcl` file records the exact provider hash, ensuring every developer and CI pipeline runs against the identical binary regardless of when they initialise the workspace.

**Trade-offs:**

| Benefit | Cost |
|---------|------|
| Reproducible builds across machines and CI pipelines | Must be updated intentionally when upgrading provider major versions |
| Prevents silent drift from automatic major version upgrades | `~> 5.0` will not adopt v6 improvements without a deliberate change |
| Lock file provides a cryptographic guarantee of provider integrity | Lock file conflicts can arise when different team members run `terraform init` on different platforms |
