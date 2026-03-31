
# LAB CONTEXT — Vandana Platform Engineering Lab
# Paste this file at the start of every new Claude chat session

---

## WHO I AM

- **Name:** Vandana T
- **Role:** Platform and DevOps Engineer
- **Experience:** 13 years
- **Goal:** $350K job search — Staff / Principal level roles
- **GitHub Org:** vandana-platform
- **Side Project:** Komplora compliance platform (feed infrastructure patterns into it)

---

## LAB GOAL

Build a real Cloud and Platform Engineering Lab on WSL2, pushed to GitHub.
Show recruiter-ready portfolio that scales from DevOps → Principal level.

**The story I am telling recruiters:**
- Tier 2 = Hands-on, manual, foundational — "I know the fundamentals deeply"
- Tier 3 = More automation, modules, reusability
- Tier 4 = Platform thinking, control planes, governance
- Tier 5 = IDP, abstractions, enterprise patterns
- Tier 6 = Strategy, global architecture, transformation
- `01-platform-core` kicks in at Tier 4+ as shared foundation higher tiers consume

---

## GITHUB REPO STRUCTURE

**Org:** vandana-platform
```
vandana-platform (ORG)
├── 01-platform-core          ← shared foundation, used from Tier 4+
├── 02-tier-1-devops          ← CURRENT FOCUS
├── 03-tier-2-senior-devops
├── 04-tier-3-staff
├── 05-tier-4-platform
├── 06-tier-5-principal
```

---

## LOCAL TECH STACK (WSL2)

- WSL2 + Ubuntu
- Docker Desktop (Windows) + enabled on WSL2
- Kubernetes enabled on Docker + WSL2
- AWS CLI + AWS UI account
- Azure CLI + Azure UI account
- Terraform v1.14.6
- Python 3.12.3 + pip
- Node.js + npm
- GitHub CLI on WSL2
- Helm
- curl / unzip / jq
- Claude Code CLI on WSL2
- Test app repo: https://github.com/borys25ol/fastapi-realworld-backend

---

## RULES WE FOLLOW

- **Branch per project:** `feat/project-name`
- **Delete branch after merge:** `git branch -d feat/name` + `git push origin --delete feat/name`
- **Always:** `terraform init` → `terraform plan` → `terraform apply` → screenshots → `terraform destroy` → commit
- **SSH push fix:** `git remote set-url origin git@github.com:vandana-platform/02-tier-1-devops.git`
- **Pace:** 2 projects/day weekdays, 1 on weekends = 90 projects in 8 weeks
- **Docs:** 5 x .md files created as empty placeholders — fill later with Claude skill
- **Apply rule updated:** apply + screenshot + destroy for ALL BASIC projects
- **Doc pattern per project:** `architecture.md`, `design-decisions.md`, `interview-prep.md`, `setup-guide.md`, `troubleshooting.md`
- **Tier-2 philosophy:** Volume + consistency + pattern. Keep docs short. Save depth for Tier 4/5.
- **project_name in variables.tf:** NEVER use personal name — always use `tier2-<project-folder-name>` e.g. `tier2-alb-baseline`, `tier2-vpc-baseline`
- **Default VPC deleted:** No default VPC in account — always apply vpc-baseline first and use its outputs for projects that need vpc_id and subnet_ids
- **No README.md content:** Create README.md as empty file only — no content needed
- **Commit from anywhere inside repo:** No need to cd to root before git add/commit

---

## PROJECT WORKFLOW

**Step by step for every project:**
1. `git checkout -b feat/<project-name>` from anywhere inside repo
2. `cd aws/<system>/<layer>/<stage>/`
3. `mkdir <project-folder> && cd <project-folder>`
4. `mkdir -p docs/images && touch README.md docs/architecture.md docs/design-decisions.md docs/interview-prep.md docs/setup-guide.md docs/troubleshooting.md`
5. Create `.tf` files using `cat >` commands (never put personal name in project_name)
6. `terraform init` → `terraform plan` → `terraform apply`
7. Take screenshots → `terraform destroy`
8. `git add .` → `git commit -m "feat: ..."` → `git push origin feat/<project-name>`
9. Merge PR on GitHub → `git branch -d feat/<project-name>` → `git push origin --delete feat/<project-name>`

