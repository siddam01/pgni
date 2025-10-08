# Complete Step-by-Step Deployment Guide
## From Zero to Live Production in AWS

---

## 🎯 Overview

You'll complete 3 main phases:
1. **AWS Account Setup** (30 minutes, one-time)
2. **Pre-Production Deployment** (20 minutes, automated)
3. **Production Deployment** (20 minutes, automated)

**Total Time:** ~70 minutes to go from nothing to live production!

---

## 📋 Phase 1: AWS Account Setup (If Not Done)

### Step 1.1: Create AWS Account

1. **Go to:** https://aws.amazon.com
2. **Click:** "Create an AWS Account"
3. **Provide:**
   - Email: `siddammani95@gmail.com`
   - Account name: `PGNi`
   - Password: (create strong password)
4. **Choose:** Personal account
5. **Enter:** Payment details (credit/debit card)
   - *Note: Won't be charged if staying in free tier*
6. **Verify:** Phone number
7. **Select:** Free tier plan

**✅ Result:** AWS account created!

---

### Step 1.2: Set Up Billing Alerts (Important!)

1. **Go to:** AWS Console → Billing Dashboard
2. **Click:** "Billing preferences"
3. **Enable:**
   - ✅ Receive Free Tier Usage Alerts
   - ✅ Receive Billing Alerts
4. **Email:** `siddammani95@gmail.com`
5. **Save preferences**

6. **Create Budget Alert:**
   - Go to: Budgets → Create budget
   - Type: Cost budget
   - Amount: $10 USD
   - Alert at: 80% ($8)
   - Email: `siddammani95@gmail.com`

**✅ Result:** You'll be notified if costs approach $10!

---

### Step 1.3: Enable MFA (Security)

1. **Go to:** IAM → Users → Your user
2. **Click:** Security credentials tab
3. **Click:** "Assign MFA device"
4. **Choose:** Virtual MFA device
5. **Scan QR code** with Google Authenticator or similar app
6. **Enter** two consecutive MFA codes
7. **Activate**

**✅ Result:** Account secured with 2FA!

---

### Step 1.4: Create IAM User for Deployment

1. **Go to:** IAM → Users → Add users
2. **User name:** `pgni-deployer`
3. **Enable:** Access key - Programmatic access
4. **Permissions:** Attach policies directly
   - ✅ AmazonEC2FullAccess
   - ✅ AmazonRDSFullAccess
   - ✅ AmazonS3FullAccess
   - ✅ IAMFullAccess
   - ✅ AmazonSSMFullAccess
5. **Create user**
6. **IMPORTANT:** Download credentials CSV
   - Access Key ID
   - Secret Access Key
   - **Save this file securely!**

**✅ Result:** IAM user created with deployment permissions!

---

### Step 1.5: Configure AWS CLI on Your Computer

Open PowerShell and run:

```powershell
# Install AWS CLI (if not already installed)
winget install Amazon.AWSCLI

# Configure AWS credentials
aws configure
```

**Enter when prompted:**
```
AWS Access Key ID: [paste from CSV]
AWS Secret Access Key: [paste from CSV]
Default region name: us-east-1
Default output format: json
```

**Test configuration:**
```powershell
aws sts get-caller-identity
```

**✅ Result:** Should show your AWS account details!

---

## 📋 Phase 2: Deploy Pre-Production Environment

### Step 2.1: Open PowerShell in Project Directory

```powershell
cd C:\MyFolder\Mytest\pgworld-master
```

**✅ Verify:** You're in the correct directory

---

### Step 2.2: Run Pre-Production Deployment Script

```powershell
.\deploy-complete.ps1 -Environment preprod
```

**What happens:**
```
[1/10] Validating AWS credentials...              ✓
[2/10] Creating RDS MySQL database...             ⏳ 10-15 min
[3/10] Creating S3 bucket...                      ✓
[4/10] Creating EC2 instance...                   ⏳ 3-5 min
[5/10] Configuring security groups...             ✓
[6/10] Generating credentials...                  ✓
[7/10] Storing secrets in Parameter Store...      ✓
[8/10] Creating deployment documentation...       ✓
[9/10] Testing connectivity...                    ✓
[10/10] Generating deployment report...           ✓
```

**⏱️ Duration:** 15-20 minutes

**✅ Result:** Pre-production environment created!

---

### Step 2.3: Review Deployment Report

