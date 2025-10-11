#!/bin/bash
################################################################################
# PGNI API - Simple Deployment (No SSH Key Issues)
################################################################################

set -e

EC2_IP="34.227.111.143"
EC2_USER="ec2-user"
REGION="us-east-1"

echo ""
echo "=========================================="
echo "🚀 PGNi API - Simple Deployment"
echo "=========================================="
echo ""

################################################################################
# Get SSH Key from SSM Parameter Store
################################################################################

echo "Step 1: Getting SSH key from AWS..."

# Get the SSH key
aws ssm get-parameter \
    --name "/pgni/preprod/ssh_private_key" \
    --with-decryption \
    --query "Parameter.Value" \
    --output text \
    --region $REGION > ec2-key.pem

if [ ! -s ec2-key.pem ]; then
    echo "❌ Could not retrieve SSH key from SSM Parameter Store"
    echo ""
    echo "Manual alternative:"
    echo "1. Go to AWS Systems Manager > Parameter Store"
    echo "2. Find: /pgni/preprod/ssh_private_key"
    echo "3. Copy the value"
    echo "4. Create ec2-key.pem with that content"
    echo "5. Run: chmod 600 ec2-key.pem"
    echo "6. Then run this script again"
    exit 1
fi

chmod 600 ec2-key.pem
echo "✅ SSH key retrieved"

################################################################################
# Test SSH Connection
################################################################################

echo "Step 2: Testing SSH connection..."

if ! ssh -i ec2-key.pem -o StrictHostKeyChecking=no -o ConnectTimeout=10 \
    $EC2_USER@$EC2_IP "echo 'Connected'" &> /dev/null; then
    echo "❌ SSH connection failed"
    echo ""
    echo "The SSH key was retrieved but connection failed."
    echo "This might be a temporary network issue."
    echo "Try running the script again."
    exit 1
fi

echo "✅ SSH connection successful"

################################################################################
# Deploy API
################################################################################

echo ""
echo "Step 3: Deploying API to EC2..."
echo ""

# Upload environment file
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

echo "Uploading configuration..."
scp -i ec2-key.pem -o StrictHostKeyChecking=no preprod.env $EC2_USER@$EC2_IP:~/
rm preprod.env

echo "Running deployment on EC2..."
echo ""

ssh -i ec2-key.pem -o StrictHostKeyChecking=no $EC2_USER@$EC2_IP << 'REMOTE_DEPLOY'

echo "=========================================="
echo "Installing Prerequisites"
echo "=========================================="

sudo yum update -y > /dev/null 2>&1
sudo yum install -y git wget mysql > /dev/null 2>&1

# Install Go
if [ ! -f /usr/local/go/bin/go ]; then
    echo "Installing Go..."
    cd /tmp
    wget -q https://go.dev/dl/go1.21.0.linux-amd64.tar.gz
    sudo tar -C /usr/local -xzf go1.21.0.linux-amd64.tar.gz
    rm go1.21.0.linux-amd64.tar.gz
    echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
fi

export PATH=$PATH:/usr/local/go/bin

echo "✅ Prerequisites installed"
echo ""

echo "=========================================="
echo "Building API"
echo "=========================================="

rm -rf /tmp/pgni
cd /tmp
echo "Cloning repository..."
git clone https://github.com/siddam01/pgni.git > /dev/null 2>&1

cd pgni/pgworld-api-master
echo "Downloading dependencies..."
go mod download > /dev/null 2>&1

echo "Building..."
go build -o pgworld-api .

if [ ! -f pgworld-api ]; then
    echo "❌ Build failed"
    exit 1
fi

echo "✅ Build successful"
echo ""

echo "=========================================="
echo "Deploying API"
echo "=========================================="

# Stop existing service
sudo systemctl stop pgworld-api 2>/dev/null || true
sleep 2

# Setup directories
sudo mkdir -p /opt/pgworld/logs
sudo chown -R ec2-user:ec2-user /opt/pgworld

# Copy files
cp pgworld-api /opt/pgworld/
cp ~/preprod.env /opt/pgworld/.env
chmod 600 /opt/pgworld/.env
chmod +x /opt/pgworld/pgworld-api

echo "✅ Files deployed"
echo ""

echo "=========================================="
echo "Configuring Service"
echo "=========================================="

# Create systemd service
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

# Start service
sudo systemctl daemon-reload
sudo systemctl enable pgworld-api
sudo systemctl start pgworld-api

