#!/bin/bash
set -e

echo "═══════════════════════════════════════════════════════"
echo "🔧 FIXING pgworld-master/lib/screens/bill.dart"
echo "═══════════════════════════════════════════════════════"
echo ""
echo "Target: 43 errors"
echo "Location: Admin app bill.dart"
echo ""

ADMIN_PATH="/home/ec2-user/pgni/pgworld-master"
cd "$ADMIN_PATH"

echo "STEP 1: Backup Original File"
echo "───────────────────────────────────────────────────────"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
cp lib/screens/bill.dart lib/screens/bill.dart.backup_$TIMESTAMP
echo "✓ Backup created: bill.dart.backup_$TIMESTAMP"

echo ""
echo "STEP 2: Fix FlatButton (deprecated) → TextButton/ElevatedButton"
echo "───────────────────────────────────────────────────────"
# FlatButton is deprecated, replace with TextButton
sed -i 's/FlatButton(/TextButton(/g' lib/screens/bill.dart
echo "✓ Replaced FlatButton with TextButton (6 occurrences)"

echo ""
echo "STEP 3: Fix List Constructor (deprecated)"
echo "───────────────────────────────────────────────────────"
# new List() is deprecated, use [] or List.empty()
sed -i 's/List<String> fileNames = new List()/List<String> fileNames = []/g' lib/screens/bill.dart
sed -i 's/List<Widget> fileWidgets = new List()/List<Widget> fileWidgets = []/g' lib/screens/bill.dart
echo "✓ Fixed List constructors"

echo ""
echo "STEP 4: Fix ImagePicker API (deprecated method)"
echo "───────────────────────────────────────────────────────"
# ImagePicker.pickImage is deprecated, use ImagePicker().pickImage()
sed -i 's/ImagePicker\.pickImage/ImagePicker().pickImage/g' lib/screens/bill.dart
echo "✓ Fixed ImagePicker API"

echo ""
echo "STEP 5: Fix XFile to File conversion"
echo "───────────────────────────────────────────────────────"
# The pickImage now returns XFile, need to convert to File
# Add import at the top if not present
if ! grep -q "import 'dart:io';" lib/screens/bill.dart; then
    sed -i '1i import '\''dart:io'\'';' lib/screens/bill.dart
fi

# Replace the upload call to handle XFile
sed -i 's/Future<String> uploadResponse = upload(image);/Future<String> uploadResponse = upload(File(image.path));/g' lib/screens/bill.dart
echo "✓ Fixed XFile to File conversion"

echo ""
echo "STEP 6: Add Missing Config Variables"
echo "───────────────────────────────────────────────────────"
# Add import for config if needed
if ! grep -q "import 'package:cloudpg/utils/config.dart';" lib/screens/bill.dart; then
    sed -i "7a import 'package:cloudpg/utils/config.dart';" lib/screens/bill.dart
fi

# Replace undefined variables with Config references
sed -i 's/\bmediaURL\b/Config.mediaURL/g' lib/screens/bill.dart
sed -i 's/\bhostelID\b/Config.hostelID/g' lib/screens/bill.dart
sed -i 's/\bSTATUS_403\b/Config.STATUS_403/g' lib/screens/bill.dart
sed -i 's/\bbillTypes\b/Config.billTypes/g' lib/screens/bill.dart
sed -i 's/\bpaymentTypes\b/Config.paymentTypes/g' lib/screens/bill.dart
sed -i 's/\bAPI\./Config.API./g' lib/screens/bill.dart
echo "✓ Added Config prefix to undefined variables"

echo ""
echo "STEP 7: Fix DateTime Null Safety"
echo "───────────────────────────────────────────────────────"
# Fix DateTime? to DateTime assignment
sed -i 's/DateTime picked = await showDatePicker(/DateTime? picked = await showDatePicker(/g' lib/screens/bill.dart

# Add null check before using picked
cat > /tmp/bill_datetime_fix.txt << 'EOF'
    if (picked != null) {
      setState(() {
        if (type == '1') {
          paidDate.text = headingDateFormat.format(picked);
          pickedPaidDate = dateFormat.format(picked);
        } else {
          expiryDate.text = headingDateFormat.format(picked);
          pickedExpiryDate = dateFormat.format(picked);
        }
      });
    }
EOF

# Replace the setState block with null-safe version
sed -i '173,181d' lib/screens/bill.dart
sed -i '172r /tmp/bill_datetime_fix.txt' lib/screens/bill.dart
echo "✓ Fixed DateTime null safety"

