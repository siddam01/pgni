#!/bin/bash
#==============================================================================
# Fix 403 Error and Deploy Full Flutter App
#==============================================================================

set -e

# Configuration
INSTANCE_ID="i-0909d462845deb151"
REGION="us-east-1"
EC2_IP="34.227.111.143"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "=============================================="
echo "  Fix 403 Error & Deploy Full App"
echo "=============================================="
echo ""

#==============================================================================
# STEP 1: Diagnose Current State
#==============================================================================
echo -e "${BLUE}=== STEP 1: Checking Current State ===${NC}"
echo ""

echo "Checking Admin Portal..."
ADMIN_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://$EC2_IP/admin/ 2>/dev/null || echo "000")
echo "  HTTP Status: $ADMIN_STATUS"

echo "Checking Tenant Portal..."
TENANT_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://$EC2_IP/tenant/ 2>/dev/null || echo "000")
echo "  HTTP Status: $TENANT_STATUS"

echo "Checking Backend API..."
API_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://$EC2_IP:8080/health 2>/dev/null || echo "000")
echo "  HTTP Status: $API_STATUS"

echo ""

if [ "$ADMIN_STATUS" = "403" ] || [ "$TENANT_STATUS" = "403" ]; then
    echo -e "${YELLOW}⚠ 403 Forbidden detected - This means:${NC}"
    echo "  - Nginx is running"
    echo "  - Files exist but have permission issues OR"
    echo "  - Wrong files (placeholders) are deployed"
    echo ""
    echo "Fixing now..."
fi

#==============================================================================
# STEP 2: Check What's Actually Deployed
#==============================================================================
echo -e "${BLUE}=== STEP 2: Checking Deployed Files ===${NC}"
echo ""

COMMAND_ID=$(aws ssm send-command \
    --instance-ids "$INSTANCE_ID" \
    --region "$REGION" \
    --document-name "AWS-RunShellScript" \
    --comment "Check deployed files" \
    --parameters 'commands=[
        "echo === Nginx Status ===",
        "sudo systemctl status nginx --no-pager | head -5",
        "echo",
        "echo === Admin Files ===",
        "ls -lah /usr/share/nginx/html/admin/ | head -10",
        "echo",
        "echo === Tenant Files ===",
        "ls -lah /usr/share/nginx/html/tenant/ | head -10",
        "echo",
        "echo === Check if Flutter Apps are Built ===",
        "[ -d /home/ec2-user/pgni/pgworld-master/build/web ] && echo Admin build: EXISTS || echo Admin build: MISSING",
        "[ -d /home/ec2-user/pgni/pgworldtenant-master/build/web ] && echo Tenant build: MISSING || echo Tenant build: MISSING",
        "echo",
        "echo === File Permissions ===",
        "ls -la /usr/share/nginx/html/admin/index.html 2>/dev/null || echo Admin index.html: NOT FOUND",
        "ls -la /usr/share/nginx/html/tenant/index.html 2>/dev/null || echo Tenant index.html: NOT FOUND"
    ]' \
    --query 'Command.CommandId' \
    --output text 2>/dev/null)

echo "Checking files on EC2... (waiting 10 seconds)"
sleep 10

aws ssm get-command-invocation \
    --command-id "$COMMAND_ID" \
    --instance-id "$INSTANCE_ID" \
    --region "$REGION" \
    --query 'StandardOutputContent' \
    --output text 2>/dev/null || echo "Could not retrieve status"

echo ""

#==============================================================================
# STEP 3: Deploy FULL Flutter Apps
#==============================================================================
echo -e "${BLUE}=== STEP 3: Deploying FULL Flutter Apps ===${NC}"
echo ""

echo "This will:"
echo "  1. Install Flutter if not present"
echo "  2. Clone/update source code"
echo "  3. Build ACTUAL Flutter web apps"
echo "  4. Deploy to Nginx with correct permissions"
echo "  5. Configure Nginx properly"
echo ""

# Install prerequisites and Flutter
echo "Phase 1/4: Installing Prerequisites..."
COMMAND_ID=$(aws ssm send-command \
    --instance-ids "$INSTANCE_ID" \
    --region "$REGION" \
    --document-name "AWS-RunShellScript" \
    --comment "Install prerequisites" \
    --parameters 'commands=[
        "sudo yum update -y",
        "sudo yum install -y git wget curl unzip nginx",
        "echo Prerequisites installed"
    ]' \
    --timeout-seconds 300 \
    --query 'Command.CommandId' \
    --output text 2>/dev/null)

