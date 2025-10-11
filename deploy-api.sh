#!/bin/bash
# PGNi API Deployment Script
# Run this on EC2 instance after SSH connection

set -e  # Exit on error

echo "========================================"
echo "  PGNi API Deployment Script"
echo "========================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if running on EC2
if [ ! -f /etc/system-release ]; then
    echo -e "${RED}Error: This script should be run on EC2 instance${NC}"
    exit 1
fi

echo -e "${YELLOW}Step 1: Cloning repository...${NC}"
if [ -d "pgni" ]; then
    echo "Repository already exists, pulling latest..."
    cd pgni
    git pull
    cd ..
else
    git clone https://github.com/siddam01/pgni.git
fi

echo ""
echo -e "${GREEN}✓ Repository ready${NC}"
echo ""

echo -e "${YELLOW}Step 2: Setting up environment...${NC}"
sudo mkdir -p /opt/pgworld

if [ -f ~/preprod.env ]; then
    sudo cp ~/preprod.env /opt/pgworld/.env
    echo -e "${GREEN}✓ Environment file copied${NC}"
else
    echo -e "${RED}Error: preprod.env not found in home directory${NC}"
    echo "Please upload preprod.env to EC2 first:"
    echo "  scp -i pgni-preprod-key.pem preprod.env ec2-user@34.227.111.143:~/"
    exit 1
fi

echo ""
echo -e "${YELLOW}Step 3: Building API...${NC}"
cd pgni/pgworld-api-master

# Build the application
/usr/local/go/bin/go build -o /opt/pgworld/pgworld-api .

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ API built successfully${NC}"
else
    echo -e "${RED}Error: Build failed${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}Step 4: Starting API service...${NC}"
sudo systemctl daemon-reload
sudo systemctl start pgworld-api
sudo systemctl enable pgworld-api

# Wait a moment for service to start
sleep 3

# Check status
if systemctl is-active --quiet pgworld-api; then
    echo -e "${GREEN}✓ API service started successfully${NC}"
else
    echo -e "${RED}Error: Service failed to start${NC}"
    echo "Check logs with: sudo journalctl -u pgworld-api -n 50"
    exit 1
fi

echo ""
echo -e "${YELLOW}Step 5: Testing API...${NC}"

# Test health endpoint
HEALTH_CHECK=$(curl -s http://localhost:8080/health || echo "failed")

if [[ $HEALTH_CHECK == *"healthy"* ]] || [[ $HEALTH_CHECK == *"ok"* ]]; then
    echo -e "${GREEN}✓ API health check passed${NC}"
else
    echo -e "${YELLOW}⚠ Health check returned: $HEALTH_CHECK${NC}"
    echo "This might be normal if database is not initialized yet"
fi

echo ""
echo "========================================"
echo -e "${GREEN}  Deployment Complete!${NC}"
echo "========================================"
echo ""
echo "API is running on:"
echo "  • Local: http://localhost:8080"
echo "  • Public: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8080"
echo ""
echo "Useful commands:"
echo "  • Check status: sudo systemctl status pgworld-api"
echo "  • View logs: sudo journalctl -u pgworld-api -f"
echo "  • Restart: sudo systemctl restart pgworld-api"
echo "  • Stop: sudo systemctl stop pgworld-api"
echo ""
echo "Next steps:"
echo "  1. Initialize database (see DEPLOY_NOW.md)"
echo "  2. Test API endpoints"
echo "  3. Update Flutter apps with API URL"
echo ""

