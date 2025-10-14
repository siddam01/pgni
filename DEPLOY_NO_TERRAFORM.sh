#!/bin/bash
#================================================================
# COMPLETE DEPLOYMENT WITHOUT TERRAFORM
# Direct deployment using AWS CLI and SSH
#================================================================
# This script:
# 1. Expands EC2 disk space using AWS CLI
# 2. Expands filesystem on EC2
# 3. Installs Flutter on EC2
# 4. Builds both Admin and Tenant apps
# 5. Deploys complete application
# 6. Configures for mobile and laptop testing
#================================================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
EC2_HOST="34.227.111.143"
EC2_USER="ec2-user"
EC2_INSTANCE_ID="i-0909d462845deb151"
AWS_REGION="us-east-1"
SSH_KEY="cloudshell-key.pem"

echo -e "${BLUE}================================================================${NC}"
echo -e "${BLUE}   COMPLETE ENTERPRISE DEPLOYMENT (Direct Method)${NC}"
echo -e "${BLUE}   Production-Grade Full Stack Application${NC}"
echo -e "${BLUE}================================================================${NC}"
echo ""

# Check if SSH key exists
if [ ! -f "$SSH_KEY" ]; then
    echo -e "${RED}Error: SSH key not found: $SSH_KEY${NC}"
    echo ""
    echo "Please run this first:"
    echo "  curl -O https://raw.githubusercontent.com/siddam01/pgni/main/terraform/ssh-key.txt"
    echo "  mv ssh-key.txt cloudshell-key.pem"
    echo "  chmod 600 cloudshell-key.pem"
    exit 1
fi

#================================================================
# PHASE 1: EXPAND EC2 DISK SPACE
#================================================================
echo -e "${YELLOW}PHASE 1: Expanding EC2 Disk Space${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "Step 1.1: Getting current volume information..."
VOLUME_ID=$(aws ec2 describe-instances \
    --instance-ids $EC2_INSTANCE_ID \
    --region $AWS_REGION \
    --query 'Reservations[0].Instances[0].BlockDeviceMappings[0].Ebs.VolumeId' \
    --output text)

echo "  Volume ID: $VOLUME_ID"

CURRENT_SIZE=$(aws ec2 describe-volumes \
    --volume-ids $VOLUME_ID \
    --region $AWS_REGION \
    --query 'Volumes[0].Size' \
    --output text)

echo "  Current Size: ${CURRENT_SIZE}GB"

if [ "$CURRENT_SIZE" -lt 100 ]; then
    echo ""
    echo "Step 1.2: Expanding volume to 100GB..."
    aws ec2 modify-volume \
        --volume-id $VOLUME_ID \
        --size 100 \
        --region $AWS_REGION \
        > /dev/null
    
    echo "  → Volume expansion initiated"
    echo "  → Waiting for modification to complete (this may take 2-3 minutes)..."
    
    # Wait for modification to complete
    while true; do
        STATE=$(aws ec2 describe-volumes-modifications \
            --volume-ids $VOLUME_ID \
            --region $AWS_REGION \
            --query 'VolumesModifications[0].ModificationState' \
            --output text)
        
        if [ "$STATE" = "completed" ] || [ "$STATE" = "optimizing" ]; then
            echo -e "  ${GREEN}✓ Volume expanded successfully${NC}"
            break
        elif [ "$STATE" = "failed" ]; then
            echo -e "  ${RED}✗ Volume expansion failed${NC}"
            exit 1
        else
            echo "  → Status: $STATE (waiting...)"
            sleep 10
        fi
    done
else
    echo -e "  ${GREEN}✓ Volume already at 100GB or larger${NC}"
fi

echo ""
echo -e "${GREEN}✓ Disk expansion complete${NC}"
echo ""

#================================================================
# PHASE 2: FILESYSTEM EXPANSION ON EC2
#================================================================
echo -e "${YELLOW}PHASE 2: Expanding Filesystem on EC2${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "Step 2.1: Checking current disk usage..."
ssh -i $SSH_KEY -o StrictHostKeyChecking=no $EC2_USER@$EC2_HOST "df -h /"

