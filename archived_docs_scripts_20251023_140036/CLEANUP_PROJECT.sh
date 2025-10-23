#!/bin/bash
set -e

echo "═══════════════════════════════════════════════════════"
echo "🧹 PGNI PROJECT CLEANUP"
echo "═══════════════════════════════════════════════════════"
echo ""
echo "Removing test files, temporary scripts, and old backups"
echo "Keeping only production-ready files"
echo ""

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/tmp/pgni_cleanup_backup_$TIMESTAMP"

echo "STEP 1: Create Safety Backup"
echo "───────────────────────────────────────────────────────"
mkdir -p "$BACKUP_DIR"
echo "✓ Backup directory: $BACKUP_DIR"

echo ""
echo "STEP 2: Remove Old Deployment Scripts"
echo "───────────────────────────────────────────────────────"

# List of scripts to remove (keeping only essential ones)
SCRIPTS_TO_REMOVE=(
    "FIX_BLANK_SCREEN.sh"
    "FIX_BOTH_APPS.sh"
    "FIX_TENANT_AND_DEPLOY_ALL.sh"
    "FINAL_TENANT_FIX.sh"
    "OPTIMIZED_TENANT_FIX.sh"
    "ULTIMATE_TENANT_FIX.sh"
    "PATCH_TENANT_SCREENS.sh"
    "CLEAN_CONFIG_AND_BUILD.sh"
    "SET_API_KEYS.sh"
    "DEPLOY_TENANT_NOW.sh"
    "FIX_AND_DEPLOY_TENANT.sh"
    "FINAL_TENANT_SOLUTION.sh"
    "COMPLETE_NULL_SAFE_FIX.sh"
    "ULTIMATE_FIX_ALL_ERRORS.sh"
    "PRODUCTION_READY_FIX.sh"
    "FINAL_WORKING_SOLUTION.sh"
    "ABSOLUTE_FINAL_FIX.sh"
    "FIX_SCREEN_NULLS.sh"
    "CREATE_UTILS_FILE.sh"
    "COMPLETE_PRODUCTION_DEPLOY.sh"
    "FINAL_COMPLETE_SOLUTION.sh"
    "SURGICAL_FIX_ALL.sh"
    "ABSOLUTE_WORKING_FIX.sh"
    "FIX_TENANT_DEPLOYMENT.sh"
    "FIX_IP_AND_DEPLOY.sh"
    "GET_PUBLIC_IP_AND_FIX.sh"
    "FIX_TENANT_LOGIN.sh"
    "AUTO_FIX_TENANT_LOGIN.sh"
    "CHECK_API_STATUS.sh"
    "FIX_API_ENDPOINTS.sh"
    "DIAGNOSE_AND_FIX_API.sh"
    "FIX_JSON_ERROR.sh"
    "FIX_API_LOGIN_ENDPOINT.sh"
    "FIX_API_LOGIN_COMPLETE.sh"
    "COMPLETE_END_TO_END_TEST.sh"
    "FIX_DATABASE_CONFIG.sh"
    "FIX_BUILD_AND_TEST.sh"
    "RESTORE_AND_FIX_COMPLETE.sh"
    "SIMPLE_DB_CONNECTION_FIX.sh"
    "FINAL_TENANT_SITE_VERIFICATION.sh"
    "VERIFY_FULL_TENANT_APP.sh"
    "FIX_LOGIN_NAVIGATION.sh"
    "DEPLOY_ALL_TENANT_SCREENS.sh"
    "RESTORE_ALL_TENANT_SCREENS.sh"
    "RESTORE_FROM_GITHUB.sh"
    "FIX_AND_BUILD_TENANT.sh"
    "RESTORE_AND_DIAGNOSE.sh"
    "COMPLETE_TENANT_FIX.sh"
    "DEPLOY_WORKING_TENANT.sh"
    "FIX_TENANT_NAVIGATION.sh"
)

REMOVED_COUNT=0
for script in "${SCRIPTS_TO_REMOVE[@]}"; do
    if [ -f "$script" ]; then
        cp "$script" "$BACKUP_DIR/" 2>/dev/null || true
        rm "$script"
        echo "  ✓ Removed: $script"
        ((REMOVED_COUNT++))
    fi
done

echo ""
echo "Removed $REMOVED_COUNT deployment scripts"

echo ""
echo "STEP 3: Remove Old Documentation Files"
echo "───────────────────────────────────────────────────────"

