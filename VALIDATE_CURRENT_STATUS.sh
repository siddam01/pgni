#!/bin/bash
#================================================================
# COMPLETE STATUS VALIDATION
# Check what's installed and what's pending
#================================================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
EC2_HOST="34.227.111.143"
EC2_USER="ec2-user"
EC2_INSTANCE_ID="i-0909d462845deb151"
AWS_REGION="us-east-1"

echo -e "${BLUE}================================================================${NC}"
echo -e "${BLUE}   INFRASTRUCTURE & DEPLOYMENT STATUS VALIDATION${NC}"
echo -e "${BLUE}================================================================${NC}"
echo ""

#================================================================
# SECTION 1: AWS INFRASTRUCTURE
#================================================================
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}   SECTION 1: AWS INFRASTRUCTURE${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo "1.1 EC2 Instance Status:"
EC2_STATE=$(aws ec2 describe-instances \
    --instance-ids $EC2_INSTANCE_ID \
    --region $AWS_REGION \
    --query 'Reservations[0].Instances[0].State.Name' \
    --output text 2>/dev/null)

if [ "$EC2_STATE" = "running" ]; then
    echo -e "  ${GREEN}✓ EC2 Instance: RUNNING${NC}"
else
    echo -e "  ${RED}✗ EC2 Instance: $EC2_STATE${NC}"
fi

echo ""
echo "1.2 EC2 Instance Details:"
aws ec2 describe-instances \
    --instance-ids $EC2_INSTANCE_ID \
    --region $AWS_REGION \
    --query 'Reservations[0].Instances[0].[InstanceType,PublicIpAddress,PrivateIpAddress]' \
    --output text | awk '{print "  Instance Type: " $1 "\n  Public IP: " $2 "\n  Private IP: " $3}'

echo ""
echo "1.3 EC2 Volume Status:"
VOLUME_ID=$(aws ec2 describe-instances \
    --instance-ids $EC2_INSTANCE_ID \
    --region $AWS_REGION \
    --query 'Reservations[0].Instances[0].BlockDeviceMappings[0].Ebs.VolumeId' \
    --output text)

VOLUME_SIZE=$(aws ec2 describe-volumes \
    --volume-ids $VOLUME_ID \
    --region $AWS_REGION \
    --query 'Volumes[0].Size' \
    --output text)

VOLUME_STATE=$(aws ec2 describe-volumes \
    --volume-ids $VOLUME_ID \
    --region $AWS_REGION \
    --query 'Volumes[0].State' \
    --output text)

echo "  Volume ID: $VOLUME_ID"
echo "  Size: ${VOLUME_SIZE}GB"
echo "  State: $VOLUME_STATE"

if [ "$VOLUME_SIZE" -ge 100 ]; then
    echo -e "  ${GREEN}✓ Volume expanded to 100GB${NC}"
else
    echo -e "  ${YELLOW}⚠ Volume still at ${VOLUME_SIZE}GB (target: 100GB)${NC}"
fi

echo ""
echo "1.4 RDS Database Status:"
RDS_STATUS=$(aws rds describe-db-instances \
    --region $AWS_REGION \
    --query 'DBInstances[?contains(DBInstanceIdentifier, `pgni`) || contains(DBInstanceIdentifier, `database`)].{ID:DBInstanceIdentifier,Status:DBInstanceStatus,Endpoint:Endpoint.Address}' \
    --output text 2>/dev/null)

if [ -n "$RDS_STATUS" ]; then
    echo "$RDS_STATUS" | while read line; do
        echo "  $line"
    done
    echo -e "  ${GREEN}✓ RDS Database found${NC}"
else
    echo -e "  ${YELLOW}⚠ No RDS database found${NC}"
fi

echo ""
echo "1.5 S3 Bucket Status:"
S3_BUCKET=$(aws s3api list-buckets \
    --region $AWS_REGION \
    --query 'Buckets[?contains(Name, `pgni`)].Name' \
    --output text 2>/dev/null)

if [ -n "$S3_BUCKET" ]; then
    echo "  Bucket: $S3_BUCKET"
    echo -e "  ${GREEN}✓ S3 Bucket exists${NC}"
else
    echo -e "  ${YELLOW}⚠ No S3 bucket found${NC}"
fi

echo ""
echo "1.6 Security Groups:"
SG_ID=$(aws ec2 describe-instances \
    --instance-ids $EC2_INSTANCE_ID \
    --region $AWS_REGION \
    --query 'Reservations[0].Instances[0].SecurityGroups[0].GroupId' \
    --output text)

if [ -n "$SG_ID" ]; then
    echo "  Security Group: $SG_ID"
    
    # Check port 80
    PORT_80=$(aws ec2 describe-security-groups \
        --group-ids $SG_ID \
        --region $AWS_REGION \
        --query 'SecurityGroups[0].IpPermissions[?FromPort==`80`].FromPort' \
        --output text)
    
    # Check port 8080
    PORT_8080=$(aws ec2 describe-security-groups \
        --group-ids $SG_ID \
        --region $AWS_REGION \
        --query 'SecurityGroups[0].IpPermissions[?FromPort==`8080`].FromPort' \
        --output text)
    
    if [ -n "$PORT_80" ]; then
        echo -e "  ${GREEN}✓ Port 80 (HTTP) open${NC}"
    else
        echo -e "  ${YELLOW}⚠ Port 80 (HTTP) not open${NC}"
    fi
    
    if [ -n "$PORT_8080" ]; then
        echo -e "  ${GREEN}✓ Port 8080 (API) open${NC}"
    else
        echo -e "  ${YELLOW}⚠ Port 8080 (API) not open${NC}"
    fi
fi

#================================================================
# SECTION 2: EC2 SOFTWARE & SERVICES (requires SSH)
#================================================================
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}   SECTION 2: EC2 SOFTWARE & SERVICES${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Check if we can connect via AWS Systems Manager
echo "2.1 Checking EC2 connectivity..."
aws ssm describe-instance-information \
    --filters "Key=InstanceIds,Values=$EC2_INSTANCE_ID" \
    --region $AWS_REGION \
    --query 'InstanceInformationList[0].PingStatus' \
    --output text &>/dev/null

if [ $? -eq 0 ]; then
    echo -e "  ${GREEN}✓ EC2 accessible via Systems Manager${NC}"
    SSM_AVAILABLE=true
else
    echo -e "  ${YELLOW}⚠ Systems Manager not available, checking via HTTP${NC}"
    SSM_AVAILABLE=false
fi

# Check via HTTP endpoints
echo ""
echo "2.2 Checking HTTP endpoints:"

# Admin UI
ADMIN_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://$EC2_HOST/admin 2>/dev/null)
if [ "$ADMIN_STATUS" = "200" ]; then
    echo -e "  ${GREEN}✓ Admin UI: HTTP $ADMIN_STATUS (DEPLOYED)${NC}"
elif [ "$ADMIN_STATUS" = "301" ] || [ "$ADMIN_STATUS" = "302" ]; then
    echo -e "  ${YELLOW}⚠ Admin UI: HTTP $ADMIN_STATUS (REDIRECT)${NC}"
else
    echo -e "  ${RED}✗ Admin UI: HTTP $ADMIN_STATUS (NOT DEPLOYED)${NC}"
fi

# Tenant UI
TENANT_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://$EC2_HOST/tenant 2>/dev/null)
if [ "$TENANT_STATUS" = "200" ]; then
    echo -e "  ${GREEN}✓ Tenant UI: HTTP $TENANT_STATUS (DEPLOYED)${NC}"
elif [ "$TENANT_STATUS" = "301" ] || [ "$TENANT_STATUS" = "302" ]; then
    echo -e "  ${YELLOW}⚠ Tenant UI: HTTP $TENANT_STATUS (REDIRECT)${NC}"
else
    echo -e "  ${RED}✗ Tenant UI: HTTP $TENANT_STATUS (NOT DEPLOYED)${NC}"
fi

# API
API_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://$EC2_HOST:8080/health 2>/dev/null)
if [ "$API_STATUS" = "200" ]; then
    echo -e "  ${GREEN}✓ API: HTTP $API_STATUS (RUNNING)${NC}"
else
    echo -e "  ${RED}✗ API: HTTP $API_STATUS (NOT RUNNING)${NC}"
fi

# Check content
echo ""
echo "2.3 Checking deployed content:"
ADMIN_CONTENT=$(curl -s http://$EC2_HOST/admin | head -1)
if echo "$ADMIN_CONTENT" | grep -q "<!DOCTYPE html>"; then
    if echo "$ADMIN_CONTENT" | grep -q "flutter"; then
        echo -e "  ${GREEN}✓ Admin: Full Flutter app detected${NC}"
    else
        echo -e "  ${YELLOW}⚠ Admin: Placeholder page detected${NC}"
    fi
else
    echo -e "  ${RED}✗ Admin: No HTML content${NC}"
fi

TENANT_CONTENT=$(curl -s http://$EC2_HOST/tenant | head -1)
if echo "$TENANT_CONTENT" | grep -q "<!DOCTYPE html>"; then
    if echo "$TENANT_CONTENT" | grep -q "flutter"; then
        echo -e "  ${GREEN}✓ Tenant: Full Flutter app detected${NC}"
    else
        echo -e "  ${YELLOW}⚠ Tenant: Placeholder page detected${NC}"
    fi
else
    echo -e "  ${RED}✗ Tenant: No HTML content${NC}"
fi

#================================================================
# SECTION 3: DETAILED EC2 STATUS (if SSM available)
#================================================================
if [ "$SSM_AVAILABLE" = true ]; then
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}   SECTION 3: DETAILED EC2 STATUS${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    echo "3.1 Disk usage:"
    aws ssm send-command \
        --instance-ids $EC2_INSTANCE_ID \
        --document-name "AWS-RunShellScript" \
        --parameters 'commands=["df -h /"]' \
        --region $AWS_REGION \
        --output text \
        --query 'Command.CommandId' | xargs -I {} aws ssm get-command-invocation \
        --command-id {} \
        --instance-id $EC2_INSTANCE_ID \
        --region $AWS_REGION \
        --query 'StandardOutputContent' \
        --output text 2>/dev/null || echo "  Unable to retrieve disk usage"
    
    echo ""
    echo "3.2 Installed software:"
    aws ssm send-command \
        --instance-ids $EC2_INSTANCE_ID \
        --document-name "AWS-RunShellScript" \
        --parameters 'commands=["which flutter nginx git go 2>/dev/null | while read cmd; do echo \"  ✓ $cmd\"; done"]' \
        --region $AWS_REGION \
        --output text \
        --query 'Command.CommandId' | xargs -I {} aws ssm get-command-invocation \
        --command-id {} \
        --instance-id $EC2_INSTANCE_ID \
        --region $AWS_REGION \
        --query 'StandardOutputContent' \
        --output text 2>/dev/null || echo "  Unable to check software"
fi

#================================================================
# SECTION 4: SUMMARY
#================================================================
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}   SECTION 4: DEPLOYMENT STATUS SUMMARY${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Calculate completion percentage
COMPLETED=0
TOTAL=10

# Infrastructure checks
[ "$EC2_STATE" = "running" ] && ((COMPLETED++))
[ "$VOLUME_SIZE" -ge 100 ] && ((COMPLETED++))
[ -n "$RDS_STATUS" ] && ((COMPLETED++))
[ -n "$S3_BUCKET" ] && ((COMPLETED++))
[ -n "$PORT_80" ] && ((COMPLETED++))
[ -n "$PORT_8080" ] && ((COMPLETED++))

# Deployment checks
[ "$ADMIN_STATUS" = "200" ] && ((COMPLETED++))
[ "$TENANT_STATUS" = "200" ] && ((COMPLETED++))
[ "$API_STATUS" = "200" ] && ((COMPLETED++))
echo "$ADMIN_CONTENT" | grep -q "flutter" && ((COMPLETED++))

PERCENT=$((COMPLETED * 100 / TOTAL))

echo "Deployment Progress: $COMPLETED/$TOTAL components ($PERCENT%)"
echo ""

# Infrastructure status
echo "Infrastructure:"
[ "$EC2_STATE" = "running" ] && echo -e "  ${GREEN}✓${NC} EC2 Instance running" || echo -e "  ${RED}✗${NC} EC2 Instance not running"
[ "$VOLUME_SIZE" -ge 100 ] && echo -e "  ${GREEN}✓${NC} Disk expanded to 100GB" || echo -e "  ${YELLOW}⚠${NC} Disk needs expansion (currently ${VOLUME_SIZE}GB)"
[ -n "$RDS_STATUS" ] && echo -e "  ${GREEN}✓${NC} RDS Database available" || echo -e "  ${RED}✗${NC} RDS Database not found"
[ -n "$S3_BUCKET" ] && echo -e "  ${GREEN}✓${NC} S3 Bucket available" || echo -e "  ${RED}✗${NC} S3 Bucket not found"
[ -n "$PORT_80" ] && echo -e "  ${GREEN}✓${NC} Port 80 (HTTP) open" || echo -e "  ${YELLOW}⚠${NC} Port 80 needs to be opened"
[ -n "$PORT_8080" ] && echo -e "  ${GREEN}✓${NC} Port 8080 (API) open" || echo -e "  ${YELLOW}⚠${NC} Port 8080 needs to be opened"

echo ""
echo "Applications:"
[ "$ADMIN_STATUS" = "200" ] && echo -e "  ${GREEN}✓${NC} Admin UI deployed" || echo -e "  ${RED}✗${NC} Admin UI not deployed"
[ "$TENANT_STATUS" = "200" ] && echo -e "  ${GREEN}✓${NC} Tenant UI deployed" || echo -e "  ${RED}✗${NC} Tenant UI not deployed"
[ "$API_STATUS" = "200" ] && echo -e "  ${GREEN}✓${NC} Backend API running" || echo -e "  ${RED}✗${NC} Backend API not running"

echo ""
echo "Application Type:"
if echo "$ADMIN_CONTENT" | grep -q "flutter"; then
    echo -e "  ${GREEN}✓${NC} Full Flutter applications deployed"
else
    echo -e "  ${YELLOW}⚠${NC} Placeholder pages deployed (Flutter apps pending)"
fi

#================================================================
# SECTION 5: PENDING ACTIONS
#================================================================
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}   SECTION 5: PENDING ACTIONS${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

PENDING=()

[ "$VOLUME_SIZE" -lt 100 ] && PENDING+=("Expand EC2 disk to 100GB")
[ "$ADMIN_STATUS" != "200" ] && PENDING+=("Deploy Admin UI")
[ "$TENANT_STATUS" != "200" ] && PENDING+=("Deploy Tenant UI")
[ "$API_STATUS" != "200" ] && PENDING+=("Start Backend API")
echo "$ADMIN_CONTENT" | grep -q "flutter" || PENDING+=("Build and deploy Full Flutter applications")

if [ ${#PENDING[@]} -eq 0 ]; then
    echo -e "${GREEN}✓ No pending actions! All components deployed successfully.${NC}"
    echo ""
    echo "Your application is ready for testing!"
else
    echo "The following actions are pending:"
    echo ""
    for action in "${PENDING[@]}"; do
        echo "  ⚠ $action"
    done
    echo ""
    echo "Run the deployment script to complete setup:"
    echo "  ./DEPLOY_NO_TERRAFORM.sh"
fi

#================================================================
# SECTION 6: ACCESS INFORMATION
#================================================================
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}   SECTION 6: ACCESS INFORMATION${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo "URLs:"
echo "  Admin Portal:  http://$EC2_HOST/admin"
echo "  Tenant Portal: http://$EC2_HOST/tenant"
echo "  API Endpoint:  http://$EC2_HOST:8080"
echo ""
echo "Test Credentials:"
echo "  Admin:  admin@pgni.com / password123"
echo "  Tenant: tenant@pgni.com / password123"
echo ""

echo -e "${BLUE}================================================================${NC}"
echo -e "${BLUE}   VALIDATION COMPLETE${NC}"
echo -e "${BLUE}================================================================${NC}"
echo ""

