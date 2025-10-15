# Post-Deployment Validation Checklist

## Overview
This checklist ensures all components of the PGNi application are properly deployed and functioning.

**Complete this checklist after running `COMPLETE_ENTERPRISE_DEPLOYMENT.sh`**

---

## ✅ Phase 1: Infrastructure Validation

### EC2 Instance
- [ ] EC2 instance is running
- [ ] Disk space is 100GB
- [ ] SSH access works
- [ ] Security groups allow ports 22, 80, 8080

**Validation Command:**
```bash
aws ec2 describe-instances --instance-ids i-0b5f620584d1e4ee9 --region us-east-1 --query 'Reservations[0].Instances[0].[State.Name,InstanceType,BlockDeviceMappings[0].Ebs.VolumeId]'

# SSH test
ssh -i cloudshell-key.pem ec2-user@34.227.111.143 "df -h | grep xvda"
```

**Expected Result:**
```
running
t3.medium (or larger)
vol-xxxxxxxxx

Filesystem      Size  Used Avail Use% Mounted on
/dev/xvda1       99G   25G   75G  25% /
```

---

### RDS Database
- [ ] RDS instance is available
- [ ] Database `pgworld` exists
- [ ] Tables are created
- [ ] Test data is loaded

**Validation Command:**
```bash
ssh -i cloudshell-key.pem ec2-user@34.227.111.143 << 'EOF'
mysql -h database-pgni.cezawkgguojl.us-east-1.rds.amazonaws.com \
  -u admin -pOmsairamdb951# \
  -e "USE pgworld; SHOW TABLES; SELECT COUNT(*) as user_count FROM users;"
EOF
```

**Expected Result:**
```
+--------------------+
| Tables_in_pgworld  |
+--------------------+
| payments           |
| pg_properties      |
| rooms              |
| tenants            |
| users              |
+--------------------+

+------------+
| user_count |
+------------+
|          3 |
+------------+
```

---

### S3 Bucket
- [ ] S3 bucket exists
- [ ] Bucket is accessible from EC2
- [ ] IAM role allows uploads

**Validation Command:**
```bash
aws s3 ls s3://pgni-preprod-698302425856-uploads/
```

**Expected Result:**
```
(bucket may be empty initially - that's OK)
```

---

## ✅ Phase 2: Application Services

### Backend API (Go)
- [ ] API service is running
- [ ] API responds to health checks
- [ ] API connects to database
- [ ] API logs are clean

**Validation Command:**
```bash
# Health check
curl http://34.227.111.143:8080/health

# Service status
ssh -i cloudshell-key.pem ec2-user@34.227.111.143 "sudo systemctl status pgworld-api"

# Check logs
ssh -i cloudshell-key.pem ec2-user@34.227.111.143 "sudo journalctl -u pgworld-api -n 20 --no-pager"
```

**Expected Result:**
```
{"status":"ok","timestamp":"2024-10-15T..."}

● pgworld-api.service - PGNi API Server
   Loaded: loaded (/etc/systemd/system/pgworld-api.service; enabled)
   Active: active (running) since ...
   
[No ERROR messages in logs]
```

---

### Nginx Web Server
- [ ] Nginx service is running
- [ ] Nginx configuration is valid
- [ ] Port 80 is accessible
- [ ] CORS headers are configured

**Validation Command:**
```bash
# Service status
ssh -i cloudshell-key.pem ec2-user@34.227.111.143 "sudo systemctl status nginx"

# Test configuration
ssh -i cloudshell-key.pem ec2-user@34.227.111.143 "sudo nginx -t"

# Check CORS headers
curl -I http://34.227.111.143/admin/ | grep -i "access-control"
```

**Expected Result:**
```
● nginx.service - The nginx HTTP and reverse proxy server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; enabled)
   Active: active (running) since ...

nginx: configuration file /etc/nginx/nginx.conf test is successful

Access-Control-Allow-Origin: *
Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS
```

---

## ✅ Phase 3: Frontend Applications

### Admin Portal (Flutter Web)
- [ ] Admin portal is accessible
- [ ] Login page loads correctly
- [ ] Can login with test credentials
- [ ] Dashboard loads after login
- [ ] All menu items are accessible

**Validation Steps:**

1. **Access Admin Portal:**
   - Open browser: http://34.227.111.143/admin/
   - Should see PGNi Admin login page

2. **Test Login:**
   - Email: `admin@pgworld.com`
   - Password: `Admin@123`
   - Click "Login"
   - Should redirect to dashboard

3. **Navigate Menu:**
   - [ ] Dashboard page loads
   - [ ] Users section accessible
   - [ ] Properties section accessible
   - [ ] Tenants section accessible
   - [ ] Payments section accessible
   - [ ] Reports section accessible

**Validation Command:**
```bash
# Check if files exist
ssh -i cloudshell-key.pem ec2-user@34.227.111.143 "ls -lh /usr/share/nginx/html/admin/ | head -10"

# Test HTTP response
curl -I http://34.227.111.143/admin/
```

