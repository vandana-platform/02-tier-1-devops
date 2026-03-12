# Interview Questions

Common questions an interviewer may ask about this project, with concise answers grounded in the implementation.

---

## Terraform Fundamentals

### What does `terraform init` do?

Downloads provider plugins (AWS `~> 5.0`), initialises the backend, and creates the `.terraform/` directory. Must be run before any other command.

### What is the difference between `terraform plan` and `terraform apply`?

- `terraform plan` — generates an execution plan and shows what will change; makes no changes.
- `terraform apply` — executes the plan and modifies real infrastructure.

### What is Terraform state and why does it matter?

State (`terraform.tfstate`) maps Terraform resource definitions to real AWS resources. Terraform uses it to determine what already exists, what needs to change, and what to destroy. Without state, Terraform cannot manage existing infrastructure.

### What is `terraform destroy` used for?

Tears down all resources managed by the configuration. Used to clean up environments and avoid ongoing cloud costs.

---

## Project-Specific

### Why is the security group defined separately from the EC2 instance?

Security groups are standalone AWS resources and can be shared across multiple instances. Defining it separately follows good IaC practice and makes `vpc_security_group_ids` a clean reference rather than an inline block.

### Why is the AMI hardcoded instead of using a data source?

Predictability. A hardcoded AMI is always the same. A `data "aws_ami"` lookup could resolve to a different AMI version on a future run, causing unexpected instance replacement. The trade-off is the AMI ID is `us-east-1`-specific.

### How would you restrict SSH access to a known IP instead of `0.0.0.0/0`?

Replace `cidr_blocks = ["0.0.0.0/0"]` in the ingress block with `cidr_blocks = ["<your-ip>/32"]`. In a production environment, consider removing SSH entirely and using AWS Systems Manager Session Manager.

### What would you change to make this production-ready?

- Custom VPC with private subnets and a bastion host or SSM
- SSH restricted or removed
- Remote state backend (S3 + DynamoDB for locking)
- IAM instance profile for AWS API access
- Key pair management via AWS Secrets Manager or Parameter Store
- Parameterised AMI using a data source with a pinned name filter

---

## IaC Concepts

### What is the benefit of separating `versions.tf`, `provider.tf`, `variables.tf`, `main.tf`, and `outputs.tf`?

Separation of concerns. Each file has a single responsibility, making the configuration easier to navigate, review, and maintain. It also mirrors community conventions, making the project familiar to other Terraform practitioners.

### What are Terraform output values used for?

Outputs expose resource attributes after apply — here `instance_id` and `public_ip`. They are also used by parent modules to consume child module values (module composition).

### How would you manage multiple environments (dev, staging, prod) with this configuration?

Use Terraform workspaces or separate state files per environment, with a `tfvars` file per environment (e.g., `dev.tfvars`, `prod.tfvars`) to override variables like region and instance type.
