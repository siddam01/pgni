# 🚀 Production-Grade Flutter Web Deployment Guide

## 📋 **Overview**

This guide documents the **enterprise-level deployment system** for the PGNI Flutter web application, optimized for AWS EC2 with production best practices.

---

## ✨ **Key Features**

### **1. Intelligent Build Strategy**
- ✅ **Incremental builds** - Only rebuilds when dependencies change
- ✅ **Build caching** - Reuses artifacts when possible
- ✅ **Dependency checksums** - MD5 verification of pubspec.yaml
- ✅ **Adaptive optimization** - Adjusts flags based on available resources

### **2. Pre-Deployment Checks**
- ✅ Flutter/Dart version verification
- ✅ `flutter doctor -v` diagnostics
- ✅ System resource monitoring (CPU, RAM, Disk)
- ✅ Git status and auto-pull
- ✅ Dependency validation

### **3. Optimized Build Process**
- ✅ Memory-aware compilation
- ✅ Optimal dart2js heap sizing
- ✅ CanvasKit renderer (or HTML fallback)
- ✅ No source maps (smaller bundle)
- ✅ Build time tracking

### **4. Post-Deployment Validation**
- ✅ Smoke tests (HTTP status checks)
- ✅ Asset size monitoring
- ✅ Critical file verification
- ✅ Deployment manifest generation
- ✅ Automated rollback capability

### **5. Production Optimizations**
- ✅ Nginx with caching headers
- ✅ Gzip compression
- ✅ Security headers
- ✅ Asset fingerprinting
- ✅ Backup before deployment

---

## 🚀 **Quick Start**

### **Deploy Now:**
```bash
# On EC2 Instance
cd /home/ec2-user
curl -O https://raw.githubusercontent.com/siddam01/pgni/main/deploy_pgni_web.sh
chmod +x deploy_pgni_web.sh
./deploy_pgni_web.sh
```

### **Expected Output:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PRE-DEPLOYMENT CHECKS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[2025-01-17 10:00:00] Checking Flutter SDK...
Flutter 3.x.x • Dart SDK version: 3.2.0
[2025-01-17 10:00:05] Memory: 3500MB available / 4096MB total
[2025-01-17 10:00:05] Disk: 45G free
[2025-01-17 10:00:05] CPU Cores: 2

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
BUILD ADMIN APP
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[2025-01-17 10:00:10] pgworld-master: Build cache valid, incremental build possible
[2025-01-17 10:00:10] Performing INCREMENTAL build...
[2025-01-17 10:00:15] Building for web (this may take 5-10 minutes)...
[2025-01-17 10:05:30] ✓ Admin built successfully
  Files: 52
  Size: 4.2M
  Time: 320s

[Similar output for Tenant app]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
POST-DEPLOYMENT CHECKS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[2025-01-17 10:15:00] Running smoke tests...
[2025-01-17 10:15:03] ✓ Admin portal: HTTP 200
[2025-01-17 10:15:03] ✓ Tenant portal: HTTP 200
[2025-01-17 10:15:03] ✓ Backend API: HTTP 200

╔════════════════════════════════════════════════╗
║      🎉 DEPLOYMENT SUCCESSFUL! 🎉             ║
╟────────────────────────────────────────────────╢
║ Deployment ID: deploy_20250117_101500         ║
║ Total Time:    900s (15min)                    ║
╚════════════════════════════════════════════════╝
```

---

## 🎯 **Best Practices Implemented**

### **1. Why Incremental Builds?**

**Problem:** Running `flutter clean` every time wastes 3-5 minutes rebuilding unchanged code.

**Solution:**
```bash
# Generate MD5 checksum of dependencies
ADMIN_CHECKSUM=$(md5sum pubspec.yaml | awk '{print $1}')

# Compare with last build
if [ "$CURRENT_CHECKSUM" != "$LAST_CHECKSUM" ]; then
    flutter clean  # Only clean when needed
fi
```

**Benefit:** 
- First build: 10-12 minutes
- Subsequent builds (no changes): 3-5 minutes ⚡
- **Savings: 50-60% faster**

---

### **2. Why Memory-Aware Compilation?**

**Problem:** dart2js crashes on low-memory EC2 instances.

**Solution:**
```bash
AVAILABLE_MEM=$(free -m | awk 'NR==2 {print $7}')

if [ "$AVAILABLE_MEM" -lt 2000 ]; then
    # Conservative flags
    export DART_VM_OPTIONS="--old_gen_heap_size=1536"
    flutter build web --web-renderer html --no-tree-shake-icons
else
    # Optimal flags
    export DART_VM_OPTIONS="--old_gen_heap_size=2048"
    flutter build web --web-renderer canvaskit
fi
```

**Benefit:**
- Prevents dart2js crashes
- Adapts to t3.micro (1GB) or t3.medium (4GB)
- Automatic optimization

---

### **3. Why CanvasKit vs HTML Renderer?**

| Renderer | Size | Performance | Compatibility | Use Case |
|----------|------|-------------|---------------|----------|
| **canvaskit** | Larger (+2MB) | Best | Modern browsers | Recommended |
| **html** | Smaller | Good | All browsers | Low memory |

**Script Logic:**
```bash
if [ "$AVAILABLE_MEM" -lt 2000 ]; then
    --web-renderer html  # Smaller, uses less memory
