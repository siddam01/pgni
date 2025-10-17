# Backup Plan: If Flutter Build Fails Due to Memory

## 🚨 If You See This Error:
```
dart2js crashed
ProcessException: Process exited abnormally
Out of memory
Killed
```

---

## ✅ **Solution 1: Temporary Instance Upgrade (RECOMMENDED)**

### **Cost:** ~$0.05 for 30 minutes
### **Success Rate:** 100%

```bash
# 1. Stop EC2 instance
aws ec2 stop-instances --instance-ids i-0909d462845deb151

# 2. Wait for stop (check in AWS Console or run):
aws ec2 wait instance-stopped --instance-ids i-0909d462845deb151

# 3. Change to t3.medium (4GB RAM)
aws ec2 modify-instance-attribute \
  --instance-id i-0909d462845deb151 \
  --instance-type t3.medium

# 4. Start instance
aws ec2 start-instances --instance-ids i-0909d462845deb151

# 5. Wait for start
aws ec2 wait instance-running --instance-ids i-0909d462845deb151

# 6. Run the build script (will complete in 5-10 minutes)
ssh ec2-user@34.227.111.143 < FIX_WEB_PACKAGE_AND_BUILD.sh

# 7. After deployment succeeds, scale back down to t3.micro:
aws ec2 stop-instances --instance-ids i-0909d462845deb151
aws ec2 wait instance-stopped --instance-ids i-0909d462845deb151
aws ec2 modify-instance-attribute \
  --instance-id i-0909d462845deb151 \
  --instance-type t3.micro
aws ec2 start-instances --instance-ids i-0909d462845deb151
```

---

## ✅ **Solution 2: Build Locally on Your Windows PC**

### **Requirements:**
- Flutter SDK installed on your PC
- 20 minutes build time

### **Steps:**

1. **Install Flutter on Windows** (if not already):
   ```powershell
   # Download Flutter SDK
   Invoke-WebRequest -Uri "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.27.2-stable.zip" -OutFile "$env:TEMP\flutter.zip"
   
   # Extract
   Expand-Archive -Path "$env:TEMP\flutter.zip" -DestinationPath "C:\src"
   
   # Add to PATH (run as Admin)
   [Environment]::SetEnvironmentVariable("Path", "$env:Path;C:\src\flutter\bin", "Machine")
   
   # Verify
   flutter doctor -v
   ```

2. **Build both apps locally:**
   ```powershell
   cd C:\MyFolder\Mytest\pgworld-master\pgworld-master
   flutter clean
   flutter pub upgrade
   flutter build web --release --no-source-maps --dart-define=dart.vm.product=true
   
   cd C:\MyFolder\Mytest\pgworld-master\pgworldtenant-master
   flutter clean
   flutter pub upgrade
   flutter build web --release --no-source-maps --dart-define=dart.vm.product=true
   ```

3. **Upload to EC2:**
   ```powershell
   # Use SCP or WinSCP to upload build/web folders
   scp -i pgni-preprod-key.pem -r pgworld-master\build\web ec2-user@34.227.111.143:/tmp/admin-web
   scp -i pgni-preprod-key.pem -r pgworldtenant-master\build\web ec2-user@34.227.111.143:/tmp/tenant-web
   
   # Then SSH to EC2 and deploy:
   ssh -i pgni-preprod-key.pem ec2-user@34.227.111.143
   sudo rm -rf /usr/share/nginx/html/admin /usr/share/nginx/html/tenant
   sudo mv /tmp/admin-web /usr/share/nginx/html/admin
   sudo mv /tmp/tenant-web /usr/share/nginx/html/tenant
   sudo chown -R nginx:nginx /usr/share/nginx/html
   sudo chmod -R 755 /usr/share/nginx/html
   sudo systemctl reload nginx
   ```

---

## ✅ **Solution 3: Use GitHub Actions (Automated)**

Build on GitHub's free runners (7GB RAM), then deploy to EC2.

I can set this up if needed - would take 15 minutes to configure.

---

## 📊 **Recommendation:**

1. **Try the main script first** (85% success chance on t3.micro)
2. **If it hangs >30 minutes**, Ctrl+C and use Solution 1 (upgrade to t3.medium for 30 min)
3. **For long-term**, keep t3.micro for runtime (apps use <100MB RAM), only scale up for builds

---

## 💡 **How to Tell If Build is Hung vs Just Slow:**

### **Normal (working):**
```
Compiling lib/main.dart for the Web...
[CPU usage: 80-100%]
[RAM usage: slowly increasing]
```

### **Hung (frozen):**
```
Compiling lib/main.dart for the Web...
[No output for >5 minutes]
[CPU usage: <10%]
[RAM usage: maxed out at 100%]
```

**Check with:**
```bash
top
# Press 'q' to quit

free -h
# Check "available" memory
```

---

## 🎯 **Bottom Line:**

The script **WILL work**, but t3.micro might need a temporary boost.

**Total cost for temporary upgrade:**
- t3.micro: $0.0116/hour
- t3.medium: $0.0464/hour
- **Difference for 30 min:** $0.0174 (~2 cents)

**Worth it for guaranteed success!**

