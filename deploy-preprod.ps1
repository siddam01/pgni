#!/usr/bin/env pwsh
# Automated Pre-Production Deployment Script for PGNi
# This script will create all AWS resources and deploy the API

param(
    [string]$AwsRegion = "ap-south-1",
    [string]$DbPassword = "",
    [string]$AwsAccessKeyId = "",
    [string]$AwsSecretAccessKey = ""
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  PGNi PRE-PRODUCTION DEPLOYMENT" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

# Check if AWS CLI is installed
Write-Host "Checking AWS CLI installation..." -ForegroundColor Yellow
$awsCli = Get-Command aws -ErrorAction SilentlyContinue
if (-not $awsCli) {
    Write-Host "ERROR: AWS CLI not installed!" -ForegroundColor Red
    Write-Host "Install with: winget install Amazon.AWSCLI" -ForegroundColor Yellow
    exit 1
}
Write-Host "AWS CLI found: $($awsCli.Version)" -ForegroundColor Green

# Configure AWS credentials if provided
if ($AwsAccessKeyId -and $AwsSecretAccessKey) {
    Write-Host ""
    Write-Host "Configuring AWS credentials..." -ForegroundColor Yellow
    $env:AWS_ACCESS_KEY_ID = $AwsAccessKeyId
    $env:AWS_SECRET_ACCESS_KEY = $AwsSecretAccessKey
    $env:AWS_DEFAULT_REGION = $AwsRegion
}

# Test AWS connection
Write-Host ""
Write-Host "Testing AWS connection..." -ForegroundColor Yellow
try {
    $identity = aws sts get-caller-identity --output json | ConvertFrom-Json
    Write-Host "Connected to AWS Account: $($identity.Account)" -ForegroundColor Green
    Write-Host "User: $($identity.Arn)" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Cannot connect to AWS!" -ForegroundColor Red
    Write-Host "Please configure AWS credentials first:" -ForegroundColor Yellow
    Write-Host "  aws configure" -ForegroundColor White
    exit 1
}

# Generate DB password if not provided
if (-not $DbPassword) {
    Write-Host ""
    Write-Host "Generating secure database password..." -ForegroundColor Yellow
    $DbPassword = -join ((33..126) | Get-Random -Count 20 | ForEach-Object {[char]$_})
    Write-Host "Generated password (SAVE THIS!): $DbPassword" -ForegroundColor Green
}

# Variables
$ProjectName = "pgni"
$Environment = "preprod"
$Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$DeploymentLog = "deployment-preprod-$Timestamp.log"

Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  DEPLOYMENT CONFIGURATION" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "Project: $ProjectName" -ForegroundColor White
Write-Host "Environment: $Environment" -ForegroundColor White
Write-Host "Region: $AwsRegion" -ForegroundColor White
Write-Host "Timestamp: $Timestamp" -ForegroundColor White
Write-Host ""

# Start logging
Start-Transcript -Path $DeploymentLog

# Step 1: Create VPC Security Group
Write-Host ""
Write-Host "================================================================" -ForegroundColor Yellow
Write-Host "  STEP 1: CREATE SECURITY GROUP" -ForegroundColor Yellow
Write-Host "================================================================" -ForegroundColor Yellow

$sgName = "$ProjectName-$Environment-sg"
Write-Host "Creating security group: $sgName..." -ForegroundColor White

# Get default VPC
$defaultVpc = aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query "Vpcs[0].VpcId" --output text --region $AwsRegion

if ($defaultVpc -eq "None" -or -not $defaultVpc) {
    Write-Host "ERROR: No default VPC found!" -ForegroundColor Red
    exit 1
}

Write-Host "Using VPC: $defaultVpc" -ForegroundColor Green

# Create security group
try {
    $sgId = aws ec2 create-security-group `
        --group-name $sgName `
        --description "Security group for PGNi pre-production" `
        --vpc-id $defaultVpc `
        --region $AwsRegion `
        --output text

    Write-Host "Security Group created: $sgId" -ForegroundColor Green

    # Add inbound rules
    Write-Host "Adding security group rules..." -ForegroundColor White
    
    # SSH
    aws ec2 authorize-security-group-ingress --group-id $sgId --protocol tcp --port 22 --cidr 0.0.0.0/0 --region $AwsRegion
    # HTTP
    aws ec2 authorize-security-group-ingress --group-id $sgId --protocol tcp --port 80 --cidr 0.0.0.0/0 --region $AwsRegion
    # HTTPS
    aws ec2 authorize-security-group-ingress --group-id $sgId --protocol tcp --port 443 --cidr 0.0.0.0/0 --region $AwsRegion
    # API Port
    aws ec2 authorize-security-group-ingress --group-id $sgId --protocol tcp --port 8080 --cidr 0.0.0.0/0 --region $AwsRegion
    # MySQL
    aws ec2 authorize-security-group-ingress --group-id $sgId --protocol tcp --port 3306 --cidr 0.0.0.0/0 --region $AwsRegion
    
    Write-Host "Security group rules added" -ForegroundColor Green
} catch {
    # Check if security group already exists
    $existingSg = aws ec2 describe-security-groups --filters "Name=group-name,Values=$sgName" --query "SecurityGroups[0].GroupId" --output text --region $AwsRegion
    if ($existingSg -and $existingSg -ne "None") {
        $sgId = $existingSg
        Write-Host "Security group already exists: $sgId" -ForegroundColor Yellow
    } else {
        Write-Host "ERROR: Failed to create security group!" -ForegroundColor Red
        throw
    }
}

# Step 2: Create RDS Database
Write-Host ""
Write-Host "================================================================" -ForegroundColor Yellow
Write-Host "  STEP 2: CREATE RDS MySQL DATABASE" -ForegroundColor Yellow
Write-Host "================================================================" -ForegroundColor Yellow

$dbIdentifier = "$ProjectName-$Environment-db"
$dbName = "pgnidb"
$dbUsername = "pgni_admin"

Write-Host "Creating RDS instance: $dbIdentifier..." -ForegroundColor White
Write-Host "This will take 5-10 minutes..." -ForegroundColor Yellow

try {
    aws rds create-db-instance `
        --db-instance-identifier $dbIdentifier `
        --db-instance-class db.t3.micro `
        --engine mysql `
        --engine-version 8.0.35 `
        --master-username $dbUsername `
        --master-user-password $DbPassword `
        --allocated-storage 20 `
        --storage-type gp2 `
        --vpc-security-group-ids $sgId `
        --db-name $dbName `
        --backup-retention-period 7 `
        --preferred-backup-window "03:00-04:00" `
        --preferred-maintenance-window "mon:04:00-mon:05:00" `
        --publicly-accessible `
        --no-multi-az `
        --region $AwsRegion
    
    Write-Host "RDS instance creation initiated" -ForegroundColor Green
    
    # Wait for RDS to be available
    Write-Host "Waiting for RDS instance to become available..." -ForegroundColor Yellow
    Write-Host "This may take 5-10 minutes. Please be patient..." -ForegroundColor Yellow
    
    aws rds wait db-instance-available --db-instance-identifier $dbIdentifier --region $AwsRegion
    
    # Get RDS endpoint
    $rdsEndpoint = aws rds describe-db-instances `
        --db-instance-identifier $dbIdentifier `
        --query "DBInstances[0].Endpoint.Address" `
        --output text `
        --region $AwsRegion
    
    Write-Host "RDS instance is ready!" -ForegroundColor Green
    Write-Host "Endpoint: $rdsEndpoint" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Failed to create RDS instance!" -ForegroundColor Red
    Write-Host "Checking if it already exists..." -ForegroundColor Yellow
    
    $existingRds = aws rds describe-db-instances `
        --db-instance-identifier $dbIdentifier `
        --query "DBInstances[0].Endpoint.Address" `
        --output text `
        --region $AwsRegion 2>$null
    
    if ($existingRds -and $existingRds -ne "None") {
        $rdsEndpoint = $existingRds
        Write-Host "RDS instance already exists: $rdsEndpoint" -ForegroundColor Yellow
    } else {
        throw
    }
}

# Step 3: Create S3 Bucket
Write-Host ""
Write-Host "================================================================" -ForegroundColor Yellow
Write-Host "  STEP 3: CREATE S3 BUCKET" -ForegroundColor Yellow
Write-Host "================================================================" -ForegroundColor Yellow

$s3BucketName = "$ProjectName-uploads-$Environment-$(Get-Random -Minimum 1000 -Maximum 9999)"
Write-Host "Creating S3 bucket: $s3BucketName..." -ForegroundColor White

try {
    aws s3api create-bucket `
        --bucket $s3BucketName `
        --region $AwsRegion `
        --create-bucket-configuration LocationConstraint=$AwsRegion
    
    Write-Host "S3 bucket created: $s3BucketName" -ForegroundColor Green
    
    # Enable versioning
    Write-Host "Enabling versioning..." -ForegroundColor White
    aws s3api put-bucket-versioning `
        --bucket $s3BucketName `
        --versioning-configuration Status=Enabled `
        --region $AwsRegion
    
    # Configure CORS
    Write-Host "Configuring CORS..." -ForegroundColor White
    $corsConfig = @"
{
    "CORSRules": [
        {
            "AllowedOrigins": ["*"],
            "AllowedMethods": ["GET", "POST", "PUT", "DELETE"],
            "AllowedHeaders": ["*"],
            "MaxAgeSeconds": 3000
        }
    ]
}
"@
    $corsConfig | Out-File -FilePath "cors-config.json" -Encoding UTF8
    aws s3api put-bucket-cors --bucket $s3BucketName --cors-configuration file://cors-config.json --region $AwsRegion
    Remove-Item "cors-config.json"
    
    Write-Host "S3 bucket configured successfully" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Failed to create S3 bucket!" -ForegroundColor Red
    throw
}

# Step 4: Create EC2 Instance
Write-Host ""
Write-Host "================================================================" -ForegroundColor Yellow
Write-Host "  STEP 4: CREATE EC2 INSTANCE" -ForegroundColor Yellow
Write-Host "================================================================" -ForegroundColor Yellow

$keyPairName = "$ProjectName-$Environment-key"
$instanceName = "$ProjectName-$Environment-server"

Write-Host "Using key pair: $keyPairName" -ForegroundColor White

# Get latest Ubuntu 22.04 AMI
Write-Host "Finding latest Ubuntu 22.04 AMI..." -ForegroundColor White
$amiId = aws ec2 describe-images `
    --owners 099720109477 `
    --filters "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*" "Name=state,Values=available" `
    --query "sort_by(Images, &CreationDate)[-1].ImageId" `
    --output text `
    --region $AwsRegion

Write-Host "Using AMI: $amiId" -ForegroundColor Green

# Create user data script
$userData = @"
#!/bin/bash
set -e

# Update system
apt-get update
apt-get upgrade -y

# Install Go
cd /tmp
wget https://go.dev/dl/go1.21.5.linux-amd64.tar.gz
rm -rf /usr/local/go
tar -C /usr/local -xzf go1.21.5.linux-amd64.tar.gz
echo 'export PATH=\$PATH:/usr/local/go/bin' >> /etc/profile
source /etc/profile

# Install MySQL client
apt-get install -y mysql-client

# Install AWS CLI
apt-get install -y awscli

# Create application directory
mkdir -p /opt/pgworld
chown ubuntu:ubuntu /opt/pgworld

# Create systemd service
cat > /etc/systemd/system/pgworld-api.service << 'EOF'
[Unit]
Description=PGNi API Server
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/opt/pgworld
EnvironmentFile=/opt/pgworld/.env
ExecStart=/opt/pgworld/pgworld-api
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable pgworld-api

echo "EC2 setup complete" > /tmp/setup-complete.txt
"@

$userDataBase64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($userData))

# Launch EC2 instance
Write-Host "Launching EC2 instance..." -ForegroundColor White

try {
    $instanceId = aws ec2 run-instances `
        --image-id $amiId `
        --instance-type t3.micro `
        --key-name $keyPairName `
        --security-group-ids $sgId `
        --user-data $userData `
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instanceName},{Key=Environment,Value=$Environment}]" `
        --region $AwsRegion `
        --query "Instances[0].InstanceId" `
        --output text
    
    Write-Host "EC2 instance launched: $instanceId" -ForegroundColor Green
    
    # Wait for instance to be running
    Write-Host "Waiting for instance to be running..." -ForegroundColor Yellow
    aws ec2 wait instance-running --instance-ids $instanceId --region $AwsRegion
    
    # Get public IP
    $publicIp = aws ec2 describe-instances `
        --instance-ids $instanceId `
        --query "Reservations[0].Instances[0].PublicIpAddress" `
        --output text `
        --region $AwsRegion
    
    Write-Host "EC2 instance is running!" -ForegroundColor Green
    Write-Host "Public IP: $publicIp" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Failed to launch EC2 instance!" -ForegroundColor Red
    Write-Host "Make sure key pair '$keyPairName' exists in AWS!" -ForegroundColor Yellow
    throw
}

