#!/bin/bash
set -e

echo "=============================================="
echo "  COMPLETE DEPLOYMENT ON EC2"
echo "=============================================="

# Use EC2 Instance Connect - no SSH key needed!
# Go to: https://console.aws.amazon.com/ec2/
# Select instance i-0909d462845deb151
# Click "Connect" > "EC2 Instance Connect" > "Connect"
# Then paste this script:

cd /home/ec2-user

# Step 1: Install Flutter
echo "=== Installing Flutter SDK ==="
if [ ! -d "flutter" ]; then
    wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.16.0-stable.tar.xz
    tar xf flutter_linux_3.16.0-stable.tar.xz
    rm flutter_linux_3.16.0-stable.tar.xz
fi

export PATH="$PATH:/home/ec2-user/flutter/bin"

# Verify Flutter
flutter --version

# Step 2: Clone/Update Repository
echo "=== Getting Source Code ==="
if [ ! -d "pgni" ]; then
    git clone https://github.com/siddam01/pgni.git
else
    cd pgni
    git pull origin main
    cd ..
fi

cd pgni

# Step 3: Build Admin App
echo "=== Building Admin App ==="
cd pgworld-master

# Update config
mkdir -p lib/utils
cat > lib/utils/config.dart << 'EOF'
class Config {
  static const String URL = "34.227.111.143:8080";
  static const String BASE_URL = "http://34.227.111.143:8080";
}
EOF

flutter clean
flutter pub get
flutter build web --release

if [ -d "build/web" ]; then
    echo "✓ Admin built: $(du -sh build/web | cut -f1)"
else
    echo "✗ Admin build failed"
    exit 1
fi

# Step 4: Build Tenant App
echo "=== Building Tenant App ==="
cd ../pgworldtenant-master

# Update config
mkdir -p lib/utils
cat > lib/utils/config.dart << 'EOF'
class Config {
  static const String URL = "34.227.111.143:8080";
  static const String BASE_URL = "http://34.227.111.143:8080";
}
EOF

flutter clean
flutter pub get
flutter build web --release

if [ -d "build/web" ]; then
    echo "✓ Tenant built: $(du -sh build/web | cut -f1)"
else
    echo "✗ Tenant build failed"
    exit 1
fi

# Step 5: Install Nginx
echo "=== Installing Nginx ==="
sudo yum install -y nginx

# Step 6: Deploy to Nginx
echo "=== Deploying to Nginx ==="
sudo rm -rf /usr/share/nginx/html/admin /usr/share/nginx/html/tenant
sudo mkdir -p /usr/share/nginx/html/admin /usr/share/nginx/html/tenant

sudo cp -r /home/ec2-user/pgni/pgworld-master/build/web/* /usr/share/nginx/html/admin/
sudo cp -r /home/ec2-user/pgni/pgworldtenant-master/build/web/* /usr/share/nginx/html/tenant/

sudo chown -R nginx:nginx /usr/share/nginx/html
sudo chmod -R 755 /usr/share/nginx/html

# Step 7: Configure Nginx
echo "=== Configuring Nginx ==="
sudo bash -c 'cat > /etc/nginx/conf.d/pgni.conf << "NGINXEOF"
server {
    listen 80 default_server;
    server_name _;
    
    # Redirect root to admin
    location = / {
        return 301 /admin/;
    }
    
    # Admin Portal
    location /admin/ {
        alias /usr/share/nginx/html/admin/;
        index index.html;
        try_files $uri $uri/ /admin/index.html;
        add_header Cache-Control "no-cache, no-store, must-revalidate";
    }
    
    # Tenant Portal
    location /tenant/ {
        alias /usr/share/nginx/html/tenant/;
        index index.html;
        try_files $uri $uri/ /tenant/index.html;
        add_header Cache-Control "no-cache, no-store, must-revalidate";
    }
    
    # API Proxy (already running on :8080)
    location /api/ {
        proxy_pass http://localhost:8080/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
NGINXEOF'

# Remove default config
sudo rm -f /etc/nginx/conf.d/default.conf

# Test and restart Nginx
sudo nginx -t
sudo systemctl enable nginx
sudo systemctl restart nginx

echo ""
echo "=============================================="
echo "  ✅ DEPLOYMENT COMPLETE!"
echo "=============================================="
echo ""
echo "Access your application:"
echo ""
echo "  Admin Portal:  http://34.227.111.143/admin/"
echo "  Tenant Portal: http://34.227.111.143/tenant/"
echo "  API:           http://34.227.111.143:8080/health"
echo ""
echo "Test Login:"
echo "  Email: admin@pgworld.com"
echo "  Password: Admin@123"
echo ""
echo "=============================================="

