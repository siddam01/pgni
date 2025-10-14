#!/bin/bash
#================================================================
# COMPLETE DEPLOYMENT USING AWS SYSTEMS MANAGER
# No SSH key required!
#================================================================

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

EC2_INSTANCE_ID="i-0909d462845deb151"
AWS_REGION="us-east-1"
EC2_HOST="34.227.111.143"

echo -e "${BLUE}================================================================${NC}"
echo -e "${BLUE}   COMPLETE DEPLOYMENT (AWS Systems Manager)${NC}"
echo -e "${BLUE}================================================================${NC}"
echo ""

#================================================================
# Execute commands on EC2 via Systems Manager
#================================================================
echo -e "${YELLOW}Deploying Full Application...${NC}"
echo "This will take 25-30 minutes total."
echo ""

COMMAND_ID=$(aws ssm send-command \
    --instance-ids $EC2_INSTANCE_ID \
    --document-name "AWS-RunShellScript" \
    --comment "Complete PGNi Application Deployment" \
    --timeout-seconds 3600 \
    --region $AWS_REGION \
    --parameters 'commands=[
        "#!/bin/bash",
        "set -e",
        "exec > >(tee /tmp/deployment.log) 2>&1",
        "",
        "echo \"========================================\"",
        "echo \"  PHASE 1: Expand Filesystem\"",
        "echo \"========================================\"",
        "sudo growpart /dev/nvme0n1 1 2>/dev/null || true",
        "sudo resize2fs /dev/nvme0n1p1 || sudo xfs_growfs / || true",
        "df -h /",
        "",
        "echo \"\"",
        "echo \"========================================\"",
        "echo \"  PHASE 2: Install Flutter (7 min)\"",
        "echo \"========================================\"",
        "sudo yum install -y git wget tar xz unzip >/dev/null 2>&1",
        "cd /opt",
        "if [ ! -d flutter ]; then",
        "    echo \"Downloading Flutter SDK...\"",
        "    sudo wget -q https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.16.0-stable.tar.xz",
        "    sudo tar xf flutter_linux_3.16.0-stable.tar.xz",
        "    sudo rm flutter_linux_3.16.0-stable.tar.xz",
        "    sudo chown -R ec2-user:ec2-user /opt/flutter",
        "    echo \"export PATH=/opt/flutter/bin:\\$PATH\" | sudo tee -a /etc/profile.d/flutter.sh",
        "fi",
        "export PATH=/opt/flutter/bin:\\$PATH",
        "flutter --version",
        "",
        "echo \"\"",
        "echo \"========================================\"",
        "echo \"  PHASE 3: Build Applications (15 min)\"",
        "echo \"========================================\"",
        "cd /opt",
        "if [ -d pgni ]; then cd pgni && git pull; else git clone https://github.com/siddam01/pgni.git && cd pgni; fi",
        "",
        "echo \"Building Admin App...\"",
        "cd /opt/pgni/pgworld-master",
        "flutter clean >/dev/null 2>&1",
        "flutter pub get",
        "flutter build web --release",
        "",
        "echo \"Building Tenant App...\"",
        "cd /opt/pgni/pgworldtenant-master",
        "flutter clean >/dev/null 2>&1",
        "flutter pub get",
        "flutter build web --release",
        "",
        "echo \"\"",
        "echo \"========================================\"",
        "echo \"  PHASE 4: Deploy Applications (2 min)\"",
        "echo \"========================================\"",
        "sudo yum install -y nginx >/dev/null 2>&1",
        "sudo systemctl enable nginx",
        "sudo systemctl start nginx",
        "",
        "sudo rm -rf /var/www/html/admin_backup /var/www/html/tenant_backup",
        "sudo mv /var/www/html/admin /var/www/html/admin_backup 2>/dev/null || true",
        "sudo mv /var/www/html/tenant /var/www/html/tenant_backup 2>/dev/null || true",
        "",
        "sudo mkdir -p /var/www/html/admin /var/www/html/tenant",
        "sudo cp -r /opt/pgni/pgworld-master/build/web/* /var/www/html/admin/",
        "sudo cp -r /opt/pgni/pgworldtenant-master/build/web/* /var/www/html/tenant/",
        "sudo chown -R ec2-user:ec2-user /var/www/html",
        "",
        "sudo tee /etc/nginx/conf.d/pgni.conf > /dev/null <<EOF",
        "server {",
        "    listen 80 default_server;",
        "    server_name _;",
        "    location /admin {",
        "        alias /var/www/html/admin;",
        "        index index.html;",
        "        try_files \\$uri \\$uri/ /admin/index.html;",
        "    }",
        "    location /tenant {",
        "        alias /var/www/html/tenant;",
        "        index index.html;",
        "        try_files \\$uri \\$uri/ /tenant/index.html;",
        "    }",
        "    location /api {",
        "        proxy_pass http://localhost:8080;",
        "        proxy_set_header Host \\$host;",
        "        proxy_set_header X-Real-IP \\$remote_addr;",
        "    }",
        "    location = / {",
        "        return 301 /admin;",
        "    }",
        "}",
        "EOF",
        "",
        "sudo nginx -t && sudo systemctl reload nginx",
        "",
        "echo \"\"",
        "echo \"========================================\"",
        "echo \"  DEPLOYMENT COMPLETE!\"",
        "echo \"========================================\"",
        "echo \"\"",
        "echo \"Admin:  http://34.227.111.143/admin\"",
        "echo \"Tenant: http://34.227.111.143/tenant\"",
        "echo \"\"",
        "echo \"Login: admin@pgni.com / password123\"",
        "echo \"\"",
        "df -h /"
    ]' \
    --output text \
    --query 'Command.CommandId')