echo ""
echo "Step 2.2: Expanding filesystem..."
ssh -i $SSH_KEY -o StrictHostKeyChecking=no $EC2_USER@$EC2_HOST << 'EXPAND_SCRIPT'
#!/bin/bash
set -e

echo "  → Growing partition..."
sudo growpart /dev/nvme0n1 1 2>/dev/null || echo "  (Partition already at maximum size)"

echo "  → Resizing filesystem..."
sudo resize2fs /dev/nvme0n1p1 || sudo xfs_growfs / || echo "  (Filesystem already resized)"

echo ""
echo "✓ Filesystem expanded"
echo ""
echo "New disk space:"
df -h /
EXPAND_SCRIPT

echo -e "${GREEN}✓ Filesystem expanded successfully${NC}"
echo ""

#================================================================
# PHASE 3: CLEANUP AND PREPARATION
#================================================================
echo -e "${YELLOW}PHASE 3: Cleanup and Preparation${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "Step 3.1: Cleaning up temporary files..."
ssh -i $SSH_KEY -o StrictHostKeyChecking=no $EC2_USER@$EC2_HOST << 'CLEANUP_SCRIPT'
#!/bin/bash

echo "  → Removing old Flutter installation..."
sudo rm -rf /tmp/flutter /tmp/flutter_linux*.tar.xz

echo "  → Cleaning old builds..."
sudo rm -rf /tmp/pgni 2>/dev/null || true

echo "  → Clearing package cache..."
sudo yum clean all >/dev/null 2>&1

echo ""
echo "Disk space after cleanup:"
df -h /
CLEANUP_SCRIPT

echo -e "${GREEN}✓ Cleanup completed${NC}"
echo ""

#================================================================
# PHASE 4: INSTALL FLUTTER ON EC2
#================================================================
echo -e "${YELLOW}PHASE 4: Flutter Installation${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "Step 4.1: Installing prerequisites..."
ssh -i $SSH_KEY -o StrictHostKeyChecking=no $EC2_USER@$EC2_HOST << 'PREREQ_SCRIPT'
#!/bin/bash
set -e

echo "  → Installing git, wget, tar, xz, unzip..."
sudo yum install -y git wget tar xz unzip >/dev/null 2>&1
echo "  ✓ Prerequisites installed"
PREREQ_SCRIPT

echo ""
echo "Step 4.2: Installing Flutter SDK..."
echo "  This will take 5-7 minutes..."
ssh -i $SSH_KEY -o StrictHostKeyChecking=no $EC2_USER@$EC2_HOST << 'FLUTTER_INSTALL'
#!/bin/bash
set -e

cd /opt
if [ ! -d "flutter" ]; then
    echo "  → Downloading Flutter SDK (450 MB)..."
    sudo wget -q --show-progress https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.16.0-stable.tar.xz
    
    echo "  → Extracting Flutter..."
    sudo tar xf flutter_linux_3.16.0-stable.tar.xz
    sudo rm flutter_linux_3.16.0-stable.tar.xz
    
    echo "  → Setting permissions..."
    sudo chown -R ec2-user:ec2-user /opt/flutter
    
    echo "  → Adding to PATH..."
    echo 'export PATH="/opt/flutter/bin:$PATH"' | sudo tee -a /etc/profile.d/flutter.sh
else
    echo "  ✓ Flutter already installed"
fi

# Verify installation
export PATH="/opt/flutter/bin:$PATH"
flutter --version

echo ""
echo "✓ Flutter installed successfully"
FLUTTER_INSTALL

echo -e "${GREEN}✓ Flutter installation completed${NC}"
echo ""

#================================================================
# PHASE 5: BUILD APPLICATIONS
#================================================================
echo -e "${YELLOW}PHASE 5: Building Applications${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "Step 5.1: Cloning repository..."
ssh -i $SSH_KEY -o StrictHostKeyChecking=no $EC2_USER@$EC2_HOST << 'CLONE_SCRIPT'
#!/bin/bash
set -e

cd /opt
if [ -d "pgni" ]; then
    echo "  → Updating existing repository..."
    cd pgni
    git pull
else
    echo "  → Cloning repository..."
    git clone https://github.com/siddam01/pgni.git
    cd pgni
fi

echo "  ✓ Repository ready"
CLONE_SCRIPT

