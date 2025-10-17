#!/bin/bash
set -e

echo "════════════════════════════════════════════════════════"
echo "🚀 Building Flutter Web Apps (Direct on EC2)"
echo "════════════════════════════════════════════════════════"
echo ""

# Check resources
echo "1. Verifying system resources..."
TOTAL_RAM=$(free -h | awk 'NR==2{print $2}')
AVAILABLE_RAM=$(free -h | awk 'NR==2{print $7}')
DISK_AVAILABLE=$(df -h / | tail -1 | awk '{print $4}')
CPU_COUNT=$(nproc)
INSTANCE_TYPE=$(ec2-metadata --instance-type 2>/dev/null | awk '{print $2}' || echo "unknown")

echo "   Instance: $INSTANCE_TYPE"
echo "   RAM: $TOTAL_RAM (Available: $AVAILABLE_RAM)"
echo "   CPUs: $CPU_COUNT"
echo "   Disk Available: $DISK_AVAILABLE"
echo "   ✓ Resources are excellent!"
echo ""

# Upgrade Flutter
echo "2. Upgrading Flutter to latest stable..."
cd /opt/flutter
sudo git fetch --all --tags 2>&1 | tail -1
sudo git checkout stable 2>&1 | tail -1
sudo git pull origin stable 2>&1 | tail -1

FLUTTER_VERSION=$(flutter --version 2>&1 | head -1)
DART_VERSION=$(dart --version 2>&1 | head -1)
echo "   ✓ $FLUTTER_VERSION"
echo "   ✓ $DART_VERSION"
echo ""

# Build Admin App
echo "3. Building Admin App..."
echo "   ════════════════════════════════════════"
cd /home/ec2-user/pgni/pgworld-master

echo "   Cleaning..."
flutter clean > /dev/null 2>&1
rm -rf .dart_tool build

echo "   Upgrading dependencies..."
flutter pub upgrade 2>&1 | tail -5

echo ""
echo "   🏗️  Compiling Admin App..."
START_TIME=$(date +%s)

export DART_VM_OPTIONS="--old_gen_heap_size=6144"
export PUB_CACHE=/home/ec2-user/.pub-cache

flutter build web --release \
  --no-source-maps \
  --dart-define=dart.vm.product=true \
  --no-tree-shake-icons

END_TIME=$(date +%s)
BUILD_TIME=$((END_TIME - START_TIME))
BUILD_MIN=$((BUILD_TIME / 60))
BUILD_SEC=$((BUILD_TIME % 60))

if [ -f "build/web/main.dart.js" ]; then
    ADMIN_SIZE=$(du -h build/web/main.dart.js | cut -f1)
    echo ""
    echo "   ✅ Admin: Success! (${ADMIN_SIZE}, ${BUILD_MIN}m ${BUILD_SEC}s)"
else
    echo ""
    echo "   ❌ Admin build failed!"
    exit 1
fi
echo ""

# Build Tenant App (with better error handling)
echo "4. Building Tenant App..."
echo "   ════════════════════════════════════════"
cd /home/ec2-user/pgni/pgworldtenant-master

echo "   Cleaning..."
flutter clean > /dev/null 2>&1
rm -rf .dart_tool build

echo "   Upgrading dependencies..."
flutter pub upgrade 2>&1 | tail -5

echo ""
echo "   🏗️  Compiling Tenant App..."
echo ""
START_TIME=$(date +%s)

# Capture full output to diagnose the error
flutter build web --release \
  --no-source-maps \
  --dart-define=dart.vm.product=true \
  --no-tree-shake-icons 2>&1 | tee /tmp/tenant_build.log

END_TIME=$(date +%s)
BUILD_TIME=$((END_TIME - START_TIME))
BUILD_MIN=$((BUILD_TIME / 60))
BUILD_SEC=$((BUILD_TIME % 60))

