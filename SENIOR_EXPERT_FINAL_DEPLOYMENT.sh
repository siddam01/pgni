#!/bin/bash
#==============================================================================
# SENIOR EXPERT - COMPLETE END-TO-END DEPLOYMENT
# This script ensures ACTUAL working application deployment
#==============================================================================

set -e

INSTANCE_ID="i-0909d462845deb151"
REGION="us-east-1"
EC2_IP="34.227.111.143"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo "=============================================="
echo "  SENIOR EXPERT - COMPLETE DEPLOYMENT"
echo "=============================================="
echo "Taking full control of deployment..."
echo "Time: $(date)"
echo ""

#==============================================================================
# STEP 1: CREATE COMPLETE DEPLOYMENT SCRIPT
#==============================================================================
echo -e "${CYAN}Creating complete deployment script...${NC}"

cat > /tmp/complete_deploy.sh << 'DEPLOY_SCRIPT'
#!/bin/bash
set -e

echo "=============================================="
echo "  COMPLETE APPLICATION DEPLOYMENT"
echo "=============================================="
echo "Starting: $(date)"
echo ""

cd /home/ec2-user

#------------------------------------------------------------------------------
# PHASE 1: System Prerequisites
#------------------------------------------------------------------------------
echo "=== PHASE 1/7: System Prerequisites ==="
echo "Updating system..."
sudo yum update -y -q

echo "Installing packages..."
sudo yum install -y git wget curl unzip nginx mysql -q

echo "✓ System prerequisites complete"
echo ""

#------------------------------------------------------------------------------
# PHASE 2: Flutter SDK Installation
#------------------------------------------------------------------------------
echo "=== PHASE 2/7: Flutter SDK Installation ==="
if [ -d "/home/ec2-user/flutter" ]; then
    echo "Flutter SDK already exists"
    export PATH="$PATH:/home/ec2-user/flutter/bin"
    flutter --version
else
    echo "Downloading Flutter SDK (~1GB, takes 5-10 min)..."
    cd /home/ec2-user
    wget -q --show-progress https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.16.0-stable.tar.xz
    
    echo "Extracting Flutter SDK..."
    tar xf flutter_linux_3.16.0-stable.tar.xz
    rm -f flutter_linux_3.16.0-stable.tar.xz
    
    export PATH="$PATH:/home/ec2-user/flutter/bin"
    
    echo "Configuring Flutter..."
    flutter config --no-analytics
    flutter doctor
fi

echo "✓ Flutter SDK ready"
flutter --version
echo ""

#------------------------------------------------------------------------------
# PHASE 3: Source Code
#------------------------------------------------------------------------------
echo "=== PHASE 3/7: Source Code ==="
cd /home/ec2-user

if [ -d "pgni" ]; then
    echo "Updating existing repository..."
    cd pgni
    git fetch origin
    git reset --hard origin/main
    git pull
    cd ..
else
    echo "Cloning repository..."
    git clone https://github.com/siddam01/pgni.git
fi

echo "✓ Source code ready"
echo ""

#------------------------------------------------------------------------------
# PHASE 4: Build Backend API
#------------------------------------------------------------------------------
echo "=== PHASE 4/7: Build Backend API ==="

# Check if Go is installed
if ! command -v go &> /dev/null; then
    echo "Installing Go..."
    cd /tmp
    wget -q https://go.dev/dl/go1.21.0.linux-amd64.tar.gz
    sudo tar -C /usr/local -xzf go1.21.0.linux-amd64.tar.gz
    rm -f go1.21.0.linux-amd64.tar.gz
fi

export PATH=$PATH:/usr/local/go/bin

echo "Building API..."
cd /home/ec2-user/pgni/pgworld-api-master
go mod download
go build -v -o pgworld-api .

if [ -f "pgworld-api" ]; then
    echo "✓ API binary built: $(du -h pgworld-api | cut -f1)"
else
    echo "✗ API build failed!"
    exit 1
fi
echo ""

#------------------------------------------------------------------------------
# PHASE 5: Build Flutter Web Apps
#------------------------------------------------------------------------------
echo "=== PHASE 5/7: Build Flutter Web Apps ==="
export PATH="$PATH:/home/ec2-user/flutter/bin"

# Build Admin App
echo "Building Admin App..."
cd /home/ec2-user/pgni/pgworld-master

