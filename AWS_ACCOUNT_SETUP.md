# AWS Account Setup Guide for PGNi Deployment

## Overview
This guide will help you set up an AWS account and prepare for deploying the PGNi application.

---

## Part 1: Create AWS Account

### Step 1: Sign Up for AWS Free Tier

**What You Get:**
- **12 months free tier** (eligible services)
- **750 hours/month** of EC2 t2.micro or t3.micro instances
- **20 GB** of RDS database storage
- **5 GB** of S3 storage
- **Always free services** (Lambda, DynamoDB free tier)

**Sign Up Process:**

1. **Go to AWS Website:**
   - Visit: https://aws.amazon.com/
   - Click "Create an AWS Account" or "Sign In to Console"

2. **Provide Email and Account Information:**
   - Root user email address (use your work/business email)
   - Account name: `PGNi-Production` (or your company name)
   - Choose a strong password

3. **Contact Information:**
   - Account type: **Professional** (for business use)
   - Full name: Your name
   - Phone number: +91-XXXXXXXXXX (India)
   - Country: India
   - Address: Your business/company address
   - City, State/Province, Postal code

4. **Payment Information:**
   - **Required:** Valid credit/debit card
   - **Important:** AWS will charge ₹2 (verification charge, refunded)
   - No charges during free tier period if you stay within limits
   - You'll only be charged if you exceed free tier limits

5. **Identity Verification:**
   - Phone verification (SMS or voice call)
   - Enter the 4-digit code received

6. **Choose Support Plan:**
   - Select: **Basic Support - Free**
   - (You can upgrade later if needed)

7. **Complete Sign Up:**
   - Wait for account activation (usually 5-10 minutes)
   - You'll receive a confirmation email

---

## Part 2: Secure Your AWS Account (CRITICAL!)

### Step 1: Enable Multi-Factor Authentication (MFA)

**Why:** Protects your account from unauthorized access

1. Sign in to AWS Console: https://console.aws.amazon.com/
2. Click your account name (top right) → **Security credentials**
3. Under "Multi-factor authentication (MFA)", click **Assign MFA device**
4. Choose MFA device:
   - **Virtual MFA device** (recommended): Use Google Authenticator or Authy app
   - Follow the setup wizard
5. Scan QR code with your authenticator app
6. Enter two consecutive MFA codes
7. Click **Assign MFA**

### Step 2: Create IAM Admin User (DON'T USE ROOT ACCOUNT!)

**Why:** Root account should only be used for account management, not daily operations

1. Go to IAM Console: https://console.aws.amazon.com/iam/
2. Click **Users** → **Add users**
3. User details:
   - User name: `pgni-admin`
   - AWS credential type: ✓ Access key + ✓ Password
4. Set permissions:
   - **Attach policies directly**
   - Select: `AdministratorAccess`
5. Review and create user
6. **IMPORTANT:** Download credentials CSV file (keep it safe!)
7. Enable MFA for this user too

### Step 3: Create Programmatic Access Keys

**For GitHub Actions CI/CD:**

1. In IAM Console, select user `pgni-admin`
2. Go to **Security credentials** tab
3. Under "Access keys", click **Create access key**
4. Choose use case: **Command Line Interface (CLI)**
5. Check "I understand" and click **Next**
6. Add description: "GitHub Actions CI/CD"
7. Click **Create access key**
8. **CRITICAL:** Copy both:
   - Access key ID (starts with AKIA...)
   - Secret access key (shown only once!)
9. Store these securely - you'll need them for GitHub Secrets

---

## Part 3: Set Up AWS Resources

### Step 1: Create EC2 Key Pair (for SSH access)

1. Go to EC2 Console: https://console.aws.amazon.com/ec2/
2. Select region: **Asia Pacific (Mumbai) - ap-south-1**
3. Left menu: **Network & Security** → **Key Pairs**
4. Click **Create key pair**
5. Details:
   - Name: `pgni-production-key`
   - Key pair type: **RSA**
   - Private key format: **pem** (for Windows, use .ppk for PuTTY)
