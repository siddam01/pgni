# ✅ AUTOMATED DEPLOYMENT - NO MORE MANUAL CONFIGURATION

## 🎯 What This Does

**ONE command** deploys everything:
- ✅ Backend API (Go)
- ✅ Frontend (Admin Portal)
- ✅ Nginx configuration
- ✅ Systemd services
- ✅ **ALL settings from config file**
- ✅ **Only asks for DB password ONCE**

---

## 🚀 QUICK START (2 Commands)

### **On EC2, run:**

```bash
# Download deployment files
curl -sL https://github.com/siddam01/pgni/archive/refs/heads/main.zip -o pgni.zip
unzip -q pgni.zip
cd pgni-main

# Run automated deployment
chmod +x DEPLOY_AUTO_COMPLETE.sh
./DEPLOY_AUTO_COMPLETE.sh
```

**That's it!** You'll only be prompted for:
1. Database password
2. Confirmation to continue

---

## 📋 What Gets Configured Automatically

All settings are in `config.production.env`:

```bash
✓ EC2 IP:      54.227.101.30
✓ RDS Host:    database-pgni.cezawkgguojl.us-east-1.rds.amazonaws.com
✓ DB Name:     pgworld
✓ DB User:     admin
✓ S3 Bucket:   pgworld-admin
✓ API Port:    8080
✓ Paths:       /opt/pgworld-api, /var/www/html/admin
```

**NO manual input needed for any of this!**

---

## 🔐 Security: Database Password

For security, the DB password is:
- ❌ **NOT stored** in config file
- ✅ **Asked once** at runtime
- ✅ **Stored only** in API .env (secure location)

---

## 📦 What the Script Does

1. **Loads config** from `config.production.env`
2. **Validates** all settings
3. **Tests** database connection
4. **Builds & deploys** backend API
5. **Deploys** admin frontend (or placeholder)
6. **Configures** Nginx
7. **Starts** all services
8. **Verifies** everything works

---

## ✅ After Deployment

You'll see:

```
=========================================
✅ DEPLOYMENT SUCCESSFUL!
=========================================

📊 Deployment Summary:

  ✓ Backend API: http://54.227.101.30:8080
  ✓ Admin Portal: http://54.227.101.30/admin/
  ⏳ Tenant Portal: http://54.227.101.30/tenant/ (upload build)

🔧 Service Management:
  API Status:  sudo systemctl status pgworld-api
  API Logs:    sudo journalctl -u pgworld-api -f
  API Restart: sudo systemctl restart pgworld-api

📁 File Locations:
  Backend:  /opt/pgworld-api
  Admin:    /var/www/html/admin
  Config:   /opt/pgworld-api/.env
```

---

## 🔧 If You Need to Change Settings

Edit the config file:

```bash
nano config.production.env

# Change any setting
# Example: Change API port
API_PORT=9090

# Save and re-run deployment
./DEPLOY_AUTO_COMPLETE.sh
```

---

## 📤 Upload Admin Build Files

If the script doesn't find pre-built files, it creates a placeholder.

**To upload your build:**

### Option A: Via WinSCP (Easiest)
1. Open WinSCP on Windows
2. Connect to `54.227.101.30`
3. Local: `C:\MyFolder\Mytest\pgworld-master\deployment-admin-20251027-213037\admin\`
4. Remote: `/var/www/html/admin/`
5. Upload all files
6. In terminal: `sudo chmod -R 755 /var/www/html/admin`

### Option B: Via SCP
```bash
# On Windows (PowerShell)
scp -i your-key.pem -r deployment-admin-*/admin/* ec2-user@54.227.101.30:/tmp/admin-upload/

# On EC2
sudo cp -r /tmp/admin-upload/* /var/www/html/admin/
sudo chmod -R 755 /var/www/html/admin
```

---

## 🐛 Troubleshooting

### Script says "Configuration file not found"
```bash
# Make sure you're in the right directory
cd pgni-main
ls -la config.production.env

# Should show the file
```

### Database connection fails
```bash
# Test manually
mysql -h database-pgni.cezawkgguojl.us-east-1.rds.amazonaws.com \
      -u admin \
      -p \
      pgworld

# Check your password
```

### API doesn't start
```bash
# Check logs
sudo journalctl -u pgworld-api -n 50

# Check if Go is installed
go version

# Reinstall Go if needed
sudo yum install -y golang
```

### Can't access from browser
```bash
# Check security group allows:
# - Port 80 (HTTP)
# - Port 8080 (API)

# Test locally first
curl http://localhost/admin/
curl http://localhost:8080/health
```

---

## 🔄 Re-deploying

To re-deploy (updates, fixes, etc.):

```bash
cd pgni-main

# Pull latest code
git pull origin main

# Re-run deployment
./DEPLOY_AUTO_COMPLETE.sh

# Password is remembered in API .env
# So it might not ask again!
```

---

## 📊 What Gets Created

### Files:
- `/opt/pgworld-api/` - Backend API binary
- `/opt/pgworld-api/.env` - API environment variables
- `/opt/pgworld-api/start.sh` - API startup script
- `/var/www/html/admin/` - Admin frontend
- `/etc/nginx/conf.d/cloudpg.conf` - Nginx config
- `/etc/systemd/system/pgworld-api.service` - Systemd service

### Services:
- `pgworld-api.service` - Backend API (auto-starts on boot)
- `nginx.service` - Web server

---

## ✅ Benefits of This Approach

1. **No manual configuration** - Everything in config file
2. **Repeatable** - Run anytime, same result
3. **Version controlled** - Config file in Git
4. **Secure** - Password not stored in config
5. **Idempotent** - Safe to run multiple times
6. **Portable** - Works on any EC2 instance

---

## 🎯 For Future Deployments

### To deploy to a new environment:

1. **Copy config file**:
   ```bash
   cp config.production.env config.staging.env
   ```

2. **Edit settings**:
   ```bash
   nano config.staging.env
   # Change EC2_PUBLIC_IP, DB_HOST, etc.
   ```

3. **Run deployment**:
   ```bash
   CONFIG_FILE=config.staging.env ./DEPLOY_AUTO_COMPLETE.sh
   ```

---

## 📞 Support

**If deployment fails:**
1. Check the error message
2. Run with verbose logging: `bash -x ./DEPLOY_AUTO_COMPLETE.sh`
3. Check logs: `sudo journalctl -u pgworld-api -f`
4. Create GitHub issue with error details

---

**Status**: ✅ Fully automated, configuration-driven deployment  
**Time**: 3-5 minutes from start to finish  
**Manual steps**: Enter DB password once, confirm deployment  
**Questions asked**: 2 (password, confirmation)  
**Previous questions asked**: ~20+ (EC2 IP, RDS endpoint, DB name, etc.)

