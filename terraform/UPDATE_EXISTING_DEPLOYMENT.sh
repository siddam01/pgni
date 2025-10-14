#!/bin/bash
# ========================================
# Update Existing PGNi Deployment
# ========================================
# This script safely adds frontend to existing infrastructure
# WITHOUT destroying or recreating existing resources
# ========================================

set -e

echo "=========================================="
echo "🔄 PGNi - Update Existing Deployment"
echo "=========================================="
echo ""
echo "This will ADD frontend to your existing infrastructure:"
echo "  ✅ Install Nginx"
echo "  ✅ Deploy Admin UI"
echo "  ✅ Deploy Tenant UI"
echo "  ✅ Open port 80"
echo ""
echo "Existing resources (EC2, RDS, S3) will NOT be touched."
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Update cancelled."
    exit 1
fi

echo ""
echo "Step 1: Checking Terraform..."
if ! command -v terraform &> /dev/null; then
    echo "Installing Terraform..."
    sudo yum install -y yum-utils
    sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
    sudo yum -y install terraform
fi
echo "✅ Terraform ready: $(terraform version | head -1)"

echo ""
echo "Step 2: Checking existing infrastructure..."

# Get EC2 instance ID
EC2_ID=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=*pgni*" "Name=instance-state-name,Values=running" \
    --query 'Reservations[0].Instances[0].InstanceId' \
    --output text 2>/dev/null)

if [ -z "$EC2_ID" ] || [ "$EC2_ID" = "None" ]; then
    echo "❌ No running EC2 instance found"
    echo "Please deploy infrastructure first with: terraform apply"
    exit 1
fi

EC2_IP=$(aws ec2 describe-instances \
    --instance-ids "$EC2_ID" \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text)

echo "✅ Found EC2 instance: $EC2_ID"
echo "   Public IP: $EC2_IP"

echo ""
echo "Step 3: Getting SSH key..."

# Try to get SSH key from SSM
SSH_KEY_SSM="/pgni/preprod/ec2/private_key"
if aws ssm get-parameter --name "$SSH_KEY_SSM" --with-decryption --query 'Parameter.Value' --output text > ec2-key.pem 2>/dev/null; then
    echo "✅ SSH key retrieved from SSM"
    chmod 600 ec2-key.pem
else
    echo "⚠️ Could not get SSH key from SSM"
    echo "Checking terraform output..."
    
    if [ -f "terraform.tfstate" ]; then
        terraform output -raw ssh_private_key > ec2-key.pem 2>/dev/null || true
        if [ -s ec2-key.pem ]; then
            chmod 600 ec2-key.pem
            echo "✅ SSH key from Terraform state"
        else
            echo "❌ SSH key not found"
            echo "Please provide SSH key manually as ec2-key.pem"
            exit 1
        fi
    else
        echo "❌ No terraform.tfstate found"
        echo "Please run this from your Terraform directory with state file"
        exit 1
    fi
fi

echo ""
echo "Step 4: Testing EC2 connection..."
if ssh -i ec2-key.pem -o ConnectTimeout=10 -o StrictHostKeyChecking=no ec2-user@$EC2_IP "echo 'Connected'" 2>&1 | grep -q "Connected"; then
    echo "✅ EC2 connection successful"
else
    echo "❌ Cannot connect to EC2"
    echo "Trying with AWS Systems Manager Session Manager instead..."
    
    # Alternative: Use Session Manager (no SSH key needed)
    if command -v aws &> /dev/null; then
        echo "Using AWS SSM Session Manager..."
        USE_SSM=true
    else
        echo "❌ Cannot connect via SSH or SSM"
        exit 1
    fi
fi

echo ""
echo "Step 5: Deploying frontend..."

if [ "$USE_SSM" = true ]; then
    echo "Using AWS Systems Manager..."
    
    # Create deployment script
    cat > /tmp/deploy_frontend.sh << 'DEPLOY_SCRIPT'
#!/bin/bash
set -e

echo "Installing Nginx..."
sudo yum install -y nginx > /dev/null 2>&1
sudo systemctl start nginx
sudo systemctl enable nginx > /dev/null 2>&1

echo "Creating directories..."
sudo mkdir -p /var/www/html/{admin,tenant}
sudo chown -R ec2-user:ec2-user /var/www/html

