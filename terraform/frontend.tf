# Frontend Deployment Configuration
# Automatically deploys Nginx web server and frontend placeholder pages

# Local variables for frontend HTML content
locals {
  # Admin UI HTML
  admin_html = <<-HTML
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>PGNi Admin Portal</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', sans-serif;
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
        h1 { color: #667eea; margin-bottom: 10px; font-size: 2.5em; }
        .subtitle { color: #666; margin-bottom: 30px; font-size: 1.1em; }
        .status {
            background: #f8f9fa;
            padding: 20px;
            margin: 20px 0;
            border-radius: 10px;
            border-left: 4px solid #667eea;
        }
        .status h3 { color: #667eea; margin-bottom: 10px; }
        .success { border-left-color: #28a745; background: #d4edda; }
        .success h3 { color: #28a745; }
        .warning { border-left-color: #ffc107; background: #fff3cd; }
        .warning h3 { color: #856404; }
        code {
            background: #e9ecef;
            padding: 3px 8px;
            border-radius: 4px;
            font-family: 'Courier New', monospace;
        }
        a { color: #667eea; text-decoration: none; font-weight: 600; }
        .button {
            display: inline-block;
            background: #667eea;
            color: white;
            padding: 12px 24px;
            border-radius: 8px;
            margin: 10px 5px;
            text-decoration: none;
        }
        .credentials { background: #e7f3ff; padding: 15px; border-radius: 8px; margin: 15px 0; }
        ul { margin-left: 20px; line-height: 1.8; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🏢 PGNi Admin Portal</h1>
        <p class="subtitle">Property Management System</p>
        
        <div class="status success">
            <h3>✅ System Deployed via Terraform</h3>
            <p><strong>Backend API:</strong> Running on port 8080</p>
            <p><strong>Database:</strong> RDS MySQL connected</p>
            <p><strong>Infrastructure:</strong> Fully automated with IaC</p>
        </div>

        <div class="status warning">
            <h3>⚠️ Full Flutter UI Pending</h3>
            <p>The complete admin interface (37 pages) can be deployed by building Flutter web and updating this directory.</p>
            <p><strong>Current status:</strong> Placeholder page</p>
        </div>

        <div class="status">
            <h3>🚀 Quick Access Options</h3>
            <p><strong>Run Locally (Windows):</strong></p>
            <div class="credentials">
                <p>1. Navigate to project directory</p>
                <p>2. Run: <code>RUN_ADMIN_APP.bat</code></p>
                <p>3. Choose option 1 (Chrome)</p>
                <p>4. Login with test credentials below</p>
            </div>
            <p><strong>API Access:</strong> <a href="/api/health">Test Backend API</a></p>
        </div>

        <div class="status">
            <h3>🔐 Test Credentials</h3>
            <div class="credentials">
                <p><strong>Email:</strong> <code>admin@pgni.com</code></p>
                <p><strong>Password:</strong> <code>password123</code></p>
            </div>
        </div>

        <div class="status">
            <h3>📱 Admin Features (37 Pages)</h3>
            <ul>
                <li>Dashboard with business metrics</li>
                <li>Property management</li>
                <li>Room availability tracking</li>
                <li>Tenant profiles and records</li>
                <li>Bills and payment tracking</li>
                <li>Reports and analytics</li>
                <li>System configuration</li>
            </ul>
        </div>

        <div style="text-align: center; margin-top: 30px;">
            <a href="/api/health" class="button">🔧 Test API</a>
            <a href="/tenant" class="button">🏠 Tenant Portal</a>
        </div>

        <p style="text-align: center; margin-top: 30px; color: #666; font-size: 0.9em;">
            Deployed with Terraform | PGNi v1.0
        </p>
    </div>
</body>
</html>
HTML

  # Tenant UI HTML
  tenant_html = <<-HTML
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>PGNi Tenant Portal</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', sans-serif;
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
        h1 { color: #11998e; margin-bottom: 10px; font-size: 2.5em; }
        .subtitle { color: #666; margin-bottom: 30px; font-size: 1.1em; }
        .status {
            background: #f8f9fa;
            padding: 20px;
            margin: 20px 0;
            border-radius: 10px;
            border-left: 4px solid #11998e;
        }
        .status h3 { color: #11998e; margin-bottom: 10px; }
        .success { border-left-color: #28a745; background: #d4edda; }
        .success h3 { color: #28a745; }
        .warning { border-left-color: #ffc107; background: #fff3cd; }
        .warning h3 { color: #856404; }
        code {
            background: #e9ecef;
            padding: 3px 8px;
            border-radius: 4px;
            font-family: 'Courier New', monospace;
        }
        a { color: #11998e; text-decoration: none; font-weight: 600; }
        .button {
            display: inline-block;
            background: #11998e;
            color: white;
            padding: 12px 24px;
            border-radius: 8px;
            margin: 10px 5px;
            text-decoration: none;
        }
        .credentials { background: #d4f8e8; padding: 15px; border-radius: 8px; margin: 15px 0; }
        ul { margin-left: 20px; line-height: 1.8; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🏠 PGNi Tenant Portal</h1>
        <p class="subtitle">Your Hostel Management Portal</p>
        
        <div class="status success">
            <h3>✅ System Deployed via Terraform</h3>
            <p><strong>Backend API:</strong> Running on port 8080</p>
            <p><strong>Database:</strong> RDS MySQL connected</p>
            <p><strong>Infrastructure:</strong> Fully automated with IaC</p>
        </div>

        <div class="status warning">
            <h3>⚠️ Full Flutter UI Pending</h3>
            <p>The complete tenant interface (28 pages) can be deployed by building Flutter web and updating this directory.</p>
            <p><strong>Current status:</strong> Placeholder page</p>
        </div>

        <div class="status">
            <h3>🚀 Quick Access Options</h3>
            <p><strong>Run Locally (Windows):</strong></p>
            <div class="credentials">
                <p>1. Navigate to project directory</p>
                <p>2. Run: <code>RUN_TENANT_APP.bat</code></p>
                <p>3. Choose option 1 (Chrome)</p>
                <p>4. Login with test credentials below</p>
            </div>
            <p><strong>API Access:</strong> <a href="/api/health">Test Backend API</a></p>
        </div>

        <div class="status">
            <h3>🔐 Test Credentials</h3>
            <div class="credentials">
                <p><strong>Email:</strong> <code>tenant@pgni.com</code></p>
                <p><strong>Password:</strong> <code>password123</code></p>
            </div>
        </div>

        <div class="status">
            <h3>📱 Tenant Features (28 Pages)</h3>
            <ul>
                <li>Dashboard (Notices, Rents, Issues)</li>
                <li>My room details</li>
                <li>Pay rent online</li>
                <li>Submit maintenance requests</li>
                <li>View food menu and timings</li>
                <li>Access hostel services</li>
                <li>Manage profile and documents</li>
            </ul>
        </div>

        <div style="text-align: center; margin-top: 30px;">
            <a href="/api/health" class="button">🔧 Test API</a>
            <a href="/admin" class="button">🏢 Admin Portal</a>
        </div>

        <p style="text-align: center; margin-top: 30px; color: #666; font-size: 0.9em;">
            Deployed with Terraform | PGNi v1.0
        </p>
    </div>
</body>
</html>
HTML

  # Nginx configuration
  nginx_config = <<-NGINX
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Admin UI
    location /admin {
        alias /var/www/html/admin;
        index index.html;
        try_files $uri $uri/ /admin/index.html;
        
        # CORS headers
        add_header Access-Control-Allow-Origin * always;
        add_header Access-Control-Allow-Methods 'GET, POST, OPTIONS' always;
        add_header Access-Control-Allow-Headers 'Content-Type, Authorization' always;
    }

    # Tenant UI
    location /tenant {
        alias /var/www/html/tenant;
        index index.html;
        try_files $uri $uri/ /tenant/index.html;
        
        # CORS headers
        add_header Access-Control-Allow-Origin * always;
        add_header Access-Control-Allow-Methods 'GET, POST, OPTIONS' always;
        add_header Access-Control-Allow-Headers 'Content-Type, Authorization' always;
    }

    # API Proxy to backend
    location /api {
        proxy_pass http://localhost:8080;
        proxy_http_version 1.1;
        
        # Proxy headers
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        
        # CORS headers
        add_header Access-Control-Allow-Origin * always;
        add_header Access-Control-Allow-Methods 'GET, POST, PUT, DELETE, OPTIONS' always;
        add_header Access-Control-Allow-Headers 'Content-Type, Authorization, apikey, appversion' always;
        
        # Handle preflight requests
        if ($request_method = 'OPTIONS') {
            return 204;
        }
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # Health check endpoint
    location /health {
        proxy_pass http://localhost:8080/health;
        access_log off;
    }

    # Root redirect to admin
    location = / {
        return 301 /admin;
    }

    # Custom error pages
    error_page 404 /404.html;
    error_page 500 502 503 504 /50x.html;
}
NGINX
}

# Null resource to deploy frontend files via SSH
resource "null_resource" "deploy_frontend" {
  # Trigger redeployment when HTML content changes
  triggers = {
    admin_html_hash  = md5(local.admin_html)
    tenant_html_hash = md5(local.tenant_html)
    nginx_config_hash = md5(local.nginx_config)
    instance_id      = aws_instance.api.id
  }

  # Wait for instance to be ready
  depends_on = [
    aws_instance.api,
    aws_security_group.ec2
  ]

  # Provisioner to install Nginx and deploy frontend
  provisioner "remote-exec" {
    inline = [
      "set -e",
      "echo '=========================================='",
      "echo 'Deploying Frontend Infrastructure'",
      "echo '=========================================='",
      "",
      "# Install Nginx",
      "echo 'Step 1: Installing Nginx...'",
      "sudo yum install -y nginx > /dev/null 2>&1",
      "sudo systemctl start nginx",
      "sudo systemctl enable nginx > /dev/null 2>&1",
      "echo '✓ Nginx installed'",
      "",
      "# Create web directories",
      "echo 'Step 2: Creating web directories...'",
      "sudo mkdir -p /var/www/html/admin",
      "sudo mkdir -p /var/www/html/tenant",
      "sudo chown -R ec2-user:ec2-user /var/www/html",
      "echo '✓ Directories created'",
      "",
      "# Create Admin UI",
      "echo 'Step 3: Deploying Admin UI...'",
      "cat > /var/www/html/admin/index.html << 'ADMIN_EOF'",
      local.admin_html,
      "ADMIN_EOF",
      "echo '✓ Admin UI deployed'",
      "",
      "# Create Tenant UI",
      "echo 'Step 4: Deploying Tenant UI...'",
      "cat > /var/www/html/tenant/index.html << 'TENANT_EOF'",
      local.tenant_html,
      "TENANT_EOF",
      "echo '✓ Tenant UI deployed'",
      "",
      "# Configure Nginx",
      "echo 'Step 5: Configuring Nginx...'",
      "sudo tee /etc/nginx/conf.d/pgni.conf > /dev/null << 'NGINX_EOF'",
      local.nginx_config,
      "NGINX_EOF",
      "",
      "# Test and reload Nginx",
      "if sudo nginx -t > /dev/null 2>&1; then",
      "  echo '✓ Nginx configuration valid'",
      "  sudo systemctl reload nginx",
      "  echo '✓ Nginx reloaded'",
      "else",
      "  echo '✗ Nginx configuration error'",
      "  sudo nginx -t",
      "  exit 1",
      "fi",
      "",
      "echo '=========================================='",
      "echo '✓ Frontend Deployment Complete!'",
      "echo '=========================================='",
      "echo ''",
      "echo 'Access URLs:'",
      "echo '  Admin:  http://${aws_instance.api.public_ip}/admin'",
      "echo '  Tenant: http://${aws_instance.api.public_ip}/tenant'",
      "echo '  API:    http://${aws_instance.api.public_ip}/api'",
      "echo ''",
    ]

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = tls_private_key.ec2_key.private_key_pem
      host        = aws_instance.api.public_ip
      timeout     = "5m"
    }
  }
}

# Output frontend URLs
output "admin_url" {
  description = "Admin portal URL"
  value       = "http://${aws_instance.api.public_ip}/admin"
}

output "tenant_url" {
  description = "Tenant portal URL"
  value       = "http://${aws_instance.api.public_ip}/tenant"
}

output "api_url" {
  description = "API endpoint URL"
  value       = "http://${aws_instance.api.public_ip}/api"
}

output "frontend_deployment_info" {
  description = "Frontend deployment information"
  value = {
    nginx_installed    = "Yes - Automated via Terraform"
    admin_pages_ready  = "Placeholder deployed, ready for Flutter build"
    tenant_pages_ready = "Placeholder deployed, ready for Flutter build"
    port_80_enabled    = "Yes - via security group"
    deployment_method  = "Infrastructure as Code (Terraform)"
  }
}

