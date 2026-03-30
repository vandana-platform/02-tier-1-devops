# Troubleshooting — S3 Static Site

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

## 2. Variable and Planning Errors

### `No value for required variable`

**Symptom:**

```
Error: No value for required variable

  on variables.tf line 7:
   7: variable "bucket_name" {

The root module input variable "bucket_name" is not set, and has no default value.
```

**Cause:** `bucket_name` has no default and must be supplied on every `plan` and `apply` invocation.

**Fix:** Pass the variable on the CLI or via a `tfvars` file:
```bash
terraform plan -var="bucket_name=your-unique-bucket-name"
```

---

## 3. AWS Permission Errors

### `AuthFailure` — Invalid AWS Credentials

**Symptom:**

```
Error: configuring Terraform AWS Provider: no valid credential sources found
```

**Cause:** Terraform cannot locate valid AWS credentials. No credentials file, environment variables, or IAM role are configured.

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

### `AccessDenied` on S3 operations

**Symptom:**

```
Error: creating S3 Bucket: AccessDenied
```

or

```
Error: putting S3 Bucket Policy: AccessDenied
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
       "s3:DeleteBucket",
       "s3:PutBucketWebsite",
       "s3:GetBucketWebsite",
       "s3:PutBucketPolicy",
       "s3:GetBucketPolicy",
       "s3:DeleteBucketPolicy",
       "s3:PutBucketPublicAccessBlock",
       "s3:GetBucketPublicAccessBlock"
     ],
     "Resource": "*"
   }
   ```

---

## 4. S3 Bucket Creation Failures

### `BucketAlreadyExists` — Name Taken Globally

**Symptom:**

```
Error: creating S3 Bucket: BucketAlreadyExists:
  The requested bucket name is not available. The bucket namespace is shared
  by all users of the system.
```

**Cause:** S3 bucket names are globally unique across all AWS accounts and regions. Another account already owns this name.

**Fix:** Choose a different name that includes a project prefix, account ID, or random suffix:
```bash
terraform apply -var="bucket_name=mycompany-static-demo-$(date +%s)"
```

---

### `BucketAlreadyOwnedByYou`

**Symptom:**

```
Error: creating S3 Bucket: BucketAlreadyOwnedByYou
```

**Cause:** The bucket already exists in your account but is not tracked in Terraform state (e.g., state was lost, or a previous apply created the bucket before failing).

**Fix:** Import the existing bucket into state before re-applying:
```bash
terraform import -var="bucket_name=your-bucket-name" aws_s3_bucket.static_site your-bucket-name
```

Then run `terraform plan` to check for drift before applying further changes.

---

### `InvalidBucketName` — Name Format Violation

**Symptom:**

```
Error: creating S3 Bucket: InvalidBucketName:
  The specified bucket is not valid.
```

**Cause:** S3 bucket names must be 3–63 characters, lowercase letters, numbers, and hyphens only. Names cannot begin or end with a hyphen, contain consecutive hyphens, or resemble an IP address.

**Fix:** Use only lowercase letters, numbers, and single hyphens:
```bash
terraform apply -var="bucket_name=my-static-site-dev"
```

---

## 5. Public Access and Bucket Policy Errors

### `Public policies are blocked by the BlockPublicPolicy setting`

**Symptom:**

```
Error: putting S3 Bucket Policy (your-bucket): OperationAborted:
  A conflicting conditional operation is currently in progress against this resource.
```

or

```
Error: putting S3 Bucket Policy: ... public policies are blocked by the BlockPublicPolicy setting.
```

**Cause:** The public access block has not yet taken effect when the bucket policy is applied. This can happen if a partial apply was interrupted or if the `depends_on` was removed from the bucket policy resource.

**Fix:**
1. Confirm the public access block resource has all four settings as `false` in `main.tf`.
2. Confirm `aws_s3_bucket_policy.static_site` still includes `depends_on = [aws_s3_bucket_public_access_block.static_site]`.
3. Re-run apply:
   ```bash
   terraform apply -var="bucket_name=your-bucket-name"
   ```

If applying individually to debug:
```bash
terraform apply -target=aws_s3_bucket_public_access_block.static_site -var="bucket_name=your-bucket-name"
terraform apply -var="bucket_name=your-bucket-name"
```

---

### Account-Level Block Public Access Override

**Symptom:** Apply succeeds without error, but the website URL returns a `403 Forbidden` or the Console shows the bucket is still blocked.

**Cause:** Your AWS **account** has S3 Block Public Access enabled at the account level, which overrides bucket-level settings.

**Fix:**
Check the account-level setting:
```bash
aws s3control get-public-access-block \
  --account-id $(aws sts get-caller-identity --query Account --output text) \
  --query PublicAccessBlockConfiguration \
  --output table
```

An administrator must disable the account-level block to allow public buckets, or the architecture should be changed to **private bucket + CloudFront OAC**, which does not require any public access.

---

## 6. Website Endpoint and HTTP Behaviour

### `403 Forbidden` When Opening the Website URL

**Symptom:**

```
curl: (22) The requested URL returned error: 403 Forbidden
```

**Cause:** One or more of the following:
- `index.html` does not exist at the bucket root.
- The bucket policy is not yet applied or is missing.
- You are using the **REST endpoint** (`s3.amazonaws.com`) instead of the **website endpoint** (`s3-website-<region>.amazonaws.com`).

