#!/bin/bash
###############################################################################
# CloudPG - Verify Current Deployment & Redeploy Clean Build
# This script checks what's actually deployed and fixes placeholder issues
###############################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo ""
echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}CloudPG - Deployment Verification${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

# ============================================
# STEP 1: Check What's Currently Deployed
# ============================================
echo -e "${BLUE}[1/6] Checking current deployment...${NC}"

ADMIN_PATH="/var/www/html/admin"
TENANT_PATH="/var/www/html/tenant"

echo "Admin portal location: $ADMIN_PATH"
if [ -d "$ADMIN_PATH" ]; then
    echo -e "${GREEN}✓ Admin directory exists${NC}"
    
    # Check for placeholders in deployed files
    if sudo grep -rq "minimal working version" "$ADMIN_PATH"/*.js 2>/dev/null; then
        echo -e "${RED}✗ FOUND: 'minimal working version' in admin files!${NC}"
        ADMIN_HAS_PLACEHOLDER=true
    else
        echo -e "${GREEN}✓ No 'minimal working version' found${NC}"
        ADMIN_HAS_PLACEHOLDER=false
    fi
    
    if sudo grep -rq "being fixed" "$ADMIN_PATH"/*.js 2>/dev/null; then
        echo -e "${RED}✗ FOUND: 'being fixed' in admin files!${NC}"
        ADMIN_HAS_PLACEHOLDER=true
    else
        echo -e "${GREEN}✓ No 'being fixed' found${NC}"
    fi
    
    # Check file dates
    echo "Admin files last modified:"
    ls -lh "$ADMIN_PATH/index.html" 2>/dev/null || echo "  index.html not found"
    
else
    echo -e "${YELLOW}⚠ Admin directory not found${NC}"
    ADMIN_HAS_PLACEHOLDER=true
fi

echo ""

echo "Tenant portal location: $TENANT_PATH"
if [ -d "$TENANT_PATH" ]; then
    echo -e "${GREEN}✓ Tenant directory exists${NC}"
    
    if sudo grep -rq "coming soon" "$TENANT_PATH"/*.js 2>/dev/null; then
        echo -e "${RED}✗ FOUND: 'coming soon' in tenant files!${NC}"
        TENANT_HAS_PLACEHOLDER=true
    else
        echo -e "${GREEN}✓ No 'coming soon' found${NC}"
        TENANT_HAS_PLACEHOLDER=false
    fi
else
    echo -e "${YELLOW}⚠ Tenant directory not found${NC}"
    TENANT_HAS_PLACEHOLDER=true
fi

echo ""

# ============================================
# STEP 2: Check Source Files
# ============================================
echo -e "${BLUE}[2/6] Checking source files...${NC}"

SOURCE_DIR="/tmp/pgni-main"
cd "$SOURCE_DIR"

echo "Checking admin source code:"
if grep -rq "minimal working version" pgworld-master/lib/ 2>/dev/null; then
    echo -e "${RED}✗ Source code has placeholders!${NC}"
    SOURCE_CLEAN=false
else
    echo -e "${GREEN}✓ Admin source code is clean${NC}"
    SOURCE_CLEAN=true
fi

echo ""
echo "Checking for pre-built files:"
ADMIN_BUILD="$SOURCE_DIR/pgworld-master/build/web"
if [ -d "$ADMIN_BUILD" ]; then
    echo -e "${GREEN}✓ Admin build directory exists${NC}"
    
    if grep -rq "minimal working version" "$ADMIN_BUILD"/*.js 2>/dev/null; then
        echo -e "${RED}✗ Build files have placeholders!${NC}"
        BUILD_CLEAN=false
    else
        echo -e "${GREEN}✓ Build files are clean${NC}"
        BUILD_CLEAN=true
    fi
else
    echo -e "${YELLOW}⚠ No pre-built admin files found${NC}"
    BUILD_CLEAN=false
fi

echo ""

# ============================================
# STEP 3: Backup Current Deployment
# ============================================
echo -e "${BLUE}[3/6] Creating backup...${NC}"

BACKUP_DIR="/var/www/backups/manual-$(date +%Y%m%d_%H%M%S)"
sudo mkdir -p "$BACKUP_DIR"

if [ -d "$ADMIN_PATH" ]; then
    sudo cp -r "$ADMIN_PATH" "$BACKUP_DIR/admin"
    echo -e "${GREEN}✓ Admin backed up${NC}"
fi

if [ -d "$TENANT_PATH" ]; then
    sudo cp -r "$TENANT_PATH" "$BACKUP_DIR/tenant"
    echo -e "${GREEN}✓ Tenant backed up${NC}"
fi

echo "Backup location: $BACKUP_DIR"
echo ""

# ============================================
# STEP 4: Deploy Clean Build
# ============================================
echo -e "${BLUE}[4/6] Deploying clean build...${NC}"

if [ "$BUILD_CLEAN" = true ] && [ -d "$ADMIN_BUILD" ]; then
    echo "Deploying clean admin build..."
    
    # Remove old files
    sudo rm -rf "$ADMIN_PATH"
    sudo mkdir -p "$ADMIN_PATH"
    
    # Copy new files
    sudo cp -r "$ADMIN_BUILD"/* "$ADMIN_PATH/"
    
    # Set permissions
    sudo chown -R nginx:nginx "$ADMIN_PATH" 2>/dev/null || \
        sudo chown -R www-data:www-data "$ADMIN_PATH" 2>/dev/null || \
        sudo chown -R ec2-user:ec2-user "$ADMIN_PATH"
    sudo chmod -R 755 "$ADMIN_PATH"
    
    echo -e "${GREEN}✓ Admin deployed from clean build${NC}"
else
    echo -e "${YELLOW}⚠ No clean build available - creating placeholder${NC}"
    
    sudo mkdir -p "$ADMIN_PATH"
    sudo tee "$ADMIN_PATH/index.html" > /dev/null <<'HTMLEOF'
<!DOCTYPE html>
<html>
<head>
    <title>CloudPG Admin - Upload Required</title>
    <style>
        body { 
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
            margin: 0;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        }
        .container {
            background: white;
            padding: 40px;
            border-radius: 10px;
            box-shadow: 0 10px 40px rgba(0,0,0,0.2);
            max-width: 600px;
            text-align: center;
        }
        h1 { color: #333; margin: 0 0 20px 0; }
        .status { 
            padding: 15px;
            background: #fff3cd;
            border: 1px solid #ffc107;
            border-radius: 5px;
            margin: 20px 0;
        }
        .instructions {
            text-align: left;
            background: #f8f9fa;
            padding: 20px;
            border-radius: 5px;
            margin: 20px 0;
        }
        .instructions ol { margin: 10px 0; padding-left: 20px; }
        .instructions li { margin: 5px 0; }
        code {
            background: #e9ecef;
            padding: 2px 6px;
            border-radius: 3px;
            font-family: monospace;
        }
        .api-check {
            margin-top: 20px;
            padding: 15px;
            background: #d1ecf1;
            border: 1px solid #bee5eb;
            border-radius: 5px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 CloudPG Admin Portal</h1>
        
        <div class="status">
            <strong>⚠️ Build Files Need Upload</strong>
            <p>The server is configured, but admin build files are missing.</p>
        </div>

        <div class="instructions">
            <h3>📤 Upload Instructions:</h3>
            <ol>
                <li>On Windows, open <strong>WinSCP</strong></li>
                <li>Connect to: <code>54.227.101.30</code></li>
                <li>Local directory: <code>deployment-admin-*/admin/</code></li>
                <li>Remote directory: <code>/var/www/html/admin/</code></li>
                <li>Upload all files</li>
                <li>Set permissions: <code>sudo chmod -R 755 /var/www/html/admin</code></li>
                <li>Refresh this page</li>
            </ol>
        </div>

        <div class="api-check">
            <strong>API Status:</strong> <span id="api-status">Checking...</span>
        </div>

        <script>
            fetch('http://54.227.101.30:8080/api/status')
                .then(r => r.json())
                .then(d => {
                    document.getElementById('api-status').textContent = '✅ API is running!';
                    document.getElementById('api-status').style.color = 'green';
                })
                .catch(e => {
                    document.getElementById('api-status').textContent = '❌ API not reachable';
                    document.getElementById('api-status').style.color = 'red';
                });
        </script>
    </div>
</body>
</html>
HTMLEOF
fi

echo ""

# ============================================
# STEP 5: Clear Nginx Cache & Restart
# ============================================
echo -e "${BLUE}[5/6] Clearing cache and restarting services...${NC}"

# Clear any nginx cache
sudo rm -rf /var/cache/nginx/* 2>/dev/null || true

# Restart nginx with no-cache headers
sudo systemctl restart nginx

echo -e "${GREEN}✓ Services restarted${NC}"
echo ""

# ============================================
# STEP 6: Verify Deployment
# ============================================
echo -e "${BLUE}[6/6] Verifying deployment...${NC}"

sleep 2

echo -n "  Testing admin portal... "
if curl -s http://localhost/admin/ > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
fi

echo -n "  Checking for placeholders... "
if sudo grep -rq "minimal working version\|being fixed" "$ADMIN_PATH"/*.js 2>/dev/null; then
    echo -e "${RED}✗ Still found!${NC}"
    echo ""
    echo -e "${YELLOW}The deployed files STILL contain placeholders.${NC}"
    echo "This means the SOURCE build files have placeholders."
    echo ""
    echo "ACTION REQUIRED:"
    echo "  1. Upload clean build files from Windows via WinSCP"
    echo "  2. Or rebuild on Windows with Flutter and upload"
else
    echo -e "${GREEN}✓ Clean!${NC}"
fi

echo ""

# ============================================
# Summary
# ============================================
echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}Verification Summary${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

echo "Current Deployment Status:"
if [ "$ADMIN_HAS_PLACEHOLDER" = true ]; then
    echo -e "  Admin: ${RED}✗ Has placeholders${NC}"
else
    echo -e "  Admin: ${GREEN}✓ Clean${NC}"
fi

if [ "$TENANT_HAS_PLACEHOLDER" = true ]; then
    echo -e "  Tenant: ${RED}✗ Has placeholders${NC}"
else
    echo -e "  Tenant: ${GREEN}✓ Clean${NC}"
fi

echo ""
echo "Source Files:"
if [ "$SOURCE_CLEAN" = true ]; then
    echo -e "  ${GREEN}✓ Source code is clean${NC}"
else
    echo -e "  ${RED}✗ Source code has placeholders${NC}"
fi

if [ "$BUILD_CLEAN" = true ]; then
    echo -e "  ${GREEN}✓ Build files are clean${NC}"
else
    echo -e "  ${RED}✗ Build files have placeholders or missing${NC}"
fi

echo ""
echo -e "${BLUE}Access URLs:${NC}"
echo "  Admin:  http://54.227.101.30/admin/"
echo "  Tenant: http://54.227.101.30/tenant/"
echo ""

if [ "$BUILD_CLEAN" = true ] && [ "$ADMIN_HAS_PLACEHOLDER" = false ]; then
    echo -e "${GREEN}✅ DEPLOYMENT SUCCESSFUL - Clean files deployed!${NC}"
    echo ""
    echo "Clear browser cache and test:"
    echo "  1. Press Ctrl+Shift+Delete"
    echo "  2. Select 'All time'"
    echo "  3. Clear cached files"
    echo "  4. Refresh: http://54.227.101.30/admin/"
else
    echo -e "${YELLOW}⚠️  ACTION REQUIRED${NC}"
    echo ""
    echo "The build files on EC2 contain placeholders or are missing."
    echo ""
    echo "Solution: Upload clean build from Windows"
    echo "  1. On Windows, locate: deployment-admin-20251027-213037/admin/"
    echo "  2. Use WinSCP to upload to: /var/www/html/admin/"
    echo "  3. Run: sudo chmod -R 755 /var/www/html/admin"
    echo "  4. Run this script again to verify"
fi

echo ""
echo "Backup location: $BACKUP_DIR"
echo ""

