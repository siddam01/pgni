# PGNi Deployment Roadmap

## Your Step-by-Step Journey from Zero to Production

---

## Phase 1: AWS Account Setup (Today - 2 hours)

### What You Need:
- Valid email address
- Credit/debit card (for verification only)
- Phone number for verification
- Mobile phone with authenticator app (Google Authenticator/Authy)

### Steps:

**Step 1: Create AWS Account (30 minutes)**
- [ ] Go to https://aws.amazon.com/
- [ ] Click "Create an AWS Account"
- [ ] Enter email, password, account name
- [ ] Fill in contact information (use business address)
- [ ] Add payment method (₹2 verification charge, refunded)
- [ ] Complete phone verification
- [ ] Choose "Basic Support - Free"
- [ ] Wait for account activation email

**Step 2: Secure Your Account (30 minutes)**
- [ ] Enable MFA on root account
- [ ] Create IAM admin user: `pgni-admin`
- [ ] Enable MFA on admin user
- [ ] Create access keys for programmatic access
- [ ] **SAVE credentials securely!**

**Step 3: Cost Management (20 minutes)**
- [ ] Set up billing alerts
- [ ] Create budget: ₹3,000/month
- [ ] Enable Cost Explorer
- [ ] Review Free Tier dashboard

**Step 4: Create Resources (30 minutes)**
- [ ] Select region: ap-south-1 (Mumbai)
- [ ] Create EC2 key pair: `pgni-preprod-key`
- [ ] Create EC2 key pair: `pgni-production-key`
- [ ] **SAVE .pem files securely!**

**Step 5: Install Tools (10 minutes)**
```powershell
# Install AWS CLI
winget install Amazon.AWSCLI

# Configure AWS CLI
aws configure
# Enter: Access Key, Secret Key, Region: ap-south-1, Format: json
```

**Reference Guide:** `AWS_ACCOUNT_SETUP.md`

---

## Phase 2: GitHub Configuration (30 minutes)

**Step 1: Configure Repository Secrets**
- [ ] Go to: https://github.com/siddam01/pgni/settings/secrets/actions
- [ ] Add `AWS_ACCESS_KEY_ID` (from IAM user)
- [ ] Add `AWS_SECRET_ACCESS_KEY` (from IAM user)

**Step 2: Create Environments**
- [ ] Go to: https://github.com/siddam01/pgni/settings/environments
- [ ] Create environment: `pre-production`
  - No approval required
- [ ] Create environment: `production`
  - **Require approval** ✓
  - Add yourself as reviewer

**Step 3: Create Develop Branch**
```bash
cd C:\MyFolder\Mytest\pgworld-master
git checkout -b develop
git push -u origin develop
```

**Reference Guide:** `GITHUB_SETUP_GUIDE.md`

---

## Phase 3: Pre-Deployment Preparation (1 hour)

**Step 1: Environment Variables Preparation**

Create a secure document with these values:

```env
# Database Configuration
DB_USER=pgni_admin
DB_PASSWORD=<generate-strong-password>
DB_NAME=pgnidb
DB_HOST=<will-get-after-RDS-creation>
DB_PORT=3306

# API Configuration
PORT=8080
test=false

# API Keys
ANDROID_LIVE_KEY=<your-android-live-key>
ANDROID_TEST_KEY=<your-android-test-key>
IOS_LIVE_KEY=<your-ios-live-key>
IOS_TEST_KEY=<your-ios-test-key>

# Razorpay Credentials
RAZORPAY_KEY_ID=<your-razorpay-key>
RAZORPAY_KEY_SECRET=<your-razorpay-secret>

# AWS S3 Configuration
AWS_REGION=ap-south-1
S3_BUCKET_NAME=pgni-uploads-prod
AWS_ACCESS_KEY_ID=<from-IAM-user>
AWS_SECRET_ACCESS_KEY=<from-IAM-user>
```

**Step 2: Generate Strong Passwords**
```powershell
# Generate strong database password
-join ((33..126) | Get-Random -Count 20 | ForEach-Object {[char]$_})
```

**Step 3: Review Checklist**
- [ ] Open `PRE_DEPLOYMENT_CHECKLIST.md`
- [ ] Review all 75+ items
- [ ] Mark completed items

---

## Phase 4: Deploy Pre-Production (2-3 hours)

**Step 1: Create RDS Database**
- [ ] Go to RDS Console
- [ ] Create MySQL database
- [ ] Instance: db.t3.micro (free tier)
- [ ] Database name: `pgnidb_preprod`
- [ ] **Save endpoint URL**

**Step 2: Create S3 Bucket**
- [ ] Go to S3 Console
- [ ] Create bucket: `pgni-uploads-preprod`
- [ ] Region: ap-south-1
- [ ] Block public access: OFF (for uploads)
- [ ] Enable versioning

