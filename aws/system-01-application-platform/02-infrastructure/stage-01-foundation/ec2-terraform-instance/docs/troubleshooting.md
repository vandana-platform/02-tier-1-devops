# Troubleshooting — EC2 Terraform Instance

Common issues encountered when working with this Terraform module and their solutions.

---

## 1. Terraform Initialization Errors

### `Failed to install provider`

**Symptom:**

```
Error: Failed to install provider
Could not retrieve the list of available versions for provider hashicorp/aws.
```

**Cause:** No internet access, or a corporate proxy is blocking the Terraform Registry.

**Fix:**
- Verify connectivity: `curl -I https://registry.terraform.io`
- If behind a proxy, set the proxy environment variables:
  ```bash
  export HTTPS_PROXY=http://proxy.example.com:8080
  export HTTP_PROXY=http://proxy.example.com:8080
  ```
- Alternatively, use a locally mirrored provider with `terraform init -plugin-dir=/path/to/providers`.

---

### `Lock file conflict after provider upgrade`

**Symptom:**

```
Error: Inconsistent dependency lock file
The lock file does not contain a suitable checksum for provider "hashicorp/aws".
```

**Cause:** The `.terraform.lock.hcl` file was committed with checksums for a different OS or architecture.

**Fix:**
```bash
terraform providers lock \
  -platform=linux_amd64 \
  -platform=darwin_amd64 \
  -platform=windows_amd64 \
  registry.terraform.io/hashicorp/aws
```

---

## 2. AWS Permission Errors

### `AuthFailure` — Invalid AWS Credentials

**Symptom:**

```
Error: configuring Terraform AWS Provider: no valid credential sources found
```

**Cause:** Terraform cannot locate valid AWS credentials. This occurs when no credentials file, environment variables, or IAM role are configured.

**Fix:**
```bash
aws configure
aws sts get-caller-identity  # verify credentials are active
```

Ensure one of the following credential sources is available:
- `~/.aws/credentials` with a valid profile
- `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` environment variables
- An attached IAM instance profile (if running on EC2)

---

### `ExpiredToken` or `InvalidClientTokenId`

**Symptom:**

```
Error: operation error EC2: ..., ExpiredTokenException
```

**Cause:** Temporary credentials (STS / SSO session) have expired.

**Fix:**
```bash
# For AWS SSO
aws sso login --profile <profile-name>

# For MFA-based sessions, re-generate the token
aws sts get-session-token --serial-number arn:aws:iam::ACCOUNT:mfa/USER --token-code 123456
```

---

### `AccessDenied` on `ec2:RunInstances`

**Symptom:**

```
Error: creating EC2 Instance: UnauthorizedOperation: You are not authorized to perform this operation.
```

**Cause:** The IAM identity executing Terraform lacks the required EC2 permissions.

**Fix:**
1. Confirm which identity is in use:
   ```bash
   aws sts get-caller-identity
   ```
2. Attach or inline a policy that includes at minimum:
   ```json
   {
     "Effect": "Allow",
     "Action": [
       "ec2:RunInstances",
       "ec2:DescribeInstances",
       "ec2:TerminateInstances",
       "ec2:CreateSecurityGroup",
       "ec2:AuthorizeSecurityGroupIngress",
       "ec2:DeleteSecurityGroup",
       "ec2:DescribeSecurityGroups",
       "ec2:DescribeImages",
       "ec2:DescribeKeyPairs"
     ],
     "Resource": "*"
   }
   ```

---

## 3. EC2 Launch Failures

### `InvalidParameterCombination` — Instance Type Not Free Tier Eligible

**Symptom:**

```
Error: creating EC2 Instance: InvalidParameterCombination:
  T1 instances are not supported for this AMI.
```

**Cause:** The selected instance type (e.g., `t1.micro`) is not compatible with the AMI or not Free Tier eligible in the target region.

**Fix:** Update `instance_type` to `t3.micro` in `variables.tf` or pass it at apply time:
```bash
terraform apply -var="instance_type=t3.micro"
```

---

### `AMI Not Found in Region`

**Symptom:**

```
Error: InvalidAMIID.NotFound: The image id '[ami-...]' does not exist
```

**Cause:** The AMI `ami-0c02fb55956c7d316` is region-specific (`us-east-1`). AMI IDs differ across regions.

