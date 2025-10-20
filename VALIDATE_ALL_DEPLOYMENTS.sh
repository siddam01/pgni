#!/bin/bash

echo "═══════════════════════════════════════════════════════"
echo "🔍 COMPREHENSIVE DEPLOYMENT VALIDATION"
echo "═══════════════════════════════════════════════════════"
echo ""

ADMIN_PATH="/home/ec2-user/pgni/pgworld-master"
TENANT_PATH="/home/ec2-user/pgni/pgworldtenant-master"

echo "══════════════════════════════════════════════════════════════"
echo "📱 ADMIN APP VALIDATION"
echo "══════════════════════════════════════════════════════════════"
echo ""

echo "1. Source Files Check"
echo "────────────────────────────────────────────────────────"

if [ -d "$ADMIN_PATH/lib/screens" ]; then
    cd "$ADMIN_PATH"
    ADMIN_SCREENS=$(ls -1 lib/screens/*.dart 2>/dev/null | wc -l)
    echo "✓ Admin source directory exists"
    echo "✓ Screen files: $ADMIN_SCREENS"
    
    # Check for key files
    echo ""
    echo "Key files check:"
    for file in "login.dart" "dashboard.dart" "users.dart" "bills.dart" "rooms.dart"; do
        if [ -f "lib/screens/$file" ]; then
            echo "  ✓ $file"
        else
            echo "  ✗ $file MISSING"
        fi
    done
else
    echo "✗ Admin source directory NOT FOUND!"
    ADMIN_SCREENS=0
fi

echo ""
echo "2. Deployment Check"
echo "────────────────────────────────────────────────────────"

if [ -d "/usr/share/nginx/html/admin" ]; then
    ADMIN_FILES=$(find /usr/share/nginx/html/admin -type f | wc -l)
    ADMIN_JS_SIZE=$(ls -lh /usr/share/nginx/html/admin/main.dart.js 2>/dev/null | awk '{print $5}' || echo "NOT FOUND")
    ADMIN_DATE=$(ls -l /usr/share/nginx/html/admin/main.dart.js 2>/dev/null | awk '{print $6, $7, $8}')
    
    echo "✓ Admin deployed to Nginx"
    echo "  Files: $ADMIN_FILES"
    echo "  JS: $ADMIN_JS_SIZE"
    echo "  Date: $ADMIN_DATE"
    
    # Check base-href
    if grep -q 'base href="/admin/"' /usr/share/nginx/html/admin/index.html 2>/dev/null; then
        echo "  ✓ base-href: /admin/"
    else
        echo "  ⚠️  base-href may be incorrect"
    fi
else
    echo "✗ Admin NOT deployed!"
    ADMIN_FILES=0
fi

echo ""
echo "3. URL Testing"
echo "────────────────────────────────────────────────────────"

ADMIN_FAILED=0
for url in "/admin/" "/admin/index.html" "/admin/main.dart.js"; do
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost$url" 2>/dev/null)
    if [ "$STATUS" = "200" ]; then
        echo "  ✅ http://54.227.101.30$url"
    else
        echo "  ❌ http://54.227.101.30$url ($STATUS)"
        ((ADMIN_FAILED++))
    fi
done

if [ $ADMIN_FAILED -eq 0 ]; then
    ADMIN_STATUS="✅ WORKING"
else
    ADMIN_STATUS="⚠️ ISSUES FOUND"
fi

echo ""
echo "══════════════════════════════════════════════════════════════"
echo "📱 TENANT APP VALIDATION"
echo "══════════════════════════════════════════════════════════════"
echo ""

echo "1. Source Files Check"
echo "────────────────────────────────────────────────────────"

if [ -d "$TENANT_PATH/lib/screens" ]; then
    cd "$TENANT_PATH"
    TENANT_SCREENS=$(ls -1 lib/screens/*.dart 2>/dev/null | wc -l)
    echo "✓ Tenant source directory exists"
    echo "✓ Screen files: $TENANT_SCREENS"
    
    # Check for key files and their complexity (indicator of real vs placeholder)
    echo ""
    echo "Key files check:"
    for file in "login.dart" "dashboard.dart" "profile.dart" "issues.dart" "notices.dart"; do
        if [ -f "lib/screens/$file" ]; then
            LINE_COUNT=$(wc -l < "lib/screens/$file")
            if [ $LINE_COUNT -gt 100 ]; then
                echo "  ✓ $file ($LINE_COUNT lines - ORIGINAL)"
            else
                echo "  ⚠️  $file ($LINE_COUNT lines - MAY BE PLACEHOLDER)"
            fi
        else
            echo "  ✗ $file MISSING"
        fi
    done
    
    # Check if login has proper imports (indicator of real code)
    echo ""
    echo "Code quality check:"
    if grep -q "utils/models.dart" lib/screens/login.dart 2>/dev/null; then
        echo "  ✓ Login has proper imports (ORIGINAL CODE)"
    else
        echo "  ⚠️  Login may be simplified version"
    fi
else
    echo "✗ Tenant source directory NOT FOUND!"
    TENANT_SCREENS=0
fi

echo ""
echo "2. Deployment Check"
echo "────────────────────────────────────────────────────────"

if [ -d "/usr/share/nginx/html/tenant" ]; then
    TENANT_FILES=$(find /usr/share/nginx/html/tenant -type f | wc -l)
    TENANT_JS_SIZE=$(ls -lh /usr/share/nginx/html/tenant/main.dart.js 2>/dev/null | awk '{print $5}' || echo "NOT FOUND")
    TENANT_DATE=$(ls -l /usr/share/nginx/html/tenant/main.dart.js 2>/dev/null | awk '{print $6, $7, $8}')
    
    echo "✓ Tenant deployed to Nginx"
    echo "  Files: $TENANT_FILES"
    echo "  JS: $TENANT_JS_SIZE"
    echo "  Date: $TENANT_DATE"
    
    # Check base-href
    if grep -q 'base href="/tenant/"' /usr/share/nginx/html/tenant/index.html 2>/dev/null; then
        echo "  ✓ base-href: /tenant/"
    else
        echo "  ⚠️  base-href may be incorrect"
    fi
else
    echo "✗ Tenant NOT deployed!"
    TENANT_FILES=0
fi

echo ""
echo "3. URL Testing"
echo "────────────────────────────────────────────────────────"

TENANT_FAILED=0
for url in "/tenant/" "/tenant/index.html" "/tenant/main.dart.js"; do
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost$url" 2>/dev/null)
    if [ "$STATUS" = "200" ]; then
        echo "  ✅ http://54.227.101.30$url"
    else
        echo "  ❌ http://54.227.101.30$url ($STATUS)"
        ((TENANT_FAILED++))
    fi
done

if [ $TENANT_FAILED -eq 0 ]; then
    TENANT_STATUS="✅ WORKING"
else
    TENANT_STATUS="⚠️ ISSUES FOUND"
fi

echo ""
echo "══════════════════════════════════════════════════════════════"
echo "🔧 API BACKEND VALIDATION"
echo "══════════════════════════════════════════════════════════════"
echo ""

# Check API service
API_STATUS=$(systemctl is-active pgworld-api 2>/dev/null || echo "not-found")
echo "API Service: $API_STATUS"

# Test API endpoints
echo ""
echo "API Endpoints:"
for endpoint in "/health" "/api/login" "/"; do
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:8080$endpoint" 2>/dev/null)
    echo "  http://54.227.101.30:8080$endpoint → $STATUS"
done

# Test Nginx proxy
echo ""
echo "Nginx API Proxy:"
PROXY_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost/api/login" 2>/dev/null)
echo "  http://54.227.101.30/api/login → $PROXY_STATUS"

echo ""
echo "══════════════════════════════════════════════════════════════"
echo "📊 FINAL SUMMARY"
echo "══════════════════════════════════════════════════════════════"
echo ""

echo "┌────────────────────────────────────────────────────────┐"
echo "│ ADMIN APP                                              │"
echo "├────────────────────────────────────────────────────────┤"
echo "│ Source Files:    $ADMIN_SCREENS screens"
echo "│ Deployed Files:  $ADMIN_FILES files"
echo "│ Bundle Size:     $ADMIN_JS_SIZE"
echo "│ Status:          $ADMIN_STATUS"
echo "│ URL:             http://54.227.101.30/admin/"
echo "│ Login:           admin@pgworld.com / Admin@123"
echo "└────────────────────────────────────────────────────────┘"
echo ""
echo "┌────────────────────────────────────────────────────────┐"
echo "│ TENANT APP                                             │"
echo "├────────────────────────────────────────────────────────┤"
echo "│ Source Files:    $TENANT_SCREENS screens"
echo "│ Deployed Files:  $TENANT_FILES files"
echo "│ Bundle Size:     $TENANT_JS_SIZE"
echo "│ Status:          $TENANT_STATUS"
echo "│ URL:             http://54.227.101.30/tenant/"
echo "│ Login:           priya@example.com / Tenant@123"
echo "└────────────────────────────────────────────────────────┘"
echo ""
echo "┌────────────────────────────────────────────────────────┐"
echo "│ API BACKEND                                            │"
echo "├────────────────────────────────────────────────────────┤"
echo "│ Service:         $API_STATUS"
echo "│ Direct:          http://54.227.101.30:8080"
echo "│ Proxy:           http://54.227.101.30/api"
echo "└────────────────────────────────────────────────────────┘"
echo ""

# Recommendations
echo "══════════════════════════════════════════════════════════════"
echo "💡 RECOMMENDATIONS"
echo "══════════════════════════════════════════════════════════════"
echo ""

if [ $ADMIN_FAILED -gt 0 ]; then
    echo "⚠️  ADMIN APP:"
    echo "   - Some URLs returning errors"
    echo "   - Check Nginx configuration"
    echo "   - Verify deployment completed"
    echo ""
fi

if [ $TENANT_FAILED -gt 0 ]; then
    echo "⚠️  TENANT APP:"
    echo "   - Some URLs returning errors"
    echo "   - Check Nginx configuration"
    echo "   - Verify deployment completed"
    echo ""
fi

if [ $TENANT_SCREENS -lt 10 ]; then
    echo "⚠️  TENANT SOURCE FILES:"
    echo "   - Only $TENANT_SCREENS screens found (expected 16)"
    echo "   - Original source code may be missing"
    echo "   - Consider restoring from backup or local repository"
    echo ""
fi

# Check if tenant screens are placeholders
cd "$TENANT_PATH"
if [ -f "lib/screens/login.dart" ]; then
    LOGIN_LINES=$(wc -l < "lib/screens/login.dart")
    if [ $LOGIN_LINES -lt 100 ]; then
        echo "⚠️  TENANT APP QUALITY:"
        echo "   - Login screen appears to be a placeholder ($LOGIN_LINES lines)"
        echo "   - Original screens may not be deployed"
        echo "   - Run: DEPLOY_ORIGINAL_TENANT_SCREENS.sh to fix"
        echo ""
    fi
fi

echo "══════════════════════════════════════════════════════════════"
echo "🎯 NEXT STEPS"
echo "══════════════════════════════════════════════════════════════"
echo ""

if [ $ADMIN_FAILED -eq 0 ] && [ $TENANT_FAILED -eq 0 ]; then
    echo "✅ All URLs are accessible!"
    echo ""
    echo "Test the applications:"
    echo "1. Clear browser cache"
    echo "2. Open http://54.227.101.30/admin/ (Admin)"
    echo "3. Open http://54.227.101.30/tenant/ (Tenant)"
    echo "4. Test navigation and all features"
    echo "5. Verify all pages load correctly"
else
    echo "⚠️  Issues found. Fix deployment:"
    echo ""
    if [ $ADMIN_FAILED -gt 0 ]; then
        echo "For Admin app:"
        echo "  cd /home/ec2-user/pgni/pgworld-master"
        echo "  flutter build web --release --base-href=\"/admin/\""
        echo "  sudo cp -r build/web/* /usr/share/nginx/html/admin/"
        echo ""
    fi
    if [ $TENANT_FAILED -gt 0 ]; then
        echo "For Tenant app:"
        echo "  bash <(curl -sL https://raw.githubusercontent.com/siddam01/pgni/main/DEPLOY_ORIGINAL_TENANT_SCREENS.sh)"
        echo ""
    fi
fi

echo "══════════════════════════════════════════════════════════════"

