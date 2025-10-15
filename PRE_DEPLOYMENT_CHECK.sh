#!/bin/bash
#==============================================================================
# PRE-DEPLOYMENT VALIDATION SCRIPT
# Validates all prerequisites before running full deployment
#==============================================================================

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
EC2_IP="34.227.111.143"
REGION="us-east-1"

echo "=============================================="
echo "  Pre-Deployment Validation"
echo "=============================================="
echo ""

ERRORS=0
WARNINGS=0

#==============================================================================
# CHECK 1: AWS CLI
#==============================================================================
echo -n "Checking AWS CLI... "
if command -v aws &> /dev/null; then
    AWS_VERSION=$(aws --version 2>&1 | head -1)
    echo -e "${GREEN}✓${NC} $AWS_VERSION"
else
    echo -e "${RED}✗ AWS CLI not found${NC}"
    ERRORS=$((ERRORS + 1))
fi

#==============================================================================
# CHECK 2: AWS Credentials
#==============================================================================
echo -n "Checking AWS credentials... "
if aws sts get-caller-identity &> /dev/null; then
    AWS_ACCOUNT=$(aws sts get-caller-identity --query 'Account' --output text)
    echo -e "${GREEN}✓${NC} Account: $AWS_ACCOUNT"
else
    echo -e "${RED}✗ AWS credentials not configured${NC}"
    ERRORS=$((ERRORS + 1))
fi

#==============================================================================
# CHECK 3: Find EC2 Instance
#==============================================================================
echo ""
echo "Searching for EC2 instances..."
INSTANCES=$(aws ec2 describe-instances \
    --region "$REGION" \
    --filters "Name=ip-address,Values=$EC2_IP" \
    --query 'Reservations[*].Instances[*].[InstanceId,State.Name,InstanceType,Tags[?Key==`Name`].Value|[0]]' \
    --output text 2>/dev/null)

if [ -n "$INSTANCES" ]; then
    echo -e "${GREEN}✓ Found EC2 instance:${NC}"
    echo "$INSTANCES" | while read -r INSTANCE_ID STATE TYPE NAME; do
        echo "  Instance ID: $INSTANCE_ID"
        echo "  State: $STATE"
        echo "  Type: $TYPE"
        echo "  Name: $NAME"
        
        if [ "$STATE" != "running" ]; then
            echo -e "  ${RED}✗ Instance is not running!${NC}"
            ERRORS=$((ERRORS + 1))
        fi
    done
    
    # Save instance ID for later
    INSTANCE_ID=$(echo "$INSTANCES" | awk '{print $1}')
    echo ""
    echo "  Instance ID to use: $INSTANCE_ID"
else
    echo -e "${RED}✗ No EC2 instance found with IP $EC2_IP${NC}"
    echo "  Searching all running instances in $REGION..."
    
    ALL_INSTANCES=$(aws ec2 describe-instances \
        --region "$REGION" \
        --filters "Name=instance-state-name,Values=running" \
        --query 'Reservations[*].Instances[*].[InstanceId,PublicIpAddress,InstanceType,Tags[?Key==`Name`].Value|[0]]' \
        --output text 2>/dev/null)
    
    if [ -n "$ALL_INSTANCES" ]; then
        echo ""
        echo "Found these running instances:"
        echo "$ALL_INSTANCES"
    else
        echo -e "${RED}✗ No running instances found${NC}"
        ERRORS=$((ERRORS + 1))
    fi
fi

#==============================================================================
# CHECK 4: EC2 Connectivity
#==============================================================================
echo ""
echo -n "Testing EC2 connectivity (port 22)... "
if timeout 5 bash -c "cat < /dev/null > /dev/tcp/$EC2_IP/22" 2>/dev/null; then
    echo -e "${GREEN}✓ Port 22 is open${NC}"
else
    echo -e "${YELLOW}⚠ Port 22 is not accessible (may need VPN or security group update)${NC}"
    WARNINGS=$((WARNINGS + 1))
fi

echo -n "Testing EC2 connectivity (port 8080)... "
if timeout 5 bash -c "cat < /dev/null > /dev/tcp/$EC2_IP/8080" 2>/dev/null; then
    echo -e "${GREEN}✓ Port 8080 is open${NC}"
else
    echo -e "${YELLOW}⚠ Port 8080 is not accessible${NC}"
    WARNINGS=$((WARNINGS + 1))
fi

echo -n "Testing EC2 connectivity (port 80)... "
if timeout 5 bash -c "cat < /dev/null > /dev/tcp/$EC2_IP/80" 2>/dev/null; then
    echo -e "${GREEN}✓ Port 80 is open${NC}"
else
    echo -e "${YELLOW}⚠ Port 80 is not accessible${NC}"
    WARNINGS=$((WARNINGS + 1))
fi

#==============================================================================
# CHECK 5: SSH Key
#==============================================================================
echo ""
echo -n "Checking SSH key... "
if [ -f "cloudshell-key.pem" ]; then
    echo -e "${GREEN}✓ Found cloudshell-key.pem${NC}"
    
    # Check permissions
    PERMS=$(stat -c %a cloudshell-key.pem 2>/dev/null || stat -f %A cloudshell-key.pem 2>/dev/null)
    if [ "$PERMS" = "600" ]; then
        echo -e "  ${GREEN}✓ Permissions are correct (600)${NC}"
    else
        echo -e "  ${YELLOW}⚠ Permissions are $PERMS (should be 600)${NC}"
        echo "    Run: chmod 600 cloudshell-key.pem"
        WARNINGS=$((WARNINGS + 1))
    fi
    
    # Check key format
    KEY_HEADER=$(head -1 cloudshell-key.pem 2>/dev/null)
    if echo "$KEY_HEADER" | grep -q "BEGIN.*PRIVATE KEY\|BEGIN RSA PRIVATE KEY\|BEGIN OPENSSH PRIVATE KEY"; then
        echo -e "  ${GREEN}✓ Key format looks valid${NC}"
    else
        echo -e "  ${YELLOW}⚠ Key format looks unusual but may still work${NC}"
        echo "    First line: $KEY_HEADER"
        WARNINGS=$((WARNINGS + 1))
    fi
