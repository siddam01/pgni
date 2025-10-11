# 🌐 URL Access & Mobile App Configuration Guide

## 🚨 Current Issue

**Problem:** `http://34.227.111.143:8080` shows "Connection Refused"

**Root Cause:** API is not deployed to EC2 yet

**Status:** Infrastructure ready, but API service not running

---

## ✅ Solution: Complete Deployment

### **Step 1: Deploy API (5 minutes)**

1. **Open AWS CloudShell:**
   ```
   https://console.aws.amazon.com/cloudshell/
   ```

2. **Copy ALL from this file:**
   ```
   DEPLOY_API_NOW_COMPLETE.txt
   ```

3. **Paste into CloudShell and press Enter**

4. **Wait 5 minutes**

5. **Verify:**
   ```bash
   curl http://34.227.111.143:8080/health
   ```

---

## 📱 Mobile App Configuration

Once API is deployed, you need to update mobile apps with the API URL.

### **For Admin App (pgworld-master):**

#### **Location:** `pgworld-master/lib/config/api_config.dart` (or similar)

```dart
class ApiConfig {
  // OLD (will not work):
  // static const String baseUrl = 'http://localhost:8080';
  
  // NEW (use this):
  static const String baseUrl = 'http://34.227.111.143:8080';
  
  // Endpoints
  static const String healthCheck = '$baseUrl/health';
  static const String login = '$baseUrl/api/login';
  static const String register = '$baseUrl/api/register';
  // ... other endpoints
}
```

### **For Tenant App (pgworldtenant-master):**

#### **Location:** `pgworldtenant-master/lib/config/api_config.dart` (or similar)

```dart
class ApiConfig {
  static const String baseUrl = 'http://34.227.111.143:8080';
  
  // Endpoints
  static const String healthCheck = '$baseUrl/health';
  static const String login = '$baseUrl/api/tenant/login';
  static const String bookings = '$baseUrl/api/tenant/bookings';
  // ... other endpoints
}
```

---

## 🔧 Finding API Configuration in Flutter Apps

### **Method 1: Search for API URL**
```bash
# In Admin app
cd pgworld-master
grep -r "localhost:8080" lib/
grep -r "baseUrl" lib/
grep -r "http://" lib/

# In Tenant app
cd pgworldtenant-master
grep -r "localhost:8080" lib/
grep -r "baseUrl" lib/
grep -r "http://" lib/
```

### **Method 2: Common File Locations**
Check these files:
- `lib/config/api_config.dart`
- `lib/config/constants.dart`
- `lib/services/api_service.dart`
- `lib/utils/constants.dart`
- `lib/main.dart`

### **Method 3: Environment Variables**
Some apps use `.env` files:
- `android/.env`
- `ios/.env`
- `.env`

Example `.env`:
```env
API_BASE_URL=http://34.227.111.143:8080
API_TIMEOUT=30000
```

---

## 🌐 URL Configuration Patterns

### **Pattern 1: Single Base URL**
```dart
class ApiConfig {
  static const String baseUrl = 'http://34.227.111.143:8080';
}
```

### **Pattern 2: Environment-Based**
```dart
class ApiConfig {
  static const String baseUrl = kReleaseMode 
    ? 'http://34.227.111.143:8080'  // Production
    : 'http://localhost:8080';       // Development
}
```

### **Pattern 3: .env File**
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static String get baseUrl => dotenv.env['API_BASE_URL'] ?? '';
}
```

---

## 🔒 Security Considerations

### **Issue: HTTP vs HTTPS**

Currently using: `http://34.227.111.143:8080` (not secure)

**For Production, you need:**

1. **Domain Name**
   - Register: `api.pgni.com`
   - Point to: `34.227.111.143`

2. **SSL Certificate**
   - Use Let's Encrypt (free)
   - Or AWS Certificate Manager

3. **Reverse Proxy**
   - Install Nginx
   - Configure SSL
   - Proxy to port 8080

**Then use:**
```dart
static const String baseUrl = 'https://api.pgni.com';
```

---

## 📱 Building Mobile Apps After Configuration

### **Admin App:**
```bash
cd pgworld-master

# Android
flutter build apk --release

# iOS (requires Mac)
flutter build ios --release

# APK location:
# build/app/outputs/flutter-apk/app-release.apk
```

### **Tenant App:**
```bash
cd pgworldtenant-master

# Android
flutter build apk --release

# iOS (requires Mac)
flutter build ios --release

# APK location:
# build/app/outputs/flutter-apk/app-release.apk
```

---

## 🧪 Testing API Connectivity

### **From Command Line:**
```bash
# Health check
curl http://34.227.111.143:8080/health

# Test endpoint (replace with actual endpoint)
curl -X POST http://34.227.111.143:8080/api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password"}'
```

### **From Flutter App:**
```dart
import 'package:http/http.dart' as http;

Future<void> testConnection() async {
  try {
    final response = await http.get(
      Uri.parse('http://34.227.111.143:8080/health'),
    );
    
    if (response.statusCode == 200) {
      print('✅ Connected to API!');
      print('Response: ${response.body}');
    } else {
      print('❌ API returned: ${response.statusCode}');
    }
  } catch (e) {
    print('❌ Connection failed: $e');
  }
}
```

