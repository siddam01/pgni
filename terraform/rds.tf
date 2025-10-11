# RDS MySQL Database Configuration
# Creates and configures the MySQL database for PGNi

# DB Subnet Group (uses default VPC subnets)
resource "aws_db_subnet_group" "main" {
  name       = "${local.name_prefix}-db-subnet-group"
  subnet_ids = data.aws_subnets.default.ids

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-db-subnet-group"
    }
  )
}

# RDS Parameter Group for MySQL 8.0
resource "aws_db_parameter_group" "main" {
  name   = "${local.name_prefix}-mysql8-params"
  family = "mysql8.0"

  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }

  parameter {
    name  = "collation_server"
    value = "utf8mb4_unicode_ci"
  }

  parameter {
    name  = "max_connections"
    value = "100"
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-mysql8-params"
    }
  )
}

# RDS MySQL Instance
# DISABLED: Using existing database created manually (database-pgni)
# See existing-rds.tf for configuration
resource "aws_db_instance" "main" {
  count = 0  # Disabled - using existing database
  identifier = "${local.name_prefix}-db"

  # Engine configuration
  engine         = "mysql"
  engine_version = "8.0.35"
  instance_class = var.db_instance_class[var.environment]

  # Storage configuration
  allocated_storage     = var.db_allocated_storage[var.environment]
  max_allocated_storage = var.db_allocated_storage[var.environment] * 5
  storage_type          = "gp3"
  storage_encrypted     = true
  kms_key_id            = var.enable_kms_encryption ? var.kms_key_id : null

  # Database configuration
  db_name  = var.db_name
  username = var.db_username
  password = local.db_password

  # Network configuration
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = true  # Set to false in production with VPN

  # Parameter group
  parameter_group_name = aws_db_parameter_group.main.name

  # Backup configuration
  backup_retention_period = var.backup_retention_period[var.environment]
  backup_window           = "03:00-04:00"
  maintenance_window      = "mon:04:00-mon:05:00"
  copy_tags_to_snapshot   = true
  skip_final_snapshot     = var.environment == "preprod"
  final_snapshot_identifier = var.environment == "production" ? "${local.name_prefix}-final-snapshot-${random_string.suffix.result}" : null

  # Performance and monitoring
  enabled_cloudwatch_logs_exports = ["error", "general", "slowquery"]
  monitoring_interval             = var.environment == "production" ? 60 : 0
  monitoring_role_arn             = var.environment == "production" ? aws_iam_role.rds_monitoring[0].arn : null

  # Deletion protection
  deletion_protection = var.environment == "production"

  # Auto minor version upgrade
  auto_minor_version_upgrade = true

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-db"
    }
  )

  lifecycle {
    prevent_destroy = false  # Set to true for production
  }
}

# IAM Role for RDS Enhanced Monitoring (production only)
resource "aws_iam_role" "rds_monitoring" {
  count = var.environment == "production" ? 1 : 0
  name  = "${local.name_prefix}-rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  count      = var.environment == "production" ? 1 : 0
  role       = aws_iam_role.rds_monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# Store database credentials in SSM Parameter Store
# DISABLED: Using existing-rds.tf for SSM parameters instead
# resource "aws_ssm_parameter" "db_endpoint" {
#   name        = "/${var.project_name}/${var.environment}/db/endpoint"
#   description = "RDS database endpoint"
#   type        = "String"
#   value       = "${local.rds_endpoint}:${local.rds_port}"
#   overwrite   = true
# 
#   tags = local.common_tags
# }
# 
# resource "aws_ssm_parameter" "db_username" {
#   name        = "/${var.project_name}/${var.environment}/db/username"
#   description = "RDS database username"
#   type        = "String"
#   value       = local.rds_username
#   overwrite   = true
# 
#   tags = local.common_tags
# }
# 
# resource "aws_ssm_parameter" "db_password" {
#   name        = "/${var.project_name}/${var.environment}/db/password"
#   description = "RDS database password"
#   type        = "SecureString"
#   value       = local.rds_password
#   overwrite   = true
# 
#   tags = local.common_tags
# }
# 
# resource "aws_ssm_parameter" "db_name" {
#   name        = "/${var.project_name}/${var.environment}/db/name"
#   description = "RDS database name"
#   type        = "String"
#   value       = local.rds_db_name
#   overwrite   = true
# 
#   tags = local.common_tags
# }

