# Install AWS CLI Manually - Step by Step

## The winget installation failed. Here's how to install manually:

---

## Option 1: Direct Download (Recommended - 5 minutes)

### Step 1: Download AWS CLI
1. **Open your browser**
2. **Go to:** https://awscli.amazonaws.com/AWSCLIV2.msi
3. **File will download:** `AWSCLIV2.msi` (~40 MB)

### Step 2: Install
1. **Double-click** the downloaded `AWSCLIV2.msi` file
2. **Click:** "Next"
3. **Accept** license agreement
4. **Click:** "Next" → "Next" → "Install"
5. **Click:** "Finish"

### Step 3: Restart PowerShell
1. **Close** current PowerShell window
2. **Open new** PowerShell
3. **Test:**
   ```powershell
   aws --version
   ```
4. **Should show:** `aws-cli/2.x.x Python/3.x.x Windows/10 exe/AMD64`

✅ **If you see version number, AWS CLI is installed!**

---

## Option 2: Alternative Method

If the MSI installer also fails, try:

### Download from Browser:
1. Go to: https://aws.amazon.com/cli/
2. Click: "Download for Windows"
3. Run the installer

---

## After Installation: Configure AWS

### Step 1: Get Your Access Keys from AWS Console

1. **Go to:** https://console.aws.amazon.com/iam/
2. **Click:** "Users" (left sidebar)
3. **Do you have a user listed?**

   **If NO:**
   - Click: "Create user"
   - Name: `pgni-deployer`
   - Click: "Next"
   - Select: "Attach policies directly"
   - Check these policies:
     - ✅ AmazonEC2FullAccess
     - ✅ AmazonRDSFullAccess
     - ✅ AmazonS3FullAccess
     - ✅ IAMFullAccess
     - ✅ AmazonSSMFullAccess
   - Click: "Create user"

   **If YES:**
   - Click on the username

4. **Click:** "Security credentials" tab
5. **Scroll to:** "Access keys" section
6. **Click:** "Create access key"
7. **Choose:** "Command Line Interface (CLI)"
8. **Check:** "I understand the above recommendation..."
9. **Click:** "Next" → "Create access key"
10. **IMPORTANT:** Copy or download:
    - Access key ID (starts with `AKIA...`)
    - Secret access key (long random string)

---

### Step 2: Configure AWS CLI

Open PowerShell and run:

```powershell
aws configure
```

**You'll be prompted for 4 things:**

```
AWS Access Key ID [None]: 
```
→ Paste your Access Key ID (AKIA...)

```
AWS Secret Access Key [None]: 
```
→ Paste your Secret Access Key

```
Default region name [None]: 
```
→ Type: `us-east-1`

```
Default output format [None]: 
```
→ Type: `json`

---

### Step 3: Test Configuration

```powershell
aws sts get-caller-identity
```

**Expected output:**
```json
{
    "UserId": "AIDAI...",
    "Account": "698302425856",
    "Arn": "arn:aws:iam::698302425856:user/pgni-deployer"
}
```

✅ **If you see your account number (698302425856), you're ready!**

---

## 🚀 Once AWS CLI is Configured

Run the deployment:

```powershell
cd C:\MyFolder\Mytest\pgworld-master

.\deploy-complete.ps1 -Environment preprod
```

**This will create:**
- ✅ MySQL Database in AWS
- ✅ S3 Storage in AWS
- ✅ EC2 Server in AWS
- ✅ All credentials and documentation

**Duration:** 15-20 minutes (automated)

---

## 🆘 Troubleshooting

### Issue: MSI installer fails with error 1603
**Possible causes:**
- Another installation in progress
- Insufficient permissions
- Corrupted download

**Solutions:**
1. **Run as Administrator:**
   - Right-click `AWSCLIV2.msi`
   - Select "Run as administrator"

2. **Clean install:**
   - Uninstall any existing AWS CLI
   - Restart computer
   - Download fresh copy
   - Install again

3. **Alternative method:**
   - Use Python pip: `pip install awscli`
   - Or use AWS CloudShell directly in AWS Console

---

### Issue: "aws command not found" after install
**Solution:**
- Close and reopen PowerShell
- Or restart computer
- Check PATH: `$env:PATH` should include AWS CLI path

---

### Issue: "Access Denied" during aws configure test
**Solution:**
- Verify IAM user has correct permissions
- Make sure you copied the full secret key (it's long!)
- Try creating new access keys

---

## 📋 Quick Checklist

- [ ] Downloaded AWSCLIV2.msi
- [ ] Installed AWS CLI (double-click MSI)
- [ ] Restarted PowerShell
- [ ] `aws --version` shows version number
- [ ] Created IAM user in AWS Console (or using existing)
- [ ] Created access keys for IAM user
- [ ] Ran `aws configure` and entered keys
- [ ] `aws sts get-caller-identity` shows account 698302425856
- [ ] Ready to run `.\deploy-complete.ps1 -Environment preprod`

---

## 🎯 Alternative: Use AWS Console Directly

If AWS CLI installation keeps failing, you can also:

1. **Use AWS CloudShell** (browser-based CLI):
   - Go to AWS Console
   - Click the CloudShell icon (top right, next to bell)
   - It has AWS CLI pre-installed
   - But you'd need to upload the script

2. **Create resources manually:**
   - Follow `DEPLOY_TO_AWS.md` for manual steps
   - Not automated, but works without CLI

**However, I recommend getting AWS CLI working on your computer for the best experience!**

---

## 📞 Summary

### What You Need:
1. AWS CLI installed on your computer
2. IAM user access keys from AWS Console
3. AWS CLI configured with those keys

### Download Link:
**Direct:** https://awscli.amazonaws.com/AWSCLIV2.msi

### After Installation:
```powershell
aws configure  # Enter your keys
aws sts get-caller-identity  # Test it works
.\deploy-complete.ps1 -Environment preprod  # Deploy!
```

---

**You're so close! Just need to get AWS CLI installed and configured, then you can deploy with one command!** 🚀

*Last Updated: January 8, 2025*

