#!/bin/bash
#===============================================================================
# AUTO-SCALE AND DEPLOY - Automated Instance Scaling for Flutter Builds
#===============================================================================
set -e

echo "════════════════════════════════════════════════════════"
echo "AUTO-SCALE AND DEPLOY v1.0"
echo "Automated EC2 scaling for Flutter web builds"
echo "════════════════════════════════════════════════════════"
echo ""

# Configuration
TARGET_BUILD_INSTANCE="t3.large"    # Fast builds (3-5 min)
FALLBACK_INSTANCE="t3.medium"       # If t3.large unavailable
ORIGINAL_INSTANCE=$(ec2-metadata --instance-type 2>/dev/null | cut -d' ' -f2 || echo "unknown")
INSTANCE_ID=$(ec2-metadata --instance-id 2>/dev/null | cut -d' ' -f2 || echo "unknown")

echo "Current instance: $ORIGINAL_INSTANCE"
echo "Instance ID: $INSTANCE_ID"
echo ""

# Check if we need to scale
CURRENT_RAM_MB=$(free -m | awk 'NR==2 {print $2}')

if [ "$CURRENT_RAM_MB" -ge 7000 ]; then
    echo "✓ Current instance has sufficient RAM ($CURRENT_RAM_MB MB)"
    echo "  Proceeding with build..."
    SKIP_SCALING=true
elif [ "$CURRENT_RAM_MB" -ge 3500 ]; then
    echo "⚠ Current instance has adequate RAM ($CURRENT_RAM_MB MB)"
    echo "  Build will take 7-10 minutes"
    SKIP_SCALING=true
else
    echo "❌ Current instance has insufficient RAM ($CURRENT_RAM_MB MB)"
    echo "   dart2js requires minimum 2GB, preferably 4GB+"
    echo "   Current build will hang or take hours/days"
    echo ""
    SKIP_SCALING=false
fi

if [ "$SKIP_SCALING" = false ]; then
    echo "════════════════════════════════════════════════════════"
    echo "AUTO-SCALING DECISION"
    echo "════════════════════════════════════════════════════════"
    echo ""
    echo "Option 1: Auto-scale to $TARGET_BUILD_INSTANCE"
    echo "  - RAM: 8GB"
    echo "  - Build time: 3-5 minutes"
    echo "  - Cost: ~\$0.02 for 10 minutes"
    echo ""
    echo "Option 2: Continue with current instance"
    echo "  - RAM: $CURRENT_RAM_MB MB"
    echo "  - Build time: HOURS or will hang"
    echo "  - Cost: Free (but wastes time)"
    echo ""
    echo "Recommendation: AUTO-SCALE (Option 1)"
    echo ""
    
    read -p "Auto-scale to $TARGET_BUILD_INSTANCE? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        echo "════════════════════════════════════════════════════════"
        echo "SCALING TO $TARGET_BUILD_INSTANCE"
        echo "════════════════════════════════════════════════════════"
        echo ""
        
        if [ "$INSTANCE_ID" = "unknown" ]; then
            echo "❌ Cannot determine instance ID"
            echo "   Please scale manually or run from EC2"
            exit 1
        fi
        
        echo "Step 1: Stopping instance..."
        aws ec2 stop-instances --instance-ids "$INSTANCE_ID"
        aws ec2 wait instance-stopped --instance-ids "$INSTANCE_ID"
        echo "✓ Instance stopped"
        
        echo ""
        echo "Step 2: Changing instance type to $TARGET_BUILD_INSTANCE..."
        if aws ec2 modify-instance-attribute --instance-id "$INSTANCE_ID" --instance-type "$TARGET_BUILD_INSTANCE"; then
            echo "✓ Instance type changed"
        else
            echo "⚠ Failed to change to $TARGET_BUILD_INSTANCE, trying $FALLBACK_INSTANCE..."
            aws ec2 modify-instance-attribute --instance-id "$INSTANCE_ID" --instance-type "$FALLBACK_INSTANCE"
            echo "✓ Instance type changed to $FALLBACK_INSTANCE"
        fi
        
        echo ""
        echo "Step 3: Starting instance..."
        aws ec2 start-instances --instance-ids "$INSTANCE_ID"
        echo "⏳ Waiting for instance to start (this will disconnect you)..."
        echo ""
        echo "════════════════════════════════════════════════════════"
        echo "NEXT STEPS:"
        echo "════════════════════════════════════════════════════════"
        echo "1. Wait 1-2 minutes for instance to fully start"
        echo "2. Reconnect to EC2"
        echo "3. Run: ./deploy_now.sh"
        echo "4. Build will complete in 3-5 minutes"
        echo ""
        echo "After deployment, scale back down:"
        echo "  ./SCALE_DOWN.sh"
        echo ""
        exit 0
    fi
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "PROCEEDING WITH BUILD ON CURRENT INSTANCE"
echo "════════════════════════════════════════════════════════"
echo ""

