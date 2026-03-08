
# Platform Bootstrap Scripts

This directory contains helper scripts used to scaffold
platform repository structures.

## bootstrap_platform_structure.py

This script generates the standard multi-cloud platform layout used
in the Tier-1 DevOps repository.

The generated structure includes:

• Cloud providers (AWS, Azure, Cross-Cloud)  
• Platform systems  
• Platform capabilities  
• Deployment maturity stages  

The script can also be reused for higher-tier platform repositories
(Tier-2, Tier-3, etc.) with minor modifications.

## Usage

Run from the repository root:

python scripts/bootstrap_platform_structure.py