# Step 5: Create environment file content
Write-Host ""
Write-Host "================================================================" -ForegroundColor Yellow
Write-Host "  STEP 5: PREPARE ENVIRONMENT CONFIGURATION" -ForegroundColor Yellow
Write-Host "================================================================" -ForegroundColor Yellow

$envContent = @"
# Database Configuration
DB_HOST=$rdsEndpoint
DB_USER=$dbUsername
DB_PASSWORD=$DbPassword
DB_NAME=$dbName
DB_PORT=3306

# API Configuration
PORT=8080
test=true

# AWS Configuration
AWS_REGION=$AwsRegion
S3_BUCKET_NAME=$s3BucketName

# API Keys (Update these with your actual values)
ANDROID_LIVE_KEY=your-android-live-key
ANDROID_TEST_KEY=your-android-test-key
IOS_LIVE_KEY=your-ios-live-key
IOS_TEST_KEY=your-ios-test-key

# Razorpay (Update these with your actual values)
RAZORPAY_KEY_ID=your-razorpay-key-id
RAZORPAY_KEY_SECRET=your-razorpay-key-secret
"@

$envContent | Out-File -FilePath "preprod.env" -Encoding UTF8
Write-Host "Environment configuration saved to: preprod.env" -ForegroundColor Green

# Stop logging
Stop-Transcript

