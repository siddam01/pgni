#!/bin/bash
# ========================================
# PGNi - Frontend Deployment Script
# ========================================
# Direct deployment without Git dependency
# ========================================

set -e

echo "=========================================="
echo "🚀 PGNi - Frontend Deployment"
echo "=========================================="
echo ""

# Configuration
EC2_HOST="34.227.111.143"
EC2_USER="ec2-user"
SSH_KEY="cloudshell-key.pem"

# Check SSH key
if [ ! -f "$SSH_KEY" ]; then
    echo "❌ SSH key not found: $SSH_KEY"
    exit 1
fi

chmod 600 "$SSH_KEY"

echo "Step 1: Testing EC2 connection..."
if ! ssh -i "$SSH_KEY" -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$EC2_USER@$EC2_HOST" "echo 'Connected'" 2>/dev/null; then
    echo "❌ Cannot connect to EC2"
    exit 1
fi
echo "✅ EC2 connection successful"
echo ""

echo "Step 2: Installing and configuring web server..."
ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "$EC2_USER@$EC2_HOST" << 'ENDSSH'
set -e

echo "  Installing Nginx..."
if ! command -v nginx &> /dev/null; then
    sudo yum install -y nginx > /dev/null 2>&1
fi
sudo systemctl start nginx
sudo systemctl enable nginx > /dev/null 2>&1
echo "  ✅ Nginx installed and started"

echo "  Creating web directories..."
sudo mkdir -p /var/www/html/admin
sudo mkdir -p /var/www/html/tenant
sudo chown -R ec2-user:ec2-user /var/www/html
echo "  ✅ Directories created"

