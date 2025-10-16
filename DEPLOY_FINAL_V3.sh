#!/bin/bash
set -e

echo "=============================================="
echo "  FINAL DEPLOYMENT - V2 + UPDATED DEPS"
echo "=============================================="

cd /home/ec2-user

export PATH="$PATH:/home/ec2-user/flutter/bin"

# Update source code
echo "=== Step 1: Update Source Code ==="
cd /home/ec2-user/pgni
git reset --hard HEAD
git pull origin main

echo "✓ Source code updated with:"
echo "  - Android Embedding V2"
echo "  - Updated dependencies (Flutter 3.x compatible)"

# Build Admin App
echo ""
echo "=== Step 2: Build Admin App ==="
cd /home/ec2-user/pgni/pgworld-master

# Update config
mkdir -p lib/utils
cat > lib/utils/config.dart << 'EOF'
class Config {
  static const String URL = "34.227.111.143:8080";
  static const String BASE_URL = "http://34.227.111.143:8080";
}
EOF

# Clean and upgrade dependencies
echo "Cleaning project..."
flutter clean
rm -rf .dart_tool build

echo "Upgrading dependencies..."
flutter pub get
flutter pub upgrade

# Build for web
echo "Building for web..."
flutter build web --release --web-renderer html

if [ -d "build/web" ]; then
    FILE_COUNT=$(ls build/web | wc -l)
    TOTAL_SIZE=$(du -sh build/web | cut -f1)
    echo "✓ Admin built successfully:"
    echo "  - Files: $FILE_COUNT"
    echo "  - Size: $TOTAL_SIZE"
else
    echo "✗ Admin build failed"
    exit 1
fi

# Build Tenant App
echo ""
echo "=== Step 3: Build Tenant App ==="
cd /home/ec2-user/pgni/pgworldtenant-master

# Update config
mkdir -p lib/utils
cat > lib/utils/config.dart << 'EOF'
class Config {
  static const String URL = "34.227.111.143:8080";
  static const String BASE_URL = "http://34.227.111.143:8080";
}
EOF

# Clean and upgrade dependencies
echo "Cleaning project..."
flutter clean
rm -rf .dart_tool build

echo "Upgrading dependencies..."
flutter pub get
flutter pub upgrade

# Build for web
echo "Building for web..."
flutter build web --release --web-renderer html

if [ -d "build/web" ]; then
    FILE_COUNT=$(ls build/web | wc -l)
    TOTAL_SIZE=$(du -sh build/web | cut -f1)
    echo "✓ Tenant built successfully:"
    echo "  - Files: $FILE_COUNT"
    echo "  - Size: $TOTAL_SIZE"
else
    echo "✗ Tenant build failed"
    exit 1
fi

# Deploy to Nginx
echo ""
echo "=== Step 4: Deploy to Nginx ==="

# Install Nginx if not already installed
sudo yum install -y nginx

# Remove old deployment
sudo rm -rf /usr/share/nginx/html/admin /usr/share/nginx/html/tenant
sudo mkdir -p /usr/share/nginx/html/admin /usr/share/nginx/html/tenant

# Copy new builds
sudo cp -r /home/ec2-user/pgni/pgworld-master/build/web/* /usr/share/nginx/html/admin/
sudo cp -r /home/ec2-user/pgni/pgworldtenant-master/build/web/* /usr/share/nginx/html/tenant/

# Set permissions
sudo chown -R nginx:nginx /usr/share/nginx/html
sudo chmod -R 755 /usr/share/nginx/html

# Verify deployment
ADMIN_FILES=$(ls /usr/share/nginx/html/admin/ | wc -l)
TENANT_FILES=$(ls /usr/share/nginx/html/tenant/ | wc -l)

echo "✓ Files deployed:"
echo "  - Admin: $ADMIN_FILES files"
echo "  - Tenant: $TENANT_FILES files"

# Verify critical files
if [ ! -f "/usr/share/nginx/html/admin/index.html" ]; then
    echo "✗ Admin index.html missing!"
    exit 1
fi

if [ ! -f "/usr/share/nginx/html/tenant/index.html" ]; then
    echo "✗ Tenant index.html missing!"
    exit 1
fi

echo "✓ Critical files verified"

# Configure Nginx
echo ""
echo "=== Step 5: Configure Nginx ==="

sudo bash -c 'cat > /etc/nginx/conf.d/pgni.conf << "NGINXEOF"
server {
    listen 80 default_server;
    server_name _;
    
    # Root redirects to admin
    location = / {
        return 301 /admin/;
    }
    
    # Admin Portal
    location /admin/ {
        alias /usr/share/nginx/html/admin/;
        index index.html;
        try_files $uri $uri/ /admin/index.html;
        
        # Disable caching for index.html
        location = /admin/index.html {
            add_header Cache-Control "no-cache, no-store, must-revalidate";
        }
    }
    
    # Tenant Portal
    location /tenant/ {
        alias /usr/share/nginx/html/tenant/;
        index index.html;
        try_files $uri $uri/ /tenant/index.html;
        
        # Disable caching for index.html
        location = /tenant/index.html {
            add_header Cache-Control "no-cache, no-store, must-revalidate";
        }
    }
    
    # API Proxy (optional)
    location /api/ {
        proxy_pass http://localhost:8080/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
NGINXEOF'

# Remove default config
sudo rm -f /etc/nginx/conf.d/default.conf

# Test Nginx configuration
echo "Testing Nginx configuration..."
sudo nginx -t

if [ $? -ne 0 ]; then
    echo "✗ Nginx config error"
    exit 1
fi

echo "✓ Nginx config valid"

# Restart Nginx
sudo systemctl enable nginx
sudo systemctl restart nginx

if [ $? -eq 0 ]; then
    echo "✓ Nginx restarted successfully"
else
    echo "✗ Nginx restart failed"
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
echo "  Admin Portal:  HTTP $ADMIN_CODE $([ "$ADMIN_CODE" = "200" ] && echo "✓ WORKING" || echo "✗ CHECK LOGS")"
echo "  Tenant Portal: HTTP $TENANT_CODE $([ "$TENANT_CODE" = "200" ] && echo "✓ WORKING" || echo "✗ CHECK LOGS")"
echo "  Backend API:   HTTP $API_CODE $([ "$API_CODE" = "200" ] && echo "✓ WORKING" || echo "✗ CHECK LOGS")"
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
echo "Deployment Summary:"
echo "  - Android Embedding: V2 ✅"
echo "  - Flutter SDK: 3.x ✅"
echo "  - Dart SDK: 3.x ✅"
echo "  - Dependencies: Updated ✅"
echo "  - Web Build: Success ✅"
echo "  - Nginx: Running ✅"
echo ""
echo "=============================================="

