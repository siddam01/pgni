# PGNi Application - Complete Deployment Guide

## Table of Contents
1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Step-by-Step Deployment](#step-by-step-deployment)
4. [Validation & Testing](#validation--testing)
5. [Accessing the Application](#accessing-the-application)
6. [Troubleshooting](#troubleshooting)
7. [Architecture](#architecture)

---

## Overview

This guide provides complete end-to-end deployment instructions for the PGNi (Paying Guest Management) application, including:
- **Backend API** (Go Lang) - Port 8080
- **Admin Portal** (Flutter Web) - http://IP/admin/
- **Tenant Portal** (Flutter Web) - http://IP/tenant/
- **Database** (AWS RDS MySQL)
- **Storage** (AWS S3)

**Deployment Time:** ~15-20 minutes (automated)

---

## Prerequisites

### 1. AWS Account Access
- AWS CloudShell access (or AWS CLI configured)
- Permissions: EC2, RDS, S3, IAM

### 2. Infrastructure Already Deployed
The following resources should already exist (created via Terraform):
- ✅ EC2 Instance (t3.medium or larger)
- ✅ RDS MySQL Database
- ✅ S3 Bucket for uploads
- ✅ Security Groups (ports 22, 80, 8080, 3306)
- ✅ IAM Roles and permissions

### 3. GitHub Repository
- Repository: https://github.com/siddam01/pgni
- Access: Public (no authentication needed)

---

## Step-by-Step Deployment

### Step 1: Open AWS CloudShell

1. Log into AWS Console
2. Click the CloudShell icon (>_) in the top navigation bar
3. Wait for CloudShell to initialize

### Step 2: Download Deployment Script

```bash
# Navigate to home directory
cd ~

# Download the complete deployment script
curl -O https://raw.githubusercontent.com/siddam01/pgni/main/COMPLETE_ENTERPRISE_DEPLOYMENT.sh

# Make it executable
chmod +x COMPLETE_ENTERPRISE_DEPLOYMENT.sh
```

### Step 3: Get SSH Key

```bash
# Download SSH key from repository
curl -O https://raw.githubusercontent.com/siddam01/pgni/main/terraform/ssh-key.txt

# Rename and set permissions
mv ssh-key.txt cloudshell-key.pem
chmod 600 cloudshell-key.pem

# Verify key exists
ls -l cloudshell-key.pem
```

### Step 4: Run Deployment

```bash
# Execute the deployment script
./COMPLETE_ENTERPRISE_DEPLOYMENT.sh
```

### Step 5: Monitor Deployment Progress

The script will show progress through 6 phases:

```
PHASE 1/6: Infrastructure Validation & Expansion
  - Checking EC2 instance status
  - Validating disk space (expanding to 100GB if needed)
  - Verifying network connectivity

PHASE 2/6: Installing Prerequisites on EC2
  - Updating system packages
  - Installing Git, Nginx, development tools
  - Downloading & installing Flutter SDK (~10 minutes)
  - Running Flutter doctor

PHASE 3/6: Building Flutter Applications
  - Cloning source code
  - Configuring API URLs
  - Building Admin App (Flutter Web)
  - Building Tenant App (Flutter Web)

PHASE 4/6: Deploying Frontend to Nginx
  - Creating web directories
  - Copying build files
  - Setting permissions

PHASE 5/6: Configuring Nginx
  - Creating Nginx configuration
  - Setting up routing (/admin/, /tenant/, /api/)
  - Enabling CORS
  - Starting Nginx service

PHASE 6/6: Validation & Health Checks
  - Testing Backend API
  - Testing Admin Portal
  - Testing Tenant Portal
  - Verifying all services
```

**Expected Duration:** 15-20 minutes
- Phase 1: ~2 minutes (infrastructure checks)
- Phase 2: ~10 minutes (Flutter SDK download)
- Phase 3: ~5 minutes (building apps)
- Phase 4-6: ~3 minutes (deployment & validation)

---

## Validation & Testing

### Automated Validation

The deployment script automatically validates:
- ✅ Backend API health check
- ✅ Admin Portal accessibility
- ✅ Tenant Portal accessibility
- ✅ Nginx service status

### Manual Validation

After deployment completes, test each component:

#### 1. Backend API Test
```bash
# From CloudShell or any terminal
curl http://34.227.111.143:8080/health

# Expected response:
# {"status":"ok","timestamp":"2024-10-13T..."}
```

#### 2. Admin Portal Test
Open in browser:
```
http://34.227.111.143/admin/
```
- Should load the Admin login page
- Try logging in with test credentials

#### 3. Tenant Portal Test
Open in browser:
```
http://34.227.111.143/tenant/
```
- Should load the Tenant login page
- Try logging in with test credentials

---

## Accessing the Application

### URLs

| Component | URL | Port |
|-----------|-----|------|
| **Admin Portal** | http://34.227.111.143/admin/ | 80 |
| **Tenant Portal** | http://34.227.111.143/tenant/ | 80 |
| **Backend API** | http://34.227.111.143:8080 | 8080 |
| **API Health** | http://34.227.111.143:8080/health | 8080 |

### Test Accounts

#### Super Admin (Full System Access)
```
Email: admin@pgworld.com
Password: Admin@123

Access: All features, user management, system configuration
```

#### PG Owner (Property Owner/Manager)
```
Email: owner@pg.com
Password: Owner@123

Access: Property management, tenant management, payments
```

#### Tenant (Resident)
```
Email: tenant@pg.com
Password: Tenant@123

Access: Profile, payments, complaints, notices
```

### Creating Additional Users

#### Via Admin Portal:
1. Login as admin@pgworld.com
2. Navigate to "Users" section
3. Click "Add New User"
4. Fill in details and assign role

#### Via Direct Database:
```sql
-- Connect to RDS from EC2
mysql -h database-pgni.cezawkgguojl.us-east-1.rds.amazonaws.com -u admin -p

USE pgworld;

-- Create new user (password is hashed)
INSERT INTO users (username, email, password_hash, role) 
VALUES ('newuser', 'newuser@example.com', 'hashed_password', 'tenant');
```

---

## Troubleshooting

### Issue 1: Deployment Script Fails at Phase 2 (Flutter Installation)

**Symptom:**
```
[ERROR] No space left on device
```

**Solution:**
The script automatically expands EC2 disk to 100GB. If it still fails:
```bash
# Check current disk usage on EC2
ssh -i cloudshell-key.pem ec2-user@34.227.111.143 "df -h"

# Manually expand filesystem
ssh -i cloudshell-key.pem ec2-user@34.227.111.143 "sudo xfs_growfs /"
```

### Issue 2: Cannot Access Admin/Tenant Portal (404 Error)

**Symptom:**
Browser shows "404 Not Found" when accessing http://34.227.111.143/admin/

**Solution:**
```bash
# SSH to EC2
ssh -i cloudshell-key.pem ec2-user@34.227.111.143

# Check if build files exist
ls -la /usr/share/nginx/html/admin/
ls -la /usr/share/nginx/html/tenant/

# Check Nginx status
sudo systemctl status nginx

# Check Nginx logs
sudo tail -f /var/log/nginx/error.log

# Restart Nginx if needed
sudo systemctl restart nginx
```

### Issue 3: API Returns 502 Bad Gateway

**Symptom:**
Accessing http://34.227.111.143:8080/health returns 502 error

**Solution:**
```bash
# SSH to EC2
ssh -i cloudshell-key.pem ec2-user@34.227.111.143

# Check API service status
sudo systemctl status pgworld-api

# Check API logs
sudo journalctl -u pgworld-api -n 50

# Restart API if needed
sudo systemctl restart pgworld-api

# Test API directly
curl http://localhost:8080/health
```

### Issue 4: Login Fails with "Invalid Credentials"

**Symptom:**
Test accounts don't work

**Solution:**
```bash
# SSH to EC2
ssh -i cloudshell-key.pem ec2-user@34.227.111.143

# Check if demo data was loaded
mysql -h database-pgni.cezawkgguojl.us-east-1.rds.amazonaws.com -u admin -pOmsairamdb951# pgworld -e "SELECT email, role FROM users;"

# If no users exist, load demo data
cd ~/pgni
mysql -h database-pgni.cezawkgguojl.us-east-1.rds.amazonaws.com -u admin -pOmsairamdb951# pgworld < demo-data.sql
```

### Issue 5: CORS Errors in Browser Console

**Symptom:**
Browser console shows CORS policy errors

**Solution:**
```bash
# SSH to EC2
ssh -i cloudshell-key.pem ec2-user@34.227.111.143

# Check Nginx configuration
sudo cat /etc/nginx/conf.d/pgni.conf

# Verify CORS headers are present
curl -I http://localhost/admin/

# If CORS headers missing, re-run Phase 5 of deployment
```

### Issue 6: SSH Connection Refused

**Symptom:**
```
ssh: connect to host 34.227.111.143 port 22: Connection refused
```

**Solution:**
```bash
# Check EC2 instance status in AWS Console
aws ec2 describe-instances --instance-ids i-0b5f620584d1e4ee9 --region us-east-1

# Check Security Group allows SSH (port 22)
aws ec2 describe-security-groups --region us-east-1 | grep -A 10 "22"

# Try EC2 Instance Connect from AWS Console instead
# EC2 Console > Instances > Select instance > Connect > EC2 Instance Connect
```

### Issue 7: Flutter Build Fails

**Symptom:**
```
[ERROR] Flutter build failed
```

**Solution:**
```bash
# SSH to EC2
ssh -i cloudshell-key.pem ec2-user@34.227.111.143

# Set Flutter path
export PATH="$PATH:/home/ec2-user/flutter/bin"

# Check Flutter installation
flutter doctor -v

# Clean and rebuild
cd ~/pgni/pgworld-master
flutter clean
flutter pub get
flutter build web --release

cd ~/pgni/pgworldtenant-master
flutter clean
flutter pub get
flutter build web --release
```

---

## Architecture

### System Components

```
┌─────────────────────────────────────────────────────────────┐
│                         AWS Cloud                            │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              EC2 Instance (t3.medium)               │   │
│  │                                                      │   │
│  │  ┌──────────────────────────────────────────┐     │   │
│  │  │         Nginx (Port 80)                  │     │   │
│  │  │  - Routes /admin/ → Admin App            │     │   │
│  │  │  - Routes /tenant/ → Tenant App          │     │   │
│  │  │  - Proxies /api/ → Backend API           │     │   │
│  │  └──────────────────────────────────────────┘     │   │
│  │                                                      │   │
│  │  ┌──────────────────────────────────────────┐     │   │
│  │  │     Backend API (Port 8080)              │     │   │
│  │  │  - Go Lang REST API                      │     │   │
│  │  │  - JWT Authentication                    │     │   │
│  │  │  - Business Logic                        │     │   │
│  │  └──────────────────────────────────────────┘     │   │
│  │                                                      │   │
│  │  ┌──────────────────────────────────────────┐     │   │
│  │  │     Flutter Web Apps                     │     │   │
│  │  │  /usr/share/nginx/html/admin/            │     │   │
│  │  │  /usr/share/nginx/html/tenant/           │     │   │
│  │  └──────────────────────────────────────────┘     │   │
│  └─────────────────────────────────────────────────────┘   │
│                          │                                   │
│                          │                                   │
│  ┌───────────────────────┼───────────────────────────────┐ │
│  │                       │                                │ │
│  │  ┌────────────────────▼──────────────┐               │ │
│  │  │  RDS MySQL Database                │               │ │
│  │  │  - User data                       │               │ │
│  │  │  - PG properties                   │               │ │
│  │  │  - Tenant records                  │               │ │
│  │  │  - Payment history                 │               │ │
│  │  └────────────────────────────────────┘               │ │
│  │                                                         │ │
│  │  ┌─────────────────────────────────────┐              │ │
│  │  │  S3 Bucket                          │              │ │
│  │  │  - Document uploads                 │              │ │
│  │  │  - Profile images                   │              │ │
│  │  │  - Payment receipts                 │              │ │
│  │  └─────────────────────────────────────┘              │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

### Data Flow

1. **User Access:**
   - User opens http://34.227.111.143/admin/ or /tenant/ in browser
   - Nginx serves the Flutter web app (static HTML/JS/CSS)

2. **Authentication:**
   - Flutter app sends login request to /api/auth/login
   - Nginx proxies to Backend API on port 8080
   - API validates credentials against MySQL
   - API returns JWT token

3. **API Requests:**
   - Flutter app includes JWT in subsequent requests
   - All requests go through Nginx proxy to Backend API
   - API validates JWT and processes request
   - API queries MySQL database
   - API may upload/download from S3
   - API returns JSON response

4. **File Uploads:**
   - User uploads file in Flutter app
   - API receives file and uploads to S3
   - API stores S3 URL in MySQL
   - Flutter app can retrieve file via S3 URL

### Security

- **Authentication:** JWT tokens
- **Authorization:** Role-based (Admin, PG Owner, Tenant)
- **Network:** AWS Security Groups restrict access
- **Database:** Private subnet, accessible only from EC2
- **Files:** S3 bucket with IAM role permissions
- **HTTPS:** (Optional) Can add SSL certificate

---

## Next Steps

### 1. Enable HTTPS (Optional but Recommended)

```bash
# Install certbot for Let's Encrypt SSL
sudo yum install -y certbot python3-certbot-nginx

# Get SSL certificate (requires domain name)
sudo certbot --nginx -d yourdomain.com
```

### 2. Set Up Custom Domain

1. Register domain (e.g., GoDaddy, Namecheap)
2. Create A record pointing to EC2 IP (34.227.111.143)
3. Update Nginx configuration with domain name
4. Enable HTTPS with SSL certificate

### 3. Configure Automated Backups

```bash
# Create backup script
sudo tee /usr/local/bin/backup-pgni.sh > /dev/null << 'EOF'
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
mysqldump -h database-pgni.cezawkgguojl.us-east-1.rds.amazonaws.com \
  -u admin -pOmsairamdb951# pgworld | \
  gzip > /backups/pgworld_$DATE.sql.gz
aws s3 cp /backups/pgworld_$DATE.sql.gz s3://pgni-backups/
find /backups -name "*.sql.gz" -mtime +7 -delete
EOF

chmod +x /usr/local/bin/backup-pgni.sh

# Schedule daily backups
sudo crontab -e
# Add: 0 2 * * * /usr/local/bin/backup-pgni.sh
```

### 4. Set Up Monitoring

```bash
# Install CloudWatch agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
sudo rpm -U ./amazon-cloudwatch-agent.rpm

# Configure monitoring for:
# - CPU usage
# - Memory usage
# - Disk space
# - API response times
# - Nginx access logs
```

### 5. Build Mobile Apps (Android & iOS)

#### For Android:
```bash
# On EC2 or local machine with Flutter
cd ~/pgni/pgworld-master
flutter build apk --release

cd ~/pgni/pgworldtenant-master
flutter build apk --release

# APK files will be at:
# build/app/outputs/flutter-apk/app-release.apk
```

#### For iOS:
```bash
# Requires macOS with Xcode
cd ~/pgni/pgworld-master
flutter build ios --release

cd ~/pgni/pgworldtenant-master
flutter build ios --release
```

---

## Maintenance

### Regular Tasks

**Daily:**
- Monitor API logs for errors
- Check disk space usage
- Review failed login attempts

**Weekly:**
- Database backup verification
- Security updates: `sudo yum update -y`
- Review user activity logs

**Monthly:**
- Full system backup
- Performance optimization
- Capacity planning review

### Useful Commands

```bash
# View API logs
sudo journalctl -u pgworld-api -f

# View Nginx access logs
sudo tail -f /var/log/nginx/access.log

# View Nginx error logs
sudo tail -f /var/log/nginx/error.log

# Check disk usage
df -h

# Check memory usage
free -h

# Check running processes
ps aux | grep -E "pgworld|nginx"

# Restart services
sudo systemctl restart pgworld-api
sudo systemctl restart nginx

# Check service status
sudo systemctl status pgworld-api
sudo systemctl status nginx
```

---

## Support

For issues or questions:
1. Check the [Troubleshooting](#troubleshooting) section
2. Review logs on EC2
3. Verify AWS infrastructure in AWS Console
4. Check GitHub repository for updates

---

**Deployment Guide Version:** 1.0  
**Last Updated:** October 15, 2024  
**Application Version:** 1.0.0

