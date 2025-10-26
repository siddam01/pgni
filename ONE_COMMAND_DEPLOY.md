# 🚀 ONE-COMMAND DEPLOYMENT

## ✅ Everything is now on GitHub!

**Repository:** https://github.com/siddam01/pgni

**Commit:** Complete RBAC implementation with Manager Management and Deployment Scripts

---

## 🎯 Deploy to EC2 with ONE Command

### **Step 1: SSH to your EC2 instance**

```bash
ssh -i your-key.pem ec2-user@YOUR_EC2_IP
```

### **Step 2: Run the master deployment script**

```bash
bash <(curl -sL https://raw.githubusercontent.com/siddam01/pgni/main/EC2_DEPLOY_MASTER.sh)
```

That's it! The script will:
- ✅ Install all dependencies (Go, MySQL client, AWS CLI, Git)
- ✅ Setup database tables and RBAC schema
- ✅ Build and deploy backend API
- ✅ Create systemd service for auto-start
- ✅ Configure firewall
- ✅ Test deployment

---

## 📋 What You'll Need to Provide

The script will prompt you for:

1. **EC2 Public IP** (can auto-detect)
2. **RDS Endpoint** (e.g., `mydb.123.us-east-1.rds.amazonaws.com`)
3. **Database User** (default: `admin`)
4. **Database Password**
5. **Database Name** (default: `pgworld`)
6. **S3 Bucket Name** (default: `pgworld-admin`)

---

## 🎬 Example Session

```bash
# On your EC2 instance
$ bash <(curl -sL https://raw.githubusercontent.com/siddam01/pgni/main/EC2_DEPLOY_MASTER.sh)

╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║    PGNI - PG/Hostel Management System                    ║
║    Master Deployment Script                              ║
║    Version 1.0                                           ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝

========================================
Starting deployment process...
========================================

📋 Step 1: Configuration

Enter your EC2 Public IP (or press Enter to auto-detect): 
Auto-detected IP: 54.227.101.30

Enter RDS Endpoint: mydb.abc123.us-east-1.rds.amazonaws.com
Enter Database User [admin]: admin
Enter Database Password: ********
Enter Database Name [pgworld]: pgworld
Enter S3 Bucket [pgworld-admin]: pgworld-admin

Configuration complete!
EC2 IP: 54.227.101.30
RDS: mydb.abc123.us-east-1.rds.amazonaws.com
Database: pgworld
S3 Bucket: pgworld-admin

Continue with deployment? (y/n): y

📦 Step 2: Installing Dependencies
✅ Go installed
✅ MySQL client installed
✅ Git installed
✅ AWS CLI installed

📥 Step 3: Getting Application Code
✅ Code cloned from GitHub

💾 Step 4: Setting up Database
✅ Database setup complete

🔧 Step 5: Building and Deploying Backend
✅ Backend build successful
✅ Backend service started successfully

🔒 Step 6: Configuring Firewall
✅ Firewall configured

✅ Step 7: Testing Deployment
✅ Backend API is responding

╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║         🎉 DEPLOYMENT SUCCESSFUL! 🎉                     ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝

📊 Deployment Summary
========================================
✅ Backend API: http://54.227.101.30:8080
✅ Database: mydb.abc123.us-east-1.rds.amazonaws.com
✅ Service: pgworld-api (running)
```

---

## 🔄 Alternative: Deploy Backend Manually

If you prefer step-by-step:

```bash
# 1. Clone repository
git clone https://github.com/siddam01/pgni.git
cd pgni

# 2. Setup database
./setup-database.sh YOUR_RDS_ENDPOINT admin YOUR_PASSWORD

# 3. Deploy backend
./deploy-backend.sh YOUR_EC2_IP your-key.pem
```

---

## 🎨 Deploy Frontend (From Your Local Machine)

After backend is deployed:

### **Windows:**
```powershell
.\deploy-windows.ps1 -EC2_IP "54.227.101.30" -KeyFile "key.pem" -S3Bucket "pgworld-admin"
```

