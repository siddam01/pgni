#!/bin/bash
set -e

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

echo "═══════════════════════════════════════════════════════════════════"
echo "🔧 FIXING ALL ADMIN DART FILES - 111 ERRORS"
echo "═══════════════════════════════════════════════════════════════════"
echo ""

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
ADMIN_PATH="/home/ec2-user/pgni/pgworld-master"

if [ ! -d "$ADMIN_PATH" ]; then
    echo "❌ ERROR: Admin path not found: $ADMIN_PATH"
    echo "Please check the path and try again"
    exit 1
fi

cd "$ADMIN_PATH"

# ═══════════════════════════════════════════════════════════════════
# STEP 1: CREATE BACKUPS
# ═══════════════════════════════════════════════════════════════════
echo "STEP 1: Creating Backups"
echo "───────────────────────────────────────────────────────"

FILES_TO_FIX=(
    "lib/screens/user.dart"
    "lib/screens/employee.dart"
    "lib/screens/notice.dart"
    "lib/screens/hostel.dart"
    "lib/screens/room.dart"
    "lib/screens/food.dart"
)

BACKUP_DIR="backups_$TIMESTAMP"
mkdir -p "$BACKUP_DIR"

for file in "${FILES_TO_FIX[@]}"; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        cp "$file" "$BACKUP_DIR/$filename"
        echo "✓ Backed up: $filename"
    fi
done

echo ""

# ═══════════════════════════════════════════════════════════════════
# STEP 2: ADD MISSING PACKAGE TO PUBSPEC.YAML
# ═══════════════════════════════════════════════════════════════════
echo "STEP 2: Adding modal_progress_hud_nsn Package"
echo "───────────────────────────────────────────────────────"

if ! grep -q "modal_progress_hud_nsn" pubspec.yaml; then
    echo "Adding modal_progress_hud_nsn to pubspec.yaml..."
    sed -i '/dependencies:/a\  modal_progress_hud_nsn: ^0.4.0' pubspec.yaml
    echo "✓ Added modal_progress_hud_nsn package"
else
    echo "✓ modal_progress_hud_nsn already present"
fi

echo ""

# ═══════════════════════════════════════════════════════════════════
# STEP 3: UPDATE IMPORTS
# ═══════════════════════════════════════════════════════════════════
echo "STEP 3: Updating Package Imports"
echo "───────────────────────────────────────────────────────"

for file in "${FILES_TO_FIX[@]}"; do
    if [ -f "$file" ]; then
        sed -i "s|import 'package:modal_progress_hud/modal_progress_hud.dart';|import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';|g" "$file"
        echo "✓ Updated import in: $(basename $file)"
    fi
done

echo ""

# ═══════════════════════════════════════════════════════════════════
# STEP 4: FIX COMMON ERRORS ACROSS ALL FILES
# ═══════════════════════════════════════════════════════════════════
echo "STEP 4: Fixing Common Errors (FlatButton, List, ImagePicker)"
echo "───────────────────────────────────────────────────────"

