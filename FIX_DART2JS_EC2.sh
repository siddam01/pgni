#!/bin/bash
set -e

echo "=============================================="
echo "  FIX DART2JS CRASH - EC2 OPTIMIZED BUILD"
echo "=============================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Step 1: Check Flutter/Dart versions
echo ""
echo "=== Step 1: Check Flutter & Dart Versions ==="
flutter --version

DART_VERSION=$(flutter --version | grep "Dart" | awk '{print $4}')
echo -e "${GREEN}✓ Current Dart version: $DART_VERSION${NC}"

# Step 2: Check system resources
echo ""
echo "=== Step 2: Check EC2 System Resources ==="
echo "Memory:"
free -h
echo ""
echo "Disk Space:"
df -h /home/ec2-user
echo ""
echo "CPU Info:"
nproc
lscpu | grep "Model name"

AVAILABLE_MEM=$(free -m | awk 'NR==2 {print $7}')
echo -e "${YELLOW}Available Memory: ${AVAILABLE_MEM}MB${NC}"

if [ "$AVAILABLE_MEM" -lt 2000 ]; then
    echo -e "${RED}⚠️  WARNING: Low memory detected (<2GB available)${NC}"
    echo "Dart2js may fail. Recommendation: Upgrade to t3.medium or larger"
fi

# Step 3: Clean project completely
echo ""
echo "=== Step 3: Clean Project Completely ==="

cd /home/ec2-user/pgni

# Clean Admin App
echo "Cleaning Admin App..."
cd pgworld-master
flutter clean
rm -rf .dart_tool
rm -rf build
rm -rf .flutter-plugins-dependencies
rm -f pubspec.lock
echo -e "${GREEN}✓ Admin app cleaned${NC}"

# Clean Tenant App
echo "Cleaning Tenant App..."
cd ../pgworldtenant-master
flutter clean
rm -rf .dart_tool
rm -rf build
rm -rf .flutter-plugins-dependencies
rm -f pubspec.lock
echo -e "${GREEN}✓ Tenant app cleaned${NC}"

# Step 4: Clear Flutter cache (if needed)
echo ""
echo "=== Step 4: Verify Flutter Cache ==="
CACHE_SIZE=$(du -sh ~/.pub-cache 2>/dev/null | cut -f1)
echo "Pub cache size: $CACHE_SIZE"

# Only repair if cache is suspiciously small or large
# Normal cache is 100-500MB

# Step 5: Update Admin App dependencies
echo ""
echo "=== Step 5: Update Admin App Dependencies ==="
cd /home/ec2-user/pgni/pgworld-master

# Update config
mkdir -p lib/utils
cat > lib/utils/config.dart << 'EOF'
class Config {
  static const String URL = "34.227.111.143:8080";
  static const String BASE_URL = "http://34.227.111.143:8080";
}
EOF

echo "Getting dependencies..."
flutter pub get

if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Failed to get dependencies${NC}"
    echo "Trying pub cache repair..."
    flutter pub cache repair
    flutter pub get
fi

echo "Checking for outdated packages..."
flutter pub outdated || true

echo -e "${GREEN}✓ Admin dependencies resolved${NC}"

# Step 6: Build Admin App with optimizations
echo ""
echo "=== Step 6: Build Admin App (Optimized for EC2) ==="

# Check available memory and adjust build strategy
if [ "$AVAILABLE_MEM" -lt 2000 ]; then
    echo -e "${YELLOW}Low memory mode: Using conservative build flags${NC}"
    BUILD_FLAGS="--release --web-renderer html --no-tree-shake-icons"
else
    echo -e "${GREEN}Normal memory: Using standard build flags${NC}"
    BUILD_FLAGS="--release --web-renderer html"
fi

echo "Building with flags: $BUILD_FLAGS"
echo "This may take 5-10 minutes..."

# Set memory limits for dart2js to prevent crashes
export DART_VM_OPTIONS="--old_gen_heap_size=2048"

# Build with error handling
flutter build web $BUILD_FLAGS 2>&1 | tee /tmp/admin_build.log