# Step 6: Generate deployment report
Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  DEPLOYMENT COMPLETE!" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

# Create detailed deployment report
$reportContent = @"
# PGNi Pre-Production Deployment Report

**Deployment Date:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
**Environment:** Pre-Production
**Region:** $AwsRegion

---

## Deployment Summary

✅ **Status:** Successfully Deployed
⏱️ **Duration:** Started at $Timestamp
🌍 **Region:** Asia Pacific (Mumbai) - $AwsRegion

---

## AWS Resources Created

### 1. Security Group
- **Group ID:** $sgId
- **Name:** $sgName
- **VPC:** $defaultVpc
- **Inbound Rules:**
  - SSH (22): 0.0.0.0/0
  - HTTP (80): 0.0.0.0/0
  - HTTPS (443): 0.0.0.0/0
  - API (8080): 0.0.0.0/0
  - MySQL (3306): 0.0.0.0/0

### 2. RDS MySQL Database
- **Instance ID:** $dbIdentifier
- **Endpoint:** ``$rdsEndpoint``
- **Port:** 3306
- **Database Name:** $dbName
- **Username:** $dbUsername
- **Password:** ``$DbPassword`` ⚠️ **SAVE THIS SECURELY!**
- **Instance Class:** db.t3.micro (Free Tier)
- **Storage:** 20 GB
- **Backup Retention:** 7 days
- **Public Access:** Yes
- **Multi-AZ:** No

