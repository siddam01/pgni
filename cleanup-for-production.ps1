# PG World - Production Cleanup Script
# This script prepares your code for production deployment

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  PG World - Production Cleanup" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$rootDir = $PSScriptRoot

# Function to safely delete file/folder
function Safe-Delete {
    param($path, $description)
    if (Test-Path $path) {
        Remove-Item $path -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "✓ Deleted: $description" -ForegroundColor Green
    } else {
        Write-Host "○ Not found: $description" -ForegroundColor Gray
    }
}

Write-Host "Step 1: Cleaning up development files..." -ForegroundColor Yellow
Write-Host ""

# API Directory - Development files
Safe-Delete "$rootDir\pgworld-api-master\main_demo.go.bak" "Demo backup file"
Safe-Delete "$rootDir\pgworld-api-master\main_local.go.backup" "Local backup file"
Safe-Delete "$rootDir\pgworld-api-master\main_demo.exe" "Demo executable"
Safe-Delete "$rootDir\pgworld-api-master\main_local_old.go" "Old local file"
Safe-Delete "$rootDir\pgworld-api-master\main_demo_old.go" "Old demo file"
Safe-Delete "$rootDir\pgworld-api-master\bin" "Build artifacts directory"

Write-Host ""
Write-Host "Step 2: Cleaning up local scripts..." -ForegroundColor Yellow
Write-Host ""

# Keep only essential scripts
Safe-Delete "$rootDir\setup-complete.ps1" "Setup script"
Safe-Delete "$rootDir\RUN_API_NOW.ps1" "Run script"

Write-Host ""
Write-Host "Step 3: Checking .gitignore..." -ForegroundColor Yellow
Write-Host ""

$gitignorePath = "$rootDir\pgworld-api-master\.gitignore"
$gitignoreContent = @"
# Environment files
.env
.env.production
.env.local
.env.*.local

# Build artifacts
*.exe
bin/
builds/
dist/

# Uploads and logs
uploads/
*.log
logs/

# Backup files
*.bak
*.backup
*_old.go
*_demo.go

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db
desktop.ini

# Go specific
vendor/
*.test
*.out
coverage.txt

# Temporary files
tmp/
temp/
"@

if (Test-Path $gitignorePath) {
    Write-Host "○ .gitignore already exists" -ForegroundColor Gray
    Write-Host "  (Review manually to ensure all patterns are included)" -ForegroundColor Gray
} else {
    Set-Content -Path $gitignorePath -Value $gitignoreContent
    Write-Host "✓ Created .gitignore" -ForegroundColor Green
}

Write-Host ""
Write-Host "Step 4: Generating production environment template..." -ForegroundColor Yellow
Write-Host ""

$envProductionPath = "$rootDir\pgworld-api-master\.env.production.template"
$envProductionContent = @"
# PG World - Production Environment Configuration
# Copy this to .env.production and fill in with real values
# NEVER commit .env.production to Git!

# ========================================
# DATABASE CONFIGURATION
# ========================================
# AWS RDS format:
# dbConfig=admin:SECURE_PASSWORD@tcp(pgworld-db.abc123.us-east-1.rds.amazonaws.com:3306)/pgworld_db

# Azure MySQL format:
# dbConfig=pgworldadmin@pgworldserver:SECURE_PASSWORD@tcp(pgworldserver.mysql.database.azure.com:3306)/pgworld_db?tls=true

dbConfig=USERNAME:PASSWORD@tcp(CLOUD_DB_HOST:3306)/pgworld_db
connectionPool=20

# ========================================
# API CONFIGURATION
# ========================================
baseURL=https://api.pgworld.com
test=false
migrate=false

# ========================================
# EMAIL CONFIGURATION
# ========================================
supportEmailID=support@pgworld.com
supportEmailPassword=YOUR_APP_PASSWORD
supportEmailHost=smtp.gmail.com
supportEmailPort=587

# ========================================
# API KEYS (GENERATE NEW ONES!)
# ========================================
# Generate using: -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 32 | ForEach-Object {[char]$_})
ANDROID_LIVE_KEY=GENERATE_32_CHAR_RANDOM_STRING
ANDROID_TEST_KEY=GENERATE_32_CHAR_RANDOM_STRING
IOS_LIVE_KEY=GENERATE_32_CHAR_RANDOM_STRING
IOS_TEST_KEY=GENERATE_32_CHAR_RANDOM_STRING

# ========================================
# PAYMENT GATEWAY (RAZORPAY)
# ========================================
RAZORPAY_KEY_ID=YOUR_PRODUCTION_RAZORPAY_KEY_ID
RAZORPAY_KEY_SECRET=YOUR_PRODUCTION_RAZORPAY_SECRET