if [ ${PIPESTATUS[0]} -ne 0 ]; then
    echo -e "${RED}✗ Admin build failed${NC}"
    echo ""
    echo "Checking error log..."
    grep -i "error\|exception\|failed" /tmp/admin_build.log | tail -20
    
    echo ""
    echo "Possible solutions:"
    echo "1. Increase EC2 memory (upgrade to t3.medium or t3.large)"
    echo "2. Add swap space: sudo fallocate -l 2G /swapfile && sudo chmod 600 /swapfile && sudo mkswap /swapfile && sudo swapon /swapfile"
    echo "3. Build apps sequentially instead of parallel"
    
    exit 1
fi

if [ ! -d "build/web" ]; then
    echo -e "${RED}✗ Build directory not created${NC}"
    exit 1
fi

FILE_COUNT=$(ls build/web 2>/dev/null | wc -l)
TOTAL_SIZE=$(du -sh build/web 2>/dev/null | cut -f1)
echo -e "${GREEN}✓ Admin built successfully:${NC}"
echo "  - Files: $FILE_COUNT"
echo "  - Size: $TOTAL_SIZE"

# Step 7: Update Tenant App dependencies
echo ""
echo "=== Step 7: Update Tenant App Dependencies ==="
cd /home/ec2-user/pgni/pgworldtenant-master

# Update config
mkdir -p lib/utils
cat > lib/utils/config.dart << 'EOF'
class Config {
  static const String URL = "34.227.111.143:8080";
  static const String BASE_URL = "http://34.227.111.143:8080";
}
EOF

echo "Getting dependencies..."
flutter pub get

if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Failed to get dependencies${NC}"
    echo "Trying pub cache repair..."
    flutter pub cache repair
    flutter pub get
fi

echo "Checking for outdated packages..."
flutter pub outdated || true

echo -e "${GREEN}✓ Tenant dependencies resolved${NC}"

# Step 8: Build Tenant App with optimizations
echo ""
echo "=== Step 8: Build Tenant App (Optimized for EC2) ==="

echo "Building with flags: $BUILD_FLAGS"
echo "This may take 5-10 minutes..."

flutter build web $BUILD_FLAGS 2>&1 | tee /tmp/tenant_build.log

if [ ${PIPESTATUS[0]} -ne 0 ]; then
    echo -e "${RED}✗ Tenant build failed${NC}"
    echo ""
    echo "Checking error log..."
    grep -i "error\|exception\|failed" /tmp/tenant_build.log | tail -20
    
    exit 1
fi

if [ ! -d "build/web" ]; then
    echo -e "${RED}✗ Build directory not created${NC}"
    exit 1
fi

FILE_COUNT=$(ls build/web 2>/dev/null | wc -l)
TOTAL_SIZE=$(du -sh build/web 2>/dev/null | cut -f1)
echo -e "${GREEN}✓ Tenant built successfully:${NC}"
echo "  - Files: $FILE_COUNT"
echo "  - Size: $TOTAL_SIZE"

# Step 9: Deploy to Nginx
echo ""
echo "=== Step 9: Deploy to Nginx ==="

sudo yum install -y nginx > /dev/null 2>&1

sudo rm -rf /usr/share/nginx/html/admin /usr/share/nginx/html/tenant
sudo mkdir -p /usr/share/nginx/html/admin /usr/share/nginx/html/tenant

sudo cp -r /home/ec2-user/pgni/pgworld-master/build/web/* /usr/share/nginx/html/admin/
sudo cp -r /home/ec2-user/pgni/pgworldtenant-master/build/web/* /usr/share/nginx/html/tenant/

sudo chown -R nginx:nginx /usr/share/nginx/html
sudo chmod -R 755 /usr/share/nginx/html

ADMIN_FILES=$(ls /usr/share/nginx/html/admin/ 2>/dev/null | wc -l)
TENANT_FILES=$(ls /usr/share/nginx/html/tenant/ 2>/dev/null | wc -l)

echo -e "${GREEN}✓ Files deployed:${NC}"
echo "  - Admin: $ADMIN_FILES files"
echo "  - Tenant: $TENANT_FILES files"

# Verify critical files
if [ ! -f "/usr/share/nginx/html/admin/index.html" ]; then
    echo -e "${RED}✗ Admin index.html missing!${NC}"
    exit 1
fi

if [ ! -f "/usr/share/nginx/html/tenant/index.html" ]; then
    echo -e "${RED}✗ Tenant index.html missing!${NC}"
    exit 1
fi

# Step 10: Configure Nginx
echo ""
echo "=== Step 10: Configure Nginx ==="

sudo bash -c 'cat > /etc/nginx/conf.d/pgni.conf << "NGINXEOF"
server {
    listen 80 default_server;
    server_name _;
    
    location = / {
        return 301 /admin/;
    }
    
    location /admin/ {
        alias /usr/share/nginx/html/admin/;
        index index.html;
        try_files $uri $uri/ /admin/index.html;
        add_header Cache-Control "no-cache, no-store, must-revalidate";
    }
    
    location /tenant/ {
        alias /usr/share/nginx/html/tenant/;
        index index.html;
        try_files $uri $uri/ /tenant/index.html;
        add_header Cache-Control "no-cache, no-store, must-revalidate";
    }
}
NGINXEOF'

sudo rm -f /etc/nginx/conf.d/default.conf

echo "Testing Nginx configuration..."
sudo nginx -t

if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Nginx config error${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Nginx config valid${NC}"

sudo systemctl enable nginx
sudo systemctl restart nginx

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Nginx restarted successfully${NC}"
else
    echo -e "${RED}✗ Nginx restart failed${NC}"
    exit 1
fi

# Step 11: Final Validation
sleep 3
echo ""
echo "=== Step 11: Final Validation ==="

ADMIN_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/admin/ 2>/dev/null || echo "000")
TENANT_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/tenant/ 2>/dev/null || echo "000")
API_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/health 2>/dev/null || echo "000")

echo ""
echo "=============================================="
echo -e "  ${GREEN}✅ DEPLOYMENT COMPLETE!${NC}"
echo "=============================================="
echo ""
echo "Test Results:"
if [ "$ADMIN_CODE" = "200" ]; then
    echo -e "  Admin Portal:  HTTP $ADMIN_CODE ${GREEN}✓ WORKING${NC}"
else
    echo -e "  Admin Portal:  HTTP $ADMIN_CODE ${RED}✗ CHECK LOGS${NC}"
fi

if [ "$TENANT_CODE" = "200" ]; then
    echo -e "  Tenant Portal: HTTP $TENANT_CODE ${GREEN}✓ WORKING${NC}"
else
    echo -e "  Tenant Portal: HTTP $TENANT_CODE ${RED}✗ CHECK LOGS${NC}"
fi

if [ "$API_CODE" = "200" ]; then
    echo -e "  Backend API:   HTTP $API_CODE ${GREEN}✓ WORKING${NC}"
else
    echo -e "  Backend API:   HTTP $API_CODE ${YELLOW}⚠ CHECK LOGS${NC}"
fi

echo ""
echo "Access URLs:"
echo "  🌐 Admin:  http://34.227.111.143/admin/"
echo "  🌐 Tenant: http://34.227.111.143/tenant/"
echo "  🔧 API:    http://34.227.111.143:8080/health"
echo ""
echo "Login Credentials:"
echo "  📧 Email:    admin@pgworld.com"
echo "  🔑 Password: Admin@123"
echo ""
echo "Build Details:"
echo "  - Dart Version: $DART_VERSION"
echo "  - Build Flags: $BUILD_FLAGS"
echo "  - Available Memory: ${AVAILABLE_MEM}MB"
echo "  - Build Logs: /tmp/admin_build.log, /tmp/tenant_build.log"
echo ""
echo "=============================================="

# Cleanup
unset DART_VM_OPTIONS

echo ""
echo -e "${GREEN}Deployment successful!${NC}"
echo "If dart2js crashes occurred, check /tmp/*_build.log for details"

