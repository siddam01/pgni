# 🚀 AWS CI/CD Pipeline Setup - Pre-Prod & Production

**Project:** PG World  
**Environments:** Development → Pre-Production → Production  
**Platform:** AWS with automated pipeline

---

## 🎯 ARCHITECTURE OVERVIEW

```
Developer → GitHub → AWS CodePipeline
                     ↓
              ┌──────────────┐
              │ CodeBuild    │
              │ (Build & Test)│
              └──────────────┘
                     ↓
         ┌───────────┴───────────┐
         ↓                       ↓
    PRE-PRODUCTION          PRODUCTION
    ├─ RDS MySQL           ├─ RDS MySQL
    ├─ EC2/Lambda          ├─ EC2/Lambda
    ├─ S3 Bucket           ├─ S3 Bucket
    └─ api-preprod.        └─ api.pgworld.com
       pgworld.com
```

---

## 📊 ENVIRONMENT STRATEGY

| Environment | Purpose | URL | Database | Auto-Deploy |
|-------------|---------|-----|----------|-------------|
| **Development** | Local testing | localhost:8080 | Local MySQL | Manual |
| **Pre-Production** | Staging/Testing | api-preprod.pgworld.com | RDS (small) | Auto on merge to `develop` |
| **Production** | Live users | api.pgworld.com | RDS (large) | Manual approval from pre-prod |

---

## 🔧 STEP-BY-STEP SETUP

### PHASE 1: Prepare Your Code (30 minutes)

#### Step 1: Create Environment-Specific Config Files

1. **Navigate to API directory:**
   ```powershell
   cd C:\MyFolder\Mytest\pgworld-master\pgworld-api-master
   ```

2. **Create `.env.development`:**
   ```env
   # Development Environment
   dbConfig=root:root@tcp(localhost:3306)/pgworld_db
   connectionPool=10
   baseURL=http://localhost:8080
   test=true
   migrate=false
   
   supportEmailID=dev@pgworld.com
   supportEmailPassword=dev_password
   supportEmailHost=smtp.gmail.com
   supportEmailPort=587
   
   ANDROID_LIVE_KEY=DEV_KEY_12345
   ANDROID_TEST_KEY=DEV_KEY_67890
   IOS_LIVE_KEY=DEV_KEY_ABCDE
   IOS_TEST_KEY=DEV_KEY_FGHIJ
   
   RAZORPAY_KEY_ID=test_key
   RAZORPAY_KEY_SECRET=test_secret
   
   s3Bucket=pgworld-dev-uploads
   AWS_REGION=us-east-1
   ```

3. **Create `.env.preprod.template`:**
   ```env
   # Pre-Production Environment (Will be stored in AWS Systems Manager)
   dbConfig=PREPROD_DB_CONNECTION
   connectionPool=15
   baseURL=https://api-preprod.pgworld.com
   test=false
   migrate=false
   
   supportEmailID=PREPROD_EMAIL
   supportEmailPassword=PREPROD_EMAIL_PASSWORD
   supportEmailHost=smtp.gmail.com
   supportEmailPort=587
   
   ANDROID_LIVE_KEY=PREPROD_ANDROID_LIVE_KEY
   ANDROID_TEST_KEY=PREPROD_ANDROID_TEST_KEY
   IOS_LIVE_KEY=PREPROD_IOS_LIVE_KEY
   IOS_TEST_KEY=PREPROD_IOS_TEST_KEY
   
   RAZORPAY_KEY_ID=PREPROD_RAZORPAY_KEY
   RAZORPAY_KEY_SECRET=PREPROD_RAZORPAY_SECRET
   
   s3Bucket=pgworld-preprod-uploads
   AWS_REGION=us-east-1
   ```