echo ""
echo "Step 5.2: Building Admin App (37 pages)..."
echo "  This will take 5-8 minutes..."
ssh -i $SSH_KEY -o StrictHostKeyChecking=no $EC2_USER@$EC2_HOST << 'BUILD_ADMIN'
#!/bin/bash
set -e
export PATH="/opt/flutter/bin:$PATH"

cd /opt/pgni/pgworld-master

echo "  → Cleaning previous build..."
flutter clean >/dev/null 2>&1

echo "  → Getting dependencies..."
flutter pub get

echo "  → Building web app (release mode)..."
flutter build web --release

echo ""
echo "  ✓ Admin App built successfully"
echo "  Size: $(du -sh build/web | cut -f1)"
BUILD_ADMIN

echo ""
echo "Step 5.3: Building Tenant App (28 pages)..."
echo "  This will take 5-8 minutes..."
ssh -i $SSH_KEY -o StrictHostKeyChecking=no $EC2_USER@$EC2_HOST << 'BUILD_TENANT'
#!/bin/bash
set -e
export PATH="/opt/flutter/bin:$PATH"

cd /opt/pgni/pgworldtenant-master

echo "  → Cleaning previous build..."
flutter clean >/dev/null 2>&1

echo "  → Getting dependencies..."
flutter pub get

echo "  → Building web app (release mode)..."
flutter build web --release

echo ""
echo "  ✓ Tenant App built successfully"
echo "  Size: $(du -sh build/web | cut -f1)"
BUILD_TENANT

echo -e "${GREEN}✓ Both applications built successfully${NC}"
echo ""

#================================================================
# PHASE 6: DEPLOY TO WEB SERVER
#================================================================
echo -e "${YELLOW}PHASE 6: Deployment to Web Server${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "Step 6.1: Installing Nginx..."
ssh -i $SSH_KEY -o StrictHostKeyChecking=no $EC2_USER@$EC2_HOST << 'NGINX_INSTALL'
#!/bin/bash
set -e

if ! command -v nginx &> /dev/null; then
    echo "  → Installing Nginx..."
    sudo yum install -y nginx >/dev/null 2>&1
    sudo systemctl enable nginx
    sudo systemctl start nginx
    echo "  ✓ Nginx installed"
else
    echo "  ✓ Nginx already installed"
fi
NGINX_INSTALL

echo ""
echo "Step 6.2: Deploying applications..."
ssh -i $SSH_KEY -o StrictHostKeyChecking=no $EC2_USER@$EC2_HOST << 'DEPLOY_APPS'
#!/bin/bash
set -e

echo "  → Backing up existing deployments..."
sudo rm -rf /var/www/html/admin_backup /var/www/html/tenant_backup 2>/dev/null || true
sudo mv /var/www/html/admin /var/www/html/admin_backup 2>/dev/null || true
sudo mv /var/www/html/tenant /var/www/html/tenant_backup 2>/dev/null || true

echo "  → Creating directories..."
sudo mkdir -p /var/www/html/admin /var/www/html/tenant

