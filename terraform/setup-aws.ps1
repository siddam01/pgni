# AWS Credentials Setup Helper
# This script helps you configure AWS credentials for PGNi deployment

Write-Host "🔐 AWS Credentials Setup for PGNi" -ForegroundColor Green
Write-Host "==================================" -ForegroundColor Green
Write-Host ""

Write-Host "ℹ️  You need AWS credentials to deploy the PGNi infrastructure." -ForegroundColor Cyan
Write-Host "   These credentials should have permissions to create:" -ForegroundColor White
Write-Host "   • EC2 instances and key pairs" -ForegroundColor White
Write-Host "   • IAM roles and policies" -ForegroundColor White
Write-Host "   • S3 buckets" -ForegroundColor White
Write-Host "   • Security groups" -ForegroundColor White
Write-Host "   • RDS access (database already exists)" -ForegroundColor White
Write-Host ""

Write-Host "📋 Please gather your AWS credentials:" -ForegroundColor Yellow
Write-Host "   1. AWS Access Key ID" -ForegroundColor White
Write-Host "   2. AWS Secret Access Key" -ForegroundColor White
Write-Host "   3. Region: us-east-1 (for this project)" -ForegroundColor White
Write-Host ""

$choice = Read-Host "Choose setup method: (1) Interactive setup (2) Manual instructions (1/2)"

if ($choice -eq "1") {
    Write-Host ""
    Write-Host "🚀 Starting interactive AWS configuration..." -ForegroundColor Green
    Write-Host "   Please enter your credentials when prompted." -ForegroundColor Yellow
    Write-Host ""
    
    # Run aws configure
    aws configure
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "✅ AWS credentials configured!" -ForegroundColor Green
        Write-Host "🔍 Testing connection..." -ForegroundColor Yellow
        
        try {
            $identity = aws sts get-caller-identity | ConvertFrom-Json
            Write-Host "✅ Connection successful!" -ForegroundColor Green
            Write-Host "   Account: $($identity.Account)" -ForegroundColor Cyan
            Write-Host "   User: $($identity.Arn)" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "🎉 You're ready to deploy! Run: .\deploy.ps1" -ForegroundColor Green
        } catch {
            Write-Host "❌ Connection test failed. Please check your credentials." -ForegroundColor Red
        }
    }
} else {
    Write-Host ""
    Write-Host "📝 Manual AWS Configuration Instructions:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "1. Run this command:" -ForegroundColor White
    Write-Host "   aws configure" -ForegroundColor Green
    Write-Host ""
    Write-Host "2. Enter the following when prompted:" -ForegroundColor White
    Write-Host "   AWS Access Key ID: [Your Access Key ID]" -ForegroundColor Cyan
    Write-Host "   AWS Secret Access Key: [Your Secret Access Key]" -ForegroundColor Cyan
    Write-Host "   Default region name: us-east-1" -ForegroundColor Cyan
    Write-Host "   Default output format: json" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "3. Test the connection:" -ForegroundColor White
    Write-Host "   aws sts get-caller-identity" -ForegroundColor Green
    Write-Host ""
    Write-Host "4. If successful, run the deployment script:" -ForegroundColor White
    Write-Host "   .\deploy.ps1" -ForegroundColor Green
    Write-Host ""
}

Write-Host "💡 Alternative methods:" -ForegroundColor Cyan
Write-Host ""
Write-Host "Environment Variables (temporary):" -ForegroundColor White
Write-Host "  `$env:AWS_ACCESS_KEY_ID='your-key-id'" -ForegroundColor Gray
Write-Host "  `$env:AWS_SECRET_ACCESS_KEY='your-secret-key'" -ForegroundColor Gray
Write-Host "  `$env:AWS_DEFAULT_REGION='us-east-1'" -ForegroundColor Gray
Write-Host ""
Write-Host "AWS SSO (if using AWS Organizations):" -ForegroundColor White
Write-Host "  aws configure sso" -ForegroundColor Gray
Write-Host ""

Write-Host "🔒 Security Note:" -ForegroundColor Red
Write-Host "   Keep your AWS credentials secure and never share them!" -ForegroundColor White