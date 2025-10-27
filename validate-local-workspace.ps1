# CloudPG Local Workspace Validation
Write-Host "
==========================================" -ForegroundColor Cyan
Write-Host " LOCAL WORKSPACE VALIDATION" -ForegroundColor Cyan
Write-Host "==========================================
" -ForegroundColor Cyan

$errors = 0

# Check Admin Source
Write-Host "Checking Admin Source Code..." -ForegroundColor Blue
if (Select-String -Path "pgworld-master\lib\*" -Pattern "minimal working version|being fixed|coming soon" -Quiet) {
    Write-Host "  X PLACEHOLDERS FOUND!" -ForegroundColor Red
    $errors++
} else {
    Write-Host "   CLEAN" -ForegroundColor Green
}

# Check Admin Build
Write-Host "Checking Admin Build Files..." -ForegroundColor Blue
if (Test-Path "pgworld-master\build\web\index.html") {
    if (Select-String -Path "pgworld-master\build\web\*.js" -Pattern "minimal working version|being fixed" -Quiet) {
        Write-Host "  X PLACEHOLDERS FOUND!" -ForegroundColor Red
        $errors++
    } else {
        Write-Host "   CLEAN" -ForegroundColor Green
    }
} else {
    Write-Host "  - Build not found" -ForegroundColor Yellow
}

# Check Tenant Source
Write-Host "Checking Tenant Source Code..." -ForegroundColor Blue
if (Select-String -Path "pgworldtenant-master\lib\*" -Pattern "minimal working version|being fixed|coming soon" -Quiet) {
    Write-Host "  X PLACEHOLDERS FOUND!" -ForegroundColor Red
    $errors++
} else {
    Write-Host "   CLEAN" -ForegroundColor Green
}

# Check Tenant Build
Write-Host "Checking Tenant Build Files..." -ForegroundColor Blue
if (Test-Path "pgworldtenant-master\build\web\index.html") {
    if (Select-String -Path "pgworldtenant-master\build\web\*.js" -Pattern "coming soon|being fixed" -Quiet) {
        Write-Host "  X PLACEHOLDERS FOUND!" -ForegroundColor Red
        $errors++
    } else {
        Write-Host "   CLEAN" -ForegroundColor Green
    }
} else {
    Write-Host "  - Build not found" -ForegroundColor Yellow
}

Write-Host "
==========================================" -ForegroundColor Cyan
if ($errors -eq 0) {
    Write-Host "  ALL CLEAN! Ready for deployment" -ForegroundColor Green
} else {
    Write-Host " X Found $errors issue(s)" -ForegroundColor Red
}
Write-Host "==========================================
" -ForegroundColor Cyan
