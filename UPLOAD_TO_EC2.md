# 📤 Upload Clean Build Files to EC2

## 🚨 **PROBLEM: Placeholders Still Showing**

The EC2 server is running, but the deployed files contain placeholder messages.

**Root Cause:** The build files that were deployed to EC2 contain placeholders from an old build.

---

## ✅ **SOLUTION: Upload Clean Build from Windows**

You have clean build files on your Windows machine. Upload them to EC2.

---

## 📦 **STEP 1: Locate Your Clean Build (Windows)**

Your clean admin build is here:
```
C:\MyFolder\Mytest\pgworld-master\deployment-admin-20251027-213037\admin\
```

**Verify it's clean locally:**
```powershell
# In PowerShell (Windows)
cd C:\MyFolder\Mytest\pgworld-master

# Check for placeholders
Select-String -Path "deployment-admin-20251027-213037\admin\*.js" -Pattern "minimal working version"

# Should show: NO MATCHES
```

---

## 🚀 **STEP 2: Upload via WinSCP (Recommended)**

### **Method A: GUI Upload**

1. **Open WinSCP**
2. **Connect:**
   - Host: `54.227.101.30`
   - User: `ec2-user`
   - Use your SSH key
3. **Navigate:**
   - Left (Windows): `C:\MyFolder\Mytest\pgworld-master\deployment-admin-20251027-213037\admin\`
   - Right (EC2): `/tmp/clean-admin/`
4. **Upload:** Drag all files from left to right
5. **In WinSCP Terminal** (Ctrl+T):
   ```bash
   # Deploy the uploaded files
   sudo rm -rf /var/www/html/admin
   sudo mkdir -p /var/www/html/admin
   sudo cp -r /tmp/clean-admin/* /var/www/html/admin/
   sudo chmod -R 755 /var/www/html/admin
   sudo chown -R nginx:nginx /var/www/html/admin
   sudo systemctl restart nginx
   
   # Verify no placeholders
   grep -r "minimal working version" /var/www/html/admin/*.js || echo "Clean!"
   ```

---

## 💻 **STEP 3: Alternative - SCP Command (PowerShell)**

If you have SSH configured:

```powershell
# On Windows PowerShell
scp -i "path\to\your-key.pem" -r deployment-admin-20251027-213037\admin\* ec2-user@54.227.101.30:/tmp/clean-admin/
```

Then on EC2:
```bash
sudo rm -rf /var/www/html/admin
sudo mkdir -p /var/www/html/admin
sudo cp -r /tmp/clean-admin/* /var/www/html/admin/
sudo chmod -R 755 /var/www/html/admin
sudo chown -R nginx:nginx /var/www/html/admin
sudo systemctl restart nginx
```

---

## 🔍 **STEP 4: Verify on EC2**

Run the verification script:

```bash
# On EC2
cd ~/pgni-main
chmod +x VERIFY_AND_REDEPLOY.sh
./VERIFY_AND_REDEPLOY.sh
```

Expected output:
```
✓ No 'minimal working version' found
✓ No 'being fixed' found
✅ DEPLOYMENT SUCCESSFUL - Clean files deployed!
```

---

## 🌐 **STEP 5: Test in Browser**

### **Clear Browser Cache (CRITICAL):**

1. **Close all CloudPG tabs**
2. **Press Ctrl+Shift+Delete**
3. **Select "All time"**
4. **Check "Cached images and files"**
5. **Click "Clear data"**
6. **Close browser completely** (check Task Manager - close all browser processes)
7. **Wait 10 seconds**
8. **Reopen browser**
9. **Visit:** `http://54.227.101.30/admin/`

### **Test with DevTools:**

1. **Open:** `http://54.227.101.30/admin/`
2. **Press F12** (DevTools)
3. **Go to Network tab**
4. **Check "Disable cache"**
5. **Press Ctrl+R** to refresh
6. **Check:**
   - ✅ No "minimal working version" message
   - ✅ Dashboard loads
   - ✅ Navigation works

### **Test Incognito Mode:**

1. **Press Ctrl+Shift+N** (Incognito/Private)
2. **Visit:** `http://54.227.101.30/admin/`
3. **If it works here → browser cache was the issue**
4. **If still broken → files on EC2 still have placeholders**

---

## 🐛 **Troubleshooting**

### **Issue: Still see placeholders after upload**

**Verify files are actually clean:**
```bash
# On EC2
find /var/www/html/admin -name "*.js" -exec grep -l "minimal working version" {} \;

# Should show: NO OUTPUT
```

If you see output, the uploaded files still have placeholders.

**Solution:** Check your local files:
```powershell
# On Windows
Select-String -Path "deployment-admin-*\admin\*.js" -Pattern "minimal working version" | Select-Object -First 5
```

If your local files have placeholders, you need to rebuild!

---

### **Issue: "Permission denied" errors**

```bash
# On EC2
sudo chown -R ec2-user:ec2-user /tmp/clean-admin
sudo chmod -R 755 /tmp/clean-admin
```

---

### **Issue: Upload is very slow**

The build files are ~5MB. If upload is slow:
1. Check your internet speed
2. Compress before upload:
   ```powershell
   # On Windows
   Compress-Archive -Path "deployment-admin-*\admin\*" -DestinationPath admin-clean.zip
   
   # Upload admin-clean.zip
   # On EC2: unzip admin-clean.zip
   ```

---

## 📊 **What You're Uploading**

```
admin/
├── index.html          (~1 KB)
├── main.dart.js        (~3 MB - compiled Flutter)
├── flutter.js          (~100 KB)
├── flutter_bootstrap.js
├── assets/
│   ├── AssetManifest.json
│   ├── FontManifest.json
│   └── fonts/
└── canvaskit/          (~2 MB - Flutter renderer)
```

**Total size:** ~5-7 MB

---

## ✅ **Success Checklist**

After upload, verify:

- [ ] Files uploaded to EC2: `/var/www/html/admin/`
- [ ] Permissions set: `755`
- [ ] Nginx restarted
- [ ] No placeholders found: `grep -r "minimal working version" /var/www/html/admin/*.js`
- [ ] Browser cache cleared
- [ ] Admin portal loads: `http://54.227.101.30/admin/`
- [ ] No "minimal working version" banner
- [ ] Dashboard cards clickable
- [ ] Navigation works (Users, Rooms, Bills, etc.)

---

## 🎯 **Quick Commands Reference**

### **On Windows (Verify clean build):**
```powershell
Select-String -Path "deployment-admin-*\admin\*.js" -Pattern "minimal working version"
# Should show: NO MATCHES
```

### **On EC2 (After upload):**
```bash
# Deploy uploaded files
sudo rm -rf /var/www/html/admin
sudo mkdir -p /var/www/html/admin
sudo cp -r /tmp/clean-admin/* /var/www/html/admin/
sudo chmod -R 755 /var/www/html/admin
sudo chown -R nginx:nginx /var/www/html/admin
sudo systemctl restart nginx

# Verify
grep -r "minimal working version" /var/www/html/admin/*.js || echo "✅ Clean!"

# Test
curl -I http://localhost/admin/
```

### **In Browser:**
```
1. Ctrl+Shift+Delete → Clear all time → Clear data
2. Close browser completely
3. Reopen
4. Visit: http://54.227.101.30/admin/
```

---

## 📞 **Still Having Issues?**

Run the verification script and share output:
```bash
cd ~/pgni-main
./VERIFY_AND_REDEPLOY.sh
```

This will tell us exactly what's wrong!

