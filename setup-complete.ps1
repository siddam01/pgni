# PG World Complete Setup Script
# This script automates the setup process

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  PG World Complete Setup Script" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

$projectRoot = "C:\MyFolder\Mytest\pgworld-master"

# Function to check if a command exists
function Test-Command {
    param($command)
    $null = Get-Command $command -ErrorAction SilentlyContinue
    return $?
}

# Check prerequisites
Write-Host "Step 1: Checking Prerequisites..." -ForegroundColor Yellow
Write-Host ""

$goInstalled = Test-Command "go"
$flutterInstalled = Test-Command "flutter"
$mysqlInstalled = Test-Command "mysql"

Write-Host "Go installed: " -NoNewline
if ($goInstalled) { Write-Host "YES [OK]" -ForegroundColor Green } else { Write-Host "NO [X]" -ForegroundColor Red }

Write-Host "Flutter installed: " -NoNewline
if ($flutterInstalled) { Write-Host "YES [OK]" -ForegroundColor Green } else { Write-Host "NO [X]" -ForegroundColor Red }

Write-Host "MySQL installed: " -NoNewline
if ($mysqlInstalled) { Write-Host "YES [OK]" -ForegroundColor Green } else { Write-Host "NO [X]" -ForegroundColor Red }

Write-Host ""

# Install Go dependencies
if ($goInstalled) {
    Write-Host "Step 2: Installing Go Dependencies..." -ForegroundColor Yellow
    Set-Location "$projectRoot\pgworld-api-master"
    
    Write-Host "  - Downloading Go modules..." -NoNewline
    go mod download 2>&1 | Out-Null
    if ($?) { Write-Host " Done [OK]" -ForegroundColor Green } else { Write-Host " Failed [X]" -ForegroundColor Red }
    
    Write-Host "  - Tidying Go modules..." -NoNewline
    go mod tidy 2>&1 | Out-Null
    if ($?) { Write-Host " Done [OK]" -ForegroundColor Green } else { Write-Host " Failed [X]" -ForegroundColor Red }
    
    Write-Host ""
} else {
    Write-Host "Step 2: Skipped (Go not installed)" -ForegroundColor Red
    Write-Host ""
}

# Setup .env file
Write-Host "Step 3: Creating .env Configuration..." -ForegroundColor Yellow
Set-Location "$projectRoot\pgworld-api-master"

$envPath = ".env"
if (Test-Path $envPath) {
    Write-Host "  - .env file already exists" -ForegroundColor Yellow
} else {
    Write-Host "  - Creating .env file..." -NoNewline
    $envContent = @"
dbConfig=root:root@tcp(localhost:3306)/pgworld_db
connectionPool=10
baseURL=http://localhost:8080
supportEmailID=your_email@gmail.com
supportEmailPassword=your_app_password
supportEmailHost=smtp.gmail.com
supportEmailPort=587
s3Bucket=pgworld-uploads
test=false
migrate=false
"@
    $envContent | Out-File -FilePath $envPath -Encoding UTF8 -NoNewline
    if ($?) { Write-Host " Done [OK]" -ForegroundColor Green } else { Write-Host " Failed [X]" -ForegroundColor Red }
}
Write-Host ""

# Create uploads directory
Write-Host "Step 4: Creating Uploads Directory..." -ForegroundColor Yellow
$uploadsPath = "$projectRoot\pgworld-api-master\uploads"
if (Test-Path $uploadsPath) {
    Write-Host "  - Uploads directory already exists" -ForegroundColor Yellow
} else {
    Write-Host "  - Creating uploads directory..." -NoNewline
    New-Item -ItemType Directory -Path $uploadsPath -Force | Out-Null
    if ($?) { Write-Host " Done [OK]" -ForegroundColor Green } else { Write-Host " Failed [X]" -ForegroundColor Red }
}
Write-Host ""

