#!/bin/bash
set -e

echo "════════════════════════════════════════════════════════"
echo "🔍 FINDING PUBLIC IP AND FIXING CONFIGURATION"
echo "════════════════════════════════════════════════════════"

# Try multiple methods to get public IP
echo "Attempting to get public IP..."

# Method 1: AWS metadata service (most reliable for EC2)
PUBLIC_IP=$(curl -s --connect-timeout 5 http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "")

if [ -z "$PUBLIC_IP" ]; then
    # Method 2: External service
    PUBLIC_IP=$(curl -s --connect-timeout 5 https://api.ipify.org 2>/dev/null || echo "")
fi

if [ -z "$PUBLIC_IP" ]; then
    # Method 3: Another external service
    PUBLIC_IP=$(curl -s --connect-timeout 5 https://checkip.amazonaws.com 2>/dev/null | tr -d '\n' || echo "")
fi

if [ -z "$PUBLIC_IP" ]; then
    # Method 4: ifconfig.me
    PUBLIC_IP=$(curl -s --connect-timeout 5 https://ifconfig.me 2>/dev/null || echo "")
fi

PRIVATE_IP=$(hostname -I | awk '{print $1}')

echo ""
echo "════════════════════════════════════════════════════════"
echo "IP ADDRESSES DETECTED"
echo "════════════════════════════════════════════════════════"
echo "Private IP: $PRIVATE_IP"
echo "Public IP:  ${PUBLIC_IP:-NOT FOUND}"
echo ""

if [ -z "$PUBLIC_IP" ]; then
    echo "❌ Could not auto-detect public IP!"
    echo ""
    echo "Please find your public IP manually:"
    echo "1. Go to AWS Console → EC2 → Instances"
    echo "2. Find your instance: ip-172-31-27-239"
    echo "3. Look for 'Public IPv4 address' in the details"
    echo ""
    echo "Then run:"
    echo "   export PUBLIC_IP=YOUR_IP_HERE"
    echo "   bash <(curl -sL https://raw.githubusercontent.com/siddam01/pgni/main/PRODUCTION_DEPLOY.sh)"
    exit 1
fi

echo "✅ Public IP found: $PUBLIC_IP"
echo ""

# Check if this matches what user is trying to access
if [ "$PUBLIC_IP" != "13.221.117.236" ]; then
    echo "⚠️  IMPORTANT: Your actual public IP is different!"
    echo ""
    echo "   You were trying:  13.221.117.236"
    echo "   Actual public IP: $PUBLIC_IP"
    echo ""
    echo "This means either:"
    echo "   1. You have the wrong IP bookmarked/saved"
    echo "   2. Your EC2 instance changed IPs (restart/elastic IP change)"
    echo "   3. You're accessing a different instance"
    echo ""
fi

echo "════════════════════════════════════════════════════════"
echo "CHECKING SERVICES"
echo "════════════════════════════════════════════════════════"

# Check API
echo ""
echo "Go API Status:"
sudo systemctl status pgworld-api --no-pager -l | head -15

# Test API endpoint
echo ""
echo "Testing API health endpoint..."
API_RESPONSE=$(curl -s http://localhost:8080/api/health 2>/dev/null || echo "FAILED")
echo "Response: $API_RESPONSE"

if [[ "$API_RESPONSE" == *"404"* ]] || [[ "$API_RESPONSE" == "FAILED" ]]; then
    echo ""
    echo "⚠️  API health endpoint not found or failing"
    echo ""
    echo "Checking API logs:"
    sudo journalctl -u pgworld-api -n 20 --no-pager
    
    echo ""
    echo "This is likely okay - the API might not have a /health endpoint"
    echo "Let's test a real endpoint:"
    
    # Test login endpoint structure
    curl -s -X POST http://localhost:8080/api/login \
        -H "Content-Type: application/json" \
        -d '{"email":"test","password":"test"}' | head -50
fi

# Check Nginx
echo ""
echo "Nginx Status:"
sudo systemctl status nginx --no-pager | head -10

# Test local access
echo ""
echo "════════════════════════════════════════════════════════"
echo "TESTING LOCAL ACCESS"
echo "════════════════════════════════════════════════════════"

echo ""
echo "Admin app (local):"
curl -s -o /dev/null -w "Status: %{http_code}, Size: %{size_download} bytes\n" http://localhost/admin/

echo ""
echo "Tenant app (local):"
curl -s -o /dev/null -w "Status: %{http_code}, Size: %{size_download} bytes\n" http://localhost/tenant/

echo ""
echo "════════════════════════════════════════════════════════"
echo "TESTING PUBLIC ACCESS"
echo "════════════════════════════════════════════════════════"

echo ""
echo "Testing from this server to public IP..."
echo ""
echo "Admin app (public):"
curl -s -o /dev/null -w "Status: %{http_code}, Size: %{size_download} bytes\n" "http://$PUBLIC_IP/admin/" --connect-timeout 10 || echo "FAILED - Security Group might be blocking"

echo ""
echo "Tenant app (public):"
curl -s -o /dev/null -w "Status: %{http_code}, Size: %{size_download} bytes\n" "http://$PUBLIC_IP/tenant/" --connect-timeout 10 || echo "FAILED - Security Group might be blocking"

echo ""
echo "════════════════════════════════════════════════════════"
echo "SECURITY GROUP CHECK"
echo "════════════════════════════════════════════════════════"

echo ""
echo "Checking if port 80 is accessible from outside..."
echo ""

# Try to get security group info
if command -v aws &>/dev/null; then
    echo "AWS CLI found, checking security groups..."
    INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id 2>/dev/null || echo "")
    if [ -n "$INSTANCE_ID" ]; then
        echo "Instance ID: $INSTANCE_ID"
        aws ec2 describe-instances --instance-ids "$INSTANCE_ID" --query 'Reservations[0].Instances[0].SecurityGroups[*].[GroupId,GroupName]' --output table 2>/dev/null || echo "Could not fetch security groups"
    fi
else
    echo "AWS CLI not installed, cannot check security groups"
fi

echo ""
echo "To check Security Groups manually:"
echo "1. Go to AWS Console → EC2 → Instances"
echo "2. Click your instance"
echo "3. Go to 'Security' tab"
echo "4. Check 'Security groups' → Inbound rules"
echo "5. You MUST have:"
echo "   - Type: HTTP, Port: 80, Source: 0.0.0.0/0"
echo "   - Type: HTTP, Port: 8080, Source: 0.0.0.0/0 (for API)"

echo ""
echo "════════════════════════════════════════════════════════"
echo "✅ FINAL RESULT"
echo "════════════════════════════════════════════════════════"

echo ""
echo "📊 Your Application URLs:"
echo ""
echo "   Admin:  http://$PUBLIC_IP/admin/"
echo "   Tenant: http://$PUBLIC_IP/tenant/"
echo ""
echo "📧 Admin Login:"
echo "   Email:    admin@pgworld.com"
echo "   Password: Admin@123"
echo ""
echo "📧 Tenant Login:"
echo "   Email:    priya@example.com"
echo "   Password: Tenant@123"
echo ""

# Check if files are actually there
echo "════════════════════════════════════════════════════════"
echo "DEPLOYED FILES CHECK"
echo "════════════════════════════════════════════════════════"

echo ""
echo "Admin files:"
ls -lh /usr/share/nginx/html/admin/ | grep -E "(index.html|main.dart.js|flutter)"

echo ""
echo "Tenant files:"
ls -lh /usr/share/nginx/html/tenant/ | grep -E "(index.html|main.dart.js|flutter)"

echo ""
echo "════════════════════════════════════════════════════════"
echo "🎯 ACTION REQUIRED"
echo "════════════════════════════════════════════════════════"

if [ "$PUBLIC_IP" != "13.221.117.236" ]; then
    echo ""
    echo "⚠️  UPDATE YOUR BOOKMARKS/LINKS!"
    echo ""
    echo "   OLD IP: 13.221.117.236 (doesn't work)"
    echo "   NEW IP: $PUBLIC_IP (use this!)"
    echo ""
    echo "   Access here: http://$PUBLIC_IP/tenant/"
    echo ""
else
    echo ""
    echo "✅ IP is correct!"
    echo ""
    echo "If you still can't access from your browser:"
    echo "1. Check AWS Security Group allows port 80 from your IP"
    echo "2. Try from a different network"
    echo "3. Check browser console (F12) for errors"
    echo ""
fi

echo "════════════════════════════════════════════════════════"