for file in "${FILES_TO_FIX[@]}"; do
    if [ -f "$file" ]; then
        echo "  Fixing: $(basename $file)"
        
        # Fix 1: FlatButton → TextButton
        sed -i 's/FlatButton(/TextButton(/g' "$file"
        
        # Fix 2: List() → []
        sed -i 's/= new List()/= []/g' "$file"
        
        # Fix 3: ImagePicker API
        sed -i 's/ImagePicker\.pickImage/ImagePicker().pickImage/g' "$file"
        
        # Fix 4: XFile → File conversion
        sed -i 's/Future<String> uploadResponse = upload(image);/Future<String> uploadResponse = upload(File(image.path));/g' "$file"
        
        # Fix 5: Add dart:io import if needed
        if grep -q "upload(File(image.path))" "$file" && ! grep -q "import 'dart:io';" "$file"; then
            sed -i "1i import 'dart:io';" "$file"
        fi
        
        # Fix 6: DateTime null safety
        sed -i 's/DateTime picked = await showDatePicker(/DateTime? picked = await showDatePicker(/g' "$file"
        
        # Fix 7: int null safety
        sed -i 's/int\.parse(parts\[0\])/int.tryParse(parts[0]) ?? 1/g' "$file"
        sed -i 's/int\.parse(parts\[1\])/int.tryParse(parts[1]) ?? 1/g' "$file"
        sed -i 's/int\.parse(parts\[2\])/int.tryParse(parts[2]) ?? 2000/g' "$file"
        
        # Fix 8: Add Config prefix to undefined variables
        sed -i 's/\([^.]\)mediaURL\([^a-zA-Z0-9_]\)/\1Config.mediaURL\2/g' "$file"
        sed -i 's/\([^.]\)hostelID\([^a-zA-Z0-9_]\)/\1Config.hostelID\2/g' "$file"
        sed -i 's/\([^.]\)STATUS_403\([^a-zA-Z0-9_]\)/\1Config.STATUS_403\2/g' "$file"
        sed -i 's/\([^.]\)billTypes\([^a-zA-Z0-9_]\)/\1Config.billTypes\2/g' "$file"
        sed -i 's/\([^.]\)paymentTypes\([^a-zA-Z0-9_]\)/\1Config.paymentTypes\2/g' "$file"
        
        # Fix 9: API → Config.API
        sed -i 's/\([^.]\)API\.EMPLOYEE/\1Config.API.EMPLOYEE/g' "$file"
        sed -i 's/\([^.]\)API\.USER/\1Config.API.USER/g' "$file"
        sed -i 's/\([^.]\)API\.NOTICE/\1Config.API.NOTICE/g' "$file"
        sed -i 's/\([^.]\)API\.HOSTEL/\1Config.API.HOSTEL/g' "$file"
        sed -i 's/\([^.]\)API\.ROOM/\1Config.API.ROOM/g' "$file"
        sed -i 's/\([^.]\)API\.FOOD/\1Config.API.FOOD/g' "$file"
        sed -i 's/\([^.]\)API\.STATUS/\1Config.API.STATUS/g' "$file"
        
        # Fix 10: Add Config import if needed
        if grep -q "Config\." "$file" && ! grep -q "import 'package:cloudpg/utils/config.dart';" "$file"; then
            # Add after the last import
            sed -i "/^import /a import 'package:cloudpg/utils/config.dart';" "$file" | head -1
        fi
        
        echo "    ✓ Fixed common errors"
    fi
done

echo ""

# ═══════════════════════════════════════════════════════════════════
# STEP 5: FIX FILE-SPECIFIC ERRORS
# ═══════════════════════════════════════════════════════════════════
echo "STEP 5: Fixing File-Specific Errors"
echo "───────────────────────────────────────────────────────"

# Fix hostel.dart and room.dart - amenityTypes and amenities
for file in "lib/screens/hostel.dart" "lib/screens/room.dart"; do
    if [ -f "$file" ]; then
        sed -i 's/\([^.]\)amenityTypes\([^a-zA-Z0-9_]\)/\1Config.amenityTypes\2/g' "$file"
        sed -i 's/\([^.]\)amenities\([^a-zA-Z0-9_]\)/\1Config.amenities\2/g' "$file"
        sed -i 's/void Function(bool)/void Function(bool?)/g' "$file"
        echo "✓ Fixed: $(basename $file)"
    fi
done

# Fix food.dart - late fields
if [ -f "lib/screens/food.dart" ]; then
    sed -i 's/\(  \)Food food;/\1late Food food;/g' "lib/screens/food.dart"
    sed -i 's/\(  \)TextEditingController foodDate;/\1late TextEditingController foodDate;/g' "lib/screens/food.dart"
    echo "✓ Fixed: food.dart (late fields)"
fi

# Fix user.dart - roomID field
if [ -f "lib/screens/user.dart" ]; then
    sed -i 's/\(  \)String roomID;/\1late String roomID;/g' "lib/screens/user.dart"
    sed -i 's/List<Room> availableRooms = new List()/List<Room> availableRooms = <Room>[]/g' "lib/screens/user.dart"
    echo "✓ Fixed: user.dart (roomID field)"
fi

echo ""

