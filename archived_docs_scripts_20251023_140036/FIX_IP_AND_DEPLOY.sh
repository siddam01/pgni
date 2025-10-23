#!/bin/bash
set -e

echo "════════════════════════════════════════════════════════"
echo "🔧 FIX IP ADDRESS & DEPLOY"
echo "════════════════════════════════════════════════════════"

# Get actual EC2 public IP
ACTUAL_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "")

if [ -z "$ACTUAL_IP" ]; then
    echo "⚠️  Could not auto-detect IP. Checking network interfaces..."
    ACTUAL_IP=$(hostname -I | awk '{print $1}')
fi

echo ""
echo "Detected IP: $ACTUAL_IP"
echo ""

# Check if Go API is running
API_STATUS=$(systemctl is-active pgworld-api 2>/dev/null || echo "inactive")
echo "API Service Status: $API_STATUS"

if [ "$API_STATUS" != "active" ]; then
    echo ""
    echo "❌ Go API is NOT running!"
    echo ""
    echo "Let's check what's available:"
    
    # Check if Go API binary exists
    if [ -f "/home/ec2-user/pgni/pgworld-api-master/main" ]; then
        echo "✓ API binary found"
    else
        echo "✗ API binary NOT found at /home/ec2-user/pgni/pgworld-api-master/main"
    fi
    
    # Check if systemd service exists
    if [ -f "/etc/systemd/system/pgworld-api.service" ]; then
        echo "✓ Systemd service file exists"
        echo ""
        echo "Starting API service..."
        sudo systemctl start pgworld-api
        sudo systemctl enable pgworld-api
        sleep 3
        API_STATUS=$(systemctl is-active pgworld-api)
        echo "API Status after start: $API_STATUS"
    else
        echo "✗ Systemd service file NOT found"
        echo ""
        echo "Need to create API service first!"
    fi
fi

# Test if API is responding
echo ""
echo "Testing API endpoint..."
API_TEST=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/api/health 2>/dev/null || echo "000")
echo "API Health Check: $API_TEST"

if [ "$API_TEST" != "200" ]; then
    echo ""
    echo "⚠️  API is not responding on port 8080"
    echo ""
    echo "Checking if port 8080 is in use:"
    sudo netstat -tlnp | grep :8080 || echo "Port 8080 is not in use"
    echo ""
    
    # Try to start the API manually if binary exists
    if [ -f "/home/ec2-user/pgni/pgworld-api-master/main" ]; then
        echo "Starting API manually..."
        cd /home/ec2-user/pgni/pgworld-api-master
        nohup ./main > /tmp/api.log 2>&1 &
        sleep 3
        echo "API started. Checking status..."
        curl -s http://localhost:8080/api/health || echo "Still not responding"
    fi
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "Checking Nginx Status"
echo "════════════════════════════════════════════════════════"

NGINX_STATUS=$(systemctl is-active nginx 2>/dev/null || echo "inactive")
echo "Nginx Status: $NGINX_STATUS"

if [ "$NGINX_STATUS" != "active" ]; then
    echo "Starting Nginx..."
    sudo systemctl start nginx
    sudo systemctl enable nginx
fi

# Check what's deployed
echo ""
echo "Current deployments:"
ls -lh /usr/share/nginx/html/ 2>/dev/null || echo "Nginx html directory not found"

echo ""
echo "════════════════════════════════════════════════════════"
echo "Network Diagnostics"
echo "════════════════════════════════════════════════════════"

echo ""
echo "Open ports:"
sudo netstat -tlnp | grep -E ':(80|8080|443)' || echo "No web services listening"

echo ""
echo "Security Group Info:"
echo "From your browser, you're trying to access: 13.221.117.236"
echo "Current server IP: $ACTUAL_IP"

if [ "$ACTUAL_IP" != "13.221.117.236" ]; then
    echo ""
    echo "⚠️  IP MISMATCH!"
    echo "   Browser trying: 13.221.117.236"
    echo "   Actual IP:       $ACTUAL_IP"
    echo ""
    echo "This could mean:"
    echo "1. Wrong EC2 instance (you're on a different server)"
    echo "2. Elastic IP changed"
    echo "3. Instance was restarted with new IP"
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "Quick Fix: Test Local Access"
echo "════════════════════════════════════════════════════════"

echo ""
echo "Testing local Nginx:"
curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" http://localhost/admin/ || echo "Admin not accessible locally"
curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" http://localhost/tenant/ || echo "Tenant not accessible locally"

echo ""
echo "════════════════════════════════════════════════════════"
echo "📋 DIAGNOSIS SUMMARY"
echo "════════════════════════════════════════════════════════"
echo ""
echo "Your browser IP:    13.221.117.236"
echo "Current server IP:  $ACTUAL_IP"
echo "API Service:        $API_STATUS"
echo "Nginx Service:      $NGINX_STATUS"
echo "API Health:         $API_TEST"
echo ""

if [ "$ACTUAL_IP" == "13.221.117.236" ]; then
    echo "✅ IP matches! Problem is likely:"
    echo "   1. API not running (port 8080)"
    echo "   2. Nginx not serving files"
    echo "   3. Files not deployed"
    echo ""
    echo "Run this to check logs:"
    echo "   sudo tail -50 /var/log/nginx/error.log"
    echo "   sudo journalctl -u pgworld-api -n 50"
else
    echo "❌ IP MISMATCH! You're either:"
    echo "   1. On the wrong EC2 instance"
    echo "   2. Need to access via: http://$ACTUAL_IP/admin/"
    echo "                          http://$ACTUAL_IP/tenant/"
    echo ""
    echo "Or update your DNS/Elastic IP to point to: $ACTUAL_IP"
fi

echo ""
echo "════════════════════════════════════════════════════════"

