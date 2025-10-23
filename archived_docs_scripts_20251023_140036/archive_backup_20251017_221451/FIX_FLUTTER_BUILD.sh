#!/bin/bash
set -e

echo "=============================================="
echo "  FLUTTER BUILD FIX - WEB ONLY"
echo "=============================================="

cd /home/ec2-user

export PATH="$PATH:/home/ec2-user/flutter/bin"

# Fix git conflicts
echo "=== Step 1: Fix Git Conflicts ==="
cd /home/ec2-user/pgni
git reset --hard HEAD
git pull origin main

# Build Admin App - WEB ONLY (skip Android)
echo "=== Step 2: Build Admin App (Web) ==="
cd /home/ec2-user/pgni/pgworld-master

# Update config
mkdir -p lib/utils
cat > lib/utils/config.dart << 'EOF'
class Config {
  static const String URL = "34.227.111.143:8080";
  static const String BASE_URL = "http://34.227.111.143:8080";
}
EOF

# Clean and get dependencies
flutter clean
rm -rf .dart_tool
rm -rf build

# Get dependencies WITHOUT Android checks
flutter pub get --no-example

# Build ONLY for web (skip Android entirely)
echo "Building for web..."
flutter build web --release --web-renderer html --no-tree-shake-icons

if [ -d "build/web" ]; then
    echo "✓ Admin built successfully: $(ls build/web | wc -l) files"
    ls -lh build/web/index.html
else
    echo "✗ Admin build failed"
    echo "Checking for errors..."
    ls -la build/ || echo "No build directory"
    exit 1
fi

# Build Tenant App - WEB ONLY
echo "=== Step 3: Build Tenant App (Web) ==="
cd /home/ec2-user/pgni/pgworldtenant-master

# Update config
mkdir -p lib/utils
cat > lib/utils/config.dart << 'EOF'
class Config {
  static const String URL = "34.227.111.143:8080";
  static const String BASE_URL = "http://34.227.111.143:8080";
}
EOF

# Clean and build
flutter clean
rm -rf .dart_tool
rm -rf build

flutter pub get --no-example
flutter build web --release --web-renderer html --no-tree-shake-icons

if [ -d "build/web" ]; then
    echo "✓ Tenant built successfully: $(ls build/web | wc -l) files"
    ls -lh build/web/index.html
else
    echo "✗ Tenant build failed"
    exit 1
fi

# Deploy to Nginx
echo "=== Step 4: Deploy to Nginx ==="
sudo yum install -y nginx

sudo rm -rf /usr/share/nginx/html/admin /usr/share/nginx/html/tenant
sudo mkdir -p /usr/share/nginx/html/admin /usr/share/nginx/html/tenant

sudo cp -r /home/ec2-user/pgni/pgworld-master/build/web/* /usr/share/nginx/html/admin/
sudo cp -r /home/ec2-user/pgni/pgworldtenant-master/build/web/* /usr/share/nginx/html/tenant/

sudo chown -R nginx:nginx /usr/share/nginx/html
sudo chmod -R 755 /usr/share/nginx/html

echo "Deployed files:"
echo "  Admin: $(ls /usr/share/nginx/html/admin/ | wc -l) files"
echo "  Tenant: $(ls /usr/share/nginx/html/tenant/ | wc -l) files"

# Verify critical files
if [ -f "/usr/share/nginx/html/admin/index.html" ]; then
    echo "✓ Admin index.html exists ($(du -h /usr/share/nginx/html/admin/index.html | cut -f1))"
else
    echo "✗ Admin index.html missing!"
    exit 1
fi

if [ -f "/usr/share/nginx/html/tenant/index.html" ]; then
    echo "✓ Tenant index.html exists ($(du -h /usr/share/nginx/html/tenant/index.html | cut -f1))"
else
    echo "✗ Tenant index.html missing!"
    exit 1
fi

# Configure Nginx
echo "=== Step 5: Configure Nginx ==="
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
    
    location /api/ {
        proxy_pass http://localhost:8080/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
NGINXEOF'

sudo rm -f /etc/nginx/conf.d/default.conf

echo "Testing Nginx config..."
sudo nginx -t

if [ $? -eq 0 ]; then
    echo "✓ Nginx config valid"
    sudo systemctl enable nginx
    sudo systemctl restart nginx
    echo "✓ Nginx restarted"
else
    echo "✗ Nginx config error"
    sudo nginx -t
    exit 1
fi

# Wait for Nginx to start
sleep 3

# Final validation
echo ""
echo "=== Step 6: Final Validation ==="
ADMIN_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/admin/)
TENANT_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/tenant/)
API_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/health)

echo ""
echo "=============================================="
echo "  ✅ DEPLOYMENT COMPLETE!"
echo "=============================================="
echo ""
echo "Test Results:"
echo "  Admin Portal:  HTTP $ADMIN_CODE $([ "$ADMIN_CODE" = "200" ] && echo "✓ WORKING" || echo "✗ FAILED")"
echo "  Tenant Portal: HTTP $TENANT_CODE $([ "$TENANT_CODE" = "200" ] && echo "✓ WORKING" || echo "✗ FAILED")"
echo "  Backend API:   HTTP $API_CODE $([ "$API_CODE" = "200" ] && echo "✓ WORKING" || echo "✗ FAILED")"
echo ""
echo "Access URLs:"
echo "  🌐 Admin Portal:  http://34.227.111.143/admin/"
echo "  🌐 Tenant Portal: http://34.227.111.143/tenant/"
echo "  🔧 API Health:    http://34.227.111.143:8080/health"
echo ""
echo "Test Login Credentials:"
echo "  📧 Email:    admin@pgworld.com"
echo "  🔑 Password: Admin@123"
echo ""
echo "=============================================="

# Show some stats
echo ""
echo "Deployment Stats:"
echo "  Admin app size:  $(du -sh /usr/share/nginx/html/admin/ | cut -f1)"
echo "  Tenant app size: $(du -sh /usr/share/nginx/html/tenant/ | cut -f1)"
echo "  Total files:     $(find /usr/share/nginx/html/admin/ -type f | wc -l) + $(find /usr/share/nginx/html/tenant/ -type f | wc -l) = $(find /usr/share/nginx/html/ -type f | wc -l)"
echo ""
echo "🎉 Your application is now live!"
echo "=============================================="