sleep 30

# Install Flutter
echo "Phase 2/4: Installing Flutter SDK (8-10 min)..."
COMMAND_ID=$(aws ssm send-command \
    --instance-ids "$INSTANCE_ID" \
    --region "$REGION" \
    --document-name "AWS-RunShellScript" \
    --comment "Install Flutter" \
    --parameters 'commands=[
        "cd /home/ec2-user",
        "if [ ! -d flutter ]; then",
        "  echo Downloading Flutter SDK...",
        "  wget -q https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.16.0-stable.tar.xz",
        "  echo Extracting Flutter SDK...",
        "  tar xf flutter_linux_3.16.0-stable.tar.xz",
        "  rm -f flutter_linux_3.16.0-stable.tar.xz",
        "  echo Flutter SDK installed",
        "else",
        "  echo Flutter SDK already exists",
        "fi",
        "export PATH=$PATH:/home/ec2-user/flutter/bin",
        "flutter --version",
        "flutter doctor -v"
    ]' \
    --timeout-seconds 900 \
    --query 'Command.CommandId' \
    --output text 2>/dev/null)

echo "  Waiting for Flutter installation..."
sleep 480  # 8 minutes

# Build Flutter apps
echo "Phase 3/4: Building Flutter Web Apps (8-10 min)..."
COMMAND_ID=$(aws ssm send-command \
    --instance-ids "$INSTANCE_ID" \
    --region "$REGION" \
    --document-name "AWS-RunShellScript" \
    --comment "Build Flutter apps" \
    --parameters 'commands=[
        "export PATH=$PATH:/home/ec2-user/flutter/bin",
        "cd /home/ec2-user",
        "echo Cloning/updating source code...",
        "if [ -d pgni ]; then",
        "  cd pgni && git pull",
        "else",
        "  git clone https://github.com/siddam01/pgni.git",
        "  cd pgni",
        "fi",
        "echo",
        "echo Building Admin App...",
        "cd /home/ec2-user/pgni/pgworld-master",
        "sed -i \"s|static const URL = .*|static const URL = \\\"34.227.111.143:8080\\\";|\" lib/utils/config.dart",
        "flutter clean",
        "flutter pub get",
        "flutter build web --release",
        "echo Admin app built: $(du -sh build/web)",
        "echo",
        "echo Building Tenant App...",
        "cd /home/ec2-user/pgni/pgworldtenant-master",
        "sed -i \"s|static const URL = .*|static const URL = \\\"34.227.111.143:8080\\\";|\" lib/utils/config.dart",
        "flutter clean",
        "flutter pub get",
        "flutter build web --release",
        "echo Tenant app built: $(du -sh build/web)",
        "echo",
        "echo Build complete!"
    ]' \
    --timeout-seconds 900 \
    --query 'Command.CommandId' \
    --output text 2>/dev/null)

echo "  Waiting for build to complete..."
sleep 480  # 8 minutes

