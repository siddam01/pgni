#!/bin/bash

#############################################################
# Fix Database Connection and Deploy
# Handles special characters in passwords properly
#############################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

clear

echo -e "${CYAN}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║   Database Connection Fix & Deployment                   ║
╚═══════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Load config
CONFIG_FILE="$HOME/.pgni-config"
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
    echo -e "${GREEN}✅ Configuration loaded${NC}"
    echo "RDS Endpoint: $RDS_ENDPOINT"
    echo "Database User: $DB_USER"
    echo "Database Name: $DB_NAME"
    echo ""
else
    echo -e "${RED}❌ Config file not found at $CONFIG_FILE${NC}"
    echo "Please run the main deployment script first."
    exit 1
fi

# Get password securely
echo -e "${YELLOW}⚠️  Important: Enter password carefully${NC}"
echo "Password will not be visible while typing (this is normal)"
echo ""
read -sp "Enter MySQL password for user '$DB_USER': " DB_PASSWORD
echo ""
echo ""

if [ -z "$DB_PASSWORD" ]; then
    echo -e "${RED}❌ Password cannot be empty!${NC}"
    exit 1
fi

# Save password to a temporary credentials file (more secure than command line)
MYSQL_CREDS="$HOME/.mysql_credentials_temp"
cat > "$MYSQL_CREDS" << EOF
[client]
host=$RDS_ENDPOINT
user=$DB_USER
password=$DB_PASSWORD
database=$DB_NAME
EOF

chmod 600 "$MYSQL_CREDS"

echo -e "${BLUE}========================================${NC}"
echo -e "${YELLOW}Step 1: Testing Database Connection${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Test connection using credentials file
if mysql --defaults-file="$MYSQL_CREDS" -e "SELECT 1 AS ConnectionTest;" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Database connection successful!${NC}"
    echo ""
else
    echo -e "${RED}❌ Database connection failed!${NC}"
    echo ""
    echo "Possible issues:"
    echo "1. ❌ Incorrect password"
    echo "2. ❌ RDS endpoint wrong: $RDS_ENDPOINT"
    echo "3. ❌ User '$DB_USER' doesn't exist or lacks permissions"
    echo "4. ❌ RDS security group doesn't allow connections from this EC2 instance"
    echo ""
    echo "To check RDS security group:"
    echo "  - Go to AWS Console → RDS → Your Database → Connectivity & security"
    echo "  - Check 'VPC security groups'"
    echo "  - Ensure inbound rules allow MySQL (port 3306) from EC2 security group"
    echo ""
    
    # Show detailed error
    echo "Detailed error:"
    mysql --defaults-file="$MYSQL_CREDS" -e "SELECT 1;" 2>&1
    
    # Cleanup
    rm -f "$MYSQL_CREDS"
    exit 1
fi

echo -e "${BLUE}========================================${NC}"
echo -e "${YELLOW}Step 2: Creating Database${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

mysql --defaults-file="$MYSQL_CREDS" -e "CREATE DATABASE IF NOT EXISTS $DB_NAME;" 2>&1

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Database '$DB_NAME' ready${NC}"
    echo ""
else
    echo -e "${RED}❌ Failed to create database${NC}"
    rm -f "$MYSQL_CREDS"
    exit 1
fi

echo -e "${BLUE}========================================${NC}"
echo -e "${YELLOW}Step 3: Checking/Updating Code${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Ensure we have the latest setup file
WORK_DIR="$HOME/pgni-deployment"
cd "$WORK_DIR" || exit 1

if [ ! -f "pgworld-api-master/setup-database-complete.sql" ]; then
    echo "Downloading latest setup file..."
    
    # Clean and re-clone
    rm -rf temp-repo
    git clone https://github.com/siddam01/pgni.git temp-repo
    
    if [ -d "temp-repo/pgworld-api-master" ]; then
        cp temp-repo/pgworld-api-master/setup-database-complete.sql pgworld-api-master/
        echo -e "${GREEN}✅ Latest setup file downloaded${NC}"
    else
        echo -e "${RED}❌ Failed to get setup file${NC}"
        rm -f "$MYSQL_CREDS"
        exit 1
    fi
    
    rm -rf temp-repo
