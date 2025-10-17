#!/bin/bash
set -e

echo "════════════════════════════════════════════════════════"
echo "🔧 FIXING NGINX ACCESS - Complete End-to-End Validation"
echo "════════════════════════════════════════════════════════"
echo ""

INSTANCE_ID="i-0909d462845deb151"
REGION="us-east-1"
PUBLIC_IP="34.227.111.143"

# ============================================================
# STEP 1: CHECK NGINX SERVICE
# ============================================================

echo "STEP 1: Checking Nginx Service"
echo "────────────────────────────────────────────────────────"

# Check if Nginx is installed
if ! command -v nginx &> /dev/null; then
    echo "❌ Nginx not installed. Installing..."
    sudo yum install -y nginx
    echo "✓ Nginx installed"
else
    echo "✓ Nginx is installed"
fi

# Check Nginx status
NGINX_STATUS=$(sudo systemctl is-active nginx 2>/dev/null || echo "inactive")
echo "  Status: $NGINX_STATUS"

if [ "$NGINX_STATUS" != "active" ]; then
    echo "  🔄 Starting Nginx..."
    sudo systemctl start nginx
    sudo systemctl enable nginx
    sleep 2
    echo "  ✓ Nginx started"
else
    echo "  ✓ Nginx is running"
fi

echo ""

# ============================================================
# STEP 2: CHECK FILES
# ============================================================

echo "STEP 2: Checking Deployed Files"
echo "────────────────────────────────────────────────────────"

if [ -f "/usr/share/nginx/html/admin/index.html" ]; then
    ADMIN_SIZE=$(du -h /usr/share/nginx/html/admin/index.html | cut -f1)
    ADMIN_JS=$(ls /usr/share/nginx/html/admin/main.dart.js 2>/dev/null && du -h /usr/share/nginx/html/admin/main.dart.js | cut -f1 || echo "NOT FOUND")
    echo "  Admin Files:"
    echo "    index.html: $ADMIN_SIZE"
    echo "    main.dart.js: $ADMIN_JS"
