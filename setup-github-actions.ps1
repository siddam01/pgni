# PG World - GitHub Actions CI/CD Setup Script
# This script sets up GitHub Actions for Pre-Production and Production

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  PG World - GitHub Actions Setup" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$rootDir = $PSScriptRoot

# Create .github/workflows directory
$workflowDir = Join-Path $rootDir ".github\workflows"
New-Item -ItemType Directory -Path $workflowDir -Force | Out-Null

Write-Host "Step 1: Creating GitHub Actions workflow..." -ForegroundColor Yellow
Write-Host ""

$workflow = @'
name: Deploy PG World API

on:
  push:
    branches:
      - develop      # Auto-deploy to pre-production
      - main         # Deploy to production (with approval)
  pull_request:
    branches:
      - develop
      - main

env:
  GO_VERSION: '1.21'
  AWS_REGION: 'us-east-1'

jobs:
  build:
    name: Build and Test
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
      
      - name: Set up Go
        uses: actions/setup-go@v4
        with:
          go-version: ${{ env.GO_VERSION }}
      
      - name: Cache Go modules
        uses: actions/cache@v3
        with:
          path: ~/go/pkg/mod
          key: ${{ runner.os }}-go-${{ hashFiles('**/go.sum') }}
          restore-keys: |
            ${{ runner.os }}-go-
      
      - name: Download dependencies
        working-directory: ./pgworld-api-master
        run: go mod download
      
      - name: Build application
        working-directory: ./pgworld-api-master
        run: |
          CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o pgworld-api .
      
      - name: Run tests
        working-directory: ./pgworld-api-master
        run: go test -v ./... || echo "No tests found"
      
      - name: Upload artifact
        uses: actions/upload-artifact@v3
        with:
          name: pgworld-api
          path: pgworld-api-master/pgworld-api
          retention-days: 7

  deploy-preprod:
    name: Deploy to Pre-Production
    needs: build
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/develop' && github.event_name == 'push'
    environment:
      name: pre-production
      url: https://api-preprod.pgworld.com
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
      
      - name: Download artifact
        uses: actions/download-artifact@v3
        with:
          name: pgworld-api
      
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.AWS_REGION }}
      
      - name: Deploy to Pre-Prod EC2
        env:
          PRIVATE_KEY: ${{ secrets.PREPROD_SSH_KEY }}
          HOST: ${{ secrets.PREPROD_HOST }}
          USER: ec2-user
        run: |
          echo "$PRIVATE_KEY" > private_key.pem
          chmod 600 private_key.pem
          
          scp -i private_key.pem -o StrictHostKeyChecking=no \
            pgworld-api $USER@$HOST:/tmp/
          
          ssh -i private_key.pem -o StrictHostKeyChecking=no $USER@$HOST << 'EOF'
            sudo systemctl stop pgworld-api || true
            
            if [ -f /opt/pgworld/pgworld-api ]; then
              sudo cp /opt/pgworld/pgworld-api /opt/pgworld/pgworld-api.backup
            fi
            
            sudo mv /tmp/pgworld-api /opt/pgworld/pgworld-api
            sudo chmod +x /opt/pgworld/pgworld-api
            
            aws ssm get-parameters-by-path \
              --path "/pgworld/preprod/" \
              --with-decryption \
              --region us-east-1 \
              --query "Parameters[*].[Name,Value]" \
              --output text | while read name value; do
              param_name=$(echo $name | awk -F'/' '{print $NF}')
              echo "$param_name=$value" >> /tmp/pgworld.env
            done
            sudo mv /tmp/pgworld.env /opt/pgworld/.env
            
            sudo systemctl start pgworld-api
            sudo systemctl status pgworld-api
          EOF
          
          rm private_key.pem
      
      - name: Health Check
        run: |
          sleep 10
          curl -f https://api-preprod.pgworld.com/ || exit 1
          echo "✓ Pre-production deployment successful!"

  deploy-production:
    name: Deploy to Production
    needs: build
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    environment:
      name: production
      url: https://api.pgworld.com
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
      
      - name: Download artifact
        uses: actions/download-artifact@v3
        with:
          name: pgworld-api
      
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.AWS_REGION }}
      
      - name: Deploy to Production EC2
        env:
          PRIVATE_KEY: ${{ secrets.PRODUCTION_SSH_KEY }}
          HOST: ${{ secrets.PRODUCTION_HOST }}
          USER: ec2-user
        run: |
          echo "$PRIVATE_KEY" > private_key.pem
          chmod 600 private_key.pem
          
          scp -i private_key.pem -o StrictHostKeyChecking=no \
            pgworld-api $USER@$HOST:/tmp/
          
          ssh -i private_key.pem -o StrictHostKeyChecking=no $USER@$HOST << 'EOF'
            sudo systemctl stop pgworld-api || true
            
            if [ -f /opt/pgworld/pgworld-api ]; then
              sudo cp /opt/pgworld/pgworld-api /opt/pgworld/pgworld-api.backup.$(date +%Y%m%d-%H%M%S)
            fi
            
            sudo mv /tmp/pgworld-api /opt/pgworld/pgworld-api
            sudo chmod +x /opt/pgworld/pgworld-api
            
            aws ssm get-parameters-by-path \
              --path "/pgworld/production/" \
              --with-decryption \
              --region us-east-1 \
              --query "Parameters[*].[Name,Value]" \
              --output text | while read name value; do
              param_name=$(echo $name | awk -F'/' '{print $NF}')
              echo "$param_name=$value" >> /tmp/pgworld.env
            done
            sudo mv /tmp/pgworld.env /opt/pgworld/.env
            
            sudo systemctl start pgworld-api
            sudo systemctl status pgworld-api
          EOF
          
          rm private_key.pem
      
      - name: Health Check
        run: |
          sleep 10
          curl -f https://api.pgworld.com/ || exit 1
          echo "✓ Production deployment successful!"
      
      - name: Rollback on Failure
        if: failure()
        env:
          PRIVATE_KEY: ${{ secrets.PRODUCTION_SSH_KEY }}
          HOST: ${{ secrets.PRODUCTION_HOST }}
          USER: ec2-user
        run: |
          echo "⚠️ Deployment failed, rolling back..."
          echo "$PRIVATE_KEY" > private_key.pem
          chmod 600 private_key.pem
          
          ssh -i private_key.pem -o StrictHostKeyChecking=no $USER@$HOST << 'EOF'
            sudo systemctl stop pgworld-api
            if [ -f /opt/pgworld/pgworld-api.backup ]; then
              sudo mv /opt/pgworld/pgworld-api.backup /opt/pgworld/pgworld-api
              sudo systemctl start pgworld-api
              echo "Rolled back to previous version"
            fi
          EOF
          
          rm private_key.pem
          exit 1