### **From Browser:**
Simply open:
```
http://34.227.111.143:8080/health
```

You should see a JSON response like:
```json
{
  "status": "healthy",
  "timestamp": "2025-10-11T...",
  "service": "PGWorld API"
}
```

---

## 🔧 Troubleshooting

### **Problem: "Connection Refused"**

**Cause:** API not deployed or service not running

**Solution:**
1. Deploy API using `DEPLOY_API_NOW_COMPLETE.txt`
2. Check service status:
   ```bash
   ssh -i ec2-key.pem ec2-user@34.227.111.143 \
     "sudo systemctl status pgworld-api"
   ```

---

### **Problem: "Connection Timeout"**

**Cause:** Firewall or security group blocking port 8080

**Solution:**
1. Check AWS Security Group:
   - EC2 Console → Security Groups
   - Ensure inbound rule allows port 8080 from 0.0.0.0/0

2. Check EC2 firewall:
   ```bash
   ssh -i ec2-key.pem ec2-user@34.227.111.143
   sudo iptables -L -n | grep 8080
   sudo firewall-cmd --list-all
   ```

---

### **Problem: Mobile App "Network Error"**

**Causes:**
1. Wrong API URL
2. API not running
3. Network permission missing

**Solutions:**

1. **Verify API URL in app**
2. **Add Internet permission** (Android):
   ```xml
   <!-- android/app/src/main/AndroidManifest.xml -->
   <uses-permission android:name="android.permission.INTERNET" />
   ```

3. **Allow cleartext traffic** (Android):
   ```xml
   <!-- android/app/src/main/AndroidManifest.xml -->
   <application
       android:usesCleartextTraffic="true"
       ...>
   ```

4. **iOS Configuration** (ios/Runner/Info.plist):
   ```xml
   <key>NSAppTransportSecurity</key>
   <dict>
       <key>NSAllowsArbitraryLoads</key>
       <true/>
   </dict>
   ```

---

### **Problem: CORS Errors**

**Cause:** API blocking requests from mobile apps

**Solution:** API already configured with CORS in `main.go`:
```go
type WithCORS struct {
    r http.Handler
}

func (h *WithCORS) ServeHTTP(w http.ResponseWriter, r *http.Request) {
    w.Header().Set("Access-Control-Allow-Origin", "*")
    w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
    w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
    
    if r.Method == "OPTIONS" {
        w.WriteHeader(http.StatusOK)
        return
    }
    
    h.r.ServeHTTP(w, r)
}
```

---

## 📋 Complete Deployment Checklist

- [ ] **1. Deploy API**
  - [ ] Run `DEPLOY_API_NOW_COMPLETE.txt` in CloudShell
  - [ ] Verify: `curl http://34.227.111.143:8080/health`

- [ ] **2. Configure Admin App**
  - [ ] Update `API_BASE_URL` to `http://34.227.111.143:8080`
  - [ ] Add Internet permission
  - [ ] Enable cleartext traffic

- [ ] **3. Configure Tenant App**
  - [ ] Update `API_BASE_URL` to `http://34.227.111.143:8080`
  - [ ] Add Internet permission
  - [ ] Enable cleartext traffic

- [ ] **4. Build Apps**
  - [ ] Build Admin APK
  - [ ] Build Tenant APK
  - [ ] Test on devices

- [ ] **5. Test End-to-End**
  - [ ] API health check works
  - [ ] Admin app connects to API
  - [ ] Tenant app connects to API
  - [ ] Login/registration works
  - [ ] All features functional

---

## 🎯 Quick Reference

### **API URL (Current):**
```
http://34.227.111.143:8080
```

### **Health Check:**
```
http://34.227.111.143:8080/health
```

### **AWS CloudShell:**
```
https://console.aws.amazon.com/cloudshell/
```

### **Deployment Script:**
```
DEPLOY_API_NOW_COMPLETE.txt
```

### **Check Service:**
```bash
ssh -i ec2-key.pem ec2-user@34.227.111.143 "sudo systemctl status pgworld-api"
```

### **View Logs:**
```bash
ssh -i ec2-key.pem ec2-user@34.227.111.143 "sudo journalctl -u pgworld-api -f"
```

---

## 🎉 Success Criteria

When deployment is successful, you'll see:

1. ✅ **API Health Check:**
   ```bash
   $ curl http://34.227.111.143:8080/health
   {"status":"healthy","service":"PGWorld API"}
   ```

2. ✅ **Browser Access:**
   Open `http://34.227.111.143:8080/health` - See JSON response

3. ✅ **Mobile App Connection:**
   Apps can login, fetch data, and perform all operations

---

## 📞 Need Help?

If issues persist after deployment:

1. Check API logs
2. Verify security groups
3. Test with curl
4. Check mobile app permissions
5. Review error messages

**The API is NOT deployed yet - that's why the URL doesn't work!**

**Run `DEPLOY_API_NOW_COMPLETE.txt` in CloudShell to fix this!**

---

**Last Updated:** October 11, 2025  
**Status:** API deployment pending  
**Action Required:** Run deployment script in CloudShell