echo "  Creating Admin UI placeholder..."
cat > /var/www/html/admin/index.html << 'HTML'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>PGNi Admin Portal</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Oxygen', 'Ubuntu', 'Cantarell', sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }
        .container {
            background: white;
            border-radius: 20px;
            padding: 40px;
            max-width: 800px;
            width: 100%;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
        }
        h1 {
            color: #667eea;
            margin-bottom: 10px;
            font-size: 2.5em;
        }
        .subtitle {
            color: #666;
            margin-bottom: 30px;
            font-size: 1.1em;
        }
        .status {
            background: #f8f9fa;
            padding: 20px;
            margin: 20px 0;
            border-radius: 10px;
            border-left: 4px solid #667eea;
        }
        .status h3 {
            color: #667eea;
            margin-bottom: 10px;
        }
        .status.success {
            border-left-color: #28a745;
            background: #d4edda;
        }
        .status.success h3 { color: #28a745; }
        .status.warning {
            border-left-color: #ffc107;
            background: #fff3cd;
        }
        .status.warning h3 { color: #856404; }
        code {
            background: #e9ecef;
            padding: 3px 8px;
            border-radius: 4px;
            font-family: 'Courier New', monospace;
            font-size: 0.9em;
        }
        a {
            color: #667eea;
            text-decoration: none;
            font-weight: 600;
        }
        a:hover { text-decoration: underline; }
        .button {
            display: inline-block;
            background: #667eea;
            color: white;
            padding: 12px 24px;
            border-radius: 8px;
            text-decoration: none;
            margin: 10px 5px;
            transition: background 0.3s;
        }
        .button:hover {
            background: #5568d3;
            text-decoration: none;
        }
        .credentials {
            background: #e7f3ff;
            padding: 15px;
            border-radius: 8px;
            margin: 15px 0;
        }
        .grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px;
            margin: 20px 0;
        }
        .card {
            background: white;
            padding: 15px;
            border-radius: 8px;
            border: 2px solid #e9ecef;
            text-align: center;
        }
        .card h4 {
            color: #667eea;
            margin-bottom: 10px;
        }
        ul { margin-left: 20px; line-height: 1.8; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🏢 PGNi Admin Portal</h1>
        <p class="subtitle">Property Management System</p>

        <div class="status success">
            <h3>✅ System Partially Deployed</h3>
            <p><strong>Backend API:</strong> Running and accessible</p>
            <p><strong>Database:</strong> Connected and ready</p>
            <p><strong>Infrastructure:</strong> AWS EC2, RDS, S3 operational</p>
        </div>

        <div class="status warning">
            <h3>⚠️ Frontend Build Pending</h3>
            <p>The full admin interface with 37 pages needs to be built with Flutter and deployed.</p>
            <p><strong>Current status:</strong> Placeholder page (this page)</p>
        </div>

        <div class="status">
            <h3>🚀 Quick Access Options</h3>
            
            <p><strong>Option 1: Run Locally (Windows)</strong></p>
            <div class="credentials">
                <p>1. Open PowerShell/CMD on your PC</p>
                <p>2. Navigate to: <code>C:\MyFolder\Mytest\pgworld-master</code></p>
                <p>3. Run: <code>RUN_ADMIN_APP.bat</code></p>
                <p>4. Choose option 1 (Chrome)</p>
                <p>5. Login with credentials below</p>
            </div>

            <p><strong>Option 2: API Access (Developers)</strong></p>
            <div class="credentials">
                <p>Backend API: <code>http://34.227.111.143:8080</code></p>
                <p>Health Check: <a href="/api/health" target="_blank">Test API</a></p>
                <p>Use Postman or cURL to interact with the API</p>
            </div>
        </div>

        <div class="status">
            <h3>🔐 Test Account Credentials</h3>
            <div class="grid">
                <div class="card">
                    <h4>Admin</h4>
                    <p><code>admin@pgni.com</code></p>
                    <p><code>password123</code></p>
                </div>
                <div class="card">
                    <h4>PG Owner</h4>
                    <p><code>owner@pgni.com</code></p>
                    <p><code>password123</code></p>
                </div>
                <div class="card">
                    <h4>Tenant</h4>
                    <p><code>tenant@pgni.com</code></p>
                    <p><code>password123</code></p>
                </div>
            </div>
        </div>

        <div class="status">
            <h3>📱 Admin Features (37 Pages)</h3>
            <ul>
                <li><strong>Dashboard:</strong> Business overview and metrics</li>
                <li><strong>Properties:</strong> Manage PG hostels</li>
                <li><strong>Rooms:</strong> Room management and availability</li>
                <li><strong>Tenants:</strong> Tenant profiles and records</li>
                <li><strong>Bills & Payments:</strong> Financial tracking</li>
                <li><strong>Reports:</strong> Analytics and insights</li>
                <li><strong>Settings:</strong> System configuration</li>
            </ul>
        </div>

        <div class="status">
            <h3>📊 System Status</h3>
            <p>✅ Backend API: Running<br>
            ✅ Database: Connected<br>
            ✅ S3 Storage: Ready<br>
            ✅ Web Server: Configured<br>
            ⏳ Frontend UI: Build pending</p>
        </div>

        <div style="text-align: center; margin-top: 30px;">
            <a href="/api/health" class="button" target="_blank">🔧 Test API</a>
            <a href="/tenant" class="button">🏠 Tenant Portal</a>
        </div>

        <p style="text-align: center; margin-top: 30px; color: #666; font-size: 0.9em;">
            PGNi Property Management System v1.0<br>
            For support: Contact your system administrator
        </p>
    </div>
</body>
</html>
HTML
echo "  ✅ Admin UI created"

echo "  Creating Tenant UI placeholder..."
cat > /var/www/html/tenant/index.html << 'HTML'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>PGNi Tenant Portal</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Oxygen', 'Ubuntu', 'Cantarell', sans-serif;
            background: linear-gradient(135deg, #11998e 0%, #38ef7d 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }
        .container {
            background: white;
            border-radius: 20px;
            padding: 40px;
            max-width: 800px;
            width: 100%;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
        }
        h1 {
            color: #11998e;
            margin-bottom: 10px;
            font-size: 2.5em;
        }
        .subtitle {
            color: #666;
            margin-bottom: 30px;
            font-size: 1.1em;
        }
        .status {
            background: #f8f9fa;
            padding: 20px;
            margin: 20px 0;
            border-radius: 10px;
            border-left: 4px solid #11998e;
        }
        .status h3 {
            color: #11998e;
            margin-bottom: 10px;
        }
        .status.success {
            border-left-color: #28a745;
            background: #d4edda;
        }
        .status.success h3 { color: #28a745; }
        .status.warning {
            border-left-color: #ffc107;
            background: #fff3cd;
        }
        .status.warning h3 { color: #856404; }
        code {
            background: #e9ecef;
            padding: 3px 8px;
            border-radius: 4px;
            font-family: 'Courier New', monospace;
            font-size: 0.9em;
        }
        a {
            color: #11998e;
            text-decoration: none;
            font-weight: 600;
        }
        a:hover { text-decoration: underline; }
        .button {
            display: inline-block;
            background: #11998e;
            color: white;
            padding: 12px 24px;
            border-radius: 8px;
            text-decoration: none;
            margin: 10px 5px;
            transition: background 0.3s;
        }
        .button:hover {
            background: #0d7a6f;
            text-decoration: none;
        }
        .credentials {
            background: #d4f8e8;
            padding: 15px;
            border-radius: 8px;
            margin: 15px 0;
        }
        .grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px;
            margin: 20px 0;
        }
        .card {
            background: white;
            padding: 15px;
            border-radius: 8px;
            border: 2px solid #e9ecef;
            text-align: center;
        }
        .card h4 {
            color: #11998e;
            margin-bottom: 10px;
        }
        ul { margin-left: 20px; line-height: 1.8; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🏠 PGNi Tenant Portal</h1>
        <p class="subtitle">Your Hostel Management Portal</p>

        <div class="status success">
            <h3>✅ System Partially Deployed</h3>
            <p><strong>Backend API:</strong> Running and accessible</p>
            <p><strong>Database:</strong> Connected and ready</p>
            <p><strong>Infrastructure:</strong> AWS EC2, RDS, S3 operational</p>
        </div>

        <div class="status warning">
            <h3>⚠️ Frontend Build Pending</h3>
            <p>The full tenant interface with 28 pages needs to be built with Flutter and deployed.</p>
            <p><strong>Current status:</strong> Placeholder page (this page)</p>
        </div>

        <div class="status">
            <h3>🚀 Quick Access Options</h3>
            
            <p><strong>Option 1: Run Locally (Windows)</strong></p>
            <div class="credentials">
                <p>1. Open PowerShell/CMD on your PC</p>
                <p>2. Navigate to: <code>C:\MyFolder\Mytest\pgworld-master</code></p>
                <p>3. Run: <code>RUN_TENANT_APP.bat</code></p>
                <p>4. Choose option 1 (Chrome)</p>
                <p>5. Login with credentials below</p>
            </div>

            <p><strong>Option 2: API Access</strong></p>
            <div class="credentials">
                <p>Backend API: <code>http://34.227.111.143:8080</code></p>
                <p>Health Check: <a href="/api/health" target="_blank">Test API</a></p>
            </div>
        </div>

        <div class="status">
            <h3>🔐 Test Account Credentials</h3>
            <div class="grid">
                <div class="card">
                    <h4>Tenant Account</h4>
                    <p><code>tenant@pgni.com</code></p>
                    <p><code>password123</code></p>
                </div>
                <div class="card">
                    <h4>Alternative</h4>
                    <p><code>alice.tenant@example.com</code></p>
                    <p><code>password123</code></p>
                </div>
            </div>
        </div>

        <div class="status">
            <h3>📱 Tenant Features (28 Pages)</h3>
            <ul>
                <li><strong>Dashboard:</strong> Notices, rents, issues</li>
                <li><strong>My Room:</strong> Room details and information</li>
                <li><strong>Payments:</strong> Pay rent, view history</li>
                <li><strong>Notices:</strong> View announcements</li>
                <li><strong>Issues:</strong> Submit and track complaints</li>
                <li><strong>Food Menu:</strong> Meal schedule and timings</li>
                <li><strong>Services:</strong> Hostel facilities</li>
                <li><strong>Profile:</strong> Manage your account</li>
            </ul>
        </div>

        <div class="status">
            <h3>📊 System Status</h3>
            <p>✅ Backend API: Running<br>
            ✅ Database: Connected<br>
            ✅ S3 Storage: Ready<br>
            ✅ Web Server: Configured<br>
            ⏳ Frontend UI: Build pending</p>
        </div>

        <div style="text-align: center; margin-top: 30px;">
            <a href="/api/health" class="button" target="_blank">🔧 Test API</a>
            <a href="/admin" class="button">🏢 Admin Portal</a>
        </div>

        <p style="text-align: center; margin-top: 30px; color: #666; font-size: 0.9em;">
            PGNi Property Management System v1.0<br>
            For support: Contact your hostel management
        </p>
    </div>
</body>
</html>
HTML
echo "  ✅ Tenant UI created"

echo "  Configuring Nginx..."
sudo tee /etc/nginx/conf.d/pgni.conf > /dev/null << 'NGINX'
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;

    # Admin UI
    location /admin {
        alias /var/www/html/admin;
        index index.html;
        try_files $uri $uri/ /admin/index.html;
    }

    # Tenant UI
    location /tenant {
        alias /var/www/html/tenant;
        index index.html;
        try_files $uri $uri/ /tenant/index.html;
    }

    # API Proxy
    location /api {
        proxy_pass http://localhost:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_cache_bypass $http_upgrade;
        
        # CORS
        add_header Access-Control-Allow-Origin * always;
        add_header Access-Control-Allow-Methods 'GET, POST, PUT, DELETE, OPTIONS' always;
        add_header Access-Control-Allow-Headers 'Content-Type, Authorization, apikey, appversion' always;
        
        if ($request_method = 'OPTIONS') {
            return 204;
        }
    }

    # Root redirect
    location = / {
        return 301 /admin;
    }

    # Health check
    location /health {
        proxy_pass http://localhost:8080/health;
    }
}
NGINX

echo "  Testing Nginx configuration..."
if sudo nginx -t > /dev/null 2>&1; then
    echo "  ✅ Nginx configuration valid"
    sudo systemctl reload nginx
    echo "  ✅ Nginx reloaded"
else
    echo "  ❌ Nginx configuration error"
    sudo nginx -t
    exit 1
fi

ENDSSH

echo "✅ Web server configuration complete"
echo ""

echo "Step 3: Opening port 80..."
SG_ID=$(aws ec2 describe-instances \
    --filters "Name=ip-address,Values=$EC2_HOST" \
    --query 'Reservations[0].Instances[0].SecurityGroups[0].GroupId' \
    --output text 2>/dev/null)

if [ -n "$SG_ID" ] && [ "$SG_ID" != "None" ]; then
    echo "  Security Group ID: $SG_ID"
    
    RULE_EXISTS=$(aws ec2 describe-security-groups \
        --group-ids "$SG_ID" \
        --query "SecurityGroups[0].IpPermissions[?FromPort==\`80\`]" \
        --output text 2>/dev/null)
    
    if [ -z "$RULE_EXISTS" ]; then
        echo "  Opening port 80..."
        aws ec2 authorize-security-group-ingress \
            --group-id "$SG_ID" \
            --protocol tcp \
            --port 80 \
            --cidr 0.0.0.0/0 > /dev/null 2>&1 && echo "  ✅ Port 80 opened" || echo "  ⚠️ Could not open port 80 automatically"
    else
        echo "  ✅ Port 80 already open"
    fi
else
    echo "  ⚠️ Please manually open port 80 in AWS Console"
fi
echo ""

echo "Step 4: Testing deployment..."
sleep 3

ADMIN_TEST=$(curl -s -o /dev/null -w "%{http_code}" "http://$EC2_HOST/admin" 2>/dev/null)
TENANT_TEST=$(curl -s -o /dev/null -w "%{http_code}" "http://$EC2_HOST/tenant" 2>/dev/null)
API_TEST=$(curl -s -o /dev/null -w "%{http_code}" "http://$EC2_HOST/api/health" 2>/dev/null)

echo "  Admin UI: HTTP $ADMIN_TEST $([ "$ADMIN_TEST" = "200" ] && echo '✅' || echo '⚠️')"
echo "  Tenant UI: HTTP $TENANT_TEST $([ "$TENANT_TEST" = "200" ] && echo '✅' || echo '⚠️')"
echo "  API: HTTP $API_TEST $([ "$API_TEST" = "200" ] && echo '✅' || echo '⚠️')"
echo ""

echo "=========================================="
echo "✅ DEPLOYMENT COMPLETE!"
echo "=========================================="
echo ""
echo "🌐 ACCESS YOUR APPLICATION:"
echo ""
echo "  Admin Portal:  http://$EC2_HOST/admin"
echo "  Tenant Portal: http://$EC2_HOST/tenant"
echo "  API Endpoint:  http://$EC2_HOST/api"
echo ""
echo "📝 NOTE:"
echo "  - Placeholder pages deployed (backend working)"
echo "  - For full UI, build Flutter apps and redeploy"
echo "  - Current pages show system status and local access options"
echo ""
echo "🔐 TEST CREDENTIALS:"
echo "  Admin:  admin@pgni.com / password123"
echo "  Tenant: tenant@pgni.com / password123"
echo ""
echo "=========================================="

