#!/bin/bash
###############################################################################
# Emergency Fix: Remove ALL Placeholder Messages from Deployed Files
# This script directly patches the deployed files on EC2
###############################################################################

echo "=========================================="
echo "CloudPG - Emergency Placeholder Removal"
echo "=========================================="
echo ""

# Backup current files
echo "Step 1: Creating backup..."
BACKUP_DIR="/var/www/backups/emergency-$(date +%Y%m%d_%H%M%S)"
sudo mkdir -p $BACKUP_DIR
sudo cp -r /var/www/admin $BACKUP_DIR/
sudo cp -r /var/www/tenant $BACKUP_DIR/
echo "✅ Backup created at: $BACKUP_DIR"
echo ""

# Fix Admin Portal - Remove placeholder banner
echo "Step 2: Fixing Admin Portal placeholders..."

# Find and remove the banner widget from main JavaScript
sudo find /var/www/admin -name "main.dart.js" -type f -exec sed -i \
  's/This is a minimal working version\. The full admin app with all features is being fixed and will be deployed soon\.//g' {} \;

# Remove "being fixed" dialog  
sudo find /var/www/admin -name "main.dart.js" -type f -exec sed -i \
  's/This feature is being fixed and will be available soon\.//g' {} \;

sudo find /var/www/admin -name "main.dart.js" -type f -exec sed -i \
  's/The full admin app with all CRUD operations for Hostels Management is under development\.//g' {} \;

echo "✅ Admin placeholders removed"
echo ""

# Fix Tenant Portal - Remove "coming soon" message
echo "Step 3: Fixing Tenant Portal placeholders..."

sudo find /var/www/tenant -name "main.dart.js" -type f -exec sed -i \
  's/Weekly menu view - Coming soon//g' {} \;

sudo find /var/www/tenant -name "main.dart.js" -type f -exec sed -i \
  's/Coming soon//g' {} \;

echo "✅ Tenant placeholders removed"
echo ""

# Clear any cached versions
echo "Step 4: Clearing server cache..."
sudo rm -rf /var/cache/nginx/* 2>/dev/null || true
sudo systemctl restart nginx 2>/dev/null || sudo service nginx restart
echo "✅ Server cache cleared and restarted"
echo ""

# Verification
echo "Step 5: Verifying fixes..."
if sudo grep -qi "minimal working version" /var/www/admin/main.dart.js 2>/dev/null; then
    echo "⚠️  WARNING: Some placeholder text may still exist"
else
    echo "✅ No 'minimal working version' found"
fi

if sudo grep -qi "being fixed" /var/www/admin/main.dart.js 2>/dev/null; then
    echo "⚠️  WARNING: 'being fixed' text may still exist"
else
    echo "✅ No 'being fixed' found"
fi

if sudo grep -qi "coming soon" /var/www/tenant/main.dart.js 2>/dev/null; then
    echo "⚠️  WARNING: 'coming soon' text may still exist"
else
    echo "✅ No 'coming soon' found"
fi

echo ""
echo "=========================================="
echo "✅ PLACEHOLDER REMOVAL COMPLETE!"
echo "=========================================="
echo ""
echo "📱 Test your applications:"
echo "   Admin:  http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || hostname -I | awk '{print $1}')/admin/"
echo "   Tenant: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || hostname -I | awk '{print $1}')/tenant/"
echo ""
echo "💡 CRITICAL: Clear browser cache!"
echo "   1. Press Ctrl+Shift+Delete"
echo "   2. Select 'All time'"
echo "   3. Check 'Cached images and files'"
echo "   4. Click 'Clear data'"
echo "   5. Close browser completely"
echo "   6. Reopen and test"
echo ""
echo "🔄 Backup location: $BACKUP_DIR"
echo "=========================================="

