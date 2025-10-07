# How to Deploy Pre-Production Environment

## Overview

I've created an **automated deployment script** that will create all AWS resources for you:
- ✅ Security Group
- ✅ RDS MySQL Database
- ✅ S3 Bucket
- ✅ EC2 Instance
- ✅ Complete configuration

---

## Prerequisites

Before running the deployment script, make sure you have:

1. **AWS Account Setup Complete:**
   - [x] Root account MFA enabled
   - [x] IAM admin user created (`pgni-admin`)
   - [x] Access keys created and saved
   - [x] Billing alerts configured
   - [x] AWS CLI installed and configured

2. **EC2 Key Pair Created:**
   - [x] Key pair named: `pgni-preprod-key`
   - [x] Saved to: `C:\AWS-Keys\pgni-preprod-key.pem`

3. **AWS CLI Configured:**
   ```powershell
   aws configure
   # Enter your Access Key ID
   # Enter your Secret Access Key
   # Region: ap-south-1
   # Output: json
   ```

4. **Test AWS Connection:**
   ```powershell
   aws sts get-caller-identity
   ```
   Should show your account details.

---

## Option 1: Quick Deployment (Automated)

### Step 1: Open PowerShell as Administrator

Right-click PowerShell → Run as Administrator

### Step 2: Navigate to Project Directory

```powershell
cd C:\MyFolder\Mytest\pgworld-master
```

### Step 3: Run Deployment Script

**If AWS CLI is already configured:**
```powershell
.\deploy-preprod.ps1
```

**If you want to provide credentials manually:**
```powershell
.\deploy-preprod.ps1 -AwsAccessKeyId "YOUR_ACCESS_KEY" -AwsSecretAccessKey "YOUR_SECRET_KEY"
```

**With custom database password:**
```powershell
.\deploy-preprod.ps1 -DbPassword "YourSecurePassword123!"
```

### Step 4: Wait for Completion

The script will:
1. Create Security Group (~30 seconds)
2. Create RDS Database (~5-10 minutes) ⏰
3. Create S3 Bucket (~1 minute)
4. Launch EC2 Instance (~2-3 minutes)
5. Generate deployment report

**Total Time:** ~15-20 minutes

### Step 5: Review Deployment Report

The script will generate:
- `PREPROD_DEPLOYMENT_REPORT.md` - Complete deployment details
- `preprod.env` - Environment variables configuration
- `deployment-preprod-XXXXXXXX.log` - Full deployment log

---

## Option 2: Manual Deployment (Step by Step)

If you prefer to create resources manually, follow: `DEPLOY_TO_AWS.md`

---

## What the Script Creates

### 1. Security Group
- Allows SSH (port 22)
- Allows HTTP (port 80)
- Allows HTTPS (port 443)
- Allows API (port 8080)
- Allows MySQL (port 3306)

### 2. RDS MySQL Database
- Instance: db.t3.micro (FREE TIER)
- Engine: MySQL 8.0
- Storage: 20 GB
- Backup: 7 days retention
- Public access: Enabled
- Database name: `pgnidb`
- Username: `pgni_admin`
- Password: Auto-generated (saved in report)

### 3. S3 Bucket
- Versioning enabled
- CORS configured
- For file uploads (receipts, documents)

### 4. EC2 Instance
- Instance: t3.micro (FREE TIER)
- OS: Ubuntu 22.04 LTS
- Pre-configured with:
  - Go 1.21.5
  - MySQL client
  - AWS CLI
  - Systemd service for API

---

## After Deployment

Once the script completes, you need to:

### 1. Update API Keys

Edit `preprod.env` and add your actual credentials:
```env
ANDROID_LIVE_KEY=your-actual-android-live-key
ANDROID_TEST_KEY=your-actual-android-test-key
IOS_LIVE_KEY=your-actual-ios-live-key
IOS_TEST_KEY=your-actual-ios-test-key
RAZORPAY_KEY_ID=your-actual-razorpay-key-id
RAZORPAY_KEY_SECRET=your-actual-razorpay-key-secret
```

### 2. Configure GitHub Secrets

The deployment report will show you the exact commands.

**Add PREPROD_SSH_KEY:**
```powershell
$pemContent = Get-Content "C:\AWS-Keys\pgni-preprod-key.pem" -Raw
$bytes = [System.Text.Encoding]::UTF8.GetBytes($pemContent)
[Convert]::ToBase64String($bytes) | clip
```
Then add to GitHub secrets.

**Add PREPROD_HOST:**
Use the EC2 Public IP from the deployment report.

### 3. Build and Deploy API

