# Run Terraform NOW - Quick Guide

## ✅ You're Ready to Deploy!

You already have:
- ✅ RDS MySQL database (`database-pgni`)
- ✅ Database credentials configured
- ✅ Terraform files configured to use your existing database

**Terraform will create:**
- S3 Bucket (for file uploads)
- EC2 Instance (to run your API)
- Security Groups (network security)
- IAM Roles (permissions)
- SSH Keys (for EC2 access)
- SSM Parameters (store credentials)

---

## 🚀 Quick Start (3 Steps)

### Step 1: Install Terraform (if not installed)

**Option A: Using Chocolatey**
```powershell
choco install terraform
```

**Option B: Manual Download**
1. Download from: https://www.terraform.io/downloads
2. Extract to `C:\terraform`
3. Add to PATH:
   ```powershell
   $env:PATH += ";C:\terraform"
   ```

**Verify:**
```powershell
terraform version
```

---

### Step 2: Install & Configure AWS CLI (if not done)

**Install:**
1. Download: https://awscli.amazonaws.com/AWSCLIV2.msi
2. Double-click to install
3. Restart PowerShell

**Configure:**
```powershell
aws configure
```

Enter:
- **Access Key ID:** [from AWS Console → IAM → Users → Security credentials]
- **Secret Access Key:** [from AWS Console]
- **Region:** `us-east-1`
- **Output:** `json`

**Test:**
```powershell
aws sts get-caller-identity
```

Should show account: `698302425856`

---

### Step 3: Run Terraform

```powershell
# Navigate to terraform directory
cd C:\MyFolder\Mytest\pgworld-master\terraform

# Initialize Terraform
terraform init

# Preview what will be created
terraform plan

# Create the infrastructure
terraform apply
```

When prompted, type: `yes`

⏱️ **Time:** 10-15 minutes (mostly waiting for EC2 to start)

---

## 📊 What Terraform Will Create

### ✅ S3 Bucket
- **Name:** `pgni-preprod-698302425856-uploads`
- **Features:** Versioning, CORS, encryption
- **Purpose:** File uploads (PG photos, documents)

### ✅ EC2 Instance
- **Type:** t3.micro (FREE TIER)
- **OS:** Amazon Linux 2023
- **Software:** Go 1.21, Git, MySQL client (pre-installed)
- **Purpose:** Run your API

### ✅ Security Groups
- **RDS:** MySQL access from EC2
- **EC2:** SSH (22), API (8080), HTTPS (443)

### ✅ IAM Role
- **Permissions:** S3 access, SSM access, CloudWatch logs
- **Attached to:** EC2 instance

### ✅ SSH Key Pair
- **Auto-generated:** 4096-bit RSA key
- **Saved in:** Terraform outputs

### ✅ SSM Parameters
- Database credentials (stored securely)
- S3 bucket name
- EC2 connection details

---

## 📝 After Terraform Completes

### 1. Save Important Files

**SSH Private Key:**
```powershell
cd C:\MyFolder\Mytest\pgworld-master\terraform
terraform output -raw ssh_private_key > pgni-preprod-key.pem

# Set permissions (Windows)
icacls pgni-preprod-key.pem /inheritance:r
icacls pgni-preprod-key.pem /grant:r "$($env:USERNAME):R"
```

**Environment File:**
```powershell
terraform output -raw environment_file > pgni-preprod.env
```

**Complete Info:**
```powershell
terraform output > deployment-info.txt
```

### 2. View Deployment Summary
```powershell
terraform output next_steps
```

This shows:
- EC2 public IP
- SSH commands
- Database connection
- API URLs
- Next steps

---

## 🔗 Connect to Your Infrastructure

### SSH to EC2:
```powershell
terraform output ssh_command
# Copy and run the command shown
```

### Test S3 Bucket:
```powershell
$bucket = terraform output -raw s3_bucket_name
aws s3 ls s3://$bucket
```

### Test Database:
```powershell
# From your computer (if MySQL installed):
mysql -h database-pgni.cezawkgguojl.us-east-1.rds.amazonaws.com -u admin -p
```

---

## 🚢 Deploy Your API

