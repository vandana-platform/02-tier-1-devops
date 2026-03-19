# Claude Code — Repo Conventions

## General Content Rule
Never target a fixed number for decisions, steps, questions, bullet points,
or any other content element. Content length and depth is always driven by
what the service being documented requires. Let the complexity of the
service determine the count.

---

## Documentation Pattern
All infrastructure modules follow the same 6-file documentation structure.
The canonical reference implementation is the EC2 module located at:

aws/system-01-application-platform/02-infrastructure/stage-01-foundation/ec2-terraform-instance/

Before generating any documentation, read all reference files below to
understand exact tone, formatting, depth, and structure:

- README.md     → aws/system-01-application-platform/02-infrastructure/stage-01-foundation/ec2-terraform-instance/README.md
- architecture  → aws/system-01-application-platform/02-infrastructure/stage-01-foundation/ec2-terraform-instance/docs/architecture.md
- decisions     → aws/system-01-application-platform/02-infrastructure/stage-01-foundation/ec2-terraform-instance/docs/design-decisions.md
- setup         → aws/system-01-application-platform/02-infrastructure/stage-01-foundation/ec2-terraform-instance/docs/setup-guide.md
- troubleshoot  → aws/system-01-application-platform/02-infrastructure/stage-01-foundation/ec2-terraform-instance/docs/troubleshooting.md
- interview     → aws/system-01-application-platform/02-infrastructure/stage-01-foundation/ec2-terraform-instance/docs/interview-prep.md

---

## Diagram Rules
- `interview-prep.md`  → Mermaid diagrams ONLY (flowchart LR, flowchart TD, graph TD, graph LR)
- `architecture.md`    → ASCII art ONLY (└── │ ▼ ├── style trees and flow arrows)
- All other files      → No diagrams of any kind

Mermaid diagrams in interview-prep.md are embedded inside the answer
paragraph of the relevant question — not as standalone sections. Use them
where a concept genuinely benefits from visualisation such as workflows,
dependency graphs, and architecture layers.

---

## README.md Rules
- H1 title + short purpose description
- Platform Context table (Repository Layer, Cloud Provider, Platform System, Capability Layer, Infrastructure Stage)
- Resources Created table
- Prerequisites table with versioned links
- Project Structure as ASCII code tree
- Input Variables table
- Terraform Workflow with bash blocks for init, plan, apply, destroy — include a destroy cost warning
- Outputs table with example output block
- Troubleshooting — real errors relevant to the service being documented
- Learning Outcomes as a bullet list

---

## architecture.md Rules
- H1 + one-line overview
- Overview section with repo path shown as an ASCII tree
- Infrastructure Components as ASCII tree with actual values, resource names, and relevant attributes for the service
- Terraform File Responsibilities table covering every .tf file and its exact purpose
- Resource Architecture section with ASCII dependency diagram, then a sub-section per resource with an attributes table
- Data Flow shown as ASCII diagram from CLI through provider to resources to outputs
- Tagging Strategy table
- State Management section — honest about current local state and what should be done for production
- Region section with a bash override example

---

## design-decisions.md Rules
- H1 + one opening paragraph explaining what the doc covers
- Numbered decisions covering every non-obvious design choice made for the module
- Each decision follows exactly this format:
  - **Decision:** one clear sentence of what was chosen
  - **Rationale:** bullet points explaining why — enough to justify the choice
  - **Trade-offs:** Benefit | Cost table
  - **When to change / Recommended next step / Production mitigations**
- Where multiple options were evaluated, include a mid-section comparison table
- Production mitigations listed in numbered preference order
- Honest about risks and shortcuts taken at foundation stage

---

## setup-guide.md Rules
- H1 + short intro covering what it does and what it demonstrates
- Prerequisites table with exact permissions required for the service
- Numbered steps covering every action needed to deploy, verify, and tear down
- Each step has: one-line explanation of what the step does, bash block, expected output code block, and a tip or warning note where relevant
- Verify step always has sub-methods covering AWS CLI, AWS Console, and Terraform Output
- Destroy step includes actual hourly cost for the resource where applicable
- Optional section at the end showing variable overrides via -var flag and tfvars file

---

## troubleshooting.md Rules
- H1 + one-line summary
- Grouped into numbered category sections by problem type
- Cover every realistic failure scenario relevant to the service being documented
- Each issue follows exactly this format:
  - ### Error Name — descriptive title
  - **Symptom:** exact error message in a code block
  - **Cause:** plain English explanation
  - **Fix:** bash or HCL or JSON code block with real commands
- Fix steps are numbered when multi-step
- Use real AWS CLI commands with --query and --output flags throughout
- Always include this final section, present but blank:

  ## Issues Faced During Implementation
  *This section documents real issues encountered while building this
  module as a personal reference.*
  <!-- To be completed -->

---

## interview-prep.md Rules
- H1 + one-line description
- Questions grouped by topic sections
- Coverage must progress in this order:
  1. Foundational — what is the service, core concepts
  2. Service Specific — deep dive on the service being documented
  3. Terraform Patterns — how resources are declared and managed
  4. Security — permissions, encryption, compliance
  5. Production Readiness — multi-env, remote state, modules
  6. DevOps and Platform Engineering — CI/CD, monitoring, scaling, secrets
- Format per question:
  - **Q[number]. Bold question**
  - Direct answer paragraph
  - Mermaid diagram embedded inside the answer where the concept benefits from it
  - Comparison table inside the answer where relevant
- Coverage should be deep enough to prepare for a Tier-2 DevOps interview
  on the service — not a quick overview, not an exhaustive textbook

---

## Commit Message Prefixes
- docs:  — documentation changes
- feat:  — new infrastructure features
- fix:   — bug fixes
- docu:  — documentation improvements