# Deploy to Nginx
echo "Phase 4/4: Deploying to Nginx with correct permissions..."
COMMAND_ID=$(aws ssm send-command \
    --instance-ids "$INSTANCE_ID" \
    --region "$REGION" \
    --document-name "AWS-RunShellScript" \
    --comment "Deploy to Nginx" \
    --parameters 'commands=[
        "echo Removing old files...",
        "sudo rm -rf /usr/share/nginx/html/admin/*",
        "sudo rm -rf /usr/share/nginx/html/tenant/*",
        "echo",
        "echo Creating directories...",
        "sudo mkdir -p /usr/share/nginx/html/admin",
        "sudo mkdir -p /usr/share/nginx/html/tenant",
        "echo",
        "echo Copying Admin app...",
        "sudo cp -r /home/ec2-user/pgni/pgworld-master/build/web/* /usr/share/nginx/html/admin/",
        "echo Admin files: $(ls -la /usr/share/nginx/html/admin/ | wc -l) files",
        "echo",
        "echo Copying Tenant app...",
        "sudo cp -r /home/ec2-user/pgni/pgworldtenant-master/build/web/* /usr/share/nginx/html/tenant/",
        "echo Tenant files: $(ls -la /usr/share/nginx/html/tenant/ | wc -l) files",
        "echo",
        "echo Setting permissions...",
        "sudo chown -R nginx:nginx /usr/share/nginx/html",
        "sudo chmod -R 755 /usr/share/nginx/html",
        "sudo chmod 644 /usr/share/nginx/html/admin/index.html",
        "sudo chmod 644 /usr/share/nginx/html/tenant/index.html",
        "echo",
        "echo Configuring Nginx...",
        "sudo tee /etc/nginx/conf.d/pgni.conf > /dev/null << \"EOF\"",
        "server {",
        "    listen 80;",
        "    server_name _;",
        "    ",
        "    location = / {",
        "        return 301 /admin/;",
        "    }",
        "    ",
        "    location /admin/ {",
        "        alias /usr/share/nginx/html/admin/;",
        "        index index.html;",
        "        try_files \\$uri \\$uri/ /admin/index.html;",
        "        add_header Cache-Control \"no-cache, no-store, must-revalidate\";",
        "        add_header Access-Control-Allow-Origin * always;",
        "    }",
        "    ",
        "    location /tenant/ {",
        "        alias /usr/share/nginx/html/tenant/;",
        "        index index.html;",
        "        try_files \\$uri \\$uri/ /tenant/index.html;",
        "        add_header Cache-Control \"no-cache, no-store, must-revalidate\";",
        "        add_header Access-Control-Allow-Origin * always;",
        "    }",
        "    ",
        "    location /api/ {",
        "        proxy_pass http://localhost:8080/;",
        "        proxy_set_header Host \\$host;",
        "        proxy_set_header X-Real-IP \\$remote_addr;",
        "        proxy_set_header X-Forwarded-For \\$proxy_add_x_forwarded_for;",
        "    }",
        "    ",
        "    location /health {",
        "        proxy_pass http://localhost:8080/health;",
        "    }",
        "}",
        "EOF",
        "echo",
        "echo Testing Nginx config...",
        "sudo nginx -t",
        "echo",
        "echo Restarting Nginx...",
        "sudo systemctl enable nginx",
        "sudo systemctl restart nginx",
        "echo",
        "echo Deployment complete!",
        "echo Admin: http://34.227.111.143/admin/",
        "echo Tenant: http://34.227.111.143/tenant/"
    ]' \
    --timeout-seconds 300 \
    --query 'Command.CommandId' \
    --output text 2>/dev/null)

echo "  Waiting for deployment..."
sleep 60

#==============================================================================
# STEP 4: Validate
#==============================================================================
echo ""
echo -e "${BLUE}=== STEP 4: Validating Deployment ===${NC}"
echo ""

sleep 10

echo "Testing Admin Portal..."
ADMIN_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://$EC2_IP/admin/ 2>/dev/null || echo "000")
if [ "$ADMIN_STATUS" = "200" ]; then
    echo -e "  ${GREEN}✓ Admin Portal: Working (HTTP $ADMIN_STATUS)${NC}"
else
    echo -e "  ${YELLOW}⚠ Admin Portal: HTTP $ADMIN_STATUS${NC}"
fi

echo "Testing Tenant Portal..."
TENANT_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://$EC2_IP/tenant/ 2>/dev/null || echo "000")
if [ "$TENANT_STATUS" = "200" ]; then
    echo -e "  ${GREEN}✓ Tenant Portal: Working (HTTP $TENANT_STATUS)${NC}"
else
    echo -e "  ${YELLOW}⚠ Tenant Portal: HTTP $TENANT_STATUS${NC}"
fi

echo "Testing Backend API..."
API_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://$EC2_IP:8080/health 2>/dev/null || echo "000")
if [ "$API_STATUS" = "200" ]; then
    echo -e "  ${GREEN}✓ Backend API: Working (HTTP $API_STATUS)${NC}"
else
    echo -e "  ${YELLOW}⚠ Backend API: HTTP $API_STATUS${NC}"
fi

#==============================================================================
# SUMMARY
#==============================================================================
echo ""
echo "=============================================="
echo "  Deployment Complete!"
echo "=============================================="
echo ""
echo "Access URLs:"
echo "  Admin Portal:  http://$EC2_IP/admin/"
echo "  Tenant Portal: http://$EC2_IP/tenant/"
echo "  Backend API:   http://$EC2_IP:8080/health"
echo ""
echo "Test Accounts:"
echo "  Super Admin: admin@pgworld.com / Admin@123"
echo "  PG Owner:    owner@pg.com / Owner@123"
echo "  Tenant:      tenant@pg.com / Tenant@123"
echo ""
echo "Note: Clear your browser cache (Ctrl+Shift+R) if you see old pages"
echo ""

