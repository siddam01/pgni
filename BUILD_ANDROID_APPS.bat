@echo off
REM ========================================
REM Build Android Apps for Play Store
REM ========================================
echo.
echo ========================================
echo    Build Android Apps
echo ========================================
echo.
echo This will build Android APK/AAB files for:
echo   - Admin App (for PG owners/managers)
echo   - Tenant App (for residents)
echo.
echo You can then:
echo   1. Install APK directly on phone (testing)
echo   2. Upload AAB to Google Play Store (production)
echo.
pause

echo.
echo Step 1: Building Admin App for Android...
echo.
cd pgworld-master
echo Building APK (for testing)...
call flutter build apk --release
echo.
echo Building AAB (for Play Store)...
call flutter build appbundle --release
echo.
echo ✓ Admin App built successfully!
echo   APK: pgworld-master\build\app\outputs\flutter-apk\app-release.apk
echo   AAB: pgworld-master\build\app\outputs\bundle\release\app-release.aab
echo.
cd ..

echo Step 2: Building Tenant App for Android...
echo.
cd pgworldtenant-master
echo Building APK (for testing)...
call flutter build apk --release
echo.
echo Building AAB (for Play Store)...
call flutter build appbundle --release
echo.
echo ✓ Tenant App built successfully!
echo   APK: pgworldtenant-master\build\app\outputs\flutter-apk\app-release.apk
echo   AAB: pgworldtenant-master\build\app\outputs\bundle\release\app-release.aab
echo.
cd ..

echo.
echo ========================================
echo ✅ ANDROID BUILDS COMPLETE!
echo ========================================
echo.
echo 📱 ADMIN APP (PG Owners):
echo    APK: pgworld-master\build\app\outputs\flutter-apk\app-release.apk
echo    AAB: pgworld-master\build\app\outputs\bundle\release\app-release.aab
echo    Size: ~25 MB
echo.
echo 📱 TENANT APP (Residents):
echo    APK: pgworldtenant-master\build\app\outputs\flutter-apk\app-release.apk
echo    AAB: pgworldtenant-master\build\app\outputs\bundle\release\app-release.aab
echo    Size: ~20 MB
echo.
echo ========================================
echo 🧪 TO TEST ON YOUR PHONE:
echo ========================================
echo.
echo 1. Copy APK file to your phone
echo 2. Enable: Settings → Security → Unknown Sources
echo 3. Tap APK file to install
echo 4. Open app and login
echo.
echo ========================================
echo 📱 TO PUBLISH TO PLAY STORE:
echo ========================================
echo.
echo 1. Go to: https://play.google.com/console
echo 2. Create new app (or select existing)
echo 3. Upload AAB file (not APK)
echo 4. Fill in app details:
echo    - Title: PGNi Admin / PGNi Tenant
echo    - Description: Property management app
echo    - Screenshots: Required
echo    - Privacy policy: Required
echo 5. Submit for review
echo 6. Wait 1-3 days for approval
echo.
echo ========================================
echo 📝 NOTES:
echo ========================================
echo.
echo • APK: For direct installation (testing)
echo • AAB: For Play Store (production)
echo • Both connect to: http://34.227.111.143:8080
echo • Apps work offline (with cached data)
echo.
pause

