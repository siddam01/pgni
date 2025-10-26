# 🚀 AWS Deployment Guide - PGNI Application

## 📋 **Pre-Deployment Checklist**

Before we deploy, let's ensure everything is ready:

- [ ] AWS Account with credentials configured
- [ ] Backend API tested locally
- [ ] Frontend tested locally
- [ ] Database accessible
- [ ] Environment variables prepared

---

## 🎯 **Deployment Architecture**

```
┌─────────────────────────────────────────────────────┐
│                   AWS Cloud                         │
│                                                     │
│  ┌─────────────────┐      ┌──────────────────┐   │
│  │   CloudFront    │      │    EC2 Instance  │   │
│  │   (CDN)         │◄────►│   Backend API    │   │
│  │   Flutter Web   │      │   (Go Server)    │   │
│  └─────────────────┘      └──────────────────┘   │
│          │                         │              │
│          │                         │              │
│  ┌───────▼─────────┐      ┌───────▼──────────┐   │
│  │   S3 Bucket     │      │   RDS MySQL      │   │
│  │   Static Assets │      │   Database       │   │
│  └─────────────────┘      └──────────────────┘   │
│                                   │              │
│                           ┌───────▼──────────┐   │
│                           │   S3 Bucket      │   │
│                           │   File Uploads   │   │
│                           └──────────────────┘   │
└─────────────────────────────────────────────────┘
```

---

## 📦 **Step 1: Prepare the Application (5 minutes)**

### **1.1 Fix Package Issue**

```bash
cd pgworld-master

# Update pubspec.yaml
# Add this line under dependencies:
# modal_progress_hud_nsn: ^0.4.0

# Get dependencies
flutter pub get

# Verify no errors
flutter analyze
```

### **1.2 Update API Endpoint**

Open `pgworld-master/lib/utils/config.dart` and update:

```dart
class Config {
  // Change this to your EC2 public IP or domain
  static const String URL = "YOUR_EC2_IP:8080";  // Will update after EC2 setup
  static const String BASE_URL = "http://YOUR_EC2_IP:8080";
  
  // ... rest of the file
}
```

### **1.3 Prepare Environment Variables**

Create `.env` file in `pgworld-api-master/`:

```env
# Database Configuration
DB_HOST=your-rds-endpoint.rds.amazonaws.com
DB_PORT=3306
DB_USER=admin
DB_PASSWORD=your-secure-password
DB_NAME=pgworld

# Server Configuration
PORT=8080
CONNECTION_POOL=10

# AWS S3 Configuration
S3_BUCKET=pgworld-uploads
AWS_REGION=us-east-1

# Email Configuration (Optional)
SUPPORT_EMAIL_ID=support@yourapp.com
SUPPORT_EMAIL_PASSWORD=your-email-password
SUPPORT_EMAIL_HOST=smtp.gmail.com
SUPPORT_EMAIL_PORT=587

# Environment
ENV=production
```

---

## 🔧 **Step 2: Deploy Backend to EC2 (20 minutes)**

### **2.1 Build Backend**

```bash
cd pgworld-api-master

# Build for Linux (EC2)
GOOS=linux GOARCH=amd64 go build -o pgworld-api main.go

# Verify build
ls -lh pgworld-api
```

### **2.2 Create EC2 Instance**

Using AWS Console:
1. Go to EC2 Dashboard
2. Click "Launch Instance"
3. Choose **Amazon Linux 2023** AMI
4. Instance type: **t2.micro** (or t2.small for production)
5. Create/select key pair: `pgworld-key.pem`
6. Security Group: Allow ports **22 (SSH)** and **8080 (API)**
7. Launch Instance

**Security Group Rules:**
```
Type         Protocol  Port Range  Source
SSH          TCP       22          My IP
Custom TCP   TCP       8080        0.0.0.0/0 (Anywhere)
MySQL        TCP       3306        EC2 Security Group (for RDS)
```

### **2.3 Upload Backend to EC2**

