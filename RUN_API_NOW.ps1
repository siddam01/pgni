# Quick Script to Run the PG World API
# This will attempt to run the API even without database initially

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  PG World API - Quick Start" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

$apiPath = "C:\MyFolder\Mytest\pgworld-master\pgworld-api-master"
$mysqlPath = "C:\Program Files\MySQL\MySQL Server 8.4\bin"

# Add MySQL to PATH
if (Test-Path $mysqlPath) {
    $env:Path += ";$mysqlPath"
    Write-Host "[OK] MySQL path added" -ForegroundColor Green
} else {
    Write-Host "[!] MySQL not found in expected location" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Checking MySQL Server status..." -ForegroundColor Yellow

# Try to check MySQL version
try {
    $mysqlVersion = & mysql --version 2>&1
    Write-Host "[OK] MySQL command available: $mysqlVersion" -ForegroundColor Green
} catch {
    Write-Host "[!] MySQL command not available" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "API Information:" -ForegroundColor Yellow
Write-Host "  Location: $apiPath" -ForegroundColor Gray
Write-Host "  Port: 8080" -ForegroundColor Gray
Write-Host "  Health: http://localhost:8080/health" -ForegroundColor Gray
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Check if executable exists
if (Test-Path "$apiPath\main.exe") {
    Write-Host "[OK] API executable found" -ForegroundColor Green
    Write-Host ""
    Write-Host "Starting API server..." -ForegroundColor Yellow
    Write-Host "Press Ctrl+C to stop" -ForegroundColor Gray
    Write-Host ""
    
    Set-Location $apiPath
    .\main.exe
} else {
    Write-Host "[X] API executable not found!" -ForegroundColor Red
    Write-Host "Building API..." -ForegroundColor Yellow
    Set-Location $apiPath
    go build -o main.exe .
    if ($?) {
        Write-Host "[OK] Build successful, starting API..." -ForegroundColor Green
        .\main.exe
    } else {
        Write-Host "[X] Build failed" -ForegroundColor Red
    }
}