4. **Create `.env.production.template`:**
   ```env
   # Production Environment (Will be stored in AWS Systems Manager)
   dbConfig=PROD_DB_CONNECTION
   connectionPool=20
   baseURL=https://api.pgworld.com
   test=false
   migrate=false
   
   supportEmailID=PROD_EMAIL
   supportEmailPassword=PROD_EMAIL_PASSWORD
   supportEmailHost=smtp.gmail.com
   supportEmailPort=587
   
   ANDROID_LIVE_KEY=PROD_ANDROID_LIVE_KEY
   ANDROID_TEST_KEY=PROD_ANDROID_TEST_KEY
   IOS_LIVE_KEY=PROD_IOS_LIVE_KEY
   IOS_TEST_KEY=PROD_IOS_TEST_KEY
   
   RAZORPAY_KEY_ID=PROD_RAZORPAY_KEY
   RAZORPAY_KEY_SECRET=PROD_RAZORPAY_SECRET
   
   s3Bucket=pgworld-production-uploads
   AWS_REGION=us-east-1
   ```

#### Step 2: Create BuildSpec for AWS CodeBuild

Create `pgworld-api-master/buildspec.yml`:

```yaml
version: 0.2

env:
  parameter-store:
    # These will be loaded from AWS Systems Manager Parameter Store
    DB_CONFIG: "/pgworld/${ENVIRONMENT}/dbConfig"
    BASE_URL: "/pgworld/${ENVIRONMENT}/baseURL"
    SUPPORT_EMAIL_ID: "/pgworld/${ENVIRONMENT}/supportEmailID"
    SUPPORT_EMAIL_PASSWORD: "/pgworld/${ENVIRONMENT}/supportEmailPassword"
    ANDROID_LIVE_KEY: "/pgworld/${ENVIRONMENT}/androidLiveKey"
    ANDROID_TEST_KEY: "/pgworld/${ENVIRONMENT}/androidTestKey"
    IOS_LIVE_KEY: "/pgworld/${ENVIRONMENT}/iOSLiveKey"
    IOS_TEST_KEY: "/pgworld/${ENVIRONMENT}/iOSTestKey"
    RAZORPAY_KEY_ID: "/pgworld/${ENVIRONMENT}/razorpayKeyID"
    RAZORPAY_KEY_SECRET: "/pgworld/${ENVIRONMENT}/razorpayKeySecret"
    S3_BUCKET: "/pgworld/${ENVIRONMENT}/s3Bucket"

phases:
  install:
    runtime-versions:
      golang: 1.21
    commands:
      - echo "Installing dependencies..."
      - cd pgworld-api-master
      
  pre_build:
    commands:
      - echo "Running pre-build checks..."
      - echo "Environment: $ENVIRONMENT"
      - go version
      - go mod download
      
  build:
    commands:
      - echo "Building application..."
      - CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o pgworld-api .
      - echo "Build completed successfully"
      
  post_build:
    commands:
      - echo "Creating deployment package..."
      - echo "Build completed on $(date)"

artifacts:
  files:
    - pgworld-api-master/pgworld-api
    - pgworld-api-master/setup-database.sql
    - pgworld-api-master/migrations/**/*
  name: pgworld-api-$(date +%Y%m%d-%H%M%S)

cache:
  paths:
    - '/go/pkg/mod/**/*'
```

#### Step 3: Create Deployment Scripts

Create `pgworld-api-master/scripts/deploy.sh`:

```bash
#!/bin/bash
# Deploy script for EC2

set -e

ENVIRONMENT=$1
ARTIFACT_PATH=$2

echo "=========================================="
echo "Deploying to $ENVIRONMENT"
echo "=========================================="

# Stop existing service
sudo systemctl stop pgworld-api || true

# Backup current version
if [ -f /opt/pgworld/pgworld-api ]; then
    sudo cp /opt/pgworld/pgworld-api /opt/pgworld/pgworld-api.backup
fi

# Copy new version
sudo cp $ARTIFACT_PATH/pgworld-api /opt/pgworld/pgworld-api
sudo chmod +x /opt/pgworld/pgworld-api

# Load environment variables from AWS Systems Manager
aws ssm get-parameters-by-path \
    --path "/pgworld/$ENVIRONMENT/" \
    --with-decryption \
    --region us-east-1 \
    --query "Parameters[*].[Name,Value]" \
    --output text | while read name value; do
    param_name=$(echo $name | awk -F'/' '{print $NF}')
    echo "$param_name=$value" >> /tmp/pgworld.env
done

sudo mv /tmp/pgworld.env /opt/pgworld/.env

# Start service
sudo systemctl start pgworld-api
sudo systemctl status pgworld-api

echo "Deployment completed successfully!"
```