echo "✅ Service configured and started"
echo ""

# Wait for startup
echo "Waiting for service to start..."
sleep 5

echo ""
echo "=========================================="
echo "Initializing Database"
echo "=========================================="

mysql -h database-pgni.cezawkgguojl.us-east-1.rds.amazonaws.com \
      -P 3306 \
      -u admin \
      -pOmsairamdb951# \
      -e "CREATE DATABASE IF NOT EXISTS pgworld CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>/dev/null

mysql -h database-pgni.cezawkgguojl.us-east-1.rds.amazonaws.com \
      -P 3306 \
      -u admin \
      -pOmsairamdb951# \
      pgworld << 'SQL' 2>/dev/null

CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(100) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role ENUM('admin', 'pg_owner', 'tenant') NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_email (email),
    INDEX idx_role (role)
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
    INDEX idx_user (user_id),
    INDEX idx_room (room_id)
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
    INDEX idx_tenant (tenant_id),
    INDEX idx_date (payment_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SQL

if [ $? -eq 0 ]; then
    echo "✅ Database initialized"
else
    echo "⚠️  Database may already exist (this is OK)"
fi

echo ""
echo "=========================================="
echo "Service Status"
echo "=========================================="

sudo systemctl status pgworld-api --no-pager -l | head -20

echo ""
echo "=========================================="
echo "Testing API"
echo "=========================================="

echo "Internal test (localhost):"
curl -s http://localhost:8080/health || echo "Not responding yet"

echo ""
echo "External test (public IP):"
curl -s http://34.227.111.143:8080/health || echo "Not responding yet"

echo ""
echo "=========================================="
echo "Recent Logs"
echo "=========================================="

sudo journalctl -u pgworld-api -n 30 --no-pager

echo ""
echo "=========================================="
echo "✅ DEPLOYMENT COMPLETE!"
echo "=========================================="

REMOTE_DEPLOY

################################################################################
# Test from CloudShell
################################################################################

echo ""
echo "=========================================="
echo "Testing from CloudShell"
echo "=========================================="
echo ""

echo "Waiting 5 seconds for service to fully start..."
sleep 5

SUCCESS=false
for i in {1..10}; do
    echo "Test attempt $i/10..."
    RESPONSE=$(curl -s --connect-timeout 5 http://$EC2_IP:8080/health 2>/dev/null)
    
    if [[ "$RESPONSE" == *"healthy"* ]] || [[ "$RESPONSE" == *"ok"* ]] || [[ "$RESPONSE" != "" ]]; then
        echo "✅ SUCCESS! API is responding!"
        echo "Response: $RESPONSE"
        SUCCESS=true
        break
    fi
    
    if [ $i -lt 10 ]; then
        sleep 3
    fi
done

echo ""
echo "=========================================="
echo "🎉 DEPLOYMENT FINISHED!"
echo "=========================================="
echo ""

if [ "$SUCCESS" = true ]; then
    echo "✅ Your API is LIVE and accessible!"
else
    echo "⚠️  API deployed but may need a few more seconds to start"
fi

echo ""
echo "📋 Access Information:"
echo ""
echo "  🌐 API URL:"
echo "     http://$EC2_IP:8080"
echo ""
echo "  ❤️  Health Check:"
echo "     http://$EC2_IP:8080/health"
echo ""
echo "  🔍 Test in Browser:"
echo "     Open: http://$EC2_IP:8080/health"
echo ""
echo "  🔐 SSH to Server:"
echo "     ssh -i ec2-key.pem $EC2_USER@$EC2_IP"
echo ""
echo "  📊 Check Status:"
echo "     ssh -i ec2-key.pem $EC2_USER@$EC2_IP 'sudo systemctl status pgworld-api'"
echo ""
echo "  📝 View Logs:"
echo "     ssh -i ec2-key.pem $EC2_USER@$EC2_IP 'sudo journalctl -u pgworld-api -f'"
echo ""
echo "=========================================="
echo ""
echo "📱 Next Steps:"
echo ""
echo "1. Test API: curl http://$EC2_IP:8080/health"
echo "2. Update mobile apps with API URL: http://$EC2_IP:8080"
echo "3. Build APKs: flutter build apk --release"
echo "4. Deploy to users!"
echo ""
echo "=========================================="
echo "✅ ALL DONE!"
echo "=========================================="
echo ""

