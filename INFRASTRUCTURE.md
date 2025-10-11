# 🏗️ PGNi Infrastructure Documentation

## Complete AWS Infrastructure Overview

---

## 📊 Infrastructure Summary

| Component | Status | Details |
|-----------|--------|---------|
| **Environment** | ✅ Active | Pre-production (preprod) |
| **Region** | ✅ Active | us-east-1 (N. Virginia) |
| **Account ID** | ✅ Active | 698302425856 |
| **Deployment Date** | ✅ Complete | October 11, 2025 |
| **Resources Created** | ✅ Complete | 36 resources |

---

## 🖥️ Compute Resources

### EC2 Instance
```yaml
Instance ID: i-0909d462845deb151
Instance Type: t3.micro
AMI: Amazon Linux 2023
Public IP: 34.227.111.143
Private IP: 172.31.27.239
State: Running
Availability Zone: us-east-1 (random subnet)
```

**Pre-installed Software:**
- Go 1.21+
- Git
- MySQL Client
- Systemd service for API

**Storage:**
- Root Volume: 30GB gp3 (encrypted with KMS)
- Encryption Key: app-pg-key

**SSH Access:**
- Key Pair: pgni-preprod-key
- Username: ec2-user
- Command: `ssh -i pgni-preprod-key.pem ec2-user@34.227.111.143`

**Cost:** $0/month (Free Tier - 750 hours/month)

---

## 💾 Database

### RDS MySQL Instance
```yaml
Identifier: database-pgni
Engine: MySQL 8.0
Instance Class: db.t3.micro
Status: Available
Endpoint: database-pgni.cezawkgguojl.us-east-1.rds.amazonaws.com
Port: 3306
Database Name: pgworld
Master Username: admin
```

**Storage:**
- Allocated: 20GB
- Type: gp2
- Auto-scaling: Disabled

**Backup:**
- Retention: 7 days
- Window: Automated

**Security:**
- Encryption: Enabled
- Public Access: No

**Cost:** ~$15/month

---

## 📦 Storage

### S3 Bucket
```yaml
Name: pgni-preprod-698302425856-uploads
Region: us-east-1
Versioning: Enabled
Encryption: KMS (app-pg-key)
Public Access: Blocked
```

**Features:**
- CORS: Configured for web uploads
- Lifecycle: Delete old versions after 90 days
- Transition: To Glacier after 90 days (production only)

**Bucket Policy:**
- EC2 instance has full access
- All other access denied

**Cost:** $0/month (Free Tier - 5GB storage)

---

## 🔒 Security

### EC2 Security Group (sg-0795934c2ed70bd1e)
```yaml
Name: pgni-preprod-api-sg
VPC: vpc-09074b1e8ad015613

Inbound Rules:
  - SSH (22): 0.0.0.0/0
  - HTTP (80): 0.0.0.0/0
  - HTTPS (443): 0.0.0.0/0
  - API (8080): 0.0.0.0/0

Outbound Rules:
  - All traffic: 0.0.0.0/0
```

### RDS Security Group (sg-03b57208ce6f5d3cd)
```yaml
Name: pgni-preprod-rds-sg
VPC: vpc-09074b1e8ad015613

Inbound Rules:
  - MySQL (3306): From EC2 security group only

Outbound Rules:
  - All traffic: 0.0.0.0/0
```

### IAM Role (pgni-preprod-ec2-role)
```yaml
Attached to: EC2 Instance
Policies:
  - AmazonSSMManagedInstanceCore (AWS Managed)
  - Custom S3 Access Policy
    - s3:GetObject on uploads bucket
    - s3:PutObject on uploads bucket
    - s3:DeleteObject on uploads bucket
    - s3:ListBucket on uploads bucket
  - Custom SSM Access Policy
    - ssm:GetParameter on /pgni/preprod/*
    - ssm:GetParameters on /pgni/preprod/*
```

---

## 🔑 Credentials & Keys

