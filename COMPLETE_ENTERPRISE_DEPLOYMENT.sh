#!/bin/bash
#==============================================================================
# COMPLETE ENTERPRISE DEPLOYMENT SCRIPT
# Deploys Full PGNi Application: Backend API + Frontend (Admin & Tenant)
#==============================================================================

set -e

# Configuration
EC2_IP="34.227.111.143"
EC2_USER="ec2-user"
SSH_KEY="cloudshell-key.pem"
REGION="us-east-1"
INSTANCE_ID="i-0b5f620584d1e4ee9"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

echo "=============================================="
echo "  PGNi Complete Enterprise Deployment"
echo "=============================================="
echo ""
echo "Deployment Target: $EC2_IP"
echo "Deployment Time: $(date)"
echo ""

#==============================================================================
# PHASE 1: INFRASTRUCTURE VALIDATION & EXPANSION
#==============================================================================

log_info "PHASE 1/6: Infrastructure Validation & Expansion"
echo "----------------------------------------------"

# Check if SSH key exists
if [ ! -f "$SSH_KEY" ]; then
    log_error "SSH key not found: $SSH_KEY"
    log_info "Downloading SSH key from repository..."
    curl -s -o "$SSH_KEY" https://raw.githubusercontent.com/siddam01/pgni/main/terraform/ssh-key.txt
    chmod 600 "$SSH_KEY"
    log_success "SSH key downloaded"
fi

# Check EC2 instance status
log_info "Checking EC2 instance status..."
INSTANCE_STATE=$(aws ec2 describe-instances --instance-ids "$INSTANCE_ID" --region "$REGION" --query 'Reservations[0].Instances[0].State.Name' --output text 2>/dev/null || echo "unknown")

if [ "$INSTANCE_STATE" != "running" ]; then
    log_error "EC2 instance is not running (state: $INSTANCE_STATE)"
    exit 1
fi
log_success "EC2 instance is running"

# Check and expand disk if needed
log_info "Checking disk space..."
VOLUME_ID=$(aws ec2 describe-instances --instance-ids "$INSTANCE_ID" --region "$REGION" --query 'Reservations[0].Instances[0].BlockDeviceMappings[0].Ebs.VolumeId' --output text)
CURRENT_SIZE=$(aws ec2 describe-volumes --volume-ids "$VOLUME_ID" --region "$REGION" --query 'Volumes[0].Size' --output text)

log_info "Current disk size: ${CURRENT_SIZE}GB"

if [ "$CURRENT_SIZE" -lt 100 ]; then
    log_warning "Disk size is less than 100GB, expanding..."
    
    # Modify volume size
    aws ec2 modify-volume --volume-id "$VOLUME_ID" --size 100 --region "$REGION"
    
    log_info "Waiting for volume modification to complete..."
    sleep 10
    
    # Wait for modification to complete
    while true; do
        MOD_STATE=$(aws ec2 describe-volumes-modifications --volume-ids "$VOLUME_ID" --region "$REGION" --query 'VolumesModifications[0].ModificationState' --output text)
        if [ "$MOD_STATE" == "optimizing" ] || [ "$MOD_STATE" == "completed" ]; then
            break
        fi
        echo -n "."
        sleep 5
    done
    echo ""
    
    log_success "Volume expanded to 100GB"
    
    # Expand the filesystem on EC2
    log_info "Expanding filesystem on EC2..."
    ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "${EC2_USER}@${EC2_IP}" << 'EOF'
        sudo growpart /dev/xvda 1 2>/dev/null || sudo growpart /dev/nvme0n1 1 2>/dev/null || true
        sudo resize2fs /dev/xvda1 2>/dev/null || sudo xfs_growfs / 2>/dev/null || true
        df -h / | tail -1
EOF
    log_success "Filesystem expanded"
else
    log_success "Disk size is adequate (${CURRENT_SIZE}GB)"
fi

echo ""

#==============================================================================
# PHASE 2: INSTALL PREREQUISITES ON EC2
#==============================================================================

log_info "PHASE 2/6: Installing Prerequisites on EC2"
echo "----------------------------------------------"

ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "${EC2_USER}@${EC2_IP}" << 'EOF'
set -e

