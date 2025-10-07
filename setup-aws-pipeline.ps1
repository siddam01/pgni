# PG World - AWS CI/CD Pipeline Setup Script
# This script helps you set up Pre-Production and Production environments

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  PG World - AWS Pipeline Setup" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$rootDir = $PSScriptRoot
$apiDir = Join-Path $rootDir "pgworld-api-master"

# Check if AWS CLI is installed
Write-Host "Step 1: Checking prerequisites..." -ForegroundColor Yellow
Write-Host ""

$awsInstalled = Get-Command aws -ErrorAction SilentlyContinue
if (-not $awsInstalled) {
    Write-Host "✗ AWS CLI not installed" -ForegroundColor Red
    Write-Host "  Install from: https://aws.amazon.com/cli/" -ForegroundColor Gray
    Write-Host "  Or run: winget install Amazon.AWSCLI" -ForegroundColor Gray
    exit 1
}
Write-Host "✓ AWS CLI installed" -ForegroundColor Green

# Check AWS credentials
try {
    $awsIdentity = aws sts get-caller-identity 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "✗ AWS credentials not configured" -ForegroundColor Red
        Write-Host "  Run: aws configure" -ForegroundColor Gray
        exit 1
    }
    Write-Host "✓ AWS credentials configured" -ForegroundColor Green
} catch {
    Write-Host "✗ AWS credentials error" -ForegroundColor Red
    exit 1
}

# Check if Git is installed
$gitInstalled = Get-Command git -ErrorAction SilentlyContinue
if (-not $gitInstalled) {
    Write-Host "✗ Git not installed" -ForegroundColor Red
    Write-Host "  Install from: https://git-scm.com/" -ForegroundColor Gray
    exit 1
}
Write-Host "✓ Git installed" -ForegroundColor Green

Write-Host ""
Write-Host "Step 2: Creating environment configuration files..." -ForegroundColor Yellow
Write-Host ""

# Create .env.development
$envDev = @"
# Development Environment
dbConfig=root:root@tcp(localhost:3306)/pgworld_db
connectionPool=10
baseURL=http://localhost:8080
test=true
migrate=false

supportEmailID=dev@pgworld.com
supportEmailPassword=dev_password
supportEmailHost=smtp.gmail.com
supportEmailPort=587

ANDROID_LIVE_KEY=DEV_KEY_12345
ANDROID_TEST_KEY=DEV_KEY_67890
IOS_LIVE_KEY=DEV_KEY_ABCDE
IOS_TEST_KEY=DEV_KEY_FGHIJ

RAZORPAY_KEY_ID=test_key
RAZORPAY_KEY_SECRET=test_secret

s3Bucket=pgworld-dev-uploads
AWS_REGION=us-east-1
"@

Set-Content -Path "$apiDir\.env.development" -Value $envDev
Write-Host "✓ Created .env.development" -ForegroundColor Green

# Create .env.preprod.template
$envPreprod = @"
# Pre-Production Environment
# Store actual values in AWS Systems Manager Parameter Store
dbConfig={{SSM:/pgworld/preprod/dbConfig}}
connectionPool=15
baseURL={{SSM:/pgworld/preprod/baseURL}}
test=false
migrate=false

supportEmailID={{SSM:/pgworld/preprod/supportEmailID}}
supportEmailPassword={{SSM:/pgworld/preprod/supportEmailPassword}}
supportEmailHost=smtp.gmail.com
supportEmailPort=587

ANDROID_LIVE_KEY={{SSM:/pgworld/preprod/androidLiveKey}}
ANDROID_TEST_KEY={{SSM:/pgworld/preprod/androidTestKey}}
IOS_LIVE_KEY={{SSM:/pgworld/preprod/iOSLiveKey}}
IOS_TEST_KEY={{SSM:/pgworld/preprod/iOSTestKey}}

RAZORPAY_KEY_ID={{SSM:/pgworld/preprod/razorpayKeyID}}
RAZORPAY_KEY_SECRET={{SSM:/pgworld/preprod/razorpayKeySecret}}

