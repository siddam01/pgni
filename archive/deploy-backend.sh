#!/bin/bash

# PGNI Backend Deployment Script
# Usage: ./deploy-backend.sh <ec2-ip> <key-file>

set -e

echo "🚀 PGNI Backend Deployment Script"
echo "=================================="

# Check arguments
if [ "$#" -lt 2 ]; then
    echo "Usage: ./deploy-backend.sh <EC2_IP> <KEY_FILE>"
    echo "Example: ./deploy-backend.sh 54.227.101.30 pgworld-key.pem"
    exit 1
fi

EC2_IP=$1
KEY_FILE=$2

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo ""
echo "${YELLOW}Step 1: Building Backend...${NC}"
cd pgworld-api-master

# Build for Linux
echo "Building Go binary for Linux..."
GOOS=linux GOARCH=amd64 go build -o pgworld-api main.go

if [ $? -eq 0 ]; then
    echo "${GREEN}✅ Build successful${NC}"
else
    echo "${RED}❌ Build failed${NC}"
    exit 1
fi

echo ""
echo "${YELLOW}Step 2: Preparing key file...${NC}"
chmod 400 "../$KEY_FILE"

echo ""
echo "${YELLOW}Step 3: Creating directory on EC2...${NC}"
ssh -i "../$KEY_FILE" -o StrictHostKeyChecking=no ec2-user@$EC2_IP "mkdir -p ~/pgworld-api"

echo ""
echo "${YELLOW}Step 4: Uploading files to EC2...${NC}"
echo "Uploading binary..."
scp -i "../$KEY_FILE" pgworld-api ec2-user@$EC2_IP:~/pgworld-api/

echo "Uploading .env..."
if [ -f ".env" ]; then
    scp -i "../$KEY_FILE" .env ec2-user@$EC2_IP:~/pgworld-api/
else
    echo "${YELLOW}⚠️  No .env file found. You'll need to create one on EC2.${NC}"
fi

echo "Uploading uploads directory..."
if [ -d "uploads" ]; then
    scp -i "../$KEY_FILE" -r uploads/ ec2-user@$EC2_IP:~/pgworld-api/
fi

echo ""
echo "${YELLOW}Step 5: Setting up service on EC2...${NC}"

ssh -i "../$KEY_FILE" ec2-user@$EC2_IP << 'ENDSSH'
cd ~/pgworld-api
chmod +x pgworld-api

# Create systemd service
sudo tee /etc/systemd/system/pgworld-api.service > /dev/null << 'EOF'
[Unit]
Description=PG World API Server
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/home/ec2-user/pgworld-api
ExecStart=/home/ec2-user/pgworld-api/pgworld-api
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd, restart service
sudo systemctl daemon-reload
sudo systemctl stop pgworld-api 2>/dev/null || true
sudo systemctl start pgworld-api
sudo systemctl enable pgworld-api

echo "Waiting for service to start..."
sleep 3

# Check status
if sudo systemctl is-active --quiet pgworld-api; then
    echo "✅ Service started successfully"
    sudo systemctl status pgworld-api --no-pager
else
    echo "❌ Service failed to start"
    echo "Logs:"
    sudo journalctl -u pgworld-api --since "1 minute ago" --no-pager
    exit 1
fi
ENDSSH

if [ $? -eq 0 ]; then
    echo ""
    echo "${GREEN}✅ Backend deployed successfully!${NC}"
    echo ""
    echo "API URL: http://$EC2_IP:8080"
    echo ""
    echo "To view logs:"
    echo "  ssh -i $KEY_FILE ec2-user@$EC2_IP 'sudo journalctl -u pgworld-api -f'"
    echo ""
    echo "To check status:"
    echo "  ssh -i $KEY_FILE ec2-user@$EC2_IP 'sudo systemctl status pgworld-api'"
    echo ""
    echo "Testing API..."
    sleep 2
    curl -s http://$EC2_IP:8080/ && echo "" || echo "${YELLOW}⚠️  API not responding yet. Check logs.${NC}"
else
    echo "${RED}❌ Deployment failed${NC}"
    exit 1
fi

cd ..

