#!/bin/bash

# PGNI Frontend Deployment Script
# Usage: ./deploy-frontend.sh <s3-bucket> <ec2-api-ip>

set -e

echo "🎨 PGNI Frontend Deployment Script"
echo "==================================="

# Check arguments
if [ "$#" -lt 2 ]; then
    echo "Usage: ./deploy-frontend.sh <S3_BUCKET> <EC2_API_IP>"
    echo "Example: ./deploy-frontend.sh pgworld-admin-portal 54.227.101.30"
    exit 1
fi

S3_BUCKET=$1
EC2_API_IP=$2

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo ""
echo "${YELLOW}Step 1: Updating API endpoint in config...${NC}"
cd pgworld-master

# Update config.dart
CONFIG_FILE="lib/utils/config.dart"

# Backup original
cp "$CONFIG_FILE" "${CONFIG_FILE}.backup"

# Update API endpoints
sed -i.bak "s/static const String URL = \".*\";/static const String URL = \"$EC2_API_IP:8080\";/" "$CONFIG_FILE"
sed -i.bak "s|static const String BASE_URL = \".*\";|static const String BASE_URL = \"http://$EC2_API_IP:8080\";|" "$CONFIG_FILE"

echo "${GREEN}✅ Config updated${NC}"

echo ""
echo "${YELLOW}Step 2: Cleaning previous builds...${NC}"
flutter clean

echo ""
echo "${YELLOW}Step 3: Getting dependencies...${NC}"
flutter pub get

echo ""
echo "${YELLOW}Step 4: Building for web...${NC}"
flutter build web --release --no-source-maps

if [ $? -eq 0 ]; then
    echo "${GREEN}✅ Build successful${NC}"
else
    echo "${RED}❌ Build failed${NC}"
    # Restore backup
    mv "${CONFIG_FILE}.backup" "$CONFIG_FILE"
    exit 1
fi

echo ""
echo "${YELLOW}Step 5: Deploying to S3...${NC}"

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "${RED}❌ AWS CLI not found. Please install it first.${NC}"
    echo "Install: https://aws.amazon.com/cli/"
    exit 1
fi

# Check if AWS is configured
if ! aws sts get-caller-identity &> /dev/null; then
    echo "${YELLOW}⚠️  AWS CLI not configured. Running aws configure...${NC}"
    aws configure
fi

# Upload to S3
echo "Uploading files to s3://$S3_BUCKET..."
aws s3 sync build/web/ s3://$S3_BUCKET/ --delete

if [ $? -eq 0 ]; then
    echo "${GREEN}✅ Files uploaded to S3${NC}"
else
    echo "${RED}❌ S3 upload failed${NC}"
    exit 1
fi

# Set cache control
echo "Setting cache control headers..."
aws s3 cp s3://$S3_BUCKET/ s3://$S3_BUCKET/ \
  --recursive \
  --metadata-directive REPLACE \
  --cache-control max-age=31536000,public \
  --exclude "index.html" \
  --exclude "flutter_service_worker.js" 2>/dev/null || true

aws s3 cp s3://$S3_BUCKET/index.html s3://$S3_BUCKET/index.html \
  --metadata-directive REPLACE \
  --cache-control max-age=0,no-cache,no-store,must-revalidate 2>/dev/null || true

echo ""
echo "${GREEN}✅ Frontend deployed successfully!${NC}"
echo ""
echo "S3 URL: http://$S3_BUCKET.s3-website-$AWS_DEFAULT_REGION.amazonaws.com"
echo ""
echo "To setup CloudFront (CDN):"
echo "1. Go to AWS CloudFront Console"
echo "2. Create distribution with S3 bucket as origin"
echo "3. Wait 15-20 minutes for deployment"
echo ""
echo "To invalidate CloudFront cache (if using):"
echo "  aws cloudfront create-invalidation --distribution-id YOUR_ID --paths '/*'"

# Restore original config backup (optional)
rm "${CONFIG_FILE}.bak" 2>/dev/null || true

cd ..

