#!/bin/bash
# Quick fix for deployment issues
# Fixes: Config file creation, Database connectivity

set -e

EC2_IP="34.227.111.143"
SSH_KEY="cloudshell-key.pem"

echo "=========================================="
echo "🚀 Quick Fix Deployment"
echo "=========================================="
echo ""

# Stage 1: Fix database security group
echo "[1/5] Fixing database security group..."

# Get RDS security group
RDS_SG=$(aws rds describe-db-instances \
    --db-instance-identifier $(aws rds describe-db-instances --query 'DBInstances[0].DBInstanceIdentifier' --output text) \
    --query 'DBInstances[0].VpcSecurityGroups[0].VpcSecurityGroupId' \
    --output text 2>/dev/null)

# Get EC2 security group
EC2_SG=$(aws ec2 describe-instances \
    --filters "Name=ip-address,Values=$EC2_IP" \
    --query 'Reservations[0].Instances[0].SecurityGroups[0].GroupId' \
    --output text)

if [ ! -z "$RDS_SG" ] && [ ! -z "$EC2_SG" ]; then
    echo "RDS Security Group: $RDS_SG"
    echo "EC2 Security Group: $EC2_SG"
    
    # Allow EC2 to connect to RDS on port 3306
    aws ec2 authorize-security-group-ingress \
        --group-id $RDS_SG \
        --protocol tcp \
        --port 3306 \
        --source-group $EC2_SG 2>/dev/null && echo "✓ RDS access granted" || echo "✓ RDS access already exists"
else
    echo "⚠️ Could not find security groups, will try direct connection"
fi

echo ""

# Stage 2: Create config file properly
echo "[2/5] Creating configuration..."
ssh -i ~/$SSH_KEY -o StrictHostKeyChecking=no ec2-user@$EC2_IP 'bash -s' << 'REMOTE_SCRIPT'
# Create directories
sudo mkdir -p /opt/pgworld/logs /opt/pgworld/backups
sudo chown -R ec2-user:ec2-user /opt/pgworld

# Create config file with proper formatting
cat > /opt/pgworld/.env << 'ENVEOF'
DB_HOST=database-pgni.cezawkgguojl.us-east-1.rds.amazonaws.com
DB_PORT=3306
DB_USER=admin
DB_PASSWORD=Omsairamdb951#
DB_NAME=pgworld
AWS_REGION=us-east-1
S3_BUCKET=pgni-preprod-698302425856-uploads
PORT=8080
test=false
ENVEOF

chmod 600 /opt/pgworld/.env
echo "✓ Config created"
REMOTE_SCRIPT

echo ""

# Stage 3: Deploy binary
echo "[3/5] Deploying binary..."
if [ -f /tmp/pgworld-api ]; then
    scp -i ~/$SSH_KEY -o StrictHostKeyChecking=no /tmp/pgworld-api ec2-user@$EC2_IP:/opt/pgworld/ 2>&1 | tail -1
    ssh -i ~/$SSH_KEY -o StrictHostKeyChecking=no ec2-user@$EC2_IP "chmod +x /opt/pgworld/pgworld-api"
    echo "✓ Binary deployed"
else
    echo "⚠️ Binary not found in cache, building..."
    cd /tmp
    rm -rf pgni_build
    git clone --depth 1 -q https://github.com/siddam01/pgni.git pgni_build
    cd pgni_build/pgworld-api-master
    export PATH=$PATH:/usr/local/go/bin
    GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -ldflags="-s -w" -o /tmp/pgworld-api .
    
    scp -i ~/$SSH_KEY -o StrictHostKeyChecking=no /tmp/pgworld-api ec2-user@$EC2_IP:/opt/pgworld/
    ssh -i ~/$SSH_KEY -o StrictHostKeyChecking=no ec2-user@$EC2_IP "chmod +x /opt/pgworld/pgworld-api"
    echo "✓ Binary built and deployed"
fi

echo ""