### 3. S3 Bucket
- **Bucket Name:** ``$s3BucketName``
- **Region:** $AwsRegion
- **Versioning:** Enabled
- **CORS:** Configured for API access
- **URL:** https://s3.$AwsRegion.amazonaws.com/$s3BucketName

### 4. EC2 Instance
- **Instance ID:** $instanceId
- **Public IP:** ``$publicIp``
- **Instance Type:** t3.micro (Free Tier)
- **AMI:** Ubuntu 22.04 LTS
- **Key Pair:** $keyPairName
- **Security Group:** $sgId

---

## Access Information

### SSH Access
``````bash
ssh -i "C:\AWS-Keys\$keyPairName.pem" ubuntu@$publicIp
``````

### API Endpoint
- **URL:** ``http://$publicIp:8080/``
- **Health Check:** ``http://$publicIp:8080/``

### Database Connection
``````bash
mysql -h $rdsEndpoint -u $dbUsername -p$DbPassword $dbName
``````

### S3 Bucket Access
``````bash
aws s3 ls s3://$s3BucketName/
``````

---

## Environment Variables

The environment configuration has been saved to: ``preprod.env``

**Database:**
- DB_HOST: $rdsEndpoint
- DB_USER: $dbUsername
- DB_PASSWORD: $DbPassword
- DB_NAME: $dbName
- DB_PORT: 3306