s3Bucket={{SSM:/pgworld/preprod/s3Bucket}}
AWS_REGION=us-east-1
"@

Set-Content -Path "$apiDir\.env.preprod.template" -Value $envPreprod
Write-Host "✓ Created .env.preprod.template" -ForegroundColor Green

# Create .env.production.template
$envProd = @"
# Production Environment
# Store actual values in AWS Systems Manager Parameter Store
dbConfig={{SSM:/pgworld/production/dbConfig}}
connectionPool=20
baseURL={{SSM:/pgworld/production/baseURL}}
test=false
migrate=false

supportEmailID={{SSM:/pgworld/production/supportEmailID}}
supportEmailPassword={{SSM:/pgworld/production/supportEmailPassword}}
supportEmailHost=smtp.gmail.com
supportEmailPort=587

ANDROID_LIVE_KEY={{SSM:/pgworld/production/androidLiveKey}}
ANDROID_TEST_KEY={{SSM:/pgworld/production/androidTestKey}}
IOS_LIVE_KEY={{SSM:/pgworld/production/iOSLiveKey}}
IOS_TEST_KEY={{SSM:/pgworld/production/iOSTestKey}}

RAZORPAY_KEY_ID={{SSM:/pgworld/production/razorpayKeyID}}
RAZORPAY_KEY_SECRET={{SSM:/pgworld/production/razorpayKeySecret}}

s3Bucket={{SSM:/pgworld/production/s3Bucket}}
AWS_REGION=us-east-1
"@

Set-Content -Path "$apiDir\.env.production.template" -Value $envProd
Write-Host "✓ Created .env.production.template" -ForegroundColor Green

Write-Host ""
Write-Host "Step 3: Creating buildspec.yml for AWS CodeBuild..." -ForegroundColor Yellow
Write-Host ""

$buildspec = @"
version: 0.2

env:
  parameter-store:
    DB_CONFIG: "/pgworld/`${ENVIRONMENT}/dbConfig"
    BASE_URL: "/pgworld/`${ENVIRONMENT}/baseURL"
    SUPPORT_EMAIL_ID: "/pgworld/`${ENVIRONMENT}/supportEmailID"
    SUPPORT_EMAIL_PASSWORD: "/pgworld/`${ENVIRONMENT}/supportEmailPassword"
    ANDROID_LIVE_KEY: "/pgworld/`${ENVIRONMENT}/androidLiveKey"
    ANDROID_TEST_KEY: "/pgworld/`${ENVIRONMENT}/androidTestKey"
    IOS_LIVE_KEY: "/pgworld/`${ENVIRONMENT}/iOSLiveKey"
    IOS_TEST_KEY: "/pgworld/`${ENVIRONMENT}/iOSTestKey"
    RAZORPAY_KEY_ID: "/pgworld/`${ENVIRONMENT}/razorpayKeyID"
    RAZORPAY_KEY_SECRET: "/pgworld/`${ENVIRONMENT}/razorpayKeySecret"
    S3_BUCKET: "/pgworld/`${ENVIRONMENT}/s3Bucket"

phases:
  install:
    runtime-versions:
      golang: 1.21
    commands:
      - echo "Installing dependencies..."
      - cd pgworld-api-master
      
  pre_build:
    commands:
      - echo "Running pre-build checks..."
      - echo "Environment: `$ENVIRONMENT"
      - go version
      - go mod download
      
  build:
    commands:
      - echo "Building application..."
      - CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o pgworld-api .
      - echo "Build completed successfully"
      
  post_build:
    commands:
      - echo "Creating deployment package..."
      - echo "Build completed on `$(date)"