else
    echo -e "${RED}✗ SSH key not found${NC}"
    echo "  Run: curl -O https://raw.githubusercontent.com/siddam01/pgni/main/terraform/ssh-key.txt"
    echo "       mv ssh-key.txt cloudshell-key.pem"
    echo "       chmod 600 cloudshell-key.pem"
    ERRORS=$((ERRORS + 1))
fi

#==============================================================================
# CHECK 6: RDS Database
#==============================================================================
echo ""
echo "Checking RDS database..."
RDS_INFO=$(aws rds describe-db-instances \
    --region "$REGION" \
    --query 'DBInstances[?contains(DBInstanceIdentifier, `pgni`) || contains(DBInstanceIdentifier, `pgworld`)][DBInstanceIdentifier,DBInstanceStatus,Endpoint.Address,AllocatedStorage]' \
    --output text 2>/dev/null)

if [ -n "$RDS_INFO" ]; then
    echo -e "${GREEN}✓ Found RDS instance:${NC}"
    echo "$RDS_INFO" | while read -r DB_ID DB_STATUS DB_ENDPOINT DB_STORAGE; do
        echo "  Database ID: $DB_ID"
        echo "  Status: $DB_STATUS"
        echo "  Endpoint: $DB_ENDPOINT"
        echo "  Storage: ${DB_STORAGE}GB"
        
        if [ "$DB_STATUS" != "available" ]; then
            echo -e "  ${YELLOW}⚠ Database is not available (status: $DB_STATUS)${NC}"
            WARNINGS=$((WARNINGS + 1))
        fi
    done
else
    echo -e "${YELLOW}⚠ No RDS instance found${NC}"
    WARNINGS=$((WARNINGS + 1))
fi

#==============================================================================
# CHECK 7: S3 Bucket
#==============================================================================
echo ""
echo "Checking S3 bucket..."
S3_BUCKETS=$(aws s3 ls | grep -i pgni || true)

if [ -n "$S3_BUCKETS" ]; then
    echo -e "${GREEN}✓ Found S3 bucket(s):${NC}"
    echo "$S3_BUCKETS"
else
    echo -e "${YELLOW}⚠ No S3 bucket found${NC}"
    WARNINGS=$((WARNINGS + 1))
fi

#==============================================================================
# CHECK 8: GitHub Repository
#==============================================================================
echo ""
echo -n "Checking GitHub repository... "
GITHUB_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://raw.githubusercontent.com/siddam01/pgni/main/README.md 2>/dev/null || echo "000")
if [ "$GITHUB_STATUS" = "200" ]; then
    echo -e "${GREEN}✓ Repository is accessible${NC}"
else
    echo -e "${YELLOW}⚠ Cannot verify GitHub access (may be network issue)${NC}"
    echo "  This is OK - deployment script will handle it"
    WARNINGS=$((WARNINGS + 1))
fi

#==============================================================================
# CHECK 9: Deployment Script
#==============================================================================
echo ""
echo -n "Checking deployment script... "
if [ -f "COMPLETE_ENTERPRISE_DEPLOYMENT.sh" ]; then
    echo -e "${GREEN}✓ Deployment script found${NC}"
    
    if [ -x "COMPLETE_ENTERPRISE_DEPLOYMENT.sh" ]; then
        echo -e "  ${GREEN}✓ Script is executable${NC}"
    else
        echo -e "  ${YELLOW}⚠ Script is not executable${NC}"
        echo "    Run: chmod +x COMPLETE_ENTERPRISE_DEPLOYMENT.sh"
        WARNINGS=$((WARNINGS + 1))
    fi
else
    echo -e "${YELLOW}⚠ Deployment script not found${NC}"
    echo "  Run: curl -O https://raw.githubusercontent.com/siddam01/pgni/main/COMPLETE_ENTERPRISE_DEPLOYMENT.sh"
    WARNINGS=$((WARNINGS + 1))
fi

#==============================================================================
# CHECK 10: API Status
#==============================================================================
echo ""
echo -n "Checking if API is already running... "
API_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "http://$EC2_IP:8080/health" 2>/dev/null || echo "000")

if [ "$API_RESPONSE" = "200" ]; then
    echo -e "${GREEN}✓ API is already running!${NC}"
    echo "  URL: http://$EC2_IP:8080/health"
else
    echo -e "${YELLOW}⚠ API is not running (will be deployed)${NC}"
fi

#==============================================================================
# SUMMARY
#==============================================================================
echo ""
echo "=============================================="
echo "  Validation Summary"
echo "=============================================="
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✓ All checks passed!${NC}"
    echo ""
    echo "You are ready to deploy. Run:"
    echo "  ./COMPLETE_ENTERPRISE_DEPLOYMENT.sh"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠ $WARNINGS warning(s) found${NC}"
    echo ""
    echo "You can proceed with deployment, but review warnings above."
    echo ""
    echo "To deploy, run:"
    echo "  ./COMPLETE_ENTERPRISE_DEPLOYMENT.sh"
    exit 0
else
    echo -e "${RED}✗ $ERRORS error(s) found${NC}"
    echo -e "${YELLOW}⚠ $WARNINGS warning(s) found${NC}"
    echo ""
    echo "Please fix the errors above before deploying."
    exit 1
fi

