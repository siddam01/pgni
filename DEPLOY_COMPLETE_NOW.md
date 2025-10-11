# 🚀 Complete Deployment Guide - All Steps in One Place

**Total Time: 15-20 minutes**

---

## ✅ Pre-Deployment Status

**Infrastructure:** ✅ Ready (36 AWS resources deployed)
- EC2: `34.227.111.143` (Running)
- RDS: `database-pgni` (Available)
- S3: `pgni-preprod-698302425856-uploads` (Active)

**Files:** ✅ Ready
- SSH Key: Extracted to `ssh-key-for-cloudshell.txt`
- Environment: `preprod.env` configured
- Deployment Script: `deploy-api.sh` ready

---

## 🎯 Complete Deployment - Method 1: AWS CloudShell (EASIEST)

### Step 1: Open SSH Key File (Windows)

**On your Windows machine:**

```powershell
# View the SSH key
notepad ssh-key-for-cloudshell.txt
```

**Select ALL the content and COPY it** (Ctrl+A, Ctrl+C)

---

### Step 2: Open AWS CloudShell

1. Go to: **https://console.aws.amazon.com/cloudshell/**
2. Wait for CloudShell to initialize (~10 seconds)
3. You'll see a terminal in your browser

---

### Step 3: Create SSH Key in CloudShell

**Paste this in CloudShell:**

```bash
cat > ec2-key.pem << 'EOF'
```

**Now paste your SSH key** (Ctrl+V or Right-click → Paste)

**Then type:**
```bash
EOF
```

**Fix permissions:**
```bash
chmod 600 ec2-key.pem
```

---

### Step 4: Create Environment File

**Paste this entire block in CloudShell:**

```bash
cat > preprod.env << 'EOF'
DB_HOST=database-pgni.cezawkgguojl.us-east-1.rds.amazonaws.com
DB_PORT=3306
DB_USER=admin
DB_PASSWORD=Omsairamdb951#
DB_NAME=pgworld
AWS_REGION=us-east-1
S3_BUCKET=pgni-preprod-698302425856-uploads
PORT=8080
test=false
EOF
```

---

### Step 5: Upload to EC2

```bash
# Set EC2 IP
EC2_IP="34.227.111.143"

# Upload environment file
scp -i ec2-key.pem -o StrictHostKeyChecking=no preprod.env ec2-user@$EC2_IP:~/

# Confirm upload
echo "File uploaded successfully!"
```

---

### Step 6: Connect to EC2

```bash
ssh -i ec2-key.pem -o StrictHostKeyChecking=no ec2-user@$EC2_IP
```

**You should now be connected to your EC2 instance!**

---

### Step 7: Deploy API (On EC2)

**Paste these commands one by one:**

```bash
# 1. Clone repository
echo "Cloning repository..."
if [ -d "pgni" ]; then
    cd pgni && git pull && cd ..
else
    git clone https://github.com/siddam01/pgni.git
fi

# 2. Build API
echo "Building API..."
cd pgni/pgworld-api-master
/usr/local/go/bin/go build -o pgworld-api .

# 3. Check if build succeeded
if [ -f "pgworld-api" ]; then
    echo "Build successful!"
else
    echo "Build failed!"
    exit 1
fi

# 4. Deploy to /opt/pgworld
echo "Deploying..."
sudo mkdir -p /opt/pgworld
sudo cp pgworld-api /opt/pgworld/
sudo cp ~/preprod.env /opt/pgworld/.env
sudo chown -R ec2-user:ec2-user /opt/pgworld

# 5. Create systemd service (if not exists)
if [ ! -f /etc/systemd/system/pgworld-api.service ]; then
    echo "Creating service..."
    sudo tee /etc/systemd/system/pgworld-api.service > /dev/null << 'SERVICE'
[Unit]
Description=PGWorld API Server
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/opt/pgworld
ExecStart=/opt/pgworld/pgworld-api
EnvironmentFile=/opt/pgworld/.env
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
SERVICE
fi

# 6. Start service
echo "Starting service..."
sudo systemctl daemon-reload
sudo systemctl enable pgworld-api
sudo systemctl restart pgworld-api

# 7. Wait for service to start
echo "Waiting for service to start..."
sleep 5

# 8. Check status
sudo systemctl status pgworld-api --no-pager

echo ""
echo "================================================"
echo "Deployment complete!"
echo "================================================"
```

---

### Step 8: Validate Deployment

**Still on EC2, run:**

```bash
# Check service status
sudo systemctl status pgworld-api

# Check logs
sudo journalctl -u pgworld-api -n 50

# Test health endpoint locally
curl http://localhost:8080/health

# Test from public IP
curl http://34.227.111.143:8080/health
```

**Expected response:**
```json
{"status":"healthy"}
```
or
```json
{"status":"ok"}
```

---

### Step 9: Create Database

