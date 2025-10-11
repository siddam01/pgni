# 🎯 PGNi Application - Complete Setup Guide

## 🚨 CURRENT STATUS

### **Your Application URLs:**
```
http://34.227.111.143:8080 → ❌ NOT YET ACCESSIBLE
```

**Reason:** API not deployed to EC2 server yet

**Solution:** Run the deployment script below (5 minutes)

---

## ✅ WHAT'S READY

| Component | Status |
|-----------|--------|
| AWS Infrastructure | ✅ **READY** |
| EC2 Instance | ✅ **RUNNING** |
| RDS Database | ✅ **RUNNING** |
| S3 Bucket | ✅ **CREATED** |
| Security Groups | ✅ **CONFIGURED** |
| GitHub Repository | ✅ **PUBLIC & ACCESSIBLE** |
| CI/CD Pipelines | ✅ **WORKING** (build only) |
| Documentation | ✅ **COMPLETE** |
| **API Deployment** | ❌ **PENDING** |

---

## 🚀 DEPLOY NOW (5 MINUTES)

### **Option 1: Automated Deployment via CloudShell** ⭐ **RECOMMENDED**

This script will automatically:
- ✅ Validate infrastructure
- ✅ Install prerequisites
- ✅ Deploy API
- ✅ Initialize database
- ✅ Perform health checks
- ✅ Generate complete report

**Steps:**

1. **Open AWS CloudShell:**
   ```
   https://console.aws.amazon.com/cloudshell/
   ```

2. **Copy the deployment script:**
   ```bash
   curl -O https://raw.githubusercontent.com/siddam01/pgni/main/COMPLETE_DEPLOYMENT_SOLUTION.sh
   chmod +x COMPLETE_DEPLOYMENT_SOLUTION.sh
   ```

3. **Run it:**
   ```bash
   ./COMPLETE_DEPLOYMENT_SOLUTION.sh
   ```

4. **Wait 5 minutes**

5. **Test:**
   ```bash
   curl http://34.227.111.143:8080/health
   ```
   
   Or open in browser:
   ```
   http://34.227.111.143:8080/health
   ```

**Expected Result:**
```json
{"status":"healthy","service":"PGWorld API"}
```

---

### **Option 2: Manual Deployment (if CloudShell has issues)**

See: `DEPLOY_API_NOW_COMPLETE.txt`

---

## 📊 INFRASTRUCTURE DETAILS

### **EC2 Instance:**
- **Public IP:** 34.227.111.143
- **Instance ID:** i-0909d462845deb151
- **Region:** us-east-1
- **AMI:** Amazon Linux 2023 (ECS Optimized)

### **RDS Database:**
- **Endpoint:** database-pgni.cezawkgguojl.us-east-1.rds.amazonaws.com
- **Database:** pgworld
- **Port:** 3306

### **S3 Bucket:**
- **Name:** pgni-preprod-698302425856-uploads
- **Region:** us-east-1

### **Security:**
- ✅ Port 22 (SSH) - Open
- ✅ Port 8080 (API) - Open
- ✅ Port 443 (HTTPS) - Open
- ✅ Port 3306 (MySQL) - EC2 only

---

## 📱 MOBILE APP CONFIGURATION

After API is deployed, update your mobile apps:

### **Flutter Configuration:**

**File:** `lib/config/api_config.dart`

```dart
class ApiConfig {
  static const String baseUrl = 'http://34.227.111.143:8080';
  
  // Endpoints
  static const String healthCheck = '$baseUrl/health';
  static const String apiV1 = '$baseUrl/api/v1';
  
  // Users
  static const String login = '$apiV1/auth/login';
  static const String register = '$apiV1/auth/register';
  
  // Properties
  static const String properties = '$apiV1/properties';
  static const String rooms = '$apiV1/rooms';
  static const String tenants = '$apiV1/tenants';
  static const String payments = '$apiV1/payments';
}
```

### **Android Manifest:**

**File:** `android/app/src/main/AndroidManifest.xml`

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    
    <!-- Add Internet Permission -->
    <uses-permission android:name="android.permission.INTERNET" />
    
    <application
        android:label="PGNi"
        android:usesCleartextTraffic="true"
        ...>
        ...
    </application>
</manifest>
```

### **Build APKs:**

```bash
# Admin App
cd pgworld-master
flutter clean
flutter pub get
flutter build apk --release

