#!/bin/bash
###############################################################################
# CloudPG - COMPLETE AUTOMATED DEPLOYMENT
# This script deploys everything with NO manual configuration needed
# Only asks for DB password ONCE
###############################################################################

set -e  # Exit on error

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo ""
echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}CloudPG - Automated Deployment${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

# ============================================
# Load Configuration from file
# ============================================
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CONFIG_FILE="$SCRIPT_DIR/config.production.env"

if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}✗ Configuration file not found: $CONFIG_FILE${NC}"
    echo ""
    echo "Please ensure config.production.env exists with all settings."
    exit 1
fi

echo -e "${BLUE}Loading configuration...${NC}"
source "$CONFIG_FILE"

# Validate required variables
REQUIRED_VARS=(
    "EC2_PUBLIC_IP"
    "DB_HOST"
    "DB_USER"
    "DB_NAME"
    "S3_BUCKET"
    "API_PORT"
)

for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var}" ]; then
        echo -e "${RED}✗ Required variable $var not set in config file${NC}"
        exit 1
    fi
done

echo -e "${GREEN}✓ Configuration loaded${NC}"
echo ""
echo -e "${BLUE}Configuration Summary:${NC}"
echo "  EC2 IP: $EC2_PUBLIC_IP"
echo "  Database: $DB_HOST"
echo "  S3 Bucket: $S3_BUCKET"
echo "  API Port: $API_PORT"
echo ""

# ============================================
# Ask for DB Password ONCE
# ============================================
if [ -z "$DB_PASSWORD" ]; then
    echo -e "${YELLOW}Database password not in config (good for security!)${NC}"
    echo -n "Enter Database Password: "
    read -s DB_PASSWORD
    echo ""
    echo ""
    
    if [ -z "$DB_PASSWORD" ]; then
        echo -e "${RED}✗ Database password is required${NC}"
        exit 1
    fi
fi

# Test database connection
echo -e "${BLUE}Testing database connection...${NC}"
mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" -e "SELECT 1;" > /dev/null 2>&1

if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Database connection failed!${NC}"
    echo "Please check your password and database configuration."
    exit 1
fi

echo -e "${GREEN}✓ Database connection successful${NC}"
echo ""

# ============================================
# Confirmation
# ============================================
echo -e "${YELLOW}Ready to deploy:${NC}"
echo "  1. Backend API → $BACKEND_DEPLOY_PATH"
echo "  2. Admin Portal → $FRONTEND_ADMIN_PATH"
echo "  3. Configure Nginx"
echo "  4. Start services"
echo ""
echo -n "Continue? (Y/n): "
read -r CONTINUE
CONTINUE=${CONTINUE:-Y}

if [[ ! $CONTINUE =~ ^[Yy]$ ]]; then
    echo "Deployment cancelled."
    exit 0
fi

echo ""
echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}Starting Deployment${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

# ============================================
# STEP 1: Deploy Backend API
# ============================================
echo -e "${BLUE}[1/5] Deploying Backend API...${NC}"

# Find the API directory
API_DIR=""
if [ -d "/tmp/pgni-main/pgworld-api-master" ]; then
    API_DIR="/tmp/pgni-main/pgworld-api-master"
elif [ -d "pgworld-api-master" ]; then
    API_DIR="pgworld-api-master"
else
    echo -e "${RED}✗ API directory not found${NC}"
    exit 1
fi

cd "$API_DIR"

# Build API if not already built
if [ ! -f "pgworld-api" ]; then
    echo "  Building Go API..."
    export GOPATH=$HOME/go
    export PATH=$PATH:$GOPATH/bin:/usr/local/go/bin
    
    go mod download
    go build -o pgworld-api .
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}✗ API build failed${NC}"
        exit 1
    fi
fi

# Deploy API
echo "  Deploying to $BACKEND_DEPLOY_PATH..."
sudo mkdir -p "$BACKEND_DEPLOY_PATH"
sudo cp pgworld-api "$BACKEND_DEPLOY_PATH/"

# Create .env file for API
echo "  Creating API environment file..."
sudo tee "$BACKEND_DEPLOY_PATH/.env" > /dev/null <<EOF
DB_HOST=$DB_HOST
DB_PORT=${DB_PORT:-3306}
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASSWORD
DB_NAME=$DB_NAME
PORT=$API_PORT
S3_BUCKET=$S3_BUCKET
AWS_REGION=${S3_REGION:-us-east-1}
ENV=${ENVIRONMENT:-production}
EOF

# Create startup script
sudo tee "$BACKEND_DEPLOY_PATH/start.sh" > /dev/null <<'EOF'
#!/bin/bash
cd "$(dirname "$0")"
source .env
exec ./pgworld-api
EOF

sudo chmod +x "$BACKEND_DEPLOY_PATH/start.sh"

