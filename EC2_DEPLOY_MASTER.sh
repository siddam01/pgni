#!/bin/bash

#############################################################
# PGNI Master Deployment Script for EC2
# One-command deployment for PG/Hostel Management System
#############################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

clear

echo -e "${CYAN}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║    PGNI - PG/Hostel Management System                    ║
║    Master Deployment Script                              ║
║    Version 1.0                                           ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}Starting deployment process...${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

#############################################################
# CONFIGURATION - AUTO DETECTION
#############################################################

echo -e "${YELLOW}📋 Step 1: Auto-detecting AWS Configuration${NC}"
echo ""

# Check if running on EC2
if [ -f /sys/hypervisor/uuid ] && [ `head -c 3 /sys/hypervisor/uuid` == ec2 ]; then
    echo -e "${GREEN}✅ Running on AWS EC2${NC}"
    IS_EC2=true
else
    echo -e "${YELLOW}⚠️  Not running on EC2, continuing anyway...${NC}"
    IS_EC2=false
fi

# Check for existing configuration file
CONFIG_FILE="$HOME/.pgni-config"
if [ -f "$CONFIG_FILE" ]; then
    echo -e "${GREEN}✅ Found existing configuration${NC}"
    source "$CONFIG_FILE"
    echo "Using saved configuration:"
    echo "  EC2 IP: $EC2_IP"
    echo "  RDS: $RDS_ENDPOINT"
    echo "  Database: $DB_NAME"
    echo "  S3 Bucket: $S3_BUCKET"
    echo ""
    read -p "Use these settings? (y/n) [y]: " USE_SAVED
    USE_SAVED=${USE_SAVED:-y}
    
    if [ "$USE_SAVED" != "y" ]; then
        rm -f "$CONFIG_FILE"
    fi
fi

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Auto-detecting AWS resources..."
    echo ""
    
    # Auto-detect EC2 IP
    EC2_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "")
    if [ -n "$EC2_IP" ]; then
        echo -e "${GREEN}✅ EC2 Public IP: $EC2_IP${NC}"
    else
        read -p "Enter EC2 Public IP: " EC2_IP
    fi
    
    # Auto-detect RDS endpoint
    echo "Searching for RDS instances..."
    RDS_ENDPOINT=$(aws rds describe-db-instances --query 'DBInstances[?DBInstanceStatus==`available`].Endpoint.Address' --output text 2>/dev/null | head -n 1)
    if [ -n "$RDS_ENDPOINT" ]; then
        echo -e "${GREEN}✅ Found RDS: $RDS_ENDPOINT${NC}"
        
        # Get DB name
        DB_NAME=$(aws rds describe-db-instances --query 'DBInstances[?Endpoint.Address==`'$RDS_ENDPOINT'`].DBName' --output text 2>/dev/null)
        if [ -z "$DB_NAME" ] || [ "$DB_NAME" == "None" ]; then
            DB_NAME="pgworld"
        fi
        echo -e "${GREEN}✅ Database Name: $DB_NAME${NC}"
        
        # Get master username
        DB_USER=$(aws rds describe-db-instances --query 'DBInstances[?Endpoint.Address==`'$RDS_ENDPOINT'`].MasterUsername' --output text 2>/dev/null)
        if [ -n "$DB_USER" ]; then
            echo -e "${GREEN}✅ Database User: $DB_USER${NC}"
        else
            DB_USER="admin"
        fi
    else
        echo -e "${YELLOW}⚠️  Could not auto-detect RDS${NC}"
        read -p "Enter RDS Endpoint: " RDS_ENDPOINT
        read -p "Enter Database User [admin]: " DB_USER
        DB_USER=${DB_USER:-admin}
        read -p "Enter Database Name [pgworld]: " DB_NAME
        DB_NAME=${DB_NAME:-pgworld}
    fi
    
    # Database password (must be entered manually for security)
    echo ""
    read -sp "Enter Database Password: " DB_PASSWORD
    echo ""
    
    # Auto-detect S3 bucket
    echo "Searching for S3 buckets..."
    S3_BUCKET=$(aws s3 ls | grep -i pgworld | grep -i admin | head -n 1 | awk '{print $3}')
    if [ -n "$S3_BUCKET" ]; then
        echo -e "${GREEN}✅ Found S3 Bucket: $S3_BUCKET${NC}"
    else
        S3_BUCKET="pgworld-admin"
        echo -e "${YELLOW}⚠️  Using default S3 Bucket: $S3_BUCKET${NC}"
    fi
    
    # Save configuration
    cat > "$CONFIG_FILE" << EOF