6. Click **Create key pair**
7. **IMPORTANT:** Save the .pem file securely (you can't download it again!)
8. Repeat for pre-production:
   - Name: `pgni-preprod-key`

### Step 2: Choose Region

**Recommended for India:** `ap-south-1` (Asia Pacific - Mumbai)

**Why Mumbai?**
- Lowest latency for Indian users
- All services available
- Compliance with data residency requirements

### Step 3: Review Service Limits

1. Go to Service Quotas: https://console.aws.amazon.com/servicequotas/
2. Check limits for:
   - EC2: Running instances
   - RDS: DB instances
   - S3: Buckets
   - Elastic IPs

---

## Part 4: Cost Management Setup

### Step 1: Set Up Billing Alerts

1. Go to Billing Console: https://console.aws.amazon.com/billing/
2. Left menu: **Billing preferences**
3. Enable:
   - ✓ Receive Free Tier Usage Alerts
   - ✓ Receive Billing Alerts
4. Enter email address
5. Save preferences

### Step 2: Create Budget Alerts

1. Go to AWS Budgets: https://console.aws.amazon.com/billing/home#/budgets
2. Click **Create budget**
3. Budget type: **Cost budget**
4. Budget details:
   - Name: `PGNi-Monthly-Budget`
   - Period: Monthly
   - Budget amount: ₹3,000 (or your limit)
5. Set alerts:
   - Alert 1: 50% of budgeted amount
   - Alert 2: 80% of budgeted amount
   - Alert 3: 100% of budgeted amount
6. Enter email for notifications
7. Create budget

### Step 3: Enable Cost Explorer

1. In Billing Console, go to **Cost Explorer**
2. Click **Enable Cost Explorer**
3. Wait 24 hours for data to populate

---

## Part 5: Pre-Deployment Checklist

Before deploying PGNi, complete these tasks:

### ✓ Account Setup
- [ ] AWS account created and activated
- [ ] Root account MFA enabled
- [ ] IAM admin user created with MFA
- [ ] Programmatic access keys created and saved
- [ ] Billing alerts configured
- [ ] Budget alerts configured

### ✓ Security Configuration
- [ ] EC2 key pairs created (production + pre-production)
- [ ] Keys stored securely
- [ ] Region selected (ap-south-1 recommended)
- [ ] Password policy configured in IAM

### ✓ GitHub Configuration
- [ ] GitHub repository secrets configured:
  - [ ] AWS_ACCESS_KEY_ID
  - [ ] AWS_SECRET_ACCESS_KEY
  - [ ] PREPROD_SSH_KEY (will be added after EC2 creation)
  - [ ] PREPROD_HOST (will be added after EC2 creation)
  - [ ] PRODUCTION_SSH_KEY (will be added after EC2 creation)
  - [ ] PRODUCTION_HOST (will be added after EC2 creation)

### ✓ Pre-Deployment Preparation
- [ ] Review PRE_DEPLOYMENT_CHECKLIST.md
- [ ] Prepare environment variables for production
- [ ] Database credentials ready
- [ ] API keys ready (Razorpay, etc.)
- [ ] S3 bucket name decided
- [ ] Domain name ready (optional but recommended)

---

## Part 6: Estimated Monthly Costs

### Free Tier (First 12 Months)
**If you stay within limits: ₹0-500/month**

| Service | Free Tier | Typical Usage | Cost |
|---------|-----------|---------------|------|
| EC2 (t2.micro) | 750 hrs/month | 2 instances × 730 hrs | Free |
| RDS (t2.micro) | 750 hrs/month | 1 instance × 730 hrs | Free |
| S3 | 5 GB storage | 2-3 GB | Free |
| Data Transfer | 15 GB/month | 10 GB | Free |
| **Total** | | | **₹0-500** |

### After Free Tier (Month 13+)
**Estimated: ₹2,500-3,500/month**

| Service | Configuration | Monthly Cost (INR) |
|---------|--------------|-------------------|
| EC2 Pre-Prod | t3.micro (1 instance) | ₹600 |
| EC2 Production | t3.small (1 instance) | ₹1,200 |
| RDS MySQL | db.t3.micro | ₹900 |
| S3 Storage | 10 GB + requests | ₹150 |
| Data Transfer | 20 GB/month | ₹200 |
| Elastic IP | 1 IP | ₹50 |
| **Total** | | **₹3,100** |

**Cost Optimization Tips:**
- Use reserved instances (save 30-40%)
- Stop pre-prod instances when not in use
- Use S3 lifecycle policies
- Enable auto-scaling (scale down during low traffic)

---

## Part 7: Next Steps After Account Setup

Once your AWS account is ready:

1. **Install AWS CLI** (for local management):
   ```powershell
   # Install AWS CLI
   winget install Amazon.AWSCLI
   
   # Configure AWS CLI
   aws configure
   # Enter: Access Key ID, Secret Access Key, Region (ap-south-1), Output format (json)
   ```

2. **Configure GitHub Secrets:**
   - Go to: https://github.com/siddam01/pgni/settings/secrets/actions
   - Add AWS credentials (from IAM user)

3. **Follow Deployment Guide:**
   - Read: `DEPLOY_TO_AWS.md`
   - Complete: `PRE_DEPLOYMENT_CHECKLIST.md`

4. **Create Develop Branch:**
   ```bash
   git checkout -b develop
   git push -u origin develop
   ```

5. **Deploy to Pre-Production:**
   - Follow steps in `DEPLOY_TO_AWS.md`
   - Test thoroughly

6. **Deploy to Production:**
   - Merge develop → main
   - Approve deployment in GitHub Actions

---

## Part 8: Important AWS Services for PGNi

### Services You'll Use:

1. **EC2 (Elastic Compute Cloud)**
   - Virtual servers for running Go API
   - Pre-production: 1 instance
   - Production: 1-2 instances

2. **RDS (Relational Database Service)**
   - Managed MySQL database
   - Automated backups
   - High availability

3. **S3 (Simple Storage Service)**
   - File storage (receipts, documents)
   - Static assets
   - Backups

4. **VPC (Virtual Private Cloud)**
   - Network isolation
   - Security groups
   - Subnet configuration

5. **CloudWatch**
   - Monitoring and logging
   - Alerts and notifications

6. **IAM (Identity and Access Management)**
   - User and permission management
   - Access control

---

## Part 9: Support and Help

### AWS Support Resources:

1. **AWS Free Tier Usage:**
   - Monitor: https://console.aws.amazon.com/billing/home#/freetier

2. **AWS Documentation:**
   - Getting Started: https://aws.amazon.com/getting-started/

3. **AWS Support:**
   - Basic Support: Included (free)
   - Forum: https://forums.aws.amazon.com/

4. **AWS India Contact:**
   - Phone: 1800-572-4555 (toll-free)
   - Email: aws-india-support@amazon.com

5. **Cost Optimization:**
   - AWS Cost Calculator: https://calculator.aws/
   - AWS Pricing: https://aws.amazon.com/pricing/

---

## Part 10: Common Issues and Solutions

### Issue 1: Account Verification Pending
**Solution:** Wait 24 hours. If still pending, contact AWS support.

### Issue 2: Can't Create Resources
**Solution:** Check service limits in Service Quotas console.

### Issue 3: Credit Card Declined
**Solution:** Use international payment enabled card or try another card.

### Issue 4: Free Tier Exceeded
**Solution:** Monitor usage in Free Tier dashboard. Stop unused resources.

---

## Quick Reference: AWS Account Details to Save

Create a secure document with these details:

```
AWS Account Information:
========================
Account ID: _____________ (12-digit number)
Root Email: _____________
IAM Admin Username: pgni-admin
IAM Admin Password: _____________ (secure)
MFA Device: _____________ (app name)

Access Keys:
============
Access Key ID: AKIA____________
Secret Access Key: _____________ (never share!)

EC2 Key Pairs:
==============
Pre-production: pgni-preprod-key.pem
Production: pgni-production-key.pem
Location: _____________ (secure location)

Region: ap-south-1 (Mumbai)

GitHub Repository:
==================
URL: https://github.com/siddam01/pgni
Status: Private
```

**Keep this information SECURE and CONFIDENTIAL!**

---

## Timeline for Complete Setup

| Task | Time Required |
|------|---------------|
| AWS account creation | 15-30 minutes |
| Account verification | 5-10 minutes |
| Security setup (MFA, IAM) | 20-30 minutes |
| Resource setup (keys, budgets) | 15-20 minutes |
| Install AWS CLI | 10 minutes |
| Configure GitHub Secrets | 10 minutes |
| **Total Time** | **1.5-2 hours** |

---

## Ready to Deploy?

Once you've completed this guide:

1. ✅ AWS account is set up and secured
2. ✅ Billing alerts are configured
3. ✅ IAM users and access keys are created
4. ✅ EC2 key pairs are generated
5. ✅ GitHub secrets are configured

**Next Step:** Open `DEPLOY_TO_AWS.md` and start deploying! 🚀

---

## Need Help?

If you encounter any issues:
1. Check AWS documentation
2. Review error messages in AWS Console
3. Check billing alerts
4. Contact AWS support (24/7 available)

**Remember:** AWS Free Tier gives you 12 months to explore and learn. Take your time to understand each service before deploying to production.

---

*Last Updated: October 2025*
*For: PGNi Application Deployment*

