# Quick Start Checklist for AWS Deployment

**Print this page and check off items as you complete them!**

---

## TODAY: AWS Account Setup (2 hours)

### Create AWS Account (30 min)
- [ ] Go to https://aws.amazon.com/
- [ ] Click "Create an AWS Account"
- [ ] Enter email: _______________________
- [ ] Choose password: ___________________
- [ ] Account name: PGNi-Production
- [ ] Account type: Professional
- [ ] Fill contact information
- [ ] Add credit/debit card (₹2 verification)
- [ ] Complete phone verification
- [ ] Choose "Basic Support - Free"
- [ ] Wait for activation email ✓

### Secure Account (30 min)
- [ ] Login to AWS Console
- [ ] Enable MFA on root account
- [ ] Install authenticator app (Google Authenticator/Authy)
- [ ] Scan QR code and save
- [ ] Go to IAM Console
- [ ] Create user: `pgni-admin`
- [ ] Attach policy: AdministratorAccess
- [ ] Enable MFA for admin user
- [ ] Create access keys
- [ ] **SAVE credentials:**
  - Access Key ID: ___________________________
  - Secret Key: ______________________________
  - Store securely! ✓

### Cost Management (20 min)
- [ ] Go to Billing Console
- [ ] Enable "Receive Free Tier Usage Alerts"
- [ ] Enable "Receive Billing Alerts"
- [ ] Create budget: ₹3,000/month
- [ ] Set alert at 50% (₹1,500)
- [ ] Set alert at 80% (₹2,400)
- [ ] Set alert at 100% (₹3,000)
- [ ] Enter email for alerts: _________________

### Create Resources (30 min)
- [ ] Select region: **ap-south-1** (Mumbai)
- [ ] Go to EC2 Console → Key Pairs
- [ ] Create key: `pgni-preprod-key`
- [ ] Download .pem file
- [ ] Save to: C:\AWS-Keys\pgni-preprod-key.pem
- [ ] Create key: `pgni-production-key`
- [ ] Download .pem file
- [ ] Save to: C:\AWS-Keys\pgni-production-key.pem
- [ ] **SECURE these files!** ✓

### Install AWS CLI (10 min)
- [ ] Open PowerShell
- [ ] Run: `winget install Amazon.AWSCLI`
- [ ] Close and reopen PowerShell
- [ ] Run: `aws configure`
- [ ] Enter Access Key ID
- [ ] Enter Secret Access Key
- [ ] Region: `ap-south-1`
- [ ] Output format: `json`
- [ ] Test: `aws s3 ls` (should work)

---

## GitHub Configuration (30 min)

### Add AWS Secrets
- [ ] Go to: https://github.com/siddam01/pgni/settings/secrets/actions
- [ ] Click "New repository secret"
- [ ] Add `AWS_ACCESS_KEY_ID`
- [ ] Add `AWS_SECRET_ACCESS_KEY`

### Create Environments
- [ ] Go to: https://github.com/siddam01/pgni/settings/environments
- [ ] Click "New environment"
- [ ] Name: `pre-production`
- [ ] No approval needed
- [ ] Click "New environment"
- [ ] Name: `production`
- [ ] Check "Required reviewers"
- [ ] Add yourself as reviewer

### Create Develop Branch
- [ ] Open terminal in project folder
- [ ] Run: `git checkout -b develop`
- [ ] Run: `git push -u origin develop`
- [ ] Verify on GitHub ✓

---

## Prepare Environment Variables

Create a secure document with these values:

### Database Credentials
```
DB_USER: pgni_admin
DB_PASSWORD: __________________ (generate strong password)
DB_NAME: pgnidb
DB_PORT: 3306
```

### API Keys
```
ANDROID_LIVE_KEY: __________________
ANDROID_TEST_KEY: __________________
IOS_LIVE_KEY: __________________
IOS_TEST_KEY: __________________
```

### Razorpay
```
RAZORPAY_KEY_ID: __________________
RAZORPAY_KEY_SECRET: __________________
```

### AWS
```
AWS_REGION: ap-south-1
S3_BUCKET_NAME: pgni-uploads-prod
```

**Generate strong password:**
```powershell
-join ((33..126) | Get-Random -Count 20 | ForEach-Object {[char]$_})
```

---

## Pre-Production Deployment (3 hours)

### Create RDS Database
- [ ] Go to RDS Console
- [ ] Click "Create database"
- [ ] Choose: Standard Create
- [ ] Engine: MySQL
- [ ] Version: 8.0
- [ ] Template: **Free tier**
- [ ] DB instance: db.t3.micro
- [ ] DB name: `pgnidb_preprod`
- [ ] Master username: `pgni_admin`
- [ ] Master password: (from your secure doc)
- [ ] Public access: Yes
- [ ] Create database
- [ ] Wait 5-10 minutes for creation
- [ ] Copy endpoint URL: _______________________

### Create S3 Bucket
- [ ] Go to S3 Console
- [ ] Click "Create bucket"
- [ ] Name: `pgni-uploads-preprod`
- [ ] Region: ap-south-1
- [ ] Uncheck "Block all public access"
- [ ] Enable versioning
- [ ] Create bucket ✓