# Tenant App
cd pgworldtenant-master
flutter clean
flutter pub get
flutter build apk --release
```

**APK Locations:**
- Admin: `pgworld-master/build/app/outputs/flutter-apk/app-release.apk`
- Tenant: `pgworldtenant-master/build/app/outputs/flutter-apk/app-release.apk`

**Detailed Guide:** `URL_ACCESS_AND_MOBILE_CONFIG.md`

---

## 👥 USER GUIDES

Complete documentation for all user roles:

| Guide | Audience | File |
|-------|----------|------|
| Getting Started | All Users | `USER_GUIDES/0_GETTING_STARTED.md` |
| PG Owner Guide | Property Owners | `USER_GUIDES/1_PG_OWNER_GUIDE.md` |
| Tenant Guide | Tenants | `USER_GUIDES/2_TENANT_GUIDE.md` |
| Admin Guide | Administrators | `USER_GUIDES/3_ADMIN_GUIDE.md` |
| Mobile App Setup | Developers | `USER_GUIDES/4_MOBILE_APP_CONFIGURATION.md` |

---

## 🔄 CI/CD PIPELINE

### **Current Status:**

| Pipeline | Status | Details |
|----------|--------|---------|
| Build & Validation | ✅ Working | Runs on every push |
| Deployment | ⏸️ Manual | Requires GitHub Secrets |
| Parallel Validation | ✅ Working | 8 parallel checks |
| Monitoring | ✅ Working | Every 6 hours |

### **Pipeline Files:**
- Main Deploy: `.github/workflows/deploy.yml`
- Parallel Validation: `.github/workflows/parallel-validation.yml`

### **Enable Auto-Deployment:**

To make pushes automatically deploy to EC2:

1. Go to: https://github.com/siddam01/pgni/settings/secrets/actions

2. Add these secrets:

   | Secret Name | Value | How to Get |
   |-------------|-------|------------|
   | `PRODUCTION_HOST` | `34.227.111.143` | (your EC2 IP) |
   | `PRODUCTION_SSH_KEY` | `<SSH private key>` | `cd terraform && terraform output -raw ssh_private_key` |
   | `AWS_ACCESS_KEY_ID` | `<your access key>` | AWS Console → IAM → Security Credentials |
   | `AWS_SECRET_ACCESS_KEY` | `<your secret key>` | AWS Console → IAM → Security Credentials |

3. Push any change:
   ```bash
   git commit --allow-empty -m "Trigger deployment"
   git push origin main
   ```

**Documentation:** `GITHUB_SECRETS_SETUP.md`

---

## 🔍 VALIDATION & TESTING

### **After Deployment, Verify:**

1. **Health Check:**
   ```bash
   curl http://34.227.111.143:8080/health
   ```

2. **Service Status:**
   ```bash
   ssh -i key.pem ec2-user@34.227.111.143
   sudo systemctl status pgworld-api
   ```

3. **View Logs:**
   ```bash
   sudo journalctl -u pgworld-api -n 50
   ```

4. **Check Port:**
   ```bash
   sudo netstat -tlnp | grep 8080
   ```

### **API Endpoints:**

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/health` | GET | Health check |
| `/api/v1/auth/login` | POST | User login |
| `/api/v1/auth/register` | POST | User registration |
| `/api/v1/users` | GET | List users |
| `/api/v1/properties` | GET/POST | Properties CRUD |
| `/api/v1/rooms` | GET/POST | Rooms CRUD |
| `/api/v1/tenants` | GET/POST | Tenants CRUD |
| `/api/v1/payments` | GET/POST | Payments CRUD |

---

## 🛠️ TROUBLESHOOTING

### **URLs Not Accessible:**

**Problem:** `curl http://34.227.111.143:8080/health` → Connection refused

**Diagnosis:**
```bash
# 1. Check if service is running
ssh -i key.pem ec2-user@34.227.111.143
sudo systemctl status pgworld-api

# 2. Check logs
sudo journalctl -u pgworld-api -n 100

# 3. Check if port is listening
sudo netstat -tlnp | grep 8080
```

**Solution:**
```bash
# Restart service
sudo systemctl restart pgworld-api

# Watch logs
sudo journalctl -u pgworld-api -f
```

### **Service Won't Start:**

Check logs for errors:
```bash
sudo journalctl -u pgworld-api -n 100 --no-pager
```

