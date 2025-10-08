# PGNi Infrastructure as Code (Terraform)

Complete Terraform configuration to deploy PGNi infrastructure to AWS.

## 📋 What Gets Created

### Infrastructure Components:
1. **RDS MySQL Database**
   - Version: MySQL 8.0.35
   - Instance: db.t3.micro (preprod) / db.t3.small (production)
   - Storage: 20GB (preprod) / 50GB (production)
   - Automated backups
   - Encrypted storage

2. **S3 Bucket**
   - File uploads storage
   - Versioning enabled
   - CORS configured
   - Lifecycle policies
   - Encryption at rest

3. **EC2 Instance**
   - Amazon Linux 2023
   - Instance: t3.micro (preprod) / t3.small (production)
   - Auto-configured with Go, Git, MySQL client
   - Systemd service pre-configured
   - IAM role with S3 and SSM access

4. **Security Groups**
   - RDS: MySQL access from EC2 only
   - EC2: SSH (22), API (8080), HTTPS (443)

5. **IAM Roles & Policies**
   - EC2 instance role with S3, SSM, CloudWatch access
   - RDS monitoring role (production)

6. **SSH Key Pair**
   - Auto-generated RSA 4096-bit key
   - Private key stored securely in outputs

7. **SSM Parameters**
   - Database credentials
   - S3 bucket name
   - EC2 connection details

---

## 🚀 Prerequisites

### Required Tools:
1. **Terraform** (>= 1.0)
   ```powershell
   # Install on Windows
   choco install terraform
   # Or download from: https://www.terraform.io/downloads
   ```

2. **AWS CLI** (configured)
   ```powershell
   # Install
   winget install Amazon.AWSCLI
   
   # Configure
   aws configure
   ```

3. **Git** (to clone repository)

### AWS Requirements:
- AWS Account: 698302425856
- IAM user with permissions:
  - EC2FullAccess
  - RDSFullAccess
  - S3FullAccess
  - IAMFullAccess
  - AmazonSSMFullAccess
  - VPCFullAccess

---

## 📦 Quick Start

### 1. Navigate to Terraform Directory
```powershell
cd C:\MyFolder\Mytest\pgworld-master\terraform
```

### 2. Copy and Configure Variables
```powershell
# Copy example file
copy terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your values
notepad terraform.tfvars
```

### 3. Initialize Terraform
```powershell
terraform init
```

This downloads required providers (AWS, Random, TLS).

### 4. Validate Configuration
```powershell
terraform validate
```

### 5. Plan Deployment (Preview)
```powershell
# For pre-production
terraform plan -var="environment=preprod"

# For production
terraform plan -var="environment=production"
```

### 6. Deploy Infrastructure
```powershell
# Deploy pre-production
terraform apply -var="environment=preprod"

# Deploy production
terraform apply -var="environment=production"
```

Type `yes` when prompted.

⏱️ **Deployment takes 15-20 minutes** (mostly waiting for RDS)

---

## 📊 After Deployment

### 1. View All Outputs
```powershell
terraform output
```

### 2. Save Credentials Securely

#### Save SSH Private Key:
```powershell
# Windows PowerShell
terraform output -raw ssh_private_key | Out-File -FilePath "pgni-preprod-key.pem" -Encoding ASCII

# Set permissions (Windows)
icacls pgni-preprod-key.pem /inheritance:r
icacls pgni-preprod-key.pem /grant:r "$($env:USERNAME):R"
```

#### Save Environment File:
```powershell
terraform output -raw environment_file | Out-File -FilePath "pgni-preprod.env" -Encoding ASCII
```

#### View Sensitive Values:
```powershell
terraform output rds_password
terraform output ssh_private_key
terraform output environment_file
```

### 3. Get Deployment Summary
```powershell
terraform output next_steps
```

---

## 🔗 Connect to Infrastructure

### SSH to EC2:
```powershell
ssh -i pgni-preprod-key.pem ec2-user@<EC2_PUBLIC_IP>

# Or use the command from outputs:
terraform output ssh_command
```

### Connect to Database:
```powershell
# Get connection string
terraform output rds_connection_string

# From your computer (if public):
mysql -h <RDS_ENDPOINT> -u pgniuser -p pgworld

# From EC2:
mysql -h <RDS_ENDPOINT> -u pgniuser -p pgworld
```

### Test API:
```powershell
# Get API URL
terraform output api_health_url

# Test
curl http://<EC2_PUBLIC_IP>:8080/health
```

---

## 🚢 Deploy Application

### 1. SSH to EC2
```powershell
ssh -i pgni-preprod-key.pem ec2-user@<EC2_PUBLIC_IP>
```

### 2. Clone Repository
```bash
cd /home/ec2-user
git clone https://github.com/siddam01/pgni.git
cd pgni/pgworld-api-master
```

### 3. Build API
```bash
/usr/local/go/bin/go build -o /opt/pgworld/pgworld-api .
```

### 4. Copy Environment File
```bash
# Upload from your computer first, then:
sudo cp ~/pgni-preprod.env /opt/pgworld/.env
sudo chown ec2-user:ec2-user /opt/pgworld/.env
sudo chmod 600 /opt/pgworld/.env
```

### 5. Start Service
```bash
sudo systemctl start pgworld-api
sudo systemctl status pgworld-api

# View logs
sudo journalctl -u pgworld-api -f
```

### 6. Test
```bash
curl http://localhost:8080/health
```

---

## 🔄 Managing Infrastructure

### Update Infrastructure
```powershell
# Modify .tf files or terraform.tfvars
# Then:
terraform plan
terraform apply
```

### Destroy Infrastructure
```powershell
# ⚠️ WARNING: This deletes everything!
terraform destroy -var="environment=preprod"
```

