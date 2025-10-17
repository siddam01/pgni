#!/bin/bash
#==============================================================================
# Check Current Deployment Status
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
echo "  Current Deployment Status Check"
echo "=============================================="
echo "Date: $(date)"
echo "Region: $REGION"
echo "Instance: $INSTANCE_ID"
echo "IP: $EC2_IP"
echo ""

#==============================================================================
# 1. EC2 INSTANCE STATUS
#==============================================================================
echo -e "${CYAN}=== 1. EC2 Instance Status ===${NC}"
echo ""

EC2_STATE=$(aws ec2 describe-instances \
    --instance-ids "$INSTANCE_ID" \
    --region "$REGION" \
    --query 'Reservations[0].Instances[0].State.Name' \
    --output text 2>/dev/null)

if [ "$EC2_STATE" = "running" ]; then
    echo -e "${GREEN}✓${NC} EC2 Instance: Running"
else
    echo -e "${RED}✗${NC} EC2 Instance: $EC2_STATE"
fi

# Get instance details
aws ec2 describe-instances \
    --instance-ids "$INSTANCE_ID" \
    --region "$REGION" \
    --query 'Reservations[0].Instances[0].[InstanceType,PublicIpAddress,PrivateIpAddress,LaunchTime]' \
    --output text 2>/dev/null | while read -r TYPE PUBLIC_IP PRIVATE_IP LAUNCH; do
    echo "  Type: $TYPE"
    echo "  Public IP: $PUBLIC_IP"
    echo "  Private IP: $PRIVATE_IP"
    echo "  Launched: $LAUNCH"
done

# Check disk space
VOLUME_ID=$(aws ec2 describe-instances \
    --instance-ids "$INSTANCE_ID" \
    --region "$REGION" \
    --query 'Reservations[0].Instances[0].BlockDeviceMappings[0].Ebs.VolumeId' \
    --output text 2>/dev/null)

VOLUME_SIZE=$(aws ec2 describe-volumes \
    --volume-ids "$VOLUME_ID" \
    --region "$REGION" \
    --query 'Volumes[0].Size' \
    --output text 2>/dev/null)

echo "  Disk Size: ${VOLUME_SIZE}GB"

echo ""

#==============================================================================
# 2. NETWORK CONNECTIVITY
#==============================================================================
echo -e "${CYAN}=== 2. Network Connectivity ===${NC}"
echo ""

# Test port 22 (SSH)
echo -n "Port 22 (SSH): "
if timeout 3 bash -c "cat < /dev/null > /dev/tcp/$EC2_IP/22" 2>/dev/null; then
    echo -e "${GREEN}✓ Open${NC}"
else
    echo -e "${YELLOW}⚠ Not accessible${NC}"
fi

# Test port 80 (HTTP)
echo -n "Port 80 (HTTP): "
if timeout 3 bash -c "cat < /dev/null > /dev/tcp/$EC2_IP/80" 2>/dev/null; then
    echo -e "${GREEN}✓ Open${NC}"
else
    echo -e "${YELLOW}⚠ Not accessible${NC}"
fi

# Test port 8080 (API)
echo -n "Port 8080 (API): "
if timeout 3 bash -c "cat < /dev/null > /dev/tcp/$EC2_IP/8080" 2>/dev/null; then
    echo -e "${GREEN}✓ Open${NC}"
else
    echo -e "${YELLOW}⚠ Not accessible${NC}"
fi

echo ""

#==============================================================================
# 3. APPLICATION STATUS
#==============================================================================
echo -e "${CYAN}=== 3. Application Status ===${NC}"
echo ""