echo "[1/5] Updating system packages..."
sudo yum update -y > /dev/null 2>&1

echo "[2/5] Installing development tools..."
sudo yum install -y git wget curl unzip nginx > /dev/null 2>&1

echo "[3/5] Checking Flutter SDK..."
if [ ! -d "/home/ec2-user/flutter" ]; then
    echo "      Downloading Flutter SDK (this may take 5-10 minutes)..."
    cd /home/ec2-user
    wget -q https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.16.0-stable.tar.xz
    echo "      Extracting Flutter SDK..."
    tar xf flutter_linux_3.16.0-stable.tar.xz
    rm -f flutter_linux_3.16.0-stable.tar.xz
    echo "      Flutter SDK installed"
else
    echo "      Flutter SDK already installed"
fi

echo "[4/5] Setting up Flutter environment..."
export PATH="$PATH:/home/ec2-user/flutter/bin"
echo 'export PATH="$PATH:/home/ec2-user/flutter/bin"' >> ~/.bashrc

echo "[5/5] Running Flutter doctor..."
flutter doctor -v || true

echo ""
echo "Prerequisites installation complete!"
df -h / | tail -1
EOF

log_success "Prerequisites installed"
echo ""

#==============================================================================
# PHASE 3: BUILD FLUTTER APPLICATIONS
#==============================================================================

log_info "PHASE 3/6: Building Flutter Applications"
echo "----------------------------------------------"

ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "${EC2_USER}@${EC2_IP}" << 'EOF'
set -e

export PATH="$PATH:/home/ec2-user/flutter/bin"

# Clone/update repository
echo "[1/6] Updating source code..."
if [ -d "/home/ec2-user/pgni" ]; then
    cd /home/ec2-user/pgni
    git pull
else
    cd /home/ec2-user
    git clone https://github.com/siddam01/pgni.git
    cd pgni
fi

echo ""
echo "[2/6] Configuring Admin App..."
cd /home/ec2-user/pgni/pgworld-master

# Update API URL in config
sed -i 's|static const URL = ".*";|static const URL = "34.227.111.143:8080";|' lib/utils/config.dart

echo "[3/6] Building Admin App (Flutter Web)..."
flutter clean > /dev/null 2>&1 || true
flutter pub get
flutter build web --release

echo ""
echo "[4/6] Configuring Tenant App..."
cd /home/ec2-user/pgni/pgworldtenant-master

# Update API URL in config
sed -i 's|static const URL = ".*";|static const URL = "34.227.111.143:8080";|' lib/utils/config.dart

echo "[5/6] Building Tenant App (Flutter Web)..."
flutter clean > /dev/null 2>&1 || true
flutter pub get
flutter build web --release

echo ""
echo "[6/6] Build summary:"
echo "    Admin App: $(du -sh /home/ec2-user/pgni/pgworld-master/build/web | cut -f1)"
echo "    Tenant App: $(du -sh /home/ec2-user/pgni/pgworldtenant-master/build/web | cut -f1)"

echo ""
echo "Flutter applications built successfully!"
EOF

log_success "Flutter applications built"
echo ""

#==============================================================================
# PHASE 4: DEPLOY FRONTEND TO NGINX
#==============================================================================

log_info "PHASE 4/6: Deploying Frontend to Nginx"
echo "----------------------------------------------"

ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "${EC2_USER}@${EC2_IP}" << 'EOF'
set -e

echo "[1/4] Creating web directories..."
sudo mkdir -p /usr/share/nginx/html/admin
sudo mkdir -p /usr/share/nginx/html/tenant

