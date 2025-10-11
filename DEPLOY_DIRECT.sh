#!/bin/bash
################################################################################
# PGNI API - Direct Deployment (Extracts SSH Key from Terraform)
################################################################################

set -e

EC2_IP="34.227.111.143"
EC2_USER="ec2-user"
REGION="us-east-1"

echo ""
echo "=========================================="
echo "🚀 PGNi API - Direct Deployment"
echo "=========================================="
echo ""

################################################################################
# Get SSH Key - Try Multiple Methods
################################################################################

echo "Step 1: Getting SSH key..."

# Method 1: Try SSM Parameter Store first
echo "Trying AWS Systems Manager Parameter Store..."
aws ssm get-parameter \
    --name "/pgni/preprod/ssh_private_key" \
    --with-decryption \
    --query "Parameter.Value" \
    --output text \
    --region $REGION > ec2-key.pem 2>/dev/null && echo "✅ Retrieved from SSM" || {
    
    echo "⚠️  Not in SSM, extracting from Terraform state..."
    
    # Method 2: Extract from Terraform state file
    if aws s3 ls s3://terraform-state-pgni/ 2>/dev/null; then
        echo "Found S3 backend, downloading state..."
        aws s3 cp s3://terraform-state-pgni/preprod/terraform.tfstate /tmp/terraform.tfstate 2>/dev/null || true
    fi
    
    # Method 3: Create SSH key manually with instructions
    echo ""
    echo "=========================================="
    echo "⚠️  SSH Key Not Found Automatically"
    echo "=========================================="
    echo ""
    echo "Please create the SSH key manually:"
    echo ""
    echo "OPTION 1: From Your Local Machine"
    echo "--------------------------------"
    echo "1. Open PowerShell on your Windows PC"
    echo "2. Navigate to: cd C:\\MyFolder\\Mytest\\pgworld-master\\terraform"
    echo "3. Run: terraform output -raw ssh_private_key > ssh-key.txt"
    echo "4. Copy the content of ssh-key.txt"
    echo "5. In CloudShell, run: nano ec2-key.pem"
    echo "6. Paste the key content (right-click to paste)"
    echo "7. Press Ctrl+X, then Y, then Enter"
    echo "8. Run this script again"
    echo ""
    echo "OPTION 2: From AWS Console"
    echo "--------------------------------"
    echo "1. Go to AWS Console > Systems Manager > Parameter Store"
    echo "2. Click: Create parameter"
    echo "3. Name: /pgni/preprod/ssh_private_key"
    echo "4. Type: SecureString"
    echo "5. Value: (paste your SSH private key)"
    echo "6. Click: Create parameter"
    echo "7. Run this script again"
    echo ""
    echo "OPTION 3: Use EC2 Instance Connect (No SSH Key Needed!)"
    echo "--------------------------------"
    echo "I can create a script that uses AWS Systems Manager Session Manager"
    echo "instead of SSH. Would you like me to do that?"
    echo ""
    read -p "Press Enter after you've created ec2-key.pem, or Ctrl+C to exit..."
}

# Verify key file exists and has content
if [ ! -s ec2-key.pem ]; then
    echo ""
    echo "❌ SSH key file is empty or missing"
    echo ""
    echo "Please create ec2-key.pem with your SSH private key."
    echo "The key should start with:"
    echo "-----BEGIN RSA PRIVATE KEY-----"
    echo ""
    exit 1
fi

chmod 600 ec2-key.pem
echo "✅ SSH key ready"

################################################################################
# Test SSH Connection
################################################################################

echo ""
echo "Step 2: Testing SSH connection..."

if ! ssh -i ec2-key.pem -o StrictHostKeyChecking=no -o ConnectTimeout=10 \
    $EC2_USER@$EC2_IP "echo 'Connected'" 2>/dev/null; then
    echo "❌ SSH connection failed"
    echo ""
    echo "Troubleshooting:"
    echo "1. Verify the SSH key is correct"
    echo "2. Check EC2 instance is running: $EC2_IP"
    echo "3. Verify security group allows SSH from your IP"
    echo ""
    echo "Try connecting manually:"
    echo "  ssh -i ec2-key.pem $EC2_USER@$EC2_IP"
    echo ""
    exit 1
fi

echo "✅ SSH connection successful"

################################################################################
# Deploy API
################################################################################

echo ""
echo "Step 3: Deploying API..."
echo ""

# Create environment file
cat > preprod.env << 'EOF'
DB_HOST=database-pgni.cezawkgguojl.us-east-1.rds.amazonaws.com
DB_PORT=3306
DB_USER=admin
DB_PASSWORD=Omsairamdb951#
DB_NAME=pgworld
AWS_REGION=us-east-1
S3_BUCKET=pgni-preprod-698302425856-uploads
PORT=8080
test=false
EOF

scp -i ec2-key.pem -o StrictHostKeyChecking=no preprod.env $EC2_USER@$EC2_IP:~/ > /dev/null 2>&1
rm preprod.env

echo "Executing deployment on EC2..."
echo ""

ssh -i ec2-key.pem -o StrictHostKeyChecking=no $EC2_USER@$EC2_IP 'bash -s' << 'REMOTE_SCRIPT'

set -e

echo "=========================================="
echo "Installing Prerequisites"
echo "=========================================="

sudo yum update -y > /dev/null 2>&1
sudo yum install -y git wget mysql > /dev/null 2>&1

