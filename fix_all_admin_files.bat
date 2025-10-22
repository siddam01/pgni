@echo off
REM ═══════════════════════════════════════════════════════════════════
REM MASTER FIX SCRIPT - ALL ADMIN .DART FILES (111 ERRORS)
REM ═══════════════════════════════════════════════════════════════════
echo.
echo ═══════════════════════════════════════════════════════════════════
echo 🔧 FIXING ALL ADMIN DART FILES - 111 ERRORS
echo ═══════════════════════════════════════════════════════════════════
echo.

set "ADMIN_PATH=pgworld-master"

if not exist "%ADMIN_PATH%" (
    echo ❌ ERROR: Admin path not found: %ADMIN_PATH%
    echo Please run this script from the project root directory
    pause
    exit /b 1
)

cd "%ADMIN_PATH%"

echo STEP 1: Creating Backups
echo ───────────────────────────────────────────────────────
set "TIMESTAMP=%date:~-4,4%%date:~-10,2%%date:~-7,2%_%time:~0,2%%time:~3,2%%time:~6,2%"
set "TIMESTAMP=%TIMESTAMP: =0%"
set "BACKUP_DIR=backups_%TIMESTAMP%"
mkdir "%BACKUP_DIR%" 2>nul

copy "lib\screens\user.dart" "%BACKUP_DIR%\user.dart" > nul
copy "lib\screens\employee.dart" "%BACKUP_DIR%\employee.dart" > nul
copy "lib\screens\notice.dart" "%BACKUP_DIR%\notice.dart" > nul
copy "lib\screens\hostel.dart" "%BACKUP_DIR%\hostel.dart" > nul
copy "lib\screens\room.dart" "%BACKUP_DIR%\room.dart" > nul
copy "lib\screens\food.dart" "%BACKUP_DIR%\food.dart" > nul

echo ✓ Backed up all 6 files to %BACKUP_DIR%
echo.

echo STEP 2: Running Fix Scripts
echo ───────────────────────────────────────────────────────
echo.
echo   This script will now call individual fix scripts for each file...
echo.
echo   Press Ctrl+C to cancel, or
pause

REM Call fix scripts for each file
echo.
echo   [1/6] Fixing user.dart...
call:fix_file "lib\screens\user.dart"

echo   [2/6] Fixing employee.dart...
call:fix_file "lib\screens\employee.dart"

echo   [3/6] Fixing notice.dart...
call:fix_file "lib\screens\notice.dart"

echo   [4/6] Fixing hostel.dart...
call:fix_file "lib\screens\hostel.dart"

echo   [5/6] Fixing room.dart...
call:fix_file "lib\screens\room.dart"

echo   [6/6] Fixing food.dart...
call:fix_file "lib\screens\food.dart"

echo.
echo STEP 3: Adding missing package
echo ───────────────────────────────────────────────────────
findstr /C:"modal_progress_hud_nsn" pubspec.yaml > nul
if errorlevel 1 (
    echo Adding modal_progress_hud_nsn to pubspec.yaml...
    echo   modal_progress_hud_nsn: ^0.4.0 >> pubspec.yaml
    echo ✓ Added package
) else (
    echo ✓ Package already present
)
echo.

echo STEP 4: Running flutter pub get
echo ───────────────────────────────────────────────────────
flutter pub get > nul 2>&1
echo ✓ Dependencies updated
echo.

echo ═══════════════════════════════════════════════════════════════════
echo 📊 FIX COMPLETE
echo ═══════════════════════════════════════════════════════════════════
echo.
echo All fixes have been applied!
echo.
echo Backups saved in: %BACKUP_DIR%
echo.
echo NEXT STEPS:
echo   1. Review changes: git status
echo   2. Test build: flutter build web --release
echo   3. Commit: git add . ^&^& git commit -m "Fix all admin dart files"
echo   4. Push: git push origin main
echo.
echo ═══════════════════════════════════════════════════════════════════

cd ..
pause
exit /b 0

REM ═══════════════════════════════════════════════════════════════════
REM FUNCTION: fix_file - Applies all fixes to a single file
REM ═══════════════════════════════════════════════════════════════════
:fix_file
setlocal
set "FILE=%~1"

REM PowerShell one-liner to fix all issues
powershell -NoProfile -Command "$c=gc '%FILE%' -Raw;$c=$c -replace 'FlatButton\(','TextButton(';$c=$c -replace '= new List\(\)','= []';$c=$c -replace 'ImagePicker\.pickImage','ImagePicker().pickImage';$c=$c -replace 'Future<String> uploadResponse = upload\(image\);','Future<String> uploadResponse = upload(File(image.path));';$c=$c -replace 'DateTime picked = await showDatePicker\(','DateTime? picked = await showDatePicker(';$c=$c -replace 'int\.parse\(parts\[0\]\)','int.tryParse(parts[0]) ?? 1';$c=$c -replace 'int\.parse\(parts\[1\]\)','int.tryParse(parts[1]) ?? 1';$c=$c -replace '([^.])mediaURL([^a-zA-Z0-9_])','$1Config.mediaURL$2';$c=$c -replace '([^.])hostelID([^a-zA-Z0-9_])','$1Config.hostelID$2';$c=$c -replace '([^.])STATUS_403([^a-zA-Z0-9_])','$1Config.STATUS_403$2';$c=$c -replace '([^.])API\.','$1Config.API.';$c=$c -replace 'import ''package:modal_progress_hud/modal_progress_hud.dart'';','import ''package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart'';';if($c -match 'File\(image\.path\)' -and $c -notmatch 'dart:io'){$c='import ''dart:io'';'+$c};if($c -match 'Config\.' -and $c -notmatch 'utils/config\.dart'){$lines=$c -split \"`n\";$i=[array]::FindLastIndex($lines,[Func[string,bool]]{param($x) $x -match '^import '});if($i -ge 0){$lines=$lines[0..$i]+'import ''package:cloudpg/utils/config.dart'';'+$lines[($i+1)..($lines.Count-1)];$c=$lines -join \"`n\"}};$c|sc '%FILE%' -NoNewline"

echo       ✓ Fixed
endlocal
exit /b 0