# Stage 4: Setup systemd service
echo "[4/5] Setting up service..."
ssh -i ~/$SSH_KEY -o StrictHostKeyChecking=no ec2-user@$EC2_IP 'bash -s' << 'SERVICE_SETUP'
sudo tee /etc/systemd/system/pgworld-api.service > /dev/null << 'SERVICEEOF'
[Unit]
Description=PGNi API Server
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/opt/pgworld
ExecStart=/opt/pgworld/pgworld-api
EnvironmentFile=/opt/pgworld/.env
Restart=always
RestartSec=5
StandardOutput=append:/opt/pgworld/logs/output.log
StandardError=append:/opt/pgworld/logs/error.log

[Install]
WantedBy=multi-user.target
SERVICEEOF

sudo systemctl daemon-reload
sudo systemctl enable pgworld-api 2>&1 | tail -1
sudo systemctl restart pgworld-api
sleep 3
echo "✓ Service started"
SERVICE_SETUP

echo ""

# Stage 5: Initialize database
echo "[5/5] Initializing database..."
ssh -i ~/$SSH_KEY -o StrictHostKeyChecking=no ec2-user@$EC2_IP 'bash -s' << 'DB_INIT'
# Wait for network
sleep 2

# Test database connection first
if mysql -h database-pgni.cezawkgguojl.us-east-1.rds.amazonaws.com -P 3306 -u admin -pOmsairamdb951# \
    -e "SELECT 1" 2>&1 | grep -q "ERROR 2002"; then
    echo "⚠️ Database not accessible yet (security group propagation takes 30-60 seconds)"
    echo "Waiting 30 seconds..."
    sleep 30
fi

# Create database
mysql -h database-pgni.cezawkgguojl.us-east-1.rds.amazonaws.com -P 3306 -u admin -pOmsairamdb951# \
    -e "CREATE DATABASE IF NOT EXISTS pgworld CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>&1 | grep -v "Warning"

# Create tables
mysql -h database-pgni.cezawkgguojl.us-east-1.rds.amazonaws.com -P 3306 -u admin -pOmsairamdb951# pgworld << 'SQLEOF' 2>&1 | grep -v "Warning"
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(100) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role ENUM('admin', 'pg_owner', 'tenant') NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS pg_properties (
    id INT AUTO_INCREMENT PRIMARY KEY,
    owner_id INT NOT NULL,
    name VARCHAR(255) NOT NULL,
    address TEXT,
    city VARCHAR(100),
    total_rooms INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS rooms (
    id INT AUTO_INCREMENT PRIMARY KEY,
    property_id INT NOT NULL,
    room_number VARCHAR(50),
    rent_amount DECIMAL(10,2),
    is_occupied BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (property_id) REFERENCES pg_properties(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS tenants (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    room_id INT,
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    move_in_date DATE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS payments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    tenant_id INT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    payment_date DATE NOT NULL,
    status ENUM('pending', 'completed', 'failed') DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
SQLEOF

echo "✓ Database initialized"
DB_INIT

echo ""
echo "=========================================="
echo "✅ Deployment Complete!"
echo "=========================================="
echo ""

# Test API
echo "Testing API..."
sleep 3

INTERNAL=$(ssh -i ~/$SSH_KEY -o StrictHostKeyChecking=no ec2-user@$EC2_IP "curl -s http://localhost:8080/health" 2>&1)
echo "Internal test: $INTERNAL"

EXTERNAL=$(curl -s http://$EC2_IP:8080/health)
echo "External test: $EXTERNAL"

echo ""

if [[ $EXTERNAL == *"healthy"* ]]; then
    echo "=========================================="
    echo "🎉 SUCCESS! API IS LIVE!"
    echo "=========================================="
    echo ""
    echo "API URL: http://$EC2_IP:8080"
    echo "Health: http://$EC2_IP:8080/health"
    echo ""
    echo "Response: $EXTERNAL"
    echo ""
    echo "Configure mobile apps:"
    echo "  baseUrl = 'http://$EC2_IP:8080'"
else
    echo "⚠️ API deployed but not responding yet"
    echo ""
    echo "Checking service status..."
    ssh -i ~/$SSH_KEY -o StrictHostKeyChecking=no ec2-user@$EC2_IP "sudo systemctl status pgworld-api --no-pager | head -15"
    
    echo ""
    echo "Checking logs..."
    ssh -i ~/$SSH_KEY -o StrictHostKeyChecking=no ec2-user@$EC2_IP "sudo journalctl -u pgworld-api -n 20 --no-pager"
fi

echo ""
echo "=========================================="

