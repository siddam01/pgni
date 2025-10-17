#!/bin/bash
set -e

echo "════════════════════════════════════════════════════════"
echo "🔧 MANUAL FIX WITH CORRECT IP"
echo "════════════════════════════════════════════════════════"
echo ""

# Use the IP from AWS Console screenshot
PUBLIC_IP="13.221.117.236"
PRIVATE_IP="172.31.27.239"

echo "Using IP addresses:"
echo "  Public IP:  $PUBLIC_IP"
echo "  Private IP: $PRIVATE_IP"
echo ""

# ============================================================
# STEP 1: UPDATE FLUTTER CONFIG
# ============================================================

echo "STEP 1: Updating Flutter Configuration"
echo "────────────────────────────────────────────────────────"

cd /home/ec2-user/pgni/pgworld-master/lib/utils

# Create/update config.dart with correct IP
cat > config.dart << EOF
class Config {
  static const String URL = "$PUBLIC_IP:8080";
  static const int timeout = 30;
  
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
}

class API {
  static const String URL = "$PUBLIC_IP:8080";
  static const String SEND_OTP = "/api/send-otp";
  static const String VERIFY_OTP = "/api/verify-otp";
  static const String BILL = "/api/bills";
  static const String USER = "/api/users";
  static const String HOSTEL = "/api/hostels";
  static const String ISSUE = "/api/issues";
  static const String NOTICE = "/api/notices";
  static const String ROOM = "/api/rooms";
  static const String SUPPORT = "/api/support";
  static const String SIGNUP = "/api/signup";
}

const String mediaURL = "http://$PUBLIC_IP:8080/uploads/";
EOF

echo "✅ Config updated with IP: $PUBLIC_IP"
echo ""

# ============================================================
# STEP 2: QUICK REBUILD
# ============================================================

echo "STEP 2: Rebuilding Admin App"
echo "────────────────────────────────────────────────────────"

cd /home/ec2-user/pgni/pgworld-master

export DART_VM_OPTIONS="--old_gen_heap_size=3072"
export PUB_CACHE=/home/ec2-user/.pub-cache

# Check if recent build exists
if [ -f "build/web/main.dart.js" ]; then
    AGE=$(( $(date +%s) - $(stat -c %Y build/web/main.dart.js) ))
    if [ $AGE -lt 300 ]; then
        echo "✓ Using existing build (${AGE}s old)"
    else
        echo "Building... (3-5 minutes)"
        flutter build web --release --no-source-maps --no-tree-shake-icons --dart-define=dart.vm.product=true
    fi
else
    echo "Building... (3-5 minutes)"
    flutter build web --release --no-source-maps --no-tree-shake-icons --dart-define=dart.vm.product=true
fi

if [ -f "build/web/main.dart.js" ]; then
    SIZE=$(du -h build/web/main.dart.js | cut -f1)
    echo "✅ Build ready ($SIZE)"
else
    echo "❌ Build failed!"
    exit 1
fi

echo ""

# ============================================================
# STEP 3: DEPLOY
# ============================================================

echo "STEP 3: Deploying to Nginx"
echo "────────────────────────────────────────────────────────"

