@echo off
echo.
echo ========================================
echo    PGNi - Build Status Check
echo ========================================
echo.

REM Check Flutter
echo Checking Flutter SDK...
flutter --version >nul 2>&1
if %errorlevel% equ 0 (
    echo [OK] Flutter SDK installed
    flutter --version | findstr "Flutter"
) else (
    echo [X] Flutter SDK NOT installed
    echo.
    echo You need to install Flutter to build Android apps.
    echo See: INSTALL_FLUTTER_AND_BUILD.md
)
echo.

REM Check Android Studio / Android SDK
echo Checking Android SDK...
if exist "%ANDROID_HOME%\platform-tools\adb.exe" (
    echo [OK] Android SDK found
) else if exist "%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe" (
    echo [OK] Android SDK found
) else (
    echo [X] Android SDK NOT found
    echo.
    echo You need Android Studio to build Android apps.
    echo See: INSTALL_FLUTTER_AND_BUILD.md
)
echo.

REM Check for existing APK files
echo Checking for existing APK files...
echo.
if exist "pgworld-master\build\app\outputs\flutter-apk\app-release.apk" (
    echo [OK] Admin APK found:
    echo     pgworld-master\build\app\outputs\flutter-apk\app-release.apk
    dir "pgworld-master\build\app\outputs\flutter-apk\app-release.apk" | findstr "app-release.apk"
) else (
    echo [X] Admin APK not found (not built yet)
)
echo.

if exist "pgworldtenant-master\build\app\outputs\flutter-apk\app-release.apk" (
    echo [OK] Tenant APK found:
    echo     pgworldtenant-master\build\app\outputs\flutter-apk\app-release.apk
    dir "pgworldtenant-master\build\app\outputs\flutter-apk\app-release.apk" | findstr "app-release.apk"
) else (
    echo [X] Tenant APK not found (not built yet)
)
echo.

REM Check for AAB files
echo Checking for AAB files (Play Store)...
echo.
if exist "pgworld-master\build\app\outputs\bundle\release\app-release.aab" (
    echo [OK] Admin AAB found:
    echo     pgworld-master\build\app\outputs\bundle\release\app-release.aab
) else (
    echo [X] Admin AAB not found (not built yet)
)
echo.

if exist "pgworldtenant-master\build\app\outputs\bundle\release\app-release.aab" (
    echo [OK] Tenant AAB found:
    echo     pgworldtenant-master\build\app\outputs\bundle\release\app-release.aab
) else (
    echo [X] Tenant AAB not found (not built yet)
)
echo.

REM Check web build
echo Checking Web builds...
echo.
if exist "pgworld-master\build\web\index.html" (
    echo [OK] Admin Web build found
) else (
    echo [X] Admin Web build not found
)

if exist "pgworldtenant-master\build\web\index.html" (
    echo [OK] Tenant Web build found
) else (
    echo [X] Tenant Web build not found
)
echo.

echo ========================================
echo    SUMMARY
echo ========================================
echo.
flutter --version >nul 2>&1
if %errorlevel% neq 0 (
    echo STATUS: Flutter SDK not installed
    echo.
    echo TO BUILD ANDROID APPS:
    echo   1. Read: INSTALL_FLUTTER_AND_BUILD.md
    echo   2. Install Flutter SDK
    echo   3. Install Android Studio
    echo   4. Run: BUILD_ANDROID_APPS.bat
    echo.
    echo OR USE WEB VERSION (no Flutter needed):
    echo   1. Run: DEPLOY_FULL_APP_NOW.bat
    echo   2. App accessible at: http://34.227.111.143
    echo   3. Works on phone browser (no installation)
) else (
    if not exist "pgworld-master\build\app\outputs\flutter-apk\app-release.apk" (
        echo STATUS: Flutter installed, but apps not built yet
        echo.
        echo TO BUILD ANDROID APPS:
        echo   Run: BUILD_ANDROID_APPS.bat
    ) else (
        echo STATUS: Apps are built and ready!
        echo.
        echo APK FILES LOCATION:
        echo   Admin:  pgworld-master\build\app\outputs\flutter-apk\app-release.apk
        echo   Tenant: pgworldtenant-master\build\app\outputs\flutter-apk\app-release.apk
        echo.
        echo TRANSFER TO PHONE:
        echo   1. Copy APK to phone
        echo   2. Enable "Unknown Sources" in phone settings
        echo   3. Tap APK to install
    )
)
echo.
pause