else
    echo -e "${GREEN}✅ Setup file found${NC}"
fi

echo ""

echo -e "${BLUE}========================================${NC}"
echo -e "${YELLOW}Step 4: Running Database Setup${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

echo "This will create:"
echo "  - 11 base tables (admins, hostels, rooms, users, etc.)"
echo "  - RBAC columns and permissions table"
echo "  - Demo data (1 admin, 1 hostel, 4 rooms, 1 tenant)"
echo ""

# Run the complete setup
mysql --defaults-file="$MYSQL_CREDS" < pgworld-api-master/setup-database-complete.sql

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ Database setup complete!${NC}"
    echo ""
else
    echo -e "${RED}❌ Database setup failed!${NC}"
    rm -f "$MYSQL_CREDS"
    exit 1
fi

echo -e "${BLUE}========================================${NC}"
echo -e "${YELLOW}Step 5: Building Backend${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

cd pgworld-api-master

# Create .env file
echo "Creating .env file..."
cat > .env << ENVEOF
DB_HOST=$RDS_ENDPOINT
DB_PORT=3306
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASSWORD
DB_NAME=$DB_NAME
PORT=8080
CONNECTION_POOL=10
ENV=production
S3_BUCKET=${S3_BUCKET}-uploads
AWS_REGION=us-east-1
ENVEOF

chmod 600 .env

echo -e "${GREEN}✅ .env file created${NC}"
echo ""

# Build
echo "Building Go application..."
/usr/local/go/bin/go mod download
/usr/local/go/bin/go build -o pgworld-api main.go

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Backend build successful${NC}"
else
    echo -e "${RED}❌ Backend build failed${NC}"
    rm -f "$MYSQL_CREDS"
    exit 1
fi

echo ""

echo -e "${BLUE}========================================${NC}"
echo -e "${YELLOW}Step 6: Starting Backend Service${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Create systemd service if it doesn't exist
if [ ! -f /etc/systemd/system/pgworld-api.service ]; then
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
    
    echo -e "${GREEN}✅ Service file created${NC}"
fi

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
    echo ""
    echo "Checking logs..."
    sudo journalctl -u pgworld-api --since "1 minute ago" --no-pager | tail -20
    rm -f "$MYSQL_CREDS"
    exit 1
fi

echo ""

echo -e "${BLUE}========================================${NC}"
echo -e "${YELLOW}Step 7: Testing Deployment${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

sleep 2

RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/ || echo "000")

if [ "$RESPONSE" = "200" ]; then
    echo -e "${GREEN}✅ Backend API is responding!${NC}"
    echo ""
    
    # Get EC2 public IP
    EC2_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "N/A")
    
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                                                           ║${NC}"
    echo -e "${CYAN}║         ${GREEN}🎉 DEPLOYMENT SUCCESSFUL! 🎉${CYAN}                     ║${NC}"
    echo -e "${CYAN}║                                                           ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${GREEN}Backend API URL:${NC} http://$EC2_IP:8080"
    echo -e "${GREEN}Service Status:${NC} Running"
    echo ""
    echo -e "${BLUE}Demo Login Credentials:${NC}"
    echo "  Username: admin"
    echo "  Password: admin123"
    echo ""
    echo -e "${BLUE}Useful Commands:${NC}"
    echo "  View logs: sudo journalctl -u pgworld-api -f"
    echo "  Restart: sudo systemctl restart pgworld-api"
    echo "  Status: sudo systemctl status pgworld-api"
    echo ""
else
    echo -e "${YELLOW}⚠️  Backend API returned status: $RESPONSE${NC}"
    echo "Checking service status..."
    sudo systemctl status pgworld-api --no-pager
fi

# Cleanup credentials file
rm -f "$MYSQL_CREDS"

echo ""
echo -e "${GREEN}Deployment completed at: $(date)${NC}"
echo ""

