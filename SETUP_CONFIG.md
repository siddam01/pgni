# 🔧 Auto-Configuration Setup for PGNI Deployment

## 🎯 How Auto-Detection Works

The deployment script now **automatically detects** your AWS configuration:

### ✅ **What Gets Auto-Detected:**

1. **EC2 Public IP** - From AWS metadata service
2. **RDS Endpoint** - Searches for available RDS instances
3. **Database Name** - From RDS instance configuration
4. **Database User** - From RDS master username
5. **S3 Bucket** - Searches for buckets matching "pgworld-admin"

### 🔐 **What You Need to Provide:**

- **Database Password** (for security, cannot be auto-detected)

---

## 📋 **Configuration File: `~/.pgni-config`**

After first run, the script saves configuration to `~/.pgni-config`:

```bash
EC2_IP="54.227.101.30"
RDS_ENDPOINT="database-pgni.cezawkgguojl.us-east-1.rds.amazonaws.com"
DB_USER="admin"
DB_NAME="pgworld"
S3_BUCKET="pgworld-admin"
```

### **On Subsequent Runs:**

The script will:
1. ✅ Load saved configuration
2. ✅ Ask if you want to use it: `Use these settings? (y/n) [y]:`
3. ✅ Skip auto-detection if you say yes
4. ✅ Only ask for database password

---

## 🚀 **Quick Setup: Create Config Manually**

If you want to **skip all prompts**, create the config file manually:

```bash
# On your EC2 instance
cat > ~/.pgni-config << 'EOF'
EC2_IP="54.227.101.30"
RDS_ENDPOINT="database-pgni.cezawkgguojl.us-east-1.rds.amazonaws.com"
DB_USER="admin"
DB_NAME="pgworld"
S3_BUCKET="pgworld-admin"
EOF

chmod 600 ~/.pgni-config
```

Then run deployment:
```bash
bash <(curl -sL https://raw.githubusercontent.com/siddam01/pgni/main/EC2_DEPLOY_MASTER.sh)
```

You'll only be prompted for:
- Confirmation to use saved settings: Press `Enter` (defaults to `y`)
- Database password: Enter your password
- Continue deployment: Press `Enter` (defaults to `Y`)

---

## 📊 **Your Current Configuration:**

Based on your deployment attempt, use these values:

```bash
cat > ~/.pgni-config << 'EOF'
EC2_IP="54.227.101.30"
RDS_ENDPOINT="database-pgni.cezawkgguojl.us-east-1.rds.amazonaws.com"
DB_USER="admin"
DB_NAME="pgworld"
S3_BUCKET="pgworld-admin"
EOF

chmod 600 ~/.pgni-config
```

---

## ⚡ **Fully Automated Deployment**

### **Option 1: With Password Environment Variable**

```bash
# Set password (will be hidden in process list)
export PGNI_DB_PASSWORD="your_password_here"

# Run deployment
bash <(curl -sL https://raw.githubusercontent.com/siddam01/pgni/main/EC2_DEPLOY_MASTER.sh)
```

### **Option 2: With Config File**

```bash
# Create config file first
cat > ~/.pgni-config << 'EOF'
EC2_IP="54.227.101.30"
RDS_ENDPOINT="database-pgni.cezawkgguojl.us-east-1.rds.amazonaws.com"
DB_USER="admin"
DB_NAME="pgworld"
S3_BUCKET="pgworld-admin"
EOF

chmod 600 ~/.pgni-config

# Run deployment (only password prompt)
bash <(curl -sL https://raw.githubusercontent.com/siddam01/pgni/main/EC2_DEPLOY_MASTER.sh)
```

---

## 🔄 **Update Configuration**

### **View Current Config:**
```bash
cat ~/.pgni-config
```

### **Edit Config:**
```bash
nano ~/.pgni-config
```

### **Delete Config (Start Fresh):**
```bash
rm ~/.pgni-config
```

---

## 🎯 **Deployment Flow**

### **First Time (No Config):**
```
📋 Step 1: Auto-detecting AWS Configuration
Auto-detecting AWS resources...
✅ EC2 Public IP: 54.227.101.30
Searching for RDS instances...
✅ Found RDS: database-pgni.cezawkgguojl.us-east-1.rds.amazonaws.com
✅ Database Name: pgworld
✅ Database User: admin
Enter Database Password: ********
Searching for S3 buckets...
✅ Found S3 Bucket: pgworld-admin
✅ Configuration saved to /home/ec2-user/.pgni-config

📊 Deployment Configuration
========================================
EC2 Public IP: 54.227.101.30
RDS Endpoint: database-pgni.cezawkgguojl.us-east-1.rds.amazonaws.com
Database User: admin
Database Name: pgworld
S3 Bucket: pgworld-admin
========================================

Continue with deployment? (Y/n): [Press Enter]
```

### **Second Time (With Config):**
```
📋 Step 1: Auto-detecting AWS Configuration
✅ Found existing configuration
Using saved configuration:
  EC2 IP: 54.227.101.30
  RDS: database-pgni.cezawkgguojl.us-east-1.rds.amazonaws.com
  Database: pgworld
  S3 Bucket: pgworld-admin

Use these settings? (y/n) [y]: [Press Enter]
Enter Database Password: ********

📊 Deployment Configuration
========================================
[Same as above]
========================================

Continue with deployment? (Y/n): [Press Enter]
```

---

## 🔐 **Security Notes**

1. **Config file is protected:** `chmod 600` ensures only you can read it
2. **Password not saved:** Database password must be entered each time (security best practice)
3. **Located in home directory:** `~/.pgni-config` is user-specific

---

## 📝 **Advanced: Use AWS Secrets Manager**

For fully automated deployments without password prompts:

```bash
# Store password in Secrets Manager
aws secretsmanager create-secret \
  --name pgni-db-password \
  --secret-string "your_password_here"

# Modify script to retrieve password
DB_PASSWORD=$(aws secretsmanager get-secret-value \
  --secret-id pgni-db-password \
  --query SecretString \
  --output text)
```

---

## ✅ **Ready to Deploy**

Now that you understand auto-configuration, run:

```bash
# If config doesn't exist, create it first:
cat > ~/.pgni-config << 'EOF'
EC2_IP="54.227.101.30"
RDS_ENDPOINT="database-pgni.cezawkgguojl.us-east-1.rds.amazonaws.com"
DB_USER="admin"
DB_NAME="pgworld"
S3_BUCKET="pgworld-admin"
EOF

chmod 600 ~/.pgni-config

# Then deploy:
bash <(curl -sL https://raw.githubusercontent.com/siddam01/pgni/main/EC2_DEPLOY_MASTER.sh)
```

**You'll only need to:**
1. Press `Enter` to use saved config
2. Enter database password
3. Press `Enter` to continue

**That's it! 🚀**

