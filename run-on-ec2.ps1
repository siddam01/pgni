# CloudPG - Run Deployment Script on EC2 from Windows
# This PowerShell script uploads and executes the deployment script on EC2

param(
    [string]$EC2Host = "54.227.101.30",
    [string]$EC2User = "ec2-user",
    [string]$KeyPath = "$env:USERPROFILE\.ssh\cloudpg-key.pem"  # Update this path
)

Write-Host "=========================================="  -ForegroundColor Cyan
Write-Host "CloudPG - EC2 Deployment Trigger"  -ForegroundColor Cyan
Write-Host "=========================================="  -ForegroundColor Cyan
Write-Host ""

# Check if SSH key exists
if (-not (Test-Path $KeyPath)) {
    Write-Host "ERROR: SSH key not found: $KeyPath" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please update the KeyPath in this script or specify it:" -ForegroundColor Yellow
    Write-Host "  .\run-on-ec2.ps1 -KeyPath 'C:\path\to\your\key.pem'" -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

# Check if script exists
$scriptPath = "validate-and-deploy-latest.sh"
if (-not (Test-Path $scriptPath)) {
    Write-Host "ERROR: Script not found: $scriptPath" -ForegroundColor Red
    Write-Host "Current directory: $(Get-Location)" -ForegroundColor Yellow
    exit 1
}

Write-Host "✓ Script found: $scriptPath" -ForegroundColor Green
Write-Host "✓ SSH key found: $KeyPath" -ForegroundColor Green
Write-Host ""

# Upload script to EC2
Write-Host "▶ Step 1: Uploading deployment script to EC2..." -ForegroundColor Blue
try {
    scp -i $KeyPath $scriptPath "${EC2User}@${EC2Host}:/tmp/validate-and-deploy-latest.sh"
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Script uploaded successfully" -ForegroundColor Green
    } else {
        throw "SCP failed with exit code $LASTEXITCODE"
    }
} catch {
    Write-Host "✗ Failed to upload script: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Troubleshooting:" -ForegroundColor Yellow
    Write-Host "  1. Check if EC2 host is correct: $EC2Host" -ForegroundColor Yellow
    Write-Host "  2. Check if SSH key has correct permissions" -ForegroundColor Yellow
    Write-Host "  3. Try manual connection: ssh -i $KeyPath ${EC2User}@${EC2Host}" -ForegroundColor Yellow
    exit 1
}

Write-Host ""

# Execute script on EC2
Write-Host "▶ Step 2: Executing deployment script on EC2..." -ForegroundColor Blue
Write-Host ""
Write-Host "=========================================="  -ForegroundColor Cyan

try {
    ssh -i $KeyPath "${EC2User}@${EC2Host}" "chmod +x /tmp/validate-and-deploy-latest.sh && /tmp/validate-and-deploy-latest.sh"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "=========================================="  -ForegroundColor Cyan
        Write-Host "✓ DEPLOYMENT COMPLETED SUCCESSFULLY" -ForegroundColor Green
        Write-Host "=========================================="  -ForegroundColor Cyan
        Write-Host ""
        Write-Host "📱 Access your applications:" -ForegroundColor Cyan
        Write-Host "   Admin:  http://${EC2Host}/admin/" -ForegroundColor White
        Write-Host "   Tenant: http://${EC2Host}/tenant/" -ForegroundColor White
        Write-Host ""
        Write-Host "💡 CRITICAL: Clear browser cache!" -ForegroundColor Yellow
        Write-Host "   1. Press Ctrl+Shift+Delete" -ForegroundColor White
        Write-Host "   2. Select 'All time'" -ForegroundColor White
        Write-Host "   3. Check 'Cached images and files'" -ForegroundColor White
        Write-Host "   4. Click 'Clear data'" -ForegroundColor White
        Write-Host ""
    } else {
        throw "Deployment script failed with exit code $LASTEXITCODE"
    }
} catch {
    Write-Host ""
    Write-Host "=========================================="  -ForegroundColor Cyan
    Write-Host "✗ DEPLOYMENT FAILED" -ForegroundColor Red
    Write-Host "=========================================="  -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Error: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "To debug, connect manually:" -ForegroundColor Yellow
    Write-Host "  ssh -i $KeyPath ${EC2User}@${EC2Host}" -ForegroundColor White
    Write-Host "  Then run: /tmp/validate-and-deploy-latest.sh" -ForegroundColor White
    exit 1
}

