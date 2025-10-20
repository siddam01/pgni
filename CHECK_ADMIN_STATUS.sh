#!/bin/bash

echo "═══════════════════════════════════════════════════════"
echo "🔍 CHECKING ADMIN APP STATUS"
echo "═══════════════════════════════════════════════════════"
echo ""

ADMIN_PATH="/home/ec2-user/pgni/pgworld-master"

echo "1. Checking Admin Source Files"
echo "───────────────────────────────────────────────────────"

if [ -d "$ADMIN_PATH/lib/screens" ]; then
    cd "$ADMIN_PATH"
    SCREEN_COUNT=$(ls -1 lib/screens/*.dart 2>/dev/null | wc -l)
    echo "✓ Admin screens directory exists"
    echo "✓ Screen files found: $SCREEN_COUNT"
    echo ""
    echo "All Admin screen files:"
    ls -1 lib/screens/*.dart 2>/dev/null | sed 's|lib/screens/||' | sed 's|\.dart||' | nl
else
    echo "❌ Admin screens directory NOT FOUND!"
    exit 1
fi

echo ""
echo "2. Checking Admin Deployment"
echo "───────────────────────────────────────────────────────"

if [ -d "/usr/share/nginx/html/admin" ]; then
    FILE_COUNT=$(find /usr/share/nginx/html/admin -type f | wc -l)
    JS_SIZE=$(ls -lh /usr/share/nginx/html/admin/main.dart.js 2>/dev/null | awk '{print $5}' || echo "NOT FOUND")
    DEPLOY_DATE=$(ls -l /usr/share/nginx/html/admin/main.dart.js 2>/dev/null | awk '{print $6, $7, $8}' || echo "N/A")
    
    echo "✓ Admin deployed to Nginx"
    echo "  Files: $FILE_COUNT"
    echo "  JS Size: $JS_SIZE"
    echo "  Last deployed: $DEPLOY_DATE"
else
    echo "❌ Admin NOT deployed to Nginx!"
fi

echo ""
echo "3. Testing Admin URLs"
echo "───────────────────────────────────────────────────────"

for url in "/admin/" "/admin/index.html" "/admin/main.dart.js"; do
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost$url" 2>/dev/null)
    if [ "$STATUS" = "200" ]; then
        echo "  ✅ http://54.227.101.30$url → $STATUS"
    else
        echo "  ❌ http://54.227.101.30$url → $STATUS"
    fi
done

echo ""
echo "4. Checking Admin Config Files"
echo "───────────────────────────────────────────────────────"

cd "$ADMIN_PATH"

if [ -f "lib/config/app_config.dart" ]; then
    echo "✓ Found: lib/config/app_config.dart"
    grep -E "apiBaseUrl|API" lib/config/app_config.dart | head -3
elif [ -f "lib/config.dart" ]; then
    echo "✓ Found: lib/config.dart"
    grep -E "apiBaseUrl|API|String URL" lib/config.dart | head -3
else
    echo "⚠️  No config file found!"
fi

echo ""
echo "5. Expected vs Actual Admin Screens"
echo "───────────────────────────────────────────────────────"

EXPECTED_SCREENS=(
    "login.dart"
    "dashboard.dart"
    "dashboard_home.dart"
    "rooms.dart"
    "rooms_screen.dart"
    "room.dart"
    "roomFilter.dart"
    "tenants_screen.dart"
    "users.dart"
    "user.dart"
    "userFilter.dart"
    "bills.dart"
    "bills_screen.dart"
    "bill.dart"
    "billFilter.dart"
    "invoices.dart"
    "reports_screen.dart"
    "report.dart"
    "settings.dart"
    "settings_screen.dart"
    "hostels.dart"
    "hostel.dart"
    "notices.dart"
    "notice.dart"
    "notes.dart"
    "note.dart"
    "issues.dart"
    "issueFilter.dart"
    "employees.dart"
    "employee.dart"
    "food.dart"
    "logs.dart"
    "photo.dart"
    "support.dart"
    "signup.dart"
    "owner_registration.dart"
    "pro.dart"
)

MISSING_COUNT=0
FOUND_COUNT=0

for screen in "${EXPECTED_SCREENS[@]}"; do
    if [ -f "lib/screens/$screen" ]; then
        ((FOUND_COUNT++))
    else
        echo "  ✗ MISSING: $screen"
        ((MISSING_COUNT++))
    fi
done

echo ""
echo "Summary:"
echo "  ✓ Found: $FOUND_COUNT screens"
echo "  ✗ Missing: $MISSING_COUNT screens"
echo "  Expected: 37 screens"

echo ""
echo "═══════════════════════════════════════════════════════"
if [ $MISSING_COUNT -eq 0 ]; then
    echo "✅ ADMIN APP: ALL 37 SCREENS PRESENT"
else
    echo "⚠️  ADMIN APP: $MISSING_COUNT SCREENS MISSING"
fi
echo "═══════════════════════════════════════════════════════"
echo ""
echo "🌐 Admin URL: http://54.227.101.30/admin/"
echo "📧 Email:     admin@pgworld.com"
echo "🔐 Password:  Admin@123"
echo ""

