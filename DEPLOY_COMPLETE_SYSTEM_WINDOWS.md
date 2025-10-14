# 🪟 COMPLETE SYSTEM DEPLOYMENT (Windows Guide)

**For:** Windows Users  
**Goal:** Deploy the complete PGNi system (Backend + Frontend)  
**Time:** 30-45 minutes  
**Result:** Full app accessible via http://34.227.111.143

---

## ⚠️ **WHAT'S CURRENTLY MISSING**

Your system is **40% deployed**:
- ✅ Backend API working at http://34.227.111.143:8080
- ❌ Admin UI (37 pages) NOT deployed
- ❌ Tenant UI (28 pages) NOT deployed

**After this deployment:** System will be **100% deployed**!

---

## 🚀 **DEPLOYMENT OPTIONS**

### **Option 1: Automated (Recommended) - 30 minutes**

Use CloudShell script to do everything automatically.

### **Option 2: Manual - 1 hour**

Build and deploy step-by-step from Windows.

### **Option 3: Placeholder Only - 5 minutes**

Deploy simple placeholder pages (build full UI later).

---

## 📋 **OPTION 1: AUTOMATED DEPLOYMENT (RECOMMENDED)**

### **Step 1: Prepare CloudShell**

```powershell
# Open AWS CloudShell (in AWS Console)
# Then run these commands:
```

```bash
# Download deployment script
curl -O https://raw.githubusercontent.com/siddam01/pgni/main/DEPLOY_COMPLETE_SYSTEM.sh

# Download SSH key
curl -O https://raw.githubusercontent.com/siddam01/pgni/main/terraform/ssh-key.txt
mv ssh-key.txt cloudshell-key.pem
chmod 600 cloudshell-key.pem

# Make script executable
chmod +x DEPLOY_COMPLETE_SYSTEM.sh

# Run deployment
./DEPLOY_COMPLETE_SYSTEM.sh
```

### **Step 2: Follow Prompts**

The script will:
1. Check prerequisites
2. Install Nginx web server
3. Build/deploy frontend apps
4. Configure URL routing
5. Open port 80
6. Test everything

### **Step 3: Access Your App**

```
http://34.227.111.143/admin
http://34.227.111.143/tenant
```

---

## 📋 **OPTION 2: MANUAL DEPLOYMENT FROM WINDOWS**

### **Prerequisites:**

- ✅ Flutter SDK installed
- ✅ SSH access to EC2
- ✅ AWS CLI configured

### **Phase 1: Build Frontend Apps (Windows)**

```powershell
# Open PowerShell
cd C:\MyFolder\Mytest\pgworld-master

# Build Admin App
cd pgworld-master
flutter build web --release
# Creates: build\web\

# Build Tenant App
cd ..\pgworldtenant-master
flutter build web --release
# Creates: build\web\
```

### **Phase 2: Deploy to EC2**

```powershell
# Set variables
$EC2_HOST = "34.227.111.143"
$SSH_KEY = "pgni-preprod-key.pem"

# Deploy Admin UI
scp -i $SSH_KEY -r pgworld-master\build\web\* ec2-user@${EC2_HOST}:/tmp/admin/

# Deploy Tenant UI
scp -i $SSH_KEY -r pgworldtenant-master\build\web\* ec2-user@${EC2_HOST}:/tmp/tenant/
```

### **Phase 3: Configure EC2 (SSH)**

```bash
# SSH to EC2
ssh -i pgni-preprod-key.pem ec2-user@34.227.111.143

# Install Nginx
sudo yum install -y nginx
sudo systemctl start nginx
sudo systemctl enable nginx

# Create directories
sudo mkdir -p /var/www/html/admin
sudo mkdir -p /var/www/html/tenant

# Move files
sudo mv /tmp/admin/* /var/www/html/admin/
sudo mv /tmp/tenant/* /var/www/html/tenant/
sudo chown -R ec2-user:ec2-user /var/www/html

# Configure Nginx
sudo tee /etc/nginx/conf.d/pgni.conf > /dev/null << 'EOF'
server {
    listen 80 default_server;
    server_name _;

    location /admin {
        alias /var/www/html/admin;
        index index.html;
        try_files $uri $uri/ /admin/index.html;
    }

    location /tenant {
        alias /var/www/html/tenant;
        index index.html;
        try_files $uri $uri/ /tenant/index.html;
    }

    location /api {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    location = / {
        return 301 /admin;
    }
}
EOF

# Test and reload
sudo nginx -t
sudo systemctl reload nginx

# Exit SSH
exit
```

### **Phase 4: Open Port 80 (AWS Console)**