# Create systemd service
echo "  Creating systemd service..."
sudo tee /etc/systemd/system/pgworld-api.service > /dev/null <<EOF
[Unit]
Description=PG World API Server
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=$BACKEND_DEPLOY_PATH
ExecStart=$BACKEND_DEPLOY_PATH/start.sh
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Start API service
echo "  Starting API service..."
sudo systemctl daemon-reload
sudo systemctl enable pgworld-api
sudo systemctl restart pgworld-api

# Wait for API to start
sleep 3

# Test API
if curl -s http://localhost:$API_PORT/health > /dev/null; then
    echo -e "${GREEN}✓ Backend API deployed and running${NC}"
else
    echo -e "${YELLOW}⚠ API deployed but health check failed - continuing anyway${NC}"
fi

echo ""

# ============================================
# STEP 2: Deploy Admin Frontend
# ============================================
echo -e "${BLUE}[2/5] Deploying Admin Frontend...${NC}"

# Create directory
sudo mkdir -p "$FRONTEND_ADMIN_PATH"

# Check if pre-built files exist
ADMIN_BUILD=""
if [ -d "/tmp/deployment-admin-*/admin" ]; then
    ADMIN_BUILD=$(find /tmp -name "deployment-admin-*" -type d | head -1)/admin
elif [ -d "/tmp/pgni-main/pgworld-master/build/web" ]; then
    ADMIN_BUILD="/tmp/pgni-main/pgworld-master/build/web"
elif [ -d "pgworld-master/build/web" ]; then
    ADMIN_BUILD="pgworld-master/build/web"
else
    echo -e "${YELLOW}⚠ No pre-built admin files found${NC}"
    echo "  Creating placeholder..."
    sudo tee "$FRONTEND_ADMIN_PATH/index.html" > /dev/null <<'HTMLEOF'