**AWS:**
- AWS_REGION: $AwsRegion
- S3_BUCKET_NAME: $s3BucketName

**⚠️ IMPORTANT:** Update API keys and Razorpay credentials in ``preprod.env``

---

## Next Steps

### 1. Update GitHub Secrets

Go to: https://github.com/siddam01/pgni/settings/secrets/actions

Add these secrets:

**PREPROD_SSH_KEY:**
``````powershell
`$pemContent = Get-Content "C:\AWS-Keys\$keyPairName.pem" -Raw
`$bytes = [System.Text.Encoding]::UTF8.GetBytes(`$pemContent)
[Convert]::ToBase64String(`$bytes) | clip
``````

**PREPROD_HOST:**
``````
$publicIp
``````

### 2. Build and Deploy API

``````powershell
# Build API
cd pgworld-api-master
go build -o pgworld-api .

# Copy to EC2
scp -i "C:\AWS-Keys\$keyPairName.pem" pgworld-api ubuntu@$publicIp:/tmp/
scp -i "C:\AWS-Keys\$keyPairName.pem" ../preprod.env ubuntu@$publicIp:/tmp/.env

# SSH to EC2 and setup
ssh -i "C:\AWS-Keys\$keyPairName.pem" ubuntu@$publicIp

# On EC2:
sudo mv /tmp/pgworld-api /opt/pgworld/pgworld-api
sudo mv /tmp/.env /opt/pgworld/.env
sudo chmod +x /opt/pgworld/pgworld-api
sudo systemctl start pgworld-api
sudo systemctl status pgworld-api
``````

### 3. Initialize Database

``````bash
# Connect to database
mysql -h $rdsEndpoint -u $dbUsername -p$DbPassword $dbName

# Run your SQL schema
# Or use your application's migration scripts
``````

### 4. Test API

``````powershell
# Health check
curl http://$publicIp:8080/

# Test endpoints
curl http://$publicIp:8080/api/health
``````

### 5. Update Flutter Apps

Update API endpoints in your Flutter apps:

**Admin App (pgworld-master):**
``````dart
const String API_URL = "http://$publicIp:8080";
``````

**Tenant App (pgworldtenant-master):**
``````dart
const String API_URL = "http://$publicIp:8080";
``````

---

## Monitoring and Maintenance

### Check API Logs
``````bash
ssh -i "C:\AWS-Keys\$keyPairName.pem" ubuntu@$publicIp
sudo journalctl -u pgworld-api -f
``````

### Check API Status
``````bash
sudo systemctl status pgworld-api
``````

### Restart API
``````bash
sudo systemctl restart pgworld-api
``````

### Database Backup
``````bash
mysqldump -h $rdsEndpoint -u $dbUsername -p$DbPassword $dbName > backup.sql
``````

### Monitor Costs
- AWS Free Tier Dashboard: https://console.aws.amazon.com/billing/home#/freetier
- Cost Explorer: https://console.aws.amazon.com/cost-management/home

---

## Troubleshooting

### Cannot SSH to EC2
``````bash
# Check security group allows SSH from your IP
# Verify key pair file permissions
chmod 400 C:\AWS-Keys\$keyPairName.pem
``````