# Kill any stuck processes
echo "Killing any stuck Flutter processes..."
killall -9 flutter dart dart2js 2>/dev/null || true
sleep 2

# Clean up zombie builds
echo "Cleaning zombie build artifacts..."
cd /home/ec2-user/pgni
rm -rf pgworld-master/.dart_tool pgworld-master/build
rm -rf pgworldtenant-master/.dart_tool pgworldtenant-master/build
echo "✓ Cleaned"

# Optimize environment
echo "Optimizing build environment..."
export DART_VM_OPTIONS="--old_gen_heap_size=$((CURRENT_RAM_MB / 2))"
export PUB_CACHE=/home/ec2-user/.pub-cache
echo "✓ Dart heap: $((CURRENT_RAM_MB / 2))MB"

# Build with progress monitoring
echo ""
echo "Starting build with progress monitoring..."
echo "Expected time: 7-10 minutes on current instance"
echo ""

BUILD_START=$(date +%s)

# Build Admin
echo "Building Admin app..."
cd pgworld-master
flutter pub get
timeout 1200 flutter build web --release --no-source-maps --no-tree-shake-icons --dart-define=dart.vm.product=true &
BUILD_PID=$!

# Monitor progress
while kill -0 $BUILD_PID 2>/dev/null; do
    ELAPSED=$(($(date +%s) - BUILD_START))
    MEM_USED=$(free -m | awk 'NR==2 {print $3}')
    echo -ne "\r⏱ Elapsed: ${ELAPSED}s | Memory: ${MEM_USED}MB used    "
    sleep 5
    
    # Check if stuck (no progress for 10 minutes)
    if [ $ELAPSED -gt 600 ]; then
        echo ""
        echo "⚠️  Build taking longer than expected (${ELAPSED}s)"
        echo "   This suggests insufficient RAM"
        echo "   Recommendation: Stop build and upgrade instance"
    fi
done

wait $BUILD_PID
BUILD_EXIT=$?

if [ $BUILD_EXIT -ne 0 ]; then
    echo ""
    echo "❌ Admin build failed!"
    echo "   Exit code: $BUILD_EXIT"
    echo ""
    echo "This likely means:"
    echo "1. Out of memory (RAM too low)"
    echo "2. Build timed out after 20 minutes"
    echo ""
    echo "SOLUTION: Upgrade to t3.medium or t3.large"
    exit 1
fi

ADMIN_TIME=$(($(date +%s) - BUILD_START))
echo ""
echo "✓ Admin built in ${ADMIN_TIME}s"

# Build Tenant
echo ""
echo "Building Tenant app..."
cd ../pgworldtenant-master
flutter pub get
timeout 1200 flutter build web --release --no-source-maps --no-tree-shake-icons --dart-define=dart.vm.product=true

TOTAL_TIME=$(($(date +%s) - BUILD_START))
echo ""
echo "✓ Both apps built in ${TOTAL_TIME}s"

# Deploy
echo ""
echo "Deploying..."
sudo rm -rf /usr/share/nginx/html/{admin,tenant}
sudo mkdir -p /usr/share/nginx/html/{admin,tenant}
sudo cp -r ../pgworld-master/build/web/* /usr/share/nginx/html/admin/
sudo cp -r build/web/* /usr/share/nginx/html/tenant/
sudo chown -R nginx:nginx /usr/share/nginx/html
sudo chmod -R 755 /usr/share/nginx/html
sudo systemctl reload nginx

echo ""
echo "════════════════════════════════════════════════════════"
echo "✓ DEPLOYMENT COMPLETE!"
echo "════════════════════════════════════════════════════════"
echo ""
echo "Total time: ${TOTAL_TIME}s ($(($TOTAL_TIME / 60))m $(($TOTAL_TIME % 60))s)"
echo ""
echo "Access URLs:"
echo "  Admin:  http://34.227.111.143/admin/"
echo "  Tenant: http://34.227.111.143/tenant/"
echo ""

# Validation
echo "Validating deployment..."
ADMIN_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/admin/)
TENANT_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/tenant/)

if [ "$ADMIN_STATUS" = "200" ] && [ "$TENANT_STATUS" = "200" ]; then
    echo "✓ All endpoints responding"
else
    echo "⚠️  Some endpoints not responding:"
    echo "   Admin: HTTP $ADMIN_STATUS"
    echo "   Tenant: HTTP $TENANT_STATUS"
fi

echo ""