**Naming convention for project_name in variables.tf:**
- Format: `tier2-<project-folder-name>`
- Examples: `tier2-alb-baseline`, `tier2-vpc-baseline`, `tier2-rds-postgres-baseline`
- Never use personal name (vandana) anywhere in resource names

**Screenshot naming convention:**
- Format: `<order>-<project-name>-<resource>.png`
- Examples: `01-tier2-alb-baseline-apply-outputs.png`, `02-tier2-alb-baseline-alb-console.png`
- Save all screenshots under: `docs/images/` inside each project folder

**Screenshot checklist per project:**
- `01` → terminal apply outputs (real IDs and ARNs)
- `02` onwards → one AWS console screenshot per resource created

---

## REPO STRUCTURE PATTERN (Tier-2)

```
02-tier-1-devops/
├── aws/
│   ├── system-01-application-platform/
│   │   ├── 01-architecture/
│   │   ├── 02-infrastructure/
│   │   │   └── stage-01-foundation/
│   │   │       └── <project-folder>/
│   │   │           ├── docs/
│   │   │           │   ├── images/
│   │   │           │   ├── architecture.md
│   │   │           │   ├── design-decisions.md
│   │   │           │   ├── interview-prep.md
│   │   │           │   ├── setup-guide.md
│   │   │           │   └── troubleshooting.md
│   │   │           ├── main.tf
│   │   │           ├── variables.tf
│   │   │           ├── outputs.tf
│   │   │           ├── provider.tf
│   │   │           ├── versions.tf
│   │   │           └── README.md
│   │   ├── 03-services/
│   │   ├── 04-ci-cd/
│   │   ├── 05-observability/
│   │   └── 06-security/
│   ├── system-02-networking-platform/
│   ├── system-03-data-platform/
│   ├── system-04-devops-platform/
│   ├── system-05-observability-platform/
│   └── system-06-security-platform/
├── azure/
├── cross-cloud/
└── scripts/
```

---

## TIER-2 AWS — FULL PROJECT MAPPING TABLE

