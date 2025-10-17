#!/bin/bash
set -e

echo "=============================================="
echo "  COMPLETE FIX & DEPLOYMENT"
echo "=============================================="

cd /home/ec2-user

# Add Flutter to PATH
export PATH="$PATH:/home/ec2-user/flutter/bin"

# Check if Flutter is installed
if [ ! -d "flutter" ]; then
    echo "=== Installing Flutter SDK ==="
    wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.16.0-stable.tar.xz
    tar xf flutter_linux_3.16.0-stable.tar.xz
    rm flutter_linux_3.16.0-stable.tar.xz
    echo "✓ Flutter installed"
fi

flutter --version

# Clone/update repository
echo "=== Getting Source Code ==="
if [ ! -d "pgni" ]; then
    git clone https://github.com/siddam01/pgni.git
else
    cd pgni && git pull origin main && cd ..
fi

cd pgni

# Build Admin App
echo "=== Building Admin App ==="
cd pgworld-master

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

if [ ! -d "build/web" ]; then
    echo "✗ Admin build failed"
    exit 1
fi
echo "✓ Admin built: $(ls build/web | wc -l) files"

# Build Tenant App
echo "=== Building Tenant App ==="
cd ../pgworldtenant-master

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

if [ ! -d "build/web" ]; then
    echo "✗ Tenant build failed"
    exit 1
fi
echo "✓ Tenant built: $(ls build/web | wc -l) files"

# Install Nginx
echo "=== Installing Nginx ==="
sudo yum install -y nginx

# Deploy to Nginx
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
sudo systemctl enable nginx
sudo systemctl restart nginx

echo ""
echo "=============================================="
echo "  ✅ DEPLOYMENT COMPLETE!"
echo "=============================================="
echo ""
echo "Access URLs:"
echo "  Admin:  http://34.227.111.143/admin/"
echo "  Tenant: http://34.227.111.143/tenant/"
echo "  API:    http://34.227.111.143:8080/health"
echo ""
echo "Test Login:"
echo "  Email: admin@pgworld.com"
echo "  Password: Admin@123"
echo ""
echo "=============================================="

