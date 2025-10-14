@echo off
REM ========================================
REM PGNi - Load Test Data (Windows)
REM ========================================
echo.
echo ========================================
echo    PGNi - Load Test Data
echo ========================================
echo.
echo This will load test accounts into your database
echo.
echo You need to run this from AWS CloudShell or
echo a machine that has MySQL client and can access RDS.
echo.
echo ----------------------------------------
echo OPTION 1: Load via CloudShell (Recommended)
echo ----------------------------------------
echo.
echo 1. Open AWS CloudShell
echo 2. Run these commands:
echo.
echo    curl -O https://raw.githubusercontent.com/siddam01/pgni/main/LOAD_TEST_DATA.sh
echo    curl -O https://raw.githubusercontent.com/siddam01/pgni/main/CREATE_TEST_ACCOUNTS.sql
echo    chmod +x LOAD_TEST_DATA.sh
echo    ./LOAD_TEST_DATA.sh
echo.
echo ----------------------------------------
echo OPTION 2: Load via EC2
echo ----------------------------------------
echo.
echo 1. SSH to EC2 instance:
echo.
echo    ssh -i pgni-preprod-key.pem ec2-user@34.227.111.143
echo.
echo 2. Download and run the script:
echo.
echo    curl -O https://raw.githubusercontent.com/siddam01/pgni/main/LOAD_TEST_DATA.sh
echo    curl -O https://raw.githubusercontent.com/siddam01/pgni/main/CREATE_TEST_ACCOUNTS.sql
echo    chmod +x LOAD_TEST_DATA.sh
echo    ./LOAD_TEST_DATA.sh
echo.
echo ----------------------------------------
echo OPTION 3: Manual SQL Import
echo ----------------------------------------
echo.
echo 1. Open CREATE_TEST_ACCOUNTS.sql in a text editor
echo 2. Copy all SQL commands
echo 3. Connect to database using a MySQL client
echo 4. Paste and execute the SQL commands
echo.
echo Database Details:
echo   Host: database-pgni.cezawkgguojl.us-east-1.rds.amazonaws.com
echo   Port: 3306
echo   User: admin
echo   Database: pgworld
echo.
pause
echo.
echo ========================================
echo Do you want to copy the commands to clipboard?
echo ========================================
echo.
set /p copy_choice="Copy CloudShell commands to clipboard? (Y/N): "

if /i "%copy_choice%"=="Y" (
    echo curl -O https://raw.githubusercontent.com/siddam01/pgni/main/LOAD_TEST_DATA.sh > temp_commands.txt
    echo curl -O https://raw.githubusercontent.com/siddam01/pgni/main/CREATE_TEST_ACCOUNTS.sql >> temp_commands.txt
    echo chmod +x LOAD_TEST_DATA.sh >> temp_commands.txt
    echo ./LOAD_TEST_DATA.sh >> temp_commands.txt
    
    type temp_commands.txt | clip
    del temp_commands.txt
    
    echo.
    echo ✅ Commands copied to clipboard!
    echo.
    echo Now:
    echo 1. Open AWS CloudShell
    echo 2. Press Ctrl+V to paste
    echo 3. Press Enter to execute
    echo.
)

echo.
echo ========================================
echo After loading test data, you can login:
echo ========================================
echo.
echo ADMIN LOGIN:
echo   Email: admin@pgni.com
echo   Password: password123
echo.
echo PG OWNER LOGIN:
echo   Email: owner@pgni.com
echo   Password: password123
echo.
echo TENANT LOGIN:
echo   Email: tenant@pgni.com
echo   Password: password123
echo.
echo Run TEST_ALL_PAGES.bat to test all UI pages!
echo.
pause

