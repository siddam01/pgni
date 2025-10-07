# PG World - Change Package Name Script
# This script updates package names from com.saikrishna to com.mani

param(
    [string]$NewDeveloperName = "mani"
)

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  PG World - Change Package Names" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$rootDir = $PSScriptRoot

Write-Host "WARNING: Changing package names is a significant change!" -ForegroundColor Yellow
Write-Host ""
Write-Host "Current Package Names:" -ForegroundColor Yellow
Write-Host "  Admin: com.saikrishna.cloudpg" -ForegroundColor Gray
Write-Host "  Tenant: com.saikrishna.cloudpgtenant" -ForegroundColor Gray
Write-Host ""
Write-Host "New Package Names:" -ForegroundColor Yellow
Write-Host "  Admin: com.$NewDeveloperName.pgni" -ForegroundColor Green
Write-Host "  Tenant: com.$NewDeveloperName.pgnitenant" -ForegroundColor Green
Write-Host ""
Write-Host "This will update:" -ForegroundColor Yellow
Write-Host "  - AndroidManifest.xml files" -ForegroundColor Gray
Write-Host "  - build.gradle files" -ForegroundColor Gray
Write-Host "  - MainActivity files" -ForegroundColor Gray
Write-Host "  - Folder structure" -ForegroundColor Gray
Write-Host ""
Write-Host "Note: If apps are already published, users will need to:" -ForegroundColor Red
Write-Host "  - Uninstall old app" -ForegroundColor Red
Write-Host "  - Install new app (treated as different app)" -ForegroundColor Red
Write-Host ""

