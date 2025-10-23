#!/bin/bash
#==============================================================================
# Diagnose 500 Error and Current Status
#==============================================================================

# Configuration
INSTANCE_ID="i-0909d462845deb151"
REGION="us-east-1"
EC2_IP="34.227.111.143"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo "=============================================="
echo "  Diagnosing 500 Error"
echo "=============================================="
echo "Time: $(date)"
echo ""

#==============================================================================
# 1. Check Current HTTP Status
#==============================================================================
echo -e "${CYAN}=== 1. Testing URLs ===${NC}"
echo ""

echo "Admin Portal (http://$EC2_IP/admin/):"
ADMIN_STATUS=$(curl -s -o /tmp/admin_response.html -w "%{http_code}" http://$EC2_IP/admin/ 2>/dev/null || echo "000")
echo "  HTTP Status: $ADMIN_STATUS"
if [ "$ADMIN_STATUS" = "500" ]; then
    echo -e "  ${RED}✗ Internal Server Error${NC}"
    echo "  This usually means:"
    echo "    - Nginx is running but misconfigured"
    echo "    - Files are missing or have wrong permissions"
    echo "    - Nginx config has syntax errors"
elif [ "$ADMIN_STATUS" = "403" ]; then
    echo -e "  ${YELLOW}⚠ Forbidden - Files exist but can't be served${NC}"
elif [ "$ADMIN_STATUS" = "200" ]; then
    echo -e "  ${GREEN}✓ Working${NC}"
    # Check if it's actual Flutter or placeholder
    if grep -q "Flutter" /tmp/admin_response.html 2>/dev/null; then
        echo "  ${GREEN}✓ Real Flutter app detected${NC}"
    else
        echo "  ${YELLOW}⚠ May be placeholder page${NC}"
    fi
else
    echo -e "  ${RED}✗ Unexpected status${NC}"
fi

echo ""
echo "Tenant Portal (http://$EC2_IP/tenant/):"
TENANT_STATUS=$(curl -s -o /tmp/tenant_response.html -w "%{http_code}" http://$EC2_IP/tenant/ 2>/dev/null || echo "000")
echo "  HTTP Status: $TENANT_STATUS"
if [ "$TENANT_STATUS" = "500" ]; then
    echo -e "  ${RED}✗ Internal Server Error${NC}"
elif [ "$TENANT_STATUS" = "403" ]; then
    echo -e "  ${YELLOW}⚠ Forbidden${NC}"
elif [ "$TENANT_STATUS" = "200" ]; then
    echo -e "  ${GREEN}✓ Working${NC}"
else
    echo -e "  ${RED}✗ Unexpected status${NC}"
fi

echo ""
echo "Backend API (http://$EC2_IP:8080/health):"
API_STATUS=$(curl -s -o /tmp/api_response.json -w "%{http_code}" http://$EC2_IP:8080/health 2>/dev/null || echo "000")
echo "  HTTP Status: $API_STATUS"
if [ "$API_STATUS" = "200" ]; then
    echo -e "  ${GREEN}✓ Working${NC}"
    cat /tmp/api_response.json 2>/dev/null | head -3
else
    echo -e "  ${RED}✗ Not responding${NC}"
fi

echo ""

#==============================================================================
# 2. Check Nginx Status and Logs
#==============================================================================
echo -e "${CYAN}=== 2. Checking Nginx on EC2 ===${NC}"
echo ""

COMMAND_ID=$(aws ssm send-command \
    --instance-ids "$INSTANCE_ID" \
    --region "$REGION" \
    --document-name "AWS-RunShellScript" \
    --comment "Check Nginx status and logs" \
    --parameters 'commands=[
        "echo === Nginx Status ===",
        "sudo systemctl status nginx --no-pager | head -10",
        "echo",
        "echo === Nginx Error Log (last 20 lines) ===",
        "sudo tail -20 /var/log/nginx/error.log 2>/dev/null || echo No error log found",
        "echo",
        "echo === Nginx Access Log (last 10 lines) ===",
        "sudo tail -10 /var/log/nginx/access.log 2>/dev/null || echo No access log found",
        "echo",
        "echo === Nginx Configuration Test ===",
        "sudo nginx -t 2>&1",
        "echo",
        "echo === Active Nginx Config ===",
        "sudo cat /etc/nginx/conf.d/pgni.conf 2>/dev/null || echo Config file not found"
    ]' \
    --timeout-seconds 60 \
    --query 'Command.CommandId' \
    --output text 2>/dev/null)

if [ "$COMMAND_ID" != "" ] && [ "$COMMAND_ID" != "None" ]; then
    echo "Retrieving Nginx status... (waiting 10 seconds)"
    sleep 10
    
    aws ssm get-command-invocation \
        --command-id "$COMMAND_ID" \
        --instance-id "$INSTANCE_ID" \
        --region "$REGION" \
        --query 'StandardOutputContent' \
        --output text 2>/dev/null | head -100
else
    echo "Could not check Nginx via SSM"
fi

echo ""

#==============================================================================
# 3. Check Deployed Files
#==============================================================================
echo -e "${CYAN}=== 3. Checking Deployed Files ===${NC}"
echo ""

COMMAND_ID=$(aws ssm send-command \
    --instance-ids "$INSTANCE_ID" \
    --region "$REGION" \
    --document-name "AWS-RunShellScript" \
    --comment "Check deployed files" \
    --parameters 'commands=[
        "echo === Admin Directory ===",
        "ls -lah /usr/share/nginx/html/admin/ 2>/dev/null | head -15 || echo Directory not found",
        "echo",
        "echo === Admin index.html ===",
        "[ -f /usr/share/nginx/html/admin/index.html ] && echo EXISTS || echo MISSING",
        "[ -f /usr/share/nginx/html/admin/index.html ] && ls -lh /usr/share/nginx/html/admin/index.html",
        "[ -f /usr/share/nginx/html/admin/index.html ] && head -5 /usr/share/nginx/html/admin/index.html",
        "echo",
        "echo === Tenant Directory ===",
        "ls -lah /usr/share/nginx/html/tenant/ 2>/dev/null | head -15 || echo Directory not found",
        "echo",
        "echo === Directory Permissions ===",
        "ls -ld /usr/share/nginx/html/",
        "ls -ld /usr/share/nginx/html/admin/ 2>/dev/null || echo admin dir missing",
        "ls -ld /usr/share/nginx/html/tenant/ 2>/dev/null || echo tenant dir missing"
    ]' \
    --timeout-seconds 60 \
    --query 'Command.CommandId' \
    --output text 2>/dev/null)

if [ "$COMMAND_ID" != "" ] && [ "$COMMAND_ID" != "None" ]; then
    echo "Checking files... (waiting 10 seconds)"
    sleep 10
    
    aws ssm get-command-invocation \
        --command-id "$COMMAND_ID" \
        --instance-id "$INSTANCE_ID" \
        --region "$REGION" \
        --query 'StandardOutputContent' \
        --output text 2>/dev/null | head -100
else
    echo "Could not check files via SSM"
fi

echo ""

#==============================================================================
# 4. Check if Flutter is Built
#==============================================================================
echo -e "${CYAN}=== 4. Checking Flutter Build Status ===${NC}"
echo ""

COMMAND_ID=$(aws ssm send-command \
    --instance-ids "$INSTANCE_ID" \
    --region "$REGION" \
    --document-name "AWS-RunShellScript" \
    --comment "Check Flutter build" \
    --parameters 'commands=[
        "echo === Flutter Installation ===",
        "[ -d /home/ec2-user/flutter ] && echo Flutter SDK: INSTALLED || echo Flutter SDK: NOT INSTALLED",
        "export PATH=$PATH:/home/ec2-user/flutter/bin",
        "which flutter && flutter --version || echo Flutter not in PATH",
        "echo",
        "echo === Source Code ===",
        "[ -d /home/ec2-user/pgni ] && echo Source: CLONED || echo Source: NOT CLONED",
        "echo",
        "echo === Admin Build ===",
        "[ -d /home/ec2-user/pgni/pgworld-master/build/web ] && echo Admin build: EXISTS || echo Admin build: MISSING",
        "[ -d /home/ec2-user/pgni/pgworld-master/build/web ] && ls -lah /home/ec2-user/pgni/pgworld-master/build/web/ | head -10",
        "echo",
        "echo === Tenant Build ===",
        "[ -d /home/ec2-user/pgni/pgworldtenant-master/build/web ] && echo Tenant build: EXISTS || echo Tenant build: MISSING",
        "[ -d /home/ec2-user/pgni/pgworldtenant-master/build/web ] && ls -lah /home/ec2-user/pgni/pgworldtenant-master/build/web/ | head -10"
    ]' \
    --timeout-seconds 60 \
    --query 'Command.CommandId' \
    --output text 2>/dev/null)

if [ "$COMMAND_ID" != "" ] && [ "$COMMAND_ID" != "None" ]; then
    echo "Checking Flutter... (waiting 10 seconds)"
    sleep 10
    
    aws ssm get-command-invocation \
        --command-id "$COMMAND_ID" \
        --instance-id "$INSTANCE_ID" \
        --region "$REGION" \
        --query 'StandardOutputContent' \
        --output text 2>/dev/null | head -100
else
    echo "Could not check Flutter via SSM"
fi

echo ""

#==============================================================================
# DIAGNOSIS SUMMARY
#==============================================================================
echo "=============================================="
echo "  Diagnosis Summary"
echo "=============================================="
echo ""

if [ "$ADMIN_STATUS" = "500" ] || [ "$TENANT_STATUS" = "500" ]; then
    echo -e "${RED}✗ 500 Internal Server Error Detected${NC}"
    echo ""
    echo "Common Causes:"
    echo "  1. Nginx config syntax error"
    echo "  2. Files missing in /usr/share/nginx/html/"
    echo "  3. Wrong file permissions"
    echo "  4. Nginx can't read files"
    echo ""
    echo "Solution:"
    echo "  Run this to fix and deploy real app:"
    echo "  ./FIX_403_AND_DEPLOY_FULL_APP.sh"
elif [ "$ADMIN_STATUS" = "403" ] || [ "$TENANT_STATUS" = "403" ]; then
    echo -e "${YELLOW}⚠ 403 Forbidden - Placeholder pages deployed${NC}"
    echo ""
    echo "This means Nginx is working but serving wrong files."
    echo ""
    echo "Solution:"
    echo "  Run this to deploy actual Flutter apps:"
    echo "  ./FIX_403_AND_DEPLOY_FULL_APP.sh"
elif [ "$ADMIN_STATUS" = "200" ] && [ "$TENANT_STATUS" = "200" ]; then
    echo -e "${GREEN}✓ Both portals are accessible!${NC}"
    echo ""
    echo "Access URLs:"
    echo "  Admin:  http://$EC2_IP/admin/"
    echo "  Tenant: http://$EC2_IP/tenant/"
    echo "  API:    http://$EC2_IP:8080/health"
    echo ""
    echo "Test Accounts:"
    echo "  admin@pgworld.com / Admin@123"
    echo "  owner@pg.com / Owner@123"
    echo "  tenant@pg.com / Tenant@123"
else
    echo -e "${RED}✗ Applications not accessible${NC}"
    echo ""
    echo "Status:"
    echo "  Admin Portal:  HTTP $ADMIN_STATUS"
    echo "  Tenant Portal: HTTP $TENANT_STATUS"
    echo "  Backend API:   HTTP $API_STATUS"
    echo ""
    echo "Solution:"
    echo "  Run complete deployment:"
    echo "  ./FIX_403_AND_DEPLOY_FULL_APP.sh"
fi

echo ""
echo "=============================================="