### SSH Key Pair
```yaml
Name: pgni-preprod-key
Type: RSA 4096-bit
Format: PEM
Location: pgni-preprod-key.pem (root directory)
```

**Usage:**
```bash
ssh -i pgni-preprod-key.pem ec2-user@34.227.111.143
```

### KMS Key
```yaml
Key ID: mrk-1b96d9eeccf649e695ed6ac2b13cb619
Alias: app-pg-key
Type: Customer managed
Usage: 
  - S3 bucket encryption
  - EC2 volume encryption
  - SSM parameter encryption (SecureString)
```

---

## 📝 SSM Parameters

All parameters stored in: `/pgni/preprod/`

### Database Parameters
```
/pgni/preprod/db/endpoint (String)
/pgni/preprod/db/username (String)
/pgni/preprod/db/password (SecureString - encrypted)
/pgni/preprod/db/name (String)
```

### Storage Parameters
```
/pgni/preprod/s3/bucket (String)
```

### Compute Parameters
```
/pgni/preprod/ec2/public_ip (String)
/pgni/preprod/ec2/private_key (SecureString - encrypted)
```

**Access:**
```bash
# View parameter
aws ssm get-parameter --name /pgni/preprod/db/endpoint

# View encrypted parameter
aws ssm get-parameter --name /pgni/preprod/db/password --with-decryption
```

---

## 🌐 Network Configuration

### VPC
```yaml
VPC ID: vpc-09074b1e8ad015613
Type: Default VPC
CIDR: (default)
DNS Support: Enabled
DNS Hostnames: Enabled
```

### Subnets
```yaml
Type: Default subnets (6 available)
Distribution: Across all availability zones in us-east-1
```

### Internet Gateway
```yaml
Attached: Yes (default VPC)
```

---

## 📈 Monitoring & Logging

### CloudWatch Logs
```yaml
Log Group: /aws/ec2/pgni-preprod
Retention: 7 days
```

**API Logs accessible via:**
```bash
sudo journalctl -u pgworld-api -f
```

### Metrics Available
- EC2: CPU, Network, Disk
- RDS: Connections, CPU, Storage, IOPS
- S3: Requests, Storage, Data transfer

---

## 💰 Cost Breakdown

### Monthly Costs (Estimated)

| Service | Type | Quantity | Cost |
|---------|------|----------|------|
| **EC2** | t3.micro | 750 hrs | $0 (Free Tier) |
| **RDS** | db.t3.micro | 1 instance | ~$15 |
| **S3** | Standard | <5GB | $0 (Free Tier) |
| **Data Transfer** | Out | <100GB | $0 (Free Tier) |
| **KMS** | Requests | Minimal | ~$0.03 |
| **SSM** | Parameters | <10 | $0 |
| **Total** | | | **~$15/month** |

**After Free Tier expires (12 months):**
- EC2 t3.micro: ~$8-10/month
- **Total:** ~$25-30/month

---

## 🔄 Backup & Recovery

### RDS Automated Backups
```yaml
Enabled: Yes
Retention: 7 days
Backup Window: Automated
Recovery Time: ~15 minutes
```

### S3 Versioning
```yaml
Enabled: Yes
Deleted Objects: Retained for 90 days
Recovery: Instant
```

### Terraform State
```yaml
Location: terraform/terraform.tfstate
Purpose: Infrastructure recreation
Backup: Commit to Git (encrypted)
```

---

## 📡 API Endpoints

### Base URL
```
http://34.227.111.143:8080
```

### Health Check
```
GET http://34.227.111.143:8080/health
Response: {"status":"healthy"}
```

### Common Endpoints (examples)
```
POST /api/auth/register
POST /api/auth/login
GET  /api/pgs
POST /api/pgs
GET  /api/bookings
POST /api/bookings
POST /api/upload
```

---

## 🔧 Terraform Configuration

### State
```yaml
Location: terraform/terraform.tfstate
Backend: Local
Resources Managed: 36
```