**Fix:**
1. Upload `index.html` to the bucket root:
   ```bash
   aws s3 cp index.html s3://YOUR_BUCKET/index.html
   ```
2. Verify the website endpoint from Terraform output — ensure you use `http://`, not `https://`:
   ```bash
   ENDPOINT=$(terraform output -raw website_endpoint)
   curl -sS "http://${ENDPOINT}/"
   ```
3. Verify the bucket policy allows `GetObject`:
   ```bash
   aws s3api get-bucket-policy \
     --bucket YOUR_BUCKET \
     --query Policy \
     --output text
   ```

---

### `404 Not Found` on Root URL

**Symptom:** The website endpoint responds but the root path returns a `404 Not Found` page served by S3.

**Cause:** No object named `index.html` exists at the root of the bucket.

**Fix:**
```bash
# Check what objects are in the bucket
aws s3 ls s3://YOUR_BUCKET/

# Upload the missing index document
aws s3 cp index.html s3://YOUR_BUCKET/index.html
```

---

### TLS Error When Using `https://` on the Website Endpoint

**Symptom:**

```
curl: (35) OpenSSL SSL_connect: SSL_ERROR_SYSCALL in connection
```

or a browser certificate error.

**Cause:** The S3 **website endpoint** (`s3-website-*.amazonaws.com`) is HTTP-only. HTTPS is not supported directly on the website endpoint hostname.

**Fix:** Use `http://` for local testing against the website endpoint. For HTTPS in production, place **CloudFront** in front of the bucket with an ACM certificate.

---

## 7. Destroy and Bucket Not Empty

### `BucketNotEmpty` During `terraform destroy`

**Symptom:**

```
Error: deleting S3 Bucket (your-bucket): BucketNotEmpty:
  The bucket you tried to delete is not empty
```

**Cause:** Terraform attempts to delete the bucket while objects remain inside it. S3 does not allow deletion of a non-empty bucket.

**Fix:**
1. Remove all objects:
   ```bash
   aws s3 rm s3://YOUR_BUCKET/ --recursive
   ```
2. If versioning was enabled on the bucket (not in this module but possible via console), also remove delete markers:
   ```bash
   aws s3api list-object-versions \
     --bucket YOUR_BUCKET \
     --query "Versions[*].{Key:Key,VersionId:VersionId}" \
     --output table
   ```
3. Re-run destroy:
   ```bash
   terraform destroy -var="bucket_name=YOUR_BUCKET"
   ```

---

## 8. Terraform State Problems

### State File Missing or Corrupted

**Symptom:**

```
Error: No state file was found!
```

or Terraform plans to create resources that already exist in AWS.

**Cause:** `terraform.tfstate` was deleted, moved, or corrupted.

**Fix:** Import each resource in dependency order if the infrastructure still exists in AWS:
```bash
BUCKET="your-bucket-name"

terraform import -var="bucket_name=$BUCKET" aws_s3_bucket.static_site "$BUCKET"
terraform import -var="bucket_name=$BUCKET" aws_s3_bucket_website_configuration.static_site "$BUCKET"
terraform import -var="bucket_name=$BUCKET" aws_s3_bucket_public_access_block.static_site "$BUCKET"
terraform import -var="bucket_name=$BUCKET" aws_s3_bucket_policy.static_site "$BUCKET"
```

Then run `terraform plan` to confirm state matches the live infrastructure before applying further changes.

---

### Resource Already Exists in AWS But Not in State

**Symptom:** `terraform plan` shows resources to be created, but the apply fails with `BucketAlreadyOwnedByYou` or a duplicate resource error.

**Cause:** Resources were created outside of Terraform (manually or from a previous run that lost its state file).

**Fix:** Import the orphaned resources as shown above, then reconcile drift with `terraform plan`.

---

## 9. Provider and Core Version Errors

### `Unsupported Terraform Core version`

**Symptom:**

```
Error: Unsupported Terraform Core version
This configuration does not support Terraform version X.Y.Z.
```

**Cause:** The installed Terraform binary is older than `>= 1.0` as required by `versions.tf`.

**Fix:** Upgrade Terraform:
```bash
# Using tfenv (recommended)
tfenv install 1.9.0
tfenv use 1.9.0

# Verify
terraform version
```

---

### `Unsupported argument` After Provider Upgrade

**Symptom:**

```
Error: Unsupported argument
An argument named "..." is not expected here.
```

**Cause:** An argument was renamed or removed in a newer version of the AWS provider.

**Fix:** Check the [AWS provider changelog](https://github.com/hashicorp/terraform-provider-aws/blob/main/CHANGELOG.md) for the breaking change. Confirm your provider version:
```bash
terraform version
terraform providers
```

---

## 10. Outputs Not Visible After Apply

**Symptom:** After a successful `terraform apply`, no output values are printed.

**Cause:** Outputs are only reprinted when they change. If the infrastructure already existed and no changes were made, outputs may not be re-displayed.

**Fix:** Query outputs explicitly:
```bash
terraform output
terraform output website_endpoint
```

Or refresh state without making changes:
```bash
terraform apply -refresh-only -var="bucket_name=your-bucket-name"
```

---

## Issues Faced During Implementation

*This section documents real issues encountered while building this module as a personal reference.*

<!-- To be completed -->
