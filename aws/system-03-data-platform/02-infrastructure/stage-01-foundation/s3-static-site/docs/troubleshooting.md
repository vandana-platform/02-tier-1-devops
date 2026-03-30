# Troubleshooting — S3 Static Site

Common issues when provisioning or using this Terraform module and how to resolve them.

---

## 1. Terraform Initialization Errors

### Failed to install provider

**Symptom:**

```
Error: Failed to install provider
Could not retrieve the list of available versions for provider hashicorp/aws.
```

**Cause:** No network path to the Terraform Registry, or a proxy is blocking downloads.

**Fix:**
1. Verify connectivity:
   ```bash
   curl -I https://registry.terraform.io
   ```
2. Behind a proxy:
   ```bash
   export HTTPS_PROXY=http://proxy.example.com:8080
   export HTTP_PROXY=http://proxy.example.com:8080
   terraform init
   ```

---

### Inconsistent lock file

**Symptom:**

```
Error: Inconsistent dependency lock file
The lock file does not contain a suitable checksum for provider "hashicorp/aws".
```

**Cause:** `.terraform.lock.hcl` was generated on another OS/architecture.

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

### Required variable not set

**Symptom:**

```
Error: No value for required variable
The root module input variable "bucket_name" is not set, and has no default value.
```

**Cause:** `bucket_name` must be supplied on the CLI or in a `tfvars` file.

**Fix:**

```bash
terraform plan -var="bucket_name=my-globally-unique-name"
```

---

## 3. AWS Permission Errors

### AccessDenied on bucket or policy operations

**Symptom:**

```
Error: error creating S3 Bucket ... AccessDenied
```

or

```
Error: putting S3 Bucket Policy ... AccessDenied
```

**Cause:** The IAM principal lacks S3 permissions for the requested operation.

**Fix:**
1. Confirm identity:
   ```bash
   aws sts get-caller-identity --output json
   ```
2. Ensure policies allow actions such as `s3:CreateBucket`, `s3:PutBucketWebsite`, `s3:PutBucketPolicy`, and `s3:PutBucketPublicAccessBlock` for the bucket ARN or `*` during sandbox development.

---

### Expired or invalid credentials

**Symptom:**

```
Error: error configuring Terraform AWS Provider: ... ExpiredToken
```

**Cause:** STS session or SSO login expired.

**Fix:**

```bash
aws sso login --profile your-profile
# or refresh keys / MFA as appropriate
aws sts get-caller-identity
```

---

## 4. S3 Bucket Naming and Availability

### BucketAlreadyOwnedByYou or BucketAlreadyExists

**Symptom:**

```
Error: creating S3 Bucket: BucketAlreadyExists
```

**Cause:** The bucket name is globally reserved or owned by another account.

**Fix:** Choose a new unique name and re-apply:

```bash
terraform apply -var="bucket_name=different-prefix-demo-2026-xyz"
```

---

### Invalid bucket name

**Symptom:**

```
Error: ... invalid bucket name
```

