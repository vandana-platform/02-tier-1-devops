# Platform Design Decisions

This section explains the architectural and operational decisions made while building the ECS service baseline.

Documenting design decisions is an important platform engineering practice because it helps future engineers understand the reasoning behind system architecture.

---

## Decision 1 — Use ECS Fargate Instead of EC2

The container runtime was implemented using **ECS Fargate** instead of ECS on EC2.

Reasons:

• eliminates infrastructure management for worker nodes  
• simplifies platform operations  
• provides serverless container execution  
• reduces operational overhead for early platform stages  

For a Tier-1 platform baseline, Fargate allows the system to focus on **container orchestration rather than cluster management**.

Future platform iterations may introduce **EKS clusters** for Kubernetes-based workloads.

---

## Decision 2 — Separate Application and Infrastructure Layers

The repository structure separates application code from infrastructure configuration.

```
app/
docker/
terraform/
```

This separation improves:

• maintainability  
• infrastructure reproducibility  
• CI/CD pipeline integration  
• platform reuse across services

It also aligns with common platform engineering repository patterns.

---

## Decision 3 — Validate Infrastructure With Minimal Applications

Initially a **full backend application** was used for testing.

However the application introduced failures unrelated to the platform infrastructure.

Examples included:

• database configuration  
• environment variables  
• authentication dependencies

To isolate infrastructure validation, a **minimal FastAPI application** was used.

This ensures platform debugging focuses on:

• container runtime  
• ECS orchestration  
• Terraform infrastructure configuration

This approach is widely used in platform engineering when validating infrastructure layers.

---

## Decision 4 — Local Container Validation Before Cloud Deployment

Container images are validated locally using Docker before pushing them to ECR.

```
docker run -p 8000:8000 fastapi-ecs
```

This prevents unnecessary debugging in cloud environments.

Local validation helps identify:

• container startup failures  
• dependency issues  
• runtime errors

before deployment to ECS.

---

## Decision 5 — Infrastructure as Code With Terraform

Terraform is used to provision the ECS infrastructure.

Benefits include:

• repeatable infrastructure deployment  
• version-controlled infrastructure  
• automated environment provisioning  
• easier CI/CD integration

Infrastructure as Code is a core principle in modern DevOps and platform engineering.

---

# Operational Lessons Learned

Several practical lessons were learned while deploying the ECS service.

### Python Module Naming Rules

Python modules cannot contain hyphens.

Example:

```
simple-api   ❌ invalid
simple_api   ✅ valid
```

---

### Docker Build Context

Docker builds require correct execution directories.

Incorrect working directories can cause build errors such as:

```
lstat docker: no such file
```

---

### ASGI Application Path

FastAPI applications require the correct module reference when starting uvicorn.

Correct example:

```
uvicorn app.simple_api.app:app
```

Incorrect module paths will cause container startup failures.

---

# Platform Engineering Perspective

This repository represents a **baseline application runtime service** within a multi-system cloud platform architecture.

In a mature platform environment, this service would integrate with additional platform capabilities such as:

• CI/CD pipelines  
• centralized logging and observability  
• service mesh networking  
• platform security controls  
• automated scaling policies  

These integrations will be implemented in future platform systems.