```bash
# Make key file secure
chmod 400 pgworld-key.pem

# Create directory on EC2
ssh -i pgworld-key.pem ec2-user@YOUR_EC2_IP << 'EOF'
mkdir -p ~/pgworld-api
exit
EOF

# Upload binary and .env
scp -i pgworld-key.pem pgworld-api ec2-user@YOUR_EC2_IP:~/pgworld-api/
scp -i pgworld-key.pem .env ec2-user@YOUR_EC2_IP:~/pgworld-api/

# Upload any other needed files
scp -i pgworld-key.pem -r uploads/ ec2-user@YOUR_EC2_IP:~/pgworld-api/
```

### **2.4 Setup Backend on EC2**

```bash
# SSH into EC2
ssh -i pgworld-key.pem ec2-user@YOUR_EC2_IP

# Make binary executable
cd ~/pgworld-api
chmod +x pgworld-api

# Test run (should start without errors)
./pgworld-api

# Press Ctrl+C to stop

# Create systemd service for auto-start
sudo tee /etc/systemd/system/pgworld-api.service > /dev/null << 'EOF'
[Unit]
Description=PG World API Server
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/home/ec2-user/pgworld-api
ExecStart=/home/ec2-user/pgworld-api/pgworld-api
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Start and enable service
sudo systemctl daemon-reload
sudo systemctl start pgworld-api
sudo systemctl enable pgworld-api

# Check status
sudo systemctl status pgworld-api

# View logs
sudo journalctl -u pgworld-api -f
```

### **2.5 Verify Backend**

```bash
# Test API from your local machine
curl http://YOUR_EC2_IP:8080/

# Should return "ok" or API response
```

---

## 🎨 **Step 3: Deploy Frontend to S3 + CloudFront (15 minutes)**

### **3.1 Update Frontend Config**

```bash
cd pgworld-master

# Update config.dart with EC2 IP
# Config.URL = "YOUR_EC2_IP:8080"
# Config.BASE_URL = "http://YOUR_EC2_IP:8080"
```

### **3.2 Build Frontend**

```bash
# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build for web
flutter build web --release --no-source-maps

# Verify build
ls -lh build/web/
```

### **3.3 Create S3 Bucket**

Using AWS Console:
1. Go to S3 Dashboard
2. Click "Create bucket"
3. Bucket name: `pgworld-admin-portal`
4. Region: Same as EC2 (e.g., us-east-1)
5. Uncheck "Block all public access"
6. Create bucket

