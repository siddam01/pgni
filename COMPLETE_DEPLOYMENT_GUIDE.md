# Complete PGNi Deployment Guide
## Everything You Need - Fully Automated

---

## 🎯 What This Solution Provides

### ✅ Fully Automated:
- Creates ALL AWS infrastructure
- Generates ALL credentials securely
- Configures CI/CD pipeline (already done)
- Optimizes costs automatically
- Generates comprehensive documentation
- Provides complete access information

### 📦 What Gets Created:

#### Pre-Production Environment:
- RDS MySQL Database (db.t3.micro - FREE TIER)
- S3 Bucket for file uploads
- EC2 Instance (t3.micro - FREE TIER)
- Security Groups with proper rules
- All credentials and configurations

#### Production Environment:
- RDS MySQL Database (db.t3.small - Production grade)
- S3 Bucket with lifecycle policies
- EC2 Instance (t3.small - Production grade)
- Enhanced security and encryption
- 30-day backups
- All credentials and configurations

### 💰 Costs (Optimized):

**Free Tier (First 12 Months):**
- Pre-Production: ₹0-500/month
- Production: ₹0-1,000/month

**After Free Tier:**
- Pre-Production: ₹1,650/month
- Production: ₹3,500/month

---

## 🚀 Quick Start (2 Commands!)

###  Before You Start:

1. **Complete AWS Setup:**
   - Follow: `YOUR_AWS_SETUP_STEPS.md`
   - Create IAM admin user
   - Configure AWS CLI
   - Create EC2 key pairs

2. **Create EC2 Key Pairs:**
   ```bash
   # In AWS Console:
   # EC2 → Key Pairs → Create Key Pair
   
   Name: pgni-preprod-key
   Download to: C:\AWS-Keys\pgni-preprod-key.pem
   
   Name: pgni-production-key
   Download to: C:\AWS-Keys\pgni-production-key.pem
   ```

3. **Verify AWS CLI:**
   ```powershell
   aws sts get-caller-identity
   ```
   Should show your account.

### Deploy Pre-Production:

```powershell
cd C:\MyFolder\Mytest\pgworld-master
.\deploy-complete.ps1 -Environment preprod
```

**Wait 15-20 minutes.** Script will:
1. Create Security Group (30 sec)
2. Create RDS Database (5-10 min)
3. Create S3 Bucket (1 min)
4. Launch EC2 Instance (2-3 min)
5. Generate complete documentation

### Deploy Production:

```powershell
.\deploy-complete.ps1 -Environment production
```

Same process, production-grade resources.

---

## 📋 What You'll Get

After running the script, you'll have a folder: `deployment-{environment}-{timestamp}/`

### Files Created:

1. **DEPLOYMENT_REPORT_{environment}_{timestamp}.md**
   - Complete deployment details
   - All URLs and endpoints
   - All credentials
   - Step-by-step next steps
   - Troubleshooting guide

2. **CREDENTIALS_{environment}.txt**
   - All usernames and passwords
   - SSH commands
   - Database connection strings
   - S3 bucket names

3. **{environment}.env**
   - Environment variables
   - Ready to copy to EC2
   - Pre-configured

4. **deployment.log**
   - Complete deployment log
   - For troubleshooting

### Information Provided:

#### AWS Resources:
- ✅ EC2 Public IP Address
- ✅ RDS Database Endpoint
- ✅ S3 Bucket Name
- ✅ Security Group IDs
- ✅ Instance IDs

#### Credentials:
- ✅ Database username
- ✅ Database password (auto-generated secure)
- ✅ API keys (auto-generated)
- ✅ JWT secrets (auto-generated)

#### Access Commands:
- ✅ SSH command to EC2
- ✅ Database connection command
- ✅ S3 access commands
- ✅ API endpoint URLs

#### Documentation:
- ✅ Complete setup guide
- ✅ Deployment checklist
- ✅ Troubleshooting steps
- ✅ Cost estimates
- ✅ Security recommendations

---

## 📖 Detailed Workflow