Make it executable:
```powershell
# In Git Bash or WSL
chmod +x pgworld-api-master/scripts/deploy.sh
```

#### Step 4: Update .gitignore

Add to `pgworld-api-master/.gitignore`:

```gitignore
# Environment files
.env
.env.local
.env.development
.env.preprod
.env.production

# Keep templates
!.env.*.template

# Deployment artifacts
pgworld-api
*.zip
```

---

### PHASE 2: Set Up AWS Infrastructure (2 hours)

#### Step 1: Create Pre-Production Environment

**1.1 Create Pre-Prod RDS Database:**

```bash
# Use AWS CLI or Console
aws rds create-db-instance \
    --db-instance-identifier pgworld-preprod-db \
    --db-instance-class db.t3.micro \
    --engine mysql \
    --engine-version 8.0 \
    --master-username admin \
    --master-user-password "SECURE_PASSWORD_HERE" \
    --allocated-storage 20 \
    --vpc-security-group-ids sg-XXXXXXXX \
    --db-name pgworld_db \
    --backup-retention-period 7 \
    --tags Key=Environment,Value=preprod Key=Project,Value=pgworld
```

**1.2 Create Pre-Prod S3 Bucket:**

```bash
aws s3 mb s3://pgworld-preprod-uploads --region us-east-1
```

**1.3 Create Pre-Prod EC2 Instance:**

```bash
# Launch EC2 instance via Console or CLI
# Tag: Environment=preprod, Name=pgworld-preprod-api
```

#### Step 2: Create Production Environment

**2.1 Create Production RDS Database:**

```bash
aws rds create-db-instance \
    --db-instance-identifier pgworld-prod-db \
    --db-instance-class db.t3.small \
    --engine mysql \
    --engine-version 8.0 \
    --master-username admin \
    --master-user-password "DIFFERENT_SECURE_PASSWORD" \
    --allocated-storage 50 \
    --vpc-security-group-ids sg-XXXXXXXX \
    --db-name pgworld_db \
    --backup-retention-period 30 \
    --multi-az \
    --tags Key=Environment,Value=production Key=Project,Value=pgworld
```

**2.2 Create Production S3 Bucket:**

```bash
aws s3 mb s3://pgworld-production-uploads --region us-east-1
```

**2.3 Create Production EC2 Instance:**

```bash
# Launch EC2 instance via Console or CLI
# Tag: Environment=production, Name=pgworld-prod-api
# Use larger instance (t3.small or t3.medium)
```

#### Step 3: Store Secrets in AWS Systems Manager Parameter Store

**For Pre-Production:**