**Cause:** Bucket names must be 3–63 characters, lowercase, DNS-compliant (no underscores in many cases), and follow [S3 naming rules](https://docs.aws.amazon.com/AmazonS3/latest/userguide/bucketnamingrules.html).

**Fix:** Use lowercase letters, numbers, and hyphens only; shorten the label if needed.

---

## 5. Public Access and Policy Application

### Policy apply blocked by public access settings

**Symptom:**

```
Error: putting S3 Bucket Policy: ... public policies are blocked by the BlockPublicPolicy setting
```

**Cause:** Public access block still prevented public bucket policies, or the public access block resource had not been applied before the policy.

**Fix:** This module sets all public block flags to `false` and uses `depends_on`. If you edited the configuration, ensure:

1. `aws_s3_bucket_public_access_block` has all four attributes `false`.
2. `aws_s3_bucket_policy` includes `depends_on = [aws_s3_bucket_public_access_block.static_site]`.

Then run:

```bash
terraform apply -var="bucket_name=your-bucket-name"
```

---

### Account-level block public access

**Symptom:** Apply succeeds but the website is not reachable, or Console shows bucket is still “public access blocked” at account level.

**Cause:** Some organisations enforce **S3 Block Public Access** at the account level.

**Fix:** An administrator must allow public buckets for this use case, or you must switch architecture to **private bucket + CloudFront OAC** (recommended for production) instead of a public website endpoint.

---

## 6. Website Endpoint and HTTP Behaviour

### 403 Forbidden when opening the website URL

**Symptom:** Browser or `curl` shows `403 Forbidden` for `http://bucket.s3-website-.../`.

**Cause:** Common causes include missing `index.html`, wrong endpoint type (REST instead of website), or objects not publicly readable despite policy.

**Fix:**
1. Upload `index.html` to the bucket root:
   ```bash
   aws s3 cp index.html s3://YOUR_BUCKET/index.html
   ```
2. Use the **website** endpoint from `terraform output website_endpoint`, not `https://YOUR_BUCKET.s3.amazonaws.com/...` unless you intentionally use the REST API with signing.
3. Verify policy allows `GetObject` on `arn:aws:s3:::YOUR_BUCKET/*`:
   ```bash
   aws s3api get-bucket-policy --bucket YOUR_BUCKET --query Policy --output text | jq .
   ```

---

### 404 Not Found on root URL

**Symptom:** Website endpoint loads but root path returns 404.

**Cause:** No object named `index.html` at the root of the bucket.

**Fix:**

```bash
aws s3 ls s3://YOUR_BUCKET/
aws s3 cp index.html s3://YOUR_BUCKET/index.html
```

---

### Using HTTPS against the website endpoint

**Symptom:** TLS errors or failures when using `https://` on the `s3-website-*` hostname.

**Cause:** The S3 **website endpoint** serves HTTP. It is not an HTTPS listener.

**Fix:** Use `http://` for quick tests, or front the bucket with **CloudFront** and ACM for HTTPS.

---

## 7. Destroy and Bucket Not Empty

### Error deleting bucket: BucketNotEmpty

**Symptom:**

```
Error: deleting S3 Bucket: BucketNotEmpty
```

**Cause:** Terraform tries to delete the bucket while objects remain.

**Fix:**
1. List and remove objects:
   ```bash
   aws s3 rm s3://YOUR_BUCKET/ --recursive
   ```
2. Delete versioned objects if versioning was enabled outside this module (not created here):
   ```bash
   aws s3api list-object-versions --bucket YOUR_BUCKET --output json
   # remove versions as required per organisation procedures
   ```
3. Re-run:
   ```bash
   terraform destroy -var="bucket_name=YOUR_BUCKET"
   ```

---

## 8. State Drift and Imports

### Bucket exists but not in state

**Symptom:** `terraform apply` fails because the bucket name already exists; state was lost.

**Cause:** State file deleted or workspace changed.

**Fix:** Import existing resources in dependency order (exact addresses must match your `main.tf`):

```bash
terraform import -var="bucket_name=YOUR_BUCKET" aws_s3_bucket.static_site YOUR_BUCKET
terraform import -var="bucket_name=YOUR_BUCKET" aws_s3_bucket_website_configuration.static_site YOUR_BUCKET
terraform import -var="bucket_name=YOUR_BUCKET" aws_s3_bucket_public_access_block.static_site YOUR_BUCKET
terraform import -var="bucket_name=YOUR_BUCKET" aws_s3_bucket_policy.static_site YOUR_BUCKET
```

Then run `terraform plan -var="bucket_name=…"` and reconcile any drift.

---

## 9. Provider and Core Version Errors

### Unsupported Terraform Core version

**Symptom:**

```
Error: Unsupported Terraform Core version
```

**Cause:** Installed Terraform is older than `versions.tf` requires.

**Fix:** Upgrade to Terraform `>= 1.0` and verify:

```bash
terraform version
```

---

## 10. Outputs Missing After Apply

**Symptom:** Terminal shows apply success but outputs do not print.

**Cause:** Outputs may not reprint if unchanged in some workflows.

**Fix:**

```bash
terraform output
terraform output website_endpoint
```

---

## Issues Faced During Implementation

*This section documents real issues encountered while building this module as a personal reference.*

<!-- To be completed -->
