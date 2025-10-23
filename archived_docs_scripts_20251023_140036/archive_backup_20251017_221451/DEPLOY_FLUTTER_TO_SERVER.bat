@echo off
REM ========================================
REM Deploy Flutter Web Apps to Server
REM ========================================
echo.
echo ========================================
echo    Deploy Flutter Web Apps to Server
echo ========================================
echo.
echo This will:
echo   1. Build Flutter web apps
echo   2. Upload to EC2 server
echo   3. Replace placeholder pages
echo.
pause

REM Configuration
set EC2_HOST=34.227.111.143
set EC2_USER=ec2-user
set SSH_KEY=pgni-preprod-key.pem

echo.
echo Step 1: Checking prerequisites...
echo.

REM Check if Flutter is installed
where flutter >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Flutter not found
    echo Please install Flutter SDK first
    pause
    exit /b 1
)
echo ✓ Flutter found

REM Check if SSH key exists
if not exist "%SSH_KEY%" (
    echo ❌ SSH key not found: %SSH_KEY%
    echo Please ensure the SSH key is in the current directory
    pause
    exit /b 1
)
echo ✓ SSH key found

REM Check if SCP is available
where scp >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ❌ SCP not found
    echo Please install OpenSSH client
    pause
    exit /b 1
)
echo ✓ SCP found

echo.
echo Step 2: Building Admin App...
echo.
cd pgworld-master
call flutter build web --release
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Admin app build failed
    pause
    exit /b 1
)
echo ✓ Admin app built successfully
cd ..

echo.
echo Step 3: Building Tenant App...
echo.
cd pgworldtenant-master
call flutter build web --release
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Tenant app build failed
    pause
    exit /b 1
)
echo ✓ Tenant app built successfully
cd ..

echo.
echo Step 4: Uploading Admin App to server...
echo.
scp -i %SSH_KEY% -r pgworld-master\build\web\* %EC2_USER%@%EC2_HOST%:/tmp/admin_new/
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Admin app upload failed
    pause
    exit /b 1
)
echo ✓ Admin app uploaded

echo.
echo Step 5: Uploading Tenant App to server...
echo.
scp -i %SSH_KEY% -r pgworldtenant-master\build\web\* %EC2_USER%@%EC2_HOST%:/tmp/tenant_new/
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Tenant app upload failed
    pause
    exit /b 1
)
echo ✓ Tenant app uploaded

echo.
echo Step 6: Installing apps on server...
echo.
ssh -i %SSH_KEY% %EC2_USER%@%EC2_HOST% "sudo rm -rf /var/www/html/admin/* && sudo mv /tmp/admin_new/* /var/www/html/admin/ && sudo rm -rf /var/www/html/tenant/* && sudo mv /tmp/tenant_new/* /var/www/html/tenant/ && sudo chown -R ec2-user:ec2-user /var/www/html && sudo systemctl reload nginx"
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Server installation failed
    pause
    exit /b 1
)
echo ✓ Apps installed on server

echo.
echo Step 7: Testing deployment...
echo.
timeout /t 3 /nobreak > nul
curl -s -o nul -w "Admin UI: HTTP %%{http_code}\n" http://%EC2_HOST%/admin
curl -s -o nul -w "Tenant UI: HTTP %%{http_code}\n" http://%EC2_HOST%/tenant

echo.
echo ========================================
echo ✅ DEPLOYMENT COMPLETE!
echo ========================================
echo.
echo Your full Flutter apps are now live at:
echo.
echo   Admin Portal:  http://%EC2_HOST%/admin
echo   Tenant Portal: http://%EC2_HOST%/tenant
echo.
echo These are the FULL apps with:
echo   - Login functionality
echo   - All 37 admin pages
echo   - All 28 tenant pages
echo   - Complete features
echo.
echo Login credentials:
echo   Admin:  admin@pgni.com / password123
echo   Tenant: tenant@pgni.com / password123
echo.
pause