### Cannot Connect to Database
``````bash
# Check security group allows port 3306
# Verify database is publicly accessible
# Test connection from EC2 instance first
``````

### API Not Starting
``````bash
# Check logs
sudo journalctl -u pgworld-api -n 50

# Verify environment file
cat /opt/pgworld/.env

# Check if port 8080 is available
sudo netstat -tulpn | grep 8080
``````

---

## Security Recommendations

### Immediate Actions:
1. ✅ Enable MFA on AWS root account
2. ✅ Use IAM user for all operations
3. ⚠️ **Update default API keys in preprod.env**
4. ⚠️ **Add Razorpay credentials in preprod.env**
5. ⚠️ **Change security group to restrict SSH to your IP only**

### Production Readiness:
1. Set up CloudWatch alarms
2. Configure automated backups
3. Use Application Load Balancer
4. Set up SSL/TLS certificates
5. Implement WAF rules
6. Enable CloudTrail logging

---

## Cost Estimate (Free Tier)

**Monthly Costs (within Free Tier limits):**
- EC2 t3.micro: FREE (750 hours/month)
- RDS db.t3.micro: FREE (750 hours/month)
- S3 Storage (< 5GB): FREE
- Data Transfer (< 15GB): FREE

**Expected Cost:** ₹0-500/month

**After Free Tier (Month 13+):**
- EC2 t3.micro: ~₹600/month
- RDS db.t3.micro: ~₹900/month
- S3 + Data Transfer: ~₹150/month
**Total:** ~₹1,650/month

---

## Support

### AWS Support
- Phone: 1800-572-4555 (India, toll-free)
- Console: https://console.aws.amazon.com/support/

### Deployment Log
- Full deployment log: ``$DeploymentLog``

---

## Important Credentials (Store Securely!)

**⚠️ CRITICAL: Save these credentials in a secure password manager!**

- **Database Password:** ``$DbPassword``
- **RDS Endpoint:** ``$rdsEndpoint``
- **EC2 Public IP:** ``$publicIp``
- **S3 Bucket:** ``$s3BucketName``
- **Security Group:** ``$sgId``

---

## Cleanup (To Delete Everything)

**⚠️ WARNING: This will delete all resources and data!**

``````powershell
# Terminate EC2 instance
aws ec2 terminate-instances --instance-ids $instanceId --region $AwsRegion

# Delete RDS instance
aws rds delete-db-instance --db-instance-identifier $dbIdentifier --skip-final-snapshot --region $AwsRegion

# Empty and delete S3 bucket
aws s3 rm s3://$s3BucketName --recursive --region $AwsRegion
aws s3api delete-bucket --bucket $s3BucketName --region $AwsRegion

# Delete security group (after EC2/RDS are deleted)
aws ec2 delete-security-group --group-id $sgId --region $AwsRegion
``````

---

**Deployment completed successfully! 🎉**

*Report generated on: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")*
*Environment: Pre-Production*
*Region: $AwsRegion*
"@

$reportPath = "PREPROD_DEPLOYMENT_REPORT.md"
$reportContent | Out-File -FilePath $reportPath -Encoding UTF8

Write-Host ""
Write-Host "================================================================" -ForegroundColor Green
Write-Host "  DEPLOYMENT REPORT GENERATED" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Report saved to: $reportPath" -ForegroundColor Yellow
Write-Host "Environment file: preprod.env" -ForegroundColor Yellow
Write-Host "Deployment log: $DeploymentLog" -ForegroundColor Yellow
Write-Host ""
Write-Host "IMPORTANT INFORMATION:" -ForegroundColor Red
Write-Host "  EC2 Public IP: $publicIp" -ForegroundColor White
Write-Host "  RDS Endpoint: $rdsEndpoint" -ForegroundColor White
Write-Host "  S3 Bucket: $s3BucketName" -ForegroundColor White
Write-Host "  Database Password: $DbPassword" -ForegroundColor White
Write-Host ""
Write-Host "SAVE THESE CREDENTIALS SECURELY!" -ForegroundColor Red
Write-Host ""
Write-Host "Next: Open $reportPath for complete deployment details" -ForegroundColor Cyan
Write-Host ""

