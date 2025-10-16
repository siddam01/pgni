# Final Complete Deployment Guide

## Current Status
- ❌ Flutter apps NOT built
- ❌ Admin/Tenant folders EMPTY
- ❌ Backend API NOT running
- ✅ Nginx installed but serving empty directories

## Solution: Deploy via EC2 Instance Connect

Since SSM commands are having issues, use EC2 Instance Connect (browser-based SSH):

---

## 🚀 STEP-BY-STEP DEPLOYMENT

### **Step 1: Connect to EC2**

1. Go to **AWS Console** → https://console.aws.amazon.com
2. Navigate to **EC2** → **Instances**
3. Select instance: `i-0909d462845deb151` (pgni-preprod-api)
4. Click **Connect** button
5. Choose **EC2 Instance Connect** tab
6. Click **Connect** button
7. A new browser window opens with terminal

### **Step 2: Copy & Paste This Script**

Once connected, copy this ENTIRE script and paste into the terminal:

```bash
#!/bin/bash
set -e

echo "=============================================="
echo "  PGNi Complete Deployment"
echo "=============================================="
echo ""

cd /home/ec2-user

echo "=== 1/6: Installing Prerequisites ==="
sudo yum update -y
sudo yum install -y git wget curl unzip nginx
echo "✓ Prerequisites installed"
echo ""

echo "=== 2/6: Installing Flutter SDK ==="
if [ ! -d flutter ]; then
    echo "Downloading Flutter SDK (this takes 5-10 minutes)..."
    wget -q https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.16.0-stable.tar.xz
    echo "Extracting..."
    tar xf flutter_linux_3.16.0-stable.tar.xz
    rm -f flutter_linux_3.16.0-stable.tar.xz
    echo "✓ Flutter SDK installed"
else
    echo "✓ Flutter SDK already installed"
fi
export PATH="$PATH:/home/ec2-user/flutter/bin"
flutter --version
echo ""

echo "=== 3/6: Cloning Source Code ==="
if [ -d pgni ]; then
    echo "Updating existing code..."
    cd pgni && git pull && cd ..
else
    echo "Cloning repository..."
    git clone https://github.com/siddam01/pgni.git
fi
echo "✓ Source code ready"
echo ""

echo "=== 4/6: Building Flutter Apps (this takes 5-10 minutes) ==="

echo "Building Admin App..."
cd /home/ec2-user/pgni/pgworld-master
sed -i 's|static const URL = ".*"|static const URL = "34.227.111.143:8080"|' lib/utils/config.dart
flutter clean
flutter pub get
flutter build web --release
echo "✓ Admin app built: $(du -sh build/web | cut -f1)"
echo ""

echo "Building Tenant App..."
cd /home/ec2-user/pgni/pgworldtenant-master
sed -i 's|static const URL = ".*"|static const URL = "34.227.111.143:8080"|' lib/utils/config.dart
flutter clean
flutter pub get
flutter build web --release
echo "✓ Tenant app built: $(du -sh build/web | cut -f1)"
echo ""

echo "=== 5/6: Deploying to Nginx ==="
echo "Cleaning old files..."
sudo rm -rf /usr/share/nginx/html/admin/*
sudo rm -rf /usr/share/nginx/html/tenant/*

echo "Creating directories..."
sudo mkdir -p /usr/share/nginx/html/admin
sudo mkdir -p /usr/share/nginx/html/tenant

echo "Copying Admin app..."
sudo cp -r /home/ec2-user/pgni/pgworld-master/build/web/* /usr/share/nginx/html/admin/

echo "Copying Tenant app..."
sudo cp -r /home/ec2-user/pgni/pgworldtenant-master/build/web/* /usr/share/nginx/html/tenant/

echo "Setting permissions..."
sudo chown -R nginx:nginx /usr/share/nginx/html
sudo chmod -R 755 /usr/share/nginx/html

echo "✓ Files deployed"
echo "  Admin files: $(ls /usr/share/nginx/html/admin/ | wc -l) files"
echo "  Tenant files: $(ls /usr/share/nginx/html/tenant/ | wc -l) files"
echo ""

echo "=== 6/6: Configuring Nginx ==="
sudo tee /etc/nginx/conf.d/pgni.conf > /dev/null << 'EOF'
server {
    listen 80;
    server_name _;
    
    location = / {
        return 301 /admin/;
    }
    
    location /admin/ {
        alias /usr/share/nginx/html/admin/;
        index index.html;
        try_files $uri $uri/ /admin/index.html;
        add_header Cache-Control "no-cache, no-store, must-revalidate";
    }
    
    location /tenant/ {
        alias /usr/share/nginx/html/tenant/;
        index index.html;
        try_files $uri $uri/ /tenant/index.html;
        add_header Cache-Control "no-cache, no-store, must-revalidate";
    }
    
    location /api/ {
        proxy_pass http://localhost:8080/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
    
    location /health {
        proxy_pass http://localhost:8080/health;
    }
}
EOF

echo "Testing Nginx config..."
sudo nginx -t

echo "Restarting Nginx..."
sudo systemctl enable nginx
sudo systemctl restart nginx

echo ""
echo "=============================================="
echo "  ✓ DEPLOYMENT COMPLETE!"
echo "=============================================="
echo ""
echo "Access your application:"
echo "  Admin Portal:  http://34.227.111.143/admin/"
echo "  Tenant Portal: http://34.227.111.143/tenant/"
echo ""
echo "Test Accounts:"
echo "  Super Admin: admin@pgworld.com / Admin@123"
echo "  PG Owner:    owner@pg.com / Owner@123"
echo "  Tenant:      tenant@pg.com / Tenant@123"
echo ""
echo "Verify deployment:"
echo "  Admin files: $(ls -1 /usr/share/nginx/html/admin/ | head -5)"
echo "  Tenant files: $(ls -1 /usr/share/nginx/html/tenant/ | head -5)"
echo ""
```

