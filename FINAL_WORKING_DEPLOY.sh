#!/bin/bash
# PGNi API - Final Working Deployment Script
# This script will deploy your API without any SSH key issues

EC2_IP="34.227.111.143"
EC2_USER="ec2-user"

echo ""
echo "========================================"
echo "PGNi API - Automated Deployment"
echo "========================================"
echo ""
echo "Starting deployment at $(date)"
echo ""

# Upload environment configuration
scp -i cloudshell-key.pem -o StrictHostKeyChecking=no << 'ENV_FILE' $EC2_USER@$EC2_IP:~/preprod.env
DB_HOST=database-pgni.cezawkgguojl.us-east-1.rds.amazonaws.com
DB_PORT=3306
DB_USER=admin
DB_PASSWORD=Omsairamdb951#
DB_NAME=pgworld
AWS_REGION=us-east-1
S3_BUCKET=pgni-preprod-698302425856-uploads
PORT=8080
test=false
ENV_FILE

# Deploy everything
ssh -i cloudshell-key.pem -o StrictHostKeyChecking=no $EC2_USER@$EC2_IP 'bash -s' << 'DEPLOY'
#!/bin/bash
set -e

echo "Step 1: Installing prerequisites..."
sudo yum update -y > /dev/null 2>&1
sudo yum install -y git wget mysql > /dev/null 2>&1

if [ ! -f /usr/local/go/bin/go ]; then
    cd /tmp
    wget -q https://go.dev/dl/go1.21.0.linux-amd64.tar.gz
    sudo tar -C /usr/local -xzf go1.21.0.linux-amd64.tar.gz
    rm -f go1.21.0.linux-amd64.tar.gz
fi

export PATH=$PATH:/usr/local/go/bin
echo "Prerequisites OK"

echo "Step 2: Building API..."
rm -rf /tmp/pgni
cd /tmp
git clone https://github.com/siddam01/pgni.git > /dev/null 2>&1
cd pgni/pgworld-api-master
go mod download > /dev/null 2>&1
go build -o pgworld-api .

if [ ! -f pgworld-api ]; then
    echo "Build failed"
    exit 1
fi
echo "Build OK"

echo "Step 3: Deploying..."
sudo systemctl stop pgworld-api 2>/dev/null || true
sleep 2

sudo mkdir -p /opt/pgworld/logs
sudo chown -R ec2-user:ec2-user /opt/pgworld

cp pgworld-api /opt/pgworld/
chmod +x /opt/pgworld/pgworld-api

cat > /tmp/preprod.env << 'EOF'
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

sudo cp /tmp/preprod.env /opt/pgworld/.env
chmod 600 /opt/pgworld/.env

sudo tee /etc/systemd/system/pgworld-api.service > /dev/null << 'SVC'
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
SVC

sudo systemctl daemon-reload
sudo systemctl enable pgworld-api
sudo systemctl start pgworld-api
echo "Service started"

sleep 5

echo "Step 4: Initializing database..."
mysql -h database-pgni.cezawkgguojl.us-east-1.rds.amazonaws.com -P 3306 -u admin -pOmsairamdb951# << 'SQL' 2>/dev/null
CREATE DATABASE IF NOT EXISTS pgworld CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE pgworld;
CREATE TABLE IF NOT EXISTS users (id INT AUTO_INCREMENT PRIMARY KEY, username VARCHAR(100) NOT NULL UNIQUE, email VARCHAR(255) NOT NULL UNIQUE, password_hash VARCHAR(255) NOT NULL, role ENUM('admin', 'pg_owner', 'tenant') NOT NULL, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, INDEX idx_email (email), INDEX idx_role (role)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS pg_properties (id INT AUTO_INCREMENT PRIMARY KEY, owner_id INT NOT NULL, name VARCHAR(255) NOT NULL, address TEXT, city VARCHAR(100), state VARCHAR(100), pincode VARCHAR(20), total_rooms INT DEFAULT 0, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE CASCADE) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS rooms (id INT AUTO_INCREMENT PRIMARY KEY, property_id INT NOT NULL, room_number VARCHAR(50) NOT NULL, room_type VARCHAR(50), rent_amount DECIMAL(10,2), is_occupied BOOLEAN DEFAULT FALSE, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, FOREIGN KEY (property_id) REFERENCES pg_properties(id) ON DELETE CASCADE) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS tenants (id INT AUTO_INCREMENT PRIMARY KEY, user_id INT NOT NULL, room_id INT, name VARCHAR(255) NOT NULL, phone VARCHAR(20), email VARCHAR(255), id_proof_type VARCHAR(50), id_proof_number VARCHAR(100), move_in_date DATE, move_out_date DATE, is_active BOOLEAN DEFAULT TRUE, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE, FOREIGN KEY (room_id) REFERENCES rooms(id) ON DELETE SET NULL) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS payments (id INT AUTO_INCREMENT PRIMARY KEY, tenant_id INT NOT NULL, amount DECIMAL(10,2) NOT NULL, payment_date DATE NOT NULL, payment_type ENUM('rent', 'deposit', 'maintenance', 'other') DEFAULT 'rent', status ENUM('pending', 'completed', 'failed') DEFAULT 'pending', transaction_id VARCHAR(255), notes TEXT, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
SQL

echo "Database OK"

echo ""
echo "Testing API..."
curl -s http://localhost:8080/health || echo "Starting..."
curl -s http://34.227.111.143:8080/health || echo "Warming up..."

echo ""
echo "Service status:"
sudo systemctl status pgworld-api --no-pager | head -10

echo ""
echo "Recent logs:"
sudo journalctl -u pgworld-api -n 15 --no-pager

echo ""
echo "DEPLOYMENT COMPLETE!"

DEPLOY

echo ""
echo "========================================"
echo "Testing from external..."
echo "========================================"

sleep 5

for i in {1..10}; do
    RESP=$(curl -s http://$EC2_IP:8080/health 2>/dev/null)
    if [ -n "$RESP" ]; then
        echo "SUCCESS! API Response: $RESP"
        break
    fi
    [ $i -lt 10 ] && sleep 3
done

echo ""
echo "========================================"
echo "DEPLOYMENT FINISHED!"
echo "========================================"
echo ""
echo "API URL: http://$EC2_IP:8080"
echo "Health: http://$EC2_IP:8080/health"
echo ""
echo "Test in browser: http://$EC2_IP:8080/health"
echo ""