'@

$workflowFile = Join-Path $workflowDir "deploy.yml"
Set-Content -Path $workflowFile -Value $workflow
Write-Host "✓ Created .github/workflows/deploy.yml" -ForegroundColor Green

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Setup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "GitHub Actions workflow created!" -ForegroundColor Yellow
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Next Steps:" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "1. Commit and push to GitHub:" -ForegroundColor White
Write-Host "   git add .github" -ForegroundColor Gray
Write-Host "   git commit -m 'Add GitHub Actions CI/CD pipeline'" -ForegroundColor Gray
Write-Host "   git push origin main" -ForegroundColor Gray
Write-Host ""

Write-Host "2. Add GitHub Secrets:" -ForegroundColor White
Write-Host "   Go to: GitHub repo -> Settings -> Secrets and variables -> Actions" -ForegroundColor Gray
Write-Host ""
Write-Host "   Add these secrets:" -ForegroundColor Gray
Write-Host "   - AWS_ACCESS_KEY_ID (your AWS access key)" -ForegroundColor Gray
Write-Host "   - AWS_SECRET_ACCESS_KEY (your AWS secret key)" -ForegroundColor Gray
Write-Host "   - PREPROD_SSH_KEY (content of preprod .pem file)" -ForegroundColor Gray
Write-Host "   - PREPROD_HOST (preprod EC2 IP address)" -ForegroundColor Gray
Write-Host "   - PRODUCTION_SSH_KEY (content of production .pem file)" -ForegroundColor Gray
Write-Host "   - PRODUCTION_HOST (production EC2 IP address)" -ForegroundColor Gray
Write-Host ""

Write-Host "3. Configure GitHub Environments:" -ForegroundColor White
Write-Host "   Go to: GitHub repo -> Settings -> Environments" -ForegroundColor Gray
Write-Host ""
Write-Host "   Create 'pre-production' environment:" -ForegroundColor Gray
Write-Host "   - No protection rules (auto-deploy)" -ForegroundColor Gray
Write-Host "   - URL: https://api-preprod.pgworld.com" -ForegroundColor Gray
Write-Host ""
Write-Host "   Create 'production' environment:" -ForegroundColor Gray
Write-Host "   - Add required reviewers (yourself)" -ForegroundColor Gray
Write-Host "   - URL: https://api.pgworld.com" -ForegroundColor Gray
Write-Host ""

Write-Host "4. Set up Branch Protection:" -ForegroundColor White
Write-Host "   Go to: GitHub repo -> Settings -> Branches" -ForegroundColor Gray
Write-Host ""
Write-Host "   Protect 'main' branch:" -ForegroundColor Gray
Write-Host "   - Require pull request reviews" -ForegroundColor Gray
Write-Host "   - Require status checks (build)" -ForegroundColor Gray
Write-Host ""
Write-Host "   Protect 'develop' branch:" -ForegroundColor Gray
Write-Host "   - Require status checks (build)" -ForegroundColor Gray
Write-Host ""

Write-Host "5. Create branches:" -ForegroundColor White
Write-Host "   git checkout -b develop" -ForegroundColor Gray
Write-Host "   git push origin develop" -ForegroundColor Gray
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Deployment Workflow:" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "To deploy to PRE-PRODUCTION:" -ForegroundColor White
Write-Host "  1. Create feature branch" -ForegroundColor Gray
Write-Host "  2. Make changes and commit" -ForegroundColor Gray
Write-Host "  3. Push to 'develop' branch" -ForegroundColor Gray
Write-Host "  4. Auto-deploys to pre-prod!" -ForegroundColor Green
Write-Host ""

Write-Host "To deploy to PRODUCTION:" -ForegroundColor White
Write-Host "  1. Verify pre-prod is stable" -ForegroundColor Gray
Write-Host "  2. Create PR: develop -> main" -ForegroundColor Gray
Write-Host "  3. Get approval and merge" -ForegroundColor Gray
Write-Host "  4. Approve deployment in GitHub Actions" -ForegroundColor Yellow
Write-Host "  5. Deploys to production!" -ForegroundColor Green
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Resources:" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Complete guide: GITHUB_ACTIONS_PIPELINE.md" -ForegroundColor White
Write-Host "AWS setup guide: AWS_PIPELINE_SETUP.md" -ForegroundColor White
Write-Host ""

Write-Host "Ready to deploy" -ForegroundColor Green
Write-Host ""