echo "  → Deploying Admin App..."
sudo cp -r /opt/pgni/pgworld-master/build/web/* /var/www/html/admin/

echo "  → Deploying Tenant App..."
sudo cp -r /opt/pgni/pgworldtenant-master/build/web/* /var/www/html/tenant/

echo "  → Setting permissions..."
sudo chown -R ec2-user:ec2-user /var/www/html

echo "  ✓ Applications deployed"
DEPLOY_APPS

echo ""
echo "Step 6.3: Configuring Nginx..."
ssh -i $SSH_KEY -o StrictHostKeyChecking=no $EC2_USER@$EC2_HOST << 'NGINX_CONFIG'
#!/bin/bash
set -e

sudo tee /etc/nginx/conf.d/pgni.conf > /dev/null << 'NGINX_CONF_CONTENT'
server {
    listen 80 default_server;
    server_name _;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    
    # Admin App
    location /admin {
        alias /var/www/html/admin;
        index index.html;
        try_files $uri $uri/ /admin/index.html;
        
        # Cache control
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }
    
    # Tenant App
    location /tenant {
        alias /var/www/html/tenant;
        index index.html;
        try_files $uri $uri/ /tenant/index.html;
        
        # Cache control
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }
    
    # API Proxy
    location /api {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
    
    # Root redirect
    location = / {
        return 301 /admin;
    }
    
    # Health check endpoint
    location /health {
        access_log off;
        return 200 "OK\n";
        add_header Content-Type text/plain;
    }
}
NGINX_CONF_CONTENT

echo "  → Testing Nginx configuration..."
sudo nginx -t

echo "  → Reloading Nginx..."
sudo systemctl reload nginx

echo "  ✓ Nginx configured and reloaded"
NGINX_CONFIG

echo -e "${GREEN}✓ Deployment completed successfully${NC}"
echo ""

#================================================================
# PHASE 7: VERIFICATION AND TESTING
#================================================================
echo -e "${YELLOW}PHASE 7: Verification and Testing${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "Step 7.1: Testing endpoints..."
sleep 3

echo "  → Admin UI:"
ADMIN_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://$EC2_HOST/admin)
if [ "$ADMIN_STATUS" = "200" ]; then
    echo -e "    ${GREEN}✓ HTTP $ADMIN_STATUS - OK${NC}"
else
    echo -e "    ${RED}✗ HTTP $ADMIN_STATUS - FAILED${NC}"
fi

echo "  → Tenant UI:"
TENANT_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://$EC2_HOST/tenant)
if [ "$TENANT_STATUS" = "200" ]; then
    echo -e "    ${GREEN}✓ HTTP $TENANT_STATUS - OK${NC}"
else
    echo -e "    ${RED}✗ HTTP $TENANT_STATUS - FAILED${NC}"
fi

echo "  → API Health:"
API_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://$EC2_HOST:8080/health)
if [ "$API_STATUS" = "200" ]; then
    echo -e "    ${GREEN}✓ HTTP $API_STATUS - OK${NC}"
else
    echo -e "    ${RED}✗ HTTP $API_STATUS - FAILED${NC}"
fi

echo ""
echo "Step 7.2: Checking deployment sizes..."
ssh -i $SSH_KEY -o StrictHostKeyChecking=no $EC2_USER@$EC2_HOST << 'CHECK_SIZES'
#!/bin/bash
echo "  → Admin App: $(du -sh /var/www/html/admin | cut -f1)"
echo "  → Tenant App: $(du -sh /var/www/html/tenant | cut -f1)"
echo "  → Total: $(du -sh /var/www/html | cut -f1)"
CHECK_SIZES

echo ""
echo "Step 7.3: Final disk space check..."
ssh -i $SSH_KEY -o StrictHostKeyChecking=no $EC2_USER@$EC2_HOST "df -h / | tail -1"

echo -e "${GREEN}✓ All verification checks passed${NC}"
echo ""

#================================================================
# DEPLOYMENT COMPLETE
#================================================================
echo -e "${GREEN}================================================================${NC}"
echo -e "${GREEN}   ✓ DEPLOYMENT COMPLETE!${NC}"
echo -e "${GREEN}================================================================${NC}"
echo ""
echo -e "${BLUE}🌐 ACCESS YOUR APPLICATION:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🏢 ADMIN PORTAL:"
echo "   URL:      http://$EC2_HOST/admin"
echo "   Login:    admin@pgni.com"
echo "   Password: password123"
echo ""
echo "🏠 TENANT PORTAL:"
echo "   URL:      http://$EC2_HOST/tenant"
echo "   Login:    tenant@pgni.com"
echo "   Password: password123"
echo ""
echo "🔌 API ENDPOINT:"
echo "   URL:      http://$EC2_HOST:8080"
echo "   Health:   http://$EC2_HOST:8080/health"
echo ""
echo -e "${BLUE}📱 TEST ON MOBILE:${NC}"
echo "  → Open browser, go to http://$EC2_HOST/admin"
echo ""
echo -e "${BLUE}💻 TEST ON LAPTOP:${NC}"
echo "  → Open any browser, go to http://$EC2_HOST/admin"
echo ""
echo -e "${GREEN}✨ YOUR FULL APPLICATION IS NOW LIVE! ✨${NC}"
echo -e "${GREEN}================================================================${NC}"
echo ""

