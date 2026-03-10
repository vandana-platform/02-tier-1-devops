
# ECS Service Baseline — Application Platform (Tier-1 DevOps)

## Overview

This repository implements the **baseline container runtime service** for the **Application Platform** within the Tier-1 DevOps architecture.

The goal of this system is to establish a **repeatable deployment pattern for containerized workloads** using:

• Docker  
• Amazon ECR  
• AWS ECS Fargate  
• Terraform Infrastructure as Code  

This repository demonstrates the fundamental workflow required to deploy containerized workloads in a cloud environment while maintaining infrastructure reproducibility.

---

# Platform Architecture

The system follows a standard container deployment lifecycle used in modern cloud platforms.

```
Developer Machine
      │
      │ Build Container
      ▼
Docker Image
      │
      │ Push
      ▼
Amazon ECR
      │
      │ ECS pulls image
      ▼
ECS Cluster
      │
      ▼
ECS Service
      │
      ▼
Running Container Task
```

The container runtime executes using **AWS ECS Fargate**, which allows container workloads to run without managing EC2 infrastructure.

---

# Repository Structure

```
ecs-service-baseline
│
├── README.md
│
├── app
│   └── simple_api
│       └── app.py
│
├── docker
│   └── Dockerfile
│
└── terraform
    ├── ecs-cluster.tf
    ├── ecs-service.tf
    ├── task-definition.tf
    ├── variables.tf
    └── outputs.tf
```

Each directory represents a specific capability of the platform service.

---

# File and Directory Explanation

This section explains the responsibility of each directory and important files in the repository.

Understanding the repository structure is important for maintainability and future platform automation.

---

## app/

The `app` directory contains the application workload used to validate the container runtime.

Directory structure:

```
app/
 └── simple_api/
      └── app.py
```

### app/simple_api/app.py

This file contains a minimal FastAPI application used for validating the container runtime.

Example:

```python
from fastapi import FastAPI

app = FastAPI()

@app.get("/")
def root():
    return {"message": "Hello from ECS Fargate"}
```

The application exposes a simple HTTP endpoint that allows verification that:

• the container starts correctly  
• ECS tasks run successfully  
• networking configuration is functional  

The minimal application ensures infrastructure debugging focuses on platform components rather than application complexity.

---

## docker/

The `docker` directory contains the container build configuration.

Directory structure:

```
docker/
 └── Dockerfile
```

### docker/Dockerfile

The Dockerfile defines how the container image is built.

Responsibilities:

• define base image  
• configure container runtime environment  
• install required dependencies  
• define container startup command  

Example Dockerfile:

```
FROM python:3.11-slim

WORKDIR /app

COPY . /app

RUN pip install fastapi uvicorn

EXPOSE 8000

CMD ["uvicorn", "app.simple_api.app:app", "--host", "0.0.0.0", "--port", "8000"]
```

The container image built from this Dockerfile is pushed to Amazon ECR and used by ECS.

---

## terraform/

The `terraform` directory contains the Infrastructure as Code used to provision the ECS environment.

Directory structure:

```
terraform/
 ├── ecs-cluster.tf
 ├── ecs-service.tf
 ├── task-definition.tf
 ├── variables.tf
 └── outputs.tf
```

### ecs-cluster.tf

Defines the ECS cluster that hosts container workloads.

Responsibilities:

• create ECS cluster resource  
• configure cluster settings  

---

### task-definition.tf

Defines the ECS task definition.

Responsibilities:

• container image reference  
• CPU and memory configuration  
• container port mappings  
• container runtime configuration  

---

### ecs-service.tf

Defines the ECS service responsible for maintaining running tasks.

Responsibilities:

• desired number of running tasks  
• cluster association  
• deployment strategy  
• task definition reference  

---

### variables.tf

Contains Terraform input variables used to parameterize infrastructure configuration.

Variables allow infrastructure to remain reusable across environments.

---

### outputs.tf

Defines output values exposed after Terraform deployment.

Examples include:

• ECS cluster name  
• service identifiers  
• resource ARNs  

---

# Application Strategy

Initially a **full backend application (FastAPI RealWorld backend)** was used to simulate a production service.

However the application required additional dependencies such as:

• PostgreSQL database  
• authentication configuration  
• environment variables  

These dependencies introduced failures unrelated to platform infrastructure.

To isolate platform validation, the application was replaced with a **minimal FastAPI service**.

This allows debugging to focus on:

• container runtime  
• ECS orchestration  
• Terraform infrastructure  

This approach is commonly used in platform engineering when validating infrastructure layers.

---

# Containerization

The application is packaged into a Docker container.

Build the container image:

```
docker build -t fastapi-ecs -f docker/Dockerfile .
```

The `.` indicates the Docker build context.

---

# Local Container Validation

Before deploying to ECS, the container should be tested locally.