**Expected Result:**
```
HTTP/1.1 200 OK
Content-Type: text/html
...
```

---

### Tenant Portal (Flutter Web)
- [ ] Tenant portal is accessible
- [ ] Login page loads correctly
- [ ] Can login with test credentials
- [ ] Dashboard loads after login
- [ ] All features are accessible

**Validation Steps:**

1. **Access Tenant Portal:**
   - Open browser: http://34.227.111.143/tenant/
   - Should see PGNi Tenant login page

2. **Test Login:**
   - Email: `tenant@pg.com`
   - Password: `Tenant@123`
   - Click "Login"
   - Should redirect to dashboard

3. **Navigate Menu:**
   - [ ] Dashboard page loads
   - [ ] Profile section accessible
   - [ ] Payments section accessible
   - [ ] Complaints section accessible
   - [ ] Notices section accessible

**Validation Command:**
```bash
# Check if files exist
ssh -i cloudshell-key.pem ec2-user@34.227.111.143 "ls -lh /usr/share/nginx/html/tenant/ | head -10"

# Test HTTP response
curl -I http://34.227.111.143/tenant/
```

**Expected Result:**
```
HTTP/1.1 200 OK
Content-Type: text/html
...
```

---

## ✅ Phase 4: API Endpoint Testing

### Authentication Endpoints
- [ ] Login endpoint works
- [ ] Logout endpoint works
- [ ] Token validation works

**Validation Command:**
```bash
# Test login
curl -X POST http://34.227.111.143:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@pgworld.com","password":"Admin@123"}'
```