### Create EC2 Instance
- [ ] Go to EC2 Console
- [ ] Click "Launch instance"
- [ ] Name: `pgni-preprod-server`
- [ ] AMI: Ubuntu Server 22.04 LTS
- [ ] Instance type: **t3.micro** (free tier)
- [ ] Key pair: `pgni-preprod-key`
- [ ] Create security group:
  - [ ] Allow SSH (22) from My IP
  - [ ] Allow HTTP (80) from Anywhere
  - [ ] Allow HTTPS (443) from Anywhere
  - [ ] Allow Custom TCP (8080) from Anywhere
- [ ] Storage: 8 GB (free tier)
- [ ] Launch instance
- [ ] Copy Public IP: _______________________

### Configure GitHub SSH Secrets
- [ ] Open PowerShell
- [ ] Run:
  ```powershell
  $pemContent = Get-Content "C:\AWS-Keys\pgni-preprod-key.pem" -Raw
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($pemContent)
  [Convert]::ToBase64String($bytes) | clip
  ```
- [ ] Go to GitHub Secrets
- [ ] Add `PREPROD_SSH_KEY` (paste from clipboard)
- [ ] Add `PREPROD_HOST` (EC2 Public IP)

### Deploy
- [ ] Run: `git checkout develop`
- [ ] Run: `git add .`
- [ ] Run: `git commit -m "Deploy to pre-production"`
- [ ] Run: `git push`
- [ ] Go to: https://github.com/siddam01/pgni/actions
- [ ] Watch deployment
- [ ] Wait for success ✓

### Test Pre-Production
- [ ] Open: `http://<EC2-IP>:8080/`
- [ ] Should see: "ok"
- [ ] Test login API
- [ ] Test registration
- [ ] Test file upload
- [ ] Check database entries

---

## Production Deployment (3 hours)

### Create Production RDS
- [ ] Create database: `pgnidb_prod`
- [ ] Same settings as pre-prod
- [ ] Enable encryption
- [ ] Enable automated backups
- [ ] Copy endpoint: _______________________

### Create Production S3
- [ ] Create bucket: `pgni-uploads-prod`
- [ ] Enable versioning
- [ ] Enable encryption

### Create Production EC2
- [ ] Instance name: `pgni-prod-server`
- [ ] Instance type: **t3.small** (better performance)
- [ ] Key pair: `pgni-production-key`
- [ ] Security group: Same rules
- [ ] Copy Public IP: _______________________

### Configure GitHub Secrets
- [ ] Convert production key to base64
- [ ] Add `PRODUCTION_SSH_KEY`
- [ ] Add `PRODUCTION_HOST`

### Deploy to Production
- [ ] Run: `git checkout main`
- [ ] Run: `git merge develop`
- [ ] Run: `git push`
- [ ] Go to GitHub Actions
- [ ] Review deployment
- [ ] **Approve deployment**
- [ ] Wait for completion ✓

### Verify Production
- [ ] Test all APIs
- [ ] Verify database
- [ ] Check file uploads
- [ ] Load test (optional)
- [ ] **PRODUCTION IS LIVE!** 🎉

---

## Mobile App Deployment (1-2 days)

### Update API Endpoints
- [ ] Admin app: Update to production URL
- [ ] Tenant app: Update to production URL

### Build APKs
- [ ] Build Admin APK
- [ ] Build Admin App Bundle
- [ ] Build Tenant APK
- [ ] Build Tenant App Bundle
- [ ] Test on physical devices

### Play Store Submission
- [ ] Create Play Console account ($25)
- [ ] Submit PGNi Admin app
- [ ] Submit PGNi (Tenant) app
- [ ] Wait for review (2-7 days)

---

## Post-Deployment Monitoring

### Daily Checks
- [ ] Check CloudWatch alarms
- [ ] Review API logs
- [ ] Monitor performance
- [ ] Check error rates

### Weekly Checks
- [ ] Review AWS costs
- [ ] Check free tier usage
- [ ] Security review
- [ ] Database optimization

---

## Important Phone Numbers & Links

**AWS Support:** 1800-572-4555 (India, toll-free)

**Your Links:**
- AWS Console: https://console.aws.amazon.com/
- GitHub Repo: https://github.com/siddam01/pgni
- AWS Free Tier: https://console.aws.amazon.com/billing/home#/freetier

**Your Guides:**
- [ ] DEPLOYMENT_ROADMAP.md - Complete journey
- [ ] AWS_ACCOUNT_SETUP.md - Detailed AWS setup
- [ ] DEPLOY_TO_AWS.md - Technical deployment
- [ ] PRE_DEPLOYMENT_CHECKLIST.md - 75+ checks
- [ ] GITHUB_SETUP_GUIDE.md - CI/CD setup

---

## Cost Tracking

**Month 1-12 (Free Tier):**
Expected: ₹0-500/month

**Month 13+ (After Free Tier):**
Expected: ₹2,500-3,500/month

**Actual Costs:**
- Month 1: ₹_______
- Month 2: ₹_______
- Month 3: ₹_______

---

## Emergency Contacts

If something goes wrong:

1. Check AWS CloudWatch logs
2. Check GitHub Actions logs
3. SSH into EC2 and check API logs
4. Call AWS Support: 1800-572-4555
5. Check RDS connection
6. Verify security groups

---

## Success!

When you complete all checkboxes:
- [ ] AWS account created ✓
- [ ] Pre-production deployed ✓
- [ ] Production deployed ✓
- [ ] Apps submitted to Play Store ✓
- [ ] Monitoring set up ✓

**YOU'RE LIVE! Congratulations! 🎉🚀**

---

*Print this checklist and check off items as you go!*
*Keep your credentials secure and never share them!*