```bash
# Database connection
aws ssm put-parameter \
    --name "/pgworld/preprod/dbConfig" \
    --value "admin:PASSWORD@tcp(pgworld-preprod-db.xxx.rds.amazonaws.com:3306)/pgworld_db" \
    --type "SecureString" \
    --overwrite

# Base URL
aws ssm put-parameter \
    --name "/pgworld/preprod/baseURL" \
    --value "https://api-preprod.pgworld.com" \
    --type "String" \
    --overwrite

# Email configuration
aws ssm put-parameter \
    --name "/pgworld/preprod/supportEmailID" \
    --value "preprod@pgworld.com" \
    --type "String" \
    --overwrite

aws ssm put-parameter \
    --name "/pgworld/preprod/supportEmailPassword" \
    --value "PREPROD_EMAIL_PASSWORD" \
    --type "SecureString" \
    --overwrite

# API Keys
aws ssm put-parameter \
    --name "/pgworld/preprod/androidLiveKey" \
    --value "PREPROD_ANDROID_LIVE_KEY_32_CHARS" \
    --type "SecureString" \
    --overwrite

aws ssm put-parameter \
    --name "/pgworld/preprod/androidTestKey" \
    --value "PREPROD_ANDROID_TEST_KEY_32_CHARS" \
    --type "SecureString" \
    --overwrite

aws ssm put-parameter \
    --name "/pgworld/preprod/iOSLiveKey" \
    --value "PREPROD_IOS_LIVE_KEY_32_CHARS" \
    --type "SecureString" \
    --overwrite

aws ssm put-parameter \
    --name "/pgworld/preprod/iOSTestKey" \
    --value "PREPROD_IOS_TEST_KEY_32_CHARS" \
    --type "SecureString" \
    --overwrite

# Razorpay
aws ssm put-parameter \
    --name "/pgworld/preprod/razorpayKeyID" \
    --value "PREPROD_RAZORPAY_KEY" \
    --type "SecureString" \
    --overwrite

aws ssm put-parameter \
    --name "/pgworld/preprod/razorpayKeySecret" \
    --value "PREPROD_RAZORPAY_SECRET" \
    --type "SecureString" \
    --overwrite

# S3 Bucket
aws ssm put-parameter \
    --name "/pgworld/preprod/s3Bucket" \
    --value "pgworld-preprod-uploads" \
    --type "String" \
    --overwrite
```

**Repeat for Production** (change `/preprod/` to `/production/` and use production values)

---

### PHASE 3: Set Up CI/CD Pipeline (1 hour)

#### Step 1: Create IAM Roles

**1.1 CodeBuild Service Role:**

Create policy `CodeBuildPGWorldPolicy.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": "arn:aws:s3:::pgworld-codepipeline-artifacts/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ssm:GetParameters",
        "ssm:GetParameter",
        "ssm:GetParametersByPath"
      ],
      "Resource": "arn:aws:ssm:us-east-1:*:parameter/pgworld/*"
    }
  ]
}
```

Create role:
```bash
aws iam create-role \
    --role-name CodeBuildPGWorldRole \
    --assume-role-policy-document file://trust-policy.json

aws iam put-role-policy \
    --role-name CodeBuildPGWorldRole \
    --policy-name CodeBuildPGWorldPolicy \
    --policy-document file://CodeBuildPGWorldPolicy.json
```

#### Step 2: Create CodeBuild Projects

**2.1 Pre-Production Build Project:**

```bash
aws codebuild create-project \
    --name pgworld-preprod-build \
    --source type=GITHUB,location=https://github.com/YOUR_USERNAME/pgworld.git \
    --artifacts type=S3,location=pgworld-codepipeline-artifacts \
    --environment type=LINUX_CONTAINER,image=aws/codebuild/standard:5.0,computeType=BUILD_GENERAL1_SMALL \
    --environment-variables name=ENVIRONMENT,value=preprod \
    --service-role arn:aws:iam::ACCOUNT_ID:role/CodeBuildPGWorldRole
```

**2.2 Production Build Project:**

```bash
aws codebuild create-project \
    --name pgworld-production-build \
    --source type=GITHUB,location=https://github.com/YOUR_USERNAME/pgworld.git \
    --artifacts type=S3,location=pgworld-codepipeline-artifacts \
    --environment type=LINUX_CONTAINER,image=aws/codebuild/standard:5.0,computeType=BUILD_GENERAL1_SMALL \
    --environment-variables name=ENVIRONMENT,value=production \
    --service-role arn:aws:iam::ACCOUNT_ID:role/CodeBuildPGWorldRole
```

#### Step 3: Create CodeDeploy Applications

```bash
# Pre-Production
aws deploy create-application \
    --application-name pgworld-preprod \
    --compute-platform Server

# Production
aws deploy create-application \
    --application-name pgworld-production \
    --compute-platform Server
```

