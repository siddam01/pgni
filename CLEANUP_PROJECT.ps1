# ============================================================================
# Project Cleanup Script
# Organizes files: keeps essential ones, archives old/duplicate documentation
# ============================================================================

Write-Host "=============================================="
Write-Host "  PGNi Project Cleanup"
Write-Host "=============================================="
Write-Host ""

$ArchiveFolder = "archive"

# Create archive folder if it doesn't exist
if (-not (Test-Path $ArchiveFolder)) {
    New-Item -ItemType Directory -Path $ArchiveFolder | Out-Null
    Write-Host "Created archive folder" -ForegroundColor Green
}

# ============================================================================
# ESSENTIAL FILES TO KEEP (in root)
# ============================================================================

$EssentialFiles = @(
    # === DEPLOYMENT & GETTING STARTED ===
    "README.md",
    "START_HERE_FINAL.md",
    "DEPLOYMENT_GUIDE.md",
    "EXECUTIVE_SUMMARY.md",
    
    # === DEPLOYMENT SCRIPTS (Keep most recent/working ones) ===
    "DEPLOY_VIA_SSM.sh",
    "FIX_403_AND_DEPLOY_FULL_APP.sh",
    "CHECK_CURRENT_STATUS.sh",
    "DIAGNOSE_500_ERROR.sh",
    
    # === VALIDATION ===
    "POST_DEPLOYMENT_VALIDATION.md",
    "PRE_DEPLOYMENT_CHECK.sh",
    
    # === CONFIGURATION ===
    ".gitignore",
    "TECHNOLOGY_STACK.md",
    
    # === TERRAFORM (Infrastructure) ===
    "terraform",
    
    # === GITHUB ACTIONS (CI/CD) ===
    ".github",
    
    # === APPLICATION CODE ===
    "pgworld-api-master",
    "pgworld-master",
    "pgworldtenant-master",
    
    # === USER GUIDES ===
    "USER_GUIDES",
    
    # === BATCH SCRIPTS FOR LOCAL TESTING ===
    "RUN_ADMIN_APP.bat",
    "RUN_TENANT_APP.bat",
    "CHECK_BUILD_STATUS.bat"
)

# ============================================================================
# FILES TO ARCHIVE (Old/Duplicate Documentation)
# ============================================================================

