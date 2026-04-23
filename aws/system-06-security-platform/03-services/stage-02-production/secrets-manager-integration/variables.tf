variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name prefix for all resources"
  type        = string
  default     = "tier2-secrets-manager-integration"
}

variable "db_username" {
  description = "Database admin username stored in Secrets Manager"
  type        = string
  default     = "dbadmin"
}

variable "secret_recovery_window_days" {
  description = "Recovery window for deleted secrets (0 for immediate destroy in lab)"
  type        = number
  default     = 0
}
