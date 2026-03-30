# Design Decisions — CloudWatch Baseline

This document records the key design decisions made during the implementation of the CloudWatch Baseline module, along with the rationale and trade-offs considered.

---

## 1. Single-File Resource Strategy (`main.tf`)

**Decision:** Both resources (log group and metric alarm) are defined in a single `main.tf` file.

**Rationale:**
- This is a minimal, single-purpose module with a narrow resource footprint — one log group and one metric alarm.
- Splitting resources across multiple files at this scale adds navigation overhead without improving clarity or maintainability.
- Keeping all resources in one file makes the module easier to review end-to-end in a pull request without context-switching between files.

**Trade-offs:**

| Benefit | Cost |
|---------|------|
| Minimal file count — easy to review at a glance | As complexity grows, `main.tf` becomes harder to scan |
| No ambiguity about where resources are declared | Does not scale well once dashboards, composite alarms, or log metric filters are introduced |
| Follows the principle of simplicity at foundation stage | May require a refactor before promoting to a shared module |

**Recommended next step:** As the module grows to include dashboards, composite alarms, log metric filters, or SNS topics, extract resources into dedicated files (`alarms.tf`, `log_groups.tf`, `dashboards.tf`) following standard Terraform module conventions.

---

## 2. No Alarm Actions Defined

**Decision:** `alarm_actions`, `ok_actions`, and `insufficient_data_actions` are not set on the metric alarm resource.

**Rationale:**
- The goal of this project is to demonstrate metric alarm provisioning as IaC, not to build a complete alerting pipeline.
- Alarm actions require an SNS topic ARN, which introduces a cross-resource dependency outside the scope of a foundation-stage exercise.
- Omitting actions keeps the module self-contained — the alarm transitions between states correctly, but no notifications are dispatched.
- The absence of actions is explicitly documented here rather than obscured, prompting the correct additions before any production use.

**Trade-offs:**

| Benefit | Cost |
|---------|------|
| No SNS topic dependency — module applies in isolation | Alarm state changes produce no notifications or automated responses |
| Simpler scope for a foundation-stage demo | Not useful in production without at least one alarm action wired to SNS |
| Alarm state is still visible in the CloudWatch Console | Engineers must poll the console manually rather than receive push alerts |

**When to change:** Before any production use, add an `alarm_actions` attribute pointing to an SNS topic ARN. The SNS topic can deliver to email, PagerDuty, Slack (via Lambda), or trigger an Auto Scaling policy.

---

## 3. Account-Wide Metric Alarm (No Instance Dimension)

**Decision:** The `high_cpu` metric alarm does not set any `dimensions` block, so it evaluates `CPUUtilization` aggregated across all EC2 instances in the account.

**Rationale:**
- At foundation stage, no specific EC2 instance ID is known at the time this module is applied.
- Omitting dimensions produces a valid alarm that monitors the aggregate metric — useful for demonstrating alarm configuration without depending on a running instance.
- The alarm will report `INSUFFICIENT_DATA` in accounts with no EC2 instances, which is the expected and transparent behaviour.

**Comparison — with and without dimensions:**

| Approach | Scope | Instance Required | Use Case |
|----------|-------|-------------------|----------|
| No dimensions (this module) | Account-wide aggregate | No | Foundation demo, fleet-level health check |
| `InstanceId` dimension | Single specific instance | Yes | Per-instance alerts in production |
| Auto Scaling Group dimension | ASG-level aggregate | Yes (ASG) | Scaling trigger for stateless application tiers |

**Trade-offs:**

| Benefit | Cost |
|---------|------|
| No dependency on a running EC2 instance at apply time | Does not alert on a specific instance; imprecise for targeted remediation |
| Demonstrates alarm lifecycle without cross-module coupling | Aggregate metric can mask individual instance saturation |
| Alarm exists and transitions states as soon as EC2 instances emit metrics | In a multi-instance environment, a single overloaded instance may not push the average above 80% |

**When to change:** In production, add a `dimensions` block with the specific `InstanceId` — or, for Auto Scaling Groups, use the `AutoScalingGroupName` dimension to monitor the group aggregate.

---

## 4. Seven-Day Default Log Retention

**Decision:** `retention_in_days` defaults to `7` for the log group.

**Rationale:**
- Seven days provides enough history to diagnose recent incidents without accumulating significant storage costs.
- CloudWatch Logs charges $0.03/GB per month for ingested data and $0.03/GB per month for archived storage. A short default retention prevents runaway costs in a development account.
- The retention period is exposed as a variable (`retention_days`) so it can be overridden per environment without modifying source files.

**Retention period comparison:**

