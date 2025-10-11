# 🔑 How to Get Your SSH Key for Deployment

The deployment script needs your EC2 SSH private key. Here's how to get it:

---

## ✅ **EASIEST METHOD: From Your Windows PC**

### **Step 1: Extract SSH Key from Terraform**

Open PowerShell on your Windows PC and run:

```powershell
cd C:\MyFolder\Mytest\pgworld-master\terraform
terraform output -raw ssh_private_key > ssh-key.txt
```

### **Step 2: View the Key**

```powershell
notepad ssh-key.txt
```

### **Step 3: Copy to CloudShell**

**Option A: Copy/Paste (Easiest)**
1. Select ALL the content in `ssh-key.txt` (Ctrl+A)
2. Copy it (Ctrl+C)
3. Go to CloudShell
4. Run: `nano ec2-key.pem`
5. Right-click in nano to paste
6. Press `Ctrl+X`, then `Y`, then `Enter`
7. Run: `chmod 600 ec2-key.pem`

**Option B: Upload via CloudShell**
1. In CloudShell, click **Actions** > **Upload file**
2. Select `ssh-key.txt` from your PC
3. Rename it: `mv ssh-key.txt ec2-key.pem`
4. Set permissions: `chmod 600 ec2-key.pem`

---

## 🔄 **ALTERNATIVE: Store in AWS Systems Manager**

If you want to avoid this in the future, store the key in AWS Parameter Store:

### **From Your Windows PC:**

```powershell
cd C:\MyFolder\Mytest\pgworld-master\terraform

# Get the key
$sshKey = terraform output -raw ssh_private_key

# Store in AWS Parameter Store
aws ssm put-parameter `
    --name "/pgni/preprod/ssh_private_key" `
    --value $sshKey `
    --type "SecureString" `
    --region us-east-1
```

Then the deployment scripts will work automatically!

---

## 🎯 **AFTER YOU HAVE THE KEY**

Once you have `ec2-key.pem` in CloudShell, run:

```bash
# Push the updated script to GitHub first
cd /path/to/your/repo
git add DEPLOY_DIRECT.sh
git commit -m "Add direct deployment script"
git push origin main

# Then in CloudShell:
curl -O https://raw.githubusercontent.com/siddam01/pgni/main/DEPLOY_DIRECT.sh
chmod +x DEPLOY_DIRECT.sh
./DEPLOY_DIRECT.sh
```

---

## 📋 **VERIFICATION**

Your SSH key should:
- Start with: `-----BEGIN RSA PRIVATE KEY-----`
- End with: `-----END RSA PRIVATE KEY-----`
- Be about 1600-3200 characters long
- Not have any extra spaces or characters

---

## 🚨 **If Terraform Output Doesn't Work**

If `terraform output` fails, you can also check:

1. **AWS EC2 Console:**
   - Go to EC2 > Key Pairs
   - You might need to create a new key pair

2. **Terraform State:**
   ```powershell
   cd terraform
   terraform show | Select-String "private_key"
   ```

---

## ✅ **Quick Summary**

**On Windows PC:**
```powershell
cd C:\MyFolder\Mytest\pgworld-master\terraform
terraform output -raw ssh_private_key > ssh-key.txt
notepad ssh-key.txt
# Copy the content
```

**In CloudShell:**
```bash
nano ec2-key.pem
# Paste the key (right-click)
# Press Ctrl+X, Y, Enter

chmod 600 ec2-key.pem
./DEPLOY_DIRECT.sh
```

**That's it!** 🎉