```
docker run -p 8000:8000 fastapi-ecs
```

Expected output:

```
Uvicorn running on http://0.0.0.0:8000
```

Local testing ensures that container startup issues are detected before cloud deployment.

---

# Container Registry (Amazon ECR)

The container image is pushed to Amazon ECR.

Tag image:

```
docker tag fastapi-ecs:latest \
ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/fastapi-ecs-repo:latest
```

Push image:

```
docker push \
ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/fastapi-ecs-repo:latest
```

ECS retrieves the container image from ECR during deployment.

---

# Infrastructure Deployment (Terraform)

Infrastructure is provisioned using Terraform.

Terraform creates:

• ECS cluster  
• ECS task definition  
• ECS service  
• IAM execution roles  

Terraform ensures infrastructure is reproducible and version controlled.

---

# Service Deployment

After pushing the container image to ECR, the ECS service is redeployed.

```
aws ecs update-service \
--cluster tier1-ecs-cluster \
--service fastapi-service \
--force-new-deployment
```

This forces ECS to start new tasks using the updated container image.

---

# Deployment Verification

List running tasks:

```
aws ecs list-tasks --cluster tier1-ecs-cluster
```

Check task status:

```
aws ecs describe-tasks \
--cluster tier1-ecs-cluster \
--tasks TASK_ID \
--query 'tasks[0].lastStatus'
```

Expected result:

```
RUNNING
```

---

# Issues Encountered During Deployment

## Container Exited Immediately

Error:

```
Essential container in task exited
exitCode: 1
```

Cause:

The original backend application required database configuration and environment variables.

Resolution:

Replace the backend with a minimal API.

---

## Incorrect ASGI Application Path

Error:

```
Error loading ASGI app
```

Cause:

Incorrect uvicorn module reference.

Correct configuration:

```
uvicorn app.simple_api.app:app
```

---

## Invalid Python Module Name

Error:

```
ModuleNotFoundError: simple-api
```

Cause:

Python modules cannot contain hyphens.

Resolution:

```
simple-api → simple_api
```

---

## Docker Build Context Error

Error:

```
lstat docker: no such file
```

Cause:

Docker build command executed from the wrong directory.

Resolution:

Execute the build command from the repository root.

---

# Platform Design Decisions

This section documents the architectural decisions made while building this ECS service baseline.

Documenting design decisions helps future engineers understand why the system was implemented in a particular way.

---

## Decision 1 — Use ECS Fargate Instead of EC2

ECS Fargate was selected instead of ECS on EC2.

Reasons:

• eliminates infrastructure management  
• reduces operational overhead  
• simplifies container execution  
• allows focus on platform services rather than cluster management  

Future platform stages may introduce Kubernetes using EKS.

---

## Decision 2 — Separate Application and Infrastructure Layers

The repository separates application code from infrastructure configuration.

```
app/
docker/
terraform/
```

This separation improves:

• maintainability  
• infrastructure reproducibility  
• CI/CD integration  
• platform reuse across services  

---

## Decision 3 — Validate Infrastructure With Minimal Applications

Complex applications introduce failures unrelated to infrastructure.

Using a minimal API ensures debugging focuses on:

• container runtime  
• ECS orchestration  
• Terraform infrastructure  

---

## Decision 4 — Local Container Validation Before Cloud Deployment

Containers are validated locally before deployment.

```
docker run -p 8000:8000 fastapi-ecs
```

This prevents unnecessary cloud debugging.

---

## Decision 5 — Infrastructure as Code With Terraform

Terraform was chosen to provision infrastructure because it provides:

• repeatable deployments  
• version controlled infrastructure  
• environment reproducibility  
• easier CI/CD automation  

---

# Operational Lessons Learned

### Python Module Naming Rules

Python modules cannot contain hyphens.

```
simple-api   ❌ invalid
simple_api   ✅ valid
```

---

### Docker Build Context

Docker builds must be executed from the correct directory.

Incorrect directory usage can cause errors such as:

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

---

# Platform Engineering Perspective

This repository represents a **baseline application runtime service** within a broader platform architecture.

In a mature platform environment this service would integrate with:

• CI/CD pipelines  
• centralized observability  
• service mesh networking  
• platform security controls  
• automated scaling policies  

These capabilities will be introduced in future platform systems.

---

# Platform Roadmap

Future platform systems will include:

```
system-01 application platform
system-02 networking platform
system-03 observability platform
system-04 CI/CD platform
system-05 security platform
```

Each system expands the capabilities of the overall platform architecture.

---

# Conclusion

This project establishes the **baseline ECS container runtime service** for the Application Platform using:

• Docker  
• Amazon ECR  
• AWS ECS Fargate  
• Terraform Infrastructure as Code  

The repository provides a reusable pattern for deploying containerized workloads and forms the foundation for higher-level platform capabilities.
