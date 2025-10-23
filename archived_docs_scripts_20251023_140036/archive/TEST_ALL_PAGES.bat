@echo off
REM ========================================
REM PGNi - Comprehensive UI Pages Test
REM ========================================
echo.
echo ========================================
echo    PGNi - UI Pages Validation Test
echo ========================================
echo.
echo This script will help you test ALL 65 UI pages
echo.
echo TOTAL PAGES:
echo   - Admin App: 37 pages
echo   - Tenant App: 28 pages
echo.
echo ----------------------------------------
echo SELECT TEST MODE:
echo ----------------------------------------
echo 1. Test Admin App (PG Owner Portal)
echo 2. Test Tenant App (Resident Portal)
echo 3. Test Both Apps (Full System)
echo 4. Generate Test Report
echo 5. Exit
echo ----------------------------------------
echo.

set /p choice="Enter your choice (1-5): "

if "%choice%"=="1" goto test_admin
if "%choice%"=="2" goto test_tenant
if "%choice%"=="3" goto test_both
if "%choice%"=="4" goto generate_report
if "%choice%"=="5" goto end
goto invalid

:test_admin
echo.
echo ========================================
echo Testing Admin App (37 Pages)
echo ========================================
echo.
echo Starting Admin App in Chrome...
echo.
cd pgworld-master
echo.
echo DEMO LOGIN CREDENTIALS:
echo   Username: demo@pgni.com
echo   Password: demo123
echo.
echo PAGES TO TEST:
echo   1. Login Screen
echo   2. Dashboard Home
echo   3. Rooms Management
echo   4. Tenants Management
echo   5. Bills Management
echo   6. Reports
echo   7. Settings
echo   ... and 30 more detail pages
echo.
echo After the app opens:
echo   1. Login with demo credentials
echo   2. Click each bottom tab (6 tabs total)
echo   3. Click items in lists to see detail pages
echo   4. Test search and filters
echo   5. Try create/edit forms
echo.
pause
echo.
echo Launching...
call flutter run -d chrome
goto end

:test_tenant
echo.
echo ========================================
echo Testing Tenant App (28 Pages)
echo ========================================
echo.
echo Starting Tenant App in Chrome...
echo.
cd pgworldtenant-master
echo.
echo DEMO LOGIN CREDENTIALS:
echo   Username: tenant@test.com
echo   Password: tenant123
echo.
echo PAGES TO TEST:
echo   1. Login Screen
echo   2. Dashboard - Notices Tab
echo   3. Dashboard - Rents Tab
echo   4. Dashboard - Issues Tab
echo   5. Settings
echo   ... and 23 more pages
echo.
echo After the app opens:
echo   1. Login with demo credentials
echo   2. Click each dashboard tab (3 tabs)
echo   3. Navigate to Settings
echo   4. Test all menu options
echo   5. Check food menu, services, etc.
echo.
pause
echo.
echo Launching...
call flutter run -d chrome
goto end

:test_both
echo.
echo ========================================
echo Testing Both Apps (Full System)
echo ========================================
echo.
echo This will open TWO browser windows:
echo   1. Admin App (localhost:50001)
echo   2. Tenant App (localhost:50002)
echo.
echo You can test both simultaneously!
echo.
pause
echo.
echo Starting Admin App...
cd pgworld-master
start cmd /k "flutter run -d chrome --web-port=50001"
timeout /t 5
echo.
echo Starting Tenant App...
cd ..\pgworldtenant-master
start cmd /k "flutter run -d chrome --web-port=50002"
echo.
echo Both apps are launching...
echo Check your browser for two tabs!
echo.
pause
goto end

:generate_report
echo.
echo ========================================
echo Generating UI Test Report
echo ========================================
echo.
echo Creating comprehensive test report...
echo.

