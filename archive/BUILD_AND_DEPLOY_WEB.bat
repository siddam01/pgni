@echo off
echo ========================================
echo Build and Deploy Flutter Web UI
echo ========================================
echo.

echo This will:
echo 1. Build Flutter web app
echo 2. Deploy to EC2 server
echo 3. Configure API to serve web files
echo.
echo Then you can access UI at: http://34.227.111.143:8080
echo.

set /p confirm="Do you want to proceed? (yes/no): "
if not "%confirm%"=="yes" (
    echo Cancelled.
    pause
    exit /b
)

echo.
echo ========================================
echo Step 1: Building Flutter Web App
echo ========================================
echo.

cd pgworld-master

echo Cleaning previous build...
call flutter clean

echo Getting dependencies...
call flutter pub get

echo Building for web (this takes 2-3 minutes)...
call flutter build web --release

if not exist "build\web\index.html" (
    echo.
    echo ERROR: Web build failed!
    echo Please check Flutter installation.
    pause
    exit /b 1
)

echo.
echo ✓ Web build complete!
echo Files ready in: build\web\
echo.

echo ========================================
echo Step 2: Deploying to EC2
echo ========================================
echo.

echo Creating deployment package...
cd build\web
tar -czf ..\..\web-deploy.tar.gz *
cd ..\..

echo.
echo Files to upload:
dir web-deploy.tar.gz

echo.
echo ========================================
echo MANUAL STEPS REQUIRED
echo ========================================
echo.
echo The web files are ready in: web-deploy.tar.gz
echo.
echo To complete deployment, run these commands in CloudShell:
echo.
echo # 1. Upload the file
echo scp web-deploy.tar.gz cloudshell:~/
echo.
echo # 2. In CloudShell, deploy to EC2:
echo scp -i ~/cloudshell-key.pem ~/web-deploy.tar.gz ec2-user@34.227.111.143:/tmp/
echo.
echo ssh -i ~/cloudshell-key.pem ec2-user@34.227.111.143
echo sudo mkdir -p /opt/pgworld/web
echo cd /opt/pgworld/web
echo sudo tar -xzf /tmp/web-deploy.tar.gz
echo sudo chown -R ec2-user:ec2-user /opt/pgworld/web
echo.
echo # 3. Update API to serve web files (requires code change)
echo.
echo ========================================
echo.
echo OR use the EASIER METHOD:
echo Just run: RUN_ADMIN_APP.bat
echo Choose option 1 (Chrome)
echo.
echo The app will open with full UI in 30 seconds!
echo (This is the recommended approach)
echo.

pause