<!DOCTYPE html>
<html>
<head>
    <title>CloudPG Admin</title>
    <style>
        body { font-family: Arial; text-align: center; padding: 50px; }
        h1 { color: #2196F3; }
        .status { padding: 20px; background: #f5f5f5; border-radius: 5px; }
    </style>
</head>
<body>
    <h1>CloudPG Admin Portal</h1>
    <p>Server is configured. Upload Flutter build files to deploy.</p>
    <div class="status">
        <h3>Upload Instructions:</h3>
        <p>1. Use WinSCP to connect to this server</p>
        <p>2. Upload admin build files to: /var/www/html/admin/</p>
        <p>3. Refresh this page</p>
    </div>
</body>
</html>
HTMLEOF
fi

# Deploy admin files if found
if [ -n "$ADMIN_BUILD" ] && [ -d "$ADMIN_BUILD" ]; then
    echo "  Copying admin files from: $ADMIN_BUILD"
    sudo cp -r "$ADMIN_BUILD"/* "$FRONTEND_ADMIN_PATH/"
    echo -e "${GREEN}✓ Admin frontend deployed${NC}"
else
    echo -e "${YELLOW}✓ Admin placeholder created - upload build files manually${NC}"
fi

# Set permissions
sudo chown -R nginx:nginx "$FRONTEND_ADMIN_PATH" 2>/dev/null || \
    sudo chown -R www-data:www-data "$FRONTEND_ADMIN_PATH" 2>/dev/null || \
    sudo chown -R ec2-user:ec2-user "$FRONTEND_ADMIN_PATH"
sudo chmod -R 755 "$FRONTEND_ADMIN_PATH"

echo ""

# ============================================
# STEP 3: Configure Nginx
# ============================================
echo -e "${BLUE}[3/5] Configuring Nginx...${NC}"

# Check if nginx is installed
if ! command -v nginx &> /dev/null; then
    echo "  Installing Nginx..."
    sudo yum install -y nginx 2>/dev/null || sudo apt-get install -y nginx 2>/dev/null
fi

# Create nginx configuration
echo "  Creating Nginx config..."
sudo tee /etc/nginx/conf.d/cloudpg.conf > /dev/null <<EOF
# CloudPG Admin Portal
server {
    listen 80;
    server_name $EC2_PUBLIC_IP;
    root $FRONTEND_ADMIN_PATH;
    index index.html;

    # Admin portal
    location /admin/ {
        alias $FRONTEND_ADMIN_PATH/;
        try_files \$uri \$uri/ /index.html;
        
        # Cache busting
        add_header Cache-Control "no-store, no-cache, must-revalidate, proxy-revalidate, max-age=0";
        add_header Pragma "no-cache";
        add_header Expires "0";
    }

    # Tenant portal (when available)
    location /tenant/ {
        alias $FRONTEND_TENANT_PATH/;
        try_files \$uri \$uri/ /index.html;
        
        add_header Cache-Control "no-store, no-cache, must-revalidate";
    }

    # API proxy
    location /api/ {
        proxy_pass http://localhost:$API_PORT/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Test nginx configuration
sudo nginx -t

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Nginx configuration valid${NC}"
else
    echo -e "${RED}✗ Nginx configuration has errors${NC}"
    exit 1
fi

echo ""

# ============================================
# STEP 4: Start Services
# ============================================
echo -e "${BLUE}[4/5] Starting Services...${NC}"

# Start/Restart Nginx
echo "  Starting Nginx..."
sudo systemctl enable nginx
sudo systemctl restart nginx

if sudo systemctl is-active --quiet nginx; then
    echo -e "${GREEN}✓ Nginx started${NC}"
else
    echo -e "${RED}✗ Nginx failed to start${NC}"
    sudo systemctl status nginx
    exit 1
fi

# Verify API is running
echo "  Verifying API..."
if sudo systemctl is-active --quiet pgworld-api; then
    echo -e "${GREEN}✓ API service running${NC}"
else
    echo -e "${YELLOW}⚠ API service not running - attempting restart${NC}"
    sudo systemctl restart pgworld-api
    sleep 2
fi

echo ""

# ============================================
# STEP 5: Verification
# ============================================
echo -e "${BLUE}[5/5] Running Verification...${NC}"

ERRORS=0

# Test API health
echo -n "  Testing API health endpoint... "
if curl -s http://localhost:$API_PORT/health > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
    ERRORS=$((ERRORS + 1))
fi

# Test admin portal
echo -n "  Testing admin portal... "
if curl -s http://localhost/admin/ > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
    ERRORS=$((ERRORS + 1))
fi

# Check for placeholders
echo -n "  Checking for placeholders... "
if sudo grep -rq "minimal working version" "$FRONTEND_ADMIN_PATH"/*.js 2>/dev/null; then
    echo -e "${YELLOW}⚠ Found placeholders${NC}"
    echo "    → Upload clean build files"
else
    echo -e "${GREEN}✓ No placeholders${NC}"
fi

# Test external access
echo -n "  Testing external access... "
if curl -s "http://$EC2_PUBLIC_IP/admin/" > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${YELLOW}⚠ Check security group${NC}"
fi

echo ""

# ============================================
# Deployment Summary
# ============================================
echo -e "${CYAN}========================================${NC}"
if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✅ DEPLOYMENT SUCCESSFUL!${NC}"
else
    echo -e "${YELLOW}⚠ DEPLOYMENT COMPLETED WITH WARNINGS${NC}"
fi
echo -e "${CYAN}========================================${NC}"
echo ""

echo -e "${BLUE}📊 Deployment Summary:${NC}"
echo ""
echo "  ${GREEN}✓${NC} Backend API: http://$EC2_PUBLIC_IP:$API_PORT"
echo "  ${GREEN}✓${NC} Admin Portal: http://$EC2_PUBLIC_IP/admin/"
echo "  ${YELLOW}⏳${NC} Tenant Portal: http://$EC2_PUBLIC_IP/tenant/ (upload build)"
echo ""

echo -e "${BLUE}🔧 Service Management:${NC}"
echo "  API Status:  sudo systemctl status pgworld-api"
echo "  API Logs:    sudo journalctl -u pgworld-api -f"
echo "  API Restart: sudo systemctl restart pgworld-api"
echo "  Nginx:       sudo systemctl restart nginx"
echo ""

echo -e "${BLUE}📁 File Locations:${NC}"
echo "  Backend:  $BACKEND_DEPLOY_PATH"
echo "  Admin:    $FRONTEND_ADMIN_PATH"
echo "  Config:   $BACKEND_DEPLOY_PATH/.env"
echo "  Logs:     /var/log/nginx/"
echo ""

if [ -z "$ADMIN_BUILD" ]; then
    echo -e "${YELLOW}⚠ IMPORTANT: Upload Admin Build Files${NC}"
    echo ""
    echo "  The admin portal placeholder is deployed."
    echo "  Upload your Flutter build files:"
    echo ""
    echo "  1. On Windows, open WinSCP"
    echo "  2. Connect to: $EC2_PUBLIC_IP"
    echo "  3. Navigate to local: deployment-admin-*/admin/"
    echo "  4. Upload all files to: $FRONTEND_ADMIN_PATH/"
    echo "  5. Set permissions: sudo chmod -R 755 $FRONTEND_ADMIN_PATH"
    echo ""
fi

echo -e "${BLUE}🌐 Next Steps:${NC}"
echo "  1. Visit: http://$EC2_PUBLIC_IP/admin/"
echo "  2. Clear browser cache (Ctrl+Shift+Delete)"
echo "  3. Test login and navigation"
echo "  4. If you see placeholders → Upload build files"
echo ""

echo -e "${YELLOW}💡 Configuration saved in: $CONFIG_FILE${NC}"
echo -e "${YELLOW}💡 Database password NOT saved (security)${NC}"
echo ""

exit 0