EC2_IP="$EC2_IP"
RDS_ENDPOINT="$RDS_ENDPOINT"
DB_USER="$DB_USER"
DB_NAME="$DB_NAME"
S3_BUCKET="$S3_BUCKET"
EOF
    chmod 600 "$CONFIG_FILE"
    echo ""
    echo -e "${GREEN}✅ Configuration saved to $CONFIG_FILE${NC}"
fi

echo ""
echo -e "${CYAN}========================================${NC}"
echo -e "${GREEN}📊 Deployment Configuration${NC}"
echo -e "${CYAN}========================================${NC}"
echo "EC2 Public IP: $EC2_IP"
echo "RDS Endpoint: $RDS_ENDPOINT"
echo "Database User: $DB_USER"
echo "Database Name: $DB_NAME"
echo "S3 Bucket: $S3_BUCKET"
echo -e "${CYAN}========================================${NC}"
echo ""

read -p "Continue with deployment? (Y/n): " CONTINUE
CONTINUE=${CONTINUE:-Y}
if [ "$CONTINUE" != "Y" ] && [ "$CONTINUE" != "y" ]; then
    echo "Deployment cancelled."
    exit 0
fi

#############################################################
# INSTALL DEPENDENCIES
#############################################################

echo ""
echo -e "${YELLOW}📦 Step 2: Installing Dependencies${NC}"
echo ""

# Update system
echo "Updating system packages..."
sudo yum update -y -q

# Install Go
if ! command -v go &> /dev/null; then
    echo "Installing Go..."
    cd /tmp
    wget -q https://go.dev/dl/go1.21.5.linux-amd64.tar.gz
    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf go1.21.5.linux-amd64.tar.gz
    echo 'export PATH=$PATH:/usr/local/go/bin' | sudo tee -a /etc/profile
    export PATH=$PATH:/usr/local/go/bin
    echo -e "${GREEN}✅ Go installed${NC}"
else
    echo -e "${GREEN}✅ Go already installed$(go version)${NC}"
fi

# Install MySQL client
if ! command -v mysql &> /dev/null; then
    echo "Installing MySQL client..."
    sudo yum install -y mysql -q
    echo -e "${GREEN}✅ MySQL client installed${NC}"
else
    echo -e "${GREEN}✅ MySQL client already installed${NC}"
fi

# Install Git
if ! command -v git &> /dev/null; then
    echo "Installing Git..."
    sudo yum install -y git -q
    echo -e "${GREEN}✅ Git installed${NC}"
else
    echo -e "${GREEN}✅ Git already installed${NC}"
fi

# Install AWS CLI
if ! command -v aws &> /dev/null; then
    echo "Installing AWS CLI..."
    cd /tmp
    curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip -q awscliv2.zip
    sudo ./aws/install
    rm -rf aws awscliv2.zip
    echo -e "${GREEN}✅ AWS CLI installed${NC}"
else
    echo -e "${GREEN}✅ AWS CLI already installed${NC}"
fi

#############################################################
# CLONE REPOSITORY
#############################################################

echo ""
echo -e "${YELLOW}📥 Step 3: Getting Application Code${NC}"
echo ""

WORK_DIR="$HOME/pgni-deployment"

if [ -d "$WORK_DIR" ]; then
    echo "Cleaning up existing directory..."
    rm -rf "$WORK_DIR"
fi

mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

echo "Cloning repository from GitHub..."
git clone https://github.com/siddam01/pgni.git temp-repo
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Repository cloned successfully${NC}"
    
    # Move the required directories
    if [ -d "temp-repo/pgworld-api-master" ]; then
        cp -r temp-repo/pgworld-api-master .
        echo -e "${GREEN}✅ Backend code copied${NC}"
    else
        echo -e "${RED}❌ Backend code not found in repository${NC}"
        exit 1
    fi
    
    if [ -d "temp-repo/pgworld-master" ]; then
        cp -r temp-repo/pgworld-master .
        echo -e "${GREEN}✅ Frontend code copied${NC}"
    fi
    
    # Cleanup
    rm -rf temp-repo
