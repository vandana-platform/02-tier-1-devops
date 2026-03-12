# Design Decisions — EC2 Terraform Instance

This document records the key design decisions made during the implementation of the EC2 Terraform Instance module, along with the rationale and trade-offs considered.

---

## 1. Single-File Resource Strategy (`main.tf`)

**Decision:** All resources (security group, EC2 instance) are defined in a single `main.tf` file.

**Rationale:**
- This is a minimal, single-purpose module with a narrow resource footprint — one security group and one EC2 instance.
- Splitting resources across multiple files at this scale adds navigation overhead without improving clarity or maintainability.
- Keeping all resources in one file makes the module easier to review end-to-end in a pull request without context-switching between files.

**Trade-offs:**

| Benefit | Cost |
|---------|------|
| Minimal file count — easy to review at a glance | As complexity grows, `main.tf` becomes harder to scan |
| No ambiguity about where resources are declared | Does not scale well once VPC, subnets, or IAM are introduced |
| Follows the principle of simplicity at foundation stage | May require a refactor before promoting to a shared module |

**Recommended next step:** As the module grows to include VPCs, subnets, IAM roles, or user data scripts, extract resources into dedicated files (`network.tf`, `iam.tf`) following standard Terraform module conventions.

---

## 2. Default VPC

**Decision:** No custom VPC or subnet is defined. The instance launches into the AWS Default VPC.

**Rationale:**
- The goal of this project is to demonstrate compute provisioning via Infrastructure as Code, not network architecture design.
- The AWS Default VPC is present in every region and account, eliminating cross-module dependencies for a foundation-stage exercise.
- Using the default VPC reduces scope and keeps the module self-contained, making it easier to apply and tear down in isolation.

**Trade-offs:**

| Benefit | Cost |
|---------|------|
| Zero network dependencies — applies immediately | Default VPC is not isolated; unsuitable for multi-environment or production workloads |
| Available in every AWS account and region | No control over CIDR blocks, subnet layout, or routing |
| Simplifies the scope of a foundation-stage module | Tight coupling to a shared network resource that may be modified externally |

**When to change:** Any workload beyond a learning or demo context should use a purpose-built VPC with defined subnets, route tables, and internet gateway configuration managed in a dedicated network module.

---

## 3. `t3.micro` as Default Instance Type

**Decision:** `t3.micro` is set as the default instance type, configurable via an input variable.

**Rationale:**
- `t3.micro` provides a balanced baseline: 2 vCPUs (burstable) and 1 GiB RAM, sufficient for a foundation-stage demo workload.
- It is eligible for the AWS Free Tier (750 hours/month for new accounts), keeping the running cost at zero during development.
- Exposing the instance type as a variable allows the caller to override the default without modifying source files, supporting reuse across environments.

**Instance type comparison:**

| Type | vCPU | Memory | Use Case |
|------|------|--------|----------|
| `t3.micro` | 2 (burstable) | 1 GiB | Dev/demo, Free Tier eligible |
| `t3.small` | 2 (burstable) | 2 GiB | Light application workloads |
| `t3.medium` | 2 (burstable) | 4 GiB | Web servers, small databases |
| `m5.large` | 2 (fixed) | 8 GiB | Consistent CPU production workloads |

**Trade-offs:**

| Benefit | Cost |
|---------|------|
| Free Tier eligible — zero cost for new accounts | Burstable CPU; not suitable for sustained CPU workloads |
| Configurable without source changes | Default may be applied accidentally to larger environments |
| Broad regional availability | Credit exhaustion under sustained load causes throttling |

---

## 4. SSH Open to `0.0.0.0/0`

**Decision:** Inbound SSH (port 22) is permitted from all source IPs (`0.0.0.0/0`).

**Rationale:**
- Acceptable for a short-lived, single-developer learning and demo environment where the instance lifecycle is measured in minutes or hours.
- Avoids the need to determine and manage a caller's dynamic IP address during a foundation-stage exercise.
- The intent is to document this explicitly as a known risk rather than obscure it, prompting the correct controls before any production use.

**Trade-offs:**

| Benefit | Cost |
|---------|------|
| No IP management required during development | Exposes the SSH port to the public internet and automated scanners |
| Simplifies access for short-lived demo instances | High risk of brute-force or credential stuffing if a key is attached |
| Clearly visible in Terraform state for auditing | Would fail any security review or compliance scan in a real environment |

**Production mitigations (in order of preference):**
1. **AWS Systems Manager Session Manager** — eliminates SSH and open port 22 entirely; no key pair required.
2. **Restrict to a known CIDR** — replace `0.0.0.0/0` with a specific IP range (e.g., corporate VPN CIDR or personal IP).
3. **Bastion host** — allow SSH only from a hardened bastion in a private subnet.

---

## 5. No Key Pair Attached

**Decision:** No `key_name` is set on the EC2 instance resource.

**Rationale:**
- The instance is not intended to be accessed via SSH in this demo. The security group and instance are provisioned to validate IaC patterns, not to run a live workload.
- Adding a key pair introduces out-of-band key material management (generation, storage, rotation) that is outside the scope of a compute provisioning exercise.
- Omitting the key pair reduces the attack surface on an instance with an open SSH security group rule.

**Trade-offs:**

| Benefit | Cost |
|---------|------|
| No key material to generate, store, or rotate | Instance is inaccessible via SSH if access is later needed |
| Reduces credential management scope | Harder to debug or inspect the instance at the OS level |
| Lower attack surface despite open port 22 | Any future access requires a re-provision or key injection via user data |

**When to change:** If the instance needs to be accessed, either attach an existing key pair via the `key_name` variable, or — preferably — use AWS Systems Manager Session Manager, which requires no key pair and no open inbound ports.

---

## 6. Hardcoded AMI ID

**Decision:** The AMI is hardcoded (`ami-0c02fb55956c7d316` — Amazon Linux 2, `us-east-1`) rather than resolved dynamically via a `data "aws_ami"` source.

**Rationale:**
- A pinned AMI ID produces a fully deterministic `terraform plan`: the same AMI is always used, regardless of when `terraform init` is run or what new AMIs AWS publishes.
- A `data "aws_ami"` lookup resolves at plan time and can silently resolve to a newer AMI version, introducing unintended OS changes between applies.
- For a foundation demo, predictability outweighs flexibility.

**Comparison — hardcoded vs dynamic AMI lookup:**

| Approach | Predictability | Freshness | Complexity |
|----------|---------------|-----------|------------|
| Hardcoded AMI ID | High — exact image every time | Low — must be updated manually | Low |
| `data "aws_ami"` (latest) | Low — resolves at plan time | High — always latest image | Medium |
| `data "aws_ami"` (pinned filter) | Medium — consistent family, varying patch | Medium | Medium |

**Trade-offs:**

| Benefit | Cost |
|---------|------|
| Fully deterministic plans and applies | AMI ID is region-specific; must be updated for other regions |
| No dependency on AMI availability or naming at plan time | Security patches and OS updates require a manual AMI update |
| Simple to audit — the exact image is visible in source | Risk of using an outdated or deprecated AMI over time |

**Mitigation:** For any long-lived or multi-region deployment, replace the hardcoded ID with a `data "aws_ami"` block filtered by owner and name pattern, combined with explicit AMI testing in a pipeline before promotion.

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