# Check Backend API
echo -n "Backend API: "
API_RESPONSE=$(curl -s http://$EC2_IP:8080/health 2>/dev/null)
API_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://$EC2_IP:8080/health 2>/dev/null || echo "000")

if [ "$API_STATUS" = "200" ]; then
    echo -e "${GREEN}✓ Running${NC}"
    echo "  Response: $API_RESPONSE"
else
    echo -e "${RED}✗ Not responding (HTTP $API_STATUS)${NC}"
fi

# Check Admin Portal
echo -n "Admin Portal: "
ADMIN_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://$EC2_IP/admin/ 2>/dev/null || echo "000")

if [ "$ADMIN_STATUS" = "200" ]; then
    echo -e "${GREEN}✓ Accessible${NC}"
    echo "  URL: http://$EC2_IP/admin/"
elif [ "$ADMIN_STATUS" = "301" ] || [ "$ADMIN_STATUS" = "302" ]; then
    echo -e "${GREEN}✓ Accessible (redirect)${NC}"
    echo "  URL: http://$EC2_IP/admin/"
else
    echo -e "${RED}✗ Not accessible (HTTP $ADMIN_STATUS)${NC}"
fi

# Check Tenant Portal
echo -n "Tenant Portal: "
TENANT_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://$EC2_IP/tenant/ 2>/dev/null || echo "000")

if [ "$TENANT_STATUS" = "200" ]; then
    echo -e "${GREEN}✓ Accessible${NC}"
    echo "  URL: http://$EC2_IP/tenant/"
elif [ "$TENANT_STATUS" = "301" ] || [ "$TENANT_STATUS" = "302" ]; then
    echo -e "${GREEN}✓ Accessible (redirect)${NC}"
    echo "  URL: http://$EC2_IP/tenant/"
else
    echo -e "${RED}✗ Not accessible (HTTP $TENANT_STATUS)${NC}"
fi

echo ""

#==============================================================================
# 4. EC2 SERVICES CHECK (via SSM)
#==============================================================================
echo -e "${CYAN}=== 4. Services on EC2 (via SSM) ===${NC}"
echo ""

COMMAND_ID=$(aws ssm send-command \
    --instance-ids "$INSTANCE_ID" \
    --region "$REGION" \
    --document-name "AWS-RunShellScript" \
    --comment "Check services" \
    --parameters 'commands=[
        "echo === Disk Usage ===",
        "df -h / | tail -1",
        "echo",
        "echo === Installed Software ===",
        "which git && echo Git: installed || echo Git: not installed",
        "which nginx && echo Nginx: installed || echo Nginx: not installed",
        "which flutter && echo Flutter: installed || echo Flutter: not installed",
        "[ -d /home/ec2-user/flutter ] && echo Flutter SDK: /home/ec2-user/flutter || echo Flutter SDK: not found",
        "echo",
        "echo === API Service ===",
        "sudo systemctl is-active pgworld-api 2>/dev/null || echo API service: not configured",
        "echo",
        "echo === Nginx Service ===",
        "sudo systemctl is-active nginx 2>/dev/null || echo Nginx: not active",
        "echo",
        "echo === Deployed Files ===",
        "[ -d /usr/share/nginx/html/admin ] && echo Admin files: exist || echo Admin files: not found",
        "[ -d /usr/share/nginx/html/tenant ] && echo Tenant files: exist || echo Tenant files: not found",
        "[ -f /usr/share/nginx/html/admin/index.html ] && echo Admin index.html: exists || echo Admin index.html: missing",
        "[ -f /usr/share/nginx/html/tenant/index.html ] && echo Tenant index.html: exists || echo Tenant index.html: missing",
        "echo",
        "echo === Source Code ===",
        "[ -d /home/ec2-user/pgni ] && echo Source code: cloned || echo Source code: not cloned",
        "[ -d /home/ec2-user/pgni/pgworld-master/build/web ] && echo Admin build: exists || echo Admin build: not found",
        "[ -d /home/ec2-user/pgni/pgworldtenant-master/build/web ] && echo Tenant build: exists || echo Tenant build: not found"
    ]' \
    --query 'Command.CommandId' \
    --output text 2>/dev/null)

if [ $? -eq 0 ] && [ "$COMMAND_ID" != "" ]; then
    echo "Checking EC2 services... (waiting 10 seconds)"
    sleep 10
    
    # Get command output
    aws ssm get-command-invocation \
        --command-id "$COMMAND_ID" \
        --instance-id "$INSTANCE_ID" \
        --region "$REGION" \
        --query 'StandardOutputContent' \
        --output text 2>/dev/null || echo "Could not retrieve command output"
else
    echo -e "${YELLOW}⚠ Could not check EC2 services via SSM${NC}"
    echo "You can check manually via AWS Console > Systems Manager > Session Manager"
fi

echo ""

#==============================================================================
# 5. RDS DATABASE
#==============================================================================
echo -e "${CYAN}=== 5. RDS Database ===${NC}"
echo ""

RDS_INFO=$(aws rds describe-db-instances \
    --region "$REGION" \
    --query 'DBInstances[?contains(DBInstanceIdentifier, `pgni`) || contains(DBInstanceIdentifier, `pgworld`)][DBInstanceIdentifier,DBInstanceStatus,Endpoint.Address,AllocatedStorage,DBInstanceClass]' \
    --output text 2>/dev/null)

if [ -n "$RDS_INFO" ]; then
    echo "$RDS_INFO" | while read -r DB_ID DB_STATUS DB_ENDPOINT DB_STORAGE DB_CLASS; do
        if [ "$DB_STATUS" = "available" ]; then
            echo -e "${GREEN}✓${NC} Database: $DB_ID"
        else
            echo -e "${YELLOW}⚠${NC} Database: $DB_ID"
        fi
        echo "  Status: $DB_STATUS"
        echo "  Endpoint: $DB_ENDPOINT"
        echo "  Storage: ${DB_STORAGE}GB"
        echo "  Class: $DB_CLASS"
    done
else
    echo -e "${YELLOW}⚠ No RDS instance found${NC}"
fi

echo ""

#==============================================================================
# 6. S3 BUCKET
#==============================================================================
echo -e "${CYAN}=== 6. S3 Storage ===${NC}"
echo ""

S3_BUCKETS=$(aws s3 ls 2>/dev/null | grep -i pgni || true)

if [ -n "$S3_BUCKETS" ]; then
    echo -e "${GREEN}✓${NC} S3 Bucket(s):"
    echo "$S3_BUCKETS"
else
    echo -e "${YELLOW}⚠ No S3 bucket found${NC}"
fi

echo ""

#==============================================================================
# 7. DEPLOYMENT SUMMARY
#==============================================================================
echo "=============================================="
echo "  Deployment Summary"
echo "=============================================="
echo ""

# Overall status
DEPLOYED=0
TOTAL=0

# Check each component
if [ "$API_STATUS" = "200" ]; then
    DEPLOYED=$((DEPLOYED + 1))
fi
TOTAL=$((TOTAL + 1))

if [ "$ADMIN_STATUS" = "200" ] || [ "$ADMIN_STATUS" = "301" ] || [ "$ADMIN_STATUS" = "302" ]; then
    DEPLOYED=$((DEPLOYED + 1))
fi
TOTAL=$((TOTAL + 1))

if [ "$TENANT_STATUS" = "200" ] || [ "$TENANT_STATUS" = "301" ] || [ "$TENANT_STATUS" = "302" ]; then
    DEPLOYED=$((DEPLOYED + 1))
fi
TOTAL=$((TOTAL + 1))

PERCENT=$((DEPLOYED * 100 / TOTAL))

echo "Deployment Progress: $DEPLOYED/$TOTAL components ($PERCENT%)"
echo ""

if [ $DEPLOYED -eq $TOTAL ]; then
    echo -e "${GREEN}✓ FULLY DEPLOYED${NC}"
    echo ""
    echo "Access your application:"
    echo "  Admin Portal:  http://$EC2_IP/admin/"
    echo "  Tenant Portal: http://$EC2_IP/tenant/"
    echo "  Backend API:   http://$EC2_IP:8080/health"
    echo ""
    echo "Test Accounts:"
    echo "  Admin: admin@pgworld.com / Admin@123"
    echo "  Owner: owner@pg.com / Owner@123"
    echo "  Tenant: tenant@pg.com / Tenant@123"
elif [ $DEPLOYED -gt 0 ]; then
    echo -e "${YELLOW}⚠ PARTIALLY DEPLOYED${NC}"
    echo ""
    echo "What's working:"
    [ "$API_STATUS" = "200" ] && echo "  ✓ Backend API"
    [ "$ADMIN_STATUS" = "200" ] && echo "  ✓ Admin Portal"
    [ "$TENANT_STATUS" = "200" ] && echo "  ✓ Tenant Portal"
    echo ""
    echo "What's missing:"
    [ "$API_STATUS" != "200" ] && echo "  ✗ Backend API"
    [ "$ADMIN_STATUS" != "200" ] && echo "  ✗ Admin Portal"
    [ "$TENANT_STATUS" != "200" ] && echo "  ✗ Tenant Portal"
    echo ""
    echo "To complete deployment, run:"
    echo "  ./DEPLOY_VIA_SSM.sh"
else
    echo -e "${RED}✗ NOT DEPLOYED${NC}"
    echo ""
    echo "Infrastructure is ready, but applications are not deployed."
    echo ""
    echo "To deploy, run:"
    echo "  ./DEPLOY_VIA_SSM.sh"
fi

echo ""
echo "=============================================="

