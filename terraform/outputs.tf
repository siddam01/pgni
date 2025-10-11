# Terraform Outputs
# Displays important information after infrastructure creation

output "environment" {
  description = "Deployment environment"
  value       = var.environment
}

output "region" {
  description = "AWS region"
  value       = var.aws_region
}

# RDS Outputs
output "rds_endpoint" {
  description = "RDS database endpoint"
  value       = "database-pgni.cezawkgguojl.us-east-1.rds.amazonaws.com:3306"
}

output "rds_database_name" {
  description = "RDS database name"
  value       = var.db_name
}

output "rds_username" {
  description = "RDS master username"
  value       = var.db_username
  sensitive   = true
}

output "rds_password" {
  description = "RDS master password"
  value       = var.db_password
  sensitive   = true
}

output "rds_connection_string" {
  description = "MySQL connection string"
  value       = "mysql -h database-pgni.cezawkgguojl.us-east-1.rds.amazonaws.com -u ${var.db_username} -p ${var.db_name}"
  sensitive   = true
}

# S3 Outputs
output "s3_bucket_name" {
  description = "S3 bucket name for uploads"
  value       = aws_s3_bucket.uploads.id
}

output "s3_bucket_arn" {
  description = "S3 bucket ARN"
  value       = aws_s3_bucket.uploads.arn
}

# EC2 Outputs
output "ec2_instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.api.id
}

output "ec2_public_ip" {
  description = "EC2 instance public IP"
  value       = var.environment == "production" && length(aws_eip.api) > 0 ? aws_eip.api[0].public_ip : aws_instance.api.public_ip
}

output "ec2_private_ip" {
  description = "EC2 instance private IP"
  value       = aws_instance.api.private_ip
}

output "ssh_private_key" {
  description = "SSH private key (save this securely!)"
  value       = tls_private_key.ec2_key.private_key_pem
  sensitive   = true
}

output "ssh_command" {
  description = "SSH command to connect to EC2"
  value       = "ssh -i ${local.name_prefix}-key.pem ec2-user@${var.environment == "production" && length(aws_eip.api) > 0 ? aws_eip.api[0].public_ip : aws_instance.api.public_ip}"
}

# API URLs
output "api_url" {
  description = "API base URL"
  value       = "http://${var.environment == "production" && length(aws_eip.api) > 0 ? aws_eip.api[0].public_ip : aws_instance.api.public_ip}:8080"
}

output "api_health_url" {
  description = "API health check URL"
  value       = "http://${var.environment == "production" && length(aws_eip.api) > 0 ? aws_eip.api[0].public_ip : aws_instance.api.public_ip}:8080/health"
}

# Security Group IDs
output "rds_security_group_id" {
  description = "RDS security group ID"
  value       = aws_security_group.rds.id
}

output "ec2_security_group_id" {
  description = "EC2 security group ID"
  value       = aws_security_group.ec2.id
}

# SSM Parameter Paths
output "ssm_parameter_path" {
  description = "SSM Parameter Store path for environment variables"
  value       = "/${var.project_name}/${var.environment}/"
}

# Complete Environment File
output "environment_file" {
  description = "Complete .env file content for API"
  value       = <<-EOF
    # Database Configuration
    DB_HOST=database-pgni.cezawkgguojl.us-east-1.rds.amazonaws.com
    DB_PORT=3306
    DB_USER=${var.db_username}
    DB_PASSWORD=${var.db_password}
    DB_NAME=${var.db_name}
    
    # S3 Configuration
    AWS_REGION=${var.aws_region}
    S3_BUCKET=${aws_s3_bucket.uploads.id}
    
    # API Configuration
    PORT=8080
    test=false
    
    # API Keys (CHANGE THESE!)
    ANDROID_LIVE_KEY=your_android_live_key_here
    ANDROID_TEST_KEY=your_android_test_key_here
    IOS_LIVE_KEY=your_ios_live_key_here
    IOS_TEST_KEY=your_ios_test_key_here
    
    # JWT Secret (CHANGE THIS!)
    JWT_SECRET=your_jwt_secret_here
  EOF
  sensitive   = true
}

# Deployment Instructions
output "next_steps" {
  description = "Next steps for deployment"
  value       = <<-EOF
    
    ========================================
    Infrastructure Created Successfully!
    ========================================
    
    Environment: ${var.environment}
    Region: ${var.aws_region}
    
    === SAVE THESE CREDENTIALS ===
    
    1. Save SSH Private Key:
       terraform output -raw ssh_private_key > ${local.name_prefix}-key.pem
       chmod 600 ${local.name_prefix}-key.pem  # On Linux/Mac
       icacls ${local.name_prefix}-key.pem /inheritance:r  # On Windows
    
    2. Save Environment File:
       terraform output -raw environment_file > ${local.name_prefix}.env
    
    3. View Sensitive Outputs:
       terraform output rds_password
       terraform output ssh_private_key
    
    === CONNECT TO EC2 ===
    
    SSH Command:
       ssh -i ${local.name_prefix}-key.pem ec2-user@${var.environment == "production" && length(aws_eip.api) > 0 ? aws_eip.api[0].public_ip : aws_instance.api.public_ip}
    
    === DEPLOY API ===
    
    1. SSH to EC2 instance
    2. Clone your repository:
       git clone https://github.com/siddam01/pgni.git
    3. Build API:
       cd pgni/pgworld-api-master
       /usr/local/go/bin/go build -o /opt/pgworld/pgworld-api .
    4. Copy environment file:
       sudo cp /path/to/${local.name_prefix}.env /opt/pgworld/.env
    5. Start service:
       sudo systemctl start pgworld-api
       sudo systemctl status pgworld-api
    
    === TEST API ===
    
    Health Check:
       curl http://${var.environment == "production" && length(aws_eip.api) > 0 ? aws_eip.api[0].public_ip : aws_instance.api.public_ip}:8080/health
    
    === DATABASE ACCESS ===
    
    Connection String:
       mysql -h ${local.rds_endpoint} -u ${local.rds_username} -p ${local.rds_db_name}
    
    === RESOURCES CREATED ===
    
    - RDS Database: database-pgni.cezawkgguojl.us-east-1.rds.amazonaws.com (existing)
    - S3 Bucket: ${aws_s3_bucket.uploads.id}
    - EC2 Instance: ${aws_instance.api.id}
    - Public IP: ${var.environment == "production" && length(aws_eip.api) > 0 ? aws_eip.api[0].public_ip : aws_instance.api.public_ip}
    
    ========================================
    
  EOF
}

# Summary for CI/CD
output "github_secrets" {
  description = "Values to add as GitHub Secrets"
  value = {
    AWS_REGION          = var.aws_region
    EC2_HOST            = var.environment == "production" && length(aws_eip.api) > 0 ? aws_eip.api[0].public_ip : aws_instance.api.public_ip
    SSH_PRIVATE_KEY     = "Run: terraform output -raw ssh_private_key"
    DB_HOST             = local.rds_endpoint
    DB_PASSWORD         = "Run: terraform output -raw rds_password"
    S3_BUCKET           = aws_s3_bucket.uploads.id
    SSM_PARAMETER_PATH  = "/${var.project_name}/${var.environment}/"
  }
  sensitive = false
}