# ═══════════════════════════════════════════════════════════════════
# STEP 6: UPDATE CONFIG.DART WITH ALL REQUIRED CONSTANTS
# ═══════════════════════════════════════════════════════════════════
echo "STEP 6: Updating Config.dart"
echo "───────────────────────────────────────────────────────"

CONFIG_FILE="lib/utils/config.dart"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Creating config.dart..."
    mkdir -p "lib/utils"
    
    cat > "$CONFIG_FILE" << 'DART_EOF'
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
DART_EOF
    
    echo "✓ Created config.dart with all constants"
else
    echo "✓ config.dart exists (adding missing constants if needed)"
    
    if ! grep -q "amenityTypes" "$CONFIG_FILE"; then
        echo "  Adding amenityTypes..."
        sed -i "/class Config {/a\  static const List<String> amenityTypes = ['WiFi', 'AC', 'Parking', 'Gym', 'Laundry', 'Security', 'Power Backup', 'Water Supply'];" "$CONFIG_FILE"
    fi
    
    if ! grep -q "static const List<String> amenities" "$CONFIG_FILE"; then
        echo "  Adding amenities..."
        sed -i "/amenityTypes =/a\  static const List<String> amenities = amenityTypes;" "$CONFIG_FILE"
    fi
fi

echo ""

# ═══════════════════════════════════════════════════════════════════
# STEP 7: RUN FLUTTER PUB GET
# ═══════════════════════════════════════════════════════════════════
echo "STEP 7: Running Flutter Pub Get"
echo "───────────────────────────────────────────────────────"

flutter pub get > /dev/null 2>&1
echo "✓ Dependencies updated"
echo ""

# ═══════════════════════════════════════════════════════════════════
# STEP 8: VERIFY FIXES
# ═══════════════════════════════════════════════════════════════════
echo "STEP 8: Verifying Fixes (Flutter Analyze)"
echo "───────────────────────────────────────────────────────"

TOTAL_ERRORS=0
FILES_FIXED=0

for file in "${FILES_TO_FIX[@]}"; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        echo "  Analyzing: $filename"
        
        ERROR_COUNT=$(flutter analyze "$file" 2>&1 | grep -c "error •" || echo "0")
        
        if [ "$ERROR_COUNT" -eq "0" ]; then
            echo "    ✅ No errors!"
            ((FILES_FIXED++))
        else
            echo "    ⚠️  $ERROR_COUNT errors remaining"
            ((TOTAL_ERRORS+=ERROR_COUNT))
        fi
    fi
done

echo ""

# ═══════════════════════════════════════════════════════════════════
# FINAL SUMMARY
# ═══════════════════════════════════════════════════════════════════
echo "═══════════════════════════════════════════════════════════════════"
echo "📊 FIX SUMMARY"
echo "═══════════════════════════════════════════════════════════════════"
echo ""
echo "Original Errors: 111"
echo "Files Fixed: $FILES_FIXED / ${#FILES_TO_FIX[@]}"
echo "Remaining Errors: $TOTAL_ERRORS"
echo ""

if [ "$TOTAL_ERRORS" -eq "0" ]; then
    echo "✅ SUCCESS! All errors fixed!"
    echo ""
    echo "Changes applied:"
    echo "  1. ✓ Added modal_progress_hud_nsn package"
    echo "  2. ✓ Fixed FlatButton → TextButton"
    echo "  3. ✓ Fixed List() → []"
    echo "  4. ✓ Fixed ImagePicker API"
    echo "  5. ✓ Fixed XFile → File conversion"
    echo "  6. ✓ Added Config prefixes"
    echo "  7. ✓ Fixed DateTime null safety"
    echo "  8. ✓ Fixed int null safety"
    echo "  9. ✓ Fixed late fields"
    echo " 10. ✓ Updated config.dart"
    echo ""
    echo "Backups saved in: $BACKUP_DIR"
    echo ""
    echo "NEXT STEPS:"
    echo "  1. Test build: flutter build web --release"
    echo "  2. Deploy: Copy build/web to /usr/share/nginx/html/admin/"
    echo "  3. Reload Nginx: sudo systemctl reload nginx"
else
    echo "⚠️  Some errors remain. Check individual files for details."
fi

echo "═══════════════════════════════════════════════════════════════════"

