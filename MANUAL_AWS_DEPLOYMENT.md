# Manual AWS Deployment Guide
## Create Infrastructure Without AWS CLI

Since AWS CLI installation requires manual steps, here's how to create everything directly through AWS Console.

---

## ⏱️ Time Required: 45-60 minutes

---

## 📋 What You'll Create

1. **RDS MySQL Database** - For storing PG data
2. **S3 Bucket** - For file uploads
3. **EC2 Instance** - For running the API
4. **Security Groups** - For network security
5. **All Credentials** - Usernames, passwords, keys

---

## 🚀 PHASE 1: Create RDS Database (15 minutes)

### Step 1: Go to RDS Console
1. Login to: https://console.aws.amazon.com/rds/
2. Make sure you're in **us-east-1** region (top right)
3. Click: **"Create database"**

### Step 2: Database Settings
**Engine options:**
- Choose: **MySQL**
- Version: **MySQL 8.0.35** (or latest 8.0.x)

**Templates:**
- Select: **Free tier** ✅

**Settings:**
- DB instance identifier: `pgni-preprod-db`
- Master username: `pgniuser`
- Master password: `PGni2025!Preprod` (or create your own - SAVE THIS!)
- Confirm password: (same as above)

**DB instance class:**
- Select: **db.t3.micro** (Free tier eligible)

**Storage:**
- Storage type: General Purpose SSD (gp2)
- Allocated storage: **20 GB**
- ✅ Enable storage autoscaling
- Maximum storage threshold: **100 GB**

**Connectivity:**
- Virtual private cloud (VPC): Default VPC
- Public access: **YES** ✅ (Important for now)
- VPC security group: Create new
- New VPC security group name: `pgni-preprod-db-sg`

**Database authentication:**
- Password authentication

**Additional configuration:**
- Initial database name: `pgworld`
- ✅ Enable automated backups
- Backup retention period: 7 days
- ✅ Enable encryption (use default key)

### Step 3: Create Database
- Click: **Create database**
- ⏳ Wait 10-15 minutes for creation
- Status will change from "Creating" to "Available"

### Step 4: Note Database Endpoint
Once available:
- Click on the database name
- Copy: **Endpoint** (looks like: `pgni-preprod-db.xxxxx.us-east-1.rds.amazonaws.com`)
- **SAVE THIS!** You'll need it later

---

## 🪣 PHASE 2: Create S3 Bucket (5 minutes)

### Step 1: Go to S3 Console
1. Go to: https://console.aws.amazon.com/s3/
2. Click: **Create bucket**

### Step 2: Bucket Settings
**General configuration:**
- Bucket name: `pgni-preprod-698302425856-uploads` (must be unique globally)
- AWS Region: **us-east-1**

**Object Ownership:**
- Select: **ACLs disabled** (recommended)

**Block Public Access:**
- ❌ Uncheck "Block all public access"
- ✅ Check "I acknowledge..."
- (We need this for file uploads)

**Bucket Versioning:**
- ✅ Enable

**Encryption:**
- Encryption type: **Server-side encryption with Amazon S3 managed keys (SSE-S3)**
- Or use your KMS key: `arn:aws:kms:us-east-1:698302425856:key/mrk-1b96d9eeccf649e695ed6ac2b13cb619`

### Step 3: Create Bucket
- Click: **Create bucket**

### Step 4: Configure CORS
1. Click on your bucket name
2. Go to: **Permissions** tab
3. Scroll to: **Cross-origin resource sharing (CORS)**
4. Click: **Edit**
5. Paste this:

```json
[
    {
        "AllowedHeaders": ["*"],
        "AllowedMethods": ["GET", "PUT", "POST", "DELETE", "HEAD"],
        "AllowedOrigins": ["*"],
        "ExposeHeaders": ["ETag"],
        "MaxAgeSeconds": 3000
    }
]
```

6. Click: **Save changes**

---

## 💻 PHASE 3: Create EC2 Instance (15 minutes)

### Step 1: Go to EC2 Console
1. Go to: https://console.aws.amazon.com/ec2/
2. Click: **Launch instance**

### Step 2: Instance Settings
**Name and tags:**
- Name: `pgni-preprod-api`

**Application and OS Images:**
- Quick Start: **Amazon Linux**
- Amazon Machine Image: **Amazon Linux 2023 AMI** (Free tier eligible)

**Instance type:**
- Select: **t3.micro** (Free tier eligible)