# Build Go API
if ($goInstalled) {
    Write-Host "Step 5: Building Go API..." -ForegroundColor Yellow
    Set-Location "$projectRoot\pgworld-api-master"
    
    Write-Host "  - Building main.exe..." -NoNewline
    go build -o main.exe . 2>&1 | Out-Null
    if ($?) { 
        Write-Host " Done [OK]" -ForegroundColor Green 
        Write-Host "  - API executable created: main.exe" -ForegroundColor Green
    } else { 
        Write-Host " Failed [X]" -ForegroundColor Red 
    }
    Write-Host ""
} else {
    Write-Host "Step 5: Skipped (Go not installed)" -ForegroundColor Red
    Write-Host ""
}

# Flutter Admin App
if ($flutterInstalled) {
    Write-Host "Step 6: Setting up Flutter Admin App..." -ForegroundColor Yellow
    Set-Location "$projectRoot\pgworld-master"
    
    Write-Host "  - Cleaning Flutter cache..." -NoNewline
    flutter clean 2>&1 | Out-Null
    if ($?) { Write-Host " Done [OK]" -ForegroundColor Green } else { Write-Host " Failed [X]" -ForegroundColor Red }
    
    Write-Host "  - Getting Flutter dependencies..." -NoNewline
    flutter pub get 2>&1 | Out-Null
    if ($?) { Write-Host " Done [OK]" -ForegroundColor Green } else { Write-Host " Failed [X]" -ForegroundColor Red }
    
    Write-Host ""
} else {
    Write-Host "Step 6: Skipped (Flutter not installed)" -ForegroundColor Red
    Write-Host ""
}

# Flutter Tenant App
if ($flutterInstalled) {
    Write-Host "Step 7: Setting up Flutter Tenant App..." -ForegroundColor Yellow
    Set-Location "$projectRoot\pgworldtenant-master"
    
    Write-Host "  - Cleaning Flutter cache..." -NoNewline
    flutter clean 2>&1 | Out-Null
    if ($?) { Write-Host " Done [OK]" -ForegroundColor Green } else { Write-Host " Failed [X]" -ForegroundColor Red }
    
    Write-Host "  - Getting Flutter dependencies..." -NoNewline
    flutter pub get 2>&1 | Out-Null
    if ($?) { Write-Host " Done [OK]" -ForegroundColor Green } else { Write-Host " Failed [X]" -ForegroundColor Red }
    
    Write-Host ""
} else {
    Write-Host "Step 7: Skipped (Flutter not installed)" -ForegroundColor Red
    Write-Host ""
}

# Summary
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Setup Summary" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

if ($goInstalled) {
    Write-Host "[OK] Go API: Ready" -ForegroundColor Green
    Write-Host "  Run with: cd pgworld-api-master; .\main.exe" -ForegroundColor Gray
} else {
    Write-Host "[X] Go API: Not Ready (Go not installed)" -ForegroundColor Red
    Write-Host "  Install Go from: https://go.dev/dl/" -ForegroundColor Gray
}
Write-Host ""

if ($flutterInstalled) {
    Write-Host "[OK] Flutter Apps: Ready" -ForegroundColor Green
    Write-Host "  Admin App: cd pgworld-master; flutter run" -ForegroundColor Gray
    Write-Host "  Tenant App: cd pgworldtenant-master; flutter run" -ForegroundColor Gray
} else {
    Write-Host "[X] Flutter Apps: Not Ready (Flutter not installed)" -ForegroundColor Red
    Write-Host "  Install Flutter from: https://docs.flutter.dev/get-started/install" -ForegroundColor Gray
}
Write-Host ""

if ($mysqlInstalled) {
    Write-Host "[OK] MySQL: Installed" -ForegroundColor Green
    Write-Host "  Setup database: Get-Content pgworld-api-master\setup-database.sql | mysql -u root -p" -ForegroundColor Gray
} else {
    Write-Host "[X] MySQL: Not Installed" -ForegroundColor Red
    Write-Host "  Install MySQL from: https://dev.mysql.com/downloads/installer/" -ForegroundColor Gray
}
Write-Host ""

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Install missing software (if any)" -ForegroundColor White
Write-Host "2. Setup MySQL database (see COMPLETE_SETUP_AND_RUN.md)" -ForegroundColor White
Write-Host "3. Start API: cd pgworld-api-master; .\main.exe" -ForegroundColor White
Write-Host "4. Start Apps: cd pgworld-master; flutter run" -ForegroundColor White
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

Set-Location $projectRoot

