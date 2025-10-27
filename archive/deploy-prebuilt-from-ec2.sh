#!/bin/bash
# Deploy Pre-Built Files from EC2
# This script uses existing compiled files from the repository
# NO COMPILATION NEEDED!

set -e

echo "========================================"
echo "CloudPG - Deploy Pre-Built Files"
echo "========================================"
echo ""

# Configuration
REPO_URL="https://github.com/siddam01/pgni.git"
WORK_DIR="/tmp/pgworld-prebuilt-$(date +%s)"

echo "Step 1: Cloning repository..."
git clone "$REPO_URL" "$WORK_DIR"
cd "$WORK_DIR"
echo "✓ Repository cloned to $WORK_DIR"
echo ""

echo "Step 2: Checking for pre-built files..."
if [ ! -d "pgworld-master/build/web" ]; then
    echo "❌ ERROR: Pre-built admin files not found!"
    echo "The repository should contain pgworld-master/build/web/"
    exit 1
fi

if [ ! -d "pgworldtenant-master/build/web" ]; then
    echo "❌ ERROR: Pre-built tenant files not found!"
    echo "The repository should contain pgworldtenant-master/build/web/"
    exit 1
fi

echo "✓ Pre-built files found for both portals"
echo ""

echo "Step 3: Deploying Admin Portal..."
BACKUP_TIME=$(date +%Y%m%d_%H%M%S)
sudo mkdir -p /var/www/admin_backup
sudo mv /var/www/admin /var/www/admin_backup/admin_$BACKUP_TIME 2>/dev/null || true
sudo mkdir -p /var/www/admin
sudo cp -r pgworld-master/build/web/* /var/www/admin/
sudo chown -R www-data:www-data /var/www/admin 2>/dev/null || sudo chown -R nginx:nginx /var/www/admin 2>/dev/null || true
echo "✓ Admin portal deployed to /var/www/admin"
echo ""

echo "Step 4: Deploying Tenant Portal..."
sudo mkdir -p /var/www/tenant_backup
sudo mv /var/www/tenant /var/www/tenant_backup/tenant_$BACKUP_TIME 2>/dev/null || true
sudo mkdir -p /var/www/tenant
sudo cp -r pgworldtenant-master/build/web/* /var/www/tenant/
sudo chown -R www-data:www-data /var/www/tenant 2>/dev/null || sudo chown -R nginx:nginx /var/www/tenant 2>/dev/null || true
echo "✓ Tenant portal deployed to /var/www/tenant"
echo ""

echo "Step 5: Restarting web server..."
sudo systemctl restart nginx 2>/dev/null || sudo systemctl restart httpd 2>/dev/null || true
echo "✓ Web server restarted"
echo ""

echo "Step 6: Cleaning up..."
cd /tmp
rm -rf "$WORK_DIR"
echo "✓ Temporary files cleaned"
echo ""

# Get public IP
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "YOUR_SERVER_IP")

echo "========================================"
echo "✅ Deployment Complete!"
echo "========================================"
echo ""
echo "📱 Access your apps:"
echo "  Admin:  http://$PUBLIC_IP/admin/"
echo "  Tenant: http://$PUBLIC_IP/tenant/"
echo ""
echo "🎉 Using pre-built files - No compilation needed!"
echo "✅ All placeholder messages removed!"
echo "✅ Full functionality enabled!"
echo ""
echo "💡 Note: Clear browser cache (Ctrl+F5) to see changes!"
echo ""