#### Step 4: Create CodePipeline

Create `pipeline-preprod.json`:

```json
{
  "pipeline": {
    "name": "pgworld-preprod-pipeline",
    "roleArn": "arn:aws:iam::ACCOUNT_ID:role/CodePipelineServiceRole",
    "artifactStore": {
      "type": "S3",
      "location": "pgworld-codepipeline-artifacts"
    },
    "stages": [
      {
        "name": "Source",
        "actions": [
          {
            "name": "Source",
            "actionTypeId": {
              "category": "Source",
              "owner": "ThirdParty",
              "provider": "GitHub",
              "version": "1"
            },
            "configuration": {
              "Owner": "YOUR_GITHUB_USERNAME",
              "Repo": "pgworld",
              "Branch": "develop",
              "OAuthToken": "YOUR_GITHUB_TOKEN"
            },
            "outputArtifacts": [
              {
                "name": "SourceOutput"
              }
            ]
          }
        ]
      },
      {
        "name": "Build",
        "actions": [
          {
            "name": "Build",
            "actionTypeId": {
              "category": "Build",
              "owner": "AWS",
              "provider": "CodeBuild",
              "version": "1"
            },
            "configuration": {
              "ProjectName": "pgworld-preprod-build"
            },
            "inputArtifacts": [
              {
                "name": "SourceOutput"
              }
            ],
            "outputArtifacts": [
              {
                "name": "BuildOutput"
              }
            ]
          }
        ]
      },
      {
        "name": "Deploy",
        "actions": [
          {
            "name": "Deploy",
            "actionTypeId": {
              "category": "Deploy",
              "owner": "AWS",
              "provider": "CodeDeploy",
              "version": "1"
            },
            "configuration": {
              "ApplicationName": "pgworld-preprod",
              "DeploymentGroupName": "pgworld-preprod-group"
            },
            "inputArtifacts": [
              {
                "name": "BuildOutput"
              }
            ]
          }
        ]
      }
    ]
  }
}
```

Create pipeline:
```bash
aws codepipeline create-pipeline --cli-input-json file://pipeline-preprod.json
```

**Repeat for Production** with manual approval stage:

Create `pipeline-production.json` (add approval stage between Build and Deploy):

```json
{
  "name": "ManualApproval",
  "actions": [
    {
      "name": "ManualApprovalAction",
      "actionTypeId": {
        "category": "Approval",
        "owner": "AWS",
        "provider": "Manual",
        "version": "1"
      },
      "configuration": {
        "CustomData": "Please review and approve deployment to production"
      }
    }
  ]
}
```

---

### PHASE 4: Configure EC2 Instances (30 minutes per instance)

SSH into each EC2 instance and set up CodeDeploy agent:

```bash
#!/bin/bash
# Run on each EC2 instance

# Install CodeDeploy agent
sudo yum update -y
sudo yum install -y ruby wget

cd /home/ec2-user
wget https://aws-codedeploy-us-east-1.s3.us-east-1.amazonaws.com/latest/install
chmod +x ./install
sudo ./install auto

# Verify installation
sudo service codedeploy-agent status

# Create application directory
sudo mkdir -p /opt/pgworld
sudo chown ec2-user:ec2-user /opt/pgworld

# Install Go
wget https://go.dev/dl/go1.21.5.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.21.5.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
source ~/.bashrc

# Create systemd service
sudo tee /etc/systemd/system/pgworld-api.service > /dev/null <<EOF
[Unit]
Description=PG World API
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/opt/pgworld
ExecStart=/opt/pgworld/pgworld-api
Restart=always
RestartSec=10
EnvironmentFile=/opt/pgworld/.env

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable pgworld-api
```

---

## 📊 WORKFLOW DIAGRAM

