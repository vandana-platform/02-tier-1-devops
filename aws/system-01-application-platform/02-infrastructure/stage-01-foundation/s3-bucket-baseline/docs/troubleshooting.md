# Troubleshooting — S3 Bucket Baseline

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

### `AccessDenied` on `s3:CreateBucket`

**Symptom:**

```
Error: creating S3 Bucket (tier1-platform-baseline-demo-bucket):
operation error S3: CreateBucket, https response error StatusCode: 403, AccessDenied
```

**Cause:** The IAM identity executing Terraform lacks the required S3 permissions.

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
       "s3:CreateBucket",
       "s3:PutBucketVersioning",
       "s3:PutEncryptionConfiguration",
       "s3:PutBucketPublicAccessBlock",
       "s3:GetBucketVersioning",
       "s3:GetEncryptionConfiguration",
       "s3:GetPublicAccessBlock",
       "s3:DeleteBucket"
     ],
     "Resource": "arn:aws:s3:::tier1-platform-baseline-demo-bucket"
   }
   ```

---

### `ExpiredToken` or `InvalidClientTokenId`

**Symptom:**

```
Error: operation error S3: ..., ExpiredTokenException
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

## 3. Bucket Name Conflicts

### `BucketAlreadyExists`

**Symptom:**

```
Error: creating S3 Bucket: BucketAlreadyExists: The requested bucket name is not available.
```

**Cause:** S3 bucket names are globally unique. Another AWS account already owns `tier1-platform-baseline-demo-bucket`.

**Fix:** Rename the bucket in `main.tf` to something unique, e.g., append your AWS account ID or a random suffix:

```hcl
bucket = "tier1-platform-baseline-demo-bucket-${data.aws_caller_identity.current.account_id}"
```

---

### `BucketAlreadyOwnedByYou`

**Symptom:**

```
Error: creating S3 Bucket: BucketAlreadyOwnedByYou
```

**Cause:** The bucket already exists in your account (possibly from a previous partial apply) but is not tracked in Terraform state.

**Fix:** Import the existing bucket into state:

```bash
terraform import aws_s3_bucket.platform_baseline_bucket tier1-platform-baseline-demo-bucket
```

Then re-run `terraform plan` to reconcile any configuration drift.

---

## 4. Provider Version Issues

### `Unsupported argument` for inline sub-resources

**Symptom:**

```
Error: Unsupported argument
An argument named "versioning" is not expected here.
```

**Cause:** An inline `versioning {}` block was used inside `aws_s3_bucket`. This syntax was deprecated and removed in AWS provider v4+.

**Fix:** Use the standalone `aws_s3_bucket_versioning` resource as shown in `main.tf`:

```hcl
resource "aws_s3_bucket_versioning" "platform_baseline_versioning" {
  bucket = aws_s3_bucket.platform_baseline_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}
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

## 5. Terraform State Problems

### State file missing or corrupted

**Symptom:**

```
Error: No state file was found!
```
or Terraform plans to recreate resources that already exist in AWS.

**Cause:** `terraform.tfstate` was deleted, moved, or corrupted.

**Fix:**
- If the bucket still exists in AWS, re-import each resource:
  ```bash
  terraform import aws_s3_bucket.platform_baseline_bucket tier1-platform-baseline-demo-bucket
  terraform import aws_s3_bucket_versioning.platform_baseline_versioning tier1-platform-baseline-demo-bucket
  terraform import aws_s3_bucket_server_side_encryption_configuration.platform_baseline_encryption tier1-platform-baseline-demo-bucket
  terraform import aws_s3_bucket_public_access_block.platform_baseline_public_access tier1-platform-baseline-demo-bucket
  ```
- If a backup exists, restore it:
  ```bash
  cp terraform.tfstate.backup terraform.tfstate
  ```

---

### `terraform destroy` fails because bucket is not empty

**Symptom:**

```
Error: deleting S3 Bucket: BucketNotEmpty: The bucket you tried to delete is not empty.
```

**Cause:** Versioned buckets retain delete markers and non-current versions that prevent deletion.

**Fix — Option A (manual):** Empty the bucket via AWS CLI before destroying:
```bash
# Delete all versions and delete markers
aws s3api list-object-versions \
  --bucket tier1-platform-baseline-demo-bucket \
  --output json \
  | jq -r '.Versions[]?, .DeleteMarkers[]? | "\(.Key) \(.VersionId)"' \
  | while read key version; do
      aws s3api delete-object \
        --bucket tier1-platform-baseline-demo-bucket \
        --key "$key" \
        --version-id "$version"
    done

terraform destroy
```

**Fix — Option B (Terraform):** Add `force_destroy = true` to the bucket resource, apply, then destroy:
```hcl
resource "aws_s3_bucket" "platform_baseline_bucket" {
  bucket        = "tier1-platform-baseline-demo-bucket"
  force_destroy = true
  ...
}
```

---

### Concurrent state lock error

**Symptom:**

```
Error: Error acquiring the state lock
```

**Cause:** Another Terraform process is running, or a previous run crashed without releasing the lock. (This is less common with local state but can occur with remote backends.)

**Fix:**
```bash
terraform force-unlock <LOCK_ID>
```

Use `force-unlock` only after confirming no other Terraform process is actively running against this state.
