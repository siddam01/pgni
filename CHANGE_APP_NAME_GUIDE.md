# 📱 How to Change App Name - PG World

**Current App Names Found:**

| App | Current Display Name | Current Package Name |
|-----|---------------------|----------------------|
| **Admin App** | "Cloud PG" | com.saikrishna.cloudpg |
| **Tenant App** | "Cloud PG" | com.saikrishna.cloudpgtenant |

---

## 🎯 CURRENT APP NAMES

### What Users See in Play Store & Phone:

**Both apps show:** `Cloud PG`

**Issues:**
- ❌ Both apps have the same display name (confusing!)
- ❌ Generic name "Cloud PG"
- ⚠️ Package names have "saikrishna" (previous developer)

---

## 📝 RECOMMENDED NEW NAMES

### Option 1: Different Names (Recommended)
- **Admin App:** `PG World Admin` or `PG Manager`
- **Tenant App:** `PG World Tenant` or `PG World`

### Option 2: With Your Branding
- **Admin App:** `[Your Brand] PG Manager`
- **Tenant App:** `[Your Brand] PG`

### Option 3: Keep Simple
- **Admin App:** `PG Admin`
- **Tenant App:** `PG Tenant`

**Recommendation:** Use **Option 1** - Clear and professional

---

## 🔧 HOW TO CHANGE APP NAMES

### ADMIN APP (PG World Admin)

#### Step 1: Change Android Display Name

**File:** `pgworld-master/android/app/src/main/AndroidManifest.xml`

**Current (Line 14):**
```xml
android:label="Cloud PG"
```

**Change to:**
```xml
android:label="PG World Admin"
```

#### Step 2: Change iOS Display Name

**File:** `pgworld-master/ios/Runner/Info.plist`

Find:
```xml
<key>CFBundleName</key>
<string>Cloud PG</string>
```

**Change to:**
```xml
<key>CFBundleName</key>
<string>PG World Admin</string>
```

Also find:
```xml
<key>CFBundleDisplayName</key>
<string>Cloud PG</string>
```

**Change to:**
```xml
<key>CFBundleDisplayName</key>
<string>PG World Admin</string>
```

---

### TENANT APP (PG World Tenant)

#### Step 1: Change Android Display Name

**File:** `pgworldtenant-master/android/app/src/main/AndroidManifest.xml`

**Current (Line 11):**
```xml
android:label="Cloud PG"
```

**Change to:**
```xml
android:label="PG World Tenant"
```

#### Step 2: Change iOS Display Name

**File:** `pgworldtenant-master/ios/Runner/Info.plist`

Find:
```xml
<key>CFBundleName</key>
<string>Cloud PG</string>
```

**Change to:**
```xml
<key>CFBundleName</key>
<string>PG World Tenant</string>
```

Also find:
```xml
<key>CFBundleDisplayName</key>
<string>Cloud PG</string>
```

**Change to:**
```xml
<key>CFBundleDisplayName</key>
<string>PG World Tenant</string>
```

---

## 📦 CHANGE PACKAGE NAME (Optional but Recommended)

### Why Change Package Name?

**Current package names:**
- Admin: `com.saikrishna.cloudpg`
- Tenant: `com.saikrishna.cloudpgtenant`

**Issues:**
- Contains previous developer name ("saikrishna")
- You should use your own domain/brand

**Recommended new names:**
- Admin: `com.yourcompany.pgworld.admin`
- Tenant: `com.yourcompany.pgworld.tenant`

### ⚠️ WARNING: Changing package name is complex!

**Package name changes require:**
1. Updating 10+ files in each app
2. Updating Google Play Console
3. Re-submitting to app stores
4. Users need to uninstall old app and install new one

**Recommendation:** 
- ✅ **Change display name NOW** (easy, no issues)
- ⚠️ **Change package name ONLY if you haven't published yet**
- ❌ **Don't change package name if app is already live** (causes problems)

