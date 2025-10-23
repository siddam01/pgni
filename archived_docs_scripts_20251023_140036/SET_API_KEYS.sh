#!/bin/bash

echo "════════════════════════════════════════════════════════"
echo "🔑 TENANT APP - API KEYS CONFIGURATION"
echo "════════════════════════════════════════════════════════"
echo ""

# Prompt for keys
echo "Please provide your API keys:"
echo ""
echo -n "Enter your MRK/API Key: "
read API_KEY

echo -n "Enter your OneSignal App ID (or press Enter to skip): "
read ONESIGNAL_ID

# Set defaults
if [ -z "$ONESIGNAL_ID" ]; then
    ONESIGNAL_ID="disabled"
    echo "✓ OneSignal disabled (web app will work without push notifications)"
fi

echo ""
echo "Keys to be configured:"
echo "  API Key:        $API_KEY"
echo "  OneSignal ID:   $ONESIGNAL_ID"
echo ""
echo -n "Is this correct? (y/n): "
read CONFIRM

if [ "$CONFIRM" != "y" ]; then
    echo "Cancelled."
    exit 1
fi

TENANT_PATH="/home/ec2-user/pgni/pgworldtenant-master"
cd "$TENANT_PATH"

echo ""
echo "Updating lib/config.dart..."

# Update the config file
sed -i "s/const String APIKEY = \".*\";/const String APIKEY = \"$API_KEY\";/" lib/config.dart
sed -i "s/const String ONESIGNAL_APP_ID = \".*\";/const String ONESIGNAL_APP_ID = \"$ONESIGNAL_ID\";/" lib/config.dart

echo "✓ API keys configured"

echo ""
echo "════════════════════════════════════════════════════════"
echo "✅ CONFIGURATION COMPLETE!"
echo "════════════════════════════════════════════════════════"
echo ""
echo "Next step: Run the build script"
echo ""
echo "bash <(curl -sL https://raw.githubusercontent.com/siddam01/pgni/main/CLEAN_CONFIG_AND_BUILD.sh)"
echo ""