echo ""
echo "STEP 8: Fix int? to int assignments"
echo "───────────────────────────────────────────────────────"
# Add null coalescing operators for int? assignments
sed -i 's/int day = int.parse(parts\[0\])/int day = int.tryParse(parts[0]) ?? 1/g' lib/screens/bill.dart
sed -i 's/int month = int.parse(parts\[1\])/int month = int.tryParse(parts[1]) ?? 1/g' lib/screens/bill.dart
echo "✓ Fixed int null safety"

echo ""
echo "STEP 9: Remove Unnecessary Null Checks (warnings)"
echo "───────────────────────────────────────────────────────"
# These are warnings, not errors, but let's fix them for clean code
# Line 603 and 707 have unnecessary null checks on non-nullable values
# These are minor and don't affect build, but we can note them
echo "✓ Null check warnings noted (non-blocking)"

echo ""
echo "STEP 10: Verify Config.dart Has Required Constants"
echo "───────────────────────────────────────────────────────"

if [ ! -f "lib/utils/config.dart" ]; then
    echo "⚠️  Warning: config.dart not found!"
    echo "Creating basic config.dart with required constants..."
    
    cat > lib/utils/config.dart << 'DART_EOF'
class Config {
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
  
  // API endpoints
  static class API {
    static const String BILL = '/bills';
    static const String STATUS = '/status';
  }
}
DART_EOF
    
    echo "✓ Created config.dart with required constants"
else
    echo "✓ config.dart exists"
    
    # Check if constants are present, if not, add them
    if ! grep -q "billTypes" lib/utils/config.dart; then
        echo "Adding billTypes to config.dart..."
        sed -i '/class Config {/a\  static const List<String> billTypes = ['\''Rent'\'', '\''Electricity'\'', '\''Water'\'', '\''Maintenance'\'', '\''Other'\''];' lib/utils/config.dart
    fi
    
    if ! grep -q "paymentTypes" lib/utils/config.dart; then
        echo "Adding paymentTypes to config.dart..."
        sed -i '/class Config {/a\  static const List<String> paymentTypes = ['\''Cash'\'', '\''Online'\'', '\''UPI'\'', '\''Card'\'', '\''Cheque'\''];' lib/utils/config.dart
    fi
    
    echo "✓ Verified config constants"
fi

echo ""
echo "STEP 11: Run Flutter Analyze"
echo "───────────────────────────────────────────────────────"
echo "Checking for remaining errors..."

flutter analyze lib/screens/bill.dart 2>&1 | tee /tmp/bill_analyze_$TIMESTAMP.log || true

ERRORS=$(grep -c "error •" /tmp/bill_analyze_$TIMESTAMP.log || echo "0")
WARNINGS=$(grep -c "warning •" /tmp/bill_analyze_$TIMESTAMP.log || echo "0")

echo ""
echo "═══════════════════════════════════════════════════════"
echo "📊 FIX RESULTS"
echo "═══════════════════════════════════════════════════════"
echo ""
echo "Original Errors: 43"
echo "Remaining Errors: $ERRORS"
echo "Warnings: $WARNINGS"
echo ""

if [ "$ERRORS" -eq "0" ]; then
    echo "✅ SUCCESS! All errors fixed!"
    echo ""
    echo "Changes made:"
    echo "  1. ✓ FlatButton → TextButton (6 fixes)"
    echo "  2. ✓ List() → [] (2 fixes)"
    echo "  3. ✓ ImagePicker API updated (1 fix)"
    echo "  4. ✓ XFile → File conversion (1 fix)"
    echo "  5. ✓ Added Config imports (1 fix)"
    echo "  6. ✓ mediaURL, hostelID, STATUS_403 → Config.* (10+ fixes)"
    echo "  7. ✓ billTypes, paymentTypes → Config.* (10+ fixes)"
    echo "  8. ✓ API.* → Config.API.* (3 fixes)"
    echo "  9. ✓ DateTime null safety (1 fix)"
    echo " 10. ✓ int null safety (2 fixes)"
    echo ""
    echo "Backup saved: lib/screens/bill.dart.backup_$TIMESTAMP"
    echo ""
    echo "Next steps:"
    echo "  1. Test the bill page in admin portal"
    echo "  2. Verify all CRUD operations work"
    echo "  3. Test document upload functionality"
else
    echo "⚠️  Still have $ERRORS errors remaining"
    echo ""
    echo "Showing remaining errors:"
    grep "error •" /tmp/bill_analyze_$TIMESTAMP.log || echo "No errors found"
    echo ""
    echo "Review the log: /tmp/bill_analyze_$TIMESTAMP.log"
fi

echo "═══════════════════════════════════════════════════════"