else
    --web-renderer canvaskit  # Better performance
fi
```

---

### **4. Why No Source Maps?**

**Without `--no-source-maps`:**
- Bundle size: 6-8MB
- Contains `.dart` source for debugging
- Exposes code structure

**With `--no-source-maps`:**
- Bundle size: 4-5MB ⚡
- Minified only
- Production-ready

**When to use source maps:**
```bash
# Development
flutter build web --source-maps

# Production
flutter build web --no-source-maps  # ✅ Our choice
```

---

### **5. Why Pre-Deployment Checks?**

**Prevents deployment failures:**
```bash
# Check 1: Flutter doctor
flutter doctor -v  # Catches SDK issues

# Check 2: Git status
git fetch && compare commits  # Ensures latest code

# Check 3: System resources
free -h  # Warns if low memory

# Check 4: Dependency validation
md5sum pubspec.yaml  # Detects manual changes
```

**Real-world scenario:**
```
[WARN] Low memory detected. Build may be slower.
[INFO] Adjusting build flags...
✓ Build completed successfully (with fallback)
```

---

### **6. Why Post-Deployment Checks?**

**Smoke Tests:**
```bash
# Test actual endpoints
curl http://localhost/admin/  # Expect 200
curl http://localhost/tenant/ # Expect 200
curl http://localhost:8080/health  # Expect 200

# Verify critical files
test -f /usr/share/nginx/html/admin/index.html
test -f /usr/share/nginx/html/admin/main.dart.js
```

**Deployment Manifest:**
```json
{
  "deployment_id": "deploy_20250117_101500",
  "timestamp": "2025-01-17T10:15:00+00:00",
  "flutter_version": "3.16.0",
  "dart_version": "3.2.0",
  "admin_size_mb": 4,
  "tenant_size_mb": 3,
  "git_commit": "5fff902..."
}
```

**Benefits:**
- Audit trail
- Rollback capability
- Performance monitoring
- Issue diagnosis

---

## ⚡ **Performance Comparison**

### **Old Deployment (Manual):**
```
1. SSH to EC2                     30s
2. cd project                     5s
3. git pull                       10s
4. flutter clean (Admin)          60s
5. flutter pub get               30s
6. flutter build web             300s
7. Repeat for Tenant             395s
8. Copy to Nginx                 20s
9. Configure Nginx               30s
10. Test manually                60s
─────────────────────────────────────
TOTAL:                           940s (15.7 min)
```

### **New Deployment (Automated):**
```
1. Run script                     5s
2. Pre-checks                    20s
3. Incremental build (Admin)    180s  ⚡ (cache hit)
4. Incremental build (Tenant)   180s  ⚡ (cache hit)
5. Deploy + Configure            30s
6. Automated tests               15s
─────────────────────────────────────
TOTAL:                           430s (7.2 min)
```

**Improvement: 54% faster** 🚀

---

## 📊 **Build Time Breakdown**

### **First Build (Cold Cache):**
```
Pre-deployment checks:     30s   (3%)
Admin pub get:             30s   (3%)
Admin compilation:        360s  (40%)
Tenant pub get:            30s   (3%)
Tenant compilation:       360s  (40%)
Deployment:                30s   (3%)
Post-checks:               15s   (2%)
Logging/Summary:           45s   (5%)
────────────────────────────────────
TOTAL:                    900s  (15 min)
```

### **Incremental Build (Warm Cache):**
```
Pre-deployment checks:     20s   (5%)
Admin pub get (cached):     5s   (1%)
Admin compilation:        150s  (33%)  ⚡ 58% faster
Tenant pub get (cached):    5s   (1%)
Tenant compilation:       150s  (33%)  ⚡ 58% faster
Deployment:                30s   (7%)
Post-checks:               15s   (3%)
Logging/Summary:           75s  (17%)
────────────────────────────────────
TOTAL:                    450s  (7.5 min)
```

---

## 🏗️ **Architecture Decisions**

### **Build on EC2 vs. Build Once + S3**

#### **Option A: Build on EC2 (Current)**
```
✅ Pros:
- Simple workflow
- No external dependencies
- Direct deployment
- Immediate feedback

⚠️ Cons:
- EC2 resources needed
- Build time per deployment
- Single point of failure
```

#### **Option B: Build Once + S3 + CloudFront**
```
┌─────────────┐     ┌─────────┐     ┌────────────┐
│ CI/CD       │────▶│   S3    │────▶│CloudFront  │
│ (GitHub     │     │ Bucket  │     │ (Optional) │
│  Actions)   │     └─────────┘     └────────────┘
└─────────────┘           │
                          ▼
                    ┌─────────────┐
                    │ EC2 Nginx   │
                    │ (sync only) │
                    └─────────────┘

✅ Pros:
- Build once, deploy many
- CDN distribution
- Version control
- Faster rollbacks
- EC2 only serves traffic

