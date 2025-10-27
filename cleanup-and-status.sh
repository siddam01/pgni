#!/bin/bash

#############################################################
# Cleanup Unwanted Files & Show Current Status
#############################################################

# Colors
GREEN='\033[92m'
RED='\033[91m'
YELLOW='\033[93m'
BLUE='\033[94m'
CYAN='\033[96m'
RESET='\033[0m'

clear

echo -e "${CYAN}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║    Cleanup & Status Check                                ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
echo -e "${RESET}"

echo -e "${YELLOW}🧹 Cleaning up unnecessary files...${RESET}"
echo ""

# Remove old deployment docs
echo "Removing outdated documentation..."
rm -f ADMIN_PORTAL_DEVELOPMENT_PLAN.md 2>/dev/null
rm -f PROJECT_COMPLETION_PLAN.md 2>/dev/null
rm -f ADMIN_MODULE_IMPLEMENTATION_STATUS.md 2>/dev/null
rm -f ADMIN_MODULE_COMPLETE_IMPLEMENTATION.md 2>/dev/null
rm -f ADMIN_MODULE_FINAL_STATUS.md 2>/dev/null
rm -f DEPLOYMENT_READY_GUIDE.md 2>/dev/null
rm -f QUICK_DEPLOY.md 2>/dev/null
rm -f ONE_COMMAND_DEPLOY.md 2>/dev/null
rm -f SETUP_CONFIG.md 2>/dev/null
rm -f ADMIN_MODULE_PENDING_TASKS.md 2>/dev/null
rm -f ADMIN_PENDING_SUMMARY.md 2>/dev/null
rm -f ADMIN_MODULE_COMPLETE_BREAKDOWN.md 2>/dev/null
rm -f ADMIN_CATEGORIES_VISUAL.md 2>/dev/null
rm -f END_TO_END_COMPLETION_PLAN.md 2>/dev/null
rm -f PHASE_1_ADMIN_PORTAL_COMPLETE.md 2>/dev/null
rm -f PHASE_2_TENANT_PORTAL_ANALYSIS_COMPLETE.md 2>/dev/null
rm -f PHASE_3_BACKEND_API_ANALYSIS_COMPLETE.md 2>/dev/null
rm -f ULTIMATE_END_TO_END_COMPLETION_SUMMARY.md 2>/dev/null
rm -f HOSTELS_MODULE_COMPLETE_SUMMARY.md 2>/dev/null
rm -f HOSTELS_MODULE_DEEP_DIVE.md 2>/dev/null
rm -f HOSTELS_MODULE_FIXES_COMPLETE.md 2>/dev/null
rm -f DEPLOY_AND_TEST_HOSTELS.md 2>/dev/null
rm -f DEPLOYMENT_INSTRUCTIONS_FINAL.md 2>/dev/null

# Remove old SQL files (keep only the working one)
echo "Removing old SQL migration files..."
rm -f pgworld-api-master/setup-database.sql 2>/dev/null
rm -f pgworld-api-master/setup-database-safe.sql 2>/dev/null
rm -f pgworld-api-master/setup-database-complete.sql 2>/dev/null
rm -f pgworld-api-master/migrations/001_owner_onboarding.sql 2>/dev/null
rm -f pgworld-api-master/migrations/001_owner_onboarding_FIXED.sql 2>/dev/null

# Remove old deployment scripts (keep only the working ones)
echo "Removing outdated deployment scripts..."
rm -f deploy-backend.sh 2>/dev/null
rm -f deploy-frontend.sh 2>/dev/null
rm -f setup-database.sh 2>/dev/null
rm -f deploy-windows.ps1 2>/dev/null
rm -f DEPLOY_HOSTELS_TO_EC2.sh 2>/dev/null
rm -f deploy_now.ps1 2>/dev/null
rm -f CLEANUP_NOW.ps1 2>/dev/null

# Remove archived directories
echo "Removing archived files..."
rm -rf archived_docs_scripts_20251023_140036 2>/dev/null

# Remove backup files
echo "Removing backup files..."
rm -rf pgworld-master/backups_20252210_195245 2>/dev/null
rm -f pgworld-master/main_old_demo.dart.bak 2>/dev/null
rm -f pgworld-api-master/main_demo.go.bak 2>/dev/null
rm -f pgworld-api-master/main_local.go.backup 2>/dev/null

# Remove test/demo files
rm -f pgworld-master/main_demo.go 2>/dev/null
rm -f pgworld-master/main_solution.go 2>/dev/null

# Remove deployment command notes
rm -f DEPLOY_COMMANDS.txt 2>/dev/null
rm -f TEST_HOSTELS_MODULE.md 2>/dev/null
rm -f START_HERE_DEPLOYMENT.md 2>/dev/null

echo -e "${GREEN}✅ Cleanup complete!${RESET}"
echo ""

echo -e "${CYAN}════════════════════════════════════════════════════════════${RESET}"
echo -e "${GREEN}📊 CURRENT PROJECT STATUS${RESET}"
echo -e "${CYAN}════════════════════════════════════════════════════════════${RESET}"
echo ""

