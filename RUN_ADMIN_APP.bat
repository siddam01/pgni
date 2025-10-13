@echo off
echo ========================================
echo Starting PGNi Admin App
echo ========================================
echo.

cd pgworld-master

echo Cleaning previous build...
call flutter clean

echo Getting dependencies...
call flutter pub get

echo.
echo ========================================
echo Choose how to run the app:
echo ========================================
echo 1. Chrome Browser (Fastest - recommended)
echo 2. Android Emulator
echo 3. Build APK for phone
echo.

set /p choice="Enter your choice (1-3): "

if "%choice%"=="1" (
    echo.
    echo Starting app in Chrome browser...
    echo.
    echo The app will open in your browser shortly!
    echo API URL: http://34.227.111.143:8080
    echo.
    call flutter run -d chrome
) else if "%choice%"=="2" (
    echo.
    echo Starting Android emulator...
    echo Make sure you have an emulator running!
    echo.
    call flutter run
) else if "%choice%"=="3" (
    echo.
    echo Building APK...
    echo This will take 2-3 minutes...
    echo.
    call flutter build apk --release
    echo.
    echo ========================================
    echo APK built successfully!
    echo ========================================
    echo.
    echo Location: build\app\outputs\flutter-apk\app-release.apk
    echo.
    echo Transfer this file to your Android phone and install it!
    echo.
    pause
) else (
    echo Invalid choice!
    pause
)