### Variables
```yaml
Environment: preprod
Region: us-east-1
Project Name: pgni
DB Username: admin
DB Password: (in terraform.tfvars)
DB Name: pgworld
```

### Key Files
- `main.tf` - Provider and backend configuration
- `variables.tf` - Input variables
- `outputs.tf` - Output values
- `rds.tf` - Database configuration
- `s3.tf` - Storage configuration
- `ec2.tf` - Compute configuration
- `security-groups.tf` - Network security
- `terraform.tfvars` - Variable values
- `existing-rds.tf` - Existing RDS reference
- `locals-override.tf` - Local variables

---

## 🚀 Deployment Files

### Essential Files
```
pgni-preprod-key.pem      - SSH private key
preprod.env               - API environment variables
deploy-api.sh             - EC2 deployment script
deploy-from-windows.ps1   - Windows deployment automation
```

### Documentation
```
README.md                 - Project overview
DEPLOYMENT_SUCCESS.md     - Infrastructure details
DEPLOY_NOW.md            - Deployment guide
INFRASTRUCTURE.md        - This file
PROJECT_STRUCTURE.md     - Project organization
PRE_DEPLOYMENT_CHECKLIST.md - Deployment checklist
```

---

## 🔍 Validation Commands

### Check EC2 Instance
```bash
aws ec2 describe-instances --instance-ids i-0909d462845deb151
```

### Check RDS Instance
```bash
aws rds describe-db-instances --db-instance-identifier database-pgni
```

### Check S3 Bucket
```bash
aws s3 ls s3://pgni-preprod-698302425856-uploads/
```

### Check Security Groups
```bash
aws ec2 describe-security-groups --group-ids sg-0795934c2ed70bd1e sg-03b57208ce6f5d3cd
```

### Test Connectivity
```bash
# From local machine
ping 34.227.111.143
curl http://34.227.111.143:8080/health

# From EC2 to RDS
mysql -h database-pgni.cezawkgguojl.us-east-1.rds.amazonaws.com -u admin -p

# From EC2 to S3
aws s3 ls s3://pgni-preprod-698302425856-uploads/
```

---

## 📞 Quick Reference

### Connection Strings

**SSH to EC2:**
```bash
ssh -i pgni-preprod-key.pem ec2-user@34.227.111.143
```

**MySQL Connection:**
```bash
mysql -h database-pgni.cezawkgguojl.us-east-1.rds.amazonaws.com -P 3306 -u admin -p pgworld
```

**S3 Access:**
```bash
aws s3 cp file.txt s3://pgni-preprod-698302425856-uploads/
```

---

## ✅ Infrastructure Checklist

- [x] EC2 instance running
- [x] RDS database available
- [x] S3 bucket created and configured
- [x] Security groups configured
- [x] IAM roles attached
- [x] SSH key generated
- [x] SSM parameters stored
- [x] Networking configured
- [x] Encryption enabled
- [x] Backups configured
- [x] Monitoring enabled
- [ ] API deployed
- [ ] Database initialized
- [ ] End-to-end tested

---

## 🔄 Update Infrastructure

To modify infrastructure:

1. **Update Terraform files:**
   ```bash
   cd terraform
   # Edit .tf files
   ```

2. **Plan changes:**
   ```bash
   terraform plan
   ```

3. **Apply changes:**
   ```bash
   terraform apply
   ```

4. **View outputs:**
   ```bash
   terraform output
   ```

---

## 🗑️ Destroy Infrastructure

**⚠️ WARNING: This will delete ALL resources!**

```bash
cd terraform
terraform destroy
```

**Resources that will be deleted:**
- EC2 instance
- Security groups
- IAM roles
- SSH key pair
- SSM parameters
- S3 bucket (if empty)

**Resources that will NOT be deleted:**
- RDS database (manually created)
- KMS key (manually created)
- VPC (default VPC)

---

**Infrastructure Status:** ✅ **READY**  
**Last Updated:** October 11, 2025  
**Next Action:** Deploy API (see DEPLOY_NOW.md)

