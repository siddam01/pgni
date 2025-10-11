# 🚀 DEPLOY NOW - Complete Deployment Guide

## ✅ Infrastructure Status: READY

All AWS infrastructure is deployed and ready for use!

---

## 📋 Pre-Deployment Verification

### ✅ Infrastructure Created
- [x] EC2 Instance: **34.227.111.143** (Running)
- [x] S3 Bucket: **pgni-preprod-698302425856-uploads**
- [x] RDS Database: **database-pgni** (MySQL)
- [x] Security Groups: Configured
- [x] IAM Roles: Created
- [x] SSH Key: Generated

### ✅ Files Ready
- [x] `pgni-preprod-key.pem` - SSH private key
- [x] `preprod.env` - API environment configuration
- [x] Terraform state - Infrastructure tracked

---

## 🎯 Deployment Steps

### Step 1: Upload Environment File to EC2

**Option A: Using SCP (Windows PowerShell)**
```powershell
# Navigate to project directory
cd C:\MyFolder\Mytest\pgworld-master

# Upload environment file
scp -i pgni-preprod-key.pem preprod.env ec2-user@34.227.111.143:~/
```

**Option B: Using WinSCP (GUI)**
1. Download WinSCP: https://winscp.net/
2. Host: `34.227.111.143`
3. Username: `ec2-user`
4. Private key: Browse to `pgni-preprod-key.pem`
5. Upload `preprod.env` to `/home/ec2-user/`

---

### Step 2: Connect to EC2 and Deploy API

```bash
# Connect to EC2
ssh -i pgni-preprod-key.pem ec2-user@34.227.111.143

# Once connected, run these commands:

# 1. Clone your repository
git clone https://github.com/siddam01/pgni.git
cd pgni/pgworld-api-master

# 2. Move environment file
sudo mkdir -p /opt/pgworld
sudo mv ~/preprod.env /opt/pgworld/.env

# 3. Build the API
/usr/local/go/bin/go build -o /opt/pgworld/pgworld-api .

# 4. Start the API service
sudo systemctl start pgworld-api

# 5. Check status
sudo systemctl status pgworld-api

# 6. Enable auto-start on boot
sudo systemctl enable pgworld-api

# 7. View logs
sudo journalctl -u pgworld-api -f
```

---

### Step 3: Initialize Database

```bash
# Still on EC2, connect to database
mysql -h database-pgni.cezawkgguojl.us-east-1.rds.amazonaws.com -u admin -p

# Enter password: Omsairamdb951#

# Run these SQL commands:
CREATE DATABASE IF NOT EXISTS pgworld CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE pgworld;

# Show tables (API will create them on first run)
SHOW TABLES;

# Exit MySQL
EXIT;
```

---

### Step 4: Test API

```bash
# Test health endpoint
curl http://34.227.111.143:8080/health

# Expected response:
# {"status":"healthy"}

# Test from your local machine
curl http://34.227.111.143:8080/health
```

---

### Step 5: Update Flutter Apps

#### Admin App (`pgworld-master`)

**File:** `pgworld-master/lib/constants.dart` or wherever API URL is defined

Find and update:
```dart
// OLD
static const String API_URL = "http://localhost:8080";

// NEW
static const String API_URL = "http://34.227.111.143:8080";
```

#### Tenant App (`pgworldtenant-master`)

**File:** `pgworldtenant-master/lib/constants.dart`

```dart
// OLD
static const String API_URL = "http://localhost:8080";

// NEW
static const String API_URL = "http://34.227.111.143:8080";
```

---

### Step 6: Test Flutter Apps

```bash
# Admin App
cd pgworld-master
flutter clean
flutter pub get
flutter run

# Tenant App
cd pgworldtenant-master
flutter clean
flutter pub get
flutter run
```

---

## 🔍 Verification Checklist

### API Verification
- [ ] API responds to health check
- [ ] Database connection successful
- [ ] API logs show no errors
- [ ] Service starts automatically

### S3 Verification
- [ ] Can upload files via API
- [ ] Files visible in S3 console
- [ ] Encryption enabled
- [ ] Access permissions correct

### Database Verification
- [ ] Can connect from EC2
- [ ] Tables created by API
- [ ] Data persists correctly
- [ ] Queries execute successfully