if [ -f "build/web/main.dart.js" ]; then
    TENANT_SIZE=$(du -h build/web/main.dart.js | cut -f1)
    echo ""
    echo "   ✅ Tenant: Success! (${TENANT_SIZE}, ${BUILD_MIN}m ${BUILD_SEC}s)"
else
    echo ""
    echo "   ❌ Tenant build failed!"
    echo ""
    echo "   Showing last 50 lines of build log:"
    echo "   ════════════════════════════════════════"
    tail -50 /tmp/tenant_build.log
    echo ""
    echo "   Full log saved to: /tmp/tenant_build.log"
    echo ""
    
    # Check for common errors
    if grep -q "web-0.3.0" /tmp/tenant_build.log; then
        echo "   🔍 Detected: Old 'web' package issue"
        echo "   Trying fix: Removing old web package cache..."
        rm -rf ~/.pub-cache/hosted/pub.dev/web-0.3.0
        echo "   Retrying build..."
        flutter build web --release \
          --no-source-maps \
          --dart-define=dart.vm.product=true \
          --no-tree-shake-icons
        
        if [ -f "build/web/main.dart.js" ]; then
            TENANT_SIZE=$(du -h build/web/main.dart.js | cut -f1)
            echo "   ✅ Tenant: Success after retry! (${TENANT_SIZE})"
        else
            echo "   ❌ Retry failed. Manual investigation needed."
            exit 1
        fi
    else
        exit 1
    fi
fi
echo ""

# Deploy to Nginx
echo "5. Deploying to Nginx..."
echo "   ════════════════════════════════════════"
sudo rm -rf /usr/share/nginx/html/admin /usr/share/nginx/html/tenant
sudo mkdir -p /usr/share/nginx/html/admin /usr/share/nginx/html/tenant
sudo cp -r /home/ec2-user/pgni/pgworld-master/build/web/* /usr/share/nginx/html/admin/
sudo cp -r /home/ec2-user/pgni/pgworldtenant-master/build/web/* /usr/share/nginx/html/tenant/
sudo chown -R nginx:nginx /usr/share/nginx/html
sudo chmod -R 755 /usr/share/nginx/html
sudo find /usr/share/nginx/html -type f -exec chmod 644 {} \;

if command -v getenforce &> /dev/null && [ "$(getenforce)" = "Enforcing" ]; then
    sudo chcon -R -t httpd_sys_content_t /usr/share/nginx/html
fi

sudo systemctl reload nginx
echo "   ✓ Deployed!"
echo ""

# Verify
echo "6. Verifying deployment..."
ADMIN_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/admin/)
TENANT_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/tenant/)
API_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/health)

ADMIN_JS=$(ls -lh /usr/share/nginx/html/admin/main.dart.js 2>/dev/null | awk '{print $5}')
TENANT_JS=$(ls -lh /usr/share/nginx/html/tenant/main.dart.js 2>/dev/null | awk '{print $5}')

echo "   Admin:  HTTP $ADMIN_STATUS (main.dart.js: $ADMIN_JS)"
echo "   Tenant: HTTP $TENANT_STATUS (main.dart.js: $TENANT_JS)"
echo "   API:    HTTP $API_STATUS"
echo ""

if [ "$ADMIN_STATUS" = "200" ] && [ "$TENANT_STATUS" = "200" ]; then
    echo "════════════════════════════════════════════════════════"
    echo "🎉 DEPLOYMENT COMPLETE!"
    echo "════════════════════════════════════════════════════════"
    echo ""
    echo "🌐 Access Your Apps:"
    echo "   http://34.227.111.143/admin/"
    echo "   http://34.227.111.143/tenant/"
    echo ""
    echo "🔐 Login:"
    echo "   Email:    admin@pgworld.com"
    echo "   Password: Admin@123"
    echo ""
else
    echo "⚠️ Deployment completed but HTTP status is not 200"
    echo "Please check Nginx logs: sudo tail -50 /var/log/nginx/error.log"
fi