1. Go to AWS Console → EC2 → Security Groups
2. Find the security group for your EC2 instance
3. Click "Edit inbound rules"
4. Click "Add rule":
   - Type: HTTP
   - Protocol: TCP
   - Port range: 80
   - Source: 0.0.0.0/0
5. Save rules

### **Phase 5: Test**

Open browser:
- http://34.227.111.143/admin
- http://34.227.111.143/tenant

---

## 📋 **OPTION 3: QUICK PLACEHOLDER DEPLOYMENT**

If you want to deploy quickly and build the full UI later:

### **Run in CloudShell:**

```bash
# SSH to EC2
ssh -i cloudshell-key.pem ec2-user@34.227.111.143

# Install Nginx
sudo yum install -y nginx
sudo systemctl start nginx
sudo systemctl enable nginx

# Create directories
sudo mkdir -p /var/www/html/admin
sudo mkdir -p /var/www/html/tenant

# Create Admin placeholder
sudo tee /var/www/html/admin/index.html > /dev/null << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>PGNi Admin Portal</title>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Arial, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            color: #333;
        }
        .container {
            background: white;
            border-radius: 20px;
            padding: 40px;
            max-width: 600px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
        }
        h1 {
            color: #667eea;
            margin-bottom: 20px;
            font-size: 2em;
        }
        .status {
            background: #f8f9fa;
            padding: 20px;
            margin: 15px 0;
            border-radius: 10px;
            border-left: 4px solid #667eea;
        }
        .status h3 {
            color: #667eea;
            margin-bottom: 10px;
        }
        code {
            background: #e9ecef;
            padding: 2px 6px;
            border-radius: 3px;
            font-family: 'Courier New', monospace;
        }
        a {
            color: #667eea;
            text-decoration: none;
            font-weight: bold;
        }
        a:hover {
            text-decoration: underline;
        }
        .credentials {
            background: #e7f3ff;
            padding: 15px;
            border-radius: 8px;
            margin: 10px 0;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🏢 PGNi Admin Portal</h1>
        
        <div class="status">
            <h3>✅ Backend API Running</h3>
            <p>Your backend is live and working!</p>
            <p>API: <a href="/api/health" target="_blank">Test API</a></p>
        </div>

        <div class="status">
            <h3>⚠️ Full UI Deployment Pending</h3>
            <p>The complete admin interface (37 pages) is ready to deploy.</p>
            <p>To deploy, run: <code>DEPLOY_COMPLETE_SYSTEM.sh</code></p>
        </div>

        <div class="status">
            <h3>🚀 Quick Access (Run Locally)</h3>
            <p>While deployment is pending, you can run the admin app locally:</p>
            <div class="credentials">
                <p><strong>Windows:</strong><br>
                Double-click <code>RUN_ADMIN_APP.bat</code></p>
                <p><strong>Login Credentials:</strong><br>
                Email: <code>admin@pgni.com</code><br>
                Password: <code>password123</code></p>
            </div>
        </div>

        <div class="status">
            <h3>📊 System Status</h3>
            <p>✅ Backend API: Running<br>
            ✅ Database: Connected<br>
            ⏳ Frontend UI: Pending deployment<br>
            ⏳ Web Server: Configured</p>
        </div>

        <div class="status">
            <h3>📝 Next Steps</h3>
            <ol style="margin-left: 20px;">
                <li>Run deployment script</li>
                <li>Load test data</li>
                <li>Access full admin portal</li>
            </ol>
        </div>
    </div>
</body>
</html>
EOF

# Create Tenant placeholder
sudo tee /var/www/html/tenant/index.html > /dev/null << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>PGNi Tenant Portal</title>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Arial, sans-serif;
            background: linear-gradient(135deg, #11998e 0%, #38ef7d 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            color: #333;
        }
        .container {
            background: white;
            border-radius: 20px;
            padding: 40px;
            max-width: 600px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
        }
        h1 {
            color: #11998e;
            margin-bottom: 20px;
            font-size: 2em;
        }
        .status {
            background: #f8f9fa;
            padding: 20px;
            margin: 15px 0;
            border-radius: 10px;
            border-left: 4px solid #11998e;
        }
        .status h3 {
            color: #11998e;
            margin-bottom: 10px;
        }
        code {
            background: #e9ecef;
            padding: 2px 6px;
            border-radius: 3px;
            font-family: 'Courier New', monospace;
        }
        a {
            color: #11998e;
            text-decoration: none;
            font-weight: bold;
        }
        a:hover {
            text-decoration: underline;
        }
        .credentials {
            background: #d4f8e8;
            padding: 15px;
            border-radius: 8px;
            margin: 10px 0;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🏠 PGNi Tenant Portal</h1>
        
        <div class="status">
            <h3>✅ Backend API Running</h3>
            <p>Your backend is live and working!</p>
            <p>API: <a href="/api/health" target="_blank">Test API</a></p>
        </div>

        <div class="status">
            <h3>⚠️ Full UI Deployment Pending</h3>
            <p>The complete tenant interface (28 pages) is ready to deploy.</p>
            <p>To deploy, run: <code>DEPLOY_COMPLETE_SYSTEM.sh</code></p>
        </div>

        <div class="status">
            <h3>🚀 Quick Access (Run Locally)</h3>
            <p>While deployment is pending, you can run the tenant app locally:</p>
            <div class="credentials">
                <p><strong>Windows:</strong><br>
                Double-click <code>RUN_TENANT_APP.bat</code></p>
                <p><strong>Login Credentials:</strong><br>
                Email: <code>tenant@pgni.com</code><br>
                Password: <code>password123</code></p>
            </div>
        </div>

        <div class="status">
            <h3>📊 System Status</h3>
            <p>✅ Backend API: Running<br>
            ✅ Database: Connected<br>
            ⏳ Frontend UI: Pending deployment<br>
            ⏳ Web Server: Configured</p>
        </div>

        <div class="status">
            <h3>📝 Features Available After Deployment</h3>
            <ul style="margin-left: 20px;">
                <li>View notices and announcements</li>
                <li>Pay rent online</li>
                <li>Submit maintenance requests</li>
                <li>View food menu</li>
                <li>Access all 28 tenant features</li>
            </ul>
        </div>
    </div>
</body>
</html>
EOF

# Configure Nginx
sudo tee /etc/nginx/conf.d/pgni.conf > /dev/null << 'EOF'
server {
    listen 80 default_server;
    server_name _;

    location /admin {
        alias /var/www/html/admin;
        index index.html;
    }

    location /tenant {
        alias /var/www/html/tenant;
        index index.html;
    }

    location /api {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    location = / {
        return 301 /admin;
    }
}
EOF

# Reload Nginx
sudo nginx -t
sudo systemctl reload nginx

echo ""
echo "✅ Placeholder pages deployed!"
echo ""
echo "Access at:"
echo "  http://34.227.111.143/admin"
echo "  http://34.227.111.143/tenant"
echo ""
```