# ========================================
# STORAGE CONFIGURATION
# ========================================
# AWS S3
s3Bucket=pgworld-production-uploads
AWS_ACCESS_KEY_ID=YOUR_AWS_ACCESS_KEY
AWS_SECRET_ACCESS_KEY=YOUR_AWS_SECRET_KEY
AWS_REGION=us-east-1

# OR Azure Blob Storage (uncomment if using Azure)
# AZURE_STORAGE_ACCOUNT=pgworldstorage
# AZURE_STORAGE_KEY=YOUR_AZURE_STORAGE_KEY
# AZURE_STORAGE_CONTAINER=uploads
"@

Set-Content -Path $envProductionPath -Value $envProductionContent
Write-Host "✓ Created .env.production.template" -ForegroundColor Green
Write-Host "  (Copy this to .env.production and fill in real values)" -ForegroundColor Gray

Write-Host ""
Write-Host "Step 5: Generating secure API keys..." -ForegroundColor Yellow
Write-Host ""

Write-Host "Generated API Keys (use these in production):" -ForegroundColor Cyan
Write-Host ""

$androidLiveKey = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 32 | ForEach-Object {[char]$_})
$androidTestKey = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 32 | ForEach-Object {[char]$_})
$iOSLiveKey = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 32 | ForEach-Object {[char]$_})
$iOSTestKey = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 32 | ForEach-Object {[char]$_})

Write-Host "ANDROID_LIVE_KEY=$androidLiveKey" -ForegroundColor White
Write-Host "ANDROID_TEST_KEY=$androidTestKey" -ForegroundColor White
Write-Host "IOS_LIVE_KEY=$iOSLiveKey" -ForegroundColor White
Write-Host "IOS_TEST_KEY=$iOSTestKey" -ForegroundColor White

# Save to file
$keysPath = "$rootDir\PRODUCTION_API_KEYS.txt"
$keysContent = @"
PG World - Production API Keys
Generated: $(Get-Date)

IMPORTANT: 
- Store these securely
- Add to .env.production
- Delete this file after copying
- NEVER commit to Git!

ANDROID_LIVE_KEY=$androidLiveKey
ANDROID_TEST_KEY=$androidTestKey
IOS_LIVE_KEY=$iOSLiveKey
IOS_TEST_KEY=$iOSTestKey
"@

Set-Content -Path $keysPath -Value $keysContent
Write-Host ""
Write-Host "✓ Saved to PRODUCTION_API_KEYS.txt" -ForegroundColor Green
Write-Host "  (Copy these to .env.production, then DELETE this file)" -ForegroundColor Yellow

Write-Host ""
Write-Host "Step 6: Verifying code security..." -ForegroundColor Yellow
Write-Host ""

# Check for hardcoded secrets in Go files
$goFiles = Get-ChildItem "$rootDir\pgworld-api-master\*.go" -Recurse
$foundIssues = $false

foreach ($file in $goFiles) {
    $content = Get-Content $file.FullName -Raw
    
    # Check for old hardcoded keys (should only be in default values)
    if ($content -match 'T9h9P6j2N6y9M3Q8' -and $file.Name -ne 'config.go') {
        Write-Host "⚠ Warning: Old key found in $($file.Name)" -ForegroundColor Yellow
        $foundIssues = $true
    }
    
    # Check for localhost hardcoding
    if ($content -match 'localhost:3306' -and $file.Name -notmatch 'config|env') {
        Write-Host "⚠ Warning: Localhost reference in $($file.Name)" -ForegroundColor Yellow
        $foundIssues = $true
    }
}

if (-not $foundIssues) {
    Write-Host "✓ No security issues found in code" -ForegroundColor Green
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Cleanup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Copy .env.production.template to .env.production" -ForegroundColor White
Write-Host "2. Fill in .env.production with real values" -ForegroundColor White
Write-Host "3. Use generated API keys from PRODUCTION_API_KEYS.txt" -ForegroundColor White
Write-Host "4. Delete PRODUCTION_API_KEYS.txt after copying keys" -ForegroundColor White
Write-Host "5. Choose deployment platform (Railway/AWS/Azure)" -ForegroundColor White
Write-Host "6. Follow deployment guide in PRE_DEPLOYMENT_CHECKLIST.md" -ForegroundColor White
Write-Host ""

Write-Host "Platform Recommendations:" -ForegroundColor Cyan
Write-Host "  • Railway: $10/month, 30 min setup (Easiest)" -ForegroundColor White
Write-Host "  • AWS: $30/month, 2 hour setup (Cheapest at scale)" -ForegroundColor White
Write-Host "  • Azure: $49/month, 2 hour setup (Enterprise)" -ForegroundColor White
Write-Host ""

Write-Host "Ready to deploy! 🚀" -ForegroundColor Green
Write-Host ""

