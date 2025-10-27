# Deployment Options - Choose What Works Best for You

## 🎯 Where to Deploy From?

You have **three options** depending on where your code is located:

---

## Option 1: Deploy from Windows (Local Machine) ⭐ RECOMMENDED

**Use this if**: Your code is on your Windows PC at `C:\MyFolder\Mytest\pgworld-master`

### Steps:

1. Open **PowerShell** on your Windows machine
2. Navigate to project directory:
   ```powershell
   cd C:\MyFolder\Mytest\pgworld-master
   ```
3. Run deployment script:
   ```powershell
   .\QUICK_DEPLOY_NOW.ps1
   ```

**Advantages**: 
- ✅ Faster (builds on your PC)
- ✅ Works offline on EC2
- ✅ Easier to troubleshoot

---

## Option 2: Deploy from Git Bash (Windows)

**Use this if**: You prefer bash commands on Windows

### Steps:

1. Open **Git Bash** on your Windows machine
2. Navigate to project:
   ```bash
   cd /c/MyFolder/Mytest/pgworld-master
   ```
3. Run bash script:
   ```bash
   bash rebuild-and-deploy-all.sh
   ```

**Requirements**: Git Bash installed on Windows

---

## Option 3: Deploy Directly from EC2 Server

**Use this if**: Your code is already on the EC2 server, or you want to build there

### Steps:

1. SSH into your EC2 server:
   ```bash
   ssh -i terraform/pgworld-key.pem ubuntu@54.227.101.30
   ```

2. Navigate to your project directory:
   ```bash
   cd /path/to/pgworld-master
   ```

3. Run the EC2 deployment script:
   ```bash
   bash deploy-from-ec2.sh
   ```

**Note**: This requires Flutter to be installed on the EC2 server

---

## 🔍 Understanding Your Setup

Based on your screenshot and command, you're logged into an EC2 instance as `ec2-user@ip-172-31-27-239`. This appears to be:

- **Private IP**: 172.31.27.239
- **User**: ec2-user

But your deployment target is:
- **Public IP**: 54.227.101.30
- **User**: ubuntu

### Questions to Clarify:

1. **Is your code on your local Windows machine?**
   - ✅ Use Option 1 (PowerShell from Windows)

2. **Is your code on the EC2 server (172.31.27.239)?**
   - ✅ Use Option 3 (deploy-from-ec2.sh)

3. **Are you trying to deploy TO 54.227.101.30 FROM 172.31.27.239?**
   - ✅ First copy code to 172.31.27.239, then use deploy-from-ec2.sh

---

## 📦 Which Files to Deploy?

You need to deploy the **built web apps**, not the source code:

### For Admin Portal:
```
pgworld-master/build/web/*
↓ (deploy to)
/var/www/admin/ (on EC2 server)
```

### For Tenant Portal:
```
pgworldtenant-master/build/web/*
↓ (deploy to)
/var/www/tenant/ (on EC2 server)
```

---

## 🚀 Quick Decision Guide

### Scenario 1: Code is on Windows PC
```powershell
# On your Windows machine
cd C:\MyFolder\Mytest\pgworld-master
.\QUICK_DEPLOY_NOW.ps1
```

### Scenario 2: Code is on EC2 (172.31.27.239)
```bash
# SSH to EC2 first
ssh -i your-key.pem ec2-user@172.31.27.239

# Then run
cd /path/to/pgworld-master
bash deploy-from-ec2.sh
```

### Scenario 3: Manual Deployment
```bash
# Build locally (Windows)
cd pgworld-master
flutter build web --release

# Deploy to EC2
scp -i terraform/pgworld-key.pem -r build/web/* ubuntu@54.227.101.30:/var/www/admin/

# Repeat for tenant portal
cd ../pgworldtenant-master
flutter build web --release
scp -i terraform/pgworld-key.pem -r build/web/* ubuntu@54.227.101.30:/var/www/tenant/

# Restart Nginx
ssh -i terraform/pgworld-key.pem ubuntu@54.227.101.30 "sudo systemctl restart nginx"
```

---

## ❌ Common Mistakes

### 1. Wrong Script Type
```bash
# WRONG - PowerShell script with bash
bash QUICK_DEPLOY_NOW.ps1

# CORRECT - Use .sh version
bash rebuild-and-deploy-all.sh
```

### 2. Running on Wrong Server
```bash
# WRONG - Running on deployment target
# You can't deploy "to" the server you're "on"

# CORRECT - Deploy FROM your local machine TO the server
# OR build on server and copy to web directory
```

### 3. Wrong User/IP
```bash
# Make sure you're targeting the right server
Target: ubuntu@54.227.101.30 (public IP)
Not: ec2-user@172.31.27.239 (might be different instance)
```

---

## 🆘 Still Confused?

### Tell me:
1. Where is your source code? (Windows PC or EC2?)
2. What's your goal? (Deploy from Windows or from EC2?)
3. Do you have Flutter installed on EC2?

### Quick Check:
```bash
# On your Windows machine
cd C:\MyFolder\Mytest\pgworld-master
dir  # Should show pgworld-master and pgworldtenant-master folders

# If yes, use Option 1 (PowerShell)
.\QUICK_DEPLOY_NOW.ps1
```

---

## 📝 Summary

| Location | Script to Use | Command |
|----------|--------------|---------|
| Windows PC | `QUICK_DEPLOY_NOW.ps1` | `.\QUICK_DEPLOY_NOW.ps1` |
| Git Bash (Windows) | `rebuild-and-deploy-all.sh` | `bash rebuild-and-deploy-all.sh` |
| EC2 Server | `deploy-from-ec2.sh` | `bash deploy-from-ec2.sh` |

**Most Common**: Your code is on Windows → Use `.\QUICK_DEPLOY_NOW.ps1`
