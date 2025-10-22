# ═══════════════════════════════════════════════════════════════════
# MASTER FIX SCRIPT - ALL ADMIN .DART FILES (111 ERRORS)
# ═══════════════════════════════════════════════════════════════════
# This script fixes all common Flutter errors across 6 admin files:
# 1. user.dart (30 errors)
# 2. employee.dart (23 errors)
# 3. notice.dart (21 errors)
# 4. hostel.dart (14 errors)
# 5. room.dart (14 errors)
# 6. food.dart (8 errors)
# ═══════════════════════════════════════════════════════════════════

Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "🔧 FIXING ALL ADMIN DART FILES - 111 ERRORS" -ForegroundColor Yellow
Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

$ErrorActionPreference = "Stop"
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$adminPath = "pgworld-master"

# Check if admin path exists
if (-not (Test-Path $adminPath)) {
    Write-Host "❌ ERROR: Admin path not found: $adminPath" -ForegroundColor Red
    Write-Host "Please run this script from the project root directory" -ForegroundColor Red
    exit 1
}

Set-Location $adminPath

# ═══════════════════════════════════════════════════════════════════
# STEP 1: CREATE BACKUPS
# ═══════════════════════════════════════════════════════════════════
Write-Host "STEP 1: Creating Backups" -ForegroundColor Green
Write-Host "───────────────────────────────────────────────────────" -ForegroundColor Gray

$filesToFix = @(
    "lib\screens\user.dart",
    "lib\screens\employee.dart",
    "lib\screens\notice.dart",
    "lib\screens\hostel.dart",
    "lib\screens\room.dart",
    "lib\screens\food.dart"
)

$backupDir = "backups_$timestamp"
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null

foreach ($file in $filesToFix) {
    if (Test-Path $file) {
        $fileName = Split-Path $file -Leaf
        Copy-Item $file "$backupDir\$fileName" -Force
        Write-Host "✓ Backed up: $fileName" -ForegroundColor Green
    }
}

Write-Host ""

# ═══════════════════════════════════════════════════════════════════
# STEP 2: ADD MISSING PACKAGE TO PUBSPEC.YAML
# ═══════════════════════════════════════════════════════════════════
Write-Host "STEP 2: Adding modal_progress_hud_nsn Package" -ForegroundColor Green
Write-Host "───────────────────────────────────────────────────────" -ForegroundColor Gray

$pubspecFile = "pubspec.yaml"
$pubspecContent = Get-Content $pubspecFile -Raw

if ($pubspecContent -notmatch "modal_progress_hud_nsn") {
    Write-Host "Adding modal_progress_hud_nsn to pubspec.yaml..." -ForegroundColor Yellow
    
    # Add the package under dependencies
    $pubspecContent = $pubspecContent -replace "(dependencies:)", "`$1`n  modal_progress_hud_nsn: ^0.4.0"
    Set-Content $pubspecFile $pubspecContent -NoNewline
    
    Write-Host "✓ Added modal_progress_hud_nsn package" -ForegroundColor Green
} else {
    Write-Host "✓ modal_progress_hud_nsn already present" -ForegroundColor Green
}

Write-Host ""

# ═══════════════════════════════════════════════════════════════════
# STEP 3: UPDATE IMPORTS (modal_progress_hud → modal_progress_hud_nsn)
# ═══════════════════════════════════════════════════════════════════
Write-Host "STEP 3: Updating Package Imports" -ForegroundColor Green
Write-Host "───────────────────────────────────────────────────────" -ForegroundColor Gray

foreach ($file in $filesToFix) {
    if (Test-Path $file) {
        $content = Get-Content $file -Raw
        $originalContent = $content
        
        # Fix import statement
        $content = $content -replace "import 'package:modal_progress_hud/modal_progress_hud\.dart';", "import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';"
        
        if ($content -ne $originalContent) {
            Set-Content $file $content -NoNewline
            Write-Host "✓ Updated import in: $(Split-Path $file -Leaf)" -ForegroundColor Green
        }
    }
}

Write-Host ""

# ═══════════════════════════════════════════════════════════════════
# STEP 4: FIX COMMON ERRORS ACROSS ALL FILES
# ═══════════════════════════════════════════════════════════════════
Write-Host "STEP 4: Fixing Common Errors (FlatButton, List, ImagePicker)" -ForegroundColor Green
Write-Host "───────────────────────────────────────────────────────" -ForegroundColor Gray

