# PGNi Pre-Production Environment Configuration
# Terraform Variables

# Environment
environment = "preprod"

# AWS Configuration
aws_region     = "us-east-1"
aws_account_id = "698302425856"

# Project
project_name = "pgni"

# Database Configuration (Using existing RDS instance)
db_name     = "pgworld"
db_username = "admin"
db_password = "Omsairamdb951#"

# Note: We already have RDS database created manually
# RDS Endpoint: database-pgni.cezawkgguojl.us-east-1.rds.amazonaws.com
# Terraform will create S3, EC2, and other resources

# KMS Encryption (Optional)
enable_kms_encryption = true
kms_key_id            = "arn:aws:kms:us-east-1:698302425856:key/mrk-1b96d9eeccf649e695ed6ac2b13cb619"

# Network Security
# Change to your IP address for better security: ["YOUR_IP/32"]
allowed_ssh_cidrs  = ["0.0.0.0/0"]
allowed_http_cidrs = ["0.0.0.0/0"]

# S3 Configuration
enable_s3_versioning = true

# Tags
common_tags = {
  Project     = "PGNi"
  Environment = "preprod"
  ManagedBy   = "Terraform"
  Owner       = "PGNi-Team"
  CreatedDate = "2025-01-08"
}

