#!/usr/bin/env pwsh
# Documentation Cleanup Script
# Removes redundant documentation files before production

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  DOCUMENTATION CLEANUP FOR PRODUCTION" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

# Files to KEEP (essential for production)
$keepFiles = @(
    "README.md",                           # Main project documentation
    "PRE_DEPLOYMENT_CHECKLIST.md",         # Important for deployment
    "DEPLOY_TO_AWS.md",                    # AWS deployment guide
    "DEPLOY_TO_AZURE.md",                  # Azure deployment guide
    "GITHUB_SETUP_GUIDE.md",               # CI/CD setup guide
    "pgworld-api-master\README.md",        # API documentation
    "pgworld-master\README.md",            # Admin app README
    "pgworldtenant-master\README.md"       # Tenant app README
)

# Files to REMOVE (redundant or development-only)
$removeFiles = @(
    "AWS_PIPELINE_SETUP.md",               # Covered in GITHUB_SETUP_GUIDE.md
    "BEFORE_AFTER_COMPARISON.md",          # Development documentation
    "CHANGE_APP_NAME_GUIDE.md",            # One-time task, already done
    "CLOUD_DEPLOYMENT_READINESS.md",       # Development assessment
    "DEPLOYMENT_READY_SUMMARY.md",         # Redundant with README.md
    "DOCUMENTATION_INDEX.md",              # Not needed with fewer docs
    "GITHUB_ACTIONS_PIPELINE.md",          # Covered in GITHUB_SETUP_GUIDE.md
    "IMPROVEMENTS_COMPLETE.md",            # Development documentation
    "IMPROVEMENT_SUMMARY.md",              # Development documentation
    "PIPELINE_QUICK_START.md",             # Redundant with GITHUB_SETUP_GUIDE.md
    "PLATFORM_COMPARISON.md",              # Covered in deployment guides
    "PRODUCTION_READY_IMPROVEMENTS.md",    # Development documentation
    "QUICK_STATUS.md",                     # Development status, not needed
    "SOLUTION_ANALYSIS_AND_ROADMAP.md",    # Development planning document
    "START_HERE.md",                       # Redundant with README.md
    "pgworld-master\COMPLETE_UI_ACCESS_GUIDE.md",     # Development guide
    "pgworld-master\SETUP_GUIDE.md",                  # Covered in main README
    "pgworld-master\VERIFICATION_COMPLETE.md"         # Development verification
)

Write-Host "Files to keep:" -ForegroundColor Green
foreach ($file in $keepFiles) {
    Write-Host "  [KEEP] $file" -ForegroundColor Green
}

Write-Host ""
Write-Host "Files to remove:" -ForegroundColor Yellow
$removedCount = 0

foreach ($file in $removeFiles) {
    $fullPath = Join-Path -Path "C:\MyFolder\Mytest\pgworld-master" -ChildPath $file
    if (Test-Path $fullPath) {
        Write-Host "  [REMOVE] $file" -ForegroundColor Yellow
        Remove-Item -Path $fullPath -Force
        $removedCount++
    } else {
        Write-Host "  [SKIP] $file (not found)" -ForegroundColor DarkGray
    }
}

Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  CLEANUP COMPLETE" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Removed: $removedCount files" -ForegroundColor Yellow
Write-Host ""
Write-Host "ESSENTIAL DOCUMENTATION REMAINING:" -ForegroundColor Green
Write-Host "  1. README.md - Main project guide" -ForegroundColor White
Write-Host "  2. PRE_DEPLOYMENT_CHECKLIST.md - Deployment checklist" -ForegroundColor White
Write-Host "  3. DEPLOY_TO_AWS.md - AWS deployment steps" -ForegroundColor White
Write-Host "  4. DEPLOY_TO_AZURE.md - Azure deployment steps" -ForegroundColor White
Write-Host "  5. GITHUB_SETUP_GUIDE.md - CI/CD pipeline setup" -ForegroundColor White
Write-Host "  6. Component READMEs (API, Admin, Tenant)" -ForegroundColor White
Write-Host ""
Write-Host "NEXT STEP: Commit and push changes to GitHub" -ForegroundColor Cyan
Write-Host "  git add ." -ForegroundColor White
Write-Host "  git commit -m 'Clean up redundant documentation'" -ForegroundColor White
Write-Host "  git push" -ForegroundColor White
Write-Host ""

