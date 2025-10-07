# 🚀 Deploy to AWS - Step by Step Guide

**Platform:** Amazon Web Services  
**Estimated Cost:** $30/month  
**Setup Time:** 2 hours  
**Difficulty:** Medium-Hard

---

## 📊 AWS ARCHITECTURE

```
Internet → Route 53 (DNS)
         ↓
    CloudFront (CDN) [Optional]
         ↓
    Application Load Balancer
         ↓
    ┌────────────────────────┐
    │   EC2 / Lambda         │ ← Your Go API
    │   (Auto-scaling)       │
    └────────────────────────┘
         ↓
    RDS MySQL (Database)
         ↓
    S3 Bucket (File Storage)
```

---

## 💰 COST BREAKDOWN

| Service | Configuration | Monthly Cost |
|---------|--------------|--------------|
| **EC2** | t3.micro (1 vCPU, 1GB RAM) | $8 |
| **RDS MySQL** | db.t3.micro (1 vCPU, 1GB RAM, 20GB) | $15 |
| **S3** | 200GB storage + requests | $5 |
| **Load Balancer** | Application LB (optional) | $16 |
| **Route 53** | Hosted zone + queries | $1 |
| **Data Transfer** | First 1GB free, then $0.09/GB | $2 |
| **SSL Certificate** | AWS Certificate Manager | **FREE** |
| **Total (Basic)** | | **$30** |
| **Total (with LB)** | | **$46** |

**Cost Optimization:** Use Lambda instead of EC2 = ~$15/month total

---

## 🎯 OPTION 1: AWS EC2 (Recommended)

### Step 1: Create RDS MySQL Database (15 minutes)

1. **Go to AWS Console → RDS**
2. **Click "Create database"**
3. **Configuration:**
   ```
   Engine: MySQL 8.0
   Template: Free tier (or Production if needed)
   DB Instance: db.t3.micro
   
   Settings:
   - DB instance identifier: pgworld-db
   - Master username: admin
   - Master password: [STRONG PASSWORD - Save this!]
   
   Storage:
   - Allocated storage: 20 GB
   - Storage type: gp3
   - Enable storage autoscaling: Yes
   - Maximum storage: 100 GB
   
   Connectivity:
   - VPC: Default
   - Public access: Yes (for now)
   - VPC security group: Create new
   - Security group name: pgworld-db-sg
   
   Database authentication: Password authentication
   Initial database name: pgworld_db
   ```

4. **Click "Create database"** (takes 5-10 minutes)

