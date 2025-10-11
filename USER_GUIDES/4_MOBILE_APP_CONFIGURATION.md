# 📱 PGNi Mobile Apps - Configuration & Build Guide

**Complete guide to configure and build PGNi mobile applications**

---

## 📦 What You Have

### Two Mobile Applications:

1. **PGNi Admin App** (`pgworld-master`)
   - For PG Owners
   - Manage properties, tenants, payments
   - Package: `com.mani.pgni`

2. **PGNi Tenant App** (`pgworldtenant-master`)
   - For Tenants
   - Find PG, book rooms, pay rent
   - Package: `com.mani.pgnitenant`

---

## 🔧 Prerequisites

### Software Required:

✅ **Flutter SDK** (Latest stable)
- Download: https://flutter.dev/docs/get-started/install

✅ **Android Studio** (For Android builds)
- Download: https://developer.android.com/studio

✅ **Xcode** (For iOS builds - Mac only)
- Download from Mac App Store

✅ **VS Code** (Optional but recommended)
- Download: https://code.visualstudio.com/

### Verify Installation:

```bash
flutter doctor
```

Should show all checkmarks ✅

---

## ⚙️ Configuration Steps

### Step 1: Update API Endpoint

Both apps need to know where your API is running.

#### For Admin App (`pgworld-master`):

1. **Find configuration file:**
   ```
   pgworld-master/lib/config.dart
   ```
   OR look for API URL in:
   ```
   pgworld-master/lib/services/api_service.dart
   pgworld-master/lib/utils/constants.dart
   ```

2. **Update API URL:**
   ```dart
   // OLD (localhost or example):
   static const String API_BASE_URL = "http://localhost:8080";
   static const String API_BASE_URL = "http://example.com";
   
   // NEW (your deployed API):
   static const String API_BASE_URL = "http://34.227.111.143:8080";
   ```

3. **Save the file**

#### For Tenant App (`pgworldtenant-master`):

1. **Find configuration file:**
   ```
   pgworldtenant-master/lib/config.dart
   ```
   OR
   ```
   pgworldtenant-master/lib/services/api_service.dart
   pgworldtenant-master/lib/utils/constants.dart
   ```

2. **Update API URL:**
   ```dart
   static const String API_BASE_URL = "http://34.227.111.143:8080";
   ```

3. **Save the file**

---

### Step 2: Update App Information (Already Done!)

Your apps already have:
- ✅ Display Name: **PGNi**
- ✅ Admin Package: `com.mani.pgni`
- ✅ Tenant Package: `com.mani.pgnitenant`

No changes needed here!

---

### Step 3: Install Dependencies

For both apps, run:

```bash
# For Admin App
cd pgworld-master
flutter pub get

# For Tenant App
cd ../pgworldtenant-master
flutter pub get
```

---

## 🏗️ Building the Apps

### Build Admin App (APK for Android)

```bash
cd pgworld-master

# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build release APK
flutter build apk --release

# Build split APKs (recommended - smaller size)
flutter build apk --split-per-abi --release
```

**Output files:**
```
pgworld-master/build/app/outputs/flutter-apk/
├── app-armeabi-v7a-release.apk  (for older phones)
├── app-arm64-v8a-release.apk     (for most modern phones)
└── app-x86_64-release.apk        (for emulators)
```

**Use:** `app-arm64-v8a-release.apk` for most users

---

### Build Tenant App (APK for Android)

```bash
cd pgworldtenant-master

# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build release APK
flutter build apk --release

# Build split APKs (recommended)
flutter build apk --split-per-abi --release
```

**Output files:**
```
pgworldtenant-master/build/app/outputs/flutter-apk/
├── app-armeabi-v7a-release.apk
├── app-arm64-v8a-release.apk
└── app-x86_64-release.apk
```

---

### Build iOS Apps (Mac only)

#### Admin App:

```bash
cd pgworld-master

# Clean
flutter clean

# Get dependencies
flutter pub get

# Build iOS
flutter build ios --release
```

Then open in Xcode:
```bash
open ios/Runner.xcworkspace
```

In Xcode:
1. Select your development team
2. Configure signing
3. Archive and export IPA

#### Tenant App:

```bash
cd pgworldtenant-master
flutter clean
flutter pub get
flutter build ios --release
open ios/Runner.xcworkspace
```

Same Xcode steps as Admin app.

---

## 📲 Testing the Apps

### Test on Emulator

```bash
# Start Android emulator from Android Studio

# Run Admin App
cd pgworld-master
flutter run

# Run Tenant App (in new terminal)
cd pgworldtenant-master
flutter run
```

### Test on Physical Device

**Android:**
1. Enable Developer Options on phone
2. Enable USB Debugging
3. Connect phone via USB
4. Trust computer on phone

```bash
# Check device connected
flutter devices

# Run app
flutter run
```

**iOS:**
1. Connect iPhone via USB
2. Trust computer
3. In Xcode, select your device
4. Run from Xcode

---

## ✅ Verification Checklist

### Before Distribution:

- [ ] API URL updated to production
- [ ] App builds successfully
- [ ] App connects to API
- [ ] Login/Registration works
- [ ] All screens load correctly
- [ ] Images display properly
- [ ] Buttons and navigation work
- [ ] No console errors
- [ ] App doesn't crash
- [ ] Tested on multiple devices

### Test Scenarios:

**Admin App:**
- [ ] Register as PG Owner
- [ ] Add property
- [ ] Add rooms
- [ ] Add tenant
- [ ] Record payment
- [ ] View reports

**Tenant App:**
- [ ] Register as Tenant
- [ ] Search PGs
- [ ] View PG details
- [ ] Submit booking request
- [ ] Record payment
- [ ] Request maintenance

---

## 📤 Distributing the Apps

### Option 1: Direct APK Distribution

**Easiest for testing:**

1. Copy APK files to your phone
2. Install from file manager
3. Allow "Install from Unknown Sources" if prompted
4. Share APK via:
   - WhatsApp
   - Email
   - Google Drive
   - Telegram

**Files to share:**
- `pgni-admin.apk` (Admin App)
- `pgni-tenant.apk` (Tenant App)

### Option 2: Google Play Store (For Production)

**Steps:**

1. **Create Developer Account:**
   - Go to: https://play.google.com/console
   - Pay one-time fee: $25
   - Complete registration

2. **Prepare Store Listing:**
   - App name: **PGNi** (Admin) / **PGNi Tenant**
   - Short description
   - Full description
   - Screenshots (required)
   - App icon
   - Feature graphic
   - Privacy policy URL

3. **Upload APK/AAB:**
   ```bash
   # Build App Bundle (recommended for Play Store)
   flutter build appbundle --release
   ```
   Upload: `build/app/outputs/bundle/release/app-release.aab`

4. **Set up:**
   - Content rating
   - Target audience
   - Pricing (Free/Paid)
   - Countries to distribute

5. **Submit for Review:**
   - Review takes 1-7 days
   - Fix any issues reported
   - App goes live after approval

### Option 3: Apple App Store (For iOS)

**Steps:**

1. **Apple Developer Account:**
   - Cost: $99/year
   - Register at: https://developer.apple.com/

2. **App Store Connect:**
   - Create app listing
   - Upload builds via Xcode
   - Fill all metadata
   - Screenshots for all devices

3. **Submit for Review:**
   - Stricter than Google Play
   - Takes 1-3 days typically
   - Must follow guidelines strictly

### Option 4: Firebase App Distribution (Beta Testing)

**Free and easy:**

1. **Setup Firebase:**
   ```bash
   npm install -g firebase-tools
   firebase login
   ```

2. **Configure in your project**

3. **Upload builds:**
   ```bash
   firebase appdistribution:distribute app-release.apk \
     --app YOUR_APP_ID \
     --groups testers
   ```

4. **Invite testers** via email

5. **They get download link**

---

## 🔒 Signing the Apps (For Production)

### Android App Signing

**Create keystore:**

```bash
keytool -genkey -v -keystore pgni-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias pgni
```

**Update `android/key.properties`:**
```properties
storePassword=your_store_password
keyPassword=your_key_password
keyAlias=pgni
storeFile=../pgni-release-key.jks
```