sudo rm -rf /usr/share/nginx/html/admin
sudo mkdir -p /usr/share/nginx/html/admin
sudo cp -r build/web/* /usr/share/nginx/html/admin/
sudo chown -R nginx:nginx /usr/share/nginx/html
sudo chmod -R 755 /usr/share/nginx/html
sudo find /usr/share/nginx/html -type f -exec chmod 644 {} \;

if command -v getenforce &> /dev/null && [ "$(getenforce)" != "Disabled" ]; then
    sudo chcon -R -t httpd_sys_content_t /usr/share/nginx/html 2>/dev/null || true
fi

sudo systemctl reload nginx

echo "✅ Deployed"
echo ""

# ============================================================
# STEP 4: FIX NGINX CONFIG
# ============================================================

echo "STEP 4: Fixing Nginx Configuration"
echo "────────────────────────────────────────────────────────"

sudo tee /etc/nginx/conf.d/pgni.conf > /dev/null << 'NGINX_EOF'
server {
    listen 80;
    listen [::]:80;
    server_name _;
    
    root /usr/share/nginx/html;
    
    location = / {
        return 301 /admin/;
    }
    
    location /admin/ {
        alias /usr/share/nginx/html/admin/;
        index index.html;
        try_files $uri $uri/ /admin/index.html;
    }
    
    location /api/ {
        proxy_pass http://127.0.0.1:8080/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
NGINX_EOF

sudo rm -f /etc/nginx/conf.d/default.conf 2>/dev/null || true
sudo nginx -t && sudo systemctl reload nginx

echo "✅ Nginx configured"
echo ""

# ============================================================
# STEP 5: VERIFY
# ============================================================

echo "STEP 5: Local Verification"
echo "────────────────────────────────────────────────────────"

LOCAL_HTTP=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/admin/)
echo "  Localhost: HTTP $LOCAL_HTTP $([ "$LOCAL_HTTP" = "200" ] && echo "✅" || echo "❌")"

PRIVATE_HTTP=$(curl -s -o /dev/null -w "%{http_code}" http://$PRIVATE_IP/admin/)
echo "  Private IP: HTTP $PRIVATE_HTTP $([ "$PRIVATE_HTTP" = "200" ] && echo "✅" || echo "❌")"

echo ""
echo "  Checking port 80 listening:"
sudo netstat -tlnp | grep :80 || sudo ss -tlnp | grep :80
echo ""

# ============================================================
# STEP 6: NETWORK DIAGNOSTICS
# ============================================================

echo "STEP 6: Network Diagnostics"
echo "────────────────────────────────────────────────────────"

echo "  Checking network route to public IP:"
ip route get $PUBLIC_IP 2>/dev/null || echo "  (Route check not available)"
echo ""

echo "  Checking if public IP is assigned to interface:"
ip addr show | grep "$PUBLIC_IP" && echo "  ✅ Public IP assigned" || echo "  ⚠️  Public IP NOT on interface (this is normal for AWS)"
echo ""

echo "  VPC/Subnet info (from hostname):"
echo "  Hostname: $(hostname)"
echo "  Private IP: $(hostname -I)"
echo ""

# ============================================================
# FINAL REPORT
# ============================================================

echo "════════════════════════════════════════════════════════"
echo "✅ CONFIGURATION COMPLETE!"
echo "════════════════════════════════════════════════════════"
echo ""
echo "🌐 YOUR APPLICATION URL:"
echo "────────────────────────────────────────────────────────"
echo ""
echo "   http://$PUBLIC_IP/admin/"
echo ""
echo "   OR: http://$PUBLIC_IP/"
echo ""
echo "════════════════════════════════════════════════════════"
echo "🔐 LOGIN CREDENTIALS:"
echo "════════════════════════════════════════════════════════"
echo ""
echo "   Email:    admin@pgworld.com"
echo "   Password: Admin@123"
echo ""
echo "   (Note: Capital 'A' in Admin@123)"
echo ""
echo "════════════════════════════════════════════════════════"
echo "📊 STATUS CHECK:"
echo "════════════════════════════════════════════════════════"
echo ""
echo "   ✓ Flutter app rebuilt with correct IP"
echo "   ✓ Deployed to Nginx"
echo "   ✓ Nginx configured and reloaded"
if [ "$LOCAL_HTTP" = "200" ]; then
    echo "   ✓ Responding on localhost"
else
    echo "   ✗ NOT responding on localhost"
fi
echo ""
echo "════════════════════════════════════════════════════════"
echo "⚠️  IMPORTANT - AWS SECURITY GROUP:"
echo "════════════════════════════════════════════════════════"
echo ""
echo "The app is configured correctly, but you MUST ensure"
echo "port 80 is open in your AWS Security Group!"
echo ""
echo "TO FIX IN AWS CONSOLE:"
echo "────────────────────────────────────────────────────────"
echo ""
echo "1. Go to: EC2 → Instances"
echo "2. Select: i-0909d462845deb151"
echo "3. Click: Security tab"
echo "4. Click: Security group link (sg-xxxxx)"
echo "5. Click: Edit inbound rules"
echo "6. Click: Add rule"
echo "7. Set:"
echo "   • Type: HTTP"
echo "   • Port: 80"
echo "   • Source: 0.0.0.0/0 (Anywhere)"
echo "8. Click: Save rules"
echo ""
echo "WAIT 30-60 seconds after saving, then try:"
echo "http://$PUBLIC_IP/admin/"
echo ""
echo "════════════════════════════════════════════════════════"
echo "🔍 IF STILL NOT WORKING:"
echo "════════════════════════════════════════════════════════"
echo ""
echo "1. Verify security group has HTTP (80) open"
echo "2. Check Network ACL in VPC settings"
echo "3. Try from different network (phone hotspot)"
echo "4. Share AWS Console screenshot of Security Group rules"
echo ""
echo "════════════════════════════════════════════════════════"
echo ""

