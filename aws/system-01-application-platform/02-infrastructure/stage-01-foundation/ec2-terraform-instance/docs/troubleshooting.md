# Troubleshooting

## InvalidParameterCombination — Instance Type Not Free Tier Eligible

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

## AuthFailure — Invalid AWS Credentials

**Symptom:**
```
Error: configuring Terraform AWS Provider: no valid credential sources found
```

**Fix:**
```bash
aws configure
aws sts get-caller-identity  # verify credentials are active
```

---

## AMI Not Found in Region

**Symptom:**
```
Error: InvalidAMIID.NotFound: The image id '[ami-...]' does not exist
```

**Cause:** The AMI `ami-0c02fb55956c7d316` is region-specific (`us-east-1`).

**Fix:** Either keep `aws_region = "us-east-1"` or look up the equivalent AMI ID for your target region:
```bash
aws ec2 describe-images \
  --owners amazon \
  --filters "Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2" \
  --query "sort_by(Images, &CreationDate)[-1].ImageId" \
  --region us-west-2
```

---

## Security Group Already Exists

**Symptom:**
```
Error: InvalidGroup.Duplicate: The security group 'tier1-ec2-sg' already exists
```

**Fix:** Import the existing security group into Terraform state:
```bash
terraform import aws_security_group.ec2_security_group <sg-id>
```

Or destroy and recreate:
```bash
terraform destroy
terraform apply
```

---

## Outputs Not Visible After Apply

Run:
```bash
terraform output
```

Or re-apply without changes:
```bash
terraform apply -refresh-only
```