$confirm = Read-Host "Are you sure you want to proceed? (Y/N)"
if ($confirm -ne 'Y' -and $confirm -ne 'y') {
    Write-Host "Cancelled." -ForegroundColor Red
    exit
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  ADMIN APP CHANGES" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Admin App - AndroidManifest.xml
Write-Host "Step 1: Updating Admin App AndroidManifest.xml..." -ForegroundColor Yellow
$adminManifest = Join-Path $rootDir "pgworld-master\android\app\src\main\AndroidManifest.xml"
if (Test-Path $adminManifest) {
    $content = Get-Content $adminManifest -Raw
    $content = $content -replace 'package="com.saikrishna.cloudpg"', "package=`"com.$NewDeveloperName.pgni`""
    Set-Content -Path $adminManifest -Value $content -NoNewline
    Write-Host "  Updated AndroidManifest.xml" -ForegroundColor Green
} else {
    Write-Host "  Not found: $adminManifest" -ForegroundColor Red
}

# Admin App - build.gradle
Write-Host "Step 2: Updating Admin App build.gradle..." -ForegroundColor Yellow
$adminGradle = Join-Path $rootDir "pgworld-master\android\app\build.gradle"
if (Test-Path $adminGradle) {
    $content = Get-Content $adminGradle -Raw
    $content = $content -replace 'applicationId "com.saikrishna.cloudpg"', "applicationId `"com.$NewDeveloperName.pgni`""
    Set-Content -Path $adminGradle -Value $content -NoNewline
    Write-Host "  Updated build.gradle" -ForegroundColor Green
} else {
    Write-Host "  Not found: $adminGradle" -ForegroundColor Red
}

# Admin App - MainActivity.java
Write-Host "Step 3: Updating Admin App MainActivity.java..." -ForegroundColor Yellow
$adminMainActivity = Join-Path $rootDir "pgworld-master\android\app\src\main\java\com\saikrishna\cloudpg\MainActivity.java"
if (Test-Path $adminMainActivity) {
    $content = Get-Content $adminMainActivity -Raw
    $content = $content -replace 'package com.saikrishna.cloudpg;', "package com.$NewDeveloperName.pgni;"
    
    # Create new directory structure
    $newDir = Join-Path $rootDir "pgworld-master\android\app\src\main\java\com\$NewDeveloperName\pgni"
    New-Item -ItemType Directory -Path $newDir -Force | Out-Null
    
    # Save to new location
    $newMainActivity = Join-Path $newDir "MainActivity.java"
    Set-Content -Path $newMainActivity -Value $content -NoNewline
    Write-Host "  Created new MainActivity.java in com\$NewDeveloperName\pgni" -ForegroundColor Green
    
    # Remove old file
    Remove-Item $adminMainActivity -Force
    Write-Host "  Removed old MainActivity.java" -ForegroundColor Green
    
    # Try to remove old directory structure if empty
    $oldDir = Join-Path $rootDir "pgworld-master\android\app\src\main\java\com\saikrishna"
    if (Test-Path $oldDir) {
        try {
            Remove-Item $oldDir -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "  Removed old package directory" -ForegroundColor Green
        } catch {
            Write-Host "  Could not remove old directory (may not be empty)" -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "  Not found: $adminMainActivity" -ForegroundColor Red
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  TENANT APP CHANGES" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Tenant App - AndroidManifest.xml
Write-Host "Step 4: Updating Tenant App AndroidManifest.xml..." -ForegroundColor Yellow
$tenantManifest = Join-Path $rootDir "pgworldtenant-master\android\app\src\main\AndroidManifest.xml"
if (Test-Path $tenantManifest) {
    $content = Get-Content $tenantManifest -Raw
    $content = $content -replace 'package="com.saikrishna.cloudpgtenant"', "package=`"com.$NewDeveloperName.pgnitenant`""
    Set-Content -Path $tenantManifest -Value $content -NoNewline
    Write-Host "  Updated AndroidManifest.xml" -ForegroundColor Green
} else {
    Write-Host "  Not found: $tenantManifest" -ForegroundColor Red
}

# Tenant App - build.gradle
Write-Host "Step 5: Updating Tenant App build.gradle..." -ForegroundColor Yellow
$tenantGradle = Join-Path $rootDir "pgworldtenant-master\android\app\build.gradle"
if (Test-Path $tenantGradle) {
    $content = Get-Content $tenantGradle -Raw
    $content = $content -replace 'applicationId "com.saikrishna.cloudpgtenant"', "applicationId `"com.$NewDeveloperName.pgnitenant`""
    Set-Content -Path $tenantGradle -Value $content -NoNewline
    Write-Host "  Updated build.gradle" -ForegroundColor Green
} else {
    Write-Host "  Not found: $tenantGradle" -ForegroundColor Red
}

# Tenant App - MainActivity.java
Write-Host "Step 6: Updating Tenant App MainActivity.java..." -ForegroundColor Yellow
$tenantMainActivity = Join-Path $rootDir "pgworldtenant-master\android\app\src\main\java\com\saikrishna\cloudpgtenant\MainActivity.java"
if (Test-Path $tenantMainActivity) {
    $content = Get-Content $tenantMainActivity -Raw
    $content = $content -replace 'package com.saikrishna.cloudpgtenant;', "package com.$NewDeveloperName.pgnitenant;"
    
    # Create new directory structure
    $newDir = Join-Path $rootDir "pgworldtenant-master\android\app\src\main\java\com\$NewDeveloperName\pgnitenant"
    New-Item -ItemType Directory -Path $newDir -Force | Out-Null
    
    # Save to new location
    $newMainActivity = Join-Path $newDir "MainActivity.java"
    Set-Content -Path $newMainActivity -Value $content -NoNewline
    Write-Host "  Created new MainActivity.java in com\$NewDeveloperName\pgnitenant" -ForegroundColor Green
    
    # Remove old file
    Remove-Item $tenantMainActivity -Force
    Write-Host "  Removed old MainActivity.java" -ForegroundColor Green
    
    # Try to remove old directory structure if empty
    $oldDir = Join-Path $rootDir "pgworldtenant-master\android\app\src\main\java\com\saikrishna"
    if (Test-Path $oldDir) {
        try {
            Remove-Item $oldDir -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "  Removed old package directory" -ForegroundColor Green
        } catch {
            Write-Host "  Could not remove old directory (may not be empty)" -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "  Not found: $tenantMainActivity" -ForegroundColor Red
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Changes Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Summary of Changes:" -ForegroundColor Yellow
Write-Host ""
Write-Host "Admin App:" -ForegroundColor White
Write-Host "  Package: com.saikrishna.cloudpg -> com.$NewDeveloperName.pgni" -ForegroundColor Green
Write-Host "  Files: AndroidManifest.xml, build.gradle, MainActivity.java" -ForegroundColor Gray
Write-Host ""
Write-Host "Tenant App:" -ForegroundColor White
Write-Host "  Package: com.saikrishna.cloudpgtenant -> com.$NewDeveloperName.pgnitenant" -ForegroundColor Green
Write-Host "  Files: AndroidManifest.xml, build.gradle, MainActivity.java" -ForegroundColor Gray
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  NEXT STEPS" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "1. Clean and rebuild both apps:" -ForegroundColor White
Write-Host "   cd pgworld-master" -ForegroundColor Gray
Write-Host "   flutter clean" -ForegroundColor Gray
Write-Host "   flutter pub get" -ForegroundColor Gray
Write-Host "   flutter build apk --release" -ForegroundColor Gray
Write-Host ""
Write-Host "   cd ../pgworldtenant-master" -ForegroundColor Gray
Write-Host "   flutter clean" -ForegroundColor Gray
Write-Host "   flutter pub get" -ForegroundColor Gray
Write-Host "   flutter build apk --release" -ForegroundColor Gray
Write-Host ""

Write-Host "2. Test on device:" -ForegroundColor White
Write-Host "   - Install both apps" -ForegroundColor Gray
Write-Host "   - Verify they work correctly" -ForegroundColor Gray
Write-Host "   - Check package names in device settings" -ForegroundColor Gray
Write-Host ""

Write-Host "3. If publishing to stores:" -ForegroundColor White
Write-Host "   - Create NEW listings (these are new apps)" -ForegroundColor Gray
Write-Host "   - Cannot update existing apps" -ForegroundColor Gray
Write-Host "   - Users will need to download new versions" -ForegroundColor Gray
Write-Host ""

Write-Host "IMPORTANT NOTES:" -ForegroundColor Red
Write-Host "  - These are now DIFFERENT apps from the originals" -ForegroundColor Yellow
Write-Host "  - Cannot update existing installations" -ForegroundColor Yellow
Write-Host "  - Users must uninstall old and install new" -ForegroundColor Yellow
Write-Host "  - Data will NOT transfer automatically" -ForegroundColor Yellow
Write-Host ""

Write-Host "Done!" -ForegroundColor Green
Write-Host ""