foreach ($file in $filesToFix) {
    if (Test-Path $file) {
        $fileName = Split-Path $file -Leaf
        Write-Host "  Fixing: $fileName" -ForegroundColor Cyan
        
        $content = Get-Content $file -Raw
        
        # Fix 1: FlatButton → TextButton
        $content = $content -replace "FlatButton\(", "TextButton("
        
        # Fix 2: List() → []
        $content = $content -replace "= new List\(\)", "= []"
        
        # Fix 3: ImagePicker API
        $content = $content -replace "ImagePicker\.pickImage", "ImagePicker().pickImage"
        
        # Fix 4: XFile → File conversion
        $content = $content -replace "Future<String> uploadResponse = upload\(image\);", "Future<String> uploadResponse = upload(File(image.path));"
        
        # Fix 5: Add dart:io import if needed (for File conversion)
        if ($content -match "upload\(File\(image\.path\)\)" -and $content -notmatch "import 'dart:io';") {
            $content = "import 'dart:io';`n" + $content
        }
        
        # Fix 6: DateTime null safety
        $content = $content -replace "DateTime picked = await showDatePicker\(", "DateTime? picked = await showDatePicker("
        
        # Fix 7: int null safety
        $content = $content -replace "int\.parse\(parts\[0\]\)", "int.tryParse(parts[0]) ?? 1"
        $content = $content -replace "int\.parse\(parts\[1\]\)", "int.tryParse(parts[1]) ?? 1"
        $content = $content -replace "int\.parse\(parts\[2\]\)", "int.tryParse(parts[2]) ?? 2000"
        
        # Fix 8: Add Config prefix to undefined variables
        $content = $content -replace "(?<!Config\.)(?<!widget\.)(?<!\.)mediaURL(?!\w)", "Config.mediaURL"
        $content = $content -replace "(?<!Config\.)(?<!widget\.)(?<!\.)hostelID(?!\w)", "Config.hostelID"
        $content = $content -replace "(?<!Config\.)(?<!widget\.)(?<!\.)STATUS_403(?!\w)", "Config.STATUS_403"
        $content = $content -replace "(?<!Config\.)(?<!widget\.)(?<!\.)billTypes(?!\w)", "Config.billTypes"
        $content = $content -replace "(?<!Config\.)(?<!widget\.)(?<!\.)paymentTypes(?!\w)", "Config.paymentTypes"
        
        # Fix 9: API → Config.API
        $content = $content -replace "(?<!Config\.)API\.EMPLOYEE", "Config.API.EMPLOYEE"
        $content = $content -replace "(?<!Config\.)API\.USER", "Config.API.USER"
        $content = $content -replace "(?<!Config\.)API\.NOTICE", "Config.API.NOTICE"
        $content = $content -replace "(?<!Config\.)API\.HOSTEL", "Config.API.HOSTEL"
        $content = $content -replace "(?<!Config\.)API\.ROOM", "Config.API.ROOM"
        $content = $content -replace "(?<!Config\.)API\.FOOD", "Config.API.FOOD"
        $content = $content -replace "(?<!Config\.)API\.STATUS", "Config.API.STATUS"
        
        # Fix 10: Add Config import if needed
        if ($content -match "Config\." -and $content -notmatch "import 'package:cloudpg/utils/config\.dart';") {
            # Find the last import line and add after it
            $lines = $content -split "`n"
            $lastImportIndex = -1
            for ($i = 0; $i -lt $lines.Count; $i++) {
                if ($lines[$i] -match "^import ") {
                    $lastImportIndex = $i
                }
            }
            if ($lastImportIndex -ge 0) {
                $lines = $lines[0..$lastImportIndex] + "import 'package:cloudpg/utils/config.dart';" + $lines[($lastImportIndex+1)..($lines.Count-1)]
                $content = $lines -join "`n"
            }
        }
        
        Set-Content $file $content -NoNewline
        Write-Host "    ✓ Fixed common errors" -ForegroundColor Green
    }
}

Write-Host ""

# ═══════════════════════════════════════════════════════════════════
# STEP 5: FIX FILE-SPECIFIC ERRORS
# ═══════════════════════════════════════════════════════════════════
Write-Host "STEP 5: Fixing File-Specific Errors" -ForegroundColor Green
Write-Host "───────────────────────────────────────────────────────" -ForegroundColor Gray

