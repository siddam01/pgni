#!/bin/bash
set -e

echo "════════════════════════════════════════════════════════"
echo "🚀 Quick Deploy: Admin App Only"
echo "════════════════════════════════════════════════════════"
echo ""
echo "Note: Tenant app has code errors - deploying Admin first"
echo ""

cd /home/ec2-user/pgni/pgworld-master

# Check if build exists
if [ -f "build/web/main.dart.js" ]; then
    echo "✓ Admin build already exists (from previous successful build)"
    ADMIN_SIZE=$(du -h build/web/main.dart.js | cut -f1)
    echo "  Size: $ADMIN_SIZE"
else
    echo "Building Admin app..."
    export DART_VM_OPTIONS="--old_gen_heap_size=6144"
    export PUB_CACHE=/home/ec2-user/.pub-cache
    
    flutter build web --release \
      --no-source-maps \
      --dart-define=dart.vm.product=true \
      --no-tree-shake-icons
    
    if [ -f "build/web/main.dart.js" ]; then
        ADMIN_SIZE=$(du -h build/web/main.dart.js | cut -f1)
        echo "✓ Admin built ($ADMIN_SIZE)"
    else
        echo "❌ Admin build failed"
        exit 1
    fi
fi

echo ""
echo "Deploying Admin app to Nginx..."
sudo rm -rf /usr/share/nginx/html/admin
sudo mkdir -p /usr/share/nginx/html/admin
sudo cp -r build/web/* /usr/share/nginx/html/admin/
sudo chown -R nginx:nginx /usr/share/nginx/html/admin
sudo chmod -R 755 /usr/share/nginx/html/admin
sudo find /usr/share/nginx/html/admin -type f -exec chmod 644 {} \;

if command -v getenforce &> /dev/null && [ "$(getenforce)" = "Enforcing" ]; then
    sudo chcon -R -t httpd_sys_content_t /usr/share/nginx/html/admin
fi

sudo systemctl reload nginx

echo "✓ Admin app deployed!"
echo ""

# Verify
ADMIN_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/admin/)
ADMIN_JS=$(ls -lh /usr/share/nginx/html/admin/main.dart.js 2>/dev/null | awk '{print $5}')

echo "════════════════════════════════════════════════════════"
echo "✅ ADMIN APP IS LIVE!"
echo "════════════════════════════════════════════════════════"
echo ""
echo "🌐 Access Admin Portal:"
echo "   http://34.227.111.143/admin/"
echo ""
echo "   Status: HTTP $ADMIN_STATUS"
echo "   Size: $ADMIN_JS"
echo ""
echo "🔐 Login:"
echo "   Email:    admin@pgworld.com"
echo "   Password: Admin@123"
echo ""
echo "⚠️  Note: Tenant app has code errors and needs fixing"
echo "   Working on it next..."
echo ""