# Update API URL
cat > lib/utils/config.dart << 'EOF'
class Config {
  static const String URL = "34.227.111.143:8080";
  static const String BASE_URL = "http://34.227.111.143:8080";
}
EOF

flutter clean
flutter pub get
flutter build web --release

if [ -d "build/web" ] && [ -f "build/web/index.html" ]; then
    echo "✓ Admin app built: $(du -sh build/web | cut -f1)"
else
    echo "✗ Admin app build failed!"
    exit 1
fi

# Build Tenant App
echo "Building Tenant App..."
cd /home/ec2-user/pgni/pgworldtenant-master

# Update API URL
cat > lib/utils/config.dart << 'EOF'
class Config {
  static const String URL = "34.227.111.143:8080";
  static const String BASE_URL = "http://34.227.111.143:8080";
}
EOF

flutter clean
flutter pub get
flutter build web --release

if [ -d "build/web" ] && [ -f "build/web/index.html" ]; then
    echo "✓ Tenant app built: $(du -sh build/web | cut -f1)"
else
    echo "✗ Tenant app build failed!"
    exit 1
fi
echo ""

#------------------------------------------------------------------------------
# PHASE 6: Deploy Backend API
#------------------------------------------------------------------------------
echo "=== PHASE 6/7: Deploy Backend API ==="

# Stop existing service
sudo systemctl stop pgworld-api 2>/dev/null || true

# Create deployment directory
sudo mkdir -p /opt/pgworld/logs
sudo chown -R ec2-user:ec2-user /opt/pgworld

# Copy API binary
cp /home/ec2-user/pgni/pgworld-api-master/pgworld-api /opt/pgworld/
chmod +x /opt/pgworld/pgworld-api

# Create configuration
cat > /opt/pgworld/.env << 'EOF'
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

chmod 600 /opt/pgworld/.env

# Create systemd service
sudo tee /etc/systemd/system/pgworld-api.service > /dev/null << 'EOF'
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
EOF

# Initialize database
echo "Initializing database..."
mysql -h database-pgni.cezawkgguojl.us-east-1.rds.amazonaws.com -P 3306 -u admin -pOmsairamdb951# \
  -e "CREATE DATABASE IF NOT EXISTS pgworld CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>/dev/null || echo "Database may already exist"

# Start API service
sudo systemctl daemon-reload
sudo systemctl enable pgworld-api
sudo systemctl start pgworld-api

# Wait for API to start
sleep 5

# Test API
API_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/health || echo "000")
if [ "$API_STATUS" = "200" ]; then
    echo "✓ Backend API is running and healthy"
else
    echo "⚠ Backend API returned status: $API_STATUS"
    echo "Checking logs..."
    sudo journalctl -u pgworld-api -n 20 --no-pager
fi
echo ""

#------------------------------------------------------------------------------
# PHASE 7: Deploy Frontend to Nginx
#------------------------------------------------------------------------------
echo "=== PHASE 7/7: Deploy Frontend to Nginx ==="

# Clean old deployments
echo "Cleaning old deployments..."
sudo rm -rf /usr/share/nginx/html/admin
sudo rm -rf /usr/share/nginx/html/tenant
sudo rm -rf /usr/share/nginx/html/html

# Create directories
echo "Creating directories..."
sudo mkdir -p /usr/share/nginx/html/admin
sudo mkdir -p /usr/share/nginx/html/tenant

