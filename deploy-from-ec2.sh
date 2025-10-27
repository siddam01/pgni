#!/bin/bash
# Deploy from EC2 Instance
# This script builds and deploys the apps directly on the EC2 server

set -e  # Exit on error

echo "========================================"
echo "CloudPG Deployment from EC2"
echo "========================================"
echo ""

# Check if running on EC2
if [ ! -f /sys/hypervisor/uuid ] && [ ! -d /sys/class/dmi/id/ ]; then
    echo "Warning: This doesn't appear to be an EC2 instance"
fi

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "ERROR: Flutter is not installed!"
    echo "Installing Flutter..."
    
    # Install Flutter
    cd /tmp
    git clone https://github.com/flutter/flutter.git -b stable
    export PATH="$PATH:/tmp/flutter/bin"
    flutter doctor
fi

# Ensure we're in the right directory
if [ ! -d "pgworld-master" ] || [ ! -d "pgworldtenant-master" ]; then
    echo "ERROR: Cannot find pgworld-master or pgworldtenant-master directories!"
    echo "Current directory: $(pwd)"
    echo "Please ensure you're in the correct directory."
    exit 1
fi

echo "Step 1: Building Admin Portal..."
cd pgworld-master
flutter clean
flutter pub get
flutter build web --release
if [ $? -ne 0 ]; then
    echo "ERROR: Admin build failed!"
    exit 1
fi
cd ..
echo "✓ Admin portal built"
echo ""

echo "Step 2: Building Tenant Portal..."
cd pgworldtenant-master
flutter clean
flutter pub get
flutter build web --release
if [ $? -ne 0 ]; then
    echo "ERROR: Tenant build failed!"
    exit 1
fi
cd ..
echo "✓ Tenant portal built"
echo ""

echo "Step 3: Deploying Admin Portal..."
sudo systemctl stop cloudpg-admin 2>/dev/null || true
sudo rm -rf /var/www/admin_backup_old 2>/dev/null || true
sudo mv /var/www/admin /var/www/admin_backup_old 2>/dev/null || true
sudo mkdir -p /var/www/admin
sudo cp -r pgworld-master/build/web/* /var/www/admin/
sudo chown -R www-data:www-data /var/www/admin
sudo systemctl start cloudpg-admin 2>/dev/null || true
echo "✓ Admin deployed"
echo ""

echo "Step 4: Deploying Tenant Portal..."
sudo systemctl stop cloudpg-tenant 2>/dev/null || true
sudo rm -rf /var/www/tenant_backup_old 2>/dev/null || true
sudo mv /var/www/tenant /var/www/tenant_backup_old 2>/dev/null || true
sudo mkdir -p /var/www/tenant
sudo cp -r pgworldtenant-master/build/web/* /var/www/tenant/
sudo chown -R www-data:www-data /var/www/tenant
sudo systemctl start cloudpg-tenant 2>/dev/null || true
echo "✓ Tenant deployed"
echo ""

echo "Step 5: Restarting Nginx..."
sudo systemctl restart nginx
echo "✓ Nginx restarted"
echo ""

echo "========================================"
echo "Deployment Complete!"
echo "========================================"
echo ""
echo "Access your apps:"
echo "  Admin:  http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)/admin/"
echo "  Tenant: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)/tenant/"
echo ""
echo "Clear browser cache (Ctrl+F5) to see changes!"
echo ""

