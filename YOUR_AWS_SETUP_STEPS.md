# Your AWS Setup - Step by Step

**AWS Account:** manisekharsiddani@gmail.com

---

## IMMEDIATE ACTIONS (Do These NOW - 30 minutes)

### Step 1: Secure Your Root Account (10 minutes)

1. **Login to AWS Console:**
   - Go to: https://console.aws.amazon.com/
   - Email: manisekharsiddani@gmail.com
   - Enter your password

2. **Enable MFA (Multi-Factor Authentication):**
   - Click your account name (top right) → **Security credentials**
   - Find "Multi-factor authentication (MFA)"
   - Click **Assign MFA device**
   - Choose **Authenticator app**
   - Install Google Authenticator or Authy on your phone
   - Scan the QR code
   - Enter two consecutive codes
   - Click **Add MFA**
   - **✓ ROOT ACCOUNT IS NOW SECURE!**

### Step 2: Create IAM Admin User (15 minutes)

**IMPORTANT:** Never use root account for daily work!

1. **Go to IAM Console:**
   - Search for "IAM" in top search bar
   - Click "IAM" service
   - Or go to: https://console.aws.amazon.com/iam/

2. **Create Admin User:**
   - Click **Users** (left menu)
   - Click **Create user**
   - User name: `pgni-admin`
   - Click **Next**

3. **Set Permissions:**
   - Select **Attach policies directly**
   - Search for: `AdministratorAccess`
   - Check the box next to `AdministratorAccess`
   - Click **Next**
   - Click **Create user**

4. **Create Console Password:**
   - Click on the user `pgni-admin`
   - Go to **Security credentials** tab
   - Click **Enable console access**
   - Choose **Custom password**
   - Enter a strong password: _______________________ (SAVE THIS!)
   - Uncheck "User must create new password"
   - Click **Enable**

5. **Enable MFA for Admin User:**
   - Still in **Security credentials** tab
   - Under "Multi-factor authentication (MFA)"
   - Click **Assign MFA device**
   - Choose **Authenticator app**
   - Scan QR code with your phone
   - Enter two codes
   - Click **Add MFA**

6. **Create Access Keys (for GitHub Actions):**
   - Still in **Security credentials** tab
   - Scroll to **Access keys**
   - Click **Create access key**
   - Choose **Command Line Interface (CLI)**
   - Check "I understand the above recommendation"
   - Click **Next**
   - Description: "GitHub Actions CI/CD"
   - Click **Create access key**
   - **CRITICAL:** Copy these NOW (shown only once!):
     ```
     Access Key ID: _________________________________
     Secret Access Key: ____________________________
     ```
   - Click **Download .csv file** (SAVE THIS FILE SECURELY!)
   - Click **Done**

### Step 3: Set Up Billing Alerts (5 minutes)

1. **Go to Billing Console:**
   - Click your account name → **Billing Dashboard**
   - Or go to: https://console.aws.amazon.com/billing/

2. **Enable Alerts:**
   - Left menu: **Billing preferences**
   - Check ✓ **Receive Free Tier Usage Alerts**
   - Check ✓ **Receive Billing Alerts**
   - Enter email: manisekharsiddani@gmail.com
   - Click **Save preferences**

3. **Create Budget:**
   - Left menu: **Budgets**
   - Click **Create budget**
   - Choose **Use a template (simplified)**
   - Select **Monthly cost budget**
   - Budget name: `PGNi-Monthly-Budget`
   - Enter amount: **₹3000** (or $40)
   - Email recipients: manisekharsiddani@gmail.com
   - Click **Create budget**

---

## NEXT ACTIONS (Today - 1 hour)

### Step 4: Select Region (2 minutes)

1. **Change Region to Mumbai:**
   - Top right corner, click the region dropdown
   - Select: **Asia Pacific (Mumbai) ap-south-1**
   - This gives lowest latency for Indian users

### Step 5: Create EC2 Key Pairs (10 minutes)

1. **Go to EC2 Console:**
   - Search for "EC2" in top search bar
   - Click "EC2" service
   - Make sure region shows **ap-south-1** (top right)

2. **Create Pre-Production Key:**
   - Left menu: **Network & Security** → **Key Pairs**
   - Click **Create key pair**
   - Name: `pgni-preprod-key`
   - Key pair type: **RSA**
   - Private key format: **pem**
   - Click **Create key pair**
   - **File will download automatically**
   - Move it to: `C:\AWS-Keys\pgni-preprod-key.pem`

3. **Create Production Key:**
   - Click **Create key pair** again
   - Name: `pgni-production-key`
   - Key pair type: **RSA**
   - Private key format: **pem**
   - Click **Create key pair**
   - Move it to: `C:\AWS-Keys\pgni-production-key.pem`

4. **SECURE THESE FILES:**
   - These are your server access keys
   - Never share them
   - Never commit to git
   - Keep backups

### Step 6: Install AWS CLI (10 minutes)

1. **Install AWS CLI:**
   ```powershell
   winget install Amazon.AWSCLI
   ```

2. **Close and reopen PowerShell**

3. **Configure AWS CLI:**
   ```powershell
   aws configure
   ```
   - AWS Access Key ID: (paste from Step 2.6)
   - AWS Secret Access Key: (paste from Step 2.6)
   - Default region name: `ap-south-1`
   - Default output format: `json`

