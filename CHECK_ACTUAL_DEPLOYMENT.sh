#!/bin/bash

echo "═══════════════════════════════════════════════════════"
echo "🔍 CHECKING ACTUAL DEPLOYMENT STATUS"
echo "═══════════════════════════════════════════════════════"
echo ""

# Check what's actually deployed
echo "1. CHECKING DEPLOYED FILES"
echo "───────────────────────────────────────────────────────"

echo ""
echo "📂 Admin App Files:"
if [ -d "/usr/share/nginx/html/admin" ]; then
    echo "  Directory exists: ✓"
    echo "  File count: $(find /usr/share/nginx/html/admin -type f | wc -l)"
    echo "  Main JS: $(ls -lh /usr/share/nginx/html/admin/main.dart.js 2>/dev/null | awk '{print $5}' || echo "NOT FOUND")"
    echo ""
    echo "  Flutter screen files in build:"
    if [ -d "/home/ec2-user/pgni/pgworld-master/lib/screens" ]; then
        echo "  Source screens available:"
        ls -1 /home/ec2-user/pgni/pgworld-master/lib/screens/*.dart 2>/dev/null | wc -l
        ls -1 /home/ec2-user/pgni/pgworld-master/lib/screens/*.dart 2>/dev/null | head -20
    fi
else
    echo "  ❌ NOT DEPLOYED"
fi

echo ""
echo "📂 Tenant App Files:"
if [ -d "/usr/share/nginx/html/tenant" ]; then
    echo "  Directory exists: ✓"
    echo "  File count: $(find /usr/share/nginx/html/tenant -type f | wc -l)"
    echo "  Main JS: $(ls -lh /usr/share/nginx/html/tenant/main.dart.js 2>/dev/null | awk '{print $5}' || echo "NOT FOUND")"
    echo ""
    echo "  Flutter screen files in build:"
    if [ -d "/home/ec2-user/pgni/pgworldtenant-master/lib/screens" ]; then
        echo "  Source screens available:"
        ls -1 /home/ec2-user/pgni/pgworldtenant-master/lib/screens/*.dart 2>/dev/null | wc -l
        ls -1 /home/ec2-user/pgni/pgworldtenant-master/lib/screens/*.dart 2>/dev/null
    fi
else
    echo "  ❌ NOT DEPLOYED"
fi

echo ""
echo "2. CHECKING NGINX CONFIGURATION"
echo "───────────────────────────────────────────────────────"
echo ""
echo "Nginx config for /admin and /tenant:"
sudo cat /etc/nginx/nginx.conf | grep -A 10 "location /admin" || echo "No /admin location block"
sudo cat /etc/nginx/nginx.conf | grep -A 10 "location /tenant" || echo "No /tenant location block"

echo ""
echo "3. TESTING URLs"
echo "───────────────────────────────────────────────────────"
echo ""

echo "Testing Admin URLs:"
for url in "/" "/admin/" "/admin/index.html" "/admin/main.dart.js"; do
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost$url" 2>/dev/null)
    if [ "$STATUS" = "200" ]; then
        echo "  ✅ http://54.227.101.30$url → $STATUS"
    else
        echo "  ❌ http://54.227.101.30$url → $STATUS"
    fi
done

echo ""
echo "Testing Tenant URLs:"
for url in "/tenant/" "/tenant/index.html" "/tenant/main.dart.js"; do
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost$url" 2>/dev/null)
    if [ "$STATUS" = "200" ]; then
        echo "  ✅ http://54.227.101.30$url → $STATUS"
    else
        echo "  ❌ http://54.227.101.30$url → $STATUS"
    fi
done

echo ""
echo "4. CHECKING API BACKEND"
echo "───────────────────────────────────────────────────────"
echo ""

# Check if API is running
API_STATUS=$(systemctl is-active pgworld-api 2>/dev/null || echo "not-found")
echo "API Service: $API_STATUS"

# Test API endpoint
API_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/health 2>/dev/null)
echo "API Health Check: $API_RESPONSE"

# Check which IP is configured in the deployed apps
echo ""
echo "5. CHECKING CONFIGURED API URLs IN DEPLOYED APPS"
echo "───────────────────────────────────────────────────────"
echo ""

echo "Checking tenant app config:"
if [ -f "/home/ec2-user/pgni/pgworldtenant-master/lib/config/app_config.dart" ]; then
    grep -E "apiBaseUrl|API.URL" /home/ec2-user/pgni/pgworldtenant-master/lib/config/app_config.dart | head -5
elif [ -f "/home/ec2-user/pgni/pgworldtenant-master/lib/config.dart" ]; then
    grep -E "apiBaseUrl|API.URL|String URL" /home/ec2-user/pgni/pgworldtenant-master/lib/config.dart | head -5
else
    echo "  Config file not found!"
fi

echo ""
echo "Checking admin app config:"
if [ -f "/home/ec2-user/pgni/pgworld-master/lib/config/app_config.dart" ]; then
    grep -E "apiBaseUrl|API.URL" /home/ec2-user/pgni/pgworld-master/lib/config/app_config.dart | head -5
elif [ -f "/home/ec2-user/pgni/pgworld-master/lib/config.dart" ]; then
    grep -E "apiBaseUrl|API.URL|String URL" /home/ec2-user/pgni/pgworld-master/lib/config.dart | head -5
else
    echo "  Config file not found!"
fi

echo ""
echo "6. LISTING ALL ACTUAL SCREEN FILES"
echo "───────────────────────────────────────────────────────"
echo ""

echo "📱 ADMIN APP SCREENS:"
if [ -d "/home/ec2-user/pgni/pgworld-master/lib/screens" ]; then
    ADMIN_COUNT=$(ls -1 /home/ec2-user/pgni/pgworld-master/lib/screens/*.dart 2>/dev/null | wc -l)
    echo "  Total screens: $ADMIN_COUNT"
    ls -1 /home/ec2-user/pgni/pgworld-master/lib/screens/*.dart 2>/dev/null | sed 's/.*\//  - /'
else
    echo "  ❌ No screens directory"
fi

echo ""
echo "📱 TENANT APP SCREENS:"
if [ -d "/home/ec2-user/pgni/pgworldtenant-master/lib/screens" ]; then
    TENANT_COUNT=$(ls -1 /home/ec2-user/pgni/pgworldtenant-master/lib/screens/*.dart 2>/dev/null | wc -l)
    echo "  Total screens: $TENANT_COUNT"
    ls -1 /home/ec2-user/pgni/pgworldtenant-master/lib/screens/*.dart 2>/dev/null | sed 's/.*\//  - /'
else
    echo "  ❌ No screens directory"
fi

echo ""
echo "7. CHECKING LAST BUILD DATE"
echo "───────────────────────────────────────────────────────"
echo ""

echo "Admin last build:"
if [ -f "/usr/share/nginx/html/admin/main.dart.js" ]; then
    ls -lh /usr/share/nginx/html/admin/main.dart.js | awk '{print "  Date: " $6, $7, $8, "Size: " $5}'
else
    echo "  Not built"
fi

echo ""
echo "Tenant last build:"
if [ -f "/usr/share/nginx/html/tenant/main.dart.js" ]; then
    ls -lh /usr/share/nginx/html/tenant/main.dart.js | awk '{print "  Date: " $6, $7, $8, "Size: " $5}'
else
    echo "  Not built"
fi

echo ""
echo "═══════════════════════════════════════════════════════"
echo "✅ SCAN COMPLETE"
echo "═══════════════════════════════════════════════════════"
echo ""
echo "📊 SUMMARY:"
echo "  Admin Screens: $ADMIN_COUNT files"
echo "  Tenant Screens: $TENANT_COUNT files"
echo "  Public URL: http://54.227.101.30/"
echo "  Admin URL: http://54.227.101.30/admin/"
echo "  Tenant URL: http://54.227.101.30/tenant/"
echo ""
echo "🔍 Check above for:"
echo "  1. Actual screen files present"
echo "  2. Correct API URL configuration"
echo "  3. HTTP status of all endpoints"
echo "  4. Last build dates"
echo ""

