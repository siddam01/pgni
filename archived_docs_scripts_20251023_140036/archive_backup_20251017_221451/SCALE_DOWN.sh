#!/bin/bash
#===============================================================================
# SCALE DOWN - Return to Original Instance Type After Build
#===============================================================================

echo "════════════════════════════════════════════════════════"
echo "SCALE DOWN TO ORIGINAL INSTANCE"
echo "════════════════════════════════════════════════════════"
echo ""

INSTANCE_ID=$(ec2-metadata --instance-id 2>/dev/null | cut -d' ' -f2 || echo "unknown")
CURRENT_TYPE=$(ec2-metadata --instance-type 2>/dev/null | cut -d' ' -f2 || echo "unknown")

echo "Current instance: $CURRENT_TYPE"
echo "Instance ID: $INSTANCE_ID"
echo ""

if [ "$INSTANCE_ID" = "unknown" ]; then
    echo "❌ Cannot determine instance ID"
    echo "   Run this script from EC2"
    exit 1
fi

echo "Scale down to:"
echo "1) t3.micro  (1GB RAM)  - $7.50/month  - Cheapest"
echo "2) t3.small  (2GB RAM)  - $15/month    - Budget"
echo "3) t3.medium (4GB RAM)  - $30/month    - Balanced"
echo "4) Keep current ($CURRENT_TYPE)"
echo ""

read -p "Select option (1-4): " -n 1 -r
echo ""

case $REPLY in
    1) TARGET="t3.micro" ;;
    2) TARGET="t3.small" ;;
    3) TARGET="t3.medium" ;;
    4) echo "Keeping current instance"; exit 0 ;;
    *) echo "Invalid option"; exit 1 ;;
esac

if [ "$TARGET" = "$CURRENT_TYPE" ]; then
    echo "Already on $TARGET"
    exit 0
fi

echo ""
echo "Scaling to $TARGET..."
echo ""
echo "⚠️  WARNING: This will disconnect you!"
echo "   Wait 1-2 minutes, then reconnect"
echo ""

read -p "Continue? (y/N): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled"
    exit 0
fi

echo "Stopping instance..."
aws ec2 stop-instances --instance-ids "$INSTANCE_ID"
aws ec2 wait instance-stopped --instance-ids "$INSTANCE_ID"
echo "✓ Stopped"

echo "Changing to $TARGET..."
aws ec2 modify-instance-attribute --instance-id "$INSTANCE_ID" --instance-type "$TARGET"
echo "✓ Changed"

echo "Starting instance..."
aws ec2 start-instances --instance-ids "$INSTANCE_ID"
echo "✓ Started"

echo ""
echo "════════════════════════════════════════════════════════"
echo "Instance scaled to $TARGET"
echo "Reconnect in 1-2 minutes"
echo "════════════════════════════════════════════════════════"