### View Current State
```powershell
terraform show
terraform state list
```

### Refresh State
```powershell
terraform refresh
```

---

## 📁 File Structure

```
terraform/
├── main.tf                  # Main configuration & providers
├── variables.tf             # Variable definitions
├── terraform.tfvars.example # Example variable values
├── outputs.tf               # Output definitions
├── rds.tf                   # RDS database configuration
├── s3.tf                    # S3 bucket configuration
├── ec2.tf                   # EC2 instance configuration
├── security-groups.tf       # Security group rules
└── README.md               # This file
```

---

## 🎯 Environment Differences

### Pre-Production:
- `db.t3.micro` database
- `t3.micro` EC2
- 7-day backups
- No enhanced monitoring
- Skip final snapshot
- No Elastic IP

### Production:
- `db.t3.small` database
- `t3.small` EC2
- 30-day backups
- Enhanced monitoring enabled
- Final snapshot on destroy
- Static Elastic IP
- Deletion protection enabled

---

## 💰 Cost Estimation

### Pre-Production (Free Tier):
- RDS db.t3.micro: **FREE** (750 hrs/month)
- EC2 t3.micro: **FREE** (750 hrs/month)
- S3: **FREE** (5 GB, 20K GET requests)
- Data transfer: **FREE** (100 GB/month)
- **Total: $0-5/month**

### After Free Tier:
- RDS: ~$15/month
- EC2: ~$8/month
- S3: ~$1/month
- **Total: ~$25/month**

### Production:
- RDS db.t3.small: ~$30/month
- EC2 t3.small: ~$15/month
- Elastic IP: ~$4/month
- Enhanced monitoring: ~$2/month
- **Total: ~$50/month**

---

## 🔒 Security Best Practices

### 1. Restrict SSH Access
In `terraform.tfvars`:
```hcl
allowed_ssh_cidrs = ["YOUR_IP/32"]  # Your IP only
```

### 2. Use KMS Encryption
```hcl
enable_kms_encryption = true
kms_key_id = "arn:aws:kms:us-east-1:698302425856:key/..."
```

### 3. Secure State File
Use S3 backend (uncomment in `main.tf`):
```hcl
terraform {
  backend "s3" {
    bucket = "pgni-terraform-state"
    key    = "infrastructure/terraform.tfstate"
    region = "us-east-1"
    encrypt = true
  }
}
```

### 4. Rotate Credentials
```powershell
# Generate new password
terraform apply -var="db_password=NewSecurePassword123!"
```

### 5. Review Security Groups
```powershell
terraform show | grep security_group
```

---

## 🆘 Troubleshooting

### Issue: "terraform: command not found"
**Solution:**
```powershell
# Install Terraform
choco install terraform
# Or download from https://www.terraform.io/downloads
```

### Issue: "Error: configuring Terraform AWS Provider"
**Solution:**
```powershell
# Configure AWS CLI
aws configure
# Test
aws sts get-caller-identity
```

### Issue: "Error: creating RDS DB Instance: DBInstanceAlreadyExists"
**Solution:**
```powershell
# Import existing instance
terraform import aws_db_instance.main pgni-preprod-db
```

### Issue: "Error: InvalidParameterValue: The parameter MasterUserPassword is not a valid password"
**Solution:**
- Password must be 8-41 characters
- Must contain uppercase, lowercase, digits
- Cannot contain @, ", or /

### Issue: Terraform state is locked
**Solution:**
```powershell
# Force unlock (use with caution!)
terraform force-unlock <LOCK_ID>
```

---

## 🔄 CI/CD Integration

### GitHub Actions
After infrastructure is created, add these as GitHub Secrets:

```powershell
# Get values from Terraform outputs
terraform output github_secrets
```

Required secrets:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_REGION`
- `EC2_HOST`
- `SSH_PRIVATE_KEY`
- `DB_HOST`
- `DB_PASSWORD`
- `S3_BUCKET`

---

## 📝 Variables Reference

### Required Variables:
- `environment` - "preprod" or "production"
- `aws_region` - AWS region (default: us-east-1)
- `aws_account_id` - Your AWS account ID

### Optional Variables:
- `db_password` - Database password (auto-generated if empty)
- `enable_kms_encryption` - Use KMS for encryption
- `kms_key_id` - KMS key ARN
- `allowed_ssh_cidrs` - IP addresses allowed to SSH
- `allowed_http_cidrs` - IP addresses allowed to access API

See `variables.tf` for complete list.

---

## 📚 Additional Resources

- [Terraform AWS Provider Docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS RDS Documentation](https://docs.aws.amazon.com/rds/)
- [AWS EC2 Documentation](https://docs.aws.amazon.com/ec2/)
- [AWS S3 Documentation](https://docs.aws.amazon.com/s3/)

---

## ✅ Verification Checklist

After deployment, verify:

- [ ] RDS database is "Available"
- [ ] Can connect to database from EC2
- [ ] S3 bucket is created with CORS
- [ ] EC2 instance is "Running"
- [ ] Can SSH to EC2 instance
- [ ] Security groups allow required traffic
- [ ] API service is configured (systemd)
- [ ] All SSM parameters are created
- [ ] SSH key is saved securely
- [ ] Environment file is saved

---

## 🎉 Success Criteria

Infrastructure is ready when:
1. ✅ All `terraform apply` completed successfully
2. ✅ Can SSH to EC2 instance
3. ✅ Can connect to RDS from EC2
4. ✅ S3 bucket is accessible
5. ✅ API health check returns "ok"

---

**Created by:** PGNi Deployment Automation  
**Last Updated:** January 8, 2025  
**Terraform Version:** >= 1.0  
**AWS Provider:** ~> 5.0

