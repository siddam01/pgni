# Variables for PGNi Infrastructure
# Author: Auto-generated for PGNi deployment
# Purpose: Define all configurable parameters for AWS infrastructure

variable "environment" {
  description = "Environment name (preprod or production)"
  type        = string
  default     = "preprod"
  
  validation {
    condition     = contains(["preprod", "production"], var.environment)
    error_message = "Environment must be either 'preprod' or 'production'."
  }
}

variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "pgni"
}

variable "aws_account_id" {
  description = "AWS Account ID"
  type        = string
  default     = "698302425856"
}

# Database Configuration
variable "db_instance_class" {
  description = "RDS instance class"
  type        = map(string)
  default = {
    preprod    = "db.t3.micro"
    production = "db.t3.small"
  }
}

variable "db_allocated_storage" {
  description = "RDS allocated storage in GB"
  type        = map(number)
  default = {
    preprod    = 20
    production = 50
  }
}

variable "db_name" {
  description = "Initial database name"
  type        = string
  default     = "pgworld"
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "pgniuser"
}

variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
  default     = ""  # Will be generated if not provided
}

# EC2 Configuration
variable "ec2_instance_type" {
  description = "EC2 instance type"
  type        = map(string)
  default = {
    preprod    = "t3.micro"
    production = "t3.small"
  }
}

variable "ec2_volume_size" {
  description = "EC2 root volume size in GB"
  type        = number
  default     = 30
}

# S3 Configuration
variable "enable_s3_versioning" {
  description = "Enable S3 bucket versioning"
  type        = bool
  default     = true
}

# KMS Configuration
variable "kms_key_id" {
  description = "KMS key ID for encryption (optional)"
  type        = string
  default     = "arn:aws:kms:us-east-1:698302425856:key/mrk-1b96d9eeccf649e695ed6ac2b13cb619"
}

variable "enable_kms_encryption" {
  description = "Use KMS for encryption"
  type        = bool
  default     = false
}

# Network Configuration
variable "allowed_ssh_cidrs" {
  description = "CIDR blocks allowed to SSH to EC2"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # Change to your IP for security
}

variable "allowed_http_cidrs" {
  description = "CIDR blocks allowed to access API"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# Backup Configuration
variable "backup_retention_period" {
  description = "Database backup retention in days"
  type        = map(number)
  default = {
    preprod    = 7
    production = 30
  }
}

# Tags
variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Project     = "PGNi"
    ManagedBy   = "Terraform"
    Owner       = "PGNi-Team"
  }
}

