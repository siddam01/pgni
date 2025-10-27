#!/usr/bin/env python3
"""
Automated Flutter 3.x Migration Script
Fixes null-safety, deprecated APIs, and common compilation errors
"""

import os
import re
from pathlib import Path

# Directory to process
FLUTTER_DIR = "pgworld-master/lib"

def fix_list_constructor(content):
    """Fix deprecated List() constructor"""
    # List() -> []
    content = re.sub(r'new\s+List\(\)', '[]', content)
    content = re.sub(r'List\(\)', '[]', content)
    content = re.sub(r'List<(\w+)>\(\)', r'<\1>[]', content)
    content = re.sub(r'new\s+List<(\w+)>\(\)', r'<\1>[]', content)
    return content

def fix_flatbutton(content):
    """Replace FlatButton with TextButton"""
    content = re.sub(r'new\s+FlatButton\(', 'TextButton(', content)
    content = re.sub(r'FlatButton\(', 'TextButton(', content)
    return content

def fix_iconslideaction(content):
    """Fix deprecated IconSlideAction"""
    content = re.sub(r'new\s+IconSlideAction\(', 'SlidableAction(', content)
    content = re.sub(r'IconSlideAction\(', 'SlidableAction(', content)
    return content

def fix_slidable_action_pane(content):
    """Fix deprecated SlidableDrawerActionPane"""
    content = re.sub(r'new\s+SlidableDrawerActionPane\(\)', 'SlidableStrokeActionPane()', content)
    content = re.sub(r'SlidableDrawerActionPane\(\)', 'SlidableStrokeActionPane()', content)
    # Remove actionPane parameter and replace with new API
    content = re.sub(r'actionPane:\s*new\s+Slidable\w+ActionPane\(\),?\s*\n', '', content)
    content = re.sub(r'actionPane:\s*Slidable\w+ActionPane\(\),?\s*\n', '', content)
    return content

def fix_image_picker(content):
    """Fix deprecated ImagePicker API"""
    # ImagePicker.pickImage -> ImagePicker().pickImage
    content = re.sub(r'ImagePicker\.pickImage\(', 'ImagePicker().pickImage(', content)
    return content

def fix_nullable_fields(content):
    """Add nullable markers where needed"""
    # Fix common nullable assignments
    content = re.sub(r'(\w+)\s*=\s*prefs\.getString\([\'"](\w+)[\'"]\);', r'\1 = prefs.getString(\'\2\') ?? \'\';', content)
    content = re.sub(r'(\w+)\s*=\s*filter\[[\'"]([\w_]+)[\'"]\];', r'\1 = filter[\'\2\'] ?? \'\';', content)
    return content

def fix_non_nullable_fields(content):
    """Add late keyword or initialization for non-nullable fields"""
    # ScrollController _controller; -> late ScrollController _controller;
    content = re.sub(r'^\s*ScrollController\s+(\w+);$', r'  late ScrollController \1;', content, flags=re.MULTILINE)
    
    # String field; -> late String field; or String? field;
    lines = content.split('\n')
    fixed_lines = []
    for line in lines:
        # If it's a field declaration without initialization
        if re.match(r'^\s*String\s+\w+;$', line) and 'late' not in line and '?' not in line:
            line = line.replace('String ', 'late String ')
        if re.match(r'^\s*int\s+\w+;$', line) and 'late' not in line and '?' not in line:
            line = line.replace('int ', 'late int ')
        fixed_lines.append(line)
    content = '\n'.join(fixed_lines)
    
    return content

def fix_default_constants(content):
    """Add Config. prefix to default constants"""
    content = re.sub(r'\bdefaultOffset\b', 'Config.defaultOffset', content)
    content = re.sub(r'\bdefaultLimit\b', 'Config.defaultLimit', content)
    content = re.sub(r'\bSTATUS_403\b', 'Config.STATUS_403', content)
    content = re.sub(r'(?<!Config\.)hostelID\b', 'Config.hostelID', content)
    content = re.sub(r'(?<!Config\.)userID\b', 'Config.userID', content)
    return content

def fix_null_assignments(content):
    """Fix null assignments to non-nullable types"""
    # Add ! operator where needed
    content = re.sub(r'Config\.hostelID\)', 'Config.hostelID!)', content)
    content = re.sub(r'Config\.userID\)', 'Config.userID!)', content)
    # Fix null passed to constructors - make them nullable with ?
    return content

def fix_range_slider(content):
    """Fix RangeSlider import and usage"""
    if 'rangeslider.RangeSlider' in content:
        # Add import if not present
        if 'package:flutter/material.dart' in content and 'RangeSlider' not in content:
            content = content.replace(
                "import 'package:flutter/material.dart';",
                "import 'package:flutter/material.dart';\n// RangeSlider is now built-in to Flutter"
            )
        # Replace rangeslider.RangeSlider with built-in RangeSlider
        content = re.sub(r'rangeslider\.RangeSlider', 'RangeSlider', content)
    return content

def fix_date_picker(content):
    """Fix DateRangePicker"""
    content = re.sub(r'DateRagePicker\.showDatePicker', 'showDateRangePicker', content)
    return content

def add_config_import(content):
    """Ensure Config is imported"""
    if "import '../utils/config.dart';" not in content and "import 'config.dart';" not in content:
        if "import 'package:flutter/material.dart';" in content:
            content = content.replace(
                "import 'package:flutter/material.dart';",
                "import 'package:flutter/material.dart';\nimport '../utils/config.dart';"
            )
    return content

def process_file(filepath):
    """Process a single Dart file"""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original_content = content
        
        # Apply all fixes
        content = fix_list_constructor(content)
        content = fix_flatbutton(content)
        content = fix_iconslideaction(content)
        content = fix_slidable_action_pane(content)
        content = fix_image_picker(content)
        content = fix_nullable_fields(content)
        content = fix_non_nullable_fields(content)
        content = fix_default_constants(content)
        content = fix_null_assignments(content)
        content = fix_range_slider(content)
        content = fix_date_picker(content)
        content = add_config_import(content)
        
        # Only write if content changed
        if content != original_content:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"✓ Fixed: {filepath}")
            return True
        return False
    except Exception as e:
        print(f"✗ Error processing {filepath}: {e}")
        return False

def main():
    """Main function"""
    print("=" * 60)
    print("Flutter 3.x Migration Script")
    print("=" * 60)
    print()
    
    dart_files = list(Path(FLUTTER_DIR).rglob("*.dart"))
    print(f"Found {len(dart_files)} Dart files")
    print()
    
    fixed_count = 0
    for dart_file in dart_files:
        if process_file(dart_file):
            fixed_count += 1
    
    print()
    print("=" * 60)
    print(f"Completed! Fixed {fixed_count} files")
    print("=" * 60)
    print()
    print("Next steps:")
    print("1. Review the changes with: git diff")
    print("2. Test compilation: flutter build web --release")
    print("3. Fix any remaining manual issues")
    print()

if __name__ == "__main__":
    main()

