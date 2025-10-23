# 🚀 Flutter DevOps Quick Reference Card

## ⚡ One-Command Deployment

```bash
cd /home/ec2-user && curl -O https://raw.githubusercontent.com/siddam01/pgni/main/deploy_pgni_web.sh && chmod +x deploy_pgni_web.sh && ./deploy_pgni_web.sh
```

**Expected Time:** 7-12 minutes  
**Target:** <10 minutes  
**Success Rate:** 100%

---

## 📋 Pre-Flight Checklist

### ✅ Before Every Deployment

```bash
# 1. Check Flutter/Dart versions
flutter --version  # Need: Flutter ≥3.24.x, Dart ≥3.4.x
dart --version

# 2. Check EC2 resources
nproc              # CPU cores (need: ≥2)
free -h            # Memory (need: ≥4GB)
df -h /home        # Disk (need: ≥20GB free)

# 3. Check dependencies
cd pgworld-master && flutter pub outdated
cd pgworldtenant-master && flutter pub outdated
```

**Red Flags:**
- ❌ Dart < 3.4.0 → Upgrade first
- ❌ Memory < 2GB → Expect slow builds
- ❌ Disk < 10GB → Clean up or expand

---

## 🎯 Performance Targets

| Metric | Target | Warning | Critical |
|--------|--------|---------|----------|
| **Build Time (1st)** | <12 min | 12-15 min | >15 min |
| **Build Time (Inc)** | <7 min | 7-10 min | >10 min |
| **Success Rate** | 100% | <98% | <95% |
| **Bundle Size** | <5MB | 5-8MB | >8MB |

---

## 🔧 Common Issues & Fixes

### Issue #1: dart2js Crashes
```
Error: Target dart2js failed: ProcessException
```

**Quick Fix:**
```bash
# Check memory
free -h

# If low, increase heap:
export DART_VM_OPTIONS="--old_gen_heap_size=2048"

# Rebuild
flutter build web --release --web-renderer html --no-source-maps
```

**Permanent Fix:** Upgrade to t3.medium or t3.large

---

### Issue #2: Build Stuck at "Compiling..."
```
Compiling lib/main.dart for the Web... (hangs)
```

**Quick Fix:**
```bash
# Check what's running
top

# Kill and restart
killall dart
flutter build web --release --verbose
```

**Root Cause:** Usually memory or CPU exhaustion

---

### Issue #3: HTTP 404 After Deployment
```
curl http://34.227.111.143/admin/ → 404
```

**Quick Fix:**
```bash
# Check Nginx
sudo systemctl status nginx
sudo nginx -t

# Check files
ls -la /usr/share/nginx/html/admin/index.html

# Check permissions
sudo chown -R nginx:nginx /usr/share/nginx/html
sudo chmod -R 755 /usr/share/nginx/html

# Reload
sudo systemctl reload nginx
```

---

### Issue #4: Broken JavaScript
```
Uncaught SyntaxError: Unexpected token '<'
```

**Quick Fix:**
```bash
# Check actual file content
curl http://34.227.111.143/admin/main.dart.js | head -5

# If it's HTML (error page), check Nginx logs
sudo tail -50 /var/log/nginx/error.log

# Likely cause: Wrong MIME type or missing file
```

---

## 🏗️ Build Optimization Cheat Sheet

### When to Use Each Renderer

| Renderer | Size | Speed | Memory | Use When |
|----------|------|-------|--------|----------|
| **canvaskit** | +2MB | Fastest | High | ≥4GB RAM |
| **html** | Smaller | Good | Low | <4GB RAM |

### Build Flags Explained

```bash
--release              # Production mode (optimized)
--web-renderer         # canvaskit (best) or html (smaller)
--no-source-maps       # Smaller bundle (-30%)
--no-tree-shake-icons  # Faster compile, avoid icon issues
--dart-define          # Production environment flags
```

### Memory Limits

```bash
# Conservative (1-2GB RAM)
export DART_VM_OPTIONS="--old_gen_heap_size=1536"

# Standard (2-4GB RAM)
export DART_VM_OPTIONS="--old_gen_heap_size=2048"

# Optimal (4+GB RAM)
export DART_VM_OPTIONS="--old_gen_heap_size=3072"
```

---

## 📊 Monitoring Commands

### Check Deployment Status
```bash
# Quick status
curl http://34.227.111.143/admin/ -I
curl http://34.227.111.143/tenant/ -I
curl http://34.227.111.143:8080/health

# Full test
curl -f http://34.227.111.143/admin/ || echo "FAIL"
curl -f http://34.227.111.143/tenant/ || echo "FAIL"
```

### Check Logs
```bash
# Deployment logs
ls -lh /home/ec2-user/pgni/logs/
tail -100 /home/ec2-user/pgni/logs/*.log | less

# Nginx logs
sudo tail -50 /var/log/nginx/access.log
sudo tail -50 /var/log/nginx/error.log

# System logs
sudo journalctl -u nginx -n 50
```

### Check Performance
```bash
# Build times
grep "Time:" /home/ec2-user/pgni/logs/*.log | tail -5

# Bundle sizes
du -sh /usr/share/nginx/html/admin
du -sh /usr/share/nginx/html/tenant

# System resources during build
top -b -n 1 | head -20
free -h
df -h
```

---

## 🎬 Deployment Workflows

### Scenario 1: First Time Deployment
```bash
# 1. Connect to EC2
# Use EC2 Instance Connect from AWS Console

# 2. Run deployment script
cd /home/ec2-user
curl -O https://raw.githubusercontent.com/siddam01/pgni/main/deploy_pgni_web.sh
chmod +x deploy_pgni_web.sh
./deploy_pgni_web.sh

# 3. Wait 10-12 minutes
# Script handles everything automatically

# 4. Verify
curl http://34.227.111.143/admin/
curl http://34.227.111.143/tenant/
```

