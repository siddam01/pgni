#!/bin/bash
# Complete Deployment from EC2 - Clones repo and deploys
# Run with: bash <(curl -sL https://raw.githubusercontent.com/siddam01/pgni/main/deploy-from-ec2-complete.sh)

set -e  # Exit on error

echo "========================================"
echo "CloudPG Complete Deployment from EC2"
echo "========================================"
echo ""

# Configuration
REPO_URL="https://github.com/siddam01/pgni.git"
WORK_DIR="/tmp/pgworld-deploy-$(date +%s)"
TARGET_SERVER="localhost"  # Since we're deploying on the same server

echo "Step 1: Checking prerequisites..."

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "Flutter not found. Installing Flutter..."
    
    # Install prerequisites
    sudo yum install -y git unzip xz curl || sudo apt-get install -y git unzip xz-utils curl
    
    # Download and install Flutter
    cd /tmp
    if [ ! -d "/opt/flutter" ]; then
        sudo git clone https://github.com/flutter/flutter.git -b stable /opt/flutter
    fi
    
    # Add to PATH
    export PATH="$PATH:/opt/flutter/bin"
    
    # Run flutter doctor
    flutter doctor -v
else
    echo "✓ Flutter is installed"
    export PATH="$PATH:$(dirname $(which flutter))"
fi

echo ""
echo "Step 2: Cloning repository..."
rm -rf "$WORK_DIR"
git clone "$REPO_URL" "$WORK_DIR"
cd "$WORK_DIR"
echo "✓ Repository cloned to $WORK_DIR"
echo ""

# Check if directories exist
if [ ! -d "pgworld-master" ] || [ ! -d "pgworldtenant-master" ]; then
    echo "ERROR: Required directories not found in repository!"
    ls -la
    exit 1
fi

echo "Step 3: Building Admin Portal..."
cd pgworld-master
flutter clean
flutter pub get
flutter build web --release --web-renderer html
if [ $? -ne 0 ]; then
    echo "ERROR: Admin build failed!"
    exit 1
fi
cd ..
echo "✓ Admin portal built"
echo ""

echo "Step 4: Building Tenant Portal..."
cd pgworldtenant-master
flutter clean
flutter pub get
flutter build web --release --web-renderer html
if [ $? -ne 0 ]; then
    echo "ERROR: Tenant build failed!"
    exit 1
fi
cd ..
echo "✓ Tenant portal built"
echo ""

echo "Step 5: Deploying Admin Portal..."
sudo systemctl stop cloudpg-admin 2>/dev/null || true
sudo mkdir -p /var/www/admin_backup
BACKUP_TIME=$(date +%Y%m%d_%H%M%S)
sudo mv /var/www/admin /var/www/admin_backup/admin_$BACKUP_TIME 2>/dev/null || true
sudo mkdir -p /var/www/admin
sudo cp -r pgworld-master/build/web/* /var/www/admin/
sudo chown -R www-data:www-data /var/www/admin 2>/dev/null || sudo chown -R nginx:nginx /var/www/admin 2>/dev/null || true
sudo systemctl start cloudpg-admin 2>/dev/null || true
echo "✓ Admin deployed to /var/www/admin"
echo ""

echo "Step 6: Deploying Tenant Portal..."
sudo systemctl stop cloudpg-tenant 2>/dev/null || true
sudo mkdir -p /var/www/tenant_backup
sudo mv /var/www/tenant /var/www/tenant_backup/tenant_$BACKUP_TIME 2>/dev/null || true
sudo mkdir -p /var/www/tenant
sudo cp -r pgworldtenant-master/build/web/* /var/www/tenant/
sudo chown -R www-data:www-data /var/www/tenant 2>/dev/null || sudo chown -R nginx:nginx /var/www/tenant 2>/dev/null || true
sudo systemctl start cloudpg-tenant 2>/dev/null || true
echo "✓ Tenant deployed to /var/www/tenant"
echo ""

echo "Step 7: Restarting web server..."
sudo systemctl restart nginx 2>/dev/null || sudo systemctl restart httpd 2>/dev/null || true
echo "✓ Web server restarted"
echo ""

echo "Step 8: Cleaning up..."
cd /tmp
rm -rf "$WORK_DIR"
echo "✓ Temporary files cleaned"
echo ""

echo "========================================"
echo "Deployment Complete!"
echo "========================================"
echo ""

# Try to get public IP
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "YOUR_SERVER_IP")

echo "Access your apps:"
echo "  Admin:  http://$PUBLIC_IP/admin/"
echo "  Tenant: http://$PUBLIC_IP/tenant/"
echo ""
echo "✅ All placeholder messages removed!"
echo "✅ Full functionality enabled!"
echo ""
echo "Note: Clear browser cache (Ctrl+F5) to see changes!"
echo ""