| # | Level | Project | Platform System | Layer | Stage | Folder Name |
|---|-------|---------|----------------|-------|-------|-------------|
| 1 | BASIC | Launch EC2 using Terraform | system-01-application-platform | 02-infrastructure | stage-01-foundation | ec2-terraform-instance |
| 2 | BASIC | Configure IAM roles and policies | system-06-security-platform | 02-infrastructure | stage-01-foundation | iam-role-baseline |
| 3 | BASIC | Deploy Docker app to ECS | system-01-application-platform | 03-services | stage-01-foundation | ecs-service-baseline |
| 4 | BASIC | Deploy app to EKS cluster | system-01-application-platform | 03-services | stage-01-foundation | eks-cluster-baseline |
| 5 | BASIC | Setup S3 static website hosting | system-03-data-platform | 02-infrastructure | stage-01-foundation | s3-static-site |
| 6 | BASIC | Configure CloudWatch logs and metrics | system-05-observability-platform | 02-infrastructure | stage-01-foundation | cloudwatch-baseline |
| 7 | BASIC | Setup Application Load Balancer | system-02-networking-platform | 02-infrastructure | stage-01-foundation | alb-baseline |
| 8 | BASIC | Create VPC with public/private subnets | system-02-networking-platform | 02-infrastructure | stage-01-foundation | vpc-baseline |
| 9 | BASIC | Setup RDS PostgreSQL | system-03-data-platform | 02-infrastructure | stage-01-foundation | rds-postgres-baseline |
| 10 | BASIC | GitHub Actions pipeline → EC2 deployment | system-04-devops-platform | 04-ci-cd | stage-01-foundation | github-actions-ec2-deploy |
| 11 | MID | Blue/Green deployment on ECS | system-01-application-platform | 03-services | stage-02-production | ecs-bluegreen |
| 12 | MID | Horizontal Pod Autoscaler on EKS | system-01-application-platform | 03-services | stage-02-production | eks-hpa |
| 13 | MID | Integrate AWS Secrets Manager | system-06-security-platform | 03-services | stage-02-production | secrets-manager-integration |
| 14 | MID | Multi-stage CI/CD with artifact versioning | system-04-devops-platform | 04-ci-cd | stage-02-production | multi-stage-pipeline |
| 15 | MID | Route53 with health checks | system-02-networking-platform | 02-infrastructure | stage-02-production | route53-healthchecks |
| 16 | MID | Setup SNS alerts from CloudWatch | system-05-observability-platform | 05-observability | stage-02-production | cloudwatch-sns-alerts |
| 17 | MID | Enable ECR image scanning | system-06-security-platform | 06-security | stage-02-production | ecr-image-scanning |
| 18 | MID | Rolling updates on EKS | system-01-application-platform | 03-services | stage-02-production | eks-rolling-updates |
| 19 | MID | AutoScaling lifecycle hooks | system-01-application-platform | 02-infrastructure | stage-02-production | autoscaling-hooks |
| 20 | MID | Terraform module reusability structure | system-04-devops-platform | 01-architecture | stage-02-production | terraform-module-library |
| 21 | HIGH | Multi-region EKS deployment | system-01-application-platform | 03-services | stage-03-scalability | eks-multi-region |
| 22 | HIGH | Canary deployment using CodeDeploy | system-04-devops-platform | 04-ci-cd | stage-03-scalability | codedeploy-canary |
| 23 | HIGH | Event-driven architecture (SNS + SQS) | system-03-data-platform | 03-services | stage-03-scalability | sns-sqs-events |
| 24 | HIGH | Distributed tracing with X-Ray | system-05-observability-platform | 05-observability | stage-03-scalability | xray-tracing |
| 25 | HIGH | Multi-account AWS setup | system-06-security-platform | 01-architecture | stage-03-scalability | multi-account-setup |
| 26 | HIGH | Cross-region RDS replication | system-03-data-platform | 02-infrastructure | stage-03-scalability | rds-cross-region |
| 27 | HIGH | Chaos engineering on EKS | system-01-application-platform | 03-services | stage-03-scalability | eks-chaos-testing |
| 28 | HIGH | Infrastructure drift detection automation | system-04-devops-platform | 05-observability | stage-03-scalability | terraform-drift-detection |
| 29 | HIGH | Service Mesh (Istio) integration | system-01-application-platform | 03-services | stage-03-scalability | istio-service-mesh |
| 30 | HIGH | Production SLO dashboard (Prometheus + Grafana) | system-05-observability-platform | 05-observability | stage-03-scalability | slo-dashboard |

---

## TIER-2 AZURE — PROJECT LIST

**BASIC (10)**
1. Launch Azure VM using Bicep
2. Configure Azure RBAC roles
3. Deploy container to Azure Container Apps
4. Deploy to AKS cluster
5. Setup Azure Blob storage
6. Configure Azure Monitor logs
7. Setup Azure Application Gateway
8. Create VNet with subnets
9. Deploy Azure SQL Database
10. Azure DevOps pipeline → AKS deployment

**MID (10)**
11. Blue/Green deployment on AKS
12. AKS autoscaling configuration
13. Integrate Azure Key Vault
14. Multi-stage Azure DevOps pipelines
15. Azure DNS with failover
16. Azure Monitor alert rules
17. ACR image scanning
18. Rolling updates on AKS
19. VM Scale Set autoscaling
20. Bicep reusable module architecture

