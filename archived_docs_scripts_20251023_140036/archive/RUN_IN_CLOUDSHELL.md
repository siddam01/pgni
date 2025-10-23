# 🚀 Deploy Full App from CloudShell

## ❗ IMPORTANT:

**You CANNOT run `.bat` files in CloudShell!**

`.bat` files are for **Windows** only.  
CloudShell uses **Linux (bash)**.

---

## ✅ SOLUTION: Use the Bash Script

I've created a **CloudShell version** for you: `DEPLOY_FULL_APP_CLOUDSHELL.sh`

---

## 🎯 HOW TO RUN IN CLOUDSHELL:

### **Step 1: Open AWS CloudShell**
```
1. Go to AWS Console
2. Click CloudShell icon (top right)
3. Wait for terminal to load
```

### **Step 2: Clone Repository**
```bash
cd ~
git clone https://github.com/siddam01/pgni.git
cd pgni
```

### **Step 3: Get SSH Key Ready**
```bash
# Option A: If ssh-key.txt exists in terraform folder
cp terraform/ssh-key.txt cloudshell-key.pem
chmod 600 cloudshell-key.pem

# Option B: Create manually
nano cloudshell-key.pem
# Paste the SSH key content from your local file:
# C:\MyFolder\Mytest\pgworld-master\pgni-preprod-key.pem
# Press: Ctrl+X, then Y, then Enter
chmod 600 cloudshell-key.pem
```

### **Step 4: Run Deployment**
```bash
chmod +x DEPLOY_FULL_APP_CLOUDSHELL.sh
./DEPLOY_FULL_APP_CLOUDSHELL.sh
```

---

## ⏱️ TIMELINE:

```
Step 1: Check prerequisites        (30 sec)
Step 2: Get latest code            (30 sec)
Step 3: Build Admin App            (3-5 min)
Step 4: Build Tenant App           (3-5 min)
Step 5: Prepare server             (10 sec)
Step 6: Upload Admin App           (2-3 min)
Step 7: Upload Tenant App          (2-3 min)
Step 8: Install on server          (30 sec)

TOTAL TIME: 12-18 minutes
```

---

## 📝 WHAT THE SCRIPT DOES:

1. **Installs Flutter** (if not already installed in CloudShell)
2. **Clones your repository** from GitHub
3. **Builds Admin App** (37 pages → web files)
4. **Builds Tenant App** (28 pages → web files)
5. **Uploads to EC2** via SCP
6. **Configures Nginx** to serve the apps
7. **Tests deployment** and shows results

---

## ✅ AFTER DEPLOYMENT:

Your apps will be live at:
- **Admin:** http://34.227.111.143/admin
- **Tenant:** http://34.227.111.143/tenant

**Login credentials:**
- Admin: `admin@pgni.com` / `password123`
- Tenant: `tenant@pgni.com` / `password123`

---

## 🔍 TROUBLESHOOTING:

### **"flutter: command not found"**
The script will install Flutter automatically. If it fails:
```bash
cd ~
wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.16.0-stable.tar.xz
tar xf flutter_linux_3.16.0-stable.tar.xz
export PATH="$HOME/flutter/bin:$PATH"
flutter --version
```

### **"SSH key not found"**
Create the key manually:
```bash
nano cloudshell-key.pem
# Paste key content
# Press Ctrl+X, Y, Enter
chmod 600 cloudshell-key.pem
```

### **"Cannot connect to server"**
Check EC2 is running:
```bash
aws ec2 describe-instances --instance-ids i-0a77ebb04e0b88984 --query 'Reservations[0].Instances[0].State.Name'
```

---

## 🚀 QUICK START (COPY-PASTE):

```bash
# In AWS CloudShell, run these commands:

cd ~
git clone https://github.com/siddam01/pgni.git || (cd pgni && git pull)
cd pgni

# Create SSH key (paste your key content when nano opens)
nano cloudshell-key.pem
# After pasting, press: Ctrl+X, Y, Enter
chmod 600 cloudshell-key.pem

# Run deployment
chmod +x DEPLOY_FULL_APP_CLOUDSHELL.sh
./DEPLOY_FULL_APP_CLOUDSHELL.sh
```

---

## 📊 FILE COMPARISON:

| File | Platform | Use |
|------|----------|-----|
| `DEPLOY_FULL_APP_NOW.bat` | Windows | Run on your PC |
| `DEPLOY_FULL_APP_CLOUDSHELL.sh` | Linux | Run in CloudShell |

**Same functionality, different platforms!**

---

## 💡 RECOMMENDATION:

**Use CloudShell** because:
- ✅ No need to install Flutter on your PC
- ✅ Faster upload (AWS network)
- ✅ No Windows-specific issues
- ✅ Script handles everything

---

## ✅ WHAT YOU'LL GET:

After running this script, you'll have:

```
✅ Admin Portal (37 pages) - LIVE at /admin
   - Login page
   - Dashboard
   - Properties management
   - Rooms management
   - Tenant management
   - Bills & payments
   - Reports & analytics
   - Settings

✅ Tenant Portal (28 pages) - LIVE at /tenant
   - Login page
   - Dashboard (3 tabs)
   - View notices
   - Pay rent
   - Submit issues
   - Food menu
   - Services
   - Profile
```

---

## 🎯 NEXT STEPS:

1. **Run the script** in CloudShell (12-18 min)
2. **Open browser:** http://34.227.111.143/admin
3. **Login** with admin credentials
4. **Test all features**
5. **Share URL** with users

---

**Ready to deploy?** Open CloudShell and run the commands above! 🚀

