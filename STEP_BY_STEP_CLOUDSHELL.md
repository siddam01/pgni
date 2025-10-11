# 🚀 CloudShell Deployment - Step by Step

## ⭐ STEP 1: Upload SSH Key (5 minutes)

### A. Open the SSH key on your Windows PC:

1. Press **Windows Key + E** (open File Explorer)
2. Navigate to: `C:\MyFolder\Mytest\pgworld-master\`
3. Find file: `cloudshell-key.pem`
4. Double-click to open in Notepad
5. Press **Ctrl+A** (select all)
6. Press **Ctrl+C** (copy)
7. **Keep Notepad open** - you'll need it

### B. In CloudShell window:

**Type this command:**
```bash
nano cloudshell-key.pem
```

Press **Enter**

**You'll see a text editor. Now:**
1. **Right-click** in the editor window (this pastes the key)
2. Press **Ctrl+X** (exit)
3. Press **Y** (yes, save)
4. Press **Enter** (confirm filename)

**Set permissions - type this:**
```bash
chmod 600 cloudshell-key.pem
```

Press **Enter**

**Verify it worked - type this:**
```bash
head -1 cloudshell-key.pem
```

Press **Enter**

**You should see:**
```
-----BEGIN RSA PRIVATE KEY-----
```

✅ **If you see this, SSH key is ready! Go to Step 2.**

❌ **If you see an error, the key didn't paste correctly. Try again.**

---

## ⭐ STEP 2: Run Deployment (7 minutes)

### A. On your Windows PC:

1. In File Explorer, go to: `C:\MyFolder\Mytest\pgworld-master\`
2. Find file: `DEPLOY_WITH_PROGRESS.txt`
3. Double-click to open in Notepad
4. Press **Ctrl+A** (select all)
5. Press **Ctrl+C** (copy)

### B. In CloudShell window:

1. **Right-click** in CloudShell (this pastes the entire script)
2. Press **Enter**

### C. Watch the progress:

You'll see:
```
==========================================
PGNi API Deployment - Starting
==========================================

Step 1: Installing prerequisites...
  - Updating system packages...
  - Installing Git...
  - Installing wget...
  ...
```

**This will take ~7 minutes. Just wait and watch!**

---

## ✅ SUCCESS - You'll see:

```
==========================================
✓ DEPLOYMENT COMPLETE!
==========================================

API is running at:
  http://34.227.111.143:8080

Health check:
  http://34.227.111.143:8080/health
```

---

## 🧪 STEP 3: Test in Browser

1. Open your web browser
2. Go to: `http://34.227.111.143:8080/health`
3. You should see:
```json
{"status":"healthy","service":"PGWorld API"}
```

✅ **If you see this JSON, YOUR API IS LIVE!** 🎉

---

## 📱 STEP 4: Update Mobile Apps

### A. Admin App (pgworld-master)

1. Open: `pgworld-master\lib\config\api_config.dart`
2. Change:
```dart
static const String baseUrl = 'http://34.227.111.143:8080';
```
3. Save the file

### B. Tenant App (pgworldtenant-master)

1. Open: `pgworldtenant-master\lib\config\api_config.dart`
2. Change:
```dart
static const String baseUrl = 'http://34.227.111.143:8080';
```
3. Save the file

### C. Update Android Manifest (BOTH apps)

File: `android\app\src\main\AndroidManifest.xml`

Add this line inside `<application>` tag:
```xml
android:usesCleartextTraffic="true"
```

Example:
```xml
<application
    android:label="PGNi"
    android:usesCleartextTraffic="true"
    android:name="${applicationName}"
    android:icon="@mipmap/ic_launcher">
```

### D. Build APKs

**Open Command Prompt in each app folder:**

```bash
# For Admin App
cd C:\MyFolder\Mytest\pgworld-master\pgworld-master
flutter clean
flutter pub get
flutter build apk --release

# For Tenant App
cd C:\MyFolder\Mytest\pgworld-master\pgworldtenant-master
flutter clean
flutter pub get
flutter build apk --release
```

**APKs will be in:**
- Admin: `pgworld-master\build\app\outputs\flutter-apk\app-release.apk`
- Tenant: `pgworldtenant-master\build\app\outputs\flutter-apk\app-release.apk`

---

## ❌ IF SOMETHING GOES WRONG:

### Problem: SSH key paste didn't work

**Solution:**
```bash
# Delete and try again
rm cloudshell-key.pem
nano cloudshell-key.pem
# Paste again carefully
```

### Problem: Deployment gets stuck

**Solution:**
- Wait 3 minutes
- If still stuck, press **Ctrl+C**
- Tell me which step it got stuck on

### Problem: API not responding after deployment

**Solution in CloudShell:**
```bash
# Check if service is running
ssh -i cloudshell-key.pem ec2-user@34.227.111.143 "sudo systemctl status pgworld-api"

# Check logs
ssh -i cloudshell-key.pem ec2-user@34.227.111.143 "sudo journalctl -u pgworld-api -n 50"

# Restart service
ssh -i cloudshell-key.pem ec2-user@34.227.111.143 "sudo systemctl restart pgworld-api"
```

---

## 📞 NEED HELP?

If you get stuck, tell me:
1. Which step you're on (1, 2, 3, or 4)
2. What error message you see (copy and paste it)
3. I'll help you fix it immediately

---

## 🎯 QUICK REFERENCE:

**CloudShell URL:**
https://console.aws.amazon.com/cloudshell/

**API Health Check:**
http://34.227.111.143:8080/health

**SSH Key Location on PC:**
`C:\MyFolder\Mytest\pgworld-master\cloudshell-key.pem`

**Deployment Script Location:**
`C:\MyFolder\Mytest\pgworld-master\DEPLOY_WITH_PROGRESS.txt`

---

## ✅ CHECKLIST:

- [ ] Step 1A: Opened cloudshell-key.pem in Notepad
- [ ] Step 1A: Copied key (Ctrl+A, Ctrl+C)
- [ ] Step 1B: Ran `nano cloudshell-key.pem` in CloudShell
- [ ] Step 1B: Pasted key (right-click)
- [ ] Step 1B: Saved (Ctrl+X, Y, Enter)
- [ ] Step 1B: Set permissions `chmod 600 cloudshell-key.pem`
- [ ] Step 1B: Verified with `head -1 cloudshell-key.pem`
- [ ] Step 2A: Opened DEPLOY_WITH_PROGRESS.txt in Notepad
- [ ] Step 2A: Copied script (Ctrl+A, Ctrl+C)
- [ ] Step 2B: Pasted in CloudShell (right-click)
- [ ] Step 2B: Pressed Enter
- [ ] Step 2C: Waited for completion (~7 min)
- [ ] Step 3: Tested in browser
- [ ] Step 4: Updated mobile apps
- [ ] Step 4: Built APKs

---

**Start with Step 1 now!** 🚀

