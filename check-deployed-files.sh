#!/bin/bash
# Check what's actually deployed on EC2

echo "========================================"
echo "Checking Deployed Files"
echo "========================================"
echo ""

echo "1. Checking if directories exist:"
ls -la /var/www/ | grep -E "admin|tenant"
echo ""

echo "2. Checking admin portal files:"
ls -lh /var/www/admin/ | head -10
echo ""

echo "3. Checking tenant portal files:"
ls -lh /var/www/tenant/ | head -10
echo ""

echo "4. Checking Nginx configuration:"
sudo nginx -t
echo ""

echo "5. Checking Nginx sites:"
ls -la /etc/nginx/sites-enabled/ 2>/dev/null || ls -la /etc/nginx/conf.d/ 2>/dev/null
echo ""

echo "6. Checking for placeholder messages in index.html:"
echo "Admin portal:"
grep -i "minimal\|placeholder\|coming soon" /var/www/admin/index.html || echo "No placeholder messages found"
echo ""
echo "Tenant portal:"
grep -i "minimal\|placeholder\|coming soon" /var/www/tenant/index.html || echo "No placeholder messages found"
echo ""

echo "7. Checking last modification time:"
stat /var/www/admin/index.html | grep Modify
stat /var/www/tenant/index.html | grep Modify
echo ""

echo "8. Getting server IP:"
curl -s http://169.254.169.254/latest/meta-data/public-ipv4
echo ""
echo ""

echo "========================================"
echo "Diagnostic Complete"
echo "========================================"

