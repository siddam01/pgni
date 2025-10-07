# 🚀 GitHub Actions CI/CD Pipeline (Easier Alternative)

**Platform:** GitHub Actions + AWS  
**Setup Time:** 1 hour (vs 3 hours for CodePipeline)  
**Cost:** FREE (GitHub Actions is free for public repos, $0.008/minute for private)

---

## 🎯 WHY GITHUB ACTIONS?

| Feature | AWS CodePipeline | GitHub Actions | Winner |
|---------|------------------|----------------|--------|
| **Setup Time** | 3 hours | 1 hour | GitHub Actions |
| **Complexity** | High | Low | GitHub Actions |
| **Cost** | $2/pipeline/month | Free (public) / $0.008/min (private) | GitHub Actions |
| **Learning Curve** | Steep | Gentle | GitHub Actions |
| **Configuration** | Multiple AWS services | One YAML file | GitHub Actions |
| **Visibility** | AWS Console | GitHub UI | GitHub Actions |
| **Community** | Good | Huge | GitHub Actions |

**Recommendation:** Use GitHub Actions unless you have AWS-only requirements

---

## 📊 ARCHITECTURE

```
Developer → GitHub
            ↓
      GitHub Actions
        (Build & Test)
            ↓
    ┌───────┴───────┐
    ↓               ↓
PRE-PROD         PROD
AWS EC2          AWS EC2
(auto-deploy)    (manual approval)
```

---

## 🚀 STEP-BY-STEP SETUP

### Step 1: Create Workflow File (5 minutes)

Create `.github/workflows/deploy.yml`:

```yaml
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
  # Job 1: Build and Test
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
        run: go test -v ./...
      
      - name: Upload artifact
        uses: actions/upload-artifact@v3
        with:
          name: pgworld-api
          path: pgworld-api-master/pgworld-api
          retention-days: 7

  # Job 2: Deploy to Pre-Production
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
          # Save SSH key
          echo "$PRIVATE_KEY" > private_key.pem
          chmod 600 private_key.pem
          
          # Copy binary to EC2
          scp -i private_key.pem -o StrictHostKeyChecking=no \
            pgworld-api $USER@$HOST:/tmp/
          
          # Deploy on EC2
          ssh -i private_key.pem -o StrictHostKeyChecking=no $USER@$HOST << 'EOF'
            # Stop service
            sudo systemctl stop pgworld-api || true
            
            # Backup current version
            if [ -f /opt/pgworld/pgworld-api ]; then
              sudo cp /opt/pgworld/pgworld-api /opt/pgworld/pgworld-api.backup
            fi
            
            # Deploy new version
            sudo mv /tmp/pgworld-api /opt/pgworld/pgworld-api
            sudo chmod +x /opt/pgworld/pgworld-api
            
            # Load environment variables from AWS Parameter Store
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
            
            # Start service
            sudo systemctl start pgworld-api
            sudo systemctl status pgworld-api
          EOF
          
          # Cleanup
          rm private_key.pem
      
      - name: Health Check
        run: |
          sleep 10
          curl -f https://api-preprod.pgworld.com/ || exit 1
          echo "✓ Pre-production deployment successful!"

  # Job 3: Deploy to Production
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
          # Save SSH key
          echo "$PRIVATE_KEY" > private_key.pem
          chmod 600 private_key.pem
          
          # Copy binary to EC2
          scp -i private_key.pem -o StrictHostKeyChecking=no \
            pgworld-api $USER@$HOST:/tmp/
          
          # Deploy on EC2
          ssh -i private_key.pem -o StrictHostKeyChecking=no $USER@$HOST << 'EOF'
            # Stop service
            sudo systemctl stop pgworld-api || true
            
            # Backup current version
            if [ -f /opt/pgworld/pgworld-api ]; then
              sudo cp /opt/pgworld/pgworld-api /opt/pgworld/pgworld-api.backup.$(date +%Y%m%d-%H%M%S)
            fi
            
            # Deploy new version
            sudo mv /tmp/pgworld-api /opt/pgworld/pgworld-api
            sudo chmod +x /opt/pgworld/pgworld-api
            
            # Load environment variables from AWS Parameter Store
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
            
            # Start service
            sudo systemctl start pgworld-api
            sudo systemctl status pgworld-api
          EOF
          
          # Cleanup
          rm private_key.pem
      
      - name: Health Check
        run: |
          sleep 10
          curl -f https://api.pgworld.com/ || exit 1
          echo "✓ Production deployment successful!"
      
      - name: Notify Success
        if: success()
        run: |
          echo "🎉 Production deployment completed successfully!"
      
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
```

---

### Step 2: Configure GitHub Secrets (10 minutes)

Go to your GitHub repository → Settings → Secrets and variables → Actions

**Add these secrets:**

```
AWS_ACCESS_KEY_ID = Your AWS access key
AWS_SECRET_ACCESS_KEY = Your AWS secret key

PREPROD_SSH_KEY = Content of pgworld-preprod-key.pem
PREPROD_HOST = EC2 IP address for pre-prod (e.g., 54.123.45.67)

PRODUCTION_SSH_KEY = Content of pgworld-production-key.pem
PRODUCTION_HOST = EC2 IP address for production (e.g., 54.123.45.68)
```

**How to add SSH key:**
1. Open your `.pem` file in notepad
2. Copy entire content (including BEGIN and END lines)
3. Paste into GitHub secret

---

### Step 3: Configure GitHub Environments (5 minutes)

Go to Settings → Environments

**Create Pre-Production environment:**
- Name: `pre-production`
- Protection rules: None (auto-deploy)
- URL: `https://api-preprod.pgworld.com`

