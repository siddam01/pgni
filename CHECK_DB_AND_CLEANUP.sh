#!/bin/bash
set -e

echo "═══════════════════════════════════════════════════════"
echo "🔍 CHECK DATABASE & CLEANUP UNWANTED FILES"
echo "═══════════════════════════════════════════════════════"
echo ""

echo "PART 1: DATABASE CONNECTION DIAGNOSTICS"
echo "═══════════════════════════════════════════════════════"
echo ""

echo "STEP 1: Check if RDS is accessible"
echo "───────────────────────────────────────────────────────"

# Check API is running and can connect to DB
if systemctl is-active --quiet pgworld-api; then
    echo "✓ API service is running"
    
    # Check API logs for DB connection
    echo ""
    echo "Checking API logs for database connection..."
    API_LOGS=$(sudo journalctl -u pgworld-api -n 20 --no-pager | grep -i "database\|mysql\|connection" || echo "")
    
    if [ -n "$API_LOGS" ]; then
        echo "$API_LOGS"
    else
        echo "No database logs found in recent API logs"
    fi
else
    echo "⚠️  API service is not running"
fi

echo ""
echo "STEP 2: Extract actual DB credentials from API"
echo "───────────────────────────────────────────────────────"

API_MAIN="/home/ec2-user/pgni/pgworld-api/main.go"
if [ -f "$API_MAIN" ]; then
    echo "Found API main.go, extracting connection string..."
    
    # Extract the actual connection string
    CONN_STRING=$(grep -A 2 'sql.Open' "$API_MAIN" | grep -oP '"mysql", "\K[^"]+' || echo "")
    
    if [ -n "$CONN_STRING" ]; then
        echo ""
        echo "Current API Connection String:"
        echo "$CONN_STRING"
        echo ""
        
        # Parse connection string
        if echo "$CONN_STRING" | grep -q "@tcp"; then
            DB_USER=$(echo "$CONN_STRING" | cut -d':' -f1)
            DB_PASS=$(echo "$CONN_STRING" | cut -d':' -f2 | cut -d'@' -f1)
            DB_HOST=$(echo "$CONN_STRING" | grep -oP '@tcp\(\K[^:]+')
            DB_NAME=$(echo "$CONN_STRING" | grep -oP '\)/\K[^?]+')
            
            echo "Parsed Credentials:"
            echo "  User: $DB_USER"
            echo "  Pass: [${#DB_PASS} characters]"
            echo "  Host: $DB_HOST"
            echo "  DB:   $DB_NAME"
        fi
    else
        echo "⚠️  Could not extract connection string"
    fi
else
    echo "⚠️  API main.go not found at $API_MAIN"
fi

echo ""
echo "STEP 3: Check if API can access database"
echo "───────────────────────────────────────────────────────"

# Test API endpoints that use database
echo "Testing /users endpoint (requires DB)..."
USERS_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/users || echo "000")

if [ "$USERS_RESPONSE" = "200" ]; then
    echo "✓ API can access database (users endpoint returned 200)"
    echo ""
    echo "✅ DATABASE IS WORKING!"
    echo "   The API is successfully connected to the database."
    echo "   Sample data may already exist."
    echo ""
    read -p "Do you want to check existing data? (Y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        echo ""
        echo "Checking existing data via API..."
        curl -s http://localhost:8080/users | jq '.data.users | length' 2>/dev/null && echo " users found" || echo ""
        curl -s http://localhost:8080/hostels | jq '.data.hostels | length' 2>/dev/null && echo " hostels found" || echo ""
    fi
else
    echo "⚠️  API returned $USERS_RESPONSE (may indicate DB connection issue)"
fi

echo ""
echo "═══════════════════════════════════════════════════════"
echo "PART 2: CLEANUP UNWANTED FILES"
echo "═══════════════════════════════════════════════════════"
echo ""

cd /home/ec2-user/pgni

echo "STEP 1: List current files"
echo "───────────────────────────────────────────────────────"

echo ""
echo "Current .sh files:"
ls -1 *.sh 2>/dev/null | head -20

echo ""
echo "Current .md files:"
ls -1 *.md 2>/dev/null | head -20

echo ""
echo "Current .ps1 files:"
ls -1 *.ps1 2>/dev/null || echo "No .ps1 files found"