### Step 1: Run Deployment Script

```powershell
.\deploy-complete.ps1 -Environment preprod
```

**What happens:**
```
================================================================
  PGNi Complete Deployment Automation
================================================================

✓ Checking prerequisites...
✓ Testing AWS connection...
✓ Generating credentials...

================================================================
  STEP 1: CREATING SECURITY GROUP
================================================================
✓ Created security group: sg-xxxxx
✓ Security group rules configured

================================================================
  STEP 2: CREATING RDS DATABASE
================================================================
✓ RDS instance creation initiated
⏳ Waiting for RDS (this may take 10 minutes)...
✓ RDS instance ready: xxxxx.rds.amazonaws.com

================================================================
  STEP 3: CREATING S3 BUCKET
================================================================
✓ S3 bucket created: pgni-uploads-preprod-xxxx
✓ Versioning enabled
✓ CORS configured

================================================================
  STEP 4: LAUNCHING EC2 INSTANCE
================================================================
✓ EC2 instance launched: i-xxxxx
✓ EC2 instance ready: 13.xxx.xxx.xxx

================================================================
  STEP 5: GENERATING CONFIGURATION
================================================================
✓ Environment configuration saved

================================================================
  STEP 6: GENERATING DOCUMENTATION
================================================================
✓ Deployment report generated
✓ Credentials saved

================================================================
  DEPLOYMENT COMPLETE!
================================================================

📁 All files saved to: deployment-preprod-20250107-143022/
```

### Step 2: Review Deployment Report

The script automatically opens: `DEPLOYMENT_REPORT_preprod_XXXXXXXX.md`

**This report contains:**
- ✅ All AWS resource IDs
- ✅ All IP addresses
- ✅ All credentials
- ✅ SSH commands
- ✅ Database connection details
- ✅ Next steps
- ✅ GitHub secrets to add
- ✅ API deployment commands

### Step 3: Update GitHub Secrets

From the deployment report, copy the commands to add GitHub secrets:

```powershell
# Convert SSH key to base64
$pemContent = Get-Content "C:\AWS-Keys\pgni-preprod-key.pem" -Raw
$bytes = [System.Text.Encoding]::UTF8.GetBytes($pemContent)
[Convert]::ToBase64String($bytes) | Set-Clipboard
```

Then go to: https://github.com/siddam01/pgni/settings/secrets/actions

Add:
- `PREPROD_SSH_KEY` (paste from clipboard)
- `PREPROD_HOST` (EC2 IP from report)
- `PRODUCTION_SSH_KEY` (if deploying production)
- `PRODUCTION_HOST` (EC2 IP from report)

### Step 4: Deploy API Code

From the deployment report, run these commands:

```powershell
# Build API
cd C:\MyFolder\Mytest\pgworld-master\pgworld-api-master
$env:CGO_ENABLED=0
$env:GOOS="linux"
$env:GOARCH="amd64"
go build -o pgworld-api .

# Copy to EC2 (replace IP with your EC2 IP)
$EC2_IP = "YOUR_EC2_IP"
scp -i "C:\AWS-Keys\pgni-preprod-key.pem" pgworld-api ubuntu@${EC2_IP}:/tmp/
scp -i "C:\AWS-Keys\pgni-preprod-key.pem" ../deployment-preprod-XXXXXX/preprod.env ubuntu@${EC2_IP}:/tmp/.env

# SSH to EC2
ssh -i "C:\AWS-Keys\pgni-preprod-key.pem" ubuntu@${EC2_IP}

# On EC2:
sudo mv /tmp/pgworld-api /opt/pgworld/pgworld-api
sudo mv /tmp/.env /opt/pgworld/.env
sudo chmod +x /opt/pgworld/pgworld-api
sudo systemctl start pgworld-api
sudo systemctl status pgworld-api
```

### Step 5: Test API

```powershell
# Test health endpoint
curl http://YOUR_EC2_IP:8080/

# Should return: "ok"
```

### Step 6: Update Flutter Apps

Update API URL in your Flutter apps:

