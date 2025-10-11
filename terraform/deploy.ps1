# AWS + Terraform Deployment Script for PGNi
# This script automates the deployment process

Write-Host "🚀 PGNi Infrastructure Deployment Script" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
Write-Host ""

# Check prerequisites
Write-Host "🔍 Checking prerequisites..." -ForegroundColor Yellow

# Check Terraform
try {
    $terraformVersion = terraform --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Terraform installed: $($terraformVersion.Split("`n")[0])" -ForegroundColor Green
    }
    else {
        throw "Terraform not found"
    }
}
catch {
    Write-Host "❌ Terraform not installed. Please run: winget install HashiCorp.Terraform" -ForegroundColor Red
    exit 1
}

# Check AWS CLI
try {
    $awsVersion = aws --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ AWS CLI installed: $awsVersion" -ForegroundColor Green
    }
    else {
        throw "AWS CLI not found"
    }
}
catch {
    Write-Host "❌ AWS CLI not installed. Please install AWS CLI first." -ForegroundColor Red
    exit 1
}

# Check AWS credentials
Write-Host "🔐 Checking AWS credentials..." -ForegroundColor Yellow
try {
    $awsIdentity = aws sts get-caller-identity 2>$null | ConvertFrom-Json
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ AWS credentials configured" -ForegroundColor Green
        Write-Host "   Account: $($awsIdentity.Account)" -ForegroundColor Cyan
        Write-Host "   User: $($awsIdentity.Arn)" -ForegroundColor Cyan
    }
    else {
        throw "AWS credentials not configured"
    }
}
catch {
    Write-Host "❌ AWS credentials not configured" -ForegroundColor Red
    Write-Host "   Please run: aws configure" -ForegroundColor Yellow
    Write-Host "   Then provide your AWS Access Key ID and Secret Access Key" -ForegroundColor Yellow
    exit 1
}

# Verify we're in the right directory
if (!(Test-Path "main.tf")) {
    Write-Host "❌ main.tf not found. Please run this script from the terraform directory." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "🏗️  Infrastructure Overview:" -ForegroundColor Cyan
Write-Host "  • EC2 Instance (t3.micro for preprod)" -ForegroundColor White
Write-Host "  • RDS Database (existing: database-pgni.cezawkgguojl.us-east-1.rds.amazonaws.com)" -ForegroundColor White
Write-Host "  • S3 Buckets for storage" -ForegroundColor White
Write-Host "  • Security Groups" -ForegroundColor White
Write-Host "  • IAM Roles" -ForegroundColor White
Write-Host ""

# Ask for confirmation
$confirmation = Read-Host "Do you want to proceed with the deployment? (y/N)"
if ($confirmation -ne 'y' -and $confirmation -ne 'Y') {
    Write-Host "Deployment cancelled." -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "🚀 Starting Terraform deployment..." -ForegroundColor Green

# Initialize Terraform
Write-Host "📦 Initializing Terraform..." -ForegroundColor Yellow
terraform init
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Terraform initialization failed!" -ForegroundColor Red
    exit 1
}

# Validate configuration
Write-Host "✅ Validating Terraform configuration..." -ForegroundColor Yellow
terraform validate
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Terraform validation failed!" -ForegroundColor Red
    exit 1
}

# Plan deployment
Write-Host "📋 Creating deployment plan..." -ForegroundColor Yellow
terraform plan -out=tfplan
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Terraform planning failed!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "📋 Deployment plan created successfully!" -ForegroundColor Green
Write-Host "Review the plan above and confirm if you want to apply these changes." -ForegroundColor Yellow
Write-Host ""

$applyConfirmation = Read-Host "Apply the infrastructure changes? (y/N)"
if ($applyConfirmation -ne 'y' -and $applyConfirmation -ne 'Y') {
    Write-Host "Deployment cancelled. Plan file saved as 'tfplan'" -ForegroundColor Yellow
    exit 0
}

# Apply infrastructure
Write-Host ""
Write-Host "🚀 Applying infrastructure changes..." -ForegroundColor Green
terraform apply tfplan
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Terraform apply failed!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "🎉 Infrastructure deployment completed successfully!" -ForegroundColor Green
Write-Host ""

# Show outputs
Write-Host "📊 Deployment outputs:" -ForegroundColor Cyan
terraform output

Write-Host ""
Write-Host "✅ Next steps:" -ForegroundColor Green
Write-Host "1. Note the EC2 instance public IP from the outputs above" -ForegroundColor White
Write-Host "2. Use the generated SSH key to connect to the instance" -ForegroundColor White
Write-Host "3. Deploy your application to the EC2 instance" -ForegroundColor White
Write-Host "4. Configure the application to use the RDS database" -ForegroundColor White
Write-Host ""
Write-Host "🔗 Useful commands:" -ForegroundColor Cyan
Write-Host "  • View current state: terraform show" -ForegroundColor White
Write-Host "  • List resources: terraform state list" -ForegroundColor White
Write-Host "  • Destroy infrastructure: terraform destroy" -ForegroundColor White