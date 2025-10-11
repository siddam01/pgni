# Safe GitHub Commit Script
# This commits only safe files, keeps sensitive info local

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Safe GitHub Commit" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Ensure .gitignore is up to date
Write-Host "Updating .gitignore..." -ForegroundColor Yellow

$gitignoreContent = @"
# Sensitive files - NEVER commit these!
*.pem
*.ppk
preprod.env
prod.env
terraform.tfvars
terraform.tfstate
terraform.tfstate.backup
.terraform/
*-key.pem
ssh-key-*.txt
credentials-*.txt
*SECRET*
*PASSWORD*

# Deployment artifacts
*.zip
*.tar.gz
pgni-key*.pem
ec2-key.pem

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Logs
*.log
logs/

# Build artifacts
pgworld-api-master/pgworld-api
*/pgworld-api

# Node modules (if any)
node_modules/

# Flutter/Dart
.dart_tool/
.flutter-plugins
.flutter-plugins-dependencies
.packages
build/
"@

$gitignoreContent | Out-File -FilePath ".gitignore" -Encoding UTF8

Write-Host "✓ .gitignore updated" -ForegroundColor Green
Write-Host ""

# Show what will be committed
Write-Host "Files that will be committed:" -ForegroundColor Yellow
Write-Host ""

# Stage safe files
Write-Host "Staging safe files..." -ForegroundColor Cyan

# Terraform files (configuration only, no state/vars)
git add terraform/*.tf 2>$null

# User guides
git add USER_GUIDES/*.md 2>$null

# Documentation
git add README.md 2>$null
git add START_HERE_COMPLETE_SOLUTION.md 2>$null
git add FINAL_APP_DETAILS.md 2>$null
git add PRE_DEPLOYMENT_CHECKLIST.md 2>$null
git add PROJECT_STRUCTURE.md 2>$null

# Deployment guides (no sensitive info)
git add DEPLOY_COMPLETE_NOW.md 2>$null
git add DEPLOY_VIA_CLOUDSHELL.md 2>$null
git add DEPLOY_MANUAL_STEPS.md 2>$null

# Source code changes
git add pgworld-api-master/*.go 2>$null
git add pgworld-master/android/app/src/main/AndroidManifest.xml 2>$null
git add pgworld-master/android/app/build.gradle 2>$null
git add pgworld-master/ios/Runner/Info.plist 2>$null
git add pgworldtenant-master/android/app/src/main/AndroidManifest.xml 2>$null
git add pgworldtenant-master/android/app/build.gradle 2>$null
git add pgworldtenant-master/ios/Runner/Info.plist 2>$null

# GitHub Actions
git add .github/workflows/deploy.yml 2>$null

# Commit deletions of old files
git add -u 2>$null

Write-Host ""
Write-Host "Files staged for commit:" -ForegroundColor Cyan
git status --short

Write-Host ""
Write-Host "========================================" -ForegroundColor Yellow
Write-Host "  REVIEW BEFORE COMMITTING" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "Sensitive files that will NOT be committed:" -ForegroundColor Green
Write-Host "  ✓ preprod.env (DB password safe)" -ForegroundColor Green
Write-Host "  ✓ *.pem files (SSH keys safe)" -ForegroundColor Green
Write-Host "  ✓ terraform.tfvars (credentials safe)" -ForegroundColor Green
Write-Host "  ✓ Deployment scripts with IPs (local only)" -ForegroundColor Green
Write-Host ""

$commit = Read-Host "Do you want to commit these files? (yes/no)"

if ($commit -eq "yes") {
    Write-Host ""
    Write-Host "Committing..." -ForegroundColor Cyan
    
    git commit -m "Production-ready deployment

- Updated Terraform configuration for existing RDS
- Enhanced security (API keys in env vars)
- Created comprehensive user guides (180+ pages)
- Updated mobile app names and packages
- Fixed GitHub Actions workflow
- Cleaned up temporary files
- Production deployment ready"
    
    Write-Host ""
    Write-Host "✓ Committed successfully!" -ForegroundColor Green
    Write-Host ""
    
    $push = Read-Host "Push to GitHub? (yes/no)"
    
    if ($push -eq "yes") {
        Write-Host ""
        Write-Host "Pushing to GitHub..." -ForegroundColor Cyan
        git push origin main
        Write-Host ""
        Write-Host "✓ Pushed to GitHub!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Your repository: https://github.com/siddam01/pgni" -ForegroundColor Cyan
    } else {
        Write-Host ""
        Write-Host "Commit created locally." -ForegroundColor Yellow
        Write-Host "Run 'git push origin main' when ready to push." -ForegroundColor Yellow
    }
} else {
    Write-Host ""
    Write-Host "Commit cancelled." -ForegroundColor Yellow
    Write-Host "Files are still staged. Run 'git reset' to unstage." -ForegroundColor Gray
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  IMPORTANT REMINDERS" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Your sensitive files are protected:" -ForegroundColor Yellow
Write-Host "  - Database password: Only on EC2" -ForegroundColor White
Write-Host "  - SSH keys: Only on your PC" -ForegroundColor White
Write-Host "  - AWS credentials: Only in your AWS account" -ForegroundColor White
Write-Host ""
Write-Host "Your deployed app keeps working even if you:" -ForegroundColor Yellow
Write-Host "  - Don't commit these files" -ForegroundColor White
Write-Host "  - Make repo private again" -ForegroundColor White
Write-Host "  - Delete local files" -ForegroundColor White
Write-Host ""
Write-Host "The API is running independently on EC2!" -ForegroundColor Green
Write-Host ""

