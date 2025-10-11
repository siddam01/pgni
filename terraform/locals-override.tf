# Override local variables to use existing RDS database

locals {
  # Use existing RDS endpoint
  db_endpoint = "database-pgni.cezawkgguojl.us-east-1.rds.amazonaws.com"
  
  # Database connection details
  db_host = "database-pgni.cezawkgguojl.us-east-1.rds.amazonaws.com"
  db_port = "3306"
  
  # Use provided credentials
  db_username_final = var.db_username
  db_password_final = var.db_password
  db_name_final     = var.db_name
}