$FilesToArchive = @(
    # Old deployment guides
    "PROJECT_STRUCTURE.md",
    "DEPLOYMENT_SUCCESS.md",
    "INFRASTRUCTURE.md",
    "QUICK_START.md",
    "VALIDATION_CHECKLIST.md",
    "CURRENT_STATUS_REPORT.md",
    "DEPLOY_VIA_CLOUDSHELL.md",
    "DEPLOY_MANUAL_STEPS.md",
    "DEPLOY_QUICK_REFERENCE.md",
    "START_HERE_COMPLETE_SOLUTION.md",
    "QUICK_FIX_NOW.md",
    "FINAL_FIX_NOW.txt",
    "UPLOAD_CODE_DIRECTLY.txt",
    "SIMPLEST_SOLUTION.MD",
    "GITHUB_SECRETS_SETUP.md",
    "PIPELINE_ARCHITECTURE.md",
    "ENTERPRISE_PIPELINE_GUIDE.md",
    "CURRENT_STATUS_AND_FIXES.md",
    "ISSUES_FIXED_SUMMARY.md",
    "COPY_THIS_TO_CLOUDSHELL.txt",
    "DEPLOY_API_NOW_COMPLETE.txt",
    "URL_ACCESS_AND_MOBILE_CONFIG.md",
    "COMPLETE_DEPLOYMENT_SOLUTION.sh",
    "START_HERE.md",
    "COMPLETE_VALIDATION_REPORT.md",
    "FIX_AND_DEPLOY_NOW.sh",
    "DEPLOY_SIMPLE.sh",
    "GET_SSH_KEY_INSTRUCTIONS.md",
    "DEPLOY_DIRECT.sh",
    "SIMPLE_DEPLOY_FOR_CLOUDSHELL.txt",
    "DEPLOY_WITH_PROGRESS.txt",
    "STEP_BY_STEP_CLOUDSHELL.md",
    "CHECK_STATUS_NOW.txt",
    "WHERE_WE_ARE_NOW.md",
    "PASTE_THIS_KEY.txt",
    "QUICK_CHECK.txt",
    "FAST_DEPLOY.txt",
    "SUPER_FAST_DEPLOY.txt",
    "ENTERPRISE_DEPLOY.txt",
    "INFRASTRUCTURE_UPGRADE.md",
    "UPGRADE_INFRASTRUCTURE.sh",
    "COMPLETE_SOLUTION_SUMMARY.md",
    "INSTANT_DEPLOY.txt",
    "DEPLOY_NOW_FAST.md",
    "PRODUCTION_DEPLOY.sh",
    "ROOT_CAUSE_ANALYSIS.md",
    "PILOT_READY_SUMMARY.md",
    "FIX_CONNECTION.txt",
    "QUICK_FIX_DEPLOY.sh",
    "SEE_APP_UI_NOW.md",
    "END_TO_END_VALIDATION.md",
    "DEPLOY_FLUTTER_WEB.md",
    "BUILD_AND_DEPLOY_WEB.bat",
    "ARCHITECTURE_CLARIFICATION.md",
    "UI_PAGES_INVENTORY.md",
    "TEST_ALL_PAGES.bat",
    "CREATE_TEST_ACCOUNTS.sql",
    "LOAD_TEST_DATA.sh",
    "LOAD_TEST_DATA.bat",
    "UI_VALIDATION_SUMMARY.md",
    "START_TESTING_NOW.md",
    "UI_PAGES_QUICK_REFERENCE.txt",
    "API_ENDPOINTS_AND_ACCOUNTS.md",
    "COMPLETE_SYSTEM_ACCESS_GUIDE.md",
    "DEPLOYMENT_STATUS_COMPLETE.md",
    "DEPLOY_COMPLETE_SYSTEM.sh",
    "DEPLOY_COMPLETE_SYSTEM_WINDOWS.md",
    "PENDING_ITEMS_CHECKLIST.md",
    "TERRAFORM_COMPLETE_DEPLOYMENT.md",
    "DEPLOY_FRONTEND_DIRECT.sh",
    "DEPLOY_FRONTEND_NOW.sh",
    "WHATS_DEPLOYED_VS_WHAT_YOU_NEED.md",
    "FINAL_DEPLOYMENT_CHECKLIST.md",
    "BUILD_ANDROID_APPS.bat",
    "INSTALL_FLUTTER_AND_BUILD.md",
    "WHY_NO_APP_FOLDER.md",
    "DEPLOY_FULL_APP_CLOUDSHELL.sh",
    "RUN_IN_CLOUDSHELL.md",
    "CLOUDSHELL_QUICK_START.txt",
    "COMPLETE_ENTERPRISE_DEPLOYMENT.sh",
    "SENIOR_LEAD_DEPLOYMENT_GUIDE.md",
    "START_DEPLOYMENT_NOW.md",
    "DEPLOY_NO_TERRAFORM.sh",
    "VALIDATE_CURRENT_STATUS.sh",
    "COMPLETE_DEPLOYMENT_SSM.sh",
    "CLEANUP_WORKSPACE.ps1",
    "WORKSPACE_SUMMARY.md",
    "DEPLOY_NOW_CLOUDSHELL.txt",
    "DEPLOY_VALIDATED.txt",
    "DEPLOY_NOW_SKIP_VALIDATION.txt",
    "FIX_SSH_AND_DEPLOY.txt",
    
    # Old PowerShell scripts
    "deploy-from-windows.ps1",
    "deploy-api-now.ps1",
    "ONE_CLICK_DEPLOY.ps1",
    "SAFE_GITHUB_COMMIT.ps1",
    
    # Old text files
    "ssh-key-for-cloudshell.txt",
    "FIX_EC2_AND_DEPLOY.txt",
    "DEPLOY_NOW_FINAL.txt",
    
    # Sensitive files (should be in .gitignore anyway)
    "preprod.env",
    "production.env"
)

# ============================================================================
# MOVE FILES TO ARCHIVE
# ============================================================================

Write-Host "Moving old documentation to archive folder..." -ForegroundColor Cyan
Write-Host ""

$MovedCount = 0
$NotFoundCount = 0

foreach ($file in $FilesToArchive) {
    if (Test-Path $file) {
        try {
            Move-Item -Path $file -Destination $ArchiveFolder -Force -ErrorAction Stop
            Write-Host "  Archived: $file" -ForegroundColor Gray
            $MovedCount++
        } catch {
            Write-Host "  Failed to move: $file" -ForegroundColor Yellow
        }
    } else {
        $NotFoundCount++
    }
}