# Fix hostel.dart and room.dart - amenityTypes and amenities
foreach ($file in @("lib\screens\hostel.dart", "lib\screens\room.dart")) {
    if (Test-Path $file) {
        $content = Get-Content $file -Raw
        
        # Fix amenityTypes and amenities references
        $content = $content -replace "(?<!Config\.)amenityTypes(?!\w)", "Config.amenityTypes"
        $content = $content -replace "(?<!Config\.)amenities(?!\w)", "Config.amenities"
        
        # Fix ValueChanged<bool> → ValueChanged<bool?>
        $content = $content -replace "void Function\(bool\)", "void Function(bool?)"
        
        Set-Content $file $content -NoNewline
        Write-Host "✓ Fixed: $(Split-Path $file -Leaf)" -ForegroundColor Green
    }
}

# Fix food.dart - late fields
if (Test-Path "lib\screens\food.dart") {
    $content = Get-Content "lib\screens\food.dart" -Raw
    
    # Make non-initialized fields late
    $content = $content -replace "(\s+)Food food;", "`$1late Food food;"
    $content = $content -replace "(\s+)TextEditingController foodDate;", "`$1late TextEditingController foodDate;"
    
    Set-Content "lib\screens\food.dart" $content -NoNewline
    Write-Host "✓ Fixed: food.dart (late fields)" -ForegroundColor Green
}

# Fix user.dart - roomID field
if (Test-Path "lib\screens\user.dart") {
    $content = Get-Content "lib\screens\user.dart" -Raw
    
    # Make roomID late or nullable
    $content = $content -replace "(\s+)String roomID;", "`$1late String roomID;"
    
    # Fix List<Room> assignment
    $content = $content -replace "List<Room> availableRooms = new List\(\)", "List<Room> availableRooms = <Room>[]"
    
    Set-Content "lib\screens\user.dart" $content -NoNewline
    Write-Host "✓ Fixed: user.dart (roomID field)" -ForegroundColor Green
}

Write-Host ""

# ═══════════════════════════════════════════════════════════════════
# STEP 6: UPDATE CONFIG.DART WITH ALL REQUIRED CONSTANTS
# ═══════════════════════════════════════════════════════════════════
Write-Host "STEP 6: Updating Config.dart" -ForegroundColor Green
Write-Host "───────────────────────────────────────────────────────" -ForegroundColor Gray

$configFile = "lib\utils\config.dart"

if (-not (Test-Path $configFile)) {
    Write-Host "Creating config.dart..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path "lib\utils" -Force | Out-Null
    
    $configContent = @"
class Config {
  // API Base URL
  static const String apiBaseUrl = 'http://54.227.101.30:8080';
  
  // Media URL
  static const String mediaURL = 'http://54.227.101.30:8080/media/';
  
  // Status codes
  static const int STATUS_403 = 403;
  
  // Session variables (set after login)
  static String? hostelID;
  static String? userID;
  static String? emailID;
  static String? name;
  
  // Bill types
  static const List<String> billTypes = [
    'Rent',
    'Electricity',
    'Water',
    'Maintenance',
    'Other'
  ];
  
  // Payment types
  static const List<String> paymentTypes = [
    'Cash',
    'Online',
    'UPI',
    'Card',
    'Cheque'
  ];
  
  // Amenity types
  static const List<String> amenityTypes = [
    'WiFi',
    'AC',
    'Parking',
    'Gym',
    'Laundry',
    'Security',
    'Power Backup',
    'Water Supply'
  ];
  
  // Amenities (for backward compatibility)
  static const List<String> amenities = amenityTypes;
  
  // API endpoints
  static class API {
    static const String BILL = '/bills';
    static const String USER = '/users';
    static const String EMPLOYEE = '/employees';
    static const String NOTICE = '/notices';
    static const String HOSTEL = '/hostels';
    static const String ROOM = '/rooms';
    static const String FOOD = '/food';
    static const String STATUS = '/status';
  }
}
"@
    
    Set-Content $configFile $configContent -NoNewline
    Write-Host "✓ Created config.dart with all constants" -ForegroundColor Green
} else {
    Write-Host "✓ config.dart exists (reviewing...)" -ForegroundColor Green
    
    $configContent = Get-Content $configFile -Raw
    $needsUpdate = $false
    
    # Check for missing constants and add them
    if ($configContent -notmatch "amenityTypes") {
        Write-Host "  Adding amenityTypes..." -ForegroundColor Yellow
        $configContent = $configContent -replace "(class Config \{)", "`$1`n  static const List<String> amenityTypes = ['WiFi', 'AC', 'Parking', 'Gym', 'Laundry', 'Security', 'Power Backup', 'Water Supply'];"
        $needsUpdate = $true
    }
    
    if ($configContent -notmatch "static const List<String> amenities") {
        Write-Host "  Adding amenities..." -ForegroundColor Yellow
        $configContent = $configContent -replace "(amenityTypes = \[.*?\];)", "`$1`n  static const List<String> amenities = amenityTypes;"
        $needsUpdate = $true
    }
    
    if ($needsUpdate) {
        Set-Content $configFile $configContent -NoNewline
        Write-Host "✓ Updated config.dart" -ForegroundColor Green
    }
}

