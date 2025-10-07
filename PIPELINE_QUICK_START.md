# 🚀 CI/CD Pipeline - Quick Start Guide

**Goal:** Set up automated deployment to Pre-Production and Production in AWS

---

## 🎯 QUICK DECISION

### Which Pipeline Should You Use?

| Feature | GitHub Actions | AWS CodePipeline |
|---------|---------------|------------------|
| **Setup Time** | 1 hour ⚡ | 3 hours |
| **Difficulty** | Easy ✅ | Hard ❌ |
| **Cost** | $0.40/month 💰 | $7/month |
| **Configuration** | 1 YAML file | 5+ AWS services |
| **Visibility** | GitHub UI | AWS Console |
| **Recommended** | **YES!** 🏆 | No (unless AWS-only) |

**Winner: GitHub Actions** - 3x faster, 17x cheaper, much easier!

---

## ⚡ SUPER QUICK START (GitHub Actions)

### 3 Commands to Set Up:

```powershell
# 1. Run setup script
.\setup-github-actions.ps1

# 2. Commit and push
git add .github
git commit -m "Add CI/CD pipeline"
git push origin main

# 3. Configure GitHub (see below)
```

### Configure GitHub (10 minutes):

**Step 1: Add Secrets**  
Go to: GitHub repo → Settings → Secrets → Actions

```
AWS_ACCESS_KEY_ID = [Your AWS access key]
AWS_SECRET_ACCESS_KEY = [Your AWS secret key]
PREPROD_SSH_KEY = [Content of preprod-key.pem]
PREPROD_HOST = [Preprod EC2 IP]
PRODUCTION_SSH_KEY = [Content of production-key.pem]
PRODUCTION_HOST = [Production EC2 IP]
```

**Step 2: Create Environments**  
Go to: GitHub repo → Settings → Environments

- Create `pre-production` (no protection)
- Create `production` (add yourself as required reviewer)

**Done!** You now have automated deployments! 🎉

---

## 📊 ENVIRONMENT SETUP

### You Need 3 Environments:

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│  Development (Local)                                        │
│  ├─ URL: http://localhost:8080                             │
│  ├─ Database: Local MySQL                                   │
│  ├─ Deploy: Manual                                          │
│  └─ Cost: FREE                                              │
│                                                             │
│  ↓ Push to 'develop' branch                                │
│                                                             │
│  Pre-Production (AWS)                                       │
│  ├─ URL: https://api-preprod.pgworld.com                   │
│  ├─ Database: RDS MySQL (db.t3.micro)                      │
│  ├─ Deploy: AUTO                                            │
│  └─ Cost: $25/month                                         │
│                                                             │
│  ↓ Merge to 'main' branch + Approve                        │
│                                                             │
│  Production (AWS)                                           │
│  ├─ URL: https://api.pgworld.com                           │
│  ├─ Database: RDS MySQL (db.t3.small, Multi-AZ)           │
│  ├─ Deploy: Manual Approval Required                        │
│  └─ Cost: $96/month                                         │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

**Total Monthly Cost:** $121-128/month (depending on pipeline choice)

---

## 🔧 AWS INFRASTRUCTURE NEEDED

### Before Setting Up Pipeline:

**1. Pre-Production:**
- [ ] RDS MySQL (db.t3.micro) - $15/month
- [ ] EC2 instance (t3.micro) - $8/month
- [ ] S3 bucket (pgworld-preprod-uploads) - $2/month
- [ ] **Total:** $25/month

**2. Production:**
- [ ] RDS MySQL (db.t3.small, Multi-AZ) - $60/month
- [ ] EC2 instance (t3.small) - $15/month
- [ ] S3 bucket (pgworld-production-uploads) - $5/month
- [ ] Load Balancer (optional) - $16/month
- [ ] **Total:** $96/month (with LB) or $80/month (without)

**3. Secrets in Parameter Store:**
- [ ] Store all environment variables in AWS Systems Manager Parameter Store
- [ ] Path format: `/pgworld/preprod/variableName` and `/pgworld/production/variableName`

