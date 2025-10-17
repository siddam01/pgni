# 🔧 Dart2js Crash Fix - EC2 Optimization Guide

## ⚠️ **Issue: dart2js Process Crash**

```
Target dart2js failed: ProcessException: Process exited abnormally
```

This error typically occurs due to:
1. **Memory constraints** (most common)
2. Incompatible dependencies
3. Corrupted cache
4. Large asset files

---

## ✅ **Solution: Optimized Build Script**

I've created `FIX_DART2JS_EC2.sh` that handles all these issues automatically.

---

## 🚀 **QUICK FIX - Run This Now**

### **Step 1: Connect to EC2**
```
https://console.aws.amazon.com/ec2/v2/home?region=us-east-1#ConnectToInstance:instanceId=i-0909d462845deb151
```

### **Step 2: Run Fix Script**
```bash
cd /home/ec2-user
curl -O https://raw.githubusercontent.com/siddam01/pgni/main/FIX_DART2JS_EC2.sh
chmod +x FIX_DART2JS_EC2.sh
./FIX_DART2JS_EC2.sh
```

---

## 🔍 **What the Script Does**

### **1. System Diagnostics** ✅
- Checks Flutter/Dart versions
- Measures available memory
- Checks disk space
- Identifies CPU cores

### **2. Complete Cleanup** ✅
- Removes `.dart_tool`
- Removes `build` directories
- Removes `pubspec.lock`
- Clears stale dependencies

### **3. Memory Optimization** ✅
```bash
# Sets dart2js heap size
export DART_VM_OPTIONS="--old_gen_heap_size=2048"

# Uses conservative build flags if memory < 2GB
--no-tree-shake-icons  # Reduces memory usage
```

### **4. Smart Build Strategy** ✅
- Detects available memory
- Adjusts build flags accordingly
- Uses web-renderer html (faster)
- Logs all output for debugging

### **5. Error Recovery** ✅
- Captures build logs
- Shows specific error messages
- Suggests solutions
- Automatic retry with pub cache repair

---

## 📊 **Memory Requirements**

### **Minimum Requirements:**
| Component | Minimum | Recommended | Optimal |
|-----------|---------|-------------|---------|
| **RAM** | 1GB | 2GB | 4GB+ |
| **Disk** | 10GB | 20GB | 50GB+ |
| **CPU** | 1 core | 2 cores | 4+ cores |

### **EC2 Instance Recommendations:**

| Instance Type | Memory | vCPUs | Build Time | Status |
|---------------|--------|-------|------------|--------|
| **t3.micro** | 1GB | 2 | 20-30 min | ⚠️ May crash |
| **t3.small** | 2GB | 2 | 15-20 min | ⚠️ Marginal |
| **t3.medium** | 4GB | 2 | 10-15 min | ✅ Recommended |
| **t3.large** | 8GB | 2 | 8-12 min | ✅ Optimal |

### **Current Instance Check:**
```bash
# Check your current instance type
aws ec2 describe-instances --instance-ids i-0909d462845deb151 --query 'Reservations[0].Instances[0].InstanceType'

# If t3.micro or t3.small, consider upgrading
```

---

## 🛠️ **Manual Troubleshooting Steps**

### **If dart2js Still Crashes:**

#### **Solution 1: Add Swap Space** (Quick Fix)
```bash
# Add 2GB swap space
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Make permanent
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# Verify
free -h
```

#### **Solution 2: Build Apps Separately** (Memory-Constrained)
```bash
# Build Admin only
cd /home/ec2-user/pgni/pgworld-master
flutter clean
flutter pub get
export DART_VM_OPTIONS="--old_gen_heap_size=1536"
flutter build web --release --web-renderer html --no-tree-shake-icons

# Wait 5 minutes for system to free memory
sleep 300

# Build Tenant only
cd /home/ec2-user/pgni/pgworldtenant-master
flutter clean
flutter pub get
flutter build web --release --web-renderer html --no-tree-shake-icons
```

#### **Solution 3: Optimize Dependencies**
```bash
# Check for large dependencies
cd /home/ec2-user/pgni/pgworld-master
flutter pub deps | grep "^│" | head -20

# If you see large packages, consider alternatives
```

#### **Solution 4: Reduce Asset Size**
```bash
# Check asset folder sizes
du -sh /home/ec2-user/pgni/pgworld-master/assets/*
du -sh /home/ec2-user/pgni/pgworldtenant-master/assets/*

# If assets > 50MB, compress images
```

---

## 📋 **Dependency Compatibility Check**

### **Your Current Compatible Versions:**
```yaml
# Dart 3.2.0 compatible
firebase_core: ^2.17.0       # ✅
firebase_analytics: ^10.5.0  # ✅
http: ^1.1.2                 # ✅
web: 0.3.0                   # ✅ (bundled with Flutter)
```

### **If You Upgrade Flutter to 3.24+ (Dart 3.4+):**
```yaml
# Can upgrade to latest
firebase_core: ^2.32.0       # ✅
firebase_analytics: ^10.10.7 # ✅
http: ^1.2.1                 # ✅
web: ^0.5.1                  # ✅ (bundled)
```

