# ✅ PGNi Deployment Validation Checklist

## 🎯 Current Status: Infrastructure Ready, API Deployment Pending

---

## ✅ Completed Items

### 1. AWS Infrastructure (36 Resources)
- [x] **EC2 Instance:** `i-0909d462845deb151` running at `34.227.111.143`
- [x] **RDS Database:** `database-pgni` (MySQL 8.0) at `database-pgni.cezawkgguojl.us-east-1.rds.amazonaws.com`
- [x] **S3 Bucket:** `pgni-preprod-698302425856-uploads`
- [x] **Security Groups:** EC2 and RDS security groups configured
- [x] **IAM Roles:** EC2 instance role with S3 and Systems Manager access
- [x] **SSH Key Pair:** Generated and saved (`pgni-preprod-key.pem`)
- [x] **SSM Parameters:** Database credentials stored securely

### 2. Configuration Files
- [x] **preprod.env:** Environment variables configured
- [x] **deploy-api.sh:** Deployment script ready
- [x] **Terraform:** Infrastructure as Code applied successfully

### 3. Source Code
- [x] **API:** `pgworld-api-master` ready to deploy
- [x] **Admin App:** `pgworld-master` ready to build
- [x] **Tenant App:** `pgworldtenant-master` ready to build

### 4. Documentation
- [x] Pre-deployment checklist
- [x] Deployment success report
- [x] Infrastructure documentation
- [x] Manual deployment guides

---

## ⏳ Pending Items

### 1. API Deployment (Required)
- [ ] Upload API code to EC2
- [ ] Build Go application
- [ ] Configure systemd service
- [ ] Start API service
- [ ] Verify API health endpoint

### 2. Database Setup (Required)
- [ ] Connect to RDS database
- [ ] Create `pgworld` database
- [ ] Run database migrations (if any)
- [ ] Verify database connectivity from API

### 3. Validation Testing (Required)
- [ ] Test API health endpoint: `http://34.227.111.143:8080/health`
- [ ] Test database queries
- [ ] Test S3 file upload
- [ ] Test API authentication
- [ ] Verify all API endpoints

### 4. Mobile Apps (Required)
- [ ] Update API endpoint URL in Admin app
- [ ] Update API endpoint URL in Tenant app
- [ ] Build Android APKs
- [ ] Test apps with deployed API

### 5. CI/CD Pipeline (Optional but Recommended)
- [ ] Configure GitHub repository secrets
- [ ] Test GitHub Actions workflow
- [ ] Verify automated deployments

---

## 🔍 Detailed Validation Steps

### Phase 1: API Deployment

#### Method A: Using AWS CloudShell (Recommended)
See: `DEPLOY_VIA_CLOUDSHELL.md`

#### Method B: Using PuTTY/WinSCP (Windows)
See: `DEPLOY_MANUAL_STEPS.md`

#### Method C: Using WSL
See: `DEPLOY_MANUAL_STEPS.md`

---

### Phase 2: Health Check

```bash
# Test from anywhere
curl http://34.227.111.143:8080/health

# Expected response:
{"status":"healthy"}
# or
{"status":"ok"}
```

**Success Criteria:**
- ✅ Returns 200 OK status
- ✅ Returns JSON response
- ✅ No connection errors

---

### Phase 3: Database Validation

```bash
# Connect to RDS
mysql -h database-pgni.cezawkgguojl.us-east-1.rds.amazonaws.com -u admin -p
# Password: Omsairamdb951#

# Check databases
SHOW DATABASES;

# Create pgworld database if not exists
CREATE DATABASE IF NOT EXISTS pgworld CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

# Use database
USE pgworld;

# Check tables (after API first run)
SHOW TABLES;
```

**Success Criteria:**
- ✅ Can connect to RDS
- ✅ `pgworld` database exists
- ✅ Tables are created (by API on first run)

---

### Phase 4: S3 Validation

```bash
# Check S3 bucket access
aws s3 ls s3://pgni-preprod-698302425856-uploads/

# Test file upload (from EC2)
echo "test" > test.txt
aws s3 cp test.txt s3://pgni-preprod-698302425856-uploads/test/
aws s3 rm s3://pgni-preprod-698302425856-uploads/test/test.txt
```

**Success Criteria:**
- ✅ Can list bucket contents
- ✅ Can upload files
- ✅ Can delete files

---

### Phase 5: API Endpoint Testing

Test all critical endpoints:

```bash
# Health check
curl http://34.227.111.143:8080/health

# Version info (if available)
curl http://34.227.111.143:8080/version

# Login endpoint test
curl -X POST http://34.227.111.143:8080/api/login \
  -H "Content-Type: application/json" \
  -d '{"username":"test","password":"test"}'

# Add more endpoint tests based on your API
```

**Success Criteria:**
- ✅ All endpoints respond
- ✅ Proper error handling
- ✅ Correct response formats

---

### Phase 6: Security Validation

```bash
# Check EC2 security group
aws ec2 describe-security-groups --group-ids sg-xxxxxxxxx

# Check RDS security group
aws ec2 describe-security-groups --group-ids sg-yyyyyyyyy

# Verify IAM role
aws iam get-role --role-name pgni-preprod-ec2-role
```

**Verify:**
- ✅ Port 8080 open for API
- ✅ Port 3306 restricted to EC2 security group
- ✅ IAM role has necessary permissions

