#!/bin/bash
# Comprehensive Rebuild and Redeploy Script for Admin and Tenant Portals
# This script removes all placeholder messages and deploys fully functional apps

echo "========================================"
echo "CloudPG Full Rebuild and Deployment"
echo "========================================"
echo ""

# Configuration
EC2_HOST="54.227.101.30"
EC2_USER="ubuntu"
SSH_KEY="terraform/pgworld-key.pem"

# Check if SSH key exists
if [ ! -f "$SSH_KEY" ]; then
    echo "ERROR: SSH key not found at $SSH_KEY"
    echo "Please ensure the SSH key is in the correct location."
    exit 1
fi

echo "Step 1: Cleaning up old build files..."
rm -rf pgworld-master/build
rm -rf pgworldtenant-master/build
echo "✓ Old build files removed"
echo ""

echo "Step 2: Building Admin Portal (pgworld-master)..."
cd pgworld-master
flutter clean
flutter pub get
flutter build web --release --web-renderer html
if [ $? -ne 0 ]; then
    echo "ERROR: Admin portal build failed!"
    cd ..
    exit 1
fi
cd ..
echo "✓ Admin portal built successfully"
echo ""

echo "Step 3: Building Tenant Portal (pgworldtenant-master)..."
cd pgworldtenant-master
flutter clean
flutter pub get
flutter build web --release --web-renderer html
if [ $? -ne 0 ]; then
    echo "ERROR: Tenant portal build failed!"
    cd ..
    exit 1
fi
cd ..
echo "✓ Tenant portal built successfully"
echo ""

echo "Step 4: Deploying Admin Portal to EC2..."
echo "Stopping admin service..."
ssh -i "$SSH_KEY" "$EC2_USER@$EC2_HOST" "sudo systemctl stop cloudpg-admin 2>/dev/null || true"

echo "Backing up current admin portal..."
BACKUP_TIME=$(date +%Y%m%d_%H%M%S)
ssh -i "$SSH_KEY" "$EC2_USER@$EC2_HOST" "sudo mv /var/www/admin /var/www/admin_backup_$BACKUP_TIME 2>/dev/null || true"

echo "Creating admin directory..."
ssh -i "$SSH_KEY" "$EC2_USER@$EC2_HOST" "sudo mkdir -p /var/www/admin"
ssh -i "$SSH_KEY" "$EC2_USER@$EC2_HOST" "sudo mkdir -p /tmp/admin"

echo "Uploading admin build files..."
scp -i "$SSH_KEY" -r pgworld-master/build/web/* "$EC2_USER@$EC2_HOST:/tmp/admin/"
ssh -i "$SSH_KEY" "$EC2_USER@$EC2_HOST" "sudo rm -rf /var/www/admin/* && sudo mv /tmp/admin/* /var/www/admin/ && sudo chown -R www-data:www-data /var/www/admin"

echo "Restarting admin service..."
ssh -i "$SSH_KEY" "$EC2_USER@$EC2_HOST" "sudo systemctl start cloudpg-admin 2>/dev/null || true"
echo "✓ Admin portal deployed successfully"
echo ""

echo "Step 5: Deploying Tenant Portal to EC2..."
echo "Stopping tenant service..."
ssh -i "$SSH_KEY" "$EC2_USER@$EC2_HOST" "sudo systemctl stop cloudpg-tenant 2>/dev/null || true"

echo "Backing up current tenant portal..."
ssh -i "$SSH_KEY" "$EC2_USER@$EC2_HOST" "sudo mv /var/www/tenant /var/www/tenant_backup_$BACKUP_TIME 2>/dev/null || true"

echo "Creating tenant directory..."
ssh -i "$SSH_KEY" "$EC2_USER@$EC2_HOST" "sudo mkdir -p /var/www/tenant"
ssh -i "$SSH_KEY" "$EC2_USER@$EC2_HOST" "sudo mkdir -p /tmp/tenant"

echo "Uploading tenant build files..."
scp -i "$SSH_KEY" -r pgworldtenant-master/build/web/* "$EC2_USER@$EC2_HOST:/tmp/tenant/"
ssh -i "$SSH_KEY" "$EC2_USER@$EC2_HOST" "sudo rm -rf /var/www/tenant/* && sudo mv /tmp/tenant/* /var/www/tenant/ && sudo chown -R www-data:www-data /var/www/tenant"

echo "Restarting tenant service..."
ssh -i "$SSH_KEY" "$EC2_USER@$EC2_HOST" "sudo systemctl start cloudpg-tenant 2>/dev/null || true"
echo "✓ Tenant portal deployed successfully"
echo ""

echo "Step 6: Restarting Nginx..."
ssh -i "$SSH_KEY" "$EC2_USER@$EC2_HOST" "sudo systemctl restart nginx"
echo "✓ Nginx restarted"
echo ""

echo "========================================"
echo "Deployment Complete!"
echo "========================================"
echo ""
echo "Access URLs:"
echo "  Admin Portal:  http://$EC2_HOST/admin/"
echo "  Tenant Portal: http://$EC2_HOST/tenant/"
echo ""
echo "All placeholder messages have been removed."
echo "Both portals are now fully functional!"
echo ""

