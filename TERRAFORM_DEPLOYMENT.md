# 🚀 Terraform Deployment Guide

## Complete Infrastructure as Code for PGNi

---

## ✅ What I Created For You

### **1. Complete Terraform Configuration**
All infrastructure defined as code in `terraform/` directory:

- **`main.tf`** - Main configuration, providers, data sources
- **`variables.tf`** - All configurable parameters
- **`outputs.tf`** - Deployment information and credentials
- **`rds.tf`** - MySQL database configuration
- **`s3.tf`** - File storage configuration
- **`ec2.tf`** - API server configuration
- **`security-groups.tf`** - Network security rules
- **`terraform.tfvars.example`** - Example configuration
- **`README.md`** - Complete documentation

### **2. Infrastructure Specification (YAML)**
- **`infrastructure.yaml`** - Complete infrastructure requirements, dependencies, validation rules

---

## 🎯 What Gets Created Automatically

When you run Terraform, it creates:

### Infrastructure:
- ✅ **RDS MySQL Database** (configured and ready)
- ✅ **S3 Bucket** (with CORS, versioning, encryption)
- ✅ **EC2 Instance** (with Go, Git, MySQL client pre-installed)
- ✅ **Security Groups** (all ports configured)
- ✅ **IAM Roles** (with S3, SSM, CloudWatch access)
- ✅ **SSH Key Pair** (auto-generated 4096-bit RSA)
- ✅ **SSM Parameters** (all credentials stored securely)

### Outputs:
- ✅ Database endpoint and credentials
- ✅ S3 bucket name
- ✅ EC2 public IP
- ✅ SSH private key
- ✅ Complete environment file
- ✅ SSH commands (copy-paste ready)
- ✅ API URLs
- ✅ Next steps guide

---

## 📋 Prerequisites

### 1. Install Terraform
```powershell
# Using Chocolatey
choco install terraform

# Or download from:
# https://www.terraform.io/downloads

# Verify installation
terraform version
```

### 2. Install AWS CLI
```powershell
# Download installer
# https://awscli.amazonaws.com/AWSCLIV2.msi

# Or using winget
winget install Amazon.AWSCLI

# Verify installation
aws --version
```

### 3. Configure AWS Credentials
```powershell
aws configure

# Enter:
# AWS Access Key ID: [from AWS Console]
# AWS Secret Access Key: [from AWS Console]
# Default region: us-east-1
# Default output format: json

# Test
aws sts get-caller-identity
```

---

## 🚀 Quick Deployment (3 Steps)

### Step 1: Navigate to Terraform Directory
```powershell
cd C:\MyFolder\Mytest\pgworld-master\terraform
```

### Step 2: Initialize Terraform
```powershell
terraform init
```

Expected output:
```
Initializing provider plugins...
- Finding hashicorp/aws versions matching "~> 5.0"...
- Finding hashicorp/random versions matching "~> 3.5"...
- Finding hashicorp/tls versions matching "~> 4.0"...
...
Terraform has been successfully initialized!
```

### Step 3: Deploy Infrastructure
```powershell
# For pre-production
terraform apply -var="environment=preprod"

# Type 'yes' when prompted
```

⏱️ **Duration: 15-20 minutes** (mostly waiting for RDS database)

---

## 📊 After Deployment

### 1. View All Information
```powershell
terraform output
```

### 2. Save Credentials

#### Save SSH Private Key:
```powershell
terraform output -raw ssh_private_key > pgni-preprod-key.pem

# Set permissions
icacls pgni-preprod-key.pem /inheritance:r
icacls pgni-preprod-key.pem /grant:r "$($env:USERNAME):R"
```

#### Save Environment File:
```powershell
terraform output -raw environment_file > pgni-preprod.env
```

#### View Next Steps:
```powershell
terraform output next_steps
```

### 3. Connect to Infrastructure

#### SSH to EC2:
```powershell
ssh -i pgni-preprod-key.pem ec2-user@<EC2_PUBLIC_IP>

# Or get command:
terraform output ssh_command
```

#### Test Database:
```powershell
# From EC2:
mysql -h <RDS_ENDPOINT> -u pgniuser -p pgworld
```

#### Test API Health:
```powershell
curl http://<EC2_PUBLIC_IP>:8080/health
```

---

## 📦 Deploy Application

### 1. SSH to EC2
```powershell
ssh -i pgni-preprod-key.pem ec2-user@<EC2_PUBLIC_IP>
```

### 2. Clone and Build
```bash
# Clone repository
git clone https://github.com/siddam01/pgni.git
cd pgni/pgworld-api-master

# Build
/usr/local/go/bin/go build -o /opt/pgworld/pgworld-api .
```

### 3. Configure Environment
```bash
# Copy environment file (upload from your computer first)
sudo cp ~/pgni-preprod.env /opt/pgworld/.env
sudo chown ec2-user:ec2-user /opt/pgworld/.env
sudo chmod 600 /opt/pgworld/.env
```

### 4. Start Service
```bash
sudo systemctl start pgworld-api
sudo systemctl status pgworld-api

# View logs
sudo journalctl -u pgworld-api -f
```

### 5. Test
```bash
curl http://localhost:8080/health
```

---

## 🎨 Customization