Common issues:
- Missing Go binary → Reinstall Go
- Database connection failed → Check RDS credentials
- Port already in use → Kill existing process

### **Database Connection Issues:**

Test database connectivity:
```bash
mysql -h database-pgni.cezawkgguojl.us-east-1.rds.amazonaws.com \
      -u admin -p pgworld
```

---

## 📈 MONITORING & MAINTENANCE

### **Service Management:**

```bash
# Check status
sudo systemctl status pgworld-api

# Stop service
sudo systemctl stop pgworld-api

# Start service
sudo systemctl start pgworld-api

# Restart service
sudo systemctl restart pgworld-api

# Enable auto-start
sudo systemctl enable pgworld-api

# View logs (live)
sudo journalctl -u pgworld-api -f

# View last 100 lines
sudo journalctl -u pgworld-api -n 100
```

### **Application Logs:**

```bash
# Output logs
tail -f /opt/pgworld/logs/output.log

# Error logs
tail -f /opt/pgworld/logs/error.log
```

### **Regular Maintenance:**

- **Daily:** Check logs for errors
- **Weekly:** Monitor disk space, CPU, memory
- **Monthly:** Update system packages
- **Quarterly:** Review security, rotate credentials

---

## 🎯 DEPLOYMENT CHECKLIST

- [ ] **Infrastructure:** EC2, RDS, S3 ready
- [ ] **API Deployed:** Service running on EC2
- [ ] **Health Check:** Returns 200 OK
- [ ] **Database:** Schema created
- [ ] **Mobile Apps:** API URL updated
- [ ] **Mobile Apps:** APKs built
- [ ] **Mobile Apps:** Tested on devices
- [ ] **CI/CD:** GitHub Secrets configured (optional)
- [ ] **Monitoring:** Logs reviewed
- [ ] **Documentation:** User guides distributed

---

## 📚 DOCUMENTATION INDEX

### **Deployment:**
- `START_HERE.md` - This file
- `COMPLETE_DEPLOYMENT_SOLUTION.sh` - Automated deployment script
- `DEPLOY_API_NOW_COMPLETE.txt` - Manual deployment instructions
- `FINAL_DEPLOYMENT_SUMMARY.md` - Detailed deployment explanation

### **Configuration:**
- `URL_ACCESS_AND_MOBILE_CONFIG.md` - Mobile app configuration
- `GITHUB_SECRETS_SETUP.md` - CI/CD secrets setup

### **Pipeline:**
- `PIPELINE_ARCHITECTURE.md` - Complete pipeline documentation
- `ENTERPRISE_PIPELINE_GUIDE.md` - Best practices

### **User Guides:**
- `USER_GUIDES/` - All user documentation

---

## 🎉 SUCCESS CRITERIA

**Your deployment is successful when:**

✅ Health check returns: `{"status":"healthy","service":"PGWorld API"}`
✅ Mobile apps can connect to API
✅ Users can login/register
✅ All features work in mobile apps

---

## 🚀 QUICK START (TL;DR)

1. **Deploy API:**
   - Open AWS CloudShell
   - Run `COMPLETE_DEPLOYMENT_SOLUTION.sh`
   - Wait 5 minutes

2. **Test API:**
   - Open: http://34.227.111.143:8080/health
   - Should see: `{"status":"healthy"}`

3. **Update Mobile Apps:**
   - Change API URL to: `http://34.227.111.143:8080`
   - Build APKs
   - Test on devices

4. **Deploy to Users:**
   - Distribute APKs
   - Share user guides
   - Monitor logs

---

## 📞 SUPPORT

For issues:
1. Check troubleshooting section above
2. Review logs: `sudo journalctl -u pgworld-api -n 100`
3. Check service status: `sudo systemctl status pgworld-api`
4. Verify security group allows port 8080

---

**Last Updated:** October 11, 2025  
**Status:** Ready for deployment  
**Next Action:** Run `COMPLETE_DEPLOYMENT_SOLUTION.sh` in CloudShell

---

## 🎯 ACTION REQUIRED

**▶️ DO THIS NOW:**

1. Open AWS CloudShell: https://console.aws.amazon.com/cloudshell/
2. Run deployment script: `COMPLETE_DEPLOYMENT_SOLUTION.sh`
3. Wait 5 minutes
4. Test: http://34.227.111.143:8080/health
5. Update mobile apps
6. Done! 🎉