**Key pair:**
- Click: **Create new key pair**
- Key pair name: `pgni-preprod-key`
- Key pair type: RSA
- Private key file format: **.pem**
- Click: **Create key pair**
- **IMPORTANT:** File will download - SAVE IT SECURELY!

**Network settings:**
- Click: **Edit**
- VPC: Default
- Auto-assign public IP: **Enable**
- Firewall (security groups): **Create security group**
- Security group name: `pgni-preprod-api-sg`
- Description: `Security group for PGNi Pre-Prod API`

**Inbound security group rules:**
Add these rules:

1. **SSH:**
   - Type: SSH
   - Port: 22
   - Source: My IP (or 0.0.0.0/0 for testing)

2. **HTTP:**
   - Click: Add security group rule
   - Type: Custom TCP
   - Port: 8080
   - Source: 0.0.0.0/0

3. **HTTPS (optional):**
   - Type: HTTPS
   - Port: 443
   - Source: 0.0.0.0/0

**Configure storage:**
- Size: **20 GB**
- Root volume type: gp3

### Step 3: Launch Instance
- Click: **Launch instance**
- Wait 2-3 minutes for instance to start

### Step 4: Note Public IP
1. Go to: **Instances**
2. Click on your instance
3. Copy: **Public IPv4 address**
4. **SAVE THIS!** (e.g., 54.123.45.67)

---

## 🔒 PHASE 4: Configure RDS Security Group (5 minutes)

### Step 1: Allow EC2 to Access RDS
1. Go to: EC2 Console → Security Groups
2. Find: `pgni-preprod-db-sg`
3. Click on it
4. Go to: **Inbound rules** tab
5. Click: **Edit inbound rules**

### Step 2: Add MySQL Rule
- Click: **Add rule**
- Type: **MySQL/Aurora**
- Port: 3306
- Source: **Custom** → Select `pgni-preprod-api-sg` (your API security group)
- Description: `Allow API to access database`
- Click: **Save rules**

---

## 📝 PHASE 5: Deploy API to EC2 (15 minutes)

### Step 1: Connect to EC2
Open PowerShell and run:

```powershell
# Navigate to where you saved the key
cd C:\Users\YOUR_USERNAME\Downloads

# Set permissions (Windows)
icacls pgni-preprod-key.pem /inheritance:r
icacls pgni-preprod-key.pem /grant:r "$($env:USERNAME):R"

# Connect to EC2 (replace with your IP)
ssh -i pgni-preprod-key.pem ec2-user@YOUR_EC2_PUBLIC_IP
```

### Step 2: Install Dependencies on EC2

Once connected, run these commands:

```bash
# Update system
sudo yum update -y

# Install Go
cd /tmp
wget https://go.dev/dl/go1.21.0.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.21.0.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
source ~/.bashrc

# Verify Go
go version

# Install Git
sudo yum install git -y

# Install MySQL client
sudo yum install mysql -y
```

### Step 3: Clone and Build API

```bash
# Clone repository
git clone https://github.com/siddam01/pgni.git
cd pgni/pgworld-api-master

# Create app directory
sudo mkdir -p /opt/pgworld
sudo chown ec2-user:ec2-user /opt/pgworld

# Build API
go build -o /opt/pgworld/pgworld-api .
```

### Step 4: Create Environment File

```bash
# Create .env file
sudo nano /opt/pgworld/.env
```

**Paste this (UPDATE with your values):**

```env
# Database Configuration
DB_HOST=YOUR_RDS_ENDPOINT
DB_PORT=3306
DB_USER=pgniuser
DB_PASSWORD=PGni2025!Preprod
DB_NAME=pgworld

# S3 Configuration
AWS_REGION=us-east-1
S3_BUCKET=pgni-preprod-698302425856-uploads

# API Configuration
PORT=8080
test=false

# API Keys (generate random strings)
ANDROID_LIVE_KEY=your_android_live_key_here
ANDROID_TEST_KEY=your_android_test_key_here
IOS_LIVE_KEY=your_ios_live_key_here
IOS_TEST_KEY=your_ios_test_key_here

# JWT Secret (generate random string)
JWT_SECRET=your_jwt_secret_here
```

**Save:** Ctrl+X, Y, Enter

### Step 5: Initialize Database

```bash
# Test database connection
mysql -h YOUR_RDS_ENDPOINT -u pgniuser -p

# Enter password: PGni2025!Preprod

# If connected successfully, exit:
exit
```

### Step 6: Create Systemd Service

