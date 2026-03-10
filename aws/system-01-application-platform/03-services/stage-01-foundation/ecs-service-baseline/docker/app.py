# Platform Test Application
#
# This file defines a minimal FastAPI application used to validate the
# container service capability implemented within the Tier-1 DevOps
# Application Platform.
#
# The purpose of this application is not to implement business logic.
# Instead, it serves as a lightweight validation workload that allows
# the platform infrastructure to be tested end-to-end.
#
# This application verifies that the platform can successfully:
#
# • Build container images using Docker
# • Push container images to Amazon ECR
# • Define container workloads using ECS task definitions
# • Run containers on AWS ECS using the Fargate launch type
# • Maintain service availability through the ECS service layer
#
# By deploying this application, engineers can confirm that the core
# platform components responsible for container orchestration,
# networking, and runtime execution are functioning correctly.
#
# This application therefore acts as a validation workload for the
# ECS service baseline defined in the Tier-1 DevOps platform layer.


from fastapi import FastAPI

app = FastAPI(
    title="Tier-1 DevOps Platform Validation API",
    description="Minimal FastAPI service used to validate ECS container platform deployment.",
    version="1.0.0"
)


@app.get("/")
def root():
    return {
        "message": "FastAPI application running successfully on AWS ECS Fargate",
        "platform_layer": "Tier-1 DevOps Application Platform",
        "status": "service operational"
    }


@app.get("/health")
def health():
    return {
        "status": "healthy",
        "service": "fastapi-ecs-service"
    }


@app.get("/version")
def version():
    return {
        "application": "fastapi-ecs-service",
        "version": "1.0.0",
        "platform": "AWS ECS Fargate"
    }