The script creates a folder:
```
deployment-preprod-20250108-143022/
```

**Open this file:**
```
DEPLOYMENT_REPORT_preprod_20250108-143022.md
```

**Contains:**
- ✅ RDS endpoint and credentials
- ✅ S3 bucket name
- ✅ EC2 public IP
- ✅ SSH commands
- ✅ Database connection strings
- ✅ All passwords and secrets
- ✅ Next steps

**✅ Keep this report safe!**

---

### Step 2.4: Deploy API to Pre-Production EC2

From the deployment report, copy the SSH command:

```powershell
# Connect to EC2 instance
ssh -i deployment-preprod-20250108-143022/preprod-key.pem ec2-user@<EC2_PUBLIC_IP>
```

**On EC2, run these commands:**

```bash
# Install Go
sudo yum update -y
sudo wget https://go.dev/dl/go1.21.0.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.21.0.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/bin/go/bin' >> ~/.bashrc
source ~/.bashrc

# Install Git
sudo yum install git -y

# Clone your repository
git clone https://github.com/siddam01/pgni.git
cd pgni/pgworld-api-master

# Create directory structure
sudo mkdir -p /opt/pgworld
sudo chown ec2-user:ec2-user /opt/pgworld

# Build API
go build -o /opt/pgworld/pgworld-api .

# Create environment file (copy from deployment report)
sudo nano /opt/pgworld/.env
# Paste the environment variables from preprod.env

# Create systemd service
sudo nano /etc/systemd/system/pgworld-api.service
```

**Paste this service configuration:**
```ini
[Unit]
Description=PGWorld API
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/opt/pgworld
EnvironmentFile=/opt/pgworld/.env
ExecStart=/opt/pgworld/pgworld-api
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

**Start the service:**
```bash
sudo systemctl daemon-reload
sudo systemctl enable pgworld-api
sudo systemctl start pgworld-api
sudo systemctl status pgworld-api
```

**Test API:**
```bash
curl http://localhost:8080/health
```

**✅ Result:** API running on pre-production!

---

### Step 2.5: Configure GitHub Secrets for CI/CD

1. **Go to:** https://github.com/siddam01/pgni/settings/secrets/actions

2. **Click:** "New repository secret"

3. **Add these secrets** (get values from deployment report):

   **AWS Credentials:**
   - Name: `AWS_ACCESS_KEY_ID`
   - Value: [from your AWS credentials]
   
   - Name: `AWS_SECRET_ACCESS_KEY`
   - Value: [from your AWS credentials]

   **Pre-Production:**
   - Name: `PREPROD_SSH_KEY`
   - Value: [content of preprod-key.pem file]
   
   - Name: `PREPROD_HOST`
   - Value: [EC2 public IP from report]

**✅ Result:** GitHub can now auto-deploy!

---

### Step 2.6: Create Develop Branch for Auto-Deployment

```powershell
# In your local project directory
cd C:\MyFolder\Mytest\pgworld-master

# Create develop branch
git checkout -b develop

# Push to GitHub
git push -u origin develop
```

**✅ Result:** Now any push to `develop` branch auto-deploys to pre-prod!

---

### Step 2.7: Test Auto-Deployment

Make a small change:

```powershell
# Edit a file (e.g., add a comment)
notepad pgworld-api-master\main.go

# Commit and push
git add .
git commit -m "Test auto-deployment"
git push
```

**Watch GitHub Actions:**
https://github.com/siddam01/pgni/actions

**You'll see:**
- ✅ Build and Test
- ✅ Deploy to Pre-Production

**✅ Result:** Auto-deployment working!

---

## 📋 Phase 3: Deploy Production Environment

### Step 3.1: Run Production Deployment Script

```powershell
cd C:\MyFolder\Mytest\pgworld-master