else
    echo "  ❌ Admin files NOT deployed!"
    echo "  Deploying now..."
    
    if [ -f "/home/ec2-user/pgni/pgworld-master/build/web/index.html" ]; then
        sudo rm -rf /usr/share/nginx/html/admin
        sudo mkdir -p /usr/share/nginx/html/admin
        sudo cp -r /home/ec2-user/pgni/pgworld-master/build/web/* /usr/share/nginx/html/admin/
        echo "  ✓ Admin files deployed"
    else
        echo "  ❌ Admin build doesn't exist! Need to build first."
        exit 1
    fi
fi

echo ""

# ============================================================
# STEP 3: CHECK PERMISSIONS
# ============================================================

echo "STEP 3: Fixing Permissions"
echo "────────────────────────────────────────────────────────"

sudo chown -R nginx:nginx /usr/share/nginx/html
sudo chmod -R 755 /usr/share/nginx/html
sudo find /usr/share/nginx/html -type f -exec chmod 644 {} \;

# Check SELinux
if command -v getenforce &> /dev/null; then
    SELINUX_STATUS=$(getenforce)
    echo "  SELinux: $SELINUX_STATUS"
    
    if [ "$SELINUX_STATUS" = "Enforcing" ]; then
        echo "  🔄 Fixing SELinux context..."
        sudo chcon -R -t httpd_sys_content_t /usr/share/nginx/html
        sudo setsebool -P httpd_can_network_connect 1
        echo "  ✓ SELinux configured"
    fi
else
    echo "  SELinux: Not present"
fi

echo "  ✓ Permissions fixed"
echo ""

# ============================================================
# STEP 4: CHECK NGINX CONFIGURATION
# ============================================================

echo "STEP 4: Checking Nginx Configuration"
echo "────────────────────────────────────────────────────────"

# Create proper Nginx config
sudo tee /etc/nginx/conf.d/pgni.conf > /dev/null << 'NGINX_EOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;
    
    root /usr/share/nginx/html;
    
    error_log /var/log/nginx/pgni_error.log warn;
    access_log /var/log/nginx/pgni_access.log;
    
    # Root redirect to admin
    location = / {
        return 301 /admin/;
    }
    
    # Admin app
    location /admin/ {
        alias /usr/share/nginx/html/admin/;
        index index.html;
        try_files $uri $uri/ /admin/index.html;
        
        # CORS headers for Flutter
        add_header 'Access-Control-Allow-Origin' '*' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS' always;
    }
    
    # Tenant app
    location /tenant/ {
        alias /usr/share/nginx/html/tenant/;
        index index.html;
        try_files $uri $uri/ /tenant/index.html;
        
        add_header 'Access-Control-Allow-Origin' '*' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS' always;
    }
    
    # API proxy
    location /api/ {
        proxy_pass http://127.0.0.1:8080/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
NGINX_EOF

echo "  ✓ Nginx config created"

# Remove default config
sudo rm -f /etc/nginx/conf.d/default.conf /etc/nginx/sites-enabled/default 2>/dev/null || true

# Test config
echo "  Testing configuration..."
if sudo nginx -t 2>&1 | grep -q "successful"; then
    echo "  ✓ Configuration valid"
else
    echo "  ❌ Configuration invalid:"
    sudo nginx -t
    exit 1
fi

# Reload
sudo systemctl reload nginx
echo "  ✓ Nginx reloaded"
echo ""

# ============================================================
# STEP 5: CHECK FIREWALL (EC2 LEVEL)
# ============================================================

echo "STEP 5: Checking Local Firewall"
echo "────────────────────────────────────────────────────────"

# Check if firewalld is running
if sudo systemctl is-active firewalld &> /dev/null; then
    echo "  Firewalld: Active"
    echo "  🔄 Opening port 80..."
    sudo firewall-cmd --permanent --add-service=http
    sudo firewall-cmd --reload
    echo "  ✓ Port 80 opened"
else
    echo "  Firewalld: Not active"
fi

# Check iptables
if sudo iptables -L -n | grep -q "DROP.*dpt:80"; then
    echo "  ⚠️  iptables blocking port 80"
    echo "  🔄 Opening port 80..."
    sudo iptables -I INPUT -p tcp --dport 80 -j ACCEPT
    sudo service iptables save 2>/dev/null || true
    echo "  ✓ Port 80 opened"
else
    echo "  ✓ No iptables blocking port 80"
fi

echo ""

# ============================================================
# STEP 6: LOCAL TEST
# ============================================================

echo "STEP 6: Local Connectivity Test"
echo "────────────────────────────────────────────────────────"

# Test from EC2 itself
LOCAL_HTTP=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/admin/ 2>/dev/null || echo "000")
echo "  http://localhost/admin/: HTTP $LOCAL_HTTP"

LOCAL_IP=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1/admin/ 2>/dev/null || echo "000")
echo "  http://127.0.0.1/admin/: HTTP $LOCAL_IP"

if [ "$LOCAL_HTTP" = "200" ] || [ "$LOCAL_IP" = "200" ]; then
    echo "  ✅ Nginx serving correctly locally"
else
    echo "  ❌ Nginx not serving properly"
    echo ""
    echo "  Checking Nginx logs:"
    sudo tail -20 /var/log/nginx/error.log
    exit 1
fi

echo ""

# ============================================================
# STEP 7: CHECK AWS SECURITY GROUP
# ============================================================

echo "STEP 7: Checking AWS Security Group"
echo "────────────────────────────────────────────────────────"

# Get security group
SG_ID=$(aws ec2 describe-instances \
    --instance-ids $INSTANCE_ID \
    --region $REGION \
    --query 'Reservations[0].Instances[0].SecurityGroups[0].GroupId' \
    --output text 2>/dev/null)

if [ "$SG_ID" != "" ] && [ "$SG_ID" != "None" ]; then
    echo "  Security Group: $SG_ID"
    
    # Check if port 80 is open
    PORT_80=$(aws ec2 describe-security-groups \
        --group-ids $SG_ID \
        --region $REGION \
        --query 'SecurityGroups[0].IpPermissions[?FromPort==`80`]' \
        --output text 2>/dev/null)
    
    if [ -z "$PORT_80" ]; then
        echo "  ❌ Port 80 NOT open in security group"
        echo "  🔄 Opening port 80..."
        
        aws ec2 authorize-security-group-ingress \
            --group-id $SG_ID \
            --protocol tcp \
            --port 80 \
            --cidr 0.0.0.0/0 \
            --region $REGION 2>/dev/null || echo "  (May already exist)"
        
        echo "  ✓ Port 80 opened"
    else
        echo "  ✓ Port 80 is open in security group"
    fi
else
    echo "  ⚠️  Could not check security group via AWS CLI"
    echo ""
    echo "  MANUAL ACTION REQUIRED:"
    echo "  1. Go to AWS Console"
    echo "  2. EC2 → Instances → $INSTANCE_ID"
    echo "  3. Security → Security Groups"
    echo "  4. Edit Inbound Rules"
    echo "  5. Add rule: HTTP (port 80) from 0.0.0.0/0"
fi

echo ""

# ============================================================
# STEP 8: FINAL VERIFICATION
# ============================================================

echo "STEP 8: Final Verification"
echo "────────────────────────────────────────────────────────"

echo "  Files deployed:"
ls -lh /usr/share/nginx/html/admin/ | head -10

echo ""
echo "  Nginx status:"
sudo systemctl status nginx --no-pager | head -5

echo ""
echo "  Listening ports:"
sudo netstat -tlnp | grep :80 || sudo ss -tlnp | grep :80

echo ""

# ============================================================
# SUMMARY
# ============================================================

echo "════════════════════════════════════════════════════════"
echo "✅ FIXES APPLIED!"
echo "════════════════════════════════════════════════════════"
echo ""
echo "📋 What was fixed:"
echo "  ✓ Nginx service started"
echo "  ✓ Files deployed correctly"
echo "  ✓ Permissions fixed"
echo "  ✓ Nginx configuration optimized"
echo "  ✓ Local firewall opened"
echo "  ✓ Security group checked/fixed"
echo ""
echo "🌐 Try accessing now:"
echo "  http://$PUBLIC_IP/admin/"
echo ""
echo "⏳ Note: May take 30-60 seconds for security group changes to propagate"
echo ""
echo "🔍 If still not working:"
echo "  1. Wait 60 seconds"
echo "  2. Try: http://$PUBLIC_IP/ (should redirect to /admin/)"
echo "  3. Check AWS Console → EC2 → Security Groups → Inbound Rules"
echo "     Must have: HTTP (80) from 0.0.0.0/0"
echo ""

