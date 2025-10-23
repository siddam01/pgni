#!/bin/bash
set -e

OLD_IP="13.221.117.236"
NEW_IP="54.227.101.30"

echo "════════════════════════════════════════════════════════"
echo "🔄 UPDATING ALL IP ADDRESSES IN REPOSITORY"
echo "════════════════════════════════════════════════════════"
echo ""
echo "Old IP: $OLD_IP"
echo "New IP: $NEW_IP"
echo ""

REPO_DIR="/home/ec2-user/pgni"
cd "$REPO_DIR"

# Count occurrences before
BEFORE_COUNT=$(grep -r "$OLD_IP" . 2>/dev/null | wc -l)
echo "Found $BEFORE_COUNT occurrences of old IP"

echo ""
echo "════════════════════════════════════════════════════════"
echo "Updating files..."
echo "════════════════════════════════════════════════════════"

# Update all .sh files
find . -name "*.sh" -type f ! -path "./.git/*" | while read file; do
    if grep -q "$OLD_IP" "$file" 2>/dev/null; then
        sed -i "s/$OLD_IP/$NEW_IP/g" "$file"
        echo "✓ Updated: $file"
    fi
done

# Update all .md files
find . -name "*.md" -type f ! -path "./.git/*" | while read file; do
    if grep -q "$OLD_IP" "$file" 2>/dev/null; then
        sed -i "s/$OLD_IP/$NEW_IP/g" "$file"
        echo "✓ Updated: $file"
    fi
done

# Update Dart config files in Flutter apps
find . -name "*.dart" -type f ! -path "./.git/*" -path "*/lib/*" | while read file; do
    if grep -q "$OLD_IP" "$file" 2>/dev/null; then
        sed -i "s/$OLD_IP/$NEW_IP/g" "$file"
        echo "✓ Updated: $file"
    fi
done

# Count occurrences after
AFTER_COUNT=$(grep -r "$OLD_IP" . 2>/dev/null | wc -l)

echo ""
echo "════════════════════════════════════════════════════════"
echo "Update Summary"
echo "════════════════════════════════════════════════════════"
echo "Before: $BEFORE_COUNT occurrences"
echo "After:  $AFTER_COUNT occurrences"
echo "Changed: $((BEFORE_COUNT - AFTER_COUNT)) instances"

if [ $AFTER_COUNT -gt 0 ]; then
    echo ""
    echo "⚠️  Still found $AFTER_COUNT occurrences:"
    grep -rn "$OLD_IP" . 2>/dev/null | head -20
else
    echo ""
    echo "✅ All occurrences updated successfully!"
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "Committing changes to git..."
echo "════════════════════════════════════════════════════════"

git add -A
git commit -m "Update all IPs from $OLD_IP to $NEW_IP" 2>&1 || echo "No changes to commit or commit failed"
git push origin main 2>&1 || echo "Push failed or already up to date"

echo ""
echo "✅ IP update complete!"