```
Developer
    ↓
  Commit to 'develop' branch
    ↓
GitHub → CodePipeline (Pre-Prod)
    ↓
CodeBuild
  - Download code
  - Load secrets from Parameter Store
  - Build Go application
  - Run tests
    ↓
CodeDeploy → Pre-Prod EC2
  - Deploy new version
  - Restart service
  - Health check
    ↓
✅ Pre-Prod Live!
    ↓
  Test in Pre-Prod
    ↓
  Merge 'develop' → 'main'
    ↓
GitHub → CodePipeline (Production)
    ↓
CodeBuild (same process)
    ↓
⏸️  Manual Approval Required
    ↓
  [Approve Deployment]
    ↓
CodeDeploy → Production EC2
    ↓
✅ Production Live!
```

---

## 🎯 BRANCH STRATEGY

```
main (production)
  ├─ Stable, production-ready code
  ├─ Protected branch (requires PR approval)
  └─ Auto-deploys to production (with approval)

develop (pre-production)
  ├─ Integration branch
  ├─ Auto-deploys to pre-prod
  └─ Merge to main when stable

feature/* (local development)
  ├─ Feature branches
  └─ Merge to develop via PR
```

---

## ✅ DEPLOYMENT CHECKLIST

### Initial Setup (One-Time)

- [ ] Create GitHub repository and push code
- [ ] Set up AWS account and configure CLI
- [ ] Create Pre-Prod infrastructure (RDS, EC2, S3)
- [ ] Create Production infrastructure (RDS, EC2, S3)
- [ ] Store all secrets in Parameter Store
- [ ] Create IAM roles for CodeBuild/CodeDeploy/CodePipeline
- [ ] Create CodeBuild projects (preprod & production)
- [ ] Create CodeDeploy applications (preprod & production)
- [ ] Create CodePipeline pipelines (preprod & production)
- [ ] Configure EC2 instances with CodeDeploy agent
- [ ] Set up DNS (api-preprod.pgworld.com, api.pgworld.com)
- [ ] Request SSL certificates
- [ ] Configure systemd services on EC2
- [ ] Import database schema to both environments

### Every Deployment

**To Pre-Production:**
- [ ] Create feature branch
- [ ] Make changes
- [ ] Test locally
- [ ] Push to `develop` branch
- [ ] Pipeline auto-runs
- [ ] Verify pre-prod deployment
- [ ] Test on pre-prod

**To Production:**
- [ ] Verify pre-prod is stable
- [ ] Create PR: `develop` → `main`
- [ ] Get approval
- [ ] Merge to `main`
- [ ] Pipeline auto-runs (build stage)
- [ ] Receive approval notification
- [ ] Review changes
- [ ] Approve deployment
- [ ] Verify production deployment
- [ ] Monitor logs and metrics

---

## 💰 COST ESTIMATE

### Pre-Production Environment
- RDS db.t3.micro: $15/month
- EC2 t3.micro: $8/month
- S3: $2/month
- **Total: ~$25/month**

### Production Environment
- RDS db.t3.small (Multi-AZ): $60/month
- EC2 t3.small: $15/month
- S3: $5/month
- Load Balancer: $16/month
- **Total: ~$96/month**

### CI/CD Services
- CodePipeline: $1/pipeline/month = $2/month
- CodeBuild: Free tier (100 min/month), then $0.005/min
- CodeDeploy: Free
- **Total: ~$2-10/month**

**Grand Total: ~$123-131/month**

---

## 🚀 QUICK START SCRIPT

I'll create an automated setup script for you. Would you like me to create:

1. **`setup-aws-pipeline.ps1`** - PowerShell script to set up everything
2. **`appspec.yml`** - CodeDeploy application specification
3. **GitHub Actions workflow** (alternative to CodePipeline)

Let me know and I'll create these files!

---

## 📞 NEXT STEPS

1. **Review this document completely**
2. **Decide**: CodePipeline (AWS-native) or GitHub Actions (easier)?
3. **Run cleanup script**: `.\cleanup-for-production.ps1`
4. **Choose setup method** and I'll guide you through it

**Ready to set up the pipeline?** Let me know your preference!

