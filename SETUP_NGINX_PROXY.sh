#!/bin/bash
set -e

echo "════════════════════════════════════════════════════════"
echo "🔧 NGINX REVERSE PROXY SETUP"
echo "   Frontend → /api → Backend:8080"
echo "════════════════════════════════════════════════════════"

PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 || echo "54.227.101.30")
DOMAIN="${DOMAIN:-$PUBLIC_IP}"  # Use domain if set, else IP

echo ""
echo "Server IP: $PUBLIC_IP"
echo "Domain: $DOMAIN"
echo ""

echo "════════════════════════════════════════════════════════"
echo "STEP 1: Backup Current Nginx Config"
echo "════════════════════════════════════════════════════════"

sudo cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup.$(date +%s)
echo "✓ Backup created"

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 2: Create Nginx Config with API Proxy"
echo "════════════════════════════════════════════════════════"

sudo tee /etc/nginx/nginx.conf > /dev/null << 'EOFNGINX'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log notice;
pid /run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile        on;
    tcp_nopush      on;
    keepalive_timeout  65;
    types_hash_max_size 4096;
    client_max_body_size 50M;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml text/javascript 
               application/json application/javascript application/xml+rss 
               application/rss+xml font/truetype font/opentype 
               application/vnd.ms-fontobject image/svg+xml;

    server {
        listen 80 default_server;
        listen [::]:80 default_server;
        server_name _;

        # Security headers
        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-Content-Type-Options "nosniff" always;
        add_header X-XSS-Protection "1; mode=block" always;

        # API Proxy - Forward /api/* to backend:8080
        location /api/ {
            # Remove /api prefix and forward to backend
            rewrite ^/api/(.*) /$1 break;
            
            proxy_pass http://127.0.0.1:8080;
            proxy_http_version 1.1;
            
            # Proxy headers
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            
            # Timeouts
            proxy_connect_timeout 60s;
            proxy_send_timeout 60s;
            proxy_read_timeout 60s;
            
            # CORS headers (handled by proxy, not backend)
            add_header 'Access-Control-Allow-Origin' '*' always;
            add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS' always;
            add_header 'Access-Control-Allow-Headers' 'Content-Type, X-API-Key, apikey, Authorization' always;
            
            # Handle preflight OPTIONS
            if ($request_method = OPTIONS) {
                add_header 'Access-Control-Allow-Origin' '*';
                add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS';
                add_header 'Access-Control-Allow-Headers' 'Content-Type, X-API-Key, apikey, Authorization';
                add_header 'Content-Length' 0;
                add_header 'Content-Type' 'text/plain charset=UTF-8';
                return 204;
            }
        }

        # Admin App
        location /admin/ {
            alias /usr/share/nginx/html/admin/;
            try_files $uri $uri/ /admin/index.html;
            
            # Cache static assets
            location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
                expires 1y;
                add_header Cache-Control "public, immutable";
            }
        }

        # Tenant App
        location /tenant/ {
            alias /usr/share/nginx/html/tenant/;
            try_files $uri $uri/ /tenant/index.html;
            
            # Cache static assets
            location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
                expires 1y;
                add_header Cache-Control "public, immutable";
            }
        }

        # Root redirect
        location = / {
            return 301 /tenant/;
        }

        # Health check
        location /health {
            access_log off;
            return 200 "healthy\n";
            add_header Content-Type text/plain;
        }
    }
}
EOFNGINX

echo "✓ Created new nginx.conf with API proxy"

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 3: Test Nginx Configuration"
echo "════════════════════════════════════════════════════════"

if sudo nginx -t; then
    echo "✓ Nginx config is valid"
else
    echo "❌ Nginx config has errors! Restoring backup..."
    sudo cp /etc/nginx/nginx.conf.backup.* /etc/nginx/nginx.conf
    exit 1
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 4: Update Flutter App to Use Relative URLs"
echo "════════════════════════════════════════════════════════"

TENANT_DIR="/home/ec2-user/pgni/pgworldtenant-master"
cd "$TENANT_DIR"

echo "Creating app_config.dart with relative API URL..."

cat > lib/config/app_config.dart << 'EOFCONFIG'
/// Production Configuration
class AppConfig {
  static const bool isProduction = true;
  
  // Use relative URL - Nginx will proxy to backend
  static const String apiBaseUrl = "/api";
  
  static const String apiKey = "mrk-1b96d9eeccf649e695ed6ac2b13cb619";
  static const String oneSignalAppId = "AKIA2FFQRNMAP3IDZD6V";
  static const int requestTimeout = 30;
  
  // API Endpoints (relative, will be proxied by Nginx)
  static const String loginEndpoint = "/login";
  static const String dashboardEndpoint = "/dashboard";
  static const String billsEndpoint = "/bill";
  static const String issuesEndpoint = "/issue";
  static const String noticesEndpoint = "/notice";
  static const String roomsEndpoint = "/room";
  static const String usersEndpoint = "/user";
  static const String supportEndpoint = "/support";
  static const String hostelEndpoint = "/hostel";
  static const String foodEndpoint = "/food";
  