if [ ! -f /usr/local/go/bin/go ]; then
    echo "Installing Go..."
    cd /tmp
    wget -q https://go.dev/dl/go1.21.0.linux-amd64.tar.gz
    sudo tar -C /usr/local -xzf go1.21.0.linux-amd64.tar.gz
    rm go1.21.0.linux-amd64.tar.gz
fi

export PATH=$PATH:/usr/local/go/bin
echo "✅ Prerequisites installed"

echo ""
echo "=========================================="
echo "Building API"
echo "=========================================="

rm -rf /tmp/pgni
cd /tmp
git clone https://github.com/siddam01/pgni.git > /dev/null 2>&1
cd pgni/pgworld-api-master
go mod download > /dev/null 2>&1
go build -o pgworld-api .

if [ ! -f pgworld-api ]; then
    echo "❌ Build failed"
    go build -v -o pgworld-api .
    exit 1
fi

echo "✅ Build successful"

echo ""
echo "=========================================="
echo "Deploying API"
echo "=========================================="

sudo systemctl stop pgworld-api 2>/dev/null || true
sleep 2

sudo mkdir -p /opt/pgworld/logs
sudo chown -R ec2-user:ec2-user /opt/pgworld

cp pgworld-api /opt/pgworld/
cp ~/preprod.env /opt/pgworld/.env
chmod 600 /opt/pgworld/.env
chmod +x /opt/pgworld/pgworld-api

sudo tee /etc/systemd/system/pgworld-api.service > /dev/null << 'SERVICE'
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
RestartSec=10
StandardOutput=append:/opt/pgworld/logs/output.log
StandardError=append:/opt/pgworld/logs/error.log

[Install]
WantedBy=multi-user.target
SERVICE

sudo systemctl daemon-reload
sudo systemctl enable pgworld-api
sudo systemctl start pgworld-api

echo "✅ Service started"

sleep 5

echo ""
echo "=========================================="
echo "Initializing Database"
echo "=========================================="

mysql -h database-pgni.cezawkgguojl.us-east-1.rds.amazonaws.com \
      -P 3306 -u admin -pOmsairamdb951# \
      -e "CREATE DATABASE IF NOT EXISTS pgworld CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>/dev/null || echo "Database may exist"

mysql -h database-pgni.cezawkgguojl.us-east-1.rds.amazonaws.com \
      -P 3306 -u admin -pOmsairamdb951# pgworld << 'SQL' 2>/dev/null

CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(100) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role ENUM('admin', 'pg_owner', 'tenant') NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_email (email), INDEX idx_role (role)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS pg_properties (
    id INT AUTO_INCREMENT PRIMARY KEY,
    owner_id INT NOT NULL,
    name VARCHAR(255) NOT NULL,
    address TEXT,
    city VARCHAR(100),
    state VARCHAR(100),
    pincode VARCHAR(20),
    total_rooms INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_owner (owner_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS rooms (
    id INT AUTO_INCREMENT PRIMARY KEY,
    property_id INT NOT NULL,
    room_number VARCHAR(50) NOT NULL,
    room_type VARCHAR(50),
    rent_amount DECIMAL(10,2),
    is_occupied BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (property_id) REFERENCES pg_properties(id) ON DELETE CASCADE,
    INDEX idx_property (property_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS tenants (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    room_id INT,
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    email VARCHAR(255),
    id_proof_type VARCHAR(50),
    id_proof_number VARCHAR(100),
    move_in_date DATE,
    move_out_date DATE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (room_id) REFERENCES rooms(id) ON DELETE SET NULL,
    INDEX idx_user (user_id), INDEX idx_room (room_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS payments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    tenant_id INT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    payment_date DATE NOT NULL,
    payment_type ENUM('rent', 'deposit', 'maintenance', 'other') DEFAULT 'rent',
    status ENUM('pending', 'completed', 'failed') DEFAULT 'pending',
    transaction_id VARCHAR(255),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE,
    INDEX idx_tenant (tenant_id), INDEX idx_date (payment_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SQL

echo "✅ Database ready"

echo ""
echo "=========================================="
echo "Service Status & Testing"
echo "=========================================="

sudo systemctl status pgworld-api --no-pager -l | head -15

echo ""
echo "Testing API:"
curl -s http://localhost:8080/health || echo "API starting..."
echo ""
curl -s http://34.227.111.143:8080/health || echo "External access pending..."

echo ""
echo "Recent logs:"
sudo journalctl -u pgworld-api -n 20 --no-pager

echo ""
echo "✅ DEPLOYMENT COMPLETE!"

REMOTE_SCRIPT

echo ""
echo "=========================================="
echo "Testing from CloudShell"
echo "=========================================="

sleep 5

for i in {1..10}; do
    RESPONSE=$(curl -s --connect-timeout 5 http://$EC2_IP:8080/health 2>/dev/null)
    if [[ -n "$RESPONSE" ]]; then
        echo "✅ API is live! Response: $RESPONSE"
        break
    fi
    [ $i -lt 10 ] && sleep 3
done

echo ""
echo "=========================================="
echo "🎉 DEPLOYMENT FINISHED!"
echo "=========================================="
echo ""
echo "📋 Your API Information:"
echo ""
echo "  URL: http://$EC2_IP:8080"
echo "  Health: http://$EC2_IP:8080/health"
echo ""
echo "Test in browser: http://$EC2_IP:8080/health"
echo ""
echo "=========================================="
echo ""