---

## 🚀 DEPLOYMENT WORKFLOW

### To Pre-Production (Automatic):

```bash
# 1. Create feature branch
git checkout -b feature/add-billing

# 2. Make changes
# ... edit code ...

# 3. Commit and push to develop
git add .
git commit -m "Add billing feature"
git push origin develop

# ✅ GitHub Actions automatically:
#    - Builds the app
#    - Runs tests
#    - Deploys to pre-prod
#    - Runs health check

# 4. Test on pre-prod
curl https://api-preprod.pgworld.com/
```

---

### To Production (Manual Approval):

```bash
# 1. Verify pre-prod is stable
# Test thoroughly!

# 2. Create PR: develop → main
# Go to GitHub, create Pull Request

# 3. Get code review
# Team reviews and approves

# 4. Merge to main
# Click "Merge pull request"

# ⏸️  GitHub Actions:
#    - Builds the app
#    - Runs tests
#    - WAITS for your approval

# 5. Approve deployment
# Go to: GitHub Actions → Click workflow → Review → Approve

# ✅ GitHub Actions then:
#    - Deploys to production
#    - Runs health check
#    - Notifies success

# 6. Verify production
curl https://api.pgworld.com/
```

**If deployment fails:** Automatic rollback to previous version!

---

## 📁 FILES CREATED

### Run Setup Script:

```powershell
# For GitHub Actions (Recommended)
.\setup-github-actions.ps1

# OR for AWS CodePipeline
.\setup-aws-pipeline.ps1
```

### Files Created by Script:

```
.github/workflows/deploy.yml     ← GitHub Actions workflow
pgworld-api-master/
  ├─ .env.development            ← Local config
  ├─ .env.preprod.template       ← Pre-prod template
  ├─ .env.production.template    ← Production template
  ├─ buildspec.yml               ← Build configuration
  ├─ appspec.yml                 ← Deployment spec
  └─ scripts/
      ├─ stop_server.sh
      ├─ before_install.sh
      ├─ after_install.sh
      ├─ start_server.sh
      └─ validate_service.sh
```

---

## ✅ COMPLETE SETUP CHECKLIST

### One-Time Setup (1-2 hours):

**AWS Infrastructure:**
- [ ] Create Pre-Prod RDS database
- [ ] Create Pre-Prod EC2 instance
- [ ] Create Pre-Prod S3 bucket
- [ ] Create Production RDS database
- [ ] Create Production EC2 instance
- [ ] Create Production S3 bucket
- [ ] Store secrets in AWS Parameter Store
- [ ] Configure security groups
- [ ] Set up DNS (Route 53 or your provider)
- [ ] Request SSL certificates

**Pipeline Setup:**
- [ ] Run setup script (GitHub Actions or AWS CodePipeline)
- [ ] Create GitHub repository
- [ ] Push code to GitHub
- [ ] Add GitHub secrets
- [ ] Configure GitHub environments
- [ ] Set up branch protection
- [ ] Create `develop` branch
- [ ] Test deployment to pre-prod
- [ ] Test deployment to production

**EC2 Configuration:**
- [ ] Install Go on both EC2 instances
- [ ] Install AWS CLI on both EC2 instances
- [ ] Configure IAM role for EC2 (Parameter Store access)
- [ ] Create systemd service on both instances
- [ ] Test service starts correctly

### Every Deployment:

**To Pre-Production:**
- [ ] Create feature branch
- [ ] Make changes and test locally
- [ ] Push to `develop` branch
- [ ] Wait for auto-deployment
- [ ] Verify on pre-prod

**To Production:**
- [ ] Verify pre-prod is stable
- [ ] Create PR: develop → main
- [ ] Get code review and approval
- [ ] Merge to main
- [ ] Approve deployment in GitHub Actions
- [ ] Verify on production
- [ ] Monitor for issues

---

## 💰 COST BREAKDOWN

### Infrastructure (AWS):
- Pre-Production: $25/month
- Production: $96/month
- **Subtotal: $121/month**

