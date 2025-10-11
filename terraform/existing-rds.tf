# Use Existing RDS Database
# Since you already created the RDS instance manually, we'll reference it instead of creating a new one

# Data source to reference existing RDS instance
data "aws_db_instance" "existing" {
  count                  = 1  # Set to 1 to use existing database
  db_instance_identifier = "database-pgni"
}

# Store existing database connection info in SSM Parameter Store
resource "aws_ssm_parameter" "existing_db_endpoint" {
  count       = 1
  name        = "/${var.project_name}/${var.environment}/db/endpoint"
  description = "RDS database endpoint (existing database)"
  type        = "String"
  value       = "database-pgni.cezawkgguojl.us-east-1.rds.amazonaws.com:3306"

  tags = local.common_tags
}

resource "aws_ssm_parameter" "existing_db_username" {
  count       = 1
  name        = "/${var.project_name}/${var.environment}/db/username"
  description = "RDS database username"
  type        = "String"
  value       = var.db_username

  tags = local.common_tags
}

resource "aws_ssm_parameter" "existing_db_password" {
  count       = 1
  name        = "/${var.project_name}/${var.environment}/db/password"
  description = "RDS database password"
  type        = "SecureString"
  value       = var.db_password

  tags = local.common_tags
}

resource "aws_ssm_parameter" "existing_db_name" {
  count       = 1
  name        = "/${var.project_name}/${var.environment}/db/name"
  description = "RDS database name"
  type        = "String"
  value       = var.db_name

  tags = local.common_tags
}

# Note: Comment out or remove the original RDS creation in rds.tf
# We're using the existing database instead