**HIGH (10)**
21. Multi-region AKS deployment
22. Event-driven architecture (Event Grid)
23. Canary deployment in AKS
24. Distributed tracing with App Insights
25. Multi-subscription Azure architecture
26. Cosmos DB multi-region replication
27. Chaos testing in AKS
28. Infrastructure drift detection Azure
29. Service Mesh on AKS
30. Enterprise monitoring dashboard

---

## TIER-2 CROSS-CLOUD — PROJECT LIST

**BASIC (10)**
1. Deploy same app on EKS and AKS
2. Terraform multi-cloud module
3. Compare CloudWatch vs Azure Monitor
4. Multi-cloud DNS routing
5. S3 ↔ Blob replication
6. Multi-cloud CI/CD pipeline
7. GitOps for EKS + AKS
8. Centralized logging across clouds
9. Cost comparison dashboard
10. Multi-cloud autoscaling comparison

**MID (10)**
11. Hybrid cloud architecture
12. Cross-cloud secret management
13. Unified observability stack
14. Multi-cloud VPC/VNet connectivity
15. Cross-cloud DR simulation
16. Global load balancing
17. Cross-cloud service mesh
18. Unified deployment rollback
19. Hybrid database replication
20. Multi-cloud monitoring alerts

**HIGH (10)**
21. Global multi-cloud platform blueprint
22. Cross-cloud identity federation
23. Multi-cloud governance automation
24. Global failover architecture
25. Cross-cloud compliance automation
26. Distributed resilience modeling
27. Unified release orchestration
28. Cross-cloud cost governance engine
29. Enterprise DevOps transformation model
30. Hybrid cloud reference architecture

---

## TIPS SAVED

**Git Auth Fix (SSH):**
```bash
git remote set-url origin git@github.com:vandana-platform/02-tier-1-devops.git
```

**LinkedIn Tip 1:**
"I ran terraform plan as a verification gate before apply — smart DevOps practice worth writing about"

**LinkedIn Tip 2:**
"Applied real infra for first 5 projects to prove I can deploy. Then shifted to speed mode — 2 projects/day, 90 projects in 8 weeks. Here's what I built..."

---

## FILE MANAGEMENT INSTRUCTIONS

**Keep CONTEXT.md and JOURNAL.md local only — never push to GitHub:**
```bash
cd ~/02-tier-1-devops
echo "CONTEXT.md" >> .gitignore
echo "JOURNAL.md" >> .gitignore
git add .gitignore
git commit -m "chore: add CONTEXT.md and JOURNAL.md to gitignore"
git push origin main
```

**Save both files locally on WSL:**
```bash
~/02-tier-1-devops/CONTEXT.md
~/02-tier-1-devops/JOURNAL.md
```

**When moving to a new tier repo (e.g. Tier-3):**
```bash
cp ~/02-tier-1-devops/CONTEXT.md ~/03-tier-2-senior-devops/CONTEXT.md
cp ~/02-tier-1-devops/JOURNAL.md ~/03-tier-2-senior-devops/JOURNAL.md
echo "CONTEXT.md" >> ~/03-tier-2-senior-devops/.gitignore
echo "JOURNAL.md" >> ~/03-tier-2-senior-devops/.gitignore
```
Then update CONTEXT.md "Current Status" section for new tier.
Then start fresh JOURNAL.md entries for new tier, keep old entries as history.

---

## HOW TO USE THESE FILES

**`CONTEXT.md`** — rarely changes, only update when:
- You move to a new tier
- New rules we decide
- New tips saved
- New tech added to stack

**`JOURNAL.md`** — update every session:
- Add new entry with date
- Mark completed projects ✅
- Update "Next Session — Start Here" section

**Every new chat — 3 steps:**
1. Paste `CONTEXT.md` → Claude knows your background + full mapping tables
2. Paste latest `JOURNAL.md` entry → Claude knows exactly where you are
3. Say "continue my lab" → start immediately, no re-explaining!