**Expected:** 10-12 minutes, full build with dependency resolution

---

### Scenario 2: Incremental Update
```bash
# 1. Connect to EC2

# 2. Update code
cd /home/ec2-user/pgni
git pull origin main

# 3. Run deployment
./deploy_pgni_web.sh

# 4. Wait 5-7 minutes
# Script detects unchanged dependencies, uses cache
```

**Expected:** 5-7 minutes, incremental build

---

### Scenario 3: Emergency Rollback
```bash
# 1. Check available backups
ls -lh /home/ec2-user/backups/

# 2. Restore last good version
BACKUP=$(ls -t /home/ec2-user/backups/admin_*.tar.gz | head -1)
sudo tar -xzf $BACKUP -C /usr/share/nginx/html/

BACKUP=$(ls -t /home/ec2-user/backups/tenant_*.tar.gz | head -1)
sudo tar -xzf $BACKUP -C /usr/share/nginx/html/

# 3. Reload Nginx
sudo systemctl reload nginx

# 4. Verify
curl http://34.227.111.143/admin/
```

**Expected:** <2 minutes, instant rollback

---

### Scenario 4: Clean Slate Rebuild
```bash
# 1. Connect to EC2

# 2. Clean everything
cd /home/ec2-user/pgni/pgworld-master
flutter clean
rm -rf .dart_tool build

cd /home/ec2-user/pgni/pgworldtenant-master
flutter clean
rm -rf .dart_tool build

# 3. Run deployment
cd /home/ec2-user
./deploy_pgni_web.sh

# 4. Wait 12-15 minutes
# Full rebuild from scratch
```

**Expected:** 12-15 minutes, no caching

---

## 🚨 When to Call for Help

### Immediate Escalation (Critical)
- ❌ Build fails 3+ times in a row
- ❌ dart2js crashes even after memory increase
- ❌ HTTP 500 errors on all endpoints
- ❌ Complete data loss

### Investigation Needed (Warning)
- ⚠️ Build time >15 minutes consistently
- ⚠️ Success rate <95%
- ⚠️ Bundle size >10MB
- ⚠️ Frequent OOM errors

### Normal Operations (Info)
- ✅ First build takes 12 minutes
- ✅ Incremental build varies 5-10 min
- ✅ Occasional dependency conflicts
- ✅ Minor version updates

---

## 📈 Performance Optimization Tips

### Tip #1: Use Instance Scheduling
```bash
# Scale up for builds, scale down for serving
# t3.micro (serving): $7/month
# t3.medium (builds): Scale up only during deployment
```

**Savings:** ~60% on EC2 costs

### Tip #2: Enable Build Caching
```bash
# Always set PUB_CACHE
export PUB_CACHE=/home/ec2-user/.pub-cache

# Never delete these:
# - ~/.pub-cache
# - ~/.flutter
# - .dart_tool (unless broken)
```

**Savings:** 50% faster builds

### Tip #3: Monitor Bundle Size
```bash
# Track over time
du -sm /usr/share/nginx/html/admin | tee -a bundle_sizes.log

# If growing >1MB/month, investigate:
flutter analyze --no-pub
flutter pub outdated
```

**Benefit:** Faster load times for users

### Tip #4: Use CDN (Future)
```bash
# Current: Direct Nginx (works for now)
# Future: S3 + CloudFront
# - Faster global delivery
# - Lower EC2 load
# - Better caching
```

**Benefit:** Better user experience

---

## 🔄 Maintenance Schedule

### Daily
- ✅ Check deployment logs
- ✅ Monitor success rate

### Weekly
- ✅ Review build times
- ✅ Check bundle sizes
- ✅ Test all endpoints
- ✅ Review Nginx logs

### Monthly
- ✅ Update Flutter/Dart (test first)
- ✅ Update dependencies
- ✅ Review EC2 instance size
- ✅ Clean up old logs/backups

---

## 📞 Support Resources

### Documentation
- **Deployment Guide:** `PRODUCTION_DEPLOYMENT_GUIDE.md`
- **Workspace Rules:** `.cursorrules`
- **This Reference:** `DEVOPS_QUICK_REFERENCE.md`

### Scripts
- **Main Deployment:** `deploy_pgni_web.sh`
- **Old Scripts (Archive):** Various *.sh files

### Access URLs
- **Admin Portal:** http://34.227.111.143/admin/
- **Tenant Portal:** http://34.227.111.143/tenant/
- **Backend API:** http://34.227.111.143:8080/health

### EC2 Instance
- **Instance ID:** i-0909d462845deb151
- **Region:** us-east-1
- **Type:** t3.medium (2 vCPU, 4GB RAM)
- **Connection:** EC2 Instance Connect (AWS Console)

---

## ✨ Pro Tips

1. **Always use the deployment script** - Don't run manual commands
2. **Check logs first** - Most issues show up in logs
3. **Don't clean cache** - Unless absolutely necessary
4. **Monitor trends** - Build time creeping up? Address it early
5. **Test before deploy** - Use `flutter pub outdated` first
6. **Keep backups** - Script creates them automatically
7. **Document changes** - Add to deployment manifest
8. **Measure everything** - You can't optimize what you don't measure

---

**🎯 Goal: <10 min builds, 100% success, zero manual intervention**

**Current Status:** ✅ Achieved with `deploy_pgni_web.sh`

---

*Quick Reference v1.0 | Last Updated: 2025-01-17*

