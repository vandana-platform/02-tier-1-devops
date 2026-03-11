# Setup Guide

## Prerequisites

| Tool | Version | Notes |
|---|---|---|
| Terraform | `>= 1.5.0` | [Install](https://developer.hashicorp.com/terraform/install) |
| AWS CLI | v2 | [Install](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) |
| AWS credentials | — | Must have EC2 and security group permissions |

---

## 1. Configure AWS Credentials

```bash
aws configure
```

Provide: Access Key ID, Secret Access Key, region (`us-east-1`), output format (`json`).

Verify:
```bash
aws sts get-caller-identity
```

---

## 2. Clone and Navigate

```bash
cd ec2-terraform-instance/
```

---

## 3. Initialize Terraform

Downloads the AWS provider plugin and sets up the working directory.

```bash
terraform init
```

---

## 4. Review the Plan

```bash
terraform plan
```

Expected: 2 resources to add — `aws_security_group` and `aws_instance`.

---

## 5. Apply

```bash
terraform apply
```

Type `yes` when prompted. On success, outputs are printed:

```
instance_id = "i-07e76ca4a6776b7c7"
public_ip   = "44.210.102.31"
```

---

## 6. Verify

```bash
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=tier1-ec2-instance" \
  --query "Reservations[*].Instances[*].{ID:InstanceId,State:State.Name,IP:PublicIpAddress}" \
  --output table
```

---

## 7. Destroy

```bash
terraform destroy
```

Always destroy when done to avoid unnecessary AWS charges.

---

## Override Variables

```bash
terraform apply \
  -var="aws_region=us-west-2" \
  -var="instance_type=t2.micro"
```