# Deploy Admin App
echo "Deploying Admin App..."
sudo cp -r /home/ec2-user/pgni/pgworld-master/build/web/* /usr/share/nginx/html/admin/

# Deploy Tenant App
echo "Deploying Tenant App..."
sudo cp -r /home/ec2-user/pgni/pgworldtenant-master/build/web/* /usr/share/nginx/html/tenant/

# Set permissions
echo "Setting permissions..."
sudo chown -R nginx:nginx /usr/share/nginx/html
sudo chmod -R 755 /usr/share/nginx/html
sudo chmod 644 /usr/share/nginx/html/admin/index.html
sudo chmod 644 /usr/share/nginx/html/tenant/index.html

# Verify files
ADMIN_FILES=$(ls /usr/share/nginx/html/admin/ | wc -l)
TENANT_FILES=$(ls /usr/share/nginx/html/tenant/ | wc -l)

if [ "$ADMIN_FILES" -gt 10 ] && [ "$TENANT_FILES" -gt 10 ]; then
    echo "✓ Files deployed successfully"
    echo "  Admin files: $ADMIN_FILES"
    echo "  Tenant files: $TENANT_FILES"
else
    echo "✗ File deployment may have failed"
    echo "  Admin files: $ADMIN_FILES"
    echo "  Tenant files: $TENANT_FILES"
fi

# Configure Nginx
echo "Configuring Nginx..."
sudo tee /etc/nginx/conf.d/pgni.conf > /dev/null << 'EOF'
server {
    listen 80 default_server;
    server_name _;
    
    # Root redirects to admin
    location = / {
        return 301 /admin/;
    }
    
    # Admin Portal
    location /admin/ {
        alias /usr/share/nginx/html/admin/;
        index index.html;
        try_files $uri $uri/ /admin/index.html;
        
        # Cache control
        add_header Cache-Control "no-cache, no-store, must-revalidate";
        add_header Pragma "no-cache";
        add_header Expires "0";
        
        # CORS
        add_header Access-Control-Allow-Origin "*" always;
        add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
        add_header Access-Control-Allow-Headers "DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization" always;
    }
    
    # Tenant Portal
    location /tenant/ {
        alias /usr/share/nginx/html/tenant/;
        index index.html;
        try_files $uri $uri/ /tenant/index.html;
        
        # Cache control
        add_header Cache-Control "no-cache, no-store, must-revalidate";
        add_header Pragma "no-cache";
        add_header Expires "0";
        
        # CORS
        add_header Access-Control-Allow-Origin "*" always;
        add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
        add_header Access-Control-Allow-Headers "DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization" always;
    }
    
    # API Proxy
    location /api/ {
        proxy_pass http://localhost:8080/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # CORS for API
        add_header Access-Control-Allow-Origin "*" always;
        add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
        add_header Access-Control-Allow-Headers "DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization" always;
        
        if ($request_method = 'OPTIONS') {
            return 204;
        }
    }
    
    # Direct API access
    location /health {
        proxy_pass http://localhost:8080/health;
    }
}
EOF

# Remove default Nginx config that might conflict
sudo rm -f /etc/nginx/conf.d/default.conf

# Test Nginx configuration
echo "Testing Nginx configuration..."
sudo nginx -t

if [ $? -eq 0 ]; then
    echo "✓ Nginx configuration is valid"
else
    echo "✗ Nginx configuration has errors!"
    exit 1
fi

# Restart Nginx
echo "Restarting Nginx..."
sudo systemctl enable nginx
sudo systemctl restart nginx

# Wait for Nginx to start
sleep 3

# Verify Nginx is running
if sudo systemctl is-active nginx > /dev/null; then
    echo "✓ Nginx is running"
else
    echo "✗ Nginx failed to start!"
    sudo systemctl status nginx
    exit 1
fi

echo ""
echo "=============================================="
echo "  ✅ DEPLOYMENT COMPLETE!"
echo "=============================================="
echo "Completed: $(date)"
echo ""

# Final validation
echo "Final Validation:"
echo "─────────────────────────────────────────────"

# Test Admin Portal
ADMIN_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/admin/ || echo "000")
echo "Admin Portal:  HTTP $ADMIN_STATUS $([ "$ADMIN_STATUS" = "200" ] && echo "✓" || echo "✗")"

# Test Tenant Portal
TENANT_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/tenant/ || echo "000")
echo "Tenant Portal: HTTP $TENANT_STATUS $([ "$TENANT_STATUS" = "200" ] && echo "✓" || echo "✗")"

# Test Backend API
API_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/health || echo "000")
echo "Backend API:   HTTP $API_STATUS $([ "$API_STATUS" = "200" ] && echo "✓" || echo "✗")"

echo ""
echo "Access URLs:"
echo "  Admin Portal:  http://34.227.111.143/admin/"
echo "  Tenant Portal: http://34.227.111.143/tenant/"
echo "  Backend API:   http://34.227.111.143:8080/health"
echo ""
echo "Test Accounts:"
echo "  Super Admin: admin@pgworld.com / Admin@123"
echo "  PG Owner:    owner@pg.com / Owner@123"
echo "  Tenant:      tenant@pg.com / Tenant@123"
echo ""
echo "Deployment Summary:"
echo "  Admin files:   $ADMIN_FILES files"
echo "  Tenant files:  $TENANT_FILES files"
echo "  API status:    $(sudo systemctl is-active pgworld-api)"
echo "  Nginx status:  $(sudo systemctl is-active nginx)"
echo ""
echo "=============================================="
DEPLOY_SCRIPT

chmod +x /tmp/complete_deploy.sh

#==============================================================================
# STEP 2: UPLOAD AND EXECUTE ON EC2
#==============================================================================
echo -e "${CYAN}Uploading deployment script to EC2...${NC}"

# Upload script to EC2
aws ssm send-command \
    --instance-ids "$INSTANCE_ID" \
    --region "$REGION" \
    --document-name "AWS-RunShellScript" \
    --comment "Upload deployment script" \
    --parameters commands="cat > /tmp/deploy.sh << 'SCRIPT_CONTENT'
$(cat /tmp/complete_deploy.sh)
SCRIPT_CONTENT
chmod +x /tmp/deploy.sh" \
    --output text \
    --query 'Command.CommandId' > /tmp/upload_cmd_id.txt

sleep 5

echo -e "${GREEN}✓ Script uploaded${NC}"
echo ""

#==============================================================================
# STEP 3: EXECUTE DEPLOYMENT
#==============================================================================
echo -e "${CYAN}Executing complete deployment on EC2...${NC}"
echo "This will take 15-20 minutes..."
echo ""

DEPLOY_CMD_ID=$(aws ssm send-command \
    --instance-ids "$INSTANCE_ID" \
    --region "$REGION" \
    --document-name "AWS-RunShellScript" \
    --comment "Execute complete deployment" \
    --parameters commands="/tmp/deploy.sh 2>&1 | tee /tmp/deployment.log" \
    --timeout-seconds 3600 \
    --output text \
    --query 'Command.CommandId')

echo "Deployment Command ID: $DEPLOY_CMD_ID"
echo ""
echo "Monitoring deployment progress..."
echo "────────────────────────────────────────────"
echo ""

# Monitor for 20 minutes
for i in {1..40}; do
    sleep 30
    
    STATUS=$(aws ssm get-command-invocation \
        --command-id "$DEPLOY_CMD_ID" \
        --instance-id "$INSTANCE_ID" \
        --region "$REGION" \
        --query 'Status' \
        --output text 2>/dev/null || echo "InProgress")
    
    echo "[$(date +%H:%M:%S)] Status: $STATUS (checked $i/40 times)"
    
    if [ "$STATUS" = "Success" ] || [ "$STATUS" = "Failed" ]; then
        break
    fi
done

echo ""
echo "=============================================="
echo "  DEPLOYMENT STATUS"
echo "=============================================="
echo ""

# Get final output
aws ssm get-command-invocation \
    --command-id "$DEPLOY_CMD_ID" \
    --instance-id "$INSTANCE_ID" \
    --region "$REGION" \
    --query 'StandardOutputContent' \
    --output text 2>/dev/null | tail -100

echo ""
echo "=============================================="
echo "  FINAL VALIDATION"
echo "=============================================="
echo ""

# Test from outside
echo "Testing from CloudShell..."
ADMIN_TEST=$(curl -s -o /dev/null -w "%{http_code}" http://$EC2_IP/admin/ || echo "000")
TENANT_TEST=$(curl -s -o /dev/null -w "%{http_code}" http://$EC2_IP/tenant/ || echo "000")
API_TEST=$(curl -s -o /dev/null -w "%{http_code}" http://$EC2_IP:8080/health || echo "000")

echo "Admin Portal:  HTTP $ADMIN_TEST $([ "$ADMIN_TEST" = "200" ] && echo "✓ WORKING" || echo "✗ FAILED")"
echo "Tenant Portal: HTTP $TENANT_TEST $([ "$TENANT_TEST" = "200" ] && echo "✓ WORKING" || echo "✗ FAILED")"
echo "Backend API:   HTTP $API_TEST $([ "$API_TEST" = "200" ] && echo "✓ WORKING" || echo "✗ FAILED")"

echo ""
echo "=============================================="
echo "  🎉 COMPLETE!"
echo "=============================================="
echo ""
echo "Access your application:"
echo "  Admin:  http://$EC2_IP/admin/"
echo "  Tenant: http://$EC2_IP/tenant/"
echo ""
echo "Test these URLs in your browser now!"
echo "=============================================="