**Create Production environment:**
- Name: `production`
- Protection rules: 
  - ✅ Required reviewers (add yourself)
  - ✅ Wait timer: 0 minutes
- URL: `https://api.pgworld.com`

This ensures production deployments require manual approval!

---

### Step 4: Set Up Branch Protection (5 minutes)

Go to Settings → Branches

**Protect `main` branch:**
- ✅ Require pull request before merging
- ✅ Require approvals (1)
- ✅ Require status checks to pass
  - Add: `build`

**Protect `develop` branch:**
- ✅ Require status checks to pass
  - Add: `build`

---

## 🔄 WORKFLOW

### Deploying to Pre-Production

```bash
# 1. Create feature branch
git checkout -b feature/my-feature

# 2. Make changes
# ... edit files ...

# 3. Commit and push
git add .
git commit -m "Add new feature"
git push origin feature/my-feature

# 4. Create PR to develop
# Go to GitHub and create PR: feature/my-feature → develop

# 5. Merge PR
# GitHub Actions automatically:
#   - Builds the app
#   - Runs tests
#   - Deploys to pre-prod

# 6. Test on pre-prod
curl https://api-preprod.pgworld.com/

# ✅ Pre-prod is live!
```

---

### Deploying to Production

```bash
# 1. Verify pre-prod is stable
# Test thoroughly on pre-prod

# 2. Create PR to main
# Go to GitHub and create PR: develop → main

# 3. Get approval and merge
# After merge, GitHub Actions:
#   - Builds the app
#   - Runs tests
#   - WAITS for your approval

# 4. Approve deployment
# Go to GitHub Actions → Click on workflow run → Review deployments → Approve

# 5. Deployment proceeds automatically

# 6. Verify production
curl https://api.pgworld.com/

# ✅ Production is live!
```

---

## 📊 COST COMPARISON

### GitHub Actions (Recommended)

**Free tier (per month):**
- Public repos: Unlimited
- Private repos: 2,000 minutes

**Paid (private repos):**
- $0.008 per minute after free tier
- Average deployment: 5 minutes
- Cost per deployment: $0.04
- Cost per month (10 deployments): **$0.40**

**AWS resources:**
- Pre-prod: $25/month
- Production: $96/month
- **Total: ~$121/month**

---

### AWS CodePipeline

**Pipeline costs:**
- $1 per active pipeline per month
- 2 pipelines: **$2/month**

**CodeBuild:**
- Free tier: 100 build minutes
- After: $0.005/minute
- **Cost: ~$5/month**

**AWS resources:**
- Pre-prod: $25/month
- Production: $96/month
- **Total: ~$128/month**

**Winner: GitHub Actions saves $7/month and is much easier!**

---

## ✅ SETUP CHECKLIST

### One-Time Setup

- [ ] Create `.github/workflows/deploy.yml`
- [ ] Add GitHub secrets (AWS keys, SSH keys)
- [ ] Configure GitHub environments (preprod, production)
- [ ] Set up branch protection rules
- [ ] Create AWS infrastructure (RDS, EC2, S3)
- [ ] Store secrets in AWS Parameter Store
- [ ] Configure EC2 instances (install Go, create systemd service)
- [ ] Set up DNS records
- [ ] Request SSL certificates

### Every Deployment

**To Pre-Production:**
- [ ] Create feature branch
- [ ] Make changes
- [ ] Create PR to `develop`
- [ ] Merge PR (auto-deploys)
- [ ] Verify on api-preprod.pgworld.com

**To Production:**
- [ ] Create PR: `develop` → `main`
- [ ] Get code review and approval
- [ ] Merge PR
- [ ] Approve deployment in GitHub Actions
- [ ] Verify on api.pgworld.com

---

## 🎯 ADVANTAGES

### vs AWS CodePipeline

| Feature | GitHub Actions | CodePipeline |
|---------|---------------|--------------|
| **Setup Time** | 1 hour | 3 hours |
| **Configuration** | 1 file | 5+ services |
| **Visibility** | GitHub UI | AWS Console |
| **Cost** | $0.40/month | $7/month |
| **Learning Curve** | Easy | Hard |
| **Community Support** | Huge | Good |
| **Debugging** | Easy (logs in GitHub) | Complex (multiple AWS logs) |

**Winner: GitHub Actions** ✅

---

### Additional Benefits

1. **One place for everything:**
   - Code, PRs, CI/CD all in GitHub
   - No switching between GitHub and AWS Console

2. **Better visibility:**
   - See build status directly on PR
   - Easy to track deployments
   - Clear approval flow

3. **Easier troubleshooting:**
   - Logs in GitHub UI
   - Re-run failed jobs with one click
   - Clear error messages

4. **Better for teams:**
   - Everyone uses GitHub already
   - No need to give AWS Console access
   - Easy to review and approve

---

## 🚀 QUICK START

Run the setup script:

```powershell
.\setup-github-actions.ps1
```

This will:
1. Create workflow file
2. Create directory structure
3. Update .gitignore
4. Provide instructions for GitHub secrets

Then:
1. Push to GitHub
2. Add secrets
3. Configure environments
4. Ready to deploy!

---

## 📞 NEXT STEPS

**Choose your preferred method:**

### Option A: GitHub Actions (Recommended) ✅
- Easier setup
- Better visibility
- Lower cost
- One place for everything

**Next:** Run `.\setup-github-actions.ps1`

### Option B: AWS CodePipeline
- AWS-native solution
- More AWS control
- Good if already using AWS heavily

**Next:** Follow `AWS_PIPELINE_SETUP.md`

**Which do you prefer?** Let me know and I'll help you set it up!

