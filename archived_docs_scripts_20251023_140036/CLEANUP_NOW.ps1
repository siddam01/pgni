# Quick cleanup script - Run this now!

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$archiveDir = "archived_docs_scripts_$timestamp"

Write-Host "Creating archive folder: $archiveDir" -ForegroundColor Cyan
New-Item -ItemType Directory -Path $archiveDir -Force | Out-Null

Write-Host "Moving .md files (keeping README.md)..." -ForegroundColor Yellow
Get-ChildItem -Path . -Filter "*.md" -File | Where-Object { $_.Name -ne "README.md" } | Move-Item -Destination $archiveDir -Force

Write-Host "Moving .sh files..." -ForegroundColor Yellow
Get-ChildItem -Path . -Filter "*.sh" -File | Move-Item -Destination $archiveDir -Force

Write-Host "Moving .ps1 files (except this one)..." -ForegroundColor Yellow
Get-ChildItem -Path . -Filter "*.ps1" -File | Where-Object { $_.Name -ne "CLEANUP_NOW.ps1" } | Move-Item -Destination $archiveDir -Force

Write-Host "Moving .bat files..." -ForegroundColor Yellow
Get-ChildItem -Path . -Filter "*.bat" -File | Move-Item -Destination $archiveDir -Force

Write-Host "Moving .csv files..." -ForegroundColor Yellow
Get-ChildItem -Path . -Filter "*.csv" -File | Move-Item -Destination $archiveDir -Force

Write-Host "Moving old archive folders..." -ForegroundColor Yellow
Get-ChildItem -Path . -Directory | Where-Object { 
    ($_.Name -like "archive*") -and ($_.Name -ne $archiveDir)
} | Move-Item -Destination $archiveDir -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "✅ CLEANUP COMPLETE!" -ForegroundColor Green
Write-Host ""
Write-Host "Archived files location: $archiveDir" -ForegroundColor Cyan
Write-Host ""
Write-Host "Your workspace now contains only:" -ForegroundColor Green
Write-Host "  - README.md"
Write-Host "  - pgworld-master/ (Admin Portal & API)"
Write-Host "  - pgworldtenant-master/ (Tenant Portal)"
Write-Host "  - terraform/ (Infrastructure)"
Write-Host "  - USER_GUIDES/ (User documentation)"
Write-Host "  - $archiveDir/ (all archived files)"
Write-Host ""