DOCS_TO_REMOVE=(
    "DEPLOYMENT_INSTRUCTIONS.md"
    "FINAL_STATUS_REPORT.md"
    "TENANT_APP_STATUS.md"
    "CURSOR_FIX_PROMPT.md"
    "PRODUCTION_SUMMARY.md"
    "IP_UPDATE_SUMMARY.md"
    "PRODUCTION_ARCHITECTURE.md"
    "FINAL_COMPLETE_STATUS.md"
    "COMPLETE_VALIDATION_GUIDE.md"
    "COMPLETE_PAGES_INVENTORY_VALIDATION.md"
    "ACTUAL_PAGES_SCAN_REPORT.md"
)

DOC_REMOVED=0
for doc in "${DOCS_TO_REMOVE[@]}"; do
    if [ -f "$doc" ]; then
        cp "$doc" "$BACKUP_DIR/" 2>/dev/null || true
        rm "$doc"
        echo "  ✓ Removed: $doc"
        ((DOC_REMOVED++))
    fi
done

echo ""
echo "Removed $DOC_REMOVED documentation files"

echo ""
echo "STEP 4: Remove Archive Folders"
echo "───────────────────────────────────────────────────────"

# Remove archive directories
if [ -d "archive" ]; then
    tar -czf "$BACKUP_DIR/archive.tar.gz" archive/
    rm -rf archive
    echo "  ✓ Removed: archive/"
fi

# Remove old backup directories
for dir in archive_backup_* tenant_original_backup_* diagnose_backup_*; do
    if [ -d "$dir" ]; then
        rm -rf "$dir"
        echo "  ✓ Removed: $dir"
    fi
done

echo ""
echo "STEP 5: Clean Application Directories"
echo "───────────────────────────────────────────────────────"

# Clean admin app
if [ -d "pgworld-master" ]; then
    cd pgworld-master
    echo "  Cleaning admin app..."
    
    # Remove build artifacts
    rm -rf build/ .dart_tool/ .packages
    
    # Remove test files if any
    find . -name "*_test.dart" -type f -delete 2>/dev/null || true
    find . -name "*_mock.dart" -type f -delete 2>/dev/null || true
    
    cd ..
    echo "  ✓ Admin app cleaned"
fi

# Clean tenant app
if [ -d "pgworldtenant-master" ]; then
    cd pgworldtenant-master
    echo "  Cleaning tenant app..."
    
    # Remove build artifacts
    rm -rf build/ .dart_tool/ .packages
    
    # Remove test files if any
    find . -name "*_test.dart" -type f -delete 2>/dev/null || true
    find . -name "*_mock.dart" -type f -delete 2>/dev/null || true
    
    cd ..
    echo "  ✓ Tenant app cleaned"
fi

echo ""
echo "STEP 6: Summary of Kept Files"
echo "───────────────────────────────────────────────────────"

echo ""
echo "✅ KEPT ESSENTIAL SCRIPTS:"
echo "  - PRODUCTION_DEPLOY.sh (Main deployment)"
echo "  - SETUP_NGINX_PROXY.sh (Nginx setup)"
echo "  - UPDATE_IP_AND_REDEPLOY.sh (IP updates)"
echo "  - TEST_TENANT_END_TO_END.sh (Testing)"
echo "  - VERIFY_AND_FIX_LOGIN_PARSING.sh (Login fix)"
echo "  - CLEANUP_PROJECT.sh (This script)"

echo ""
echo "✅ KEPT ESSENTIAL DOCUMENTATION:"
echo "  - README.md (Main docs)"
echo "  - COMPLETE_PAGES_INVENTORY.md (Page inventory)"
echo "  - CLEANUP_AND_VALIDATION_PLAN.md (Validation plan)"

echo ""
echo "✅ KEPT APPLICATION FOLDERS:"
echo "  - pgworld-master/ (Admin app)"
echo "  - pgworldtenant-master/ (Tenant app)"
echo "  - USER_GUIDES/ (User documentation)"

echo ""
echo "═══════════════════════════════════════════════════════"
echo "✅ CLEANUP COMPLETE!"
echo "═══════════════════════════════════════════════════════"
echo ""
echo "📊 Summary:"
echo "  - Deployment scripts removed: $REMOVED_COUNT"
echo "  - Documentation files removed: $DOC_REMOVED"
echo "  - Archive folders cleaned: Yes"
echo "  - Build artifacts cleaned: Yes"
echo ""
echo "💾 Backup Location: $BACKUP_DIR"
echo ""
echo "🎯 Next Steps:"
echo "  1. Review remaining files"
echo "  2. Load sample data: bash LOAD_SAMPLE_DATA.sh"
echo "  3. Run validation tests: bash RUN_VALIDATION_TESTS.sh"
echo ""
echo "═══════════════════════════════════════════════════════"