**Admin App:** `pgworld-master/lib/config.dart`
```dart
const String API_BASE_URL = "http://YOUR_EC2_IP:8080";
```

**Tenant App:** `pgworldtenant-master/lib/config.dart`
```dart
const String API_BASE_URL = "http://YOUR_EC2_IP:8080";
```

---

## 🔐 Security & Credentials

### Where Credentials Are Stored:

1. **Deployment Folder:**
   - `CREDENTIALS_preprod.txt` - Plain text (local only)
   - `preprod.env` - Environment file (for EC2)

2. **GitHub Secrets:**
   - SSH keys (base64 encoded)
   - Host IPs
   - Database passwords

3. **AWS Systems Manager Parameter Store** (optional):
   - Can store all secrets encrypted
   - Accessed by EC2 at runtime

### Credentials Generated:

- ✅ Database password (24 characters, random)
- ✅ API key (32 characters, random)
- ✅ JWT secret (64 characters, random)
- ✅ All stored securely

### What YOU Need to Add:

Update in the `.env` file:
- Razorpay Key ID
- Razorpay Key Secret
- Android Live Key
- Android Test Key
- iOS Live Key
- iOS Test Key

---

## 💰 Cost Optimization (Built-in)

### Free Tier Optimization:
- ✅ Uses t3.micro for EC2 (750 hrs/month free)
- ✅ Uses db.t3.micro for RDS (750 hrs/month free)
- ✅ Keeps S3 under 5GB (free)
- ✅ Minimal data transfer

### Cost Monitoring:
- ✅ Budget alerts configured (during AWS setup)
- ✅ Free tier usage dashboard
- ✅ Cost Explorer enabled

### Cost Saving Tips:
1. **Stop Pre-Prod When Not Using:**
   ```bash
   aws ec2 stop-instances --instance-ids i-xxxxx
   aws rds stop-db-instance --db-instance-identifier pgni-preprod-db
   ```
   Saves: ~₹1,500/month

2. **Use S3 Lifecycle Policies:**
   - Auto-delete old uploads after 90 days
   - Saves: ₹50-100/month

3. **Monitor Free Tier:**
   - Check monthly: https://console.aws.amazon.com/billing/home#/freetier

---

## 🔄 CI/CD Pipeline (Already Configured)

### GitHub Actions Workflow:

**Already created:** `.github/workflows/deploy.yml`

**How it works:**

1. **Push to `develop` branch:**
   - Builds API automatically
   - Deploys to pre-production automatically
   - No approval needed

2. **Push to `main` branch:**
   - Builds API automatically
   - Waits for YOUR approval
   - Deploys to production after approval

### To Activate CI/CD:

1. **Create develop branch:**
   ```bash
   git checkout -b develop
   git push -u origin develop
   ```

2. **Make changes and push:**
   ```bash
   git add .
   git commit -m "Your changes"
   git push
   ```

3. **GitHub Actions will:**
   - Build the API
   - Deploy to pre-production
   - You can monitor at: https://github.com/siddam01/pgni/actions

---

## 📊 Monitoring

### What's Monitored:

1. **EC2 Instance:**
   - CPU utilization
   - Memory usage
   - Disk space
   - Network traffic

2. **RDS Database:**
   - Connection count
   - Query performance
   - Storage usage
   - Backup status

3. **API Application:**
   - Request rate
   - Error rate
   - Response time
   - Uptime

### How to Monitor:

**CloudWatch Dashboard:**
- https://console.aws.amazon.com/cloudwatch/

**API Logs:**
```bash
ssh -i "C:\AWS-Keys\pgni-preprod-key.pem" ubuntu@YOUR_EC2_IP
sudo journalctl -u pgworld-api -f
```

**Database Logs:**
- RDS Console: https://console.aws.amazon.com/rds/

---

## 🆘 Common Issues

### Issue 1: Script Fails "Key pair not found"

**Solution:**
```bash
# In AWS Console:
# EC2 → Key Pairs → Create Key Pair
# Name: pgni-preprod-key (or pgni-production-key)
# Download to: C:\AWS-Keys\
```