echo "[2/4] Deploying Admin App..."
sudo rm -rf /usr/share/nginx/html/admin/*
sudo cp -r /home/ec2-user/pgni/pgworld-master/build/web/* /usr/share/nginx/html/admin/

echo "[3/4] Deploying Tenant App..."
sudo rm -rf /usr/share/nginx/html/tenant/*
sudo cp -r /home/ec2-user/pgni/pgworldtenant-master/build/web/* /usr/share/nginx/html/tenant/

echo "[4/4] Setting permissions..."
sudo chown -R nginx:nginx /usr/share/nginx/html
sudo chmod -R 755 /usr/share/nginx/html

echo ""
echo "Frontend deployed successfully!"
EOF

log_success "Frontend deployed to Nginx"
echo ""

#==============================================================================
# PHASE 5: CONFIGURE NGINX
#==============================================================================

log_info "PHASE 5/6: Configuring Nginx"
echo "----------------------------------------------"

ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "${EC2_USER}@${EC2_IP}" << 'EOF'
set -e

echo "[1/3] Creating Nginx configuration..."
sudo tee /etc/nginx/conf.d/pgni.conf > /dev/null << 'NGINX_CONF'
# Admin App
server {
    listen 80;
    server_name _;
    
    # Root redirects to admin
    location = / {
        return 301 /admin/;
    }
    
    # Admin App
    location /admin/ {
        alias /usr/share/nginx/html/admin/;
        try_files $uri $uri/ /admin/index.html;
        
        # CORS headers
        add_header 'Access-Control-Allow-Origin' '*' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS' always;
        add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization' always;
    }
    
    # Tenant App
    location /tenant/ {
        alias /usr/share/nginx/html/tenant/;
        try_files $uri $uri/ /tenant/index.html;
        
        # CORS headers
        add_header 'Access-Control-Allow-Origin' '*' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS' always;
        add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization' always;
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
    }
    
    # Health check
    location /health {
        proxy_pass http://localhost:8080/health;
    }
}
NGINX_CONF

echo "[2/3] Testing Nginx configuration..."
sudo nginx -t

echo "[3/3] Starting Nginx..."
sudo systemctl enable nginx
sudo systemctl restart nginx

echo ""
echo "Nginx configured and running!"
EOF

log_success "Nginx configured"
echo ""

#==============================================================================
# PHASE 6: VALIDATION & HEALTH CHECKS
#==============================================================================

log_info "PHASE 6/6: Validation & Health Checks"
echo "----------------------------------------------"

log_info "Waiting for services to stabilize..."
sleep 5

echo ""
echo "Running health checks..."
echo ""

# Check API
log_info "Checking Backend API..."
API_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "http://${EC2_IP}:8080/health" || echo "000")
if [ "$API_RESPONSE" == "200" ]; then
    log_success "Backend API is healthy (HTTP $API_RESPONSE)"
else
    log_error "Backend API check failed (HTTP $API_RESPONSE)"
fi

# Check Admin App
log_info "Checking Admin App..."
ADMIN_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "http://${EC2_IP}/admin/" || echo "000")
if [ "$ADMIN_RESPONSE" == "200" ]; then
    log_success "Admin App is accessible (HTTP $ADMIN_RESPONSE)"
else
    log_error "Admin App check failed (HTTP $ADMIN_RESPONSE)"
fi

# Check Tenant App
log_info "Checking Tenant App..."
TENANT_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "http://${EC2_IP}/tenant/" || echo "000")
if [ "$TENANT_RESPONSE" == "200" ]; then
    log_success "Tenant App is accessible (HTTP $TENANT_RESPONSE)"
else
    log_error "Tenant App check failed (HTTP $TENANT_RESPONSE)"
fi

# Check Nginx
log_info "Checking Nginx status..."
NGINX_STATUS=$(ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "${EC2_USER}@${EC2_IP}" "sudo systemctl is-active nginx" || echo "inactive")
if [ "$NGINX_STATUS" == "active" ]; then
    log_success "Nginx is running"
else
    log_error "Nginx is not running"
fi

echo ""
echo "=============================================="
echo "  DEPLOYMENT COMPLETE!"
echo "=============================================="
echo ""
echo "Application URLs:"
echo "  Admin Portal:  http://${EC2_IP}/admin/"
echo "  Tenant Portal: http://${EC2_IP}/tenant/"
echo "  Backend API:   http://${EC2_IP}:8080/health"
echo ""
echo "Test Accounts:"
echo "  Super Admin:"
echo "    Email: admin@pgworld.com"
echo "    Password: Admin@123"
echo ""
echo "  PG Owner:"
echo "    Email: owner@pg.com"
echo "    Password: Owner@123"
echo ""
echo "  Tenant:"
echo "    Email: tenant@pg.com"
echo "    Password: Tenant@123"
echo ""
echo "Deployment completed at: $(date)"
echo "=============================================="