### 1. SSH to EC2
```powershell
ssh -i pgni-preprod-key.pem ec2-user@<EC2_PUBLIC_IP>
```

### 2. Clone & Build
```bash
# Clone repository
git clone https://github.com/siddam01/pgni.git
cd pgni/pgworld-api-master

# Build API
/usr/local/go/bin/go build -o /opt/pgworld/pgworld-api .
```

### 3. Copy Environment File
```bash
# From your computer, upload the env file first:
# scp -i pgni-preprod-key.pem pgni-preprod.env ec2-user@<EC2_IP>:~

# Then on EC2:
sudo cp ~/pgni-preprod.env /opt/pgworld/.env
sudo chown ec2-user:ec2-user /opt/pgworld/.env
sudo chmod 600 /opt/pgworld/.env
```

### 4. Start API Service
```bash
sudo systemctl start pgworld-api
sudo systemctl status pgworld-api

# View logs
sudo journalctl -u pgworld-api -f
```

### 5. Test API
```bash
curl http://localhost:8080/health
```

Should return: `{"status":"ok"}`

---

## 🆘 Troubleshooting

### "terraform: command not found"
**Solution:**
```powershell
# Install Terraform
choco install terraform
# Or download manually from terraform.io
```

### "aws: command not found"
**Solution:**
- Install AWS CLI from: https://awscli.amazonaws.com/AWSCLIV2.msi
- Run: `aws configure`

### "Error: configuring Terraform AWS Provider"
**Solution:**
```powershell
aws configure
aws sts get-caller-identity
```

### "Error: creating EC2 Instance"
**Possible causes:**
- Check AWS quotas (EC2 limits)
- Verify region is us-east-1
- Check free tier eligibility

### Terraform State Locked
**Solution:**
```powershell
# Wait a few minutes, then retry
# Or force unlock (use carefully):
terraform force-unlock <LOCK_ID>
```

---

## 💰 Cost Estimate

### With Free Tier (First 12 Months):
- EC2 t3.micro: **FREE** (750 hours/month)
- S3: **FREE** (5 GB, 20K GET requests)
- Data transfer: **FREE** (100 GB/month)
- RDS: **$0** (already created, separate billing)

**Total New Cost: $0-5/month** ✅

---

## 🔄 Update Infrastructure

**To modify resources:**
1. Edit `.tf` files or `terraform.tfvars`
2. Run: `terraform plan` (preview changes)
3. Run: `terraform apply` (apply changes)

**To destroy everything:**
```powershell
terraform destroy
```
⚠️ **Warning:** This deletes S3, EC2, and all created resources (but NOT your manual RDS database)

---

## ✅ Success Criteria

Infrastructure is ready when:
- ✅ `terraform apply` completes successfully
- ✅ Can SSH to EC2 instance
- ✅ S3 bucket is accessible
- ✅ API health check returns OK
- ✅ Can connect to database from EC2

---

## 📋 Complete Checklist

**Before Running:**
- [ ] Terraform installed
- [ ] AWS CLI installed
- [ ] AWS credentials configured
- [ ] In `terraform/` directory

**Run Terraform:**
- [ ] `terraform init` - Success
- [ ] `terraform plan` - Reviewed
- [ ] `terraform apply` - Completed
- [ ] Save SSH key
- [ ] Save environment file

**Deploy API:**
- [ ] SSH to EC2 works
- [ ] Clone repository
- [ ] Build API
- [ ] Copy environment file
- [ ] Start service
- [ ] API health check OK

**Test:**
- [ ] Database connection works
- [ ] S3 uploads work
- [ ] API endpoints respond
- [ ] Flutter apps can connect

---

## 🎉 You're Almost Done!

**Current Status:**
- ✅ RDS Database (manual)
- ⏳ S3, EC2, Security (Terraform will create)
- ⏳ API deployment
- ⏳ Flutter apps update

**After running Terraform:**
- ✅ Complete infrastructure
- ⏳ Deploy API (10 min)
- ⏳ Update Flutter apps (5 min)
- **GO LIVE!** 🚀

---

**Start now:**
```powershell
cd C:\MyFolder\Mytest\pgworld-master\terraform
terraform init
terraform apply
```

Good luck! 🎉