artifacts:
  files:
    - pgworld-api-master/pgworld-api
    - pgworld-api-master/setup-database.sql
    - pgworld-api-master/migrations/**/*
  name: pgworld-api-`$(date +%Y%m%d-%H%M%S)

cache:
  paths:
    - '/go/pkg/mod/**/*'
"@

Set-Content -Path "$apiDir\buildspec.yml" -Value $buildspec
Write-Host "✓ Created buildspec.yml" -ForegroundColor Green

Write-Host ""
Write-Host "Step 4: Creating appspec.yml for AWS CodeDeploy..." -ForegroundColor Yellow
Write-Host ""

$appspec = @"
version: 0.0
os: linux
files:
  - source: pgworld-api-master/pgworld-api
    destination: /opt/pgworld
  - source: pgworld-api-master/setup-database.sql
    destination: /opt/pgworld
  - source: pgworld-api-master/migrations
    destination: /opt/pgworld/migrations

hooks:
  ApplicationStop:
    - location: scripts/stop_server.sh
      timeout: 30
      runas: ec2-user
      
  BeforeInstall:
    - location: scripts/before_install.sh
      timeout: 60
      runas: ec2-user
      
  AfterInstall:
    - location: scripts/after_install.sh
      timeout: 60
      runas: ec2-user
      
  ApplicationStart:
    - location: scripts/start_server.sh
      timeout: 30
      runas: ec2-user
      
  ValidateService:
    - location: scripts/validate_service.sh
      timeout: 60
      runas: ec2-user
"@

Set-Content -Path "$apiDir\appspec.yml" -Value $appspec
Write-Host "✓ Created appspec.yml" -ForegroundColor Green

Write-Host ""
Write-Host "Step 5: Creating deployment scripts..." -ForegroundColor Yellow
Write-Host ""

# Create scripts directory
$scriptsDir = Join-Path $apiDir "scripts"
New-Item -ItemType Directory -Path $scriptsDir -Force | Out-Null

# stop_server.sh
$stopServer = @"
#!/bin/bash
echo "Stopping PG World API..."
sudo systemctl stop pgworld-api || true
"@
Set-Content -Path "$scriptsDir\stop_server.sh" -Value $stopServer
Write-Host "✓ Created scripts/stop_server.sh" -ForegroundColor Green

# before_install.sh
$beforeInstall = @"
#!/bin/bash
echo "Preparing for installation..."

# Backup current version
if [ -f /opt/pgworld/pgworld-api ]; then
    echo "Backing up current version..."
    sudo cp /opt/pgworld/pgworld-api /opt/pgworld/pgworld-api.backup.`$(date +%Y%m%d-%H%M%S)
fi

# Clean old backups (keep last 5)
cd /opt/pgworld
ls -t pgworld-api.backup.* 2>/dev/null | tail -n +6 | xargs -r rm --
"@
Set-Content -Path "$scriptsDir\before_install.sh" -Value $beforeInstall
Write-Host "✓ Created scripts/before_install.sh" -ForegroundColor Green

# after_install.sh
$afterInstall = @"
#!/bin/bash
echo "Configuring application..."

# Make binary executable
sudo chmod +x /opt/pgworld/pgworld-api

# Load environment variables from AWS Systems Manager
echo "Loading configuration from Parameter Store..."
ENVIRONMENT=`${ENVIRONMENT:-preprod}

aws ssm get-parameters-by-path \
    --path "/pgworld/`$ENVIRONMENT/" \
    --with-decryption \
    --region us-east-1 \
    --query "Parameters[*].[Name,Value]" \
    --output text | while read name value; do
    param_name=`$(echo `$name | awk -F'/' '{print `$NF}')
    echo "`$param_name=`$value" >> /tmp/pgworld.env
done

sudo mv /tmp/pgworld.env /opt/pgworld/.env
sudo chown ec2-user:ec2-user /opt/pgworld/.env
"@
Set-Content -Path "$scriptsDir\after_install.sh" -Value $afterInstall
Write-Host "✓ Created scripts/after_install.sh" -ForegroundColor Green

# start_server.sh
$startServer = @"
#!/bin/bash
echo "Starting PG World API..."
sudo systemctl start pgworld-api
sudo systemctl enable pgworld-api
"@
Set-Content -Path "$scriptsDir\start_server.sh" -Value $startServer
Write-Host "✓ Created scripts/start_server.sh" -ForegroundColor Green

