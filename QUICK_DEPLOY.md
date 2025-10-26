# 🚀 Quick Deploy - Get Live in 30 Minutes!

## ⚡ **Ultra-Fast Deployment Guide**

---

## 📋 **Prerequisites** (5 minutes)

```bash
# 1. AWS Account with:
- EC2 instance running (or create one)
- RDS MySQL database (or use existing)
- S3 bucket for frontend
- AWS CLI installed and configured

# 2. Your Information:
EC2_IP="YOUR_EC2_PUBLIC_IP"           # e.g., 54.227.101.30
KEY_FILE="pgworld-key.pem"            # Your EC2 key file
RDS_ENDPOINT="YOUR_RDS_ENDPOINT"      # e.g., mydb.123.us-east-1.rds.amazonaws.com
DB_USER="admin"                       # Your database username
DB_PASSWORD="YOUR_PASSWORD"           # Your database password
S3_BUCKET="pgworld-admin-portal"      # Your S3 bucket name
```

---

## 🎯 **3-Step Deployment**

### **Step 1: Deploy Database** (5 minutes)

```bash
# Run database setup script
./setup-database.sh $RDS_ENDPOINT $DB_USER $DB_PASSWORD

# Expected output: ✅ Database setup complete!
```

### **Step 2: Deploy Backend** (10 minutes)

```bash
# Run backend deployment script
./deploy-backend.sh $EC2_IP $KEY_FILE

# Expected output: ✅ Backend deployed successfully!
# API URL: http://YOUR_EC2_IP:8080

# Test it:
curl http://$EC2_IP:8080/
# Should return: "ok"
```

### **Step 3: Deploy Frontend** (10 minutes)

```bash
# Run frontend deployment script
./deploy-frontend.sh $S3_BUCKET $EC2_IP

# Expected output: ✅ Frontend deployed successfully!
# S3 URL: http://your-bucket.s3-website-us-east-1.amazonaws.com
```

---

## ✅ **You're Live!**

### **Access Your Application:**

**Admin Portal:**
```
http://pgworld-admin-portal.s3-website-us-east-1.amazonaws.com
```

**API:**
```
http://YOUR_EC2_IP:8080
```

### **Test It:**
1. Open the admin portal URL
2. Login with your credentials
3. Go to Settings → Managers
4. Try adding a manager
5. Success! 🎉

---

## 🛠️ **Common Issues & Fixes**

### **Issue: API not responding**
```bash
# Check backend status
ssh -i $KEY_FILE ec2-user@$EC2_IP 'sudo systemctl status pgworld-api'

# View logs
ssh -i $KEY_FILE ec2-user@$EC2_IP 'sudo journalctl -u pgworld-api -f'

# Restart if needed
ssh -i $KEY_FILE ec2-user@$EC2_IP 'sudo systemctl restart pgworld-api'
```

### **Issue: Frontend not loading**
```bash
# Check S3 bucket policy (must be public)
aws s3api get-bucket-policy --bucket $S3_BUCKET

# Re-upload if needed
cd pgworld-master
flutter build web --release
aws s3 sync build/web/ s3://$S3_BUCKET/ --delete
```

### **Issue: Database connection failed**
```bash
# Test database connection
mysql -h $RDS_ENDPOINT -u $DB_USER -p

# Update .env on EC2
ssh -i $KEY_FILE ec2-user@$EC2_IP
cd ~/pgworld-api
nano .env
# Update DB_HOST, DB_USER, DB_PASSWORD
sudo systemctl restart pgworld-api
```

---

## 📊 **Verify Deployment**

Run this checklist:

```bash
# 1. Backend health check
curl http://$EC2_IP:8080/
# ✅ Should return: "ok"

# 2. Backend service status
ssh -i $KEY_FILE ec2-user@$EC2_IP 'sudo systemctl is-active pgworld-api'
# ✅ Should return: active

# 3. Frontend accessible
curl -I http://$S3_BUCKET.s3-website-us-east-1.amazonaws.com
# ✅ Should return: HTTP/1.1 200 OK

# 4. Database tables exist
mysql -h $RDS_ENDPOINT -u $DB_USER -p$DB_PASSWORD pgworld -e "SHOW TABLES LIKE '%admin%';"
# ✅ Should show: admins, admin_permissions
```

---

## 🔄 **Update Deployed App**

### **Update Backend:**
```bash
cd pgworld-api-master
# Make your changes
./deploy-backend.sh $EC2_IP $KEY_FILE
```

### **Update Frontend:**
```bash
cd pgworld-master
# Make your changes
./deploy-frontend.sh $S3_BUCKET $EC2_IP
```

---

## 🎨 **Optional: Setup Custom Domain**

### **1. Buy Domain (Route 53)**
```
- Go to Route 53
- Buy domain: yourdomain.com
```

### **2. Point to CloudFront**
```
- Create CloudFront distribution
- Origin: S3 bucket
- CNAME: yourdomain.com
- SSL: Request certificate in ACM
```

### **3. Update DNS**
```
- Add A record: yourdomain.com → CloudFront
- Add A record: api.yourdomain.com → EC2 IP
```

---

## 📞 **Need Help?**

### **View Logs:**
```bash
# Backend logs (live)
ssh -i $KEY_FILE ec2-user@$EC2_IP 'sudo journalctl -u pgworld-api -f'

# Backend logs (last hour)
ssh -i $KEY_FILE ec2-user@$EC2_IP 'sudo journalctl -u pgworld-api --since "1 hour ago"'

# Check for errors
ssh -i $KEY_FILE ec2-user@$EC2_IP 'sudo journalctl -u pgworld-api --since "1 hour ago" | grep -i error'
```

### **Restart Services:**
```bash
# Restart backend
ssh -i $KEY_FILE ec2-user@$EC2_IP 'sudo systemctl restart pgworld-api'

# Stop backend
ssh -i $KEY_FILE ec2-user@$EC2_IP 'sudo systemctl stop pgworld-api'

# Start backend
ssh -i $KEY_FILE ec2-user@$EC2_IP 'sudo systemctl start pgworld-api'
```

### **Database Operations:**
```bash
# Backup database
mysqldump -h $RDS_ENDPOINT -u $DB_USER -p$DB_PASSWORD pgworld > backup_$(date +%Y%m%d).sql

# Restore database
mysql -h $RDS_ENDPOINT -u $DB_USER -p$DB_PASSWORD pgworld < backup.sql

# View tables
mysql -h $RDS_ENDPOINT -u $DB_USER -p$DB_PASSWORD pgworld -e "SHOW TABLES;"
```

---

## 🎉 **Success!**

Your PGNI application is now live and accessible to users!

**What's Working:**
- ✅ Complete RBAC system
- ✅ Manager Management UI
- ✅ All screens permission-protected
- ✅ Backend API running
- ✅ Frontend served from S3
- ✅ Database connected

**Share with your team:**
- Frontend URL: `http://$S3_BUCKET.s3-website-us-east-1.amazonaws.com`
- Admin login credentials
- Manager Management guide

---

**Deployment Time:** ~30 minutes  
**Status:** ✅ LIVE  
**Next:** User training & feedback collection

🚀 **Congratulations on your deployment!** 🚀

