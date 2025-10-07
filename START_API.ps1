# Quick Start Script for PG World API
# Run this after MySQL is installed and database is setup

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Starting PG World API Server" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

$apiPath = "C:\MyFolder\Mytest\pgworld-master\pgworld-api-master"

# Check if main.exe exists
if (Test-Path "$apiPath\main.exe") {
    Write-Host "[OK] API executable found" -ForegroundColor Green
} else {
    Write-Host "[X] API executable not found. Building..." -ForegroundColor Yellow
    Set-Location $apiPath
    go build -o main.exe .
    if ($?) {
        Write-Host "[OK] Build successful" -ForegroundColor Green
    } else {
        Write-Host "[X] Build failed" -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "Starting API server..." -ForegroundColor Yellow
Write-Host "Server will run on: http://localhost:8080" -ForegroundColor Cyan
Write-Host ""
Write-Host "Press Ctrl+C to stop the server" -ForegroundColor Gray
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

Set-Location $apiPath
.\main.exe