5. **Configure Security Group:**
   - Go to EC2 → Security Groups
   - Find `pgworld-db-sg`
   - Edit Inbound Rules
   - Add rule: MySQL/Aurora (port 3306)
   - Source: Custom → Add EC2 security group (we'll create this next)
   - **Temporary:** Allow from "My IP" for initial setup

6. **Save Database Endpoint:**
   ```
   pgworld-db.abc123.us-east-1.rds.amazonaws.com:3306
   ```

---

### Step 2: Import Database Schema (10 minutes)

1. **Connect from your local machine:**
   ```bash
   mysql -h pgworld-db.abc123.us-east-1.rds.amazonaws.com \
         -u admin \
         -p \
         pgworld_db
   ```

2. **Import schema:**
   ```bash
   mysql -h pgworld-db.abc123.us-east-1.rds.amazonaws.com \
         -u admin \
         -p \
         pgworld_db < pgworld-api-master/setup-database.sql
   ```

3. **Run migrations:**
   ```bash
   mysql -h pgworld-db.abc123.us-east-1.rds.amazonaws.com \
         -u admin \
         -p \
         pgworld_db < pgworld-api-master/migrations/001_owner_onboarding.sql
   ```

4. **Verify:**
   ```sql
   USE pgworld_db;
   SHOW TABLES;
   ```

---

### Step 3: Create S3 Bucket (5 minutes)

1. **Go to S3 Console**
2. **Click "Create bucket"**
3. **Configuration:**
   ```
   Bucket name: pgworld-production-uploads
   Region: us-east-1 (same as RDS)
   
   Block Public Access: Keep all checked
   Bucket Versioning: Disabled
   Encryption: Enable (SSE-S3)
   ```

4. **Create IAM User for S3 Access:**
   - Go to IAM → Users → Create user
   - Username: `pgworld-s3-user`
   - Attach policy: `AmazonS3FullAccess` (or create custom policy)
   - Create access key
   - **Save:** Access Key ID and Secret Access Key

---

### Step 4: Launch EC2 Instance (20 minutes)

1. **Go to EC2 Console → Launch Instance**
2. **Configuration:**
   ```
   Name: pgworld-api
   
   Application and OS Images:
   - Amazon Linux 2023 (Free tier eligible)
   
   Instance type:
   - t3.micro (1 vCPU, 1 GB RAM)
   
   Key pair:
   - Create new key pair
   - Name: pgworld-key
   - Type: RSA
   - Format: .pem
   - Download and save securely!
   
   Network settings:
   - VPC: Default
   - Auto-assign public IP: Enable
   - Create security group: pgworld-api-sg
   - Allow SSH (port 22) from My IP
   - Allow HTTP (port 80) from Anywhere
   - Allow HTTPS (port 443) from Anywhere
   - Allow Custom TCP (port 8080) from Anywhere (temporary)
   
   Storage:
   - 8 GB gp3
   ```

3. **Click "Launch instance"**

---

### Step 5: Configure EC2 Instance (30 minutes)

1. **Connect via SSH:**
   ```bash
   chmod 400 pgworld-key.pem
   ssh -i pgworld-key.pem ec2-user@[EC2-PUBLIC-IP]
   ```

2. **Install Go:**
   ```bash
   # Update system
   sudo yum update -y
   
   # Install Go
   wget https://go.dev/dl/go1.21.5.linux-amd64.tar.gz
   sudo tar -C /usr/local -xzf go1.21.5.linux-amd64.tar.gz
   
   # Add to PATH
   echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
   source ~/.bashrc
   
   # Verify
   go version
   ```

3. **Install Git:**
   ```bash
   sudo yum install git -y
   ```

4. **Clone your repository:**
   ```bash
   # If using Git
   git clone https://github.com/yourusername/pgworld.git
   cd pgworld/pgworld-api-master
   
   # Or upload via SCP
   # scp -i pgworld-key.pem -r pgworld-api-master ec2-user@[EC2-IP]:~/
   ```

5. **Create production environment file:**
   ```bash
   cd ~/pgworld/pgworld-api-master
   nano .env.production
   ```

   Paste:
   ```env
   dbConfig=admin:YOUR_DB_PASSWORD@tcp(pgworld-db.abc123.us-east-1.rds.amazonaws.com:3306)/pgworld_db
   connectionPool=20
   baseURL=http://[EC2-PUBLIC-IP]:8080
   test=false
   migrate=false
   
   supportEmailID=support@pgworld.com
   supportEmailPassword=YOUR_APP_PASSWORD
   supportEmailHost=smtp.gmail.com
   supportEmailPort=587
   
   ANDROID_LIVE_KEY=[FROM PRODUCTION_API_KEYS.txt]
   ANDROID_TEST_KEY=[FROM PRODUCTION_API_KEYS.txt]
   IOS_LIVE_KEY=[FROM PRODUCTION_API_KEYS.txt]
   IOS_TEST_KEY=[FROM PRODUCTION_API_KEYS.txt]
   
   RAZORPAY_KEY_ID=YOUR_RAZORPAY_KEY
   RAZORPAY_KEY_SECRET=YOUR_RAZORPAY_SECRET
   
   s3Bucket=pgworld-production-uploads
   AWS_ACCESS_KEY_ID=YOUR_AWS_KEY
   AWS_SECRET_ACCESS_KEY=YOUR_AWS_SECRET
   AWS_REGION=us-east-1
   ```

   Copy `.env.production` to `.env`:
   ```bash
   cp .env.production .env
   ```

6. **Build and run:**
   ```bash
   # Install dependencies
   go mod download
   
   # Build
   go build -o pgworld-api .
   
   # Test run
   ./pgworld-api
   ```

7. **Test API:**
   ```bash
   # From another terminal
   curl http://[EC2-PUBLIC-IP]:8080/
   ```

---

### Step 6: Set Up as System Service (15 minutes)

1. **Create systemd service:**
   ```bash
   sudo nano /etc/systemd/system/pgworld-api.service
   ```

   Paste:
   ```ini
   [Unit]
   Description=PG World API
   After=network.target

   [Service]
   Type=simple
   User=ec2-user
   WorkingDirectory=/home/ec2-user/pgworld/pgworld-api-master
   ExecStart=/home/ec2-user/pgworld/pgworld-api-master/pgworld-api
   Restart=always
   RestartSec=10

   [Install]
   WantedBy=multi-user.target
   ```

2. **Enable and start:**
   ```bash
   sudo systemctl daemon-reload
   sudo systemctl enable pgworld-api
   sudo systemctl start pgworld-api
   sudo systemctl status pgworld-api
   ```

3. **Check logs:**
   ```bash
   sudo journalctl -u pgworld-api -f
   ```

---

### Step 7: Configure Domain and SSL (30 minutes)

1. **Register domain (if needed):**
   - Go to Route 53
   - Register domain (e.g., pgworld.com) - $12/year

2. **Request SSL Certificate:**
   - Go to AWS Certificate Manager
   - Request public certificate
   - Domain: `api.pgworld.com` and `*.pgworld.com`
   - Validation: DNS validation
   - Add CNAME records to Route 53 (automatic if domain in Route 53)
   - Wait for validation (5-30 minutes)

3. **Create Application Load Balancer:**
   - Go to EC2 → Load Balancers → Create
   - Type: Application Load Balancer
   - Name: pgworld-alb
   - Scheme: Internet-facing
   - Listeners: HTTPS (port 443)
   - Availability Zones: Select at least 2
   - Security group: Allow HTTPS from anywhere
   - Target group: Create new
     - Target type: Instances
     - Protocol: HTTP, Port: 8080
     - Register EC2 instance
   - SSL certificate: Select from ACM

4. **Configure Route 53:**
   - Go to Route 53 → Hosted zones
   - Select your domain
   - Create record:
     - Name: api
     - Type: A
     - Alias: Yes
     - Alias target: Application Load Balancer
     - Routing policy: Simple

5. **Update .env:**
   ```bash
   nano .env
   # Change baseURL to:
   baseURL=https://api.pgworld.com
   
   sudo systemctl restart pgworld-api
   ```

---

### Step 8: Update Database Security (5 minutes)

1. **Go to RDS → Security Groups**
2. **Edit `pgworld-db-sg` inbound rules:**
3. **Remove "My IP" rule**
4. **Keep only:**
   - MySQL/Aurora (3306) from `pgworld-api-sg`

---

## ✅ VERIFICATION CHECKLIST

- [ ] RDS database created and accessible
- [ ] Database schema imported
- [ ] S3 bucket created with access keys
- [ ] EC2 instance running
- [ ] API compiles and runs
- [ ] API accessible via public IP
- [ ] Systemd service running
- [ ] SSL certificate issued
- [ ] Load balancer created
- [ ] Domain points to load balancer
- [ ] HTTPS works: `https://api.pgworld.com`
- [ ] All API endpoints working
- [ ] File uploads work to S3

---

## 🔍 TESTING

```bash
# Health check
curl https://api.pgworld.com/health

# Test endpoint
curl https://api.pgworld.com/

# Check logs
ssh -i pgworld-key.pem ec2-user@[EC2-IP]
sudo journalctl -u pgworld-api -f
```

---

## 💰 COST OPTIMIZATION TIPS

1. **Use Reserved Instances:** Save 30-70%
2. **Use Spot Instances:** Save up to 90% (for non-critical)
3. **Enable S3 Intelligent Tiering:** Auto-save on storage
4. **Use CloudFront CDN:** Reduce data transfer costs
5. **Monitor with CloudWatch:** Set billing alerts

---

## 🎯 NEXT STEPS

1. Update Flutter mobile apps with new API URL
2. Set up monitoring (CloudWatch)
3. Configure backups (RDS automated backups)
4. Set up CI/CD (GitHub Actions → EC2)
5. Scale as needed (add more EC2 instances)

**Your API is now live on AWS! 🎉**