echo "Command ID: $COMMAND_ID"
echo ""
echo "Deployment started! Monitoring progress..."
echo ""

# Monitor progress
PREV_STATUS=""
while true; do
    STATUS=$(aws ssm get-command-invocation \
        --command-id $COMMAND_ID \
        --instance-id $EC2_INSTANCE_ID \
        --region $AWS_REGION \
        --query 'Status' \
        --output text 2>/dev/null)
    
    if [ "$STATUS" != "$PREV_STATUS" ]; then
        echo "[$(date +%H:%M:%S)] Status: $STATUS"
        PREV_STATUS="$STATUS"
    fi
    
    if [ "$STATUS" = "Success" ]; then
        echo -e "${GREEN}✓ Deployment completed successfully!${NC}"
        break
    elif [ "$STATUS" = "Failed" ] || [ "$STATUS" = "Cancelled" ] || [ "$STATUS" = "TimedOut" ]; then
        echo -e "${YELLOW}✗ Deployment failed with status: $STATUS${NC}"
        break
    fi
    
    sleep 10
done

echo ""
echo "Fetching deployment output..."
echo ""

aws ssm get-command-invocation \
    --command-id $COMMAND_ID \
    --instance-id $EC2_INSTANCE_ID \
    --region $AWS_REGION \
    --query 'StandardOutputContent' \
    --output text

echo ""
echo -e "${BLUE}================================================================${NC}"
echo -e "${BLUE}   TESTING DEPLOYMENT${NC}"
echo -e "${BLUE}================================================================${NC}"
echo ""

sleep 5

echo "Admin UI:"
curl -s -o /dev/null -w "  HTTP %{http_code}\n" http://$EC2_HOST/admin

echo "Tenant UI:"
curl -s -o /dev/null -w "  HTTP %{http_code}\n" http://$EC2_HOST/tenant

echo "API:"
curl -s -o /dev/null -w "  HTTP %{http_code}\n" http://$EC2_HOST:8080/health

echo ""
echo -e "${GREEN}================================================================${NC}"
echo -e "${GREEN}   ACCESS YOUR APPLICATION${NC}"
echo -e "${GREEN}================================================================${NC}"
echo ""
echo "🏢 Admin:  http://$EC2_HOST/admin"
echo "   Login:  admin@pgni.com / password123"
echo ""
echo "🏠 Tenant: http://$EC2_HOST/tenant"
echo "   Login:  tenant@pgni.com / password123"
echo ""
echo "📱 Test on mobile and laptop now!"
echo ""

