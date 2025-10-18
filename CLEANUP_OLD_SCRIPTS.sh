#!/bin/bash

echo "════════════════════════════════════════════════════════"
echo "🧹 Cleaning Up Old Deployment Scripts"
echo "════════════════════════════════════════════════════════"

cd /home/ec2-user/pgni/

# Create archive for old scripts
ARCHIVE_DIR="old_scripts_archive_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$ARCHIVE_DIR"

# Move old scripts to archive
OLD_SCRIPTS=(
    "ABSOLUTE_FINAL_FIX.sh"
    "ABSOLUTE_WORKING_FIX.sh"
    "CLEAN_CONFIG_AND_BUILD.sh"
    "COMPLETE_NULL_SAFE_FIX.sh"
    "COMPLETE_PRODUCTION_DEPLOY.sh"
    "COMPLETE_SETUP_WITH_DATA.sh"
    "COMPLETE_TENANT_REBUILD.sh"
    "CREATE_UTILS_FILE.sh"
    "DEPLOY_ADMIN_ONLY_NOW.sh"
    "DEPLOY_TENANT_NOW.sh"
    "FINAL_COMPLETE_SOLUTION.sh"
    "FINAL_TENANT_FIX.sh"
    "FINAL_TENANT_SOLUTION.sh"
    "FINAL_WORKING_SOLUTION.sh"
    "FIX_AND_DEPLOY_TENANT.sh"
    "FIX_BLANK_SCREEN.sh"
    "FIX_BOTH_APPS.sh"
    "FIX_NGINX_ACCESS.sh"
    "FIX_SCREEN_NULLS.sh"
    "FIX_TENANT_AND_DEPLOY_ALL.sh"
    "FIX_TENANT_DEPLOYMENT.sh"
    "FIX_WITH_MANUAL_IP.sh"
    "OPTIMIZED_TENANT_FIX.sh"
    "PATCH_TENANT_SCREENS.sh"
    "PRODUCTION_READY_FIX.sh"
    "SET_API_KEYS.sh"
    "SIMPLE_BUILD_AND_DEPLOY.sh"
    "SURGICAL_FIX_ALL.sh"
    "ULTIMATE_FIX_ALL_ERRORS.sh"
    "ULTIMATE_TENANT_FIX.sh"
)

for script in "${OLD_SCRIPTS[@]}"; do
    if [ -f "$script" ]; then
        mv "$script" "$ARCHIVE_DIR/"
        echo "✓ Archived: $script"
    fi
done

echo ""
echo "✅ Cleanup complete!"
echo "   Archived $(ls -1 $ARCHIVE_DIR | wc -l) old scripts to: $ARCHIVE_DIR"
echo ""
echo "Active deployment script:"
echo "   → PRODUCTION_DEPLOY.sh (The only script you need!)"