4. **Test AWS CLI:**
   ```powershell
   aws sts get-caller-identity
   ```
   - Should show your account details

### Step 7: Configure GitHub Secrets (10 minutes)

1. **Go to GitHub Repository:**
   - https://github.com/siddam01/pgni/settings/secrets/actions

2. **Add AWS Credentials:**
   
   **Add `AWS_ACCESS_KEY_ID`:**
   - Click **New repository secret**
   - Name: `AWS_ACCESS_KEY_ID`
   - Value: (paste Access Key ID from Step 2.6)
   - Click **Add secret**
   
   **Add `AWS_SECRET_ACCESS_KEY`:**
   - Click **New repository secret**
   - Name: `AWS_SECRET_ACCESS_KEY`
   - Value: (paste Secret Access Key from Step 2.6)
   - Click **Add secret**

3. **Verify Secrets:**
   - You should now see 2 secrets:
     - AWS_ACCESS_KEY_ID
     - AWS_SECRET_ACCESS_KEY

### Step 8: Prepare Environment Variables (15 minutes)

Create a secure document with these values (we'll use them during deployment):

```env
# Database Configuration
DB_USER=pgni_admin
DB_PASSWORD=__________________ (generate strong password below)
DB_NAME=pgnidb
DB_PORT=3306

# API Configuration
PORT=8080
test=false

# API Keys (your actual keys)
ANDROID_LIVE_KEY=__________________
ANDROID_TEST_KEY=__________________
IOS_LIVE_KEY=__________________
IOS_TEST_KEY=__________________

# Razorpay Credentials (your actual credentials)
RAZORPAY_KEY_ID=__________________
RAZORPAY_KEY_SECRET=__________________

# AWS Configuration
AWS_REGION=ap-south-1
S3_BUCKET_NAME=pgni-uploads-prod
AWS_ACCESS_KEY_ID=__________________ (from Step 2.6)
AWS_SECRET_ACCESS_KEY=______________ (from Step 2.6)
```

**Generate strong database password:**
```powershell
-join ((33..126) | Get-Random -Count 20 | ForEach-Object {[char]$_})
```

---

## WHAT YOU'VE COMPLETED

- [x] AWS account created: manisekharsiddani@gmail.com
- [ ] Root account MFA enabled
- [ ] IAM admin user created: pgni-admin
- [ ] Access keys created and saved
- [ ] Billing alerts configured
- [ ] Budget created: ₹3000/month
- [ ] Region selected: ap-south-1 (Mumbai)
- [ ] EC2 key pairs created and saved
- [ ] AWS CLI installed and configured
- [ ] GitHub secrets configured
- [ ] Environment variables prepared

---

## NEXT: Deploy Pre-Production (Tomorrow - 3 hours)

Once you complete the above steps, you're ready to deploy!

**What we'll create:**
1. RDS MySQL Database (free tier)
2. S3 Bucket for file uploads
3. EC2 Instance for API (free tier)
4. Configure CI/CD deployment

**Guide to follow:** `DEPLOY_TO_AWS.md`

---

## Important Security Notes

### Never Share These:
- ❌ AWS Access Keys
- ❌ AWS Secret Keys
- ❌ EC2 .pem key files
- ❌ Database passwords
- ❌ Razorpay credentials

### Always Keep Secure:
- ✓ Keep .pem files in C:\AWS-Keys\
- ✓ Don't commit keys to git
- ✓ Use MFA everywhere
- ✓ Monitor billing alerts

### If Keys Are Compromised:
1. Immediately delete the access key in IAM
2. Create new access key
3. Update GitHub secrets
4. Check CloudTrail for unauthorized activity

---

## Cost Monitoring

**Free Tier (First 12 Months):**
- EC2: 750 hours/month = FREE
- RDS: 750 hours/month = FREE
- S3: 5 GB = FREE
- Expected cost: ₹0-500/month

**Check Free Tier Usage:**
- https://console.aws.amazon.com/billing/home#/freetier

**Your Budget Alert:**
- Set at: ₹3000/month
- You'll get email if approaching limit

---

## Quick Commands Reference

```powershell
# Check AWS CLI is working
aws sts get-caller-identity

# List S3 buckets
aws s3 ls

# List EC2 instances
aws ec2 describe-instances --region ap-south-1

# Check free tier usage
aws ce get-cost-forecast --time-period Start=2024-10-01,End=2024-10-31 --metric BLENDED_COST --granularity MONTHLY
```

---

## Support Contacts

**AWS Support:**
- Phone: 1800-572-4555 (India, toll-free)
- Console: https://console.aws.amazon.com/support/

**Your Account:**
- Email: manisekharsiddani@gmail.com
- Region: ap-south-1 (Mumbai)
- Account Type: Free Tier

---

## Ready for Next Step?

Once you've completed all the checkboxes above, come back and say:

**"AWS setup complete, ready to deploy!"**

Then I'll guide you through:
1. Creating RDS database
2. Creating S3 bucket
3. Launching EC2 instance
4. Deploying your PGNi API
5. Testing everything

Take your time with the setup. Security is important! 🔒

---

*Last Updated: Now*
*Your AWS Journey Starts Here!*