### Edit Configuration:
```powershell
# Copy example
copy terraform.tfvars.example terraform.tfvars

# Edit
notepad terraform.tfvars
```

Example `terraform.tfvars`:
```hcl
environment = "preprod"
aws_region  = "us-east-1"

# Restrict SSH to your IP
allowed_ssh_cidrs = ["YOUR_IP/32"]

# Enable KMS encryption
enable_kms_encryption = true
kms_key_id = "arn:aws:kms:us-east-1:698302425856:key/mrk-1b96d9eeccf649e695ed6ac2b13cb619"

# Custom password (or leave empty to auto-generate)
# db_password = "YourSecurePassword123!"
```

### Preview Changes:
```powershell
terraform plan -var="environment=preprod"
```

### Apply Changes:
```powershell
terraform apply -var="environment=preprod"
```

---

## 🔄 Deploy Production

### Same process, different environment:
```powershell
terraform apply -var="environment=production"
```

**Differences:**
- Larger instance sizes (t3.small, db.t3.small)
- 30-day backups
- Enhanced monitoring
- Static Elastic IP
- Deletion protection

---

## 💰 Cost Estimate

### Pre-Production (Free Tier):
- **$0-5/month** for first 12 months
- Uses t3.micro and db.t3.micro (FREE)

### Production:
- **~$50/month** after free tier
- Enhanced monitoring and backups

---

## 🔒 Security Features

✅ Encrypted storage (RDS, S3, EC2 volumes)  
✅ Security groups (minimal access)  
✅ IAM roles (least privilege)  
✅ Secrets in SSM Parameter Store  
✅ Optional KMS encryption  
✅ IMDSv2 enforced on EC2  
✅ SSH key auto-generated  

---

## 🆘 Troubleshooting

### "terraform: command not found"
```powershell
# Install Terraform
choco install terraform
```

### "Error: configuring Terraform AWS Provider"
```powershell
# Configure AWS CLI
aws configure
aws sts get-caller-identity
```

### "Error: creating RDS DB Instance: timeout"
- RDS takes 10-15 minutes to create (normal)
- Wait and let Terraform complete

### View Terraform Logs:
```powershell
$env:TF_LOG="DEBUG"
terraform apply
```

---

## 📁 File Structure

```
terraform/
├── main.tf                    # Main configuration
├── variables.tf               # Variable definitions
├── outputs.tf                 # Output definitions
├── rds.tf                     # Database configuration
├── s3.tf                      # Storage configuration
├── ec2.tf                     # Server configuration
├── security-groups.tf         # Security rules
├── terraform.tfvars.example   # Example config
└── README.md                  # Full documentation

infrastructure.yaml            # Complete infrastructure spec
TERRAFORM_DEPLOYMENT.md       # This guide
```

---

## ✅ Validation

### Pre-Deployment Checks:
- [ ] Terraform installed (`terraform version`)
- [ ] AWS CLI installed (`aws --version`)
- [ ] AWS credentials configured (`aws sts get-caller-identity`)
- [ ] In correct directory (`cd terraform/`)

### Post-Deployment Checks:
- [ ] RDS status is "Available"
- [ ] S3 bucket created
- [ ] EC2 instance running
- [ ] Can SSH to EC2
- [ ] Can connect to database
- [ ] Security groups configured
- [ ] SSH key saved
- [ ] Environment file saved

---

## 🎯 Advantages of Terraform

### vs Manual Deployment:
- ⚡ **Faster:** 1 command vs 60 minutes of clicking
- 🔄 **Repeatable:** Same result every time
- 📝 **Documented:** Infrastructure as code
- 🔒 **Secure:** Best practices built-in
- ✅ **Validated:** Catches errors before creation
- 🗑️ **Easy cleanup:** `terraform destroy`

### vs PowerShell Script:
- 🌍 **Cross-platform:** Works on Windows, Mac, Linux
- 📊 **State management:** Knows what's deployed
- 🔄 **Idempotent:** Can re-run safely
- 📚 **Well-documented:** Standard tool with community support

---

## 📞 Support

### Need Help?
1. Check: `terraform/README.md` (detailed guide)
2. Check: `infrastructure.yaml` (complete specs)
3. View outputs: `terraform output next_steps`
4. Check logs: `terraform show`

### Common Commands:
```powershell
terraform init      # Initialize
terraform validate  # Check syntax
terraform plan      # Preview changes
terraform apply     # Create infrastructure
terraform output    # View information
terraform destroy   # Delete everything
```

---

## 🎉 Summary

### What You Get:
1. **Complete infrastructure** - RDS, S3, EC2, networking
2. **All credentials** - Auto-generated and saved securely
3. **Ready to deploy** - Server pre-configured
4. **Well documented** - Every output explained
5. **Cost optimized** - Free tier eligible

### Time Saved:
- Manual deployment: 60-90 minutes
- Terraform deployment: 20 minutes (mostly waiting)
- **Savings: 40-70 minutes!**

### Next Steps:
1. Install Terraform (5 min)
2. Configure AWS CLI (5 min)
3. Run `terraform apply` (20 min)
4. Deploy your API (10 min)
5. **You're live!** 🚀

---

**Ready to deploy? Start with:**
```powershell
cd C:\MyFolder\Mytest\pgworld-master\terraform
terraform init
terraform apply -var="environment=preprod"
```

Good luck! 🎉

