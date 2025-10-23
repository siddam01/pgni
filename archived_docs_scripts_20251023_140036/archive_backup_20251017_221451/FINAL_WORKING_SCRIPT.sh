#!/bin/bash
set -e

echo "=============================================="
echo "  COMPLETE FIX & DEPLOYMENT"
echo "=============================================="
cd /home/ec2-user

export PATH="$PATH:/home/ec2-user/flutter/bin"

# Fix git conflicts
echo "=== Fixing Git Conflicts ==="
cd /home/ec2-user/pgni
git reset --hard HEAD
git pull origin main

# Build Admin App with force
echo "=== Building Admin App ==="
cd /home/ec2-user/pgni/pgworld-master

# Create proper config
mkdir -p lib/utils
cat > lib/utils/config.dart << 'EOF'
class Config {
  static const String URL = "34.227.111.143:8080";
  static const String BASE_URL = "http://34.227.111.143:8080";
}
EOF

# Build for web (skip Android requirements)
flutter clean
flutter pub get
flutter build web --release --no-tree-shake-icons

if [ -d "build/web" ]; then
    echo "✓ Admin built: $(ls build/web | wc -l) files"
else
    echo "✗ Admin build failed"
    exit 1
fi

# Build Tenant App
echo "=== Building Tenant App ==="
cd /home/ec2-user/pgni/pgworldtenant-master

# Create proper config
mkdir -p lib/utils
cat > lib/utils/config.dart << 'EOF'
class Config {
  static const String URL = "34.227.111.143:8080";
  static const String BASE_URL = "http://34.227.111.143:8080";
}
EOF

flutter clean
flutter pub get
flutter build web --release --no-tree-shake-icons

if [ -d "build/web" ]; then
    echo "✓ Tenant built: $(ls build/web | wc -l) files"
else
    echo "✗ Tenant build failed"
    exit 1
fi

# Deploy
echo "=== Deploying to Nginx ==="
sudo rm -rf /usr/share/nginx/html/admin /usr/share/nginx/html/tenant
sudo mkdir -p /usr/share/nginx/html/admin /usr/share/nginx/html/tenant

sudo cp -r /home/ec2-user/pgni/pgworld-master/build/web/* /usr/share/nginx/html/admin/
sudo cp -r /home/ec2-user/pgni/pgworldtenant-master/build/web/* /usr/share/nginx/html/tenant/

sudo chown -R nginx:nginx /usr/share/nginx/html
sudo chmod -R 755 /usr/share/nginx/html

echo "Files deployed:"
echo "  Admin: $(ls /usr/share/nginx/html/admin/ | wc -l) files"
echo "  Tenant: $(ls /usr/share/nginx/html/tenant/ | wc -l) files"

# Check critical files
if [ -f "/usr/share/nginx/html/admin/index.html" ] && [ -f "/usr/share/nginx/html/tenant/index.html" ]; then
    echo "✓ Both index.html files exist"
else
    echo "✗ index.html files missing!"
    exit 1
fi

# Configure Nginx
echo "=== Configuring Nginx ==="
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
sudo nginx -t

if [ $? -eq 0 ]; then
    sudo systemctl enable nginx
    sudo systemctl restart nginx
    echo "✓ Nginx restarted"
else
    echo "✗ Nginx config error"
    exit 1
fi

# Final Test
sleep 3
echo ""
echo "=============================================="
echo "  ✅ DEPLOYMENT COMPLETE!"
echo "=============================================="

ADMIN_TEST=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/admin/)
TENANT_TEST=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/tenant/)

echo "Final Test Results:"
echo "  Admin Portal:  HTTP $ADMIN_TEST $([ "$ADMIN_TEST" = "200" ] && echo "✓" || echo "✗")"
echo "  Tenant Portal: HTTP $TENANT_TEST $([ "$TENANT_TEST" = "200" ] && echo "✓" || echo "✗")"
echo ""
echo "Access URLs:"
echo "  Admin:  http://34.227.111.143/admin/"
echo "  Tenant: http://34.227.111.143/tenant/"
echo ""
echo "Test Login:"
echo "  Email: admin@pgworld.com"
echo "  Password: Admin@123"
echo "=============================================="

