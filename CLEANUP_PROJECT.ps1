# Cleanup unnecessary files - keep only essential application code and deployment scripts

Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "Cleaning up unnecessary files..." -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Create archive folder for backup
$archiveFolder = "archive_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
New-Item -ItemType Directory -Path $archiveFolder -Force | Out-Null

# List of files to KEEP (essential)
$keepFiles = @(
    # Essential deployment scripts
    "FIX_WITH_MANUAL_IP.sh",
    "SIMPLE_BUILD_AND_DEPLOY.sh",
    "FIX_NGINX_ACCESS.sh",
    
    # Application source code folders
    "pgworld-api-master",
    "pgworld-master",
    "pgworldtenant-master",
    
    # Infrastructure
    "terraform",
    ".github",
    
    # Essential docs
    "README.md",
    ".gitignore",
    ".cursorrules",
    
    # Archive folder
    $archiveFolder
)

# Get all .md files except README.md
$mdFiles = Get-ChildItem -Filter "*.md" | Where-Object { $_.Name -ne "README.md" }
Write-Host "Found $($mdFiles.Count) .md documentation files to archive" -ForegroundColor Yellow

# Get all .ps1 files
$ps1Files = Get-ChildItem -Filter "*.ps1" | Where-Object { $_.Name -ne "CLEANUP_PROJECT.ps1" }
Write-Host "Found $($ps1Files.Count) .ps1 script files to archive" -ForegroundColor Yellow

# Get all .sh files except essential ones
$shFiles = Get-ChildItem -Filter "*.sh" | Where-Object { 
    $_.Name -notin @("FIX_WITH_MANUAL_IP.sh", "SIMPLE_BUILD_AND_DEPLOY.sh", "FIX_NGINX_ACCESS.sh")
}
Write-Host "Found $($shFiles.Count) .sh script files to archive" -ForegroundColor Yellow

# Get all .txt files
$txtFiles = Get-ChildItem -Filter "*.txt"
Write-Host "Found $($txtFiles.Count) .txt files to archive" -ForegroundColor Yellow

# Get all .bat files
$batFiles = Get-ChildItem -Filter "*.bat"
Write-Host "Found $($batFiles.Count) .bat files to archive" -ForegroundColor Yellow

Write-Host ""
Write-Host "Moving files to archive..." -ForegroundColor Green

# Move files to archive
$allFilesToArchive = $mdFiles + $ps1Files + $shFiles + $txtFiles + $batFiles

foreach ($file in $allFilesToArchive) {
    try {
        Move-Item -Path $file.FullName -Destination $archiveFolder -Force
        Write-Host "  Archived: $($file.Name)" -ForegroundColor Gray
    } catch {
        Write-Host "  Warning: Could not archive $($file.Name)" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "✅ Cleanup Complete!" -ForegroundColor Green
Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "📁 Project structure after cleanup:" -ForegroundColor White
Write-Host ""
Write-Host "Essential files kept:" -ForegroundColor Green
Write-Host "  ✓ FIX_WITH_MANUAL_IP.sh (main deployment script)" -ForegroundColor Gray
Write-Host "  ✓ SIMPLE_BUILD_AND_DEPLOY.sh (simple deployment)" -ForegroundColor Gray
Write-Host "  ✓ FIX_NGINX_ACCESS.sh (network fix script)" -ForegroundColor Gray
Write-Host "  ✓ README.md (main documentation)" -ForegroundColor Gray
Write-Host "  ✓ pgworld-api-master/ (backend API)" -ForegroundColor Gray
Write-Host "  ✓ pgworld-master/ (admin app)" -ForegroundColor Gray
Write-Host "  ✓ pgworldtenant-master/ (tenant app)" -ForegroundColor Gray
Write-Host "  ✓ terraform/ (infrastructure code)" -ForegroundColor Gray
Write-Host "  ✓ .github/ (CI/CD pipelines)" -ForegroundColor Gray
Write-Host ""
Write-Host "Archived files moved to:" -ForegroundColor Yellow
Write-Host "  $archiveFolder/" -ForegroundColor Gray
Write-Host ""
Write-Host "To restore archived files: Copy them back from $archiveFolder/" -ForegroundColor Cyan
Write-Host ""