echo ""
echo "STEP 2: Remove unwanted PowerShell files"
echo "───────────────────────────────────────────────────────"

PS1_COUNT=0
for file in *.ps1; do
    if [ -f "$file" ]; then
        rm "$file"
        echo "  ✓ Removed: $file"
        ((PS1_COUNT++))
    fi
done

if [ $PS1_COUNT -eq 0 ]; then
    echo "  ✓ No .ps1 files to remove"
else
    echo ""
    echo "Removed $PS1_COUNT PowerShell files"
fi

echo ""
echo "STEP 3: Remove unwanted documentation files"
echo "───────────────────────────────────────────────────────"

# List of documentation files to remove (keeping only essential ones)
DOCS_TO_REMOVE=(
    "CLEANUP_AND_VALIDATION_PLAN.md"
    "VALIDATION_EXECUTION_GUIDE.md"
    "CLEANUP_AND_VALIDATION_SUMMARY.md"
    "ACTUAL_PAGES_SCAN_REPORT.md"
    "TENANT_APP_STATUS.md"
    "DEPLOYMENT_INSTRUCTIONS.md"
    "FINAL_STATUS_REPORT.md"
    "CURSOR_FIX_PROMPT.md"
    "PRODUCTION_SUMMARY.md"
    "IP_UPDATE_SUMMARY.md"
    "PRODUCTION_ARCHITECTURE.md"
    "FINAL_COMPLETE_STATUS.md"
    "COMPLETE_VALIDATION_GUIDE.md"
)

DOC_REMOVED=0
for doc in "${DOCS_TO_REMOVE[@]}"; do
    if [ -f "$doc" ]; then
        rm "$doc"
        echo "  ✓ Removed: $doc"
        ((DOC_REMOVED++))
    fi
done

echo ""
echo "Removed $DOC_REMOVED documentation files"

echo ""
echo "STEP 4: Remove old deployment scripts"
echo "───────────────────────────────────────────────────────"

# Remove test/temp deployment scripts
SCRIPTS_TO_REMOVE=(
    "TEST_TENANT_END_TO_END.sh"
    "FIX_TENANT_NAVIGATION.sh"
    "COMPLETE_TENANT_FIX.sh"
    "DEPLOY_WORKING_TENANT.sh"
    "RESTORE_AND_DIAGNOSE.sh"
    "CLEANUP_PROJECT.sh"
    "LOAD_SAMPLE_DATA.sh"
)

SCRIPT_REMOVED=0
for script in "${SCRIPTS_TO_REMOVE[@]}"; do
    if [ -f "$script" ]; then
        rm "$script"
        echo "  ✓ Removed: $script"
        ((SCRIPT_REMOVED++))
    fi
done

echo ""
echo "Removed $SCRIPT_REMOVED old scripts"

echo ""
echo "STEP 5: Final file list"
echo "───────────────────────────────────────────────────────"

echo ""
echo "✅ ESSENTIAL FILES KEPT:"
echo ""
echo "📄 Documentation:"
ls -1 *.md 2>/dev/null | grep -E "^(README|COMPLETE_PAGES_INVENTORY)" || echo "  README.md and COMPLETE_PAGES_INVENTORY.md"

echo ""
echo "📜 Deployment Scripts:"
ls -1 *.sh 2>/dev/null | head -10 || echo "  Production deployment scripts"

echo ""
echo "📁 Application Folders:"
ls -d pgworld* USER_GUIDES 2>/dev/null || echo "  pgworld-master/, pgworldtenant-master/, USER_GUIDES/"

echo ""
echo "═══════════════════════════════════════════════════════"
echo "✅ CLEANUP COMPLETE!"
echo "═══════════════════════════════════════════════════════"
echo ""
echo "📊 Summary:"
echo "  - PowerShell files removed: $PS1_COUNT"
echo "  - Documentation files removed: $DOC_REMOVED"
echo "  - Old scripts removed: $SCRIPT_REMOVED"
echo ""
echo "🎯 System Status:"
echo "  - Admin Portal: http://54.227.101.30/admin/"
echo "  - Tenant Portal: http://54.227.101.30/tenant/"
echo "  - API: http://54.227.101.30:8080"
echo ""
echo "Next: Test login and verify data in admin portal"
echo "═══════════════════════════════════════════════════════"