**Fix:** Either keep `aws_region = "us-east-1"` or look up the equivalent AMI ID for your target region:
```bash
aws ec2 describe-images \
  --owners amazon \
  --filters "Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2" \
  --query "sort_by(Images, &CreationDate)[-1].ImageId" \
  --region us-west-2
```

---

### `InsufficientInstanceCapacity`

**Symptom:**

```
Error: creating EC2 Instance: InsufficientInstanceCapacity: There is no Spot capacity available
that matches your request, or we're unable to fulfill your current On-Demand request in the
Availability Zone you requested.
```

**Cause:** AWS does not have sufficient capacity to launch the requested instance type in the selected Availability Zone.

**Fix:**
- Try a different Availability Zone by specifying a subnet in another AZ:
  ```hcl
  resource "aws_instance" "app_server" {
    ami               = var.ami_id
    instance_type     = var.instance_type
    availability_zone = "us-east-1b"  # try a different AZ
  }
  ```
- Try an alternative instance type of equivalent size (e.g., `t3a.micro` instead of `t3.micro`).
- Wait a few minutes and retry — capacity issues are often transient.

---

### `VPCIdNotSpecified` — No Default VPC

**Symptom:**

```
Error: creating EC2 Instance: VPCIdNotSpecified: No default VPC for this user
```

**Cause:** The target region has no default VPC, which was either deleted or never existed.

**Fix:**
- Recreate the default VPC via the AWS console or CLI:
  ```bash
  aws ec2 create-default-vpc --region us-east-1
  ```
- Or explicitly specify a VPC subnet in `main.tf`:
  ```hcl
  resource "aws_instance" "app_server" {
    ami           = var.ami_id
    instance_type = var.instance_type
    subnet_id     = "subnet-xxxxxxxx"
  }
  ```

---

## 4. Security Group Configuration Issues

### `InvalidGroup.Duplicate` — Security Group Already Exists

**Symptom:**

```
Error: InvalidGroup.Duplicate: The security group 'tier1-ec2-sg' already exists
```

**Cause:** A security group with the same name exists in the VPC but is not tracked in Terraform state (e.g., created manually or from a previous partial apply).

**Fix:** Import the existing security group into Terraform state:
```bash
terraform import aws_security_group.ec2_security_group <sg-id>
```

To find the security group ID:
```bash
aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=tier1-ec2-sg" \
  --query "SecurityGroups[0].GroupId" \
  --output text
```

Or destroy and recreate if the group is unused:
```bash
terraform destroy -target=aws_security_group.ec2_security_group
terraform apply
```

---

### Security Group Rule Blocking Expected Traffic

**Symptom:** Instance launches successfully but inbound traffic (e.g., SSH on port 22, HTTP on port 80) is refused or times out.

**Cause:** The security group inbound rules do not permit traffic on the required port, or the source CIDR is incorrect.

**Fix:** Verify the current rules:
```bash
aws ec2 describe-security-groups \
  --group-ids <sg-id> \
  --query "SecurityGroups[0].IpPermissions"
```

Ensure the security group resource in `main.tf` includes the necessary ingress rule:
```hcl
ingress {
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]  # restrict to your IP in production
}
```

After updating, apply the change:
```bash
terraform apply
```

---

## 5. SSH Connectivity Problems

### `Connection timed out` or `Connection refused`

**Symptom:**

```
ssh: connect to host <public-ip> port 22: Connection timed out
```

**Cause:** One or more of the following:
- The instance has not yet fully booted (user data still running).
- The security group does not allow inbound SSH (port 22).
- The instance is in a private subnet with no public IP.

**Fix:**
1. Wait 1–2 minutes after `terraform apply` for the instance to finish initialising.
2. Confirm the security group permits SSH:
   ```bash
   aws ec2 describe-security-groups --group-ids <sg-id>
   ```
3. Confirm the instance has a public IP:
   ```bash
   terraform output instance_public_ip
   ```
4. If the instance is in a private subnet, connect via a bastion host or AWS Systems Manager Session Manager instead.

---

### `Permission denied (publickey)`

**Symptom:**

```
ec2-user@<ip>: Permission denied (publickey).
```

**Cause:** The SSH key pair used to connect does not match the key pair associated with the instance at launch.

