#!/bin/bash
set -e

echo "=============================================="
echo "  ANDROID EMBEDDING V2 - DEPLOYMENT"
echo "=============================================="

cd /home/ec2-user

export PATH="$PATH:/home/ec2-user/flutter/bin"

# Update source code with V2 fixes
echo "=== Step 1: Update Source Code ==="
cd /home/ec2-user/pgni
git reset --hard HEAD
git pull origin main

echo "✓ Source code updated with Android Embedding V2 fixes"

# Build Admin App - WEB ONLY
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

# Clean and build
flutter clean
rm -rf .dart_tool build

flutter pub get
flutter build web --release --web-renderer html

if [ -d "build/web" ]; then
    echo "✓ Admin built: $(ls build/web | wc -l) files"
else
    echo "✗ Admin build failed"
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
rm -rf .dart_tool build

flutter pub get
flutter build web --release --web-renderer html

if [ -d "build/web" ]; then
    echo "✓ Tenant built: $(ls build/web | wc -l) files"
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

# Verify deployment
if [ -f "/usr/share/nginx/html/admin/index.html" ] && [ -f "/usr/share/nginx/html/tenant/index.html" ]; then
    echo "✓ Files deployed successfully"
else
    echo "✗ Deployment failed - missing index.html"
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
}
NGINXEOF'

sudo rm -f /etc/nginx/conf.d/default.conf
sudo nginx -t && sudo systemctl enable nginx && sudo systemctl restart nginx

# Final validation
sleep 3
ADMIN_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/admin/)
TENANT_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/tenant/)

echo ""
echo "=============================================="
echo "  ✅ DEPLOYMENT COMPLETE!"
echo "=============================================="
echo ""
echo "Test Results:"
echo "  Admin:  HTTP $ADMIN_CODE $([ "$ADMIN_CODE" = "200" ] && echo "✓" || echo "✗")"
echo "  Tenant: HTTP $TENANT_CODE $([ "$TENANT_CODE" = "200" ] && echo "✓" || echo "✗")"
echo ""
echo "Access URLs:"
echo "  🌐 Admin:  http://34.227.111.143/admin/"
echo "  🌐 Tenant: http://34.227.111.143/tenant/"
echo ""
echo "Login: admin@pgworld.com / Admin@123"
echo "=============================================="