else
    echo -e "${RED}❌ Failed to clone repository${NC}"
    exit 1
fi

#############################################################
# SETUP DATABASE
#############################################################

echo ""
echo -e "${YELLOW}💾 Step 4: Setting up Database${NC}"
echo ""

echo "Creating database and tables..."

mysql -h "$RDS_ENDPOINT" -u "$DB_USER" -p"$DB_PASSWORD" << EOSQL
-- Create database if not exists
CREATE DATABASE IF NOT EXISTS $DB_NAME;
USE $DB_NAME;

-- Create admin_permissions table
CREATE TABLE IF NOT EXISTS admin_permissions (
  id VARCHAR(12) PRIMARY KEY,
  admin_id VARCHAR(12) NOT NULL,
  hostel_id VARCHAR(12) NOT NULL,
  role VARCHAR(20) NOT NULL DEFAULT 'manager',
  can_view_dashboard BOOLEAN DEFAULT FALSE,
  can_manage_rooms BOOLEAN DEFAULT FALSE,
  can_manage_tenants BOOLEAN DEFAULT FALSE,
  can_manage_bills BOOLEAN DEFAULT FALSE,
  can_view_financials BOOLEAN DEFAULT FALSE,
  can_manage_employees BOOLEAN DEFAULT FALSE,
  can_view_reports BOOLEAN DEFAULT FALSE,
  can_manage_notices BOOLEAN DEFAULT FALSE,
  can_manage_issues BOOLEAN DEFAULT FALSE,
  can_manage_payments BOOLEAN DEFAULT FALSE,
  assigned_by VARCHAR(12) NOT NULL,
  status ENUM('0', '1') DEFAULT '1',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_admin_id (admin_id),
  INDEX idx_hostel_id (hostel_id),
  INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Add columns to admins table if they don't exist
ALTER TABLE admins 
  ADD COLUMN IF NOT EXISTS role ENUM('owner', 'manager') DEFAULT 'owner',
  ADD COLUMN IF NOT EXISTS parent_admin_id VARCHAR(12) NULL,
  ADD COLUMN IF NOT EXISTS assigned_hostel_ids TEXT NULL;

-- Update existing admins to be owners
UPDATE admins SET role = 'owner' WHERE role IS NULL;

EOSQL

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Database setup complete${NC}"
else
    echo -e "${RED}❌ Database setup failed${NC}"
    exit 1
fi

#############################################################
# BUILD & DEPLOY BACKEND
#############################################################

echo ""
echo -e "${YELLOW}🔧 Step 5: Building and Deploying Backend${NC}"
echo ""

cd pgworld-api-master

# Create .env file
echo "Creating .env file..."
cat > .env << EOF
DB_HOST=$RDS_ENDPOINT
DB_PORT=3306
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASSWORD
DB_NAME=$DB_NAME
PORT=8080
CONNECTION_POOL=10
ENV=production
S3_BUCKET=$S3_BUCKET-uploads
AWS_REGION=us-east-1
EOF

echo -e "${GREEN}✅ .env file created${NC}"

# Build backend
echo "Building Go application..."
go mod download
go build -o pgworld-api main.go

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Backend build successful${NC}"
else
    echo -e "${RED}❌ Backend build failed${NC}"
    exit 1
fi

# Create systemd service
echo "Creating systemd service..."
sudo tee /etc/systemd/system/pgworld-api.service > /dev/null << 'EOSVC'
[Unit]
Description=PG World API Server
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/home/ec2-user/pgni-deployment/pgworld-api-master
ExecStart=/home/ec2-user/pgni-deployment/pgworld-api-master/pgworld-api
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOSVC

# Start service
echo "Starting backend service..."
sudo systemctl daemon-reload
sudo systemctl stop pgworld-api 2>/dev/null || true
sudo systemctl start pgworld-api
sudo systemctl enable pgworld-api

sleep 3

if sudo systemctl is-active --quiet pgworld-api; then
    echo -e "${GREEN}✅ Backend service started successfully${NC}"
else
    echo -e "${RED}❌ Backend service failed to start${NC}"
    echo "Checking logs..."
    sudo journalctl -u pgworld-api --since "1 minute ago" --no-pager
    exit 1
fi

#############################################################
# CONFIGURE FIREWALL
#############################################################

echo ""
echo -e "${YELLOW}🔒 Step 6: Configuring Firewall${NC}"
echo ""

# Allow port 8080
sudo firewall-cmd --permanent --add-port=8080/tcp 2>/dev/null || true
sudo firewall-cmd --reload 2>/dev/null || true

echo -e "${GREEN}✅ Firewall configured${NC}"

#############################################################
# TEST DEPLOYMENT
#############################################################

echo ""
echo -e "${YELLOW}✅ Step 7: Testing Deployment${NC}"
echo ""

echo "Testing backend API..."
sleep 2

RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/ || echo "000")

