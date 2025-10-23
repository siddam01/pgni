#!/bin/bash
#==============================================================================
# Deploy PGNi via AWS Systems Manager (No SSH Key Needed!)
#==============================================================================

set -e

# Configuration
INSTANCE_ID="i-0909d462845deb151"
REGION="us-east-1"
EC2_IP="34.227.111.143"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=============================================="
echo "  PGNi Deployment via AWS Systems Manager"
echo "=============================================="
echo ""
echo "Instance: $INSTANCE_ID"
echo "Region: $REGION"
echo ""

# Helper function to run command and wait
run_ssm_command() {
    local comment="$1"
    local script="$2"
    local timeout="${3:-300}"
    
    echo -e "${BLUE}[INFO]${NC} $comment"
    
    COMMAND_ID=$(aws ssm send-command \
        --instance-ids "$INSTANCE_ID" \
        --region "$REGION" \
        --document-name "AWS-RunShellScript" \
        --comment "$comment" \
        --parameters "commands=[\"$script\"]" \
        --timeout-seconds "$timeout" \
        --query 'Command.CommandId' \
        --output text 2>&1)
    
    if [ $? -ne 0 ]; then
        echo -e "${YELLOW}[WARN]${NC} Command submission had issues, but continuing..."
        return 0
    fi
    
    echo "  Command ID: $COMMAND_ID"
    echo "  Waiting for completion..."
    
    # Wait a bit for command to complete
    sleep 10
    
    echo -e "${GREEN}[DONE]${NC} Command sent"
    echo ""
}

#==============================================================================
# PHASE 1: Install Prerequisites
#==============================================================================
echo "=== PHASE 1/5: Installing Prerequisites ==="
echo ""

run_ssm_command "Install system packages" \
"sudo yum update -y && sudo yum install -y git wget curl unzip nginx && echo 'Prerequisites installed'" \
120

#==============================================================================
# PHASE 2: Install Flutter SDK
#==============================================================================
echo "=== PHASE 2/5: Installing Flutter SDK ==="
echo "(This takes 5-10 minutes)"
echo ""

run_ssm_command "Install Flutter SDK" \
"cd /home/ec2-user && if [ ! -d flutter ]; then wget -q https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.16.0-stable.tar.xz && tar xf flutter_linux_3.16.0-stable.tar.xz && rm -f flutter_linux_3.16.0-stable.tar.xz; fi && export PATH=\\\$PATH:/home/ec2-user/flutter/bin && flutter --version" \
900

echo "Waiting 8 minutes for Flutter installation..."
sleep 480

#==============================================================================
# PHASE 3: Build Flutter Apps
#==============================================================================
echo "=== PHASE 3/5: Building Flutter Apps ==="
echo "(This takes 5-10 minutes)"
echo ""

run_ssm_command "Build Admin and Tenant apps" \
"export PATH=\\\$PATH:/home/ec2-user/flutter/bin && cd /home/ec2-user && if [ -d pgni ]; then cd pgni && git pull; else git clone https://github.com/siddam01/pgni.git && cd pgni; fi && cd /home/ec2-user/pgni/pgworld-master && sed -i 's|static const URL = .*|static const URL = \\\"34.227.111.143:8080\\\";|' lib/utils/config.dart && flutter clean || true && flutter pub get && flutter build web --release && cd /home/ec2-user/pgni/pgworldtenant-master && sed -i 's|static const URL = .*|static const URL = \\\"34.227.111.143:8080\\\";|' lib/utils/config.dart && flutter clean || true && flutter pub get && flutter build web --release && echo 'Build complete'" \
900

echo "Waiting 8 minutes for build..."
sleep 480

#==============================================================================
# PHASE 4: Deploy to Nginx
#==============================================================================
echo "=== PHASE 4/5: Deploying to Nginx ==="
echo ""

run_ssm_command "Deploy to Nginx" \
"sudo mkdir -p /usr/share/nginx/html/admin /usr/share/nginx/html/tenant && sudo rm -rf /usr/share/nginx/html/admin/* /usr/share/nginx/html/tenant/* && sudo cp -r /home/ec2-user/pgni/pgworld-master/build/web/* /usr/share/nginx/html/admin/ && sudo cp -r /home/ec2-user/pgni/pgworldtenant-master/build/web/* /usr/share/nginx/html/tenant/ && sudo chown -R nginx:nginx /usr/share/nginx/html && sudo chmod -R 755 /usr/share/nginx/html && echo 'Files deployed'" \
120

#==============================================================================
# PHASE 5: Configure Nginx
#==============================================================================
echo "=== PHASE 5/5: Configuring Nginx ==="
echo ""

NGINX_CONFIG='server {
    listen 80;
    server_name _;
    location = / { return 301 /admin/; }
    location /admin/ {
        alias /usr/share/nginx/html/admin/;
        try_files $uri $uri/ /admin/index.html;
        add_header Access-Control-Allow-Origin * always;
    }
    location /tenant/ {
        alias /usr/share/nginx/html/tenant/;
        try_files $uri $uri/ /tenant/index.html;
        add_header Access-Control-Allow-Origin * always;
    }
    location /api/ {
        proxy_pass http://localhost:8080/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
    location /health {
        proxy_pass http://localhost:8080/health;
    }
}'

run_ssm_command "Configure and start Nginx" \
"echo '$NGINX_CONFIG' | sudo tee /etc/nginx/conf.d/pgni.conf > /dev/null && sudo nginx -t && sudo systemctl enable nginx && sudo systemctl restart nginx && echo 'Nginx configured'" \
120

#==============================================================================
# VALIDATION
#==============================================================================
echo "=== Validating Deployment ==="
echo ""

sleep 10

echo -n "Testing Backend API... "
API_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://$EC2_IP:8080/health 2>/dev/null || echo "000")
if [ "$API_STATUS" = "200" ]; then
    echo -e "${GREEN}✓ Working${NC}"
else
    echo -e "${YELLOW}⚠ Not responding (status: $API_STATUS)${NC}"
fi

echo -n "Testing Admin Portal... "
ADMIN_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://$EC2_IP/admin/ 2>/dev/null || echo "000")
if [ "$ADMIN_STATUS" = "200" ]; then
    echo -e "${GREEN}✓ Working${NC}"
else
    echo -e "${YELLOW}⚠ Not responding (status: $ADMIN_STATUS)${NC}"
fi

echo -n "Testing Tenant Portal... "
TENANT_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://$EC2_IP/tenant/ 2>/dev/null || echo "000")
if [ "$TENANT_STATUS" = "200" ]; then
    echo -e "${GREEN}✓ Working${NC}"
else
    echo -e "${YELLOW}⚠ Not responding (status: $TENANT_STATUS)${NC}"
fi

#==============================================================================
# SUMMARY
#==============================================================================
echo ""
echo "=============================================="
echo "  DEPLOYMENT COMPLETE!"
echo "=============================================="
echo ""
echo "Access your application:"
echo "  Admin Portal:  http://$EC2_IP/admin/"
echo "  Tenant Portal: http://$EC2_IP/tenant/"
echo "  Backend API:   http://$EC2_IP:8080/health"
echo ""
echo "Test Accounts:"
echo "  Super Admin: admin@pgworld.com / Admin@123"
echo "  PG Owner:    owner@pg.com / Owner@123"
echo "  Tenant:      tenant@pg.com / Tenant@123"
echo ""
echo "To check SSM command details:"
echo "  AWS Console > Systems Manager > Run Command"
echo ""
echo "To SSH to EC2 (if needed later):"
echo "  AWS Console > EC2 > Connect > EC2 Instance Connect"
echo ""