**Expected Result:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": 1,
    "email": "admin@pgworld.com",
    "role": "admin"
  }
}
```

---

### User Management Endpoints
- [ ] Get users list
- [ ] Create user
- [ ] Update user
- [ ] Delete user

**Validation Command:**
```bash
# Get JWT token first
TOKEN=$(curl -s -X POST http://34.227.111.143:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@pgworld.com","password":"Admin@123"}' | jq -r '.token')

# Test get users
curl -X GET http://34.227.111.143:8080/api/users \
  -H "Authorization: Bearer $TOKEN"
```

**Expected Result:**
```json
[
  {
    "id": 1,
    "email": "admin@pgworld.com",
    "role": "admin",
    "username": "admin"
  },
  ...
]
```

---

### Property Management Endpoints
- [ ] Get properties list
- [ ] Create property
- [ ] Update property
- [ ] Delete property

**Validation Command:**
```bash
# Get properties
curl -X GET http://34.227.111.143:8080/api/properties \
  -H "Authorization: Bearer $TOKEN"
```

---

## ✅ Phase 5: End-to-End User Workflows

### Workflow 1: Admin Creates PG Owner
1. [ ] Login as admin@pgworld.com
2. [ ] Navigate to Users
3. [ ] Click "Add New User"
4. [ ] Fill details (role: pg_owner)
5. [ ] Submit
6. [ ] Verify user appears in list

---

### Workflow 2: PG Owner Creates Property
1. [ ] Login as owner@pg.com
2. [ ] Navigate to Properties
3. [ ] Click "Add New Property"
4. [ ] Fill property details
5. [ ] Submit
6. [ ] Verify property appears in list

---

### Workflow 3: PG Owner Adds Room
1. [ ] Login as owner@pg.com
2. [ ] Select a property
3. [ ] Click "Add Room"
4. [ ] Fill room details
5. [ ] Submit
6. [ ] Verify room appears in property

---

### Workflow 4: PG Owner Adds Tenant
1. [ ] Login as owner@pg.com
2. [ ] Navigate to Tenants
3. [ ] Click "Add New Tenant"
4. [ ] Fill tenant details
5. [ ] Assign to room
6. [ ] Submit
7. [ ] Verify tenant appears in list

---

### Workflow 5: Tenant Views Profile
1. [ ] Login as tenant@pg.com
2. [ ] Navigate to Profile
3. [ ] Verify personal information
4. [ ] Verify room assignment
5. [ ] Verify payment history

---

### Workflow 6: Tenant Makes Payment Request
1. [ ] Login as tenant@pg.com
2. [ ] Navigate to Payments
3. [ ] Click "Make Payment"
4. [ ] Enter amount
5. [ ] Submit
6. [ ] Verify payment status

---

## ✅ Phase 6: Performance & Security

### Performance Checks
- [ ] Page load time < 3 seconds
- [ ] API response time < 500ms
- [ ] No console errors in browser
- [ ] Images load correctly
- [ ] Forms submit without delay

**Validation:**
1. Open browser developer tools (F12)
2. Check Network tab for response times
3. Check Console tab for errors

---

### Security Checks
- [ ] Cannot access admin features as tenant
- [ ] Cannot access without authentication
- [ ] JWT token expires after timeout
- [ ] Password fields are masked
- [ ] SQL injection attempts are blocked

**Validation Command:**
```bash
# Test unauthorized access
curl -X GET http://34.227.111.143:8080/api/users
# Should return 401 Unauthorized

# Test with invalid token
curl -X GET http://34.227.111.143:8080/api/users \
  -H "Authorization: Bearer invalid_token"
# Should return 401 Unauthorized
```

---

## ✅ Phase 7: Browser Compatibility

### Desktop Browsers
- [ ] Chrome (latest)
- [ ] Firefox (latest)
- [ ] Edge (latest)
- [ ] Safari (latest)

### Mobile Browsers
- [ ] Chrome Mobile (Android)
- [ ] Safari Mobile (iOS)

**Validation:**
Test login and basic navigation in each browser.

---

## ✅ Phase 8: Error Handling

### Network Errors
- [ ] API timeout shows user-friendly error
- [ ] Network disconnection shows error message
- [ ] Failed requests can be retried

### Validation Errors
- [ ] Empty form fields show validation errors
- [ ] Invalid email format is caught
- [ ] Duplicate entries are prevented

### Server Errors
- [ ] 500 errors show user-friendly message
- [ ] 404 errors show "not found" page
- [ ] Errors are logged for debugging

---

## ✅ Phase 9: Data Integrity

### Database Checks
- [ ] Foreign key constraints work
- [ ] Cascade deletes work correctly
- [ ] Data types are correct
- [ ] Indexes are created

**Validation Command:**
```bash
ssh -i cloudshell-key.pem ec2-user@34.227.111.143 << 'EOF'
mysql -h database-pgni.cezawkgguojl.us-east-1.rds.amazonaws.com \
  -u admin -pOmsairamdb951# pgworld \
  -e "SHOW CREATE TABLE users\G"
EOF
```

---

### File Upload Checks
- [ ] Can upload profile image
- [ ] Can upload documents
- [ ] File size limits work
- [ ] File type validation works
- [ ] Files are stored in S3

---

## ✅ Phase 10: Monitoring & Logging

### Application Logs
- [ ] API logs are readable
- [ ] Nginx access logs are working
- [ ] Nginx error logs are clean
- [ ] No critical errors in logs

**Validation Command:**
```bash
ssh -i cloudshell-key.pem ec2-user@34.227.111.143 << 'EOF'
echo "=== API Logs ==="
sudo journalctl -u pgworld-api -n 20 --no-pager

echo ""
echo "=== Nginx Access Log ==="
sudo tail -20 /var/log/nginx/access.log

echo ""
echo "=== Nginx Error Log ==="
sudo tail -20 /var/log/nginx/error.log
EOF
```

---

### System Monitoring
- [ ] CPU usage is normal (<80%)
- [ ] Memory usage is normal (<80%)
- [ ] Disk usage is normal (<80%)
- [ ] No zombie processes

**Validation Command:**
```bash
ssh -i cloudshell-key.pem ec2-user@34.227.111.143 << 'EOF'
echo "=== CPU & Memory ==="
top -bn1 | head -20

echo ""
echo "=== Disk Usage ==="
df -h

echo ""
echo "=== Process Status ==="
ps aux | grep -E "pgworld|nginx" | grep -v grep
EOF
```

---

## ✅ Summary Report

After completing all checks, fill this summary:

### Overall Status
- [ ] **PASS** - All checks passed, application is production-ready
- [ ] **PARTIAL** - Most checks passed, minor issues need fixing
- [ ] **FAIL** - Critical issues found, deployment needs troubleshooting

### Component Status
| Component | Status | Notes |
|-----------|--------|-------|
| EC2 Instance | ☐ Pass ☐ Fail | |
| RDS Database | ☐ Pass ☐ Fail | |
| S3 Bucket | ☐ Pass ☐ Fail | |
| Backend API | ☐ Pass ☐ Fail | |
| Nginx | ☐ Pass ☐ Fail | |
| Admin Portal | ☐ Pass ☐ Fail | |
| Tenant Portal | ☐ Pass ☐ Fail | |

### Issues Found
(List any issues discovered during validation)

1. Issue: _______________________
   Severity: ☐ Critical ☐ High ☐ Medium ☐ Low
   Status: ☐ Fixed ☐ In Progress ☐ Open

2. Issue: _______________________
   Severity: ☐ Critical ☐ High ☐ Medium ☐ Low
   Status: ☐ Fixed ☐ In Progress ☐ Open

---

## Next Steps

### If All Checks Pass ✅
1. Set up automated backups (see DEPLOYMENT_GUIDE.md)
2. Configure monitoring and alerts
3. Set up custom domain and HTTPS
4. Build mobile apps for Android/iOS
5. Begin user acceptance testing (UAT)

### If Issues Found ❌
1. Review DEPLOYMENT_GUIDE.md troubleshooting section
2. Check relevant logs for errors
3. Fix issues and re-run affected checks
4. Document resolution for future reference

---

**Validation Completed By:** _______________________  
**Date:** _______________________  
**Overall Result:** ☐ PASS ☐ PARTIAL ☐ FAIL

