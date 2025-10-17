#!/bin/bash
echo "════════════════════════════════════════════════════════"
echo "Fixing Web Package Compatibility & Building Flutter Apps"
echo "════════════════════════════════════════════════════════"
echo ""

# Step 1: Upgrade Flutter to latest stable
echo "1. Upgrading Flutter to latest stable..."
cd /opt/flutter
git fetch --all --tags
git checkout stable
git pull origin stable
flutter doctor -v

echo ""
echo "✓ Flutter upgraded to: $(flutter --version | head -1)"
echo ""

# Step 2: Clean and rebuild Admin app
echo "2. Rebuilding Admin App with upgraded Flutter..."
cd /home/ec2-user/pgni/pgworld-master

# Clean everything
flutter clean
rm -rf .dart_tool build
rm -rf ~/.pub-cache/hosted/pub.dev/web-*

# Update dependencies to latest compatible versions
echo ""
echo "Upgrading dependencies..."
flutter pub upgrade

# Build with latest Flutter
echo ""
echo "Building Admin app (this may take 10-15 minutes)..."
export DART_VM_OPTIONS="--old_gen_heap_size=1024"
export PUB_CACHE=/home/ec2-user/.pub-cache

flutter build web --release \
  --no-source-maps \
  --dart-define=dart.vm.product=true \
  --no-tree-shake-icons

if [ -f "build/web/main.dart.js" ]; then
    ADMIN_SIZE=$(du -h build/web/main.dart.js | cut -f1)
    echo "✓ Admin build complete! (main.dart.js: $ADMIN_SIZE)"
else
    echo "❌ Admin build failed - main.dart.js not found!"
    exit 1
fi

# Step 3: Clean and rebuild Tenant app
echo ""
echo "3. Rebuilding Tenant App..."
cd /home/ec2-user/pgni/pgworldtenant-master

flutter clean
rm -rf .dart_tool build
rm -rf ~/.pub-cache/hosted/pub.dev/web-*

echo ""
echo "Upgrading dependencies..."
flutter pub upgrade

echo ""
echo "Building Tenant app (this may take 10-15 minutes)..."
flutter build web --release \
  --no-source-maps \
  --dart-define=dart.vm.product=true \
  --no-tree-shake-icons

if [ -f "build/web/main.dart.js" ]; then
    TENANT_SIZE=$(du -h build/web/main.dart.js | cut -f1)
    echo "✓ Tenant build complete! (main.dart.js: $TENANT_SIZE)"
else
    echo "❌ Tenant build failed - main.dart.js not found!"
    exit 1
fi

# Step 4: Deploy to Nginx
echo ""
echo "4. Deploying to Nginx..."
sudo rm -rf /usr/share/nginx/html/admin /usr/share/nginx/html/tenant
sudo mkdir -p /usr/share/nginx/html/admin /usr/share/nginx/html/tenant
sudo cp -r /home/ec2-user/pgni/pgworld-master/build/web/* /usr/share/nginx/html/admin/
sudo cp -r /home/ec2-user/pgni/pgworldtenant-master/build/web/* /usr/share/nginx/html/tenant/
sudo chown -R nginx:nginx /usr/share/nginx/html
sudo chmod -R 755 /usr/share/nginx/html
sudo find /usr/share/nginx/html -type f -exec chmod 644 {} \;

# Fix SELinux if enabled
if command -v getenforce &> /dev/null && [ "$(getenforce)" = "Enforcing" ]; then
    echo "Fixing SELinux context..."
    sudo chcon -R -t httpd_sys_content_t /usr/share/nginx/html
fi

sudo systemctl reload nginx

# Step 5: Verify deployment
echo ""
echo "5. Verifying deployment..."
if [ -f "/usr/share/nginx/html/admin/main.dart.js" ]; then
    DEPLOYED_SIZE=$(du -h /usr/share/nginx/html/admin/main.dart.js | cut -f1)
    echo "✓ Admin deployed ($DEPLOYED_SIZE)"
else
    echo "❌ Admin deployment failed!"
    exit 1
fi

if [ -f "/usr/share/nginx/html/tenant/main.dart.js" ]; then
    DEPLOYED_SIZE=$(du -h /usr/share/nginx/html/tenant/main.dart.js | cut -f1)
    echo "✓ Tenant deployed ($DEPLOYED_SIZE)"
else
    echo "❌ Tenant deployment failed!"
    exit 1
fi

# Test URLs
ADMIN_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/admin/)
TENANT_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/tenant/)

echo ""
echo "════════════════════════════════════════════════════════"
echo "✅ DEPLOYMENT COMPLETE!"
echo "════════════════════════════════════════════════════════"
echo ""
echo "🌐 Access Your Apps:"
echo "   Admin:  http://34.227.111.143/admin/  (HTTP $ADMIN_STATUS)"
echo "   Tenant: http://34.227.111.143/tenant/ (HTTP $TENANT_STATUS)"
echo ""
echo "🔐 Test Login:"
echo "   Email:    admin@pgworld.com"
echo "   Password: Admin@123"
echo ""
echo "📊 Flutter Version:"
flutter --version | head -1
echo ""
echo "⏱️  Build Time: ~20-30 minutes on t3.micro"
echo "💡 Tip: Upgrade to t3.medium for 5x faster builds!"
echo ""

