#!/usr/bin/env python3

"""
Platform Repository Bootstrap Script

Creates the standard platform engineering repository structure
for multi-cloud DevOps systems.

Author: Vandana T
"""

import os

providers = ["aws", "azure", "cross-cloud"]

systems = [
    "system-01-application-platform",
    "system-02-networking-platform",
    "system-03-data-platform",
    "system-04-devops-platform",
    "system-05-observability-platform",
    "system-06-security-platform",
]

capabilities = [
    "01-architecture",
    "02-infrastructure",
    "03-services",
    "04-ci-cd",
    "05-observability",
    "06-security",
]

stages = [
    "stage-01-foundation",
    "stage-02-production",
    "stage-03-scalability",
]

for provider in providers:
    for system in systems:
        for capability in capabilities:

            path = f"{provider}/{system}/{capability}"
            os.makedirs(path, exist_ok=True)

            if capability != "01-architecture":
                for stage in stages:
                    stage_path = f"{path}/{stage}"
                    os.makedirs(stage_path, exist_ok=True)

                    gitkeep = f"{stage_path}/.gitkeep"
                    open(gitkeep, "a").close()

        # architecture docs
        arch_path = f"{provider}/{system}/01-architecture"
        open(f"{arch_path}/01-system-context.md", "a").close()
        open(f"{arch_path}/02-platform-overview.md", "a").close()
        open(f"{arch_path}/03-deployment-architecture.drawio", "a").close()

print("Platform structure generated.")
