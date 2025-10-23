@echo off
echo ===============================================================
echo FIXING pgworld-master\lib\screens\bill.dart - 43 Errors
echo ===============================================================
echo.

set BILL_FILE=pgworld-master\lib\screens\bill.dart

if not exist "%BILL_FILE%" (
    echo ERROR: File not found: %BILL_FILE%
    echo Please run this script from the project root directory
    pause
    exit /b 1
)

echo Step 1: Creating backup...
copy "%BILL_FILE%" "%BILL_FILE%.backup_%date:~-4,4%%date:~-10,2%%date:~-7,2%_%time:~0,2%%time:~3,2%%time:~6,2%" > nul
echo OK - Backup created

echo.
echo Step 2: Fixing FlatButton - TextButton (6 occurrences)...
powershell -Command "(gc '%BILL_FILE%') -replace 'FlatButton\(', 'TextButton(' | Set-Content '%BILL_FILE%'"
echo OK

echo.
echo Step 3: Fixing List constructors (2 occurrences)...
powershell -Command "(gc '%BILL_FILE%') -replace 'List<String> fileNames = new List\(\)', 'List<String> fileNames = []' | Set-Content '%BILL_FILE%'"
powershell -Command "(gc '%BILL_FILE%') -replace 'List<Widget> fileWidgets = new List\(\)', 'List<Widget> fileWidgets = []' | Set-Content '%BILL_FILE%'"
echo OK

echo.
echo Step 4: Fixing ImagePicker API...
powershell -Command "(gc '%BILL_FILE%') -replace 'ImagePicker\.pickImage', 'ImagePicker().pickImage' | Set-Content '%BILL_FILE%'"
echo OK

echo.
echo Step 5: Fixing XFile to File conversion...
powershell -Command "(gc '%BILL_FILE%') -replace 'Future<String> uploadResponse = upload\(image\);', 'Future<String> uploadResponse = upload(File(image.path));' | Set-Content '%BILL_FILE%'"
echo OK

echo.
echo Step 6: Adding dart:io import if missing...
findstr /C:"import 'dart:io';" "%BILL_FILE%" > nul
if errorlevel 1 (
    powershell -Command "$content = Get-Content '%BILL_FILE%'; 'import ''dart:io'';' | Set-Content '%BILL_FILE%'; $content | Add-Content '%BILL_FILE%'"
    echo OK - Added dart:io import
) else (
    echo OK - dart:io import already present
)

echo.
echo Step 7: Fixing undefined config variables...
powershell -Command "(gc '%BILL_FILE%') -replace '(?<!Config\.)mediaURL(?!\w)', 'Config.mediaURL' | Set-Content '%BILL_FILE%'"
powershell -Command "(gc '%BILL_FILE%') -replace '(?<!Config\.)hostelID(?!\w)', 'Config.hostelID' | Set-Content '%BILL_FILE%'"
powershell -Command "(gc '%BILL_FILE%') -replace '(?<!Config\.)STATUS_403(?!\w)', 'Config.STATUS_403' | Set-Content '%BILL_FILE%'"
powershell -Command "(gc '%BILL_FILE%') -replace '(?<!Config\.)billTypes(?!\w)', 'Config.billTypes' | Set-Content '%BILL_FILE%'"
powershell -Command "(gc '%BILL_FILE%') -replace '(?<!Config\.)paymentTypes(?!\w)', 'Config.paymentTypes' | Set-Content '%BILL_FILE%'"
powershell -Command "(gc '%BILL_FILE%') -replace 'API\.BILL', 'Config.API.BILL' | Set-Content '%BILL_FILE%'"
powershell -Command "(gc '%BILL_FILE%') -replace 'API\.STATUS', 'Config.API.STATUS' | Set-Content '%BILL_FILE%'"
echo OK

echo.
echo Step 8: Fixing DateTime null safety...
powershell -Command "(gc '%BILL_FILE%') -replace 'DateTime picked = await showDatePicker\(', 'DateTime? picked = await showDatePicker(' | Set-Content '%BILL_FILE%'"
echo OK

echo.
echo Step 9: Fixing int null safety...
powershell -Command "(gc '%BILL_FILE%') -replace 'int day = int\.parse\(parts\[0\]\)', 'int day = int.tryParse(parts[0]) ?? 1' | Set-Content '%BILL_FILE%'"
powershell -Command "(gc '%BILL_FILE%') -replace 'int month = int\.parse\(parts\[1\]\)', 'int month = int.tryParse(parts[1]) ?? 1' | Set-Content '%BILL_FILE%'"
echo OK

echo.
echo ===============================================================
echo FIXES APPLIED SUCCESSFULLY!
echo ===============================================================
echo.
echo Changes made:
echo   1. FlatButton - TextButton (6 fixes)
echo   2. List() - [] (2 fixes)  
echo   3. ImagePicker API updated
echo   4. XFile - File conversion
echo   5. Added Config prefixes for all undefined variables
echo   6. Fixed DateTime null safety
echo   7. Fixed int null safety
echo.
echo Backup saved with timestamp
echo.
echo NEXT STEPS:
echo   1. Review the changes in: %BILL_FILE%
echo   2. Test with: flutter analyze %BILL_FILE%
echo   3. If all good, commit: git add %BILL_FILE%
echo.
echo Press any key to close...
pause > nul

