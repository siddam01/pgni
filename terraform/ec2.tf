# EC2 Instance Configuration
# Creates EC2 instance for running the PGNi API

# Generate SSH key pair
resource "tls_private_key" "ec2_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create AWS key pair
resource "aws_key_pair" "ec2" {
  key_name   = "${local.name_prefix}-key"
  public_key = tls_private_key.ec2_key.public_key_openssh

  tags = local.common_tags
}

# IAM Role for EC2
resource "aws_iam_role" "ec2" {
  name = "${local.name_prefix}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

# IAM Policy for EC2 to access S3, SSM, and CloudWatch
resource "aws_iam_role_policy" "ec2" {
  name = "${local.name_prefix}-ec2-policy"
  role = aws_iam_role.ec2.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.uploads.arn,
          "${aws_s3_bucket.uploads.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/${var.project_name}/${var.environment}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Resource = var.enable_kms_encryption ? var.kms_key_id : "*"
      }
    ]
  })
}

# Attach SSM managed policy for Session Manager (optional - for secure access without SSH keys)
resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "ec2" {
  name = "${local.name_prefix}-ec2-profile"
  role = aws_iam_role.ec2.name

  tags = local.common_tags
}

# User data script for EC2 initialization
locals {
  user_data = <<-EOF
    #!/bin/bash
    set -e
    
    # Update system
    yum update -y
    
    # Install dependencies
    yum install -y git mysql jq
    
    # Install Go
    cd /tmp
    wget https://go.dev/dl/go1.21.0.linux-amd64.tar.gz
    tar -C /usr/local -xzf go1.21.0.linux-amd64.tar.gz
    echo 'export PATH=$PATH:/usr/local/go/bin' >> /home/ec2-user/.bashrc
    echo 'export PATH=$PATH:/usr/local/go/bin' >> /root/.bashrc
    
    # Create app directory
    mkdir -p /opt/pgworld
    chown ec2-user:ec2-user /opt/pgworld
    
    # Install CloudWatch agent (optional)
    wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
    rpm -U ./amazon-cloudwatch-agent.rpm
    
    # Create systemd service file
    cat > /etc/systemd/system/pgworld-api.service <<'UNIT'
    [Unit]
    Description=PGWorld API Service
    After=network.target
    
    [Service]
    Type=simple
    User=ec2-user
    WorkingDirectory=/opt/pgworld
    EnvironmentFile=/opt/pgworld/.env
    ExecStart=/opt/pgworld/pgworld-api
    Restart=always
    RestartSec=10
    StandardOutput=journal
    StandardError=journal
    
    [Install]
    WantedBy=multi-user.target
    UNIT
    
    # Enable service
    systemctl daemon-reload
    systemctl enable pgworld-api
    
    # Create placeholder env file
    cat > /opt/pgworld/.env <<'ENV'
    # Environment variables will be populated during deployment
    DB_HOST=${aws_db_instance.main.endpoint}
    DB_PORT=3306
    DB_NAME=${var.db_name}
    PORT=8080
    AWS_REGION=${var.aws_region}
    S3_BUCKET=${aws_s3_bucket.uploads.id}
    test=false
    ENV
    
    chown ec2-user:ec2-user /opt/pgworld/.env
    chmod 600 /opt/pgworld/.env
    
    # Create deployment script
    cat > /home/ec2-user/deploy-api.sh <<'DEPLOY'
    #!/bin/bash
    # Quick deployment script
    cd /opt/pgworld
    sudo systemctl stop pgworld-api || true
    
    # Backup current version
    if [ -f /opt/pgworld/pgworld-api ]; then
      sudo cp /opt/pgworld/pgworld-api /opt/pgworld/pgworld-api.backup.$(date +%Y%m%d-%H%M%S)
    fi
    
    # Git pull or build new version here
    echo "Ready for deployment"
    
    sudo systemctl start pgworld-api
    sudo systemctl status pgworld-api
    DEPLOY
    
    chmod +x /home/ec2-user/deploy-api.sh
    chown ec2-user:ec2-user /home/ec2-user/deploy-api.sh
    
    echo "EC2 initialization complete" > /home/ec2-user/init-complete.txt
  EOF
}

# EC2 Instance
resource "aws_instance" "api" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.ec2_instance_type[var.environment]
  key_name      = aws_key_pair.ec2.key_name

  vpc_security_group_ids = [aws_security_group.ec2.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2.name

  root_block_device {
    volume_size           = var.ec2_volume_size
    volume_type           = "gp3"
    encrypted             = true
    kms_key_id            = var.enable_kms_encryption ? var.kms_key_id : null
    delete_on_termination = var.environment == "preprod"
  }

  user_data = local.user_data

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"  # Enforce IMDSv2
    http_put_response_hop_limit = 1
  }

  monitoring = var.environment == "production"

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-api"
    }
  )

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_db_instance.main,
    aws_s3_bucket.uploads
  ]
}

# Elastic IP (optional - for static IP)
resource "aws_eip" "api" {
  count    = var.environment == "production" ? 1 : 0
  instance = aws_instance.api.id
  domain   = "vpc"

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-api-eip"
    }
  )
}

# Store EC2 details in SSM
resource "aws_ssm_parameter" "ec2_public_ip" {
  name        = "/${var.project_name}/${var.environment}/ec2/public_ip"
  description = "EC2 instance public IP"
  type        = "String"
  value       = var.environment == "production" ? aws_eip.api[0].public_ip : aws_instance.api.public_ip

  tags = local.common_tags

  depends_on = [aws_instance.api]
}

resource "aws_ssm_parameter" "ec2_private_key" {
  name        = "/${var.project_name}/${var.environment}/ec2/private_key"
  description = "EC2 SSH private key"
  type        = "SecureString"
  value       = tls_private_key.ec2_key.private_key_pem

  tags = local.common_tags
}