.\deploy-complete.ps1 -Environment production
```

**What happens:**
```
[1/10] Validating AWS credentials...              ✓
[2/10] Creating RDS MySQL database...             ⏳ 10-15 min
[3/10] Creating S3 bucket...                      ✓
[4/10] Creating EC2 instance...                   ⏳ 3-5 min
[5/10] Configuring security groups...             ✓
[6/10] Generating credentials...                  ✓
[7/10] Storing secrets in Parameter Store...      ✓
[8/10] Creating deployment documentation...       ✓
[9/10] Testing connectivity...                    ✓
[10/10] Generating deployment report...           ✓
```

**⏱️ Duration:** 15-20 minutes

**✅ Result:** Production environment created!

---

### Step 3.2: Review Production Deployment Report

Open:
```
deployment-production-20250108-153045/DEPLOYMENT_REPORT_production_20250108-153045.md
```

**✅ Save all credentials securely!**

---

### Step 3.3: Deploy API to Production EC2

```powershell
# Connect to production EC2
ssh -i deployment-production-20250108-153045/production-key.pem ec2-user@<PRODUCTION_EC2_IP>
```

**Repeat the same steps as pre-production:**
- Install Go and Git
- Clone repository
- Build API
- Create environment file
- Create systemd service
- Start service

**✅ Result:** API running on production!

---

### Step 3.4: Add Production GitHub Secrets

Go to: https://github.com/siddam01/pgni/settings/secrets/actions

**Add:**
- `PRODUCTION_SSH_KEY` - [production SSH key]
- `PRODUCTION_HOST` - [production EC2 IP]

**✅ Result:** GitHub can deploy to production!

---

### Step 3.5: Create Production Environment in GitHub

1. **Go to:** https://github.com/siddam01/pgni/settings/environments
2. **Click:** "New environment"
3. **Name:** `production`
4. **Enable:** Required reviewers
5. **Add yourself** as reviewer
6. **Save**

**✅ Result:** Production deployments require approval!

---

### Step 3.6: Test Production Deployment

```powershell
# Switch to main branch
git checkout main

# Merge develop into main
git merge develop

# Push to trigger production deployment
git push
```

**Watch GitHub Actions:**
- ✅ Build and Test
- ⏳ Deploy to Production - **Waiting for approval**
- **You approve**
- ✅ Deploy to Production - **Deployed!**

**✅ Result:** Production deployment working!

---

## 🎉 Phase 4: Update Flutter Apps

### Step 4.1: Update API Endpoints

**Admin App:**
```dart
// pgworld-master/lib/config.dart
const String API_BASE_URL = 'http://<PRODUCTION_EC2_IP>:8080';
```

**Tenant App:**
```dart
// pgworldtenant-master/lib/config.dart
const String API_BASE_URL = 'http://<PRODUCTION_EC2_IP>:8080';
```

---

### Step 4.2: Rebuild Flutter Apps

```powershell
# Admin App
cd C:\MyFolder\Mytest\pgworld-master
flutter clean
flutter pub get
flutter build apk --release

# Tenant App
cd C:\MyFolder\Mytest\pgworldtenant-master
flutter clean
flutter pub get
flutter build apk --release
```

**✅ Result:** Updated apps with production API!

---

## 📊 Summary of What You Created

### Pre-Production Environment:
- ✅ RDS MySQL (db.t3.micro) - FREE TIER
- ✅ S3 Bucket (versioned, CORS enabled)
- ✅ EC2 Instance (t3.micro) - FREE TIER
- ✅ Security Groups (configured)
- ✅ Auto-deployment from `develop` branch

**URL:** `http://<PREPROD_EC2_IP>:8080`

---

### Production Environment:
- ✅ RDS MySQL (db.t3.small)
- ✅ S3 Bucket (optimized, lifecycle rules)
- ✅ EC2 Instance (t3.small)
- ✅ Enhanced security & encryption
- ✅ 30-day backups
- ✅ Approval-gated deployment from `main` branch

**URL:** `http://<PRODUCTION_EC2_IP>:8080`

---

### CI/CD Pipeline:
- ✅ Auto-build on every push
- ✅ Auto-deploy to pre-prod from `develop`
- ✅ Approval-gated deploy to production from `main`
- ✅ Automatic rollback on failure

---

## 💰 Cost Breakdown

### First 12 Months (Free Tier):
- Pre-Production: **₹0 - ₹500/month**
- Production: **₹0 - ₹1,000/month**
- **Total: ₹0 - ₹1,500/month**

### After Free Tier:
- Pre-Production: **₹1,650/month**
- Production: **₹3,500/month**
- **Total: ₹5,150/month**

---

## 🔒 Security Checklist

- ✅ MFA enabled on AWS account
- ✅ IAM user (not root) for deployments
- ✅ Credentials stored in AWS Parameter Store
- ✅ SSH keys for EC2 access
- ✅ GitHub Secrets for CI/CD
- ✅ Security groups configured
- ✅ Database in private subnet (if VPC configured)
- ✅ Encrypted RDS backups