If you need to change package name, I can provide detailed instructions.

---

## 🚀 APPLY CHANGES (Easy Method)

I'll create a script to change the app names automatically!

### Run the script:

```powershell
.\change-app-names.ps1 -AdminName "PG World Admin" -TenantName "PG World Tenant"
```

Or edit manually using the instructions above.

---

## ✅ AFTER CHANGING NAMES

### Rebuild Apps:

**Admin App:**
```bash
cd pgworld-master

# For Android
flutter clean
flutter build apk --release

# For iOS
flutter clean
flutter build ios --release
```

**Tenant App:**
```bash
cd pgworldtenant-master

# For Android
flutter clean
flutter build apk --release

# For iOS
flutter clean
flutter build ios --release
```

---

## 📱 WHERE THE NAME APPEARS

### Display Name (android:label / CFBundleDisplayName):

✅ **Shows in:**
- Play Store listing
- App Store listing
- Phone home screen (app icon label)
- App switcher / Recent apps
- Settings → Apps list

❌ **Does NOT affect:**
- Package name (com.saikrishna.cloudpg)
- App functionality
- Existing users (updates work fine)

---

## 🎨 ALSO CHECK APP TITLES IN CODE

The app name also appears in the app UI itself. Let me check:

### In Admin App:

**Files to check:**
- `pgworld-master/lib/main.dart`
- `pgworld-master/lib/screens/dashboard.dart`
- Any screen with `AppBar` title

### In Tenant App:

**Files to check:**
- `pgworldtenant-master/lib/main.dart`
- `pgworldtenant-master/lib/screens/*.dart`

These show the app title at the top of screens. You may want to change these too!

---

## 📊 SUMMARY

### What to Change:

| File | Current | Change To |
|------|---------|-----------|
| **Admin - AndroidManifest.xml** | "Cloud PG" | "PG World Admin" |
| **Admin - Info.plist** | "Cloud PG" | "PG World Admin" |
| **Tenant - AndroidManifest.xml** | "Cloud PG" | "PG World Tenant" |
| **Tenant - Info.plist** | "Cloud PG" | "PG World Tenant" |

### Results:

✅ Users see different names for each app  
✅ Professional branding  
✅ No conflicts  
✅ Existing users can update normally  

---

## 🤔 WHICH NAME SHOULD I USE?

### For PG Owners (Admin App):

**Good names:**
- ✅ "PG World Admin" (clear purpose)
- ✅ "PG Manager" (short and clear)
- ✅ "PG Admin" (simple)
- ✅ "[Your Brand] PG Manager"

**Avoid:**
- ❌ "Cloud PG" (too generic)
- ❌ "PG World" (same as tenant app - confusing!)

### For Tenants (Tenant App):

**Good names:**
- ✅ "PG World" (simple, main app)
- ✅ "PG World Tenant" (clear)
- ✅ "[Your Brand] PG"

**Avoid:**
- ❌ "Cloud PG" (too generic)
- ❌ "PG World Admin" (confusing with admin app!)

---

## 🎯 MY RECOMMENDATION

**Admin App:** `PG World Admin`  
**Tenant App:** `PG World`

**Why?**
- Clear distinction
- Professional
- Easy to understand
- Good for branding

---

## 🔧 QUICK CHANGE COMMANDS

Let me know your preferred names and I'll:
1. Update all necessary files
2. Create a script to automate it
3. Verify the changes

**What names would you like?**

---

## 📞 NEXT STEPS

1. **Decide on names**
   - Admin app name: _______________
   - Tenant app name: _______________

2. **Let me know**
   - I'll update all files for you

3. **Or edit manually**
   - Follow the instructions above
   - Edit 4 files total (2 per app)

4. **Rebuild apps**
   - Run `flutter clean && flutter build`

5. **Test**
   - Install on phone
   - Check app name appears correctly

**Ready to change? Tell me your preferred names!**