Write-Host ""
Write-Host "Archived $MovedCount files" -ForegroundColor Green
Write-Host "$NotFoundCount files not found (already clean)" -ForegroundColor Gray
Write-Host ""

# ============================================================================
# CREATE ARCHIVE README
# ============================================================================

$ArchiveReadme = @"
# Archive Folder

This folder contains old documentation and deployment scripts that have been superseded by newer versions.

## Why These Files Are Archived

These files were created during the development and deployment process but are no longer needed:
- **Old deployment scripts**: Replaced by more robust versions
- **Duplicate documentation**: Consolidated into main guides
- **Troubleshooting guides**: Issues have been fixed
- **Experimental scripts**: Better approaches were found

## Current (Active) Documentation

See the project root for current documentation:
- **README.md** - Project overview
- **START_HERE_FINAL.md** - Quick start guide
- **DEPLOYMENT_GUIDE.md** - Complete deployment instructions
- **EXECUTIVE_SUMMARY.md** - Business overview
- **TECHNOLOGY_STACK.md** - Tech stack details

## Deployment Scripts (Current)

Active deployment scripts:
- **DEPLOY_VIA_SSM.sh** - Deploy via AWS Systems Manager (recommended)
- **FIX_403_AND_DEPLOY_FULL_APP.sh** - Fix errors and deploy full app
- **CHECK_CURRENT_STATUS.sh** - Check deployment status
- **DIAGNOSE_500_ERROR.sh** - Diagnose server errors

---

**Note**: These archived files are kept for reference only. Use the current documentation in the project root.

Date Archived: $(Get-Date -Format "yyyy-MM-dd")
"@

Set-Content -Path "$ArchiveFolder/README.md" -Value $ArchiveReadme
Write-Host "Created archive README" -ForegroundColor Green
Write-Host ""

# ============================================================================
# SUMMARY OF ESSENTIAL FILES
# ============================================================================

Write-Host "=============================================="
Write-Host "  Cleanup Complete!"
Write-Host "=============================================="
Write-Host ""
Write-Host "Essential Files Remaining in Root:" -ForegroundColor Cyan
Write-Host ""

Write-Host "GETTING STARTED:" -ForegroundColor Yellow
Write-Host "  README.md"
Write-Host "  START_HERE_FINAL.md"
Write-Host "  DEPLOYMENT_GUIDE.md"
Write-Host "  EXECUTIVE_SUMMARY.md"
Write-Host ""

Write-Host "DEPLOYMENT SCRIPTS:" -ForegroundColor Yellow
Write-Host "  DEPLOY_VIA_SSM.sh            (Deploy via AWS SSM - recommended)"
Write-Host "  FIX_403_AND_DEPLOY_FULL_APP.sh  (Fix errors and deploy)"
Write-Host "  CHECK_CURRENT_STATUS.sh      (Check status)"
Write-Host "  DIAGNOSE_500_ERROR.sh        (Diagnose errors)"
Write-Host "  PRE_DEPLOYMENT_CHECK.sh      (Pre-deployment validation)"
Write-Host ""

Write-Host "VALIDATION:" -ForegroundColor Yellow
Write-Host "  POST_DEPLOYMENT_VALIDATION.md"
Write-Host ""

Write-Host "LOCAL TESTING:" -ForegroundColor Yellow
Write-Host "  RUN_ADMIN_APP.bat"
Write-Host "  RUN_TENANT_APP.bat"
Write-Host "  CHECK_BUILD_STATUS.bat"
Write-Host ""

Write-Host "INFRASTRUCTURE:" -ForegroundColor Yellow
Write-Host "  terraform/                    (Infrastructure as Code)"
Write-Host "  .github/                      (CI/CD pipelines)"
Write-Host ""

Write-Host "APPLICATION CODE:" -ForegroundColor Yellow
Write-Host "  pgworld-api-master/           (Backend API - Go)"
Write-Host "  pgworld-master/               (Admin App - Flutter)"
Write-Host "  pgworldtenant-master/         (Tenant App - Flutter)"
Write-Host ""

Write-Host "USER GUIDES:" -ForegroundColor Yellow
Write-Host "  USER_GUIDES/                  (End-user documentation)"
Write-Host ""

Write-Host "REFERENCE:" -ForegroundColor Yellow
Write-Host "  TECHNOLOGY_STACK.md"
Write-Host ""

Write-Host "Old files archived to: $ArchiveFolder\" -ForegroundColor Gray
Write-Host ""
Write-Host "=============================================="

