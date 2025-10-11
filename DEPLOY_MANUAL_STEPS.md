# 🚀 Manual Deployment Steps (Windows)

## Issue: Windows OpenSSH Key Format

Windows OpenSSH is having trouble with the RSA key format. Here are alternative deployment methods:

---

## ✅ OPTION 1: Use PuTTY (Recommended for Windows)

### Step 1: Download PuTTY
1. Download from: https://www.putty.org/
2. Install both **PuTTY** and **PuTTYgen**

### Step 2: Convert Key with PuTTYgen
1. Open **PuTTYgen**
2. Click **"Load"**
3. Select `pgni-preprod-key.pem` (change filter to "All Files")
4. Click **"Save private key"**
5. Save as `pgni-key.ppk`
6. Click **"Yes"** to save without passphrase

### Step 3: Upload Files with WinSCP
1. Download WinSCP: https://winscp.net/
2. Open WinSCP
3. New Session:
   - Host: `34.227.111.143`
   - Username: `ec2-user`
   - Click **"Advanced"** → **"SSH"** → **"Authentication"**
   - Browse to `pgni-key.ppk`
4. Click **"Login"**
5. Upload these files to `/home/ec2-user/`:
   - `preprod.env`
   - `deploy-api.sh`

### Step 4: Connect with PuTTY
1. Open **PuTTY**
2. Host Name: `ec2-user@34.227.111.143`
3. Port: `22`
4. Connection → SSH → Auth → Browse to `pgni-key.ppk`
5. Click **"Open"**

### Step 5: Deploy on EC2
```bash
# Make script executable
chmod +x deploy-api.sh

# Run deployment
./deploy-api.sh
```

---

## ✅ OPTION 2: Use WSL (Windows Subsystem for Linux)

### Step 1: Open WSL/Ubuntu
```bash
# Navigate to mounted drive
cd /mnt/c/MyFolder/Mytest/pgworld-master

# Fix key permissions
chmod 600 pgni-preprod-key.pem
```

### Step 2: Upload Files
```bash
# Upload environment file
scp -i pgni-preprod-key.pem preprod.env ec2-user@34.227.111.143:~/

# Upload deploy script
scp -i pgni-preprod-key.pem deploy-api.sh ec2-user@34.227.111.143:~/
```

### Step 3: SSH and Deploy
```bash
# Connect
ssh -i pgni-preprod-key.pem ec2-user@34.227.111.143

# Once connected:
chmod +x deploy-api.sh
./deploy-api.sh
```

---

## ✅ OPTION 3: Use AWS Systems Manager (No SSH Needed!)

### Step 1: Enable SSM on EC2
The EC2 already has SSM agent and IAM role configured!

### Step 2: Connect via Browser
1. Go to: https://console.aws.amazon.com/ec2/
2. Find instance: `i-0909d462845deb151`
3. Click **"Connect"**
4. Choose **"Session Manager"** tab
5. Click **"Connect"**

### Step 3: Deploy via Browser Terminal
```bash
# Switch to ec2-user
sudo su - ec2-user
cd ~

# Create env file manually (copy-paste content from preprod.env)
cat > preprod.env << 'EOF'
[Paste content of preprod.env here]
EOF

# Create deploy script (copy-paste content from deploy-api.sh)
cat > deploy-api.sh << 'EOF'
[Paste content of deploy-api.sh here]
EOF

# Make executable and run
chmod +x deploy-api.sh
./deploy-api.sh
```

---

## ✅ OPTION 4: Manual Deployment (Step by Step)

If you can connect via any method, here's the manual deployment:

### On EC2 Instance:

```bash
# 1. Clone repository
git clone https://github.com/siddam01/pgni.git
cd pgni/pgworld-api-master

# 2. Create environment file
sudo mkdir -p /opt/pgworld

# Copy your preprod.env content to /opt/pgworld/.env
sudo nano /opt/pgworld/.env
# Paste the content, then Ctrl+X, Y, Enter

# 3. Build API
/usr/local/go/bin/go build -o /opt/pgworld/pgworld-api .

# 4. Start service
sudo systemctl start pgworld-api
sudo systemctl enable pgworld-api

# 5. Check status
sudo systemctl status pgworld-api

# 6. View logs
sudo journalctl -u pgworld-api -f
```

---

## 📋 Environment File Content (preprod.env)

```env
# Database Configuration
DB_HOST=database-pgni.cezawkgguojl.us-east-1.rds.amazonaws.com
DB_PORT=3306
DB_USER=admin
DB_PASSWORD=Omsairamdb951#
DB_NAME=pgworld

# AWS Configuration
AWS_REGION=us-east-1
S3_BUCKET=pgni-preprod-698302425856-uploads

# API Configuration
PORT=8080
test=false

# API Keys (if needed)
# Add your API keys here
```

---

## ✅ Validation Steps

### 1. Check API Health
```bash
curl http://34.227.111.143:8080/health
```

**Expected:** `{"status":"healthy"}` or `{"status":"ok"}`

### 2. Check Service Status
```bash
sudo systemctl status pgworld-api
```

**Expected:** `Active: active (running)`

### 3. Check Logs
```bash
sudo journalctl -u pgworld-api -n 50
```

**Look for:** No errors, successful startup messages

### 4. Check Database Connection
```bash
mysql -h database-pgni.cezawkgguojl.us-east-1.rds.amazonaws.com -u admin -p
# Password: Omsairamdb951#

# Then:
SHOW DATABASES;
USE pgworld;
SHOW TABLES;
```

### 5. Test from Local Machine
```bash
curl http://34.227.111.143:8080/health
```

Or open in browser:
```
http://34.227.111.143:8080/health
```

---

## 🔧 Troubleshooting

### Service Won't Start
```bash
# Check detailed logs
sudo journalctl -u pgworld-api -n 100 --no-pager

# Check if port is in use
sudo netstat -tlnp | grep 8080

# Check environment file
cat /opt/pgworld/.env

# Try running manually
cd /opt/pgworld
./pgworld-api
```

### Database Connection Failed
```bash
# Test connection
mysql -h database-pgni.cezawkgguojl.us-east-1.rds.amazonaws.com -u admin -p

# Check security group
# Make sure RDS security group allows EC2 security group
```

### API Not Accessible
```bash
# Check if service is running
sudo systemctl status pgworld-api

# Check if listening on port
sudo netstat -tlnp | grep 8080

# Check security group allows port 8080
```

---

## 📞 Quick Reference

**EC2 IP:** `34.227.111.143`  
**API URL:** `http://34.227.111.143:8080`  
**Health Check:** `http://34.227.111.143:8080/health`  
**Database:** `database-pgni.cezawkgguojl.us-east-1.rds.amazonaws.com:3306`  
**S3 Bucket:** `pgni-preprod-698302425856-uploads`

---

**Choose the method that works best for you!**

**Recommended:** Option 1 (PuTTY + WinSCP) or Option 3 (AWS Systems Manager)