**Fix:**
1. Confirm which key pair is attached to the instance:
   ```bash
   aws ec2 describe-instances \
     --instance-ids <instance-id> \
     --query "Reservations[0].Instances[0].KeyName" \
     --output text
   ```
2. Ensure you are connecting with the corresponding private key:
   ```bash
   ssh -i ~/.ssh/<key-name>.pem ec2-user@<public-ip>
   ```
3. Check key file permissions — SSH requires the private key to be readable only by the owner:
   ```bash
   chmod 400 ~/.ssh/<key-name>.pem
   ```

---

### `Key pair does not exist`

**Symptom:**

```
Error: creating EC2 Instance: InvalidKeyPair.NotFound: The key pair 'my-key' does not exist
```

**Cause:** The key pair name referenced in `main.tf` or `variables.tf` does not exist in the target region.

**Fix:**
- List available key pairs in the region:
  ```bash
  aws ec2 describe-key-pairs --query "KeyPairs[*].KeyName" --output table
  ```
- Create a new key pair if needed:
  ```bash
  aws ec2 create-key-pair --key-name my-key --query "KeyMaterial" --output text > ~/.ssh/my-key.pem
  chmod 400 ~/.ssh/my-key.pem
  ```
- Update `key_name` in `variables.tf` to match an existing key pair.

---

## 6. Terraform State Problems

### State file missing or corrupted

**Symptom:**

```
Error: No state file was found!
```

or Terraform plans to recreate resources that already exist in AWS.

**Cause:** `terraform.tfstate` was deleted, moved, or corrupted.

**Fix:**
- If the instance and security group still exist in AWS, re-import each resource:
  ```bash
  terraform import aws_instance.app_server <instance-id>
  terraform import aws_security_group.ec2_security_group <sg-id>
  ```
- If a backup exists, restore it:
  ```bash
  cp terraform.tfstate.backup terraform.tfstate
  ```

---

### Concurrent state lock error

**Symptom:**

```
Error: Error acquiring the state lock
```

**Cause:** Another Terraform process is running, or a previous run crashed without releasing the lock. This is less common with local state but can occur with remote backends.

**Fix:**
```bash
terraform force-unlock <LOCK_ID>
```

Use `force-unlock` only after confirming no other Terraform process is actively running against this state.

---

### Resource already exists in AWS but not in state

**Symptom:** `terraform plan` shows resources will be created, but the apply fails with a duplicate resource error (e.g., `InvalidGroup.Duplicate`).

**Cause:** Resources were created outside of Terraform (manually or from a previous run that lost its state file).

**Fix:** Import the orphaned resources into state before re-applying:
```bash
# Instance
terraform import aws_instance.app_server <instance-id>

# Security group
terraform import aws_security_group.ec2_security_group <sg-id>
```

Then run `terraform plan` to confirm the state matches the live infrastructure before applying further changes.

---

## 7. Provider Version Issues

### `Unsupported argument` for deprecated EC2 attributes

**Symptom:**

```
Error: Unsupported argument
An argument named "ebs_optimized" is not expected here.
```

**Cause:** Certain arguments were moved or renamed in newer versions of the AWS provider.

**Fix:** Check the [AWS provider changelog](https://github.com/hashicorp/terraform-provider-aws/blob/main/CHANGELOG.md) for the breaking change and update the resource block accordingly. Refer to `versions.tf` for the required provider constraint and ensure your local provider matches:
```bash
terraform version
terraform providers
```

---

### `Required Terraform version not met`

**Symptom:**

```
Error: Unsupported Terraform Core version
This configuration does not support Terraform version X.Y.Z.
```

**Cause:** The installed Terraform binary is older than `>= 1.5.0` as required by `versions.tf`.

**Fix:** Upgrade Terraform:
```bash
# Using tfenv (recommended)
tfenv install 1.9.0
tfenv use 1.9.0

# Verify
terraform version
```

---

## 8. Outputs Not Visible After Apply

**Symptom:** After a successful `terraform apply`, no output values are printed.

**Cause:** Outputs are only printed when they change. If the infrastructure already existed and no changes were made, outputs may not be re-displayed.

**Fix:** Query outputs explicitly:
```bash
terraform output
```

Or refresh state without making changes:
```bash
terraform apply -refresh-only
```