### **Linux/Mac:**
```bash
./deploy-frontend.sh pgworld-admin 54.227.101.30
```

---

## 📊 What Was Committed

### **36 files changed, 8,721+ insertions**

**New Features:**
- ✅ Complete RBAC system with 10 permissions
- ✅ Manager Management UI (3 new screens)
- ✅ Permission Service for centralized access control
- ✅ Permission checks in all screens

**New Files:**
- `pgworld-master/lib/utils/permission_service.dart`
- `pgworld-master/lib/screens/managers.dart`
- `pgworld-master/lib/screens/manager_add.dart`
- `pgworld-master/lib/screens/manager_permissions.dart`

**Deployment Scripts:**
- `EC2_DEPLOY_MASTER.sh` - One-command deployment ⭐
- `deploy-backend.sh` - Backend deployment
- `deploy-frontend.sh` - Frontend deployment
- `deploy-windows.ps1` - Windows deployment
- `setup-database.sh` - Database setup

**Documentation:**
- `DEPLOYMENT_READY.md` - Complete guide
- `DEPLOY_NOW.md` - Detailed steps
- `QUICK_DEPLOY.md` - Quick reference
- `.cursorrules` - Development standards
- Multiple implementation reports

---

## 🔧 Post-Deployment Commands

After deployment, useful commands:

```bash
# View logs
sudo journalctl -u pgworld-api -f

# Restart service
sudo systemctl restart pgworld-api

# Check status
sudo systemctl status pgworld-api

# Test API
curl http://localhost:8080/

# View deployment info
cat ~/pgni-deployment-info.txt
```

---

## 🎯 Quick Links

**GitHub Repository:**
https://github.com/siddam01/pgni

**Latest Commit:**
```
feat: Complete RBAC implementation with Manager Management and Deployment Scripts
Commit ID: c143f0f
```

**Deployment Script URL:**
```
https://raw.githubusercontent.com/siddam01/pgni/main/EC2_DEPLOY_MASTER.sh
```

---

## ✅ Verification Checklist

After running the one-command deployment:

- [ ] Backend API responds: `curl http://YOUR_EC2_IP:8080/`
- [ ] Service is running: `sudo systemctl status pgworld-api`
- [ ] Database tables created: Check admin_permissions table
- [ ] Logs show no errors: `sudo journalctl -u pgworld-api`
- [ ] Firewall allows port 8080
- [ ] Deployment info saved: `~/pgni-deployment-info.txt`

---

## 🆘 Troubleshooting

**Script fails to download:**
```bash
# Check internet connectivity
curl -I https://github.com

# Try with verbose output
bash -x <(curl -sL https://raw.githubusercontent.com/siddam01/pgni/main/EC2_DEPLOY_MASTER.sh)
```

**Database connection fails:**
```bash
# Test connection manually
mysql -h YOUR_RDS_ENDPOINT -u admin -p

# Check security groups - EC2 must be allowed to access RDS
```

**Service won't start:**
```bash
# Check logs
sudo journalctl -u pgworld-api --since "5 minutes ago"

# Verify .env file
cat ~/pgni-deployment/pgworld-api-master/.env

# Test binary manually
cd ~/pgni-deployment/pgworld-api-master
./pgworld-api
```

---

## 🎉 Success!

Your deployment is complete when you see:

```
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║         🎉 DEPLOYMENT SUCCESSFUL! 🎉                     ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
```

**Next:** Deploy frontend and start using your application!

---

## 📞 Need Help?

1. Check logs: `sudo journalctl -u pgworld-api -f`
2. Read deployment info: `cat ~/pgni-deployment-info.txt`
3. Review guides: See `DEPLOYMENT_READY.md` in repo
4. Test manually: `curl http://localhost:8080/`

---

**Ready to deploy? Just run:**

```bash
bash <(curl -sL https://raw.githubusercontent.com/siddam01/pgni/main/EC2_DEPLOY_MASTER.sh)
```

🚀 **Let's go!**