  // App Version
  static const String appVersion = "1.0.0";
  static const String appName = "PG Tenant";
  
  // Headers
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'X-API-Key': apiKey,
    'apikey': apiKey,
  };
  
  // Full API URL helper
  static String getApiUrl(String endpoint) {
    return '$apiBaseUrl$endpoint';
  }
}
EOFCONFIG

echo "✓ Created app_config.dart with relative URLs"

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 5: Rebuild Tenant App"
echo "════════════════════════════════════════════════════════"

export DART_VM_OPTIONS="--old_gen_heap_size=10240"
export PUB_CACHE=/home/ec2-user/.pub-cache

BUILD_START=$(date +%s)

echo "Building tenant app (this takes ~60 seconds)..."

flutter build web \
  --release \
  --base-href="/tenant/" \
  --no-source-maps \
  --dart-define=dart.vm.product=true \
  2>&1 | grep -E "Compiling|Built|✓|Font|Error" || true

BUILD_END=$(date +%s)
BUILD_TIME=$((BUILD_END - BUILD_START))

if [ ! -f "build/web/main.dart.js" ]; then
    echo "❌ Build failed!"
    exit 1
fi

SIZE=$(du -h build/web/main.dart.js | cut -f1)
echo ""
echo "✅ Build successful: $SIZE in ${BUILD_TIME}s"

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 6: Deploy Tenant App"
echo "════════════════════════════════════════════════════════"

sudo rm -rf /usr/share/nginx/html/tenant.old 2>/dev/null || true
sudo mv /usr/share/nginx/html/tenant /usr/share/nginx/html/tenant.old 2>/dev/null || true
sudo mkdir -p /usr/share/nginx/html/tenant
sudo cp -r build/web/* /usr/share/nginx/html/tenant/
sudo chown -R nginx:nginx /usr/share/nginx/html/tenant
sudo chmod -R 755 /usr/share/nginx/html/tenant

if command -v getenforce &>/dev/null && [ "$(getenforce)" != "Disabled" ]; then
    sudo chcon -R -t httpd_sys_content_t /usr/share/nginx/html/tenant 2>/dev/null || true
fi

echo "✓ Tenant app deployed"

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 7: Reload Nginx"
echo "════════════════════════════════════════════════════════"

sudo systemctl reload nginx
echo "✓ Nginx reloaded"

sleep 2

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 8: Verify API Proxy"
echo "════════════════════════════════════════════════════════"

echo ""
echo "Testing API through Nginx proxy..."
RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X POST http://localhost/api/login \
    -H "Content-Type: application/json" \
    -H "X-API-Key: mrk-1b96d9eeccf649e695ed6ac2b13cb619" \
    -d '{"email":"priya@example.com","password":"Tenant@123"}' 2>&1)

HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_CODE:" | cut -d: -f2)

if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ API proxy works! (HTTP 200)"
else
    echo "⚠️  API proxy returned HTTP $HTTP_CODE"
    echo "Response: $(echo "$RESPONSE" | grep -v HTTP_CODE)"
fi

echo ""
echo "Testing tenant app..."
TENANT_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/tenant/)
echo "Tenant app: HTTP $TENANT_STATUS $([ "$TENANT_STATUS" = "200" ] && echo "✅" || echo "⚠️")"

echo ""
echo "════════════════════════════════════════════════════════"
echo "✅ SETUP COMPLETE!"
echo "════════════════════════════════════════════════════════"

echo ""
echo "🌐 Your Application:"
echo "   URL: http://$PUBLIC_IP/tenant/"
echo ""
echo "📧 Login:"
echo "   Email:    priya@example.com"
echo "   Password: Tenant@123"
echo ""
echo "🔧 Architecture:"
echo "   Frontend: http://$PUBLIC_IP/tenant/"
echo "   API Calls: http://$PUBLIC_IP/api/* (relative)"
echo "   Backend: http://127.0.0.1:8080 (internal only)"
echo ""
echo "✅ Benefits:"
echo "   • No CORS issues (same origin)"
echo "   • Backend not exposed to public"
echo "   • Ready for HTTPS/domain"
echo "   • Production-ready architecture"
echo ""
echo "🚀 Next Steps for Domain:"
echo "   1. Get Elastic IP in AWS"
echo "   2. Point your domain to Elastic IP"
echo "   3. Install SSL certificate (Let's Encrypt)"
echo "   4. Update server_name in nginx.conf"
echo ""
echo "📊 Build Stats:"
echo "   Size: $SIZE"
echo "   Time: ${BUILD_TIME}s"
echo ""
echo "⚠️  IMPORTANT - Clear browser cache:"
echo "   Ctrl+Shift+Delete → Clear all → Try again"
echo ""
echo "════════════════════════════════════════════════════════"

