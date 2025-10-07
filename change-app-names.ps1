# PG World - Change App Names Script
# This script updates the display names for both Admin and Tenant apps

param(
    [string]$AdminName = "PGNi",
    [string]$TenantName = "PGNi"
)

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  PG World - Change App Names" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$rootDir = $PSScriptRoot

Write-Host "Current App Names:" -ForegroundColor Yellow
Write-Host "  Admin App: 'Cloud PG'" -ForegroundColor Gray
Write-Host "  Tenant App: 'Cloud PG'" -ForegroundColor Gray
Write-Host ""
Write-Host "New App Names:" -ForegroundColor Yellow
Write-Host "  Admin App: '$AdminName'" -ForegroundColor Green
Write-Host "  Tenant App: '$TenantName'" -ForegroundColor Green
Write-Host ""

$confirm = Read-Host "Do you want to proceed? (Y/N)"
if ($confirm -ne 'Y' -and $confirm -ne 'y') {
    Write-Host "Cancelled." -ForegroundColor Red
    exit
}

Write-Host ""
Write-Host "Step 1: Updating Admin App (Android)..." -ForegroundColor Yellow

# Admin App - Android
$adminAndroidManifest = Join-Path $rootDir "pgworld-master\android\app\src\main\AndroidManifest.xml"
if (Test-Path $adminAndroidManifest) {
    $content = Get-Content $adminAndroidManifest -Raw
    $content = $content -replace 'android:label="Cloud PG"', "android:label=`"$AdminName`""
    Set-Content -Path $adminAndroidManifest -Value $content
    Write-Host "✓ Updated: pgworld-master/android/app/src/main/AndroidManifest.xml" -ForegroundColor Green
} else {
    Write-Host "✗ Not found: $adminAndroidManifest" -ForegroundColor Red
}

Write-Host ""
Write-Host "Step 2: Updating Admin App (iOS)..." -ForegroundColor Yellow

# Admin App - iOS
$adminInfoPlist = Join-Path $rootDir "pgworld-master\ios\Runner\Info.plist"
if (Test-Path $adminInfoPlist) {
    $content = Get-Content $adminInfoPlist -Raw
    $content = $content -replace '<string>Cloud PG</string>', "<string>$AdminName</string>"
    Set-Content -Path $adminInfoPlist -Value $content
    Write-Host "✓ Updated: pgworld-master/ios/Runner/Info.plist" -ForegroundColor Green
} else {
    Write-Host "✗ Not found: $adminInfoPlist" -ForegroundColor Red
}

Write-Host ""
Write-Host "Step 3: Updating Tenant App (Android)..." -ForegroundColor Yellow

# Tenant App - Android
$tenantAndroidManifest = Join-Path $rootDir "pgworldtenant-master\android\app\src\main\AndroidManifest.xml"
if (Test-Path $tenantAndroidManifest) {
    $content = Get-Content $tenantAndroidManifest -Raw
    $content = $content -replace 'android:label="Cloud PG"', "android:label=`"$TenantName`""
    Set-Content -Path $tenantAndroidManifest -Value $content
    Write-Host "✓ Updated: pgworldtenant-master/android/app/src/main/AndroidManifest.xml" -ForegroundColor Green
} else {
    Write-Host "✗ Not found: $tenantAndroidManifest" -ForegroundColor Red
}

Write-Host ""
Write-Host "Step 4: Updating Tenant App (iOS)..." -ForegroundColor Yellow

# Tenant App - iOS
$tenantInfoPlist = Join-Path $rootDir "pgworldtenant-master\ios\Runner\Info.plist"
if (Test-Path $tenantInfoPlist) {
    $content = Get-Content $tenantInfoPlist -Raw
    $content = $content -replace '<string>cloudpgtenant</string>', "<string>$TenantName</string>"
    Set-Content -Path $tenantInfoPlist -Value $content
    Write-Host "✓ Updated: pgworldtenant-master/ios/Runner/Info.plist" -ForegroundColor Green
} else {
    Write-Host "✗ Not found: $tenantInfoPlist" -ForegroundColor Red
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Changes Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Summary:" -ForegroundColor Yellow
Write-Host "  ✓ Admin App (Android): $AdminName" -ForegroundColor Green
Write-Host "  ✓ Admin App (iOS): $AdminName" -ForegroundColor Green
Write-Host "  ✓ Tenant App (Android): $TenantName" -ForegroundColor Green
Write-Host "  ✓ Tenant App (iOS): $TenantName" -ForegroundColor Green
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Next Steps:" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "1. Rebuild Admin App:" -ForegroundColor White
Write-Host "   cd pgworld-master" -ForegroundColor Gray
Write-Host "   flutter clean" -ForegroundColor Gray
Write-Host "   flutter build apk --release" -ForegroundColor Gray
Write-Host ""

Write-Host "2. Rebuild Tenant App:" -ForegroundColor White
Write-Host "   cd pgworldtenant-master" -ForegroundColor Gray
Write-Host "   flutter clean" -ForegroundColor Gray
Write-Host "   flutter build apk --release" -ForegroundColor Gray
Write-Host ""

Write-Host "3. Install and test on device" -ForegroundColor White
Write-Host ""

Write-Host "4. When ready to publish:" -ForegroundColor White
Write-Host "   - Update Play Store listing with new name" -ForegroundColor Gray
Write-Host "   - Update App Store listing with new name" -ForegroundColor Gray
Write-Host "   - Update screenshots if they show old name" -ForegroundColor Gray
Write-Host ""

Write-Host "Where the new names will appear:" -ForegroundColor Cyan
Write-Host "  ✓ Play Store listing" -ForegroundColor Green
Write-Host "  ✓ App Store listing" -ForegroundColor Green
Write-Host "  ✓ Phone home screen" -ForegroundColor Green
Write-Host "  ✓ App switcher" -ForegroundColor Green
Write-Host "  ✓ Settings -> Apps" -ForegroundColor Green
Write-Host ""

Write-Host "Note: Package names remain unchanged" -ForegroundColor Gray
Write-Host "  - Admin: com.saikrishna.cloudpg" -ForegroundColor Gray
Write-Host "  - Tenant: com.saikrishna.cloudpgtenant" -ForegroundColor Gray
Write-Host "  (This is fine - existing users can still update)" -ForegroundColor Gray
Write-Host ""

Write-Host "Done!" -ForegroundColor Green
Write-Host ""

