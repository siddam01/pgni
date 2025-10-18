# PG World - Production-Ready Management System

[![Flutter](https://img.shields.io/badge/Flutter-3.35%2B-blue)](https://flutter.dev)
[![Null Safety](https://img.shields.io/badge/null--safety-enabled-brightgreen)](https://dart.dev/null-safety)
[![Production](https://img.shields.io/badge/status-production--ready-success)](http://54.227.101.30/tenant/)

**Production-grade Paying Guest (PG) Management System** with modern architecture, full null-safety, and clean code structure.

---

## 🚀 ONE-COMMAND DEPLOYMENT

### **Deploy Production Build:**
```bash
bash <(curl -sL https://raw.githubusercontent.com/siddam01/pgni/main/PRODUCTION_DEPLOY.sh)
```

**⏱️ Deploy Time:** 3-5 minutes  
**📊 Status:** ✅ Production Ready  
**🎯 Target:** Flutter 3.35+ | Null-Safe | Clean Architecture

---

## 🌐 Access Your Application

### **Tenant Portal:**
```
🌐 URL:      http://54.227.101.30/tenant/
📧 Email:    priya@example.com
🔐 Password: Tenant@123
```

### **Admin Portal:**
```
🌐 URL:      http://54.227.101.30/admin/
📧 Email:    admin@pgworld.com
🔐 Password: Admin@123
```

---

## 📁 Project Structure

```
pgworld-master/
├── pgworld-api-master/              # Backend API (Go)
│   ├── main.go                      # API server
│   ├── models.go                    # Data models
│   └── setup-database.sql           # DB schema
│
├── pgworld-master/                  # Admin App (Flutter)
│   ├── lib/
│   │   ├── screens/                 # UI screens
│   │   ├── utils/                   # Utilities
│   │   └── main.dart                # Entry point
│   └── pubspec.yaml
│
├── pgworldtenant-master/            # Tenant App (Flutter) ⭐
│   ├── lib/
│   │   ├── config/
│   │   │   └── app_config.dart      # Production config
│   │   ├── services/
│   │   │   ├── api_service.dart     # API layer
│   │   │   └── session_manager.dart # Session handling
│   │   ├── screens/
│   │   │   ├── login_screen.dart
│   │   │   └── dashboard_screen.dart
│   │   ├── utils/
│   │   │   ├── app_utils.dart       # Utilities
│   │   │   └── models.dart          # Data models
│   │   └── main.dart
│   └── pubspec.yaml
│
├── terraform/                       # AWS Infrastructure
├── .github/workflows/               # CI/CD Pipelines
│
└── PRODUCTION_DEPLOY.sh             # ⭐ MAIN DEPLOYMENT SCRIPT
```

---

## ✨ What's Included

### **Modern Architecture:**
- ✅ **Clean Code Structure** - Organized by feature and layer
- ✅ **Separation of Concerns** - Config, Services, UI separate
- ✅ **Service Layer** - API, Session management abstracted
- ✅ **State Management** - SessionManager for global state
- ✅ **Null Safety** - Full Dart 3.0+ null-safety compliance

### **Production Features:**
- ✅ **Environment Config** - Production settings in `app_config.dart`
- ✅ **Session Management** - Persistent login with SharedPreferences
- ✅ **Network Handling** - Internet connectivity checks
- ✅ **Error Handling** - Graceful error messages and alerts
- ✅ **Security** - API key authentication, secure headers
- ✅ **Performance** - Optimized build with tree-shaking

### **Developer Experience:**
- ✅ **Flutter 3.35+** - Latest stable SDK
- ✅ **Material 3** - Modern UI components
- ✅ **Type Safety** - Strong typing throughout
- ✅ **Documentation** - Comprehensive inline docs
- ✅ **Fast Builds** - ~3-5 minutes end-to-end

---

## 🔧 Manual Build (Optional)

If you prefer to build manually:

```bash
# Navigate to tenant app
cd /home/ec2-user/pgni/pgworldtenant-master

# Clean and get dependencies
flutter clean
flutter pub get

# Build for web
flutter build web \
  --release \
  --base-href="/tenant/" \
  --no-source-maps \
  --dart-define=dart.vm.product=true

# Deploy to Nginx
sudo cp -r build/web/* /usr/share/nginx/html/tenant/
sudo systemctl reload nginx
```

---

## 📋 What the Deployment Script Does

### **Phase 1-2: Clean Setup**
- Backs up existing code
- Removes old build artifacts
- Creates clean lib structure

### **Phase 3-4: Configuration**
- Creates `lib/config/app_config.dart` with production settings
- Sets up `SessionManager` for user state

### **Phase 5-6: Core Services**
- Creates utility functions (connectivity, dialogs, formatters)
- Defines data models with null-safety

### **Phase 7-10: UI Layer**
- Creates API service layer
- Builds Login and Dashboard screens
- Sets up main entry point

### **Phase 11-12: Build**
- Updates dependencies
- Compiles Flutter web app
- Optimizes for production

### **Phase 13-14: Deploy & Verify**
- Deploys to Nginx at `/tenant/`
- Sets correct permissions
- Verifies all endpoints return HTTP 200

---

## 🛠️ Troubleshooting

### **Blank Screen?**
1. Check browser console (F12 → Console)
2. Look for 404 errors for JS files
3. Verify base-href: `<base href="/tenant/">`

### **Build Fails?**
1. Check Flutter version: `flutter --version` (need 3.35+)
2. Clear cache: `flutter clean`
3. Check logs in `/tmp/production_deploy_*.log`

### **Can't Access?**
1. Check Nginx status: `sudo systemctl status nginx`
2. Test locally: `curl http://localhost/tenant/`
3. Check firewall: Security group should allow port 80

---

## 📊 Technical Specifications

| Component | Technology | Version |
|-----------|------------|---------|
| Frontend | Flutter Web | 3.35.6+ |
| Language | Dart | 3.9.2+ |
| Backend | Go | 1.21+ |
| Database | MySQL | 8.0+ |
| Server | AWS EC2 | t3.xlarge |
| Web Server | Nginx | Latest |
| State | SharedPreferences | 2.2.2 |
| HTTP | http package | 1.1.0 |
| Connectivity | connectivity_plus | 6.0.5 |

---

## 📦 Dependencies

All dependencies are automatically managed. Current production dependencies:

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.2
  http: ^1.1.0
  shared_preferences: ^2.2.2
  connectivity_plus: ^6.0.5
  intl: ^0.19.0
```

---

## 🎯 Next Steps

After successful deployment:

1. **Access the app:** http://54.227.101.30/tenant/
2. **Login** with provided credentials
3. **Test features:** Dashboard, profile, settings
4. **Monitor:** Check Nginx logs if issues occur
5. **Extend:** Add more screens using the same architecture pattern

---

## 📝 Architecture Pattern

The codebase follows a layered architecture:

```
┌─────────────────────────────────────┐
│         Presentation Layer          │
│    (Screens, Widgets, UI Logic)     │
├─────────────────────────────────────┤
│         Service Layer               │
│    (API, Session, Business Logic)   │
├─────────────────────────────────────┤
│         Data Layer                  │
│      (Models, Repositories)         │
├─────────────────────────────────────┤
│         Core Layer                  │
│   (Config, Utils, Constants)        │
└─────────────────────────────────────┘
```

---

## 🤝 Support

For issues or questions:
- Check `/tmp/production_deploy_*.log` for build logs
- Review browser console for runtime errors
- Verify Nginx configuration: `sudo nginx -t`

---

## ✅ Production Checklist

- [x] Clean project structure
- [x] Modern Flutter 3.35+ architecture
- [x] Full null-safety compliance
- [x] Production-grade configuration
- [x] Session management
- [x] API service layer
- [x] Responsive UI
- [x] Error handling
- [x] Performance optimized
- [x] Deployed with correct base-href
- [x] All endpoints verified (HTTP 200)
- [x] Security headers configured

---

**🎉 Ready for Production!**

The application is fully built, tested, and deployed. Access it now at http://54.227.101.30/tenant/