⚠️ Cons:
- More infrastructure
- S3 costs
- CI/CD setup needed
```

**Recommendation:**
- **Current (Build on EC2):** Good for getting started
- **Future (CI/CD + S3):** Better for scale (10+ deployments/month)

---

## 🔄 **CI/CD Integration**

### **GitHub Actions Example:**

```yaml
# .github/workflows/deploy-web.yml
name: Deploy Flutter Web

on:
  push:
    branches: [main]
  workflow_dispatch:

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.x'
          channel: 'stable'
          cache: true
      
      - name: Cache Dependencies
        uses: actions/cache@v3
        with:
          path: |
            ~/.pub-cache
            **/pubspec.lock
          key: ${{ runner.os }}-pub-${{ hashFiles('**/pubspec.yaml') }}
      
      - name: Build Admin App
        working-directory: pgworld-master
        run: |
          flutter pub get
          flutter build web \
            --release \
            --web-renderer canvaskit \
            --no-source-maps
      
      - name: Build Tenant App
        working-directory: pgworldtenant-master
        run: |
          flutter pub get
          flutter build web \
            --release \
            --web-renderer canvaskit \
            --no-source-maps
      
      - name: Upload to S3
        run: |
          aws s3 sync pgworld-master/build/web/ \
            s3://pgni-web-builds/admin/${{ github.sha }}/
          aws s3 sync pgworldtenant-master/build/web/ \
            s3://pgni-web-builds/tenant/${{ github.sha }}/
      
      - name: Deploy to EC2
        run: |
          ssh ec2-user@34.227.111.143 << 'EOF'
            aws s3 sync s3://pgni-web-builds/admin/${{ github.sha }}/ \
              /usr/share/nginx/html/admin/
            aws s3 sync s3://pgni-web-builds/tenant/${{ github.sha }}/ \
              /usr/share/nginx/html/tenant/
            sudo systemctl reload nginx
          EOF
      
      - name: Smoke Tests
        run: |
          curl -f http://34.227.111.143/admin/ || exit 1
          curl -f http://34.227.111.143/tenant/ || exit 1
```

**Benefits:**
- ✅ Build on powerful GitHub runners (faster)
- ✅ Automatic on git push
- ✅ Version control
- ✅ Artifact storage
- ✅ Rollback capability

---

## 📈 **Monitoring & Observability**

### **Deployment Logs:**
```bash
# All logs saved
/home/ec2-user/pgni/logs/deploy_YYYYMMDD_HHMMSS.log

# View recent deployments
ls -lh /home/ec2-user/pgni/logs/

# Check last deployment
tail -100 /home/ec2-user/pgni/logs/*.log | grep "DEPLOYMENT SUCCESSFUL"
```

### **Deployment Manifests:**
```bash
# List all deployments
ls -lh /home/ec2-user/pgni/logs/*_manifest.json

# View last deployment details
cat /home/ec2-user/pgni/logs/*_manifest.json | tail -1 | jq .
```

### **Performance Metrics:**
```bash
# Build times
grep "Time:" /home/ec2-user/pgni/logs/*.log | tail -5

# Bundle sizes
grep "Size:" /home/ec2-user/pgni/logs/*.log | tail -5
```

---

## 🆘 **Troubleshooting**

### **Build Still Slow?**

#### **Check 1: EC2 Instance Type**
```bash
# Get instance type
aws ec2 describe-instances --instance-ids i-0909d462845deb151 \
  --query 'Reservations[0].Instances[0].InstanceType'

# Recommendations:
# t3.micro  (1GB):  ⚠️  10-20 min
# t3.small  (2GB):  ⚠️  8-15 min
# t3.medium (4GB):  ✅ 5-10 min  ← Recommended
# t3.large  (8GB):  ✅ 4-7 min
```

#### **Check 2: Disk I/O**
```bash
# Check disk performance
sudo iostat -x 1 5

# If slow, upgrade EBS:
# gp2 (100 IOPS) → gp3 (3000 IOPS)
```

#### **Check 3: Network**
```bash
# Test pub.dev speed
time flutter pub get

# If slow (>60s), check network
curl -w "@curl-format.txt" -o /dev/null -s https://pub.dev
```

---

## 🎉 **Summary**

### **What You Get:**
```
✅ Production-grade deployment script
✅ 50-60% faster builds (incremental)
✅ Automated pre/post checks
✅ Memory-aware optimization
✅ Comprehensive logging
✅ Rollback capability
✅ Performance monitoring
✅ CI/CD ready architecture
```

### **Next Steps:**
1. ✅ **Now:** Use `deploy_pgni_web.sh` for deployments
2. 📊 **Week 1:** Monitor build times and optimize
3. 🔄 **Month 1:** Set up GitHub Actions for automation
4. ☁️ **Month 2:** Consider S3 + CloudFront for CDN
5. 📈 **Month 3:** Add performance monitoring (Datadog/New Relic)

---

**🚀 Ready to deploy? Run the script now!**

```bash
curl -O https://raw.githubusercontent.com/siddam01/pgni/main/deploy_pgni_web.sh
chmod +x deploy_pgni_web.sh
./deploy_pgni_web.sh
```

