#!/bin/bash
#===============================================================================
# EMERGENCY DIAGNOSTIC - Flutter Build Stuck for 2+ Days
#===============================================================================

echo "════════════════════════════════════════════════════════"
echo "EMERGENCY DIAGNOSTIC REPORT"
echo "════════════════════════════════════════════════════════"
echo ""

# 1. Check if build is still running
echo "1. CHECKING FOR STUCK PROCESSES:"
ps aux | grep -E "flutter|dart|dart2js" | grep -v grep
if [ $? -eq 0 ]; then
    echo "⚠️  Found Flutter/Dart processes - may be stuck!"
    echo ""
    echo "Kill them? (y/n)"
    read -r response
    if [ "$response" = "y" ]; then
        killall -9 flutter dart dart2js 2>/dev/null
        echo "✓ Processes killed"
    fi
else
    echo "✓ No stuck processes found"
fi
echo ""

# 2. System resources
echo "2. SYSTEM RESOURCES:"
echo "CPU:"
top -bn1 | head -20
echo ""
echo "Memory:"
free -h
echo ""
echo "Swap:"
swapon --show
echo ""
echo "Disk:"
df -h /home/ec2-user
echo ""

# 3. Check for zombie builds
echo "3. CHECKING FOR ZOMBIE BUILD ARTIFACTS:"
find /home/ec2-user/pgni -name ".dart_tool" -type d 2>/dev/null
find /home/ec2-user/pgni -name "build" -type d 2>/dev/null
echo ""

# 4. Check Flutter cache
echo "4. FLUTTER CACHE:"
du -sh ~/.pub-cache 2>/dev/null || echo "No pub cache"
du -sh /opt/flutter/.pub-cache 2>/dev/null || echo "No flutter pub cache"
echo ""

# 5. Check for disk issues
echo "5. DISK I/O (5 sec sample):"
iostat -x 1 5 | tail -20 || echo "iostat not available"
echo ""

# 6. Instance metadata
echo "6. EC2 INSTANCE INFO:"
ec2-metadata --instance-type || echo "Not on EC2 or ec2-metadata not available"
echo ""

# 7. Root cause analysis
echo "════════════════════════════════════════════════════════"
echo "ROOT CAUSE ANALYSIS:"
echo "════════════════════════════════════════════════════════"

TOTAL_RAM_MB=$(free -m | awk 'NR==2 {print $2}')
AVAIL_RAM_MB=$(free -m | awk 'NR==2 {print $7}')

echo "RAM: ${TOTAL_RAM_MB}MB total, ${AVAIL_RAM_MB}MB available"

if [ "$TOTAL_RAM_MB" -lt 2000 ]; then
    echo "❌ CRITICAL: RAM too low ($TOTAL_RAM_MB MB)"
    echo "   dart2js needs minimum 2GB, you have <1GB"
    echo "   This is why the build hung!"
    echo ""
    echo "SOLUTIONS:"
    echo "1. Upgrade to t3.medium (4GB RAM) - RECOMMENDED"
    echo "2. Add more swap (risky, very slow)"
    echo "3. Build elsewhere and copy artifacts"
fi

if [ "$AVAIL_RAM_MB" -lt 500 ]; then
    echo "⚠️  WARNING: Very low available RAM ($AVAIL_RAM_MB MB)"
    echo "   System may be thrashing"
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "RECOMMENDATIONS:"
echo "════════════════════════════════════════════════════════"
echo "Based on t3.micro (≈900MB RAM):"
echo ""
echo "❌ Building Flutter web on t3.micro: IMPOSSIBLE"
echo "   - dart2js requires 2-4GB RAM minimum"
echo "   - Will hang/crash/take forever on <1GB RAM"
echo ""
echo "✅ IMMEDIATE SOLUTION:"
echo "   1. Stop instance"
echo "   2. Change to t3.medium (4GB RAM)"
echo "   3. Start instance"
echo "   4. Build will complete in 5-10 minutes"
echo ""
echo "⚡ FASTER SOLUTION:"
echo "   1. Change to t3.large (8GB RAM)"
echo "   2. Build will complete in 3-5 minutes"
echo ""
echo "💡 COST-EFFECTIVE:"
echo "   1. Scale to t3.large for build"
echo "   2. Scale back to t3.micro after deployment"
echo "   3. Pay only for 10 minutes of t3.large time"
echo ""