### Pipeline:
- GitHub Actions: $0.40/month (or FREE for public repo)
- AWS CodePipeline: $7/month
- **Subtotal: $0.40-7/month**

### Total:
- With GitHub Actions: **$121/month** ✅
- With AWS CodePipeline: **$128/month**

**Recommendation:** GitHub Actions saves $84/year!

---

## 🎯 WHICH GUIDE TO READ?

### Just Starting:
👉 Read: **This file (PIPELINE_QUICK_START.md)** - You're reading it!

### Want GitHub Actions (Recommended):
👉 Read: **GITHUB_ACTIONS_PIPELINE.md** (detailed guide)  
👉 Run: **`.\setup-github-actions.ps1`** (setup script)

### Want AWS CodePipeline:
👉 Read: **AWS_PIPELINE_SETUP.md** (detailed guide)  
👉 Run: **`.\setup-aws-pipeline.ps1`** (setup script)

### Need AWS Infrastructure Setup:
👉 Read: **DEPLOY_TO_AWS.md** (infrastructure guide)

---

## 🆘 TROUBLESHOOTING

### GitHub Actions workflow fails:

**Problem:** Build fails  
**Solution:** Check logs in GitHub Actions tab, fix errors, push again

**Problem:** Can't connect to EC2  
**Solution:** Verify SSH key is correct in GitHub secrets

**Problem:** Deployment fails  
**Solution:** Check EC2 is running, security group allows SSH (port 22)

### EC2 deployment issues:

**Problem:** Service won't start  
**Solution:** 
```bash
# SSH into EC2
ssh -i key.pem ec2-user@YOUR_IP

# Check logs
sudo journalctl -u pgworld-api -f

# Check service status
sudo systemctl status pgworld-api
```

**Problem:** Can't load environment variables  
**Solution:** Verify IAM role allows SSM Parameter Store access

---

## 📞 NEXT STEPS

### Ready to Set Up?

**Step 1:** Choose your pipeline
- ⭐ **GitHub Actions** (recommended) - easier, cheaper
- ⚠️ **AWS CodePipeline** - AWS-native, more complex

**Step 2:** Run the setup script
```powershell
# For GitHub Actions
.\setup-github-actions.ps1

# OR for AWS CodePipeline
.\setup-aws-pipeline.ps1
```

**Step 3:** Follow the on-screen instructions

**Step 4:** Read the detailed guide for your choice

**Step 5:** Deploy! 🚀

---

## 📚 ALL AVAILABLE GUIDES

| Document | Purpose | Read Time |
|----------|---------|-----------|
| **PIPELINE_QUICK_START.md** | This file - Quick overview | 5 min |
| **GITHUB_ACTIONS_PIPELINE.md** | Complete GitHub Actions guide | 15 min |
| **AWS_PIPELINE_SETUP.md** | Complete AWS CodePipeline guide | 20 min |
| **DEPLOY_TO_AWS.md** | AWS infrastructure setup | 30 min |
| **DEPLOY_TO_AZURE.md** | Azure deployment | 30 min |
| **PLATFORM_COMPARISON.md** | Platform comparison | 10 min |
| **PRE_DEPLOYMENT_CHECKLIST.md** | Pre-deployment checklist | 15 min |

---

## 🎉 SUMMARY

✅ **You have everything you need to set up a production-ready CI/CD pipeline!**

**The setup includes:**
- ✅ Automated deployments to Pre-Prod and Production
- ✅ Manual approval for production (safety!)
- ✅ Automatic rollback on failure
- ✅ Health checks after deployment
- ✅ Environment-specific configuration
- ✅ Secure secret management
- ✅ Cost-optimized infrastructure

**Recommendation:**
1. Use **GitHub Actions** (easier, cheaper)
2. Start with **Pre-Production** only ($25/month)
3. Add **Production** when ready ($121/month total)
4. Deploy and iterate!

**Ready? Run:** `.\setup-github-actions.ps1`

🚀 **Let's get your app deployed to the cloud!**

