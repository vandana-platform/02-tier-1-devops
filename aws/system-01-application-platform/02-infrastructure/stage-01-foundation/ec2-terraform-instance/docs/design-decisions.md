# Design Decisions

## 1. Single-File Resource Strategy (`main.tf`)

**Decision:** All resources (security group, EC2 instance) are defined in one `main.tf`.

**Rationale:** This is a minimal, single-purpose module. Splitting resources across multiple files adds overhead with no benefit at this scale. As complexity grows (VPC, subnets, IAM), resources should be extracted into dedicated files.

---

## 2. Default VPC

**Decision:** No custom VPC or subnet is defined. The instance launches into the AWS Default VPC.

**Rationale:** The goal of this project is to demonstrate compute provisioning via IaC, not network architecture. Using the default VPC reduces scope and dependency count for a foundation-stage module.

---

## 3. `t3.micro` as Default Instance Type

**Decision:** `t3.micro` is the default, configurable via variable.

**Rationale:** `t3.micro` is cost-efficient, broadly available, and eligible for the AWS Free Tier (750 hours/month for new accounts). The variable makes it easy to override without modifying source files.

---

## 4. SSH Open to `0.0.0.0/0`

**Decision:** Inbound SSH (port 22) is allowed from all IPs.

**Rationale:** Acceptable for a short-lived learning/demo environment. In production, this should be restricted to a known IP range or replaced with AWS Systems Manager Session Manager to eliminate the need for open SSH entirely.

---

## 5. No Key Pair

**Decision:** No `key_name` is set on the EC2 instance.

**Rationale:** The instance is not intended to be accessed via SSH in this demo. Adding a key pair would require out-of-band key management and is outside the scope of the provisioning exercise.

---

## 6. Hardcoded AMI

**Decision:** AMI is hardcoded (`ami-0c02fb55956c7d316`) rather than looked up via a data source.

**Rationale:** Simplicity. A `data "aws_ami"` lookup adds complexity and can resolve to unexpected AMI versions. For a foundation demo, a pinned AMI is predictable and sufficient. The trade-off is that the AMI ID is region-specific (`us-east-1`).

---

## 7. Version Constraints in `versions.tf`

**Decision:** Terraform `>= 1.5.0` and AWS provider `~> 5.0` are pinned in a separate `versions.tf`.

**Rationale:** Version constraints prevent CI/CD drift and ensure reproducible infrastructure builds across machines. Separating them into `versions.tf` follows the standard Terraform module convention.