### Flutter Apps Verification
- [ ] Apps connect to API
- [ ] Login/Register works
- [ ] File upload works
- [ ] Data displays correctly

---

## 📊 Infrastructure Details

### EC2 Instance
```
Instance ID: i-0909d462845deb151
Public IP: 34.227.111.143
Private IP: 172.31.27.239
Type: t3.micro
OS: Amazon Linux 2023
```

### S3 Bucket
```
Name: pgni-preprod-698302425856-uploads
Region: us-east-1
Encryption: KMS (app-pg-key)
Versioning: Enabled
```

### RDS Database
```
Endpoint: database-pgni.cezawkgguojl.us-east-1.rds.amazonaws.com
Port: 3306
Database: pgworld
User: admin
Engine: MySQL 8.0
```

---

## 🔐 Security Configuration

### EC2 Security Group
```
Ingress:
  - SSH (22): 0.0.0.0/0
  - HTTP (80): 0.0.0.0/0
  - HTTPS (443): 0.0.0.0/0
  - API (8080): 0.0.0.0/0

Egress:
  - All traffic: 0.0.0.0/0
```

### RDS Security Group
```
Ingress:
  - MySQL (3306): From EC2 security group only

Egress:
  - All traffic: 0.0.0.0/0
```

---

## 🆘 Troubleshooting

### Cannot SSH to EC2

**Problem:** Permission denied or connection refused

**Solution:**
```powershell
# Fix key permissions on Windows
icacls pgni-preprod-key.pem /inheritance:r
icacls pgni-preprod-key.pem /grant:r "%USERNAME%:R"

# Try SSH again
ssh -i pgni-preprod-key.pem ec2-user@34.227.111.143
```

---

### API Service Not Starting

**Check logs:**
```bash
sudo journalctl -u pgworld-api -n 100 --no-pager
```

**Common issues:**
1. **Missing .env file**
   ```bash
   ls -la /opt/pgworld/.env
   ```

2. **Wrong permissions**
   ```bash
   sudo chmod 644 /opt/pgworld/.env
   sudo chown ec2-user:ec2-user /opt/pgworld/.env
   ```

3. **Port already in use**
   ```bash
   sudo netstat -tlnp | grep 8080
   ```

---

### Database Connection Failed

**Test connection:**
```bash
mysql -h database-pgni.cezawkgguojl.us-east-1.rds.amazonaws.com -u admin -p
```

**If fails, check:**
1. Security group allows EC2 → RDS
2. RDS instance is running
3. Credentials are correct in `.env`

**Check security group:**
```bash
# On EC2, check connectivity
telnet database-pgni.cezawkgguojl.us-east-1.rds.amazonaws.com 3306
```

---

### S3 Upload Failed

**Check IAM role:**
```bash
# On EC2, verify role
aws sts get-caller-identity

# Try uploading test file
aws s3 cp /tmp/test.txt s3://pgni-preprod-698302425856-uploads/test.txt
```

**If fails:**
1. Check IAM role is attached to EC2
2. Verify S3 bucket policy
3. Check API has AWS credentials in environment

---

### Flutter App Cannot Connect

**Check API URL:**
1. Verify `API_URL` is updated to `http://34.227.111.143:8080`
2. Check API is running: `curl http://34.227.111.143:8080/health`
3. Check security group allows port 8080

**Network debugging:**
```bash
# From your computer
ping 34.227.111.143
curl http://34.227.111.143:8080/health
```

---

## 📱 Mobile App Configuration

### Update API Endpoints

**Find API URL definitions in:**
- `pgworld-master/lib/config.dart`
- `pgworld-master/lib/constants.dart`
- `pgworld-master/lib/services/api_service.dart`
- `pgworldtenant-master/lib/config.dart`
- `pgworldtenant-master/lib/constants.dart`
- `pgworldtenant-master/lib/services/api_service.dart`

**Replace all instances of:**
- `localhost` → `34.227.111.143`
- `127.0.0.1` → `34.227.111.143`
- `10.0.2.2` → `34.227.111.143` (Android emulator)

---

## 🔄 CI/CD Pipeline Setup (Optional)

### Configure GitHub Secrets

Go to: `https://github.com/siddam01/pgni/settings/secrets/actions`