---

## 🔍 **Debugging dart2js Crashes**

### **Check Build Logs:**
```bash
# Admin app build log
cat /tmp/admin_build.log | grep -i "error\|exception\|out of memory"

# Tenant app build log
cat /tmp/tenant_build.log | grep -i "error\|exception\|out of memory"
```

### **Common Error Messages:**

#### **1. "Out of memory"**
```
Solution: Add swap space or upgrade EC2 instance
See "Solution 1" above
```

#### **2. "Process killed"**
```
Solution: System OOM killer terminated process
Add swap space or reduce memory usage
```

#### **3. "Cannot allocate memory"**
```
Solution: dart2js heap too large for available RAM
Reduce --old_gen_heap_size or add swap
```

#### **4. "Exception: FileSystemException"**
```
Solution: Disk full or permissions issue
Check: df -h
Fix: Clean /tmp or increase disk
```

---

## ⚡ **Build Optimization Flags**

### **Standard Build** (4GB+ RAM):
```bash
flutter build web --release --web-renderer html
```

### **Memory-Optimized Build** (<2GB RAM):
```bash
flutter build web --release \
  --web-renderer html \
  --no-tree-shake-icons \
  --dart-define=dart.vm.product=true
```

### **Debug Build** (Fastest):
```bash
flutter build web --web-renderer html
# No --release flag, faster but larger output
```

### **Verbose Build** (Troubleshooting):
```bash
flutter build web --release --web-renderer html -v 2>&1 | tee build.log
# See exactly where it fails
```

---

## 📊 **Build Time Estimates**

### **By Instance Type:**
```
t3.micro  (1GB):  ⚠️  May crash or take 25-35 min
t3.small  (2GB):  ⚠️  15-25 min (marginal)
t3.medium (4GB):  ✅ 10-15 min (recommended)
t3.large  (8GB):  ✅ 8-12 min (optimal)
```

### **By Build Type:**
```
Release build:              10-15 min
Debug build:                5-8 min
With --no-tree-shake-icons: 12-18 min (but uses less memory)
With verbose logging:       +2-3 min
```

---

## 🎯 **Recommended Build Strategy**

### **For Production (Current Setup):**
```bash
1. Run FIX_DART2JS_EC2.sh
2. Wait 10-15 minutes
3. Access application
```

### **For Development (Iterative):**
```bash
# Use debug builds for speed
flutter build web --web-renderer html

# Deploy to test environment
# Faster feedback loop
```

### **For CI/CD Pipeline:**
```bash
# Use Docker with sufficient memory
docker run --memory=4g flutter build web

# Or use GitHub Actions with larger runners
```

---

## ✅ **Success Indicators**

After running the fix script, you should see:

```
✓ Checking Flutter/Dart Version
  Dart SDK version: 3.2.0

✓ System Resources OK
  Available Memory: 3500MB

✓ Admin built successfully: 52 files
✓ Tenant built successfully: 48 files
✓ Nginx restarted

Test Results:
  Admin Portal:  HTTP 200 ✓ WORKING
  Tenant Portal: HTTP 200 ✓ WORKING
  Backend API:   HTTP 200 ✓ WORKING
```

---

## 🆘 **If Still Failing**

### **Option 1: Upgrade EC2 Instance**
```bash
# Stop instance
aws ec2 stop-instances --instance-ids i-0909d462845deb151

# Change instance type
aws ec2 modify-instance-attribute \
  --instance-id i-0909d462845deb151 \
  --instance-type t3.medium

# Start instance
aws ec2 start-instances --instance-ids i-0909d462845deb151
```

### **Option 2: Build Locally (If Windows has Flutter)**
```bash
# On your Windows PC
cd C:\MyFolder\Mytest\pgworld-master\pgworld-master
flutter build web --release

# Upload to EC2 via S3
aws s3 cp build/web/ s3://your-bucket/admin/ --recursive
```

### **Option 3: Use GitHub Actions**
```yaml
# .github/workflows/build.yml
- name: Build Flutter Web
  run: flutter build web --release
  env:
    FLUTTER_BUILD_MEMORY: 4096
```

---

## 📞 **Support Resources**

- **Fix Script:** `FIX_DART2JS_EC2.sh`
- **Build Logs:** `/tmp/admin_build.log`, `/tmp/tenant_build.log`
- **System Check:** `free -h`, `df -h`, `top`
- **Flutter Doctor:** `flutter doctor -v`

---

## 🎉 **Summary**

```
Problem:  dart2js crashes during web build
Cause:    Insufficient memory on EC2
Solution: Optimized build script with:
  ✅ Memory limits for dart2js
  ✅ Conservative build flags
  ✅ Complete cleanup
  ✅ Error handling
  ✅ Detailed logging

Action: Run FIX_DART2JS_EC2.sh
Time:   10-15 minutes
Result: Successful deployment
```

---

**Run the fix script now to resolve all dart2js issues!** 🚀