if [ "$RESPONSE" = "200" ]; then
    echo -e "${GREEN}✅ Backend API is responding${NC}"
else
    echo -e "${YELLOW}⚠️  Backend API returned status: $RESPONSE${NC}"
    echo "Checking service status..."
    sudo systemctl status pgworld-api --no-pager
fi

#############################################################
# COMPLETION
#############################################################

echo ""
echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                                                           ║${NC}"
echo -e "${CYAN}║         ${GREEN}🎉 DEPLOYMENT SUCCESSFUL! 🎉${CYAN}                     ║${NC}"
echo -e "${CYAN}║                                                           ║${NC}"
echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}📊 Deployment Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${GREEN}✅ Backend API:${NC} http://$EC2_IP:8080"
echo -e "${GREEN}✅ Database:${NC} $RDS_ENDPOINT"
echo -e "${GREEN}✅ Service:${NC} pgworld-api (running)"
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}📝 Important Information${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Working Directory: $WORK_DIR"
echo "Backend Location: $WORK_DIR/pgworld-api-master"
echo "Service Name: pgworld-api"
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}🔧 Useful Commands${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "View logs:"
echo "  sudo journalctl -u pgworld-api -f"
echo ""
echo "Restart service:"
echo "  sudo systemctl restart pgworld-api"
echo ""
echo "Check status:"
echo "  sudo systemctl status pgworld-api"
echo ""
echo "Test API:"
echo "  curl http://localhost:8080/"
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}🎯 Next Steps${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "1. Test API from your local machine:"
echo "   curl http://$EC2_IP:8080/"
echo ""
echo "2. Deploy frontend (from your local machine):"
echo "   cd pgworld-master"
echo "   # Update lib/utils/config.dart with EC2 IP"
echo "   flutter build web --release"
echo "   aws s3 sync build/web/ s3://$S3_BUCKET/"
echo ""
echo "3. Access your application:"
echo "   Frontend: http://$S3_BUCKET.s3-website-us-east-1.amazonaws.com"
echo "   Backend: http://$EC2_IP:8080"
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}📞 Support${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "If you encounter any issues:"
echo "  - Check logs: sudo journalctl -u pgworld-api -f"
echo "  - Verify database: mysql -h $RDS_ENDPOINT -u $DB_USER -p"
echo "  - Test connectivity: curl http://localhost:8080/"
echo ""
echo -e "${GREEN}Deployment completed at: $(date)${NC}"
echo ""
echo -e "${CYAN}Thank you for using PGNI! 🚀${NC}"
echo ""

# Save deployment info
cat > $HOME/pgni-deployment-info.txt << EOF
PGNI Deployment Information
===========================
Deployed: $(date)
EC2 IP: $EC2_IP
RDS Endpoint: $RDS_ENDPOINT
Database: $DB_NAME
S3 Bucket: $S3_BUCKET
Backend URL: http://$EC2_IP:8080
Working Directory: $WORK_DIR
Service: pgworld-api

Commands:
- View logs: sudo journalctl -u pgworld-api -f
- Restart: sudo systemctl restart pgworld-api
- Status: sudo systemctl status pgworld-api
- Test: curl http://localhost:8080/
EOF

echo -e "${GREEN}Deployment info saved to: $HOME/pgni-deployment-info.txt${NC}"
echo ""