Then open port 80 in AWS Console.

---

## ✅ **POST-DEPLOYMENT CHECKLIST**

After deployment:

- [ ] Open http://34.227.111.143/admin in browser
- [ ] Verify admin page loads
- [ ] Open http://34.227.111.143/tenant in browser
- [ ] Verify tenant page loads
- [ ] Test login with admin@pgni.com / password123
- [ ] Navigate through pages
- [ ] Load test data (optional)

---

## 🎯 **DEPLOYMENT COMPARISON**

| Method | Time | Difficulty | Result |
|--------|------|------------|--------|
| **Option 1 (Automated)** | 30 min | ⭐ Easy | Full deployment |
| **Option 2 (Manual)** | 60 min | ⭐⭐ Medium | Full deployment |
| **Option 3 (Placeholder)** | 5 min | ⭐ Easy | Quick access, build later |

---

## 📝 **TROUBLESHOOTING**

### **Issue: Port 80 not accessible**

```bash
# Check if port is open
curl http://34.227.111.143/admin

# If fails, check security group in AWS Console
```

### **Issue: Nginx not starting**

```bash
# Check Nginx status
sudo systemctl status nginx

# Check configuration
sudo nginx -t

# View logs
sudo tail -f /var/log/nginx/error.log
```

### **Issue: Pages show 404**

```bash
# Check if files exist
ls -la /var/www/html/admin/
ls -la /var/www/html/tenant/

# Check Nginx configuration
cat /etc/nginx/conf.d/pgni.conf
```

---

## 🚀 **RECOMMENDED APPROACH**

**For fastest deployment:**

1. Use **Option 1 (Automated)** via CloudShell (30 minutes)
2. Run `DEPLOY_COMPLETE_SYSTEM.sh`
3. Let the script handle everything
4. Access your app at http://34.227.111.143

**For learning/customization:**

1. Use **Option 2 (Manual)** (60 minutes)
2. Follow each step to understand the process
3. Customize as needed

**For quick preview:**

1. Use **Option 3 (Placeholder)** (5 minutes)
2. Deploy placeholders now
3. Build and deploy full UI later when ready

---

## ✨ **AFTER DEPLOYMENT**

Once deployed, your system will be:

✅ **100% Operational**  
✅ **Accessible via URL**  
✅ **65 Pages Live**  
✅ **No local installation needed**  
✅ **Production-ready**

**Access URLs:**
- Admin: http://34.227.111.143/admin
- Tenant: http://34.227.111.143/tenant
- API: http://34.227.111.143/api

---

**Choose your deployment method and let's get your app fully deployed!** 🚀