```powershell
# Build API
cd pgworld-api-master
$env:CGO_ENABLED=0
$env:GOOS="linux"
$env:GOARCH="amd64"
go build -o pgworld-api .

# Get EC2 IP from deployment report
$EC2_IP = "YOUR_EC2_PUBLIC_IP"

# Copy to EC2
scp -i "C:\AWS-Keys\pgni-preprod-key.pem" pgworld-api ubuntu@${EC2_IP}:/tmp/
scp -i "C:\AWS-Keys\pgni-preprod-key.pem" ../preprod.env ubuntu@${EC2_IP}:/tmp/.env

# SSH to EC2
ssh -i "C:\AWS-Keys\pgni-preprod-key.pem" ubuntu@${EC2_IP}

# On EC2, run:
sudo mv /tmp/pgworld-api /opt/pgworld/pgworld-api
sudo mv /tmp/.env /opt/pgworld/.env
sudo chmod +x /opt/pgworld/pgworld-api
sudo systemctl start pgworld-api
sudo systemctl status pgworld-api
```

### 4. Initialize Database

```bash
# Connect to RDS
mysql -h YOUR_RDS_ENDPOINT -u pgni_admin -p YOUR_DB_PASSWORD pgnidb

# Run your schema
# Your application will auto-create tables
```

### 5. Test API

```powershell
# Health check
curl http://YOUR_EC2_IP:8080/

# Should return: "ok"
```

---

## Troubleshooting

### Script Fails with "AWS CLI not installed"
```powershell
winget install Amazon.AWSCLI
# Close and reopen PowerShell
```

### Script Fails with "Cannot connect to AWS"
```powershell
# Configure AWS CLI
aws configure
# Enter your credentials
```

### EC2 Key Pair Not Found
```bash
# Go to EC2 Console
# Network & Security → Key Pairs
# Create key pair: pgni-preprod-key
# Download and save to C:\AWS-Keys\
```

### Security Group Already Exists
The script will use the existing security group. This is fine.

### RDS Already Exists
The script will use the existing RDS instance. This is fine.

### Script Takes Too Long
- Creating RDS takes 5-10 minutes (this is normal)
- Wait for "RDS instance is ready!" message
- Do not interrupt the script

---

## Cost Information

### Free Tier (First 12 Months)
All resources created are within free tier limits:
- EC2 t3.micro: 750 hours/month FREE
- RDS db.t3.micro: 750 hours/month FREE
- S3 storage < 5GB: FREE
- Data transfer < 15GB: FREE

**Expected Cost:** ₹0-500/month

### Monitoring Costs
- Check Free Tier: https://console.aws.amazon.com/billing/home#/freetier
- Your budget alerts will notify you if approaching limits

---

## Security Best Practices

### After Deployment:

1. **Restrict SSH Access:**
   ```bash
   # In AWS Console, edit security group
   # Change SSH rule from 0.0.0.0/0 to your IP only
   ```

2. **Update Default Passwords:**
   - Database password (auto-generated, save it!)
   - Add your actual API keys

3. **Enable CloudWatch Logs:**
   - Monitor API logs
   - Set up alarms for errors

4. **Regular Backups:**
   - RDS automated backups: Enabled (7 days)
   - Manual snapshots: Create weekly

---

## Getting Help

### If Deployment Fails:

1. **Check the deployment log:**
   ```powershell
   Get-Content deployment-preprod-*.log | Select-Object -Last 50
   ```

2. **Verify Prerequisites:**
   - AWS CLI configured
   - EC2 key pair created
   - IAM permissions correct

3. **AWS Console:**
   - Check EC2: https://console.aws.amazon.com/ec2/
   - Check RDS: https://console.aws.amazon.com/rds/
   - Check S3: https://console.aws.amazon.com/s3/

4. **AWS Support:**
   - Phone: 1800-572-4555 (India)

---

## Ready to Deploy?

### Quick Checklist:

- [ ] AWS account setup complete
- [ ] AWS CLI installed and configured
- [ ] EC2 key pair created: `pgni-preprod-key`
- [ ] Key saved to: `C:\AWS-Keys\pgni-preprod-key.pem`
- [ ] Tested AWS connection: `aws sts get-caller-identity`

### Run Deployment:

```powershell
cd C:\MyFolder\Mytest\pgworld-master
.\deploy-preprod.ps1
```

### Then:

1. Wait 15-20 minutes for completion
2. Open `PREPROD_DEPLOYMENT_REPORT.md`
3. Save all credentials securely
4. Follow "After Deployment" steps
5. Test API
6. You're live in pre-production! 🎉

---

## What's Next?

After pre-production is working:

1. **Test Thoroughly:**
   - Test all API endpoints
   - Test Flutter apps
   - Test file uploads
   - Test payments

2. **Deploy to Production:**
   - Use `deploy-prod.ps1` (coming soon)
   - Similar process with production keys

3. **Submit Apps to Play Store:**
   - Build release APKs
   - Submit for review

---

**Need help? I'm here to assist! Just ask!** 😊

*Last Updated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")*