---

## 📱 Next Steps After Deployment

### For PG Owners (Your Users):
1. **Download:** Updated apps from Play Store
2. **Register:** Create account
3. **Add:** PG details
4. **Manage:** Rooms, tenants, payments

### For You (Admin):
1. **Monitor:** AWS costs via billing dashboard
2. **Test:** All features in production
3. **Promote:** App to PG owners
4. **Support:** Users as they onboard

---

## 🆘 Troubleshooting

### Issue: "AWS credentials not configured"
**Solution:**
```powershell
aws configure
# Re-enter credentials
```

### Issue: "Can't connect to EC2"
**Solution:**
```powershell
# Check security group allows SSH
aws ec2 describe-security-groups --group-ids <SG_ID>

# Add your IP if needed
aws ec2 authorize-security-group-ingress --group-id <SG_ID> --protocol tcp --port 22 --cidr <YOUR_IP>/32
```

### Issue: "API not starting on EC2"
**Solution:**
```bash
# Check logs
sudo journalctl -u pgworld-api -f

# Check if .env file exists
cat /opt/pgworld/.env

# Restart service
sudo systemctl restart pgworld-api
```

### Issue: "Database connection failed"
**Solution:**
```bash
# Test RDS connection
mysql -h <RDS_ENDPOINT> -u pgniuser -p

# Check security group allows MySQL (port 3306)
```

### Issue: "GitHub Actions deployment failing"
**Solution:**
1. Check GitHub Secrets are added correctly
2. Verify EC2 instance is running
3. Check SSH key permissions
4. Review GitHub Actions logs

---

## 📞 Support Resources

### AWS Documentation:
- EC2: https://docs.aws.amazon.com/ec2/
- RDS: https://docs.aws.amazon.com/rds/
- S3: https://docs.aws.amazon.com/s3/

### GitHub Actions:
- Docs: https://docs.github.com/actions

### Your Project Files:
- `START_DEPLOYMENT_NOW.md` - Quick start
- `COMPLETE_DEPLOYMENT_GUIDE.md` - Detailed guide
- `CI_CD_FIXED.md` - CI/CD troubleshooting
- Deployment reports in `deployment-*` folders

---

## ✅ Deployment Checklist

### AWS Account Setup:
- [ ] AWS account created
- [ ] Billing alerts configured
- [ ] MFA enabled
- [ ] IAM user created
- [ ] AWS CLI configured

### Pre-Production:
- [ ] Deployment script run
- [ ] RDS created
- [ ] S3 created
- [ ] EC2 created
- [ ] API deployed to EC2
- [ ] GitHub secrets added
- [ ] Develop branch created
- [ ] Auto-deployment tested

### Production:
- [ ] Deployment script run
- [ ] Production environment created
- [ ] API deployed to production EC2
- [ ] Production secrets added
- [ ] Environment protection configured
- [ ] Production deployment tested

### Flutter Apps:
- [ ] API endpoints updated
- [ ] Apps rebuilt
- [ ] Apps tested with production API

### Go Live:
- [ ] All features tested
- [ ] Performance verified
- [ ] Monitoring set up
- [ ] Documentation complete
- [ ] Users can access

---

## 🎯 Quick Command Reference

### Deploy Infrastructure:
```powershell
.\deploy-complete.ps1 -Environment preprod      # Pre-production
.\deploy-complete.ps1 -Environment production   # Production
```

### Git Workflow:
```bash
git checkout develop    # Work on pre-prod
git push                # Auto-deploys to pre-prod

git checkout main       # Release to prod
git merge develop       # Merge changes
git push                # Triggers approval-gated prod deploy
```

### Connect to EC2:
```bash
ssh -i <key-file>.pem ec2-user@<EC2_IP>
```

### Check API Status:
```bash
sudo systemctl status pgworld-api
sudo journalctl -u pgworld-api -f
```

### Database Connection:
```bash
mysql -h <RDS_ENDPOINT> -u pgniuser -p
```

---

## 🎉 Congratulations!

You now have:
- ✅ Complete AWS infrastructure
- ✅ Pre-production environment
- ✅ Production environment
- ✅ Full CI/CD automation
- ✅ Cost-optimized setup
- ✅ Complete documentation

**You're ready to go live!** 🚀

---

*Last Updated: January 8, 2025*
*Status: Complete and Production-Ready*