**Update `android/app/build.gradle`:**
```gradle
android {
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

**Build signed APK:**
```bash
flutter build apk --release
```

### iOS App Signing

Done automatically in Xcode with your Apple Developer account.

---

## 🐛 Common Issues & Solutions

### Issue: Build Fails

**Solution:**
```bash
flutter clean
flutter pub get
flutter build apk
```

### Issue: API Connection Failed

**Check:**
- Is API running? Test: `http://34.227.111.143:8080/health`
- Is API URL correct in config?
- Is phone on same network (if testing)?
- Check firewall rules

### Issue: "Unsigned APK" Warning

**Solution:**
- Normal for development
- Sign APK for production (see above)

### Issue: App Crashes on Launch

**Debug:**
```bash
flutter run
# See console errors
```

**Common causes:**
- Missing dependencies
- Wrong API URL
- Network permission missing
- Initialization error

### Issue: Images Not Loading

**Check:**
- S3 bucket public access
- Image URLs correct
- Network permission in AndroidManifest.xml:
  ```xml
  <uses-permission android:name="android.permission.INTERNET"/>
  ```

---

## 📊 App Size Optimization

### Reduce APK Size:

1. **Use split APKs:**
   ```bash
   flutter build apk --split-per-abi
   ```

2. **Enable ProGuard/R8 (in `build.gradle`):**
   ```gradle
   buildTypes {
       release {
           minifyEnabled true
           shrinkResources true
       }
   }
   ```

3. **Remove unused assets:**
   - Delete unused images
   - Optimize image sizes
   - Use WebP format

4. **Analyze app size:**
   ```bash
   flutter build apk --analyze-size
   ```

---

## 🔄 Updates & Versioning

### Update Version:

Edit `pubspec.yaml`:
```yaml
version: 1.0.1+2
#        │    └── Build number (increment always)
#        └── Version name (semantic versioning)
```

### Version Strategy:

- **1.0.0** - Initial release
- **1.0.1** - Bug fixes
- **1.1.0** - New features
- **2.0.0** - Major changes

### Releasing Updates:

1. Update version number
2. Build new APK/AAB
3. Test thoroughly
4. Upload to store
5. Write changelog
6. Submit for review

---

## 📱 Push Notifications (Optional)

### Setup Firebase Cloud Messaging:

1. **Create Firebase project**
2. **Add Android/iOS apps**
3. **Download config files:**
   - `google-services.json` (Android)
   - `GoogleService-Info.plist` (iOS)
4. **Add to projects**
5. **Install packages:**
   ```yaml
   dependencies:
     firebase_core: latest
     firebase_messaging: latest
   ```
6. **Initialize in code**
7. **Send notifications from admin**

---

## 💡 Best Practices

### Development:

✅ Test on multiple devices
✅ Test on different Android versions
✅ Test on slow networks
✅ Handle offline scenarios
✅ Show loading indicators
✅ Validate user inputs
✅ Handle errors gracefully

### Security:

✅ Store API keys securely
✅ Use HTTPS (when SSL configured)
✅ Validate all user inputs
✅ Don't log sensitive data
✅ Use secure storage for tokens
✅ Implement session timeout

### Performance:

✅ Lazy load images
✅ Cache API responses
✅ Optimize list scrolling
✅ Minimize API calls
✅ Compress images
✅ Use pagination

---

## 📞 Support

### Need Help?

**Build Issues:**
- Flutter Discord: https://discord.gg/flutter
- Stack Overflow: Tag `flutter`

**API Issues:**
- Check: `DEPLOYMENT_SUCCESS.md`
- Test API: `http://34.227.111.143:8080/health`

**App Store:**
- Google Play Console Help
- Apple Developer Support

---

## ✅ Quick Reference

### Your API:
```
http://34.227.111.143:8080
```

### Build Commands:
```bash
# Admin App
cd pgworld-master
flutter clean && flutter pub get
flutter build apk --release

# Tenant App
cd pgworldtenant-master
flutter clean && flutter pub get
flutter build apk --release
```

### APK Locations:
```
pgworld-master/build/app/outputs/flutter-apk/app-release.apk
pgworldtenant-master/build/app/outputs/flutter-apk/app-release.apk
```

---

## 🎉 You're Ready!

**Build, test, and distribute your apps!**

**Your users will love PGNi!** 📱✨

For deployment steps, see: `ONE_CLICK_DEPLOY.ps1`