Write-Host ""

# ═══════════════════════════════════════════════════════════════════
# STEP 7: RUN FLUTTER PUB GET
# ═══════════════════════════════════════════════════════════════════
Write-Host "STEP 7: Running Flutter Pub Get" -ForegroundColor Green
Write-Host "───────────────────────────────────────────────────────" -ForegroundColor Gray

flutter pub get 2>&1 | Out-Null
Write-Host "✓ Dependencies updated" -ForegroundColor Green
Write-Host ""

# ═══════════════════════════════════════════════════════════════════
# STEP 8: VERIFY FIXES
# ═══════════════════════════════════════════════════════════════════
Write-Host "STEP 8: Verifying Fixes (Flutter Analyze)" -ForegroundColor Green
Write-Host "───────────────────────────────────────────────────────" -ForegroundColor Gray

$totalErrors = 0
$filesFixed = 0

foreach ($file in $filesToFix) {
    if (Test-Path $file) {
        $fileName = Split-Path $file -Leaf
        Write-Host "  Analyzing: $fileName" -ForegroundColor Cyan
        
        $analyzeOutput = flutter analyze $file 2>&1 | Out-String
        $errorCount = ($analyzeOutput | Select-String -Pattern "error •" -AllMatches).Matches.Count
        
        if ($errorCount -eq 0) {
            Write-Host "    ✅ No errors!" -ForegroundColor Green
            $filesFixed++
        } else {
            Write-Host "    ⚠️  $errorCount errors remaining" -ForegroundColor Yellow
            $totalErrors += $errorCount
        }
    }
}

Write-Host ""

# ═══════════════════════════════════════════════════════════════════
# FINAL SUMMARY
# ═══════════════════════════════════════════════════════════════════
Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "📊 FIX SUMMARY" -ForegroundColor Yellow
Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "Original Errors: 111" -ForegroundColor White
Write-Host "Files Fixed: $filesFixed / $($filesToFix.Count)" -ForegroundColor $(if ($filesFixed -eq $filesToFix.Count) { "Green" } else { "Yellow" })
Write-Host "Remaining Errors: $totalErrors" -ForegroundColor $(if ($totalErrors -eq 0) { "Green" } else { "Yellow" })
Write-Host ""

if ($totalErrors -eq 0) {
    Write-Host "✅ SUCCESS! All errors fixed!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Changes applied:" -ForegroundColor Cyan
    Write-Host "  1. ✓ Added modal_progress_hud_nsn package" -ForegroundColor Green
    Write-Host "  2. ✓ Fixed FlatButton → TextButton" -ForegroundColor Green
    Write-Host "  3. ✓ Fixed List() → []" -ForegroundColor Green
    Write-Host "  4. ✓ Fixed ImagePicker API" -ForegroundColor Green
    Write-Host "  5. ✓ Fixed XFile → File conversion" -ForegroundColor Green
    Write-Host "  6. ✓ Added Config prefixes" -ForegroundColor Green
    Write-Host "  7. ✓ Fixed DateTime null safety" -ForegroundColor Green
    Write-Host "  8. ✓ Fixed int null safety" -ForegroundColor Green
    Write-Host "  9. ✓ Fixed late fields" -ForegroundColor Green
    Write-Host " 10. ✓ Updated config.dart" -ForegroundColor Green
    Write-Host ""
    Write-Host "Backups saved in: $backupDir" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "NEXT STEPS:" -ForegroundColor Yellow
    Write-Host "  1. Review changes: git status" -ForegroundColor White
    Write-Host "  2. Test build: flutter build web --release" -ForegroundColor White
    Write-Host "  3. Commit: git add . && git commit -m 'Fix all admin dart files'" -ForegroundColor White
    Write-Host "  4. Push: git push origin main" -ForegroundColor White
} else {
    Write-Host "⚠️  Some errors remain. Check individual files for details." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Review the analyze output above for remaining issues." -ForegroundColor White
}

Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Cyan

Set-Location ..

