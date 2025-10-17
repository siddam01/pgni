#!/bin/bash
set -e

echo "════════════════════════════════════════════════════════"
echo "🚀 DEPLOYING ADMIN APP (Already Built Successfully)"
echo "════════════════════════════════════════════════════════"
echo ""

PUBLIC_IP="13.221.117.236"

# The Admin app is already built in /home/ec2-user/pgni/pgworld-master/build/web
cd /home/ec2-user/pgni/pgworld-master

if [ ! -d "build/web" ] || [ ! -f "build/web/main.dart.js" ]; then
    echo "❌ Admin build not found! Please run the full build script first."
    exit 1
fi

echo "✓ Admin build verified"
ADMIN_SIZE=$(du -h build/web/main.dart.js | cut -f1)
ADMIN_FILES=$(ls -1 build/web | wc -l)
echo "  Size: $ADMIN_SIZE | Files: $ADMIN_FILES"

echo ""
echo "Backing up old deployment..."
if [ -d "/usr/share/nginx/html/admin" ]; then
    sudo mv /usr/share/nginx/html/admin /usr/share/nginx/html/admin.backup.$(date +%s) 2>/dev/null || true
    echo "✓ Backup created"
fi

echo ""
echo "Deploying Admin app to Nginx..."
sudo mkdir -p /usr/share/nginx/html/admin
sudo cp -r build/web/* /usr/share/nginx/html/admin/

echo ""
echo "Setting permissions..."
sudo chown -R nginx:nginx /usr/share/nginx/html/admin
sudo chmod -R 755 /usr/share/nginx/html/admin
sudo find /usr/share/nginx/html/admin -type f -exec chmod 644 {} \;

# SELinux
if command -v getenforce &> /dev/null && [ "$(getenforce)" != "Disabled" ]; then
    sudo chcon -R -t httpd_sys_content_t /usr/share/nginx/html/admin 2>/dev/null || true
    echo "✓ SELinux context fixed"
fi

echo ""
echo "Reloading Nginx..."
sudo systemctl reload nginx

sleep 2

echo ""
echo "Testing deployment..."
ADMIN_TEST=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/admin/)

echo ""
echo "════════════════════════════════════════════════════════"
if [ "$ADMIN_TEST" = "200" ]; then
    echo "✅ ADMIN APP DEPLOYED SUCCESSFULLY!"
else
    echo "⚠️  ADMIN APP HTTP STATUS: $ADMIN_TEST"
fi
echo "════════════════════════════════════════════════════════"
echo ""
echo "🌐 Access Admin Portal:"
echo "   URL:      http://$PUBLIC_IP/admin/"
echo "   Email:    admin@pgworld.com"
echo "   Password: Admin@123"
echo ""
echo "⚡ IMPORTANT:"
echo "   • Hard refresh: Ctrl + Shift + R (Windows)"
echo "   • Or use Incognito mode"
echo ""
echo "════════════════════════════════════════════════════════"

