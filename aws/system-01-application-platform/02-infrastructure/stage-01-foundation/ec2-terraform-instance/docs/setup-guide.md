# Setup Guide — EC2 Terraform Instance

Step-by-step instructions to deploy, verify, and tear down the EC2 Terraform Instance using Terraform.

This module provisions a `t3.micro` Amazon Linux 2 EC2 instance with an SSH-enabled security group in AWS. It demonstrates basic compute provisioning as part of the Tier-1 DevOps platform engineering foundation.

---

## Prerequisites

| Requirement | Version / Notes |
|-------------|----------------|
| Terraform CLI | `>= 1.5.0` — [install guide](https://developer.hashicorp.com/terraform/install) |
| AWS CLI | `>= 2.x` — [install guide](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) |
| AWS credentials | Configured via `aws configure`, environment variables, or an IAM role |
| IAM permissions | `ec2:RunInstances`, `ec2:DescribeInstances`, `ec2:TerminateInstances`, `ec2:CreateSecurityGroup`, `ec2:AuthorizeSecurityGroupIngress`, `ec2:DeleteSecurityGroup` |

---

## 1. Clone / Navigate to the Project

```bash
cd 02-tier-1-devops/aws/system-01-application-platform/02-infrastructure/stage-01-foundation/ec2-terraform-instance
```

---

## 2. Configure AWS Credentials

Verify that the correct AWS account and region are active before proceeding:

```bash
aws configure list
aws sts get-caller-identity
```

Expected output includes your `Account`, `UserId`, and `Arn`. If the output is wrong, re-run `aws configure` or export the appropriate environment variables:

```bash
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-east-1"
```

---

## 3. Initialize Terraform

Downloads the AWS provider plugin and sets up the local backend:

```bash
terraform init
```

Expected output:

```
Initializing the backend...
Initializing provider plugins...
- Finding hashicorp/aws versions matching "~> 5.0"...
- Installing hashicorp/aws v5.x.x...

Terraform has been successfully initialized!
```

> If you see provider download errors, check your internet connection or configure a private Terraform registry mirror.

---

## 4. Validate the Configuration

Checks syntax and internal consistency without contacting AWS:

```bash
terraform validate
```

Expected output:

```
Success! The configuration is valid.
```

---

## 5. Review the Execution Plan

Generates a diff of what Terraform will create, change, or destroy:

```bash
terraform plan
```

Review the plan output carefully. You should see **2 resources to add**:

```
Plan: 2 to add, 0 to change, 0 to destroy.
```

The two resources are:

- `aws_security_group.ec2_security_group`
- `aws_instance.tier1_ec2_instance`

To override the default region or instance type:

```bash
terraform plan -var="aws_region=us-west-2" -var="instance_type=t2.micro"
```

To save the plan for use in the apply step:

```bash
terraform plan -out=tfplan
```

---

## 6. Apply the Infrastructure

Provisions all resources in AWS:

```bash
terraform apply
```

Terraform will display the plan again and prompt for confirmation:

```
Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes
```

Type `yes` and press Enter.

To apply a saved plan without an interactive prompt (useful in CI/CD):

```bash
terraform apply tfplan
```

Expected output after completion:

```
Apply complete! Resources: 2 added, 0 changed, 0 destroyed.

Outputs:

instance_id = "i-07e76ca4a6776b7c7"
public_ip   = "44.210.102.31"
```

---

## 7. Verify the Instance in AWS

### Via AWS CLI

```bash
# Confirm the instance exists and check its state
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=tier1-ec2-instance" \
  --query "Reservations[*].Instances[*].{ID:InstanceId,State:State.Name,IP:PublicIpAddress}" \
  --output table

# Confirm the security group exists
aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=tier1-ec2-sg" \
  --query "SecurityGroups[*].{ID:GroupId,Name:GroupName,Description:Description}" \
  --output table
```

### Via AWS Console

1. Open the [EC2 Console](https://console.aws.amazon.com/ec2/home).
2. Navigate to **Instances** and search for `tier1-ec2-instance`.
3. Confirm the instance state shows **running**.
4. Navigate to **Security Groups** and confirm `tier1-ec2-sg` is attached with port 22 open on inbound rules.

### Via Terraform Output

```bash
terraform output instance_id
terraform output public_ip
```

---

## 8. Review Terraform State

Inspect the local state to confirm all resources are tracked:

```bash
terraform state list
```

Expected output:

```
aws_instance.tier1_ec2_instance
aws_security_group.ec2_security_group
```

---

## 9. Destroy the Infrastructure

Removes all provisioned resources. **This is irreversible and will terminate the EC2 instance.**

```bash
terraform destroy
```

Terraform will display the destroy plan and prompt for confirmation:

```
Do you really want to destroy all resources?
  Terraform will destroy all your managed infrastructure, as shown above.
  There is no undo. Only 'yes' will be accepted to confirm.

  Enter a value: yes
```

Expected output:

```
Destroy complete! Resources: 2 destroyed.
```

> **Cost control:** EC2 instances accrue charges while running. Always destroy this stack when it is no longer needed to avoid unexpected AWS costs. A `t3.micro` instance costs approximately $0.0104/hour in `us-east-1`.

---

## Optional: Targeting a Specific Region or Instance Type

All commands support the `-var` flag to override defaults:

```bash
terraform apply \
  -var="aws_region=us-west-2" \
  -var="instance_type=t2.micro"
```

Alternatively, create a `terraform.tfvars` file:

```hcl
aws_region    = "us-west-2"
instance_type = "t2.micro"
```