Add these secrets:
```
AWS_ACCESS_KEY_ID: [Your AWS Access Key]
AWS_SECRET_ACCESS_KEY: [Your AWS Secret Key]
AWS_REGION: us-east-1
EC2_HOST: 34.227.111.143
SSH_PRIVATE_KEY: [Contents of pgni-preprod-key.pem]
DB_HOST: database-pgni.cezawkgguojl.us-east-1.rds.amazonaws.com
DB_PASSWORD: Omsairamdb951#
S3_BUCKET: pgni-preprod-698302425856-uploads
```

The workflow in `.github/workflows/deploy.yml` will automatically deploy on:
- Push to `develop` branch → Pre-production
- Push to `main` branch → Production (with approval)

---

## 📈 Monitoring & Logs

### API Logs
```bash
# Real-time logs
sudo journalctl -u pgworld-api -f

# Last 100 lines
sudo journalctl -u pgworld-api -n 100

# Logs since today
sudo journalctl -u pgworld-api --since today
```

### EC2 Metrics
- Go to: AWS Console → EC2 → Monitoring
- View: CPU, Network, Disk

### RDS Metrics
- Go to: AWS Console → RDS → database-pgni → Monitoring
- View: Connections, CPU, Storage

### S3 Metrics
- Go to: AWS Console → S3 → pgni-preprod-698302425856-uploads → Metrics
- View: Requests, Storage, Data transfer

---

## 💰 Cost Monitoring

### Current Costs (Estimated)
- **EC2 t3.micro:** $0/month (Free Tier - 750 hrs)
- **RDS db.t3.micro:** ~$15/month
- **S3 Storage:** ~$0.023/GB/month
- **Data Transfer:** First 100GB free

**Total: ~$15-20/month**

### Cost Optimization Tips
1. Stop EC2 when not in use (development)
2. Enable S3 lifecycle policies (already done)
3. Use RDS backups wisely
4. Monitor data transfer

---

## 🎯 Quick Command Reference

### SSH to EC2
```bash
ssh -i pgni-preprod-key.pem ec2-user@34.227.111.143
```

### Check API Status
```bash
sudo systemctl status pgworld-api
```

### Restart API
```bash
sudo systemctl restart pgworld-api
```

### View API Logs
```bash
sudo journalctl -u pgworld-api -f
```

### Connect to Database
```bash
mysql -h database-pgni.cezawkgguojl.us-east-1.rds.amazonaws.com -u admin -p
```

### Test API Health
```bash
curl http://34.227.111.143:8080/health
```

---

## ✅ Post-Deployment Checklist

### Infrastructure
- [ ] EC2 instance accessible via SSH
- [ ] API service running and healthy
- [ ] Database connection working
- [ ] S3 bucket accessible
- [ ] Security groups configured

### Application
- [ ] API responds to health check
- [ ] Database tables created
- [ ] File uploads working
- [ ] Authentication working
- [ ] All endpoints tested

### Mobile Apps
- [ ] Admin app connects to API
- [ ] Tenant app connects to API
- [ ] Login/register flows work
- [ ] Data syncs correctly
- [ ] File uploads work

### Documentation
- [ ] API endpoints documented
- [ ] Deployment steps recorded
- [ ] Credentials stored securely
- [ ] Team members have access

---

## 🎉 Success Indicators

**You'll know deployment is successful when:**

1. ✅ `curl http://34.227.111.143:8080/health` returns `{"status":"healthy"}`
2. ✅ Flutter apps can login/register users
3. ✅ Files upload to S3 successfully
4. ✅ Database shows user data
5. ✅ API logs show no errors

---

## 📞 Need Help?

### Resources
- **Infrastructure Details:** `DEPLOYMENT_SUCCESS.md`
- **Project Structure:** `PROJECT_STRUCTURE.md`
- **Pre-deployment Checklist:** `PRE_DEPLOYMENT_CHECKLIST.md`

### Common Commands
- **View all outputs:** `cd terraform && terraform output`
- **Get SSH key:** `cd terraform && terraform output -raw ssh_private_key`
- **Get env file:** `cd terraform && terraform output -raw environment_file`

---

**🚀 Ready to Deploy! Follow the steps above to get your application running!**

**Estimated Deployment Time:** 30-45 minutes
**Difficulty:** Intermediate
**Status:** All infrastructure ready, just need to deploy code!