### Issue 2: Cannot connect to AWS

**Solution:**
```powershell
aws configure
# Enter your Access Key ID
# Enter your Secret Access Key
# Region: ap-south-1
# Format: json
```

### Issue 3: RDS creation times out

**Solution:**
- This is normal, RDS takes 10-15 minutes
- Wait patiently, script will continue
- Check AWS Console to see progress

### Issue 4: S3 bucket name already exists

**Solution:**
- Script generates random bucket names
- If it fails, re-run the script
- It will generate a new random name

### Issue 5: Cannot SSH to EC2

**Solution:**
```powershell
# Fix key permissions
icacls "C:\AWS-Keys\pgni-preprod-key.pem" /reset
icacls "C:\AWS-Keys\pgni-preprod-key.pem" /grant:r "$($env:USERNAME):R"
icacls "C:\AWS-Keys\pgni-preprod-key.pem" /inheritance:r
```

---

## 📞 Getting Help

### If Deployment Fails:

1. **Check the log:**
   ```powershell
   Get-Content deployment-preprod-XXXXXX/deployment.log | Select-Object -Last 50
   ```

2. **Check AWS Console:**
   - EC2: https://console.aws.amazon.com/ec2/
   - RDS: https://console.aws.amazon.com/rds/
   - S3: https://console.aws.amazon.com/s3/

3. **Re-run the script:**
   - Safe to re-run
   - Will skip existing resources

### AWS Support:

- **Phone:** 1800-572-4555 (India, toll-free)
- **Console:** https://console.aws.amazon.com/support/

### Your AWS Account:
- **Email:** manisekharsiddani@gmail.com
- **Region:** ap-south-1 (Mumbai)

---

## ✅ Deployment Checklist

### Before Deployment:
- [ ] AWS account created
- [ ] IAM admin user created
- [ ] AWS CLI installed and configured
- [ ] EC2 key pairs created
- [ ] Billing alerts configured

### Run Deployment:
- [ ] Run: `.\deploy-complete.ps1 -Environment preprod`
- [ ] Wait for completion (15-20 minutes)
- [ ] Review deployment report
- [ ] Save all credentials securely

### After Deployment:
- [ ] Update GitHub secrets
- [ ] Build and deploy API code
- [ ] Test API endpoints
- [ ] Update Flutter apps
- [ ] Add Razorpay credentials
- [ ] Add API keys (Android/iOS)
- [ ] Test complete user flow

### Repeat for Production:
- [ ] Run: `.\deploy-complete.ps1 -Environment production`
- [ ] Follow same steps
- [ ] Test thoroughly
- [ ] Go live!

---

## 🎉 Success!

After completing all steps:

✅ Pre-production environment deployed
✅ Production environment deployed
✅ CI/CD pipeline active
✅ All credentials generated and saved
✅ Complete documentation provided
✅ Costs optimized
✅ Ready for users!

---

## 📁 Files Reference

**Created by this solution:**
- `deploy-complete.ps1` - Master deployment script
- `COMPLETE_DEPLOYMENT_GUIDE.md` - This guide
- `deployment-{env}-{timestamp}/` - Deployment folder with all details

**Already exists:**
- `.github/workflows/deploy.yml` - CI/CD pipeline
- `YOUR_AWS_SETUP_STEPS.md` - AWS setup guide
- `DEPLOY_TO_AWS.md` - Manual deployment guide (if needed)
- `PRE_DEPLOYMENT_CHECKLIST.md` - Complete checklist

---

## 🚀 Ready to Deploy?

```powershell
# Navigate to project
cd C:\MyFolder\Mytest\pgworld-master

# Deploy pre-production
.\deploy-complete.ps1 -Environment preprod

# Deploy production (after pre-prod is tested)
.\deploy-complete.ps1 -Environment production
```

**That's it!** Everything else is automated! 🎉

---

*Last Updated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")*
*Your complete deployment solution is ready!*