```bash
sudo nano /etc/systemd/system/pgworld-api.service
```

**Paste this:**

```ini
[Unit]
Description=PGWorld API Service
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/opt/pgworld
EnvironmentFile=/opt/pgworld/.env
ExecStart=/opt/pgworld/pgworld-api
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

**Save:** Ctrl+X, Y, Enter

### Step 7: Start API Service

```bash
# Reload systemd
sudo systemctl daemon-reload

# Enable service (start on boot)
sudo systemctl enable pgworld-api

# Start service
sudo systemctl start pgworld-api

# Check status
sudo systemctl status pgworld-api

# Check logs
sudo journalctl -u pgworld-api -f
```

### Step 8: Test API

```bash
# Test from EC2
curl http://localhost:8080/health

# Should return: {"status":"ok"}
```

### Step 9: Test from Your Computer

Open browser or PowerShell:
```powershell
curl http://YOUR_EC2_PUBLIC_IP:8080/health
```

---

## ✅ PHASE 6: Save All Credentials

Create a file on your computer with all this information:

```
=== PGNi Pre-Production Environment ===

RDS Database:
- Endpoint: YOUR_RDS_ENDPOINT
- Port: 3306
- Username: pgniuser
- Password: PGni2025!Preprod
- Database: pgworld

S3 Bucket:
- Name: pgni-preprod-698302425856-uploads
- Region: us-east-1

EC2 Instance:
- Public IP: YOUR_EC2_PUBLIC_IP
- SSH Key: pgni-preprod-key.pem
- SSH Command: ssh -i pgni-preprod-key.pem ec2-user@YOUR_EC2_PUBLIC_IP

API:
- URL: http://YOUR_EC2_PUBLIC_IP:8080
- Health: http://YOUR_EC2_PUBLIC_IP:8080/health

Security Groups:
- Database: pgni-preprod-db-sg
- API: pgni-preprod-api-sg

Created: [DATE]
```

---

## 🎯 Next Steps

### 1. Update Flutter Apps

Edit your Flutter app configuration:

**Admin App:** `pgworld-master/lib/config.dart`
```dart
const String API_BASE_URL = 'http://YOUR_EC2_PUBLIC_IP:8080';
```

**Tenant App:** `pgworldtenant-master/lib/config.dart`
```dart
const String API_BASE_URL = 'http://YOUR_EC2_PUBLIC_IP:8080';
```

### 2. Rebuild Apps

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

### 3. Test Everything

1. Install app on phone
2. Create account
3. Add PG
4. Upload photo (tests S3)
5. Add tenant
6. Record payment

---

## 💰 Cost Estimate

### Free Tier (First 12 Months):
- RDS db.t3.micro: FREE (750 hours/month)
- EC2 t3.micro: FREE (750 hours/month)
- S3: FREE (5 GB storage, 20,000 GET requests)
- Data transfer: FREE (100 GB/month)

**Total: $0-5/month** 💚

### After Free Tier:
- RDS: ~$15/month
- EC2: ~$8/month
- S3: ~$1/month
- **Total: ~$25/month**

---

## 🆘 Troubleshooting

### Database Connection Failed
```bash
# Check security group allows EC2
# Check RDS endpoint is correct
# Test with mysql client:
mysql -h YOUR_RDS_ENDPOINT -u pgniuser -p
```

### API Won't Start
```bash
# Check logs
sudo journalctl -u pgworld-api -f

# Check if port 8080 is available
sudo netstat -tlnp | grep 8080

# Restart service
sudo systemctl restart pgworld-api
```

### Can't Connect from Internet
```bash
# Check EC2 security group allows port 8080
# Check EC2 instance is running
# Try from EC2 first: curl http://localhost:8080/health
```

### S3 Upload Fails
- Check bucket name in .env
- Check CORS is configured
- Check bucket permissions

---

## 📞 Summary

### What You Created:
- ✅ MySQL Database (RDS)
- ✅ File Storage (S3)
- ✅ API Server (EC2)
- ✅ Security Groups
- ✅ Working API

### Access Information:
- API URL: http://YOUR_EC2_PUBLIC_IP:8080
- Database: YOUR_RDS_ENDPOINT:3306
- Storage: s3://pgni-preprod-698302425856-uploads

### Time Spent:
- ~45-60 minutes manual setup

### Ready For:
- Flutter app testing
- PG owner usage
- Production deployment (repeat with production values)

---

**Congratulations! Your pre-production environment is live!** 🎉

*Created: January 8, 2025*