> UI_TEST_REPORT.txt echo UI PAGES TEST REPORT
>> UI_TEST_REPORT.txt echo Generated: %date% %time%
>> UI_TEST_REPORT.txt echo ========================================
>> UI_TEST_REPORT.txt echo.
>> UI_TEST_REPORT.txt echo ADMIN APP - 37 PAGES
>> UI_TEST_REPORT.txt echo ----------------------------------------
>> UI_TEST_REPORT.txt echo [ ] 1. Login Screen
>> UI_TEST_REPORT.txt echo [ ] 2. Dashboard Home
>> UI_TEST_REPORT.txt echo [ ] 3. Rooms Management
>> UI_TEST_REPORT.txt echo [ ] 4. Tenants Management
>> UI_TEST_REPORT.txt echo [ ] 5. Bills Management
>> UI_TEST_REPORT.txt echo [ ] 6. Reports
>> UI_TEST_REPORT.txt echo [ ] 7. Settings
>> UI_TEST_REPORT.txt echo [ ] 8. Properties/Hostels List
>> UI_TEST_REPORT.txt echo [ ] 9. Property Details
>> UI_TEST_REPORT.txt echo [ ] 10. Add/Edit Property
>> UI_TEST_REPORT.txt echo [ ] 11. Room Details
>> UI_TEST_REPORT.txt echo [ ] 12. Add/Edit Room
>> UI_TEST_REPORT.txt echo [ ] 13. User/Tenant List
>> UI_TEST_REPORT.txt echo [ ] 14. User Profile
>> UI_TEST_REPORT.txt echo [ ] 15. Add/Edit User
>> UI_TEST_REPORT.txt echo [ ] 16. User Filter
>> UI_TEST_REPORT.txt echo [ ] 17. Bills List
>> UI_TEST_REPORT.txt echo [ ] 18. Bill Details
>> UI_TEST_REPORT.txt echo [ ] 19. Bill Filter
>> UI_TEST_REPORT.txt echo [ ] 20. Invoices
>> UI_TEST_REPORT.txt echo [ ] 21. Payments
>> UI_TEST_REPORT.txt echo [ ] 22. Notices
>> UI_TEST_REPORT.txt echo [ ] 23. Notice Details
>> UI_TEST_REPORT.txt echo [ ] 24. Notes
>> UI_TEST_REPORT.txt echo [ ] 25. Note Details
>> UI_TEST_REPORT.txt echo [ ] 26. Issues/Complaints
>> UI_TEST_REPORT.txt echo [ ] 27. Issue Filter
>> UI_TEST_REPORT.txt echo [ ] 28. Issue Details
>> UI_TEST_REPORT.txt echo [ ] 29. Employees
>> UI_TEST_REPORT.txt echo [ ] 30. Employee Details
>> UI_TEST_REPORT.txt echo [ ] 31. Food Menu
>> UI_TEST_REPORT.txt echo [ ] 32. Logs
>> UI_TEST_REPORT.txt echo [ ] 33. Reports Dashboard
>> UI_TEST_REPORT.txt echo [ ] 34. Owner Registration
>> UI_TEST_REPORT.txt echo [ ] 35. Support
>> UI_TEST_REPORT.txt echo [ ] 36. Photo Gallery
>> UI_TEST_REPORT.txt echo [ ] 37. Room Filter
>> UI_TEST_REPORT.txt echo.
>> UI_TEST_REPORT.txt echo TENANT APP - 28 PAGES
>> UI_TEST_REPORT.txt echo ----------------------------------------
>> UI_TEST_REPORT.txt echo [ ] 1. Splash Screen
>> UI_TEST_REPORT.txt echo [ ] 2. Login
>> UI_TEST_REPORT.txt echo [ ] 3. Registration
>> UI_TEST_REPORT.txt echo [ ] 4. OTP Verification
>> UI_TEST_REPORT.txt echo [ ] 5. Dashboard - Notices
>> UI_TEST_REPORT.txt echo [ ] 6. Dashboard - Rents
>> UI_TEST_REPORT.txt echo [ ] 7. Dashboard - Issues
>> UI_TEST_REPORT.txt echo [ ] 8. PG/Hostel Search
>> UI_TEST_REPORT.txt echo [ ] 9. Hostel Details
>> UI_TEST_REPORT.txt echo [ ] 10. Room Details
>> UI_TEST_REPORT.txt echo [ ] 11. Room Booking
>> UI_TEST_REPORT.txt echo [ ] 12. My Room
>> UI_TEST_REPORT.txt echo [ ] 13. Rent Payment
>> UI_TEST_REPORT.txt echo [ ] 14. Payment History
>> UI_TEST_REPORT.txt echo [ ] 15. Bills
>> UI_TEST_REPORT.txt echo [ ] 16. Notices
>> UI_TEST_REPORT.txt echo [ ] 17. Notice Details
>> UI_TEST_REPORT.txt echo [ ] 18. Submit Issue
>> UI_TEST_REPORT.txt echo [ ] 19. My Issues
>> UI_TEST_REPORT.txt echo [ ] 20. Issue Details
>> UI_TEST_REPORT.txt echo [ ] 21. Food Menu
>> UI_TEST_REPORT.txt echo [ ] 22. Meal Schedule
>> UI_TEST_REPORT.txt echo [ ] 23. Meal History
>> UI_TEST_REPORT.txt echo [ ] 24. Services
>> UI_TEST_REPORT.txt echo [ ] 25. Profile
>> UI_TEST_REPORT.txt echo [ ] 26. Documents
>> UI_TEST_REPORT.txt echo [ ] 27. Settings
>> UI_TEST_REPORT.txt echo [ ] 28. Support
>> UI_TEST_REPORT.txt echo.
>> UI_TEST_REPORT.txt echo TEST RESULTS SUMMARY
>> UI_TEST_REPORT.txt echo ----------------------------------------
>> UI_TEST_REPORT.txt echo Total Pages Tested: __/65
>> UI_TEST_REPORT.txt echo Working Pages: __/65
>> UI_TEST_REPORT.txt echo Broken Pages: __/65
>> UI_TEST_REPORT.txt echo Success Rate: __%
>> UI_TEST_REPORT.txt echo.
>> UI_TEST_REPORT.txt echo ISSUES FOUND
>> UI_TEST_REPORT.txt echo ----------------------------------------
>> UI_TEST_REPORT.txt echo (Add any issues you find during testing)
>> UI_TEST_REPORT.txt echo.
>> UI_TEST_REPORT.txt echo.

echo.
echo ✓ Test report template created: UI_TEST_REPORT.txt
echo.
echo INSTRUCTIONS:
echo 1. Run the apps using options 1, 2, or 3
echo 2. Open UI_TEST_REPORT.txt in Notepad
echo 3. Mark [X] for each page you test successfully
echo 4. Note any issues you find
echo 5. Calculate final statistics
echo.
notepad UI_TEST_REPORT.txt
goto end

:invalid
echo.
echo ❌ Invalid choice. Please select 1-5.
echo.
pause
goto menu

:end
echo.
echo ========================================
echo Test session complete!
echo ========================================
echo.
echo For detailed page inventory, see: UI_PAGES_INVENTORY.md
echo For test results, see: UI_TEST_REPORT.txt
echo.
pause