**Step 3: Create EC2 Instance**
- [ ] Go to EC2 Console
- [ ] Launch instance
- [ ] AMI: Ubuntu Server 22.04 LTS
- [ ] Instance type: t3.micro (free tier)
- [ ] Key pair: `pgni-preprod-key`
- [ ] Security group: Allow ports 22 (SSH), 8080 (API), 443 (HTTPS)
- [ ] **Save public IP address**

**Step 4: Configure EC2 Instance**
```bash
# SSH into instance
ssh -i "pgni-preprod-key.pem" ubuntu@<EC2-PUBLIC-IP>

# Install Go
wget https://go.dev/dl/go1.21.5.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.21.5.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
source ~/.bashrc

# Install MySQL client
sudo apt update
sudo apt install mysql-client -y

# Test database connection
mysql -h <RDS-ENDPOINT> -u pgni_admin -p
```

**Step 5: Add GitHub Secrets (for SSH)**
- [ ] Convert .pem to base64:
  ```powershell
  $pemContent = Get-Content "pgni-preprod-key.pem" -Raw
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($pemContent)
  [Convert]::ToBase64String($bytes)
  ```
- [ ] Add to GitHub Secrets:
  - `PREPROD_SSH_KEY` = <base64-encoded-key>
  - `PREPROD_HOST` = <EC2-PUBLIC-IP>

**Step 6: Push to Develop Branch**
```bash
git checkout develop
git add .
git commit -m "Configure pre-production deployment"
git push
```

**Step 7: Monitor Deployment**
- [ ] Go to: https://github.com/siddam01/pgni/actions
- [ ] Watch workflow execution
- [ ] Check logs for errors

**Step 8: Test Pre-Production**
- [ ] API health check: `http://<EC2-IP>:8080/`
- [ ] Test login API
- [ ] Test file upload
- [ ] Check database entries

**Reference Guide:** `DEPLOY_TO_AWS.md` (Sections 1-6)

---

## Phase 5: Deploy Production (2-3 hours)

**Step 1: Create Production Resources**
- [ ] RDS: `pgnidb_prod` (db.t3.micro)
- [ ] S3: `pgni-uploads-prod`
- [ ] EC2: t3.small instance (better performance)
- [ ] Key pair: `pgni-production-key`

**Step 2: Configure Production Security**
- [ ] Enable RDS encryption
- [ ] Enable S3 versioning
- [ ] Configure VPC security groups
- [ ] Set up CloudWatch alarms
- [ ] Enable automated backups

**Step 3: Add Production GitHub Secrets**
- [ ] `PRODUCTION_SSH_KEY` (base64-encoded)
- [ ] `PRODUCTION_HOST` (EC2 public IP)
- [ ] Update environment variables for production

**Step 4: Deploy to Production**
```bash
# Merge develop to main (creates deployment)
git checkout main
git merge develop
git push
```

**Step 5: Approve Production Deployment**
- [ ] Go to: https://github.com/siddam01/pgni/actions
- [ ] Review deployment request
- [ ] **Approve deployment**
- [ ] Monitor deployment logs

**Step 6: Post-Deployment Verification**
- [ ] API health check
- [ ] Test all APIs
- [ ] Load test (simulate 100+ users)
- [ ] Check database performance
- [ ] Verify file uploads to S3
- [ ] Check CloudWatch metrics

**Reference Guide:** `DEPLOY_TO_AWS.md` (Sections 7-10)

---

## Phase 6: Mobile App Deployment (1-2 days)

**Step 1: Update API Endpoints**
- [ ] Admin app: Update API URL to production
- [ ] Tenant app: Update API URL to production

**Step 2: Build APKs/IPAs**
```bash
# Admin app
cd pgworld-master
flutter build apk --release
flutter build appbundle --release  # For Play Store
flutter build ios --release        # For App Store

# Tenant app
cd pgworldtenant-master
flutter build apk --release
flutter build appbundle --release
flutter build ios --release
```

**Step 3: Test Builds**
- [ ] Install APK on physical device
- [ ] Test all features
- [ ] Test payments (Razorpay)
- [ ] Test file uploads
- [ ] Performance testing

**Step 4: Play Store Submission (Admin App)**
- [ ] Create Google Play Console account
- [ ] App name: **PGNi Admin**
- [ ] Package: `com.mani.pgni`
- [ ] Upload screenshots
- [ ] Write description
- [ ] Set pricing: Free
- [ ] Submit for review

**Step 5: Play Store Submission (Tenant App)**
- [ ] App name: **PGNi**
- [ ] Package: `com.mani.pgnitenant`
- [ ] Upload screenshots
- [ ] Write description
- [ ] Set pricing: Free
- [ ] Submit for review