```bash
# Connect to database
mysql -h database-pgni.cezawkgguojl.us-east-1.rds.amazonaws.com -u admin -p
# Password: Omsairamdb951#
```

**In MySQL prompt:**
```sql
CREATE DATABASE IF NOT EXISTS pgworld CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE pgworld;
SHOW TABLES;
EXIT;
```

---

### Step 10: Final Test

**Exit EC2 and return to CloudShell:**
```bash
exit
```

**Test from CloudShell:**
```bash
curl http://34.227.111.143:8080/health
```

**Test from your Windows machine (PowerShell):**
```powershell
Invoke-WebRequest -Uri http://34.227.111.143:8080/health
```

**Test from browser:**
Open: http://34.227.111.143:8080/health

---

## ✅ Success Criteria

You should see:

1. ✅ Service status: `active (running)`
2. ✅ Health endpoint returns: `{"status":"healthy"}`
3. ✅ No errors in logs
4. ✅ Database connected
5. ✅ API accessible from anywhere

---

## 🎯 Alternative Method: PuTTY (If CloudShell Fails)

### Requirements:
- Download PuTTY: https://www.putty.org/
- Download WinSCP: https://winscp.net/

### Steps:

1. **Convert SSH Key:**
   - Open PuTTYgen
   - Load `pgni-preprod-key.pem`
   - Save as `pgni-key.ppk`

2. **Upload Files (WinSCP):**
   - Host: `34.227.111.143`
   - User: `ec2-user`
   - Auth: Use `pgni-key.ppk`
   - Upload: `preprod.env` to home directory

3. **Connect (PuTTY):**
   - Host: `34.227.111.143`
   - User: `ec2-user`
   - Auth: Use `pgni-key.ppk`

4. **Deploy:**
   - Follow Step 7 above (same commands)

---

## 🚨 Troubleshooting

### Service Won't Start

```bash
# Check detailed logs
sudo journalctl -u pgworld-api -n 100 --no-pager

# Try manual run
cd /opt/pgworld
./pgworld-api
```

### Database Connection Failed

```bash
# Test connection
mysql -h database-pgni.cezawkgguojl.us-east-1.rds.amazonaws.com -u admin -p

# Check environment file
cat /opt/pgworld/.env
```

### Port Not Accessible

```bash
# Check if listening
sudo netstat -tlnp | grep 8080

# Check security group in AWS Console
# Make sure port 8080 is open
```

### Build Failed

```bash
# Check Go version
/usr/local/go/bin/go version

# Check error details
cd ~/pgni/pgworld-api-master
/usr/local/go/bin/go build -v -o pgworld-api .
```

---

## 📱 Next Steps: Update Mobile Apps

### After API is deployed and working:

1. **Update API endpoint in Admin App:**
   ```
   pgworld-master/lib/config.dart (or similar)
   Change to: http://34.227.111.143:8080
   ```

2. **Update API endpoint in Tenant App:**
   ```
   pgworldtenant-master/lib/config.dart (or similar)
   Change to: http://34.227.111.143:8080
   ```

3. **Rebuild apps:**
   ```bash
   cd pgworld-master
   flutter clean
   flutter pub get
   flutter build apk

   cd ../pgworldtenant-master
   flutter clean
   flutter pub get
   flutter build apk
   ```

---

## 📊 Deployment Checklist

- [ ] SSH key extracted
- [ ] AWS CloudShell opened
- [ ] SSH key created in CloudShell
- [ ] Environment file created
- [ ] Files uploaded to EC2
- [ ] Connected to EC2
- [ ] Repository cloned
- [ ] API built successfully
- [ ] Service created
- [ ] Service started
- [ ] Health endpoint working
- [ ] Database created
- [ ] Logs checked (no errors)
- [ ] Accessible from internet
- [ ] Mobile apps updated

---

## 💰 Current Costs

**Monthly:** ~$15
- EC2 t2.micro: Free (first 12 months) or $8.50
- RDS db.t3.micro: $14.02
- S3: $0.50
- Data Transfer: $0.50

---

## 📞 Quick Reference

**EC2:** `34.227.111.143`
**API:** `http://34.227.111.143:8080`
**Health:** `http://34.227.111.143:8080/health`

**RDS:** `database-pgni.cezawkgguojl.us-east-1.rds.amazonaws.com:3306`
**User:** `admin`
**Pass:** `Omsairamdb951#`
**DB:** `pgworld`

**S3:** `pgni-preprod-698302425856-uploads`

**Files:**
- `ssh-key-for-cloudshell.txt` - SSH key for EC2
- `preprod.env` - Environment configuration
- `deploy-api.sh` - Deployment script

---

## 🎉 You're All Set!

**Start with Step 1 and follow through to Step 10.**

**Everything will be deployed and validated!**

**Total time: 15-20 minutes**

Good luck! 🚀