### **Step 3: Press Enter**

The script will run and show progress for each phase.

### **Step 4: Wait 15-20 Minutes**

You'll see output like:
```
=== 1/6: Installing Prerequisites ===
✓ Prerequisites installed

=== 2/6: Installing Flutter SDK ===
Downloading Flutter SDK (this takes 5-10 minutes)...
...
```

### **Step 5: Test When Complete**

Open in your browser:
- http://34.227.111.143/admin/
- http://34.227.111.143/tenant/

Both should show the actual Flutter apps, NOT 500 errors!

---

## ⏱️ Timeline

| Phase | Duration | What Happens |
|-------|----------|--------------|
| 1. Prerequisites | 2 min | Install system packages |
| 2. Flutter SDK | 8 min | Download & extract Flutter |
| 3. Clone Code | 1 min | Get source from GitHub |
| 4. Build Apps | 8 min | Compile Admin + Tenant |
| 5. Deploy | 1 min | Copy to Nginx |
| 6. Configure | 1 min | Setup Nginx |
| **TOTAL** | **~20 min** | Full deployment |

---

## 🔍 Troubleshooting

### If Flutter Download is Slow
It's normal - Flutter SDK is ~1GB. Just wait patiently.

### If Build Fails
```bash
# Check disk space
df -h

# Check Flutter
flutter doctor -v
```

### If Still Getting 500 Error
```bash
# Check Nginx logs
sudo tail -50 /var/log/nginx/error.log

# Check if files exist
ls -la /usr/share/nginx/html/admin/
ls -la /usr/share/nginx/html/tenant/

# Restart Nginx
sudo systemctl restart nginx
```

---

## ✅ Success Criteria

After deployment, you should see:
- ✅ Admin portal loads (not 500 error)
- ✅ Tenant portal loads (not 500 error)
- ✅ Login page visible with forms
- ✅ Can enter credentials
- ✅ Files exist in /usr/share/nginx/html/

---

## 📞 Alternative: Local PC to EC2

If EC2 Instance Connect doesn't work, you can also:

1. **Use CloudShell with working SSH key**
2. **Use Session Manager from CloudShell:**
   ```bash
   aws ssm start-session --target i-0909d462845deb151 --region us-east-1
   ```

---

**Recommended: Use EC2 Instance Connect (browser-based) - it's the easiest!**

1. AWS Console → EC2 → Instances
2. Select instance → Connect
3. EC2 Instance Connect → Connect
4. Paste the script above
5. Wait 20 minutes
6. Test the URLs!