# validate_service.sh
$validateService = @"
#!/bin/bash
echo "Validating service..."

# Wait for service to start
sleep 5

# Check if service is running
if sudo systemctl is-active --quiet pgworld-api; then
    echo "✓ Service is running"
    
    # Check if API responds
    response=`$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/)
    if [ "`$response" = "200" ]; then
        echo "✓ API is responding"
        exit 0
    else
        echo "✗ API is not responding (HTTP `$response)"
        exit 1
    fi
else
    echo "✗ Service is not running"
    sudo systemctl status pgworld-api
    exit 1
fi
"@
Set-Content -Path "$scriptsDir\validate_service.sh" -Value $validateService
Write-Host "✓ Created scripts/validate_service.sh" -ForegroundColor Green

Write-Host ""
Write-Host "Step 6: Updating .gitignore..." -ForegroundColor Yellow
Write-Host ""

$gitignoreContent = @"
# Environment files
.env
.env.local
.env.development
.env.preprod
.env.production

# Keep templates
!.env.*.template

# Build artifacts
pgworld-api
*.exe
bin/
builds/

# Uploads
uploads/
*.log

# Backup files
*.bak
*.backup
*_old.go

# IDE
.vscode/
.idea/

# OS
.DS_Store
Thumbs.db
"@

$gitignorePath = Join-Path $apiDir ".gitignore"
Set-Content -Path $gitignorePath -Value $gitignoreContent
Write-Host "✓ Updated .gitignore" -ForegroundColor Green

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Setup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Files Created:" -ForegroundColor Yellow
Write-Host "  ✓ .env.development" -ForegroundColor Green
Write-Host "  ✓ .env.preprod.template" -ForegroundColor Green
Write-Host "  ✓ .env.production.template" -ForegroundColor Green
Write-Host "  ✓ buildspec.yml" -ForegroundColor Green
Write-Host "  ✓ appspec.yml" -ForegroundColor Green
Write-Host "  ✓ scripts/stop_server.sh" -ForegroundColor Green
Write-Host "  ✓ scripts/before_install.sh" -ForegroundColor Green
Write-Host "  ✓ scripts/after_install.sh" -ForegroundColor Green
Write-Host "  ✓ scripts/start_server.sh" -ForegroundColor Green
Write-Host "  ✓ scripts/validate_service.sh" -ForegroundColor Green
Write-Host "  ✓ .gitignore" -ForegroundColor Green
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Next Steps:" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Commit files to Git:" -ForegroundColor White
Write-Host "   cd pgworld-api-master" -ForegroundColor Gray
Write-Host "   git add ." -ForegroundColor Gray
Write-Host "   git commit -m 'Add CI/CD pipeline configuration'" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Create GitHub repository and push code" -ForegroundColor White
Write-Host ""
Write-Host "3. Set up AWS infrastructure:" -ForegroundColor White
Write-Host "   - Create RDS databases (preprod & production)" -ForegroundColor Gray
Write-Host "   - Create S3 buckets (preprod & production)" -ForegroundColor Gray
Write-Host "   - Create EC2 instances (preprod & production)" -ForegroundColor Gray
Write-Host "   - Store secrets in Parameter Store" -ForegroundColor Gray
Write-Host ""
Write-Host "4. Create CI/CD pipeline:" -ForegroundColor White
Write-Host "   - Create CodeBuild projects" -ForegroundColor Gray
Write-Host "   - Create CodeDeploy applications" -ForegroundColor Gray
Write-Host "   - Create CodePipeline pipelines" -ForegroundColor Gray
Write-Host ""
Write-Host "5. Read complete guide:" -ForegroundColor White
Write-Host "   AWS_PIPELINE_SETUP.md" -ForegroundColor Gray
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Would you like to use:" -ForegroundColor Cyan
Write-Host "  A) AWS CodePipeline (AWS-native)" -ForegroundColor White
Write-Host "  B) GitHub Actions (easier setup)" -ForegroundColor White
Write-Host ""
Write-Host "Let me know and I'll create the configuration!" -ForegroundColor Yellow
Write-Host ""

