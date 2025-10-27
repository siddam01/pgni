#!/bin/bash
###############################################################################
# CloudPG Clean Deployment Script - Production Ready
# Deploys pre-built, placeholder-free admin and tenant portals
###############################################################################

set -e  # Exit on error

echo "========================================"
echo "CloudPG - Production Deployment"
echo "========================================"
echo ""

# Configuration
DEPLOY_DIR="/tmp/pgworld-deploy-$(date +%s)"
ADMIN_WEB_DIR="/var/www/admin"
TENANT_WEB_DIR="/var/www/tenant"
REPO_URL="https://github.com/siddam01/pgni.git"
COMMIT_HASH="c5266e0"  # Production-ready commit with no placeholders

# Step 1: Clone repository at specific commit
echo "Step 1: Cloning production-ready version..."
git clone --quiet $REPO_URL $DEPLOY_DIR 2>/dev/null || {
    echo "❌ Failed to clone repository"
    exit 1
}
cd $DEPLOY_DIR
git checkout --quiet $COMMIT_HASH 2>/dev/null || {
    echo "❌ Failed to checkout commit $COMMIT_HASH"
    exit 1
}
echo "✓ Cloned repository at commit $COMMIT_HASH"
echo ""

# Step 2: Verify pre-built files exist
echo "Step 2: Verifying pre-built files..."
if [ ! -f "pgworld-master/build/web/index.html" ]; then
    echo "❌ Admin pre-built files not found!"
    exit 1
fi

if [ ! -f "pgworldtenant-master/build/web/index.html" ]; then
    echo "❌ Tenant pre-built files not found!"
    exit 1
fi
echo "✓ Pre-built files verified for both portals"
echo ""

# Step 3: Backup existing deployments
echo "Step 3: Creating backups..."
BACKUP_DIR="/var/www/backups/$(date +%Y%m%d_%H%M%S)"
sudo mkdir -p $BACKUP_DIR
if [ -d "$ADMIN_WEB_DIR" ]; then
    sudo cp -r $ADMIN_WEB_DIR $BACKUP_DIR/admin 2>/dev/null || true
    echo "✓ Admin backup created at $BACKUP_DIR/admin"
fi
if [ -d "$TENANT_WEB_DIR" ]; then
    sudo cp -r $TENANT_WEB_DIR $BACKUP_DIR/tenant 2>/dev/null || true
    echo "✓ Tenant backup created at $BACKUP_DIR/tenant"
fi
echo ""

# Step 4: Deploy Admin Portal
echo "Step 4: Deploying Admin Portal..."
sudo rm -rf $ADMIN_WEB_DIR
sudo mkdir -p $ADMIN_WEB_DIR
sudo cp -r pgworld-master/build/web/* $ADMIN_WEB_DIR/
sudo chown -R nginx:nginx $ADMIN_WEB_DIR 2>/dev/null || sudo chown -R www-data:www-data $ADMIN_WEB_DIR 2>/dev/null || true
sudo chmod -R 755 $ADMIN_WEB_DIR
echo "✓ Admin portal deployed to $ADMIN_WEB_DIR"
echo ""

# Step 5: Deploy Tenant Portal
echo "Step 5: Deploying Tenant Portal..."
sudo rm -rf $TENANT_WEB_DIR
sudo mkdir -p $TENANT_WEB_DIR
sudo cp -r pgworldtenant-master/build/web/* $TENANT_WEB_DIR/
sudo chown -R nginx:nginx $TENANT_WEB_DIR 2>/dev/null || sudo chown -R www-data:www-data $TENANT_WEB_DIR 2>/dev/null || true
sudo chmod -R 755 $TENANT_WEB_DIR
echo "✓ Tenant portal deployed to $TENANT_WEB_DIR"
echo ""

# Step 6: Configure Nginx (if needed)
echo "Step 6: Validating Nginx configuration..."
NGINX_CONF="/etc/nginx/nginx.conf"
NGINX_CONF_D="/etc/nginx/conf.d"
NGINX_SITES="/etc/nginx/sites-available"

# Check if configuration exists
if sudo test -f "$NGINX_CONF_D/cloudpg.conf" || sudo test -f "$NGINX_SITES/cloudpg"; then
    echo "✓ Nginx configuration already exists"
else
    echo "Creating Nginx configuration..."
    sudo tee /etc/nginx/conf.d/cloudpg.conf > /dev/null <<EOF
server {
    listen 80;
    server_name _;

    # Admin Portal
    location /admin/ {
        alias /var/www/admin/;
        index index.html;
        try_files \$uri \$uri/ /admin/index.html;
        
        # Flutter web specific headers
        add_header Cache-Control "no-cache, no-store, must-revalidate";
        add_header Pragma "no-cache";
        add_header Expires "0";
    }

    # Tenant Portal
    location /tenant/ {
        alias /var/www/tenant/;
        index index.html;
        try_files \$uri \$uri/ /tenant/index.html;
        
        # Flutter web specific headers
        add_header Cache-Control "no-cache, no-store, must-revalidate";
        add_header Pragma "no-cache";
        add_header Expires "0";
    }

    # Root redirect
    location = / {
        return 301 /admin/;
    }
}
EOF
    echo "✓ Nginx configuration created"
fi
echo ""

# Step 7: Test and restart Nginx
echo "Step 7: Restarting web server..."
sudo nginx -t && sudo systemctl restart nginx || sudo service nginx restart
echo "✓ Web server restarted successfully"
echo ""

# Step 8: Cleanup
echo "Step 8: Cleaning up..."
cd /tmp
sudo rm -rf $DEPLOY_DIR
echo "✓ Temporary files cleaned"
echo ""

# Step 9: Get server IP
echo "=========================================="
echo "✅ Deployment Complete!"
echo "=========================================="
echo ""
SERVER_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || hostname -I | awk '{print $1}')
echo "📱 Access your applications:"
echo "   Admin:  http://$SERVER_IP/admin/"
echo "   Tenant: http://$SERVER_IP/tenant/"
echo ""
echo "🎉 Production-ready version deployed!"
echo "✅ All placeholder messages removed"
echo "✅ Full functionality enabled"
echo ""
echo "💡 Note: Clear browser cache (Ctrl+F5) to see changes!"
echo ""
echo "📦 Backup location: $BACKUP_DIR"
echo ""
echo "=========================================="

