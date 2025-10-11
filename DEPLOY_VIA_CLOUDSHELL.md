# 🚀 Deploy via AWS CloudShell (EASIEST METHOD!)

## Why This Works Best
- No SSH key format issues
- Pre-authenticated with AWS
- No software installation needed
- Browser-based, works anywhere

---

## Step 1: Open AWS CloudShell

1. Go to: https://console.aws.amazon.com/cloudshell/
2. Login with your AWS account
3. CloudShell will open in your browser

---

## Step 2: Get Terraform SSH Key

In CloudShell, run:

```bash
# Clone your repository (if needed)
# Or download key directly from S3 if you stored it there

# Get SSH key from Terraform
cd /tmp
cat > get-ssh-key.sh << 'EOF'
#!/bin/bash
# This will output the SSH key - save it to a file
echo "-----BEGIN RSA PRIVATE KEY-----
[YOUR KEY CONTENT FROM terraform output -raw ssh_private_key]
-----END RSA PRIVATE KEY-----"
EOF

chmod +x get-ssh-key.sh
./get-ssh-key.sh > ec2-key.pem
chmod 600 ec2-key.pem
```

---

## Step 3: Create Environment File

```bash
cat > preprod.env << 'EOF'
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
EOF
```

---

## Step 4: Create Deployment Script

```bash
cat > deploy-api.sh << 'EOF'
#!/bin/bash
set -e

echo "========================================="
echo "PGNi API Deployment Script"
echo "========================================="
echo ""

# Install Go if not present
if ! command -v go &> /dev/null; then
    echo "Installing Go..."
    wget https://go.dev/dl/go1.21.0.linux-amd64.tar.gz
    sudo tar -C /usr/local -xzf go1.21.0.linux-amd64.tar.gz
    export PATH=$PATH:/usr/local/go/bin
fi

# Clone repository
echo "Cloning repository..."
if [ -d "pgni" ]; then
    cd pgni
    git pull
else
    git clone https://github.com/siddam01/pgni.git
    cd pgni
fi

# Build API
echo "Building API..."
cd pgworld-api-master
/usr/local/go/bin/go build -o pgworld-api .

# Setup directory
echo "Setting up application..."
sudo mkdir -p /opt/pgworld
sudo cp pgworld-api /opt/pgworld/
sudo cp ~/preprod.env /opt/pgworld/.env

# Create systemd service
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

# Start service
echo "Starting service..."
sudo systemctl daemon-reload
sudo systemctl enable pgworld-api
sudo systemctl restart pgworld-api

echo ""
echo "Waiting for service to start..."
sleep 5

# Check status
sudo systemctl status pgworld-api --no-pager

echo ""
echo "========================================="
echo "Deployment Complete!"
echo "========================================="
echo ""
echo "API URL: http://34.227.111.143:8080"
echo "Health: http://34.227.111.143:8080/health"
echo ""
EOF

chmod +x deploy-api.sh
```

---

## Step 5: Upload and Deploy

```bash
# Set EC2 IP
EC2_IP="34.227.111.143"

# Upload files
scp -i ec2-key.pem -o StrictHostKeyChecking=no preprod.env ec2-user@$EC2_IP:~/
scp -i ec2-key.pem -o StrictHostKeyChecking=no deploy-api.sh ec2-user@$EC2_IP:~/

# Connect and deploy
ssh -i ec2-key.pem -o StrictHostKeyChecking=no ec2-user@$EC2_IP "chmod +x deploy-api.sh && ./deploy-api.sh"
```

---

## Step 6: Validate

```bash
# Test health endpoint
curl http://34.227.111.143:8080/health

# Or from CloudShell
aws ec2 describe-instances --instance-ids i-0909d462845deb151 --query 'Reservations[0].Instances[0].State.Name'
```

---

## Alternative: Direct SSH from CloudShell

Since CloudShell has AWS credentials, you can also connect via Systems Manager:

```bash
# Install session manager plugin (if needed)
aws ssm start-session --target i-0909d462845deb151
```

Then run commands directly on EC2!

---

## 🎯 Summary

**CloudShell eliminates:**
- ✅ Windows SSH key format issues
- ✅ OpenSSH installation problems
- ✅ Permission issues
- ✅ Credential configuration

**Just open CloudShell and run the commands above!**

---

## Quick Copy-Paste Version

```bash
# In AWS CloudShell:

# 1. Get SSH key from your local machine's terraform output
# Copy the terraform output -raw ssh_private_key content and paste:
cat > ec2-key.pem << 'EOF'
[PASTE SSH KEY HERE]
EOF
chmod 600 ec2-key.pem

# 2. Create environment file
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

# 3. Upload and execute deployment
EC2_IP="34.227.111.143"
scp -i ec2-key.pem -o StrictHostKeyChecking=no preprod.env ec2-user@$EC2_IP:~/

# 4. SSH and deploy manually
ssh -i ec2-key.pem -o StrictHostKeyChecking=no ec2-user@$EC2_IP

# Once connected:
git clone https://github.com/siddam01/pgni.git
cd pgni/pgworld-api-master
/usr/local/go/bin/go build -o pgworld-api .
sudo mkdir -p /opt/pgworld
sudo cp pgworld-api /opt/pgworld/
sudo cp ~/preprod.env /opt/pgworld/.env
sudo systemctl restart pgworld-api
sudo systemctl status pgworld-api
```

**Test:** `curl http://34.227.111.143:8080/health`

---

**This is the EASIEST way to deploy from Windows!**