---

### Phase 7: Service Monitoring

```bash
# On EC2 instance:

# Check service status
sudo systemctl status pgworld-api

# View live logs
sudo journalctl -u pgworld-api -f

# View recent logs
sudo journalctl -u pgworld-api -n 100

# Check for errors
sudo journalctl -u pgworld-api | grep -i error
```

**Success Criteria:**
- ✅ Service is active (running)
- ✅ No critical errors in logs
- ✅ Service restarts automatically on failure

---

### Phase 8: Load Testing (Optional)

```bash
# Simple load test
for i in {1..100}; do
  curl -s http://34.227.111.143:8080/health > /dev/null &
done
wait

# Check API is still responsive
curl http://34.227.111.143:8080/health
```

---

## 📊 Infrastructure Cost Validation

### Current Monthly Cost Estimate: ~$15/month

**Breakdown:**
- EC2 t2.micro (750h free tier): $0 (or $8.50)
- RDS db.t3.micro: ~$14.02
- S3 Standard Storage: ~$0.50
- Data Transfer: ~$0.50
- **Total:** ~$15-23/month

**Verify:**
- [ ] Check AWS Billing Dashboard
- [ ] Set up billing alerts
- [ ] Review cost allocation tags

---

## 🚨 Troubleshooting Guide

### Issue: API Health Check Fails

**Possible Causes:**
1. Service not running
2. Port 8080 not listening
3. Security group blocking traffic
4. Application error

**Debug Steps:**
```bash
# Check service
sudo systemctl status pgworld-api

# Check port
sudo netstat -tlnp | grep 8080

# Check logs
sudo journalctl -u pgworld-api -n 50

# Try manual start
cd /opt/pgworld
./pgworld-api
```

---

### Issue: Database Connection Failed

**Possible Causes:**
1. Wrong credentials
2. Security group rules
3. Database not created
4. Network issue

**Debug Steps:**
```bash
# Test from EC2
mysql -h database-pgni.cezawkgguojl.us-east-1.rds.amazonaws.com -u admin -p

# Check security groups
aws ec2 describe-security-groups --filters "Name=group-name,Values=pgni-preprod-rds-sg"

# Check RDS status
aws rds describe-db-instances --db-instance-identifier database-pgni
```

---

### Issue: S3 Upload Failed

**Possible Causes:**
1. IAM permissions
2. Bucket policy
3. Wrong bucket name
4. Region mismatch

**Debug Steps:**
```bash
# Check IAM role
aws sts get-caller-identity

# Test S3 access
aws s3 ls s3://pgni-preprod-698302425856-uploads/

# Check bucket policy
aws s3api get-bucket-policy --bucket pgni-preprod-698302425856-uploads
```

---

## ✅ Sign-Off Checklist

### Infrastructure
- [ ] All AWS resources created and running
- [ ] Security groups properly configured
- [ ] IAM roles and permissions verified
- [ ] Backup strategy in place

### Application
- [ ] API deployed and running
- [ ] Health endpoint responding
- [ ] Database connected and initialized
- [ ] S3 uploads working

### Testing
- [ ] All API endpoints tested
- [ ] Mobile apps tested with live API
- [ ] Error handling verified
- [ ] Load testing completed (optional)

### Documentation
- [ ] Deployment guide reviewed
- [ ] Credentials documented securely
- [ ] Runbook created for operations
- [ ] Disaster recovery plan documented

### Security
- [ ] Secrets not in source control
- [ ] HTTPS/TLS configured (future)
- [ ] Database backups enabled
- [ ] Monitoring and alerts configured

### CI/CD
- [ ] GitHub Actions configured
- [ ] Automated deployments tested
- [ ] Rollback procedure tested

---

## 🎯 Success Criteria Summary

**Infrastructure:** ✅ COMPLETE  
**API Deployment:** ⏳ PENDING  
**Database Setup:** ⏳ PENDING  
**Validation:** ⏳ PENDING  
**Mobile Apps:** ⏳ PENDING  
**CI/CD:** ⏳ OPTIONAL  

---

## 📞 Quick Reference

**EC2 IP:** `34.227.111.143`  
**Instance ID:** `i-0909d462845deb151`  
**API URL:** `http://34.227.111.143:8080`  
**Health Check:** `http://34.227.111.143:8080/health`  

**RDS Endpoint:** `database-pgni.cezawkgguojl.us-east-1.rds.amazonaws.com:3306`  
**Database:** `pgworld`  
**Username:** `admin`  
**Password:** `Omsairamdb951#`  

**S3 Bucket:** `pgni-preprod-698302425856-uploads`  
**Region:** `us-east-1`  

**SSH Key:** `pgni-preprod-key.pem`  
**Environment File:** `preprod.env`  

---

## 🚀 Next Steps

1. **Deploy API** using one of these methods:
   - AWS CloudShell (`DEPLOY_VIA_CLOUDSHELL.md`)
   - PuTTY + WinSCP (`DEPLOY_MANUAL_STEPS.md`)
   - WSL (`DEPLOY_MANUAL_STEPS.md`)

2. **Validate** using this checklist

3. **Update Mobile Apps** with new API endpoint

4. **Test End-to-End** functionality

5. **Configure CI/CD** for automated future deployments

---

**Ready to proceed with deployment!** 🎉