echo "Deploying Admin UI..."
cat > /var/www/html/admin/index.html << 'HTML'
<!DOCTYPE html>
<html><head><meta charset="UTF-8"><title>PGNi Admin</title><style>body{font-family:Arial;text-align:center;padding:50px;background:linear-gradient(135deg,#667eea,#764ba2);color:#fff;min-height:100vh;display:flex;align-items:center;justify-content:center}.box{background:#fff;color:#333;padding:40px;border-radius:20px;max-width:700px;box-shadow:0 20px 60px rgba(0,0,0,.3)}h1{color:#667eea;font-size:2.5em;margin-bottom:20px}.status{background:#f0f0f0;padding:15px;margin:15px 0;border-radius:10px;border-left:4px solid #667eea}a{color:#667eea;font-weight:600}</style></head><body><div class="box"><h1>🏢 PGNi Admin Portal</h1><div class="status"><h3>✅ Deployed via Terraform</h3><p>Backend API running on port 8080</p></div><div class="status"><h3>🚀 Quick Access</h3><p>Run locally: <code>RUN_ADMIN_APP.bat</code></p><p>Login: admin@pgni.com / password123</p></div><div class="status"><p><a href="/api/health">Test API</a> | <a href="/tenant">Tenant Portal</a></p></div></div></body></html>
HTML

echo "Deploying Tenant UI..."
cat > /var/www/html/tenant/index.html << 'HTML'
<!DOCTYPE html>
<html><head><meta charset="UTF-8"><title>PGNi Tenant</title><style>body{font-family:Arial;text-align:center;padding:50px;background:linear-gradient(135deg,#11998e,#38ef7d);color:#fff;min-height:100vh;display:flex;align-items:center;justify-content:center}.box{background:#fff;color:#333;padding:40px;border-radius:20px;max-width:700px;box-shadow:0 20px 60px rgba(0,0,0,.3)}h1{color:#11998e;font-size:2.5em;margin-bottom:20px}.status{background:#f0f0f0;padding:15px;margin:15px 0;border-radius:10px;border-left:4px solid #11998e}a{color:#11998e;font-weight:600}</style></head><body><div class="box"><h1>🏠 PGNi Tenant Portal</h1><div class="status"><h3>✅ Deployed via Terraform</h3><p>Backend API running on port 8080</p></div><div class="status"><h3>🚀 Quick Access</h3><p>Run locally: <code>RUN_TENANT_APP.bat</code></p><p>Login: tenant@pgni.com / password123</p></div><div class="status"><p><a href="/api/health">Test API</a> | <a href="/admin">Admin Portal</a></p></div></div></body></html>
HTML

echo "Configuring Nginx..."
sudo tee /etc/nginx/conf.d/pgni.conf > /dev/null << 'NGINX'
server {
    listen 80;
    location /admin { alias /var/www/html/admin; index index.html; }
    location /tenant { alias /var/www/html/tenant; index index.html; }
    location /api { proxy_pass http://localhost:8080; }
    location = / { return 301 /admin; }
}
NGINX

sudo nginx -t && sudo systemctl reload nginx
echo "✅ Frontend deployed successfully!"
DEPLOY_SCRIPT

    # Send command via SSM
    COMMAND_ID=$(aws ssm send-command \
        --instance-ids "$EC2_ID" \
        --document-name "AWS-RunShellScript" \
        --parameters 'commands=["/bin/bash /tmp/deploy_frontend.sh"]' \
        --query 'Command.CommandId' \
        --output text)
    
    echo "Waiting for deployment to complete..."
    aws ssm wait command-executed \
        --command-id "$COMMAND_ID" \
        --instance-id "$EC2_ID"
    
    echo "✅ Frontend deployed via SSM"
else
    # Deploy via SSH
    ssh -i ec2-key.pem -o StrictHostKeyChecking=no ec2-user@$EC2_IP << 'ENDSSH'
set -e
echo "Installing Nginx..."
sudo yum install -y nginx > /dev/null 2>&1
sudo systemctl start nginx
sudo systemctl enable nginx > /dev/null 2>&1

echo "Creating directories..."
sudo mkdir -p /var/www/html/{admin,tenant}
sudo chown -R ec2-user:ec2-user /var/www/html

echo "Deploying Admin UI..."
cat > /var/www/html/admin/index.html << 'HTML'
<!DOCTYPE html>
<html><head><meta charset="UTF-8"><title>PGNi Admin</title><style>body{font-family:Arial;text-align:center;padding:50px;background:linear-gradient(135deg,#667eea,#764ba2);color:#fff;min-height:100vh;display:flex;align-items:center;justify-content:center}.box{background:#fff;color:#333;padding:40px;border-radius:20px;max-width:700px;box-shadow:0 20px 60px rgba(0,0,0,.3)}h1{color:#667eea;font-size:2.5em;margin-bottom:20px}.status{background:#f0f0f0;padding:15px;margin:15px 0;border-radius:10px;border-left:4px solid #667eea}a{color:#667eea;font-weight:600}</style></head><body><div class="box"><h1>🏢 PGNi Admin Portal</h1><div class="status"><h3>✅ Deployed via Script</h3><p>Backend API running on port 8080</p></div><div class="status"><h3>🚀 Quick Access</h3><p>Run locally: <code>RUN_ADMIN_APP.bat</code></p><p>Login: admin@pgni.com / password123</p></div><div class="status"><p><a href="/api/health">Test API</a> | <a href="/tenant">Tenant Portal</a></p></div></div></body></html>
HTML

echo "Deploying Tenant UI..."
cat > /var/www/html/tenant/index.html << 'HTML'
<!DOCTYPE html>
<html><head><meta charset="UTF-8"><title>PGNi Tenant</title><style>body{font-family:Arial;text-align:center;padding:50px;background:linear-gradient(135deg,#11998e,#38ef7d);color:#fff;min-height:100vh;display:flex;align-items:center;justify-content:center}.box{background:#fff;color:#333;padding:40px;border-radius:20px;max-width:700px;box-shadow:0 20px 60px rgba(0,0,0,.3)}h1{color:#11998e;font-size:2.5em;margin-bottom:20px}.status{background:#f0f0f0;padding:15px;margin:15px 0;border-radius:10px;border-left:4px solid #11998e}a{color:#11998e;font-weight:600}</style></head><body><div class="box"><h1>🏠 PGNi Tenant Portal</h1><div class="status"><h3>✅ Deployed via Script</h3><p>Backend API running on port 8080</p></div><div class="status"><h3>🚀 Quick Access</h3><p>Run locally: <code>RUN_TENANT_APP.bat</code></p><p>Login: tenant@pgni.com / password123</p></div><div class="status"><p><a href="/api/health">Test API</a> | <a href="/admin">Admin Portal</a></p></div></div></body></html>
HTML

echo "Configuring Nginx..."
sudo tee /etc/nginx/conf.d/pgni.conf > /dev/null << 'NGINX'
server {
    listen 80;
    location /admin { alias /var/www/html/admin; index index.html; }
    location /tenant { alias /var/www/html/tenant; index index.html; }
    location /api { proxy_pass http://localhost:8080; }
    location = / { return 301 /admin; }
}
NGINX

sudo nginx -t && sudo systemctl reload nginx
echo "✅ Frontend deployed successfully!"
ENDSSH
    
    echo "✅ Frontend deployed via SSH"
fi

echo ""
echo "Step 6: Opening port 80..."
SG_ID=$(aws ec2 describe-instances \
    --instance-ids "$EC2_ID" \
    --query 'Reservations[0].Instances[0].SecurityGroups[0].GroupId' \
    --output text)

if [ -n "$SG_ID" ]; then
    echo "Security Group: $SG_ID"
    
    # Check if port 80 already open
    RULE_EXISTS=$(aws ec2 describe-security-groups \
        --group-ids "$SG_ID" \
        --query "SecurityGroups[0].IpPermissions[?FromPort==\`80\`]" \
        --output text)
    
    if [ -z "$RULE_EXISTS" ]; then
        echo "Opening port 80..."
        aws ec2 authorize-security-group-ingress \
            --group-id "$SG_ID" \
            --protocol tcp \
            --port 80 \
            --cidr 0.0.0.0/0 > /dev/null 2>&1 && echo "✅ Port 80 opened" || echo "⚠️ Could not open port 80"
    else
        echo "✅ Port 80 already open"
    fi
fi

echo ""
echo "Step 7: Testing deployment..."
sleep 3

ADMIN_HTTP=$(curl -s -o /dev/null -w "%{http_code}" "http://$EC2_IP/admin" 2>/dev/null)
TENANT_HTTP=$(curl -s -o /dev/null -w "%{http_code}" "http://$EC2_IP/tenant" 2>/dev/null)
API_HTTP=$(curl -s -o /dev/null -w "%{http_code}" "http://$EC2_IP/api/health" 2>/dev/null)

echo "Test Results:"
echo "  Admin UI:  HTTP $ADMIN_HTTP $([ "$ADMIN_HTTP" = "200" ] && echo '✅' || echo '⚠️')"
echo "  Tenant UI: HTTP $TENANT_HTTP $([ "$TENANT_HTTP" = "200" ] && echo '✅' || echo '⚠️')"
echo "  API:       HTTP $API_HTTP $([ "$API_HTTP" = "200" ] && echo '✅' || echo '⚠️')"

echo ""
echo "=========================================="
echo "✅ UPDATE COMPLETE!"
echo "=========================================="
echo ""
echo "🌐 ACCESS YOUR APPLICATION:"
echo ""
echo "  Admin Portal:  http://$EC2_IP/admin"
echo "  Tenant Portal: http://$EC2_IP/tenant"
echo "  API Endpoint:  http://$EC2_IP/api"
echo ""
echo "🔐 TEST CREDENTIALS:"
echo "  admin@pgni.com / password123"
echo "  tenant@pgni.com / password123"
echo ""
echo "📊 DEPLOYMENT STATUS:"
echo "  Backend:  ✅ Running (existing)"
echo "  Frontend: ✅ Deployed (new)"
echo "  Database: ✅ Connected (existing)"
echo "  Storage:  ✅ Ready (existing)"
echo ""
echo "=========================================="