| Period | Use Case | Storage Cost Exposure |
|--------|----------|-----------------------|
| `7` days (this module) | Development / demo / short-term debugging | Minimal |
| `30` days | Standard production operational window | Low-medium |
| `90` days | Regulatory baseline for most compliance frameworks | Medium |
| `365` days | PCI-DSS, HIPAA, SOC 2 requirement for audit trails | High |
| `3653` days (10 years) | Long-term compliance archival | Very high — use S3 export instead |

**Trade-offs:**

| Benefit | Cost |
|---------|------|
| Minimal storage cost in dev accounts | Logs older than 7 days are permanently deleted — insufficient for incident reviews spanning a week |
| Configurable without source changes | Default may be applied accidentally to a production group that requires longer retention |
| Consistent with a throw-away foundation stage environment | Does not meet any compliance framework's minimum retention requirement |

**Production mitigations (in order of preference):**
1. **Override via `tfvars`** — set `retention_days = 90` (or the required compliance period) in a `prod.tfvars` file.
2. **Export to S3** — configure a CloudWatch Logs subscription filter to export logs to S3 for long-term archival at lower cost before the group retention window expires.
3. **Enforce via SCP** — apply a Service Control Policy preventing log group retention from being set below a minimum threshold in production OUs.

---

## 5. Hardcoded 80% CPU Threshold

**Decision:** The alarm threshold is hardcoded to `80` (percent CPU utilisation) rather than exposed as an input variable.

**Rationale:**
- 80% is a widely accepted baseline for CPU saturation alerting — it provides headroom before full saturation while still catching genuine workload spikes early.
- Exposing the threshold as a variable adds surface area without improving the learning objective of this foundation module.
- For a demo, a fixed threshold makes the resource attributes easy to reason about and verify without consulting `tfvars`.

**Trade-offs:**

| Benefit | Cost |
|---------|------|
| Simple to reason about — the threshold is visible in `main.tf` | Cannot be adjusted per environment without modifying source |
| No variable sprawl for a single-purpose module | 80% may be too low (causing alert noise) or too high (missing real incidents) for specific workloads |
| Consistent across all deployments of this module | Prevents runtime tuning without a code change and new Terraform apply |

**Recommended next step:** If this module is promoted to a shared library, expose `cpu_threshold` as an input variable with a default of `80` and validation constraints (`>= 50`, `<= 95`).

---

## 6. Two Evaluation Periods at 120-Second Resolution

**Decision:** The alarm uses `evaluation_periods = 2` and `period = 120` (seconds), requiring two consecutive breaches over a four-minute window before transitioning to `ALARM`.

**Rationale:**
- A single-period evaluation on a 120-second window would trigger on transient CPU spikes that resolve before any action is warranted.
- Two consecutive evaluations reduce false positive rates — a sustained breach over four minutes is far more likely to represent a real workload issue than a momentary spike.
- 120-second periods use basic CloudWatch monitoring resolution, which is available at no additional charge. 1-minute detailed monitoring requires opting in per instance and incurs additional cost.

**Trade-offs:**

| Benefit | Cost |
|---------|------|
| Reduces alert noise from transient spikes | Adds a four-minute detection lag before the alarm fires |
| No additional cost — uses basic 5-minute metric resolution with 120s aggregation | May be too slow for latency-sensitive workloads requiring faster incident response |
| Standard pattern for production CPU alarms | Two missed evaluations during a `INSUFFICIENT_DATA` period resets the consecutive count |

---

## 7. Version Constraints in `versions.tf`

**Decision:** Terraform `>= 1.0` and AWS provider `~> 5.0` are pinned in a dedicated `versions.tf` file.

**Rationale:**
- `~> 5.0` permits minor and patch updates within the v5 major line, protecting against breaking changes introduced in a future v6 release while still receiving bug fixes and improvements.
- `>= 1.0` is a permissive lower bound that allows any stable Terraform version from 1.0 onward. CloudWatch resources used here require no HCL features beyond v1.0 baseline.
- Separating version constraints into `versions.tf` follows standard Terraform module conventions and makes them easy to locate and update.
- The `.terraform.lock.hcl` file records the exact provider hash, ensuring every developer and CI pipeline runs against the identical binary regardless of when they initialise the workspace.

**Trade-offs:**

| Benefit | Cost |
|---------|------|
| Reproducible builds across machines and CI pipelines | Must be updated intentionally when upgrading provider major versions |
| Prevents silent drift from automatic major version upgrades | `~> 5.0` will not adopt v6 improvements without a deliberate change |
| Lock file provides a cryptographic guarantee of provider integrity | Lock file conflicts can arise when different team members run `terraform init` on different platforms |
