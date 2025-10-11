# Override local variables to use existing RDS database

locals {
  # Use existing RDS endpoint
  rds_endpoint = "database-pgni.cezawkgguojl.us-east-1.rds.amazonaws.com"
  rds_port     = 3306
  rds_username = var.db_username
  rds_password = var.db_password
  rds_db_name  = var.db_name
  
  # Backwards compatibility
  db_endpoint = "database-pgni.cezawkgguojl.us-east-1.rds.amazonaws.com"
  db_host = "database-pgni.cezawkgguojl.us-east-1.rds.amazonaws.com"
  db_port = "3306"
  db_username_final = var.db_username
  db_password_final = var.db_password
  db_name_final     = var.db_name
}

