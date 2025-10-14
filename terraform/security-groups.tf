# Security Groups Configuration
# Defines network security rules for RDS, EC2, and other resources

# Security Group for RDS Database
resource "aws_security_group" "rds" {
  name        = "${local.name_prefix}-rds-sg"
  description = "Security group for PGNi RDS database"
  vpc_id      = data.aws_vpc.default.id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-rds-sg"
    }
  )
}

# Allow MySQL access from EC2
resource "aws_security_group_rule" "rds_from_ec2" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ec2.id
  security_group_id        = aws_security_group.rds.id
  description              = "Allow MySQL access from EC2 instances"
}

# Allow all outbound traffic from RDS
resource "aws_security_group_rule" "rds_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.rds.id
  description       = "Allow all outbound traffic"
}

# Security Group for EC2 API Server
resource "aws_security_group" "ec2" {
  name        = "${local.name_prefix}-api-sg"
  description = "Security group for PGNi API server"
  vpc_id      = data.aws_vpc.default.id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-api-sg"
    }
  )
}

# Allow SSH access
resource "aws_security_group_rule" "ec2_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.allowed_ssh_cidrs
  security_group_id = aws_security_group.ec2.id
  description       = "Allow SSH access"
}

# Allow HTTP access on port 80 (Web Server / Nginx)
resource "aws_security_group_rule" "ec2_http_80" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = var.allowed_http_cidrs
  security_group_id = aws_security_group.ec2.id
  description       = "Allow HTTP access for web server (Nginx)"
}

# Allow HTTP access on port 8080 (API)
resource "aws_security_group_rule" "ec2_http_8080" {
  type              = "ingress"
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"
  cidr_blocks       = var.allowed_http_cidrs
  security_group_id = aws_security_group.ec2.id
  description       = "Allow API access on port 8080"
}

# Allow HTTPS access (optional, for future use)
resource "aws_security_group_rule" "ec2_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = var.allowed_http_cidrs
  security_group_id = aws_security_group.ec2.id
  description       = "Allow HTTPS access"
}

# Allow all outbound traffic from EC2
resource "aws_security_group_rule" "ec2_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ec2.id
  description       = "Allow all outbound traffic"
}