**Bucket Policy:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::pgworld-admin-portal/*"
    }
  ]
}
```

**Enable Static Website Hosting:**
- Index document: `index.html`
- Error document: `index.html`

### **3.4 Upload Frontend to S3**

Using AWS CLI:
```bash
# Install AWS CLI if not already installed
# aws configure (enter your credentials)

# Upload files
aws s3 sync build/web/ s3://pgworld-admin-portal/ --delete

# Set cache control
aws s3 cp s3://pgworld-admin-portal/ s3://pgworld-admin-portal/ \
  --recursive \
  --metadata-directive REPLACE \
  --cache-control max-age=31536000,public
```

Or using AWS Console:
1. Go to S3 bucket
2. Click "Upload"
3. Upload all files from `build/web/`
4. Set permissions to public

### **3.5 Create CloudFront Distribution (Optional but Recommended)**

1. Go to CloudFront Dashboard
2. Click "Create Distribution"
3. Origin Domain: Select your S3 bucket
4. Default Cache Behavior: Redirect HTTP to HTTPS
5. Default Root Object: `index.html`
6. Create Distribution

**Note:** CloudFront takes 15-20 minutes to deploy.

---

## 💾 **Step 4: Setup Database (10 minutes)**

### **Option A: Use Existing RDS (Recommended)**

Your terraform setup already created RDS. Update connection:

```bash
# Get RDS endpoint from AWS Console or terraform output
terraform output db_endpoint

# Update .env on EC2 with correct endpoint
ssh -i pgworld-key.pem ec2-user@YOUR_EC2_IP
cd ~/pgworld-api
nano .env
# Update DB_HOST with RDS endpoint

# Restart API
sudo systemctl restart pgworld-api
```

### **Option B: Run Database Migrations**

```bash
# SSH to EC2
ssh -i pgworld-key.pem ec2-user@YOUR_EC2_IP

# Install MySQL client
sudo yum install -y mysql

# Connect to RDS
mysql -h YOUR_RDS_ENDPOINT -u admin -p

# Run migrations
USE pgworld;

-- Create RBAC tables if not exist
CREATE TABLE IF NOT EXISTS admin_permissions (
  id VARCHAR(12) PRIMARY KEY,
  admin_id VARCHAR(12) NOT NULL,
  hostel_id VARCHAR(12) NOT NULL,
  role VARCHAR(20) NOT NULL,
  can_view_dashboard BOOLEAN DEFAULT FALSE,
  can_manage_rooms BOOLEAN DEFAULT FALSE,
  can_manage_tenants BOOLEAN DEFAULT FALSE,
  can_manage_bills BOOLEAN DEFAULT FALSE,
  can_view_financials BOOLEAN DEFAULT FALSE,
  can_manage_employees BOOLEAN DEFAULT FALSE,
  can_view_reports BOOLEAN DEFAULT FALSE,
  can_manage_notices BOOLEAN DEFAULT FALSE,
  can_manage_issues BOOLEAN DEFAULT FALSE,
  can_manage_payments BOOLEAN DEFAULT FALSE,
  assigned_by VARCHAR(12) NOT NULL,
  status ENUM('0', '1') DEFAULT '1',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (admin_id) REFERENCES admins(id),
  FOREIGN KEY (hostel_id) REFERENCES hostels(id)
);

-- Add role column to admins if not exists
ALTER TABLE admins ADD COLUMN IF NOT EXISTS role ENUM('owner', 'manager') DEFAULT 'owner';
ALTER TABLE admins ADD COLUMN IF NOT EXISTS parent_admin_id VARCHAR(12) NULL;
ALTER TABLE admins ADD COLUMN IF NOT EXISTS assigned_hostel_ids TEXT NULL;

-- Verify
SHOW TABLES;
DESCRIBE admin_permissions;
```

---

## ✅ **Step 5: Post-Deployment Testing (10 minutes)**

### **5.1 Test Backend API**

```bash
# Health check
curl http://YOUR_EC2_IP:8080/

# Test admin login
curl -X GET "http://YOUR_EC2_IP:8080/admin?username=test&email=test@example.com" \
  -H "apikey: your-api-key" \
  -H "appversion: 1.0"

# Test permissions endpoint
curl -X GET "http://YOUR_EC2_IP:8080/permissions/get?admin_id=ADMIN_ID&hostel_id=HOSTEL_ID" \
  -H "apikey: your-api-key" \
  -H "appversion: 1.0"
```

### **5.2 Test Frontend**

1. **Via S3:** `http://pgworld-admin-portal.s3-website-us-east-1.amazonaws.com`
2. **Via CloudFront:** `https://YOUR_CLOUDFRONT_DOMAIN.cloudfront.net`

**Test Flow:**
```
1. Open frontend URL
2. Login as owner
3. Go to Settings → Managers
4. Try adding a manager
5. Verify permissions work
6. Login as manager
7. Verify restricted access
```

### **5.3 Monitor Logs**

```bash
# Backend logs
ssh -i pgworld-key.pem ec2-user@YOUR_EC2_IP
sudo journalctl -u pgworld-api -f

# Check for errors
sudo journalctl -u pgworld-api --since "10 minutes ago" | grep -i error
```

---

## 🔒 **Step 6: Security Hardening (5 minutes)**

### **6.1 Enable HTTPS (Recommended)**

**Option A: Using AWS Certificate Manager + CloudFront**
1. Request SSL certificate in ACM
2. Verify domain ownership
3. Attach to CloudFront distribution

**Option B: Using Let's Encrypt on EC2**
```bash
ssh -i pgworld-key.pem ec2-user@YOUR_EC2_IP

# Install certbot
sudo yum install -y certbot

# Get certificate (requires domain)
sudo certbot certonly --standalone -d api.yourdomain.com

# Update nginx/API to use HTTPS
```

### **6.2 Restrict S3 Access**

Update S3 bucket policy to only allow CloudFront:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::cloudfront:user/CloudFront Origin Access Identity YOUR_OAI_ID"
      },
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::pgworld-admin-portal/*"
    }
  ]
}
```

### **6.3 Update Security Groups**

Restrict SSH access:
```
Type    Protocol  Port  Source
SSH     TCP       22    YOUR_IP_ONLY (not 0.0.0.0/0)
```

---

## 📊 **Step 7: Setup Monitoring (Optional)**

### **7.1 CloudWatch Logs**

```bash
# Install CloudWatch agent on EC2
ssh -i pgworld-key.pem ec2-user@YOUR_EC2_IP

sudo yum install -y amazon-cloudwatch-agent

# Configure log streaming
sudo tee /opt/aws/amazon-cloudwatch-agent/etc/config.json > /dev/null << 'EOF'
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/messages",
            "log_group_name": "/aws/ec2/pgworld-api",
            "log_stream_name": "{instance_id}/system"
          }
        ]
      }
    }
  }
}
EOF

sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/config.json \
  -s
```

### **7.2 Setup Alarms**

Create CloudWatch alarms for:
- CPU utilization > 80%
- Memory utilization > 80%
- Disk space < 20%
- API response time > 2s
- Error rate > 5%

---

## 🎉 **Deployment Complete!**

### **Your Application is Now Live:**

**Frontend URL:**
- S3: `http://pgworld-admin-portal.s3-website-us-east-1.amazonaws.com`
- CloudFront: `https://YOUR_DOMAIN.cloudfront.net`

**Backend API:**
- EC2: `http://YOUR_EC2_IP:8080`

**Database:**
- RDS: `YOUR_RDS_ENDPOINT:3306`

---

## 📝 **Quick Reference**

### **Useful Commands:**

```bash
# Restart backend
ssh -i pgworld-key.pem ec2-user@YOUR_EC2_IP
sudo systemctl restart pgworld-api

# View logs
sudo journalctl -u pgworld-api -f

# Update frontend
cd pgworld-master
flutter build web --release
aws s3 sync build/web/ s3://pgworld-admin-portal/ --delete

# CloudFront invalidation (after frontend update)
aws cloudfront create-invalidation \
  --distribution-id YOUR_DISTRIBUTION_ID \
  --paths "/*"

# Database backup
mysqldump -h YOUR_RDS_ENDPOINT -u admin -p pgworld > backup.sql

# Check API health
curl http://YOUR_EC2_IP:8080/
```

### **Troubleshooting:**

**Backend not responding:**
```bash
ssh -i pgworld-key.pem ec2-user@YOUR_EC2_IP
sudo systemctl status pgworld-api
sudo journalctl -u pgworld-api --since "1 hour ago"
```

**Frontend not loading:**
- Check S3 bucket policy
- Verify CloudFront distribution status
- Check browser console for CORS errors

**Database connection failed:**
- Verify RDS security group allows EC2
- Check .env DB_HOST is correct
- Test connection: `mysql -h YOUR_RDS_ENDPOINT -u admin -p`

---

## 🚀 **Next Steps**

1. ✅ **Setup Custom Domain** (Optional)
   - Buy domain from Route 53
   - Point to CloudFront distribution
   - Add SSL certificate

2. ✅ **Enable Backups**
   - RDS automated backups (enabled by default)
   - S3 versioning for uploads
   - EC2 AMI snapshots

3. ✅ **Monitor Performance**
   - Setup CloudWatch dashboards
   - Configure alarms
   - Review logs regularly

4. ✅ **User Training**
   - Share deployment URLs
   - Provide user guides
   - Train owners/managers

---

**Congratulations! Your PGNI application is now live on AWS!** 🎊

Need help with any step? Let me know!