**Step 6: iOS App Store Submission**
- [ ] Create Apple Developer account ($99/year)
- [ ] Configure signing certificates
- [ ] Submit both apps for review

**Timeline:** 2-7 days for review approval

---

## Phase 7: Monitoring and Maintenance (Ongoing)

**Daily Tasks:**
- [ ] Check CloudWatch alarms
- [ ] Review error logs
- [ ] Monitor API performance
- [ ] Check database queries

**Weekly Tasks:**
- [ ] Review AWS costs
- [ ] Check free tier usage
- [ ] Review security logs
- [ ] Update dependencies

**Monthly Tasks:**
- [ ] Database backup verification
- [ ] Security audit
- [ ] Performance optimization
- [ ] Cost optimization review

**Tools to Use:**
- AWS CloudWatch (monitoring)
- AWS Cost Explorer (cost analysis)
- AWS Trusted Advisor (recommendations)
- GitHub Actions (automated deployments)

---

## Complete Timeline

| Phase | Duration | Cost |
|-------|----------|------|
| AWS Account Setup | 2 hours | ₹0 |
| GitHub Configuration | 30 mins | ₹0 |
| Pre-Deployment Prep | 1 hour | ₹0 |
| Pre-Production Deploy | 2-3 hours | ₹0 (free tier) |
| Production Deploy | 2-3 hours | ₹0 (free tier) |
| Mobile App Deploy | 1-2 days | Play Console: $25 |
| **Total Initial Setup** | **1-2 days** | **$25** |
| | | |
| **Monthly Costs (Year 1)** | | ₹0-500 (free tier) |
| **Monthly Costs (Year 2+)** | | ₹2,500-3,500 |

---

## Cost Breakdown

### First 12 Months (Free Tier)
- EC2: 750 hours/month = FREE
- RDS: 750 hours/month = FREE
- S3: 5 GB = FREE
- Data Transfer: 15 GB = FREE
- **Total: ₹0-500/month**

### After Free Tier (Month 13+)
- EC2 Pre-Prod (t3.micro): ₹600
- EC2 Production (t3.small): ₹1,200
- RDS (db.t3.micro): ₹900
- S3 (10 GB): ₹150
- Data Transfer: ₹200
- **Total: ₹3,050/month**

**Cost Optimization:**
- Stop pre-prod during off-hours: Save ₹400/month
- Use reserved instances: Save 30%
- Auto-scaling: Scale down during low traffic

---

## Emergency Contacts

**AWS Support:**
- Phone: 1800-572-4555 (India, toll-free)
- Console: https://console.aws.amazon.com/support/

**GitHub Support:**
- Help: https://support.github.com/

**Domain Issues:**
- GoDaddy: 1800-123-8946
- Cloudflare: https://support.cloudflare.com/

---

## Success Metrics

After deployment, track these metrics:

**Technical Metrics:**
- API response time: < 200ms
- Uptime: > 99.5%
- Database query time: < 50ms
- Error rate: < 0.1%

**Business Metrics:**
- Number of PG registrations
- Number of tenant registrations
- Payment success rate
- User retention rate

**Cost Metrics:**
- Monthly AWS bill
- Cost per user
- Cost per transaction

---

## Your Current Status

✅ **Completed:**
- [x] Application developed
- [x] Security improvements implemented
- [x] App names changed to PGNi
- [x] Package names updated
- [x] GitHub repository created (private)
- [x] CI/CD pipeline configured
- [x] Documentation cleaned up

⏳ **Next Steps:**
1. Create AWS account (2 hours)
2. Configure GitHub secrets (30 mins)
3. Deploy to pre-production (3 hours)
4. Deploy to production (3 hours)
5. Submit apps to stores (1-2 days)

🎯 **Goal:** Production deployment within 2-3 days!

---

## Quick Links

**Documentation:**
- AWS Account Setup: `AWS_ACCOUNT_SETUP.md`
- AWS Deployment: `DEPLOY_TO_AWS.md`
- Pre-Deployment Checklist: `PRE_DEPLOYMENT_CHECKLIST.md`
- GitHub Setup: `GITHUB_SETUP_GUIDE.md`
- Main README: `README.md`

**Online Resources:**
- AWS Console: https://console.aws.amazon.com/
- GitHub Repository: https://github.com/siddam01/pgni
- AWS Free Tier: https://aws.amazon.com/free/

---

## Need Help?

If you get stuck at any phase:
1. Check the specific guide for that phase
2. Review error messages carefully
3. Check AWS documentation
4. Contact AWS support (24/7)

**Remember:** Take it one phase at a time. You don't need to rush!

---

*Your journey to production starts with AWS account creation. Good luck! 🚀*