# Check what exists
echo -e "${BLUE}📁 Project Structure:${RESET}"
echo "  ✅ pgworld-master/          - Admin Portal (Flutter)"
echo "  ✅ pgworldtenant-master/    - Tenant Portal (Flutter)"
echo "  ✅ pgworld-api-master/      - Backend API (Go)"
echo ""

echo -e "${BLUE}🔧 Active Deployment Files:${RESET}"
echo "  ✅ fix-and-deploy.sh        - Complete automated deployment"
echo "  ✅ fix-database.py          - Python database setup"
echo "  ✅ test-db-connection.sh    - Test database connection"
echo "  ✅ EC2_DEPLOY_MASTER.sh     - Full EC2 deployment"
echo ""

echo -e "${BLUE}📝 Current Documentation:${RESET}"
echo "  ✅ README.md                - Main project README"
echo "  ✅ DEPLOYMENT_OPTIONS.md    - Deployment method comparison"
echo "  ✅ DATABASE_SETUP_FIXED.md  - Database setup guide"
echo "  ✅ FOREIGN_KEY_FIX.md       - Foreign key issue explanation"
echo "  ✅ PYTHON_MIGRATION_GUIDE.md - Python script documentation"
echo ""

echo -e "${BLUE}📄 Database Migration Files:${RESET}"
echo "  ✅ setup-database-simple.sql - Working SQL migration (no foreign keys)"
echo ""

echo -e "${CYAN}════════════════════════════════════════════════════════════${RESET}"
echo -e "${YELLOW}⚠️  CURRENT ISSUE:${RESET}"
echo -e "${CYAN}════════════════════════════════════════════════════════════${RESET}"
echo ""
echo "  ❌ Database tables incomplete (hostel_id column missing in rooms table)"
echo "  ❌ Backend not deployed yet"
echo "  ❌ Frontend not deployed yet"
echo ""

echo -e "${CYAN}════════════════════════════════════════════════════════════${RESET}"
echo -e "${GREEN}🎯 NEXT STEPS:${RESET}"
echo -e "${CYAN}════════════════════════════════════════════════════════════${RESET}"
echo ""
echo "  1️⃣  Fix database schema (choose one):"
echo ""
echo "      ${GREEN}OPTION A (Recommended):${RESET}"
echo "      bash <(curl -sL https://raw.githubusercontent.com/siddam01/pgni/main/fix-and-deploy.sh)"
echo "      ${YELLOW}↳ Password when prompted: Omsairam951#${RESET}"
echo "      ${BLUE}↳ Does: Database + Backend deployment${RESET}"
echo ""
echo "      ${GREEN}OPTION B (SQL only):${RESET}"
echo "      cd ~/pgni-deployment"
echo "      mysql -h \$(grep RDS_ENDPOINT ~/.pgni-config | cut -d'\"' -f2) \\"
echo "            -u \$(grep DB_USER ~/.pgni-config | cut -d'\"' -f2) \\"
echo "            -p < setup-database-simple.sql"
echo "      ${YELLOW}↳ Password: Omsairam951#${RESET}"
echo "      ${BLUE}↳ Does: Database only${RESET}"
echo ""
echo "  2️⃣  Once database is fixed, build backend:"
echo "      cd ~/pgni-deployment/pgworld-api-master"
echo "      go build -o pgworld-api main.go"
echo "      sudo systemctl restart pgworld-api"
echo ""
echo "  3️⃣  Test backend API:"
echo "      curl http://localhost:8080/"
echo ""
echo "  4️⃣  Deploy frontends to S3 (from local machine)"
echo ""

echo -e "${CYAN}════════════════════════════════════════════════════════════${RESET}"
echo -e "${GREEN}📦 WHAT YOU'LL GET AFTER DATABASE SETUP:${RESET}"
echo -e "${CYAN}════════════════════════════════════════════════════════════${RESET}"
echo ""
echo "  ✅ 12 tables (admins, hostels, rooms, users, bills, issues, etc.)"
echo "  ✅ RBAC system (owner/manager roles, 10 permissions)"
echo "  ✅ Demo data:"
echo "     • 1 Admin (username: admin, password: admin123)"
echo "     • 1 Hostel (Demo PG Hostel)"
echo "     • 4 Rooms (101, 102, 103, 104)"
echo "     • 1 Tenant (John Doe in Room 101)"
echo ""

echo -e "${CYAN}════════════════════════════════════════════════════════════${RESET}"
echo -e "${GREEN}💡 RECOMMENDATION:${RESET}"
echo -e "${CYAN}════════════════════════════════════════════════════════════${RESET}"
echo ""
echo "  Run OPTION A (fix-and-deploy.sh) - it will:"
echo "  ✅ Fix database completely"
echo "  ✅ Build and deploy backend"
echo "  ✅ Start API service"
echo "  ✅ Test everything"
echo ""
echo "  ${GREEN}One command to complete deployment:${RESET}"
echo "  ${CYAN}bash <(curl -sL https://raw.githubusercontent.com/siddam01/pgni/main/fix-and-deploy.sh)${RESET}"
echo ""

echo -e "${YELLOW}Status check completed at: $(date)${RESET}"
echo ""


