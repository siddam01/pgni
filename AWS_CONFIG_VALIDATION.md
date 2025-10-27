# AWS Configuration Validation Guide

## 📋 Current AWS Setup (Pre-Prod)

### 1. Backend API Configuration

**API Gateway:**
- Service: Amazon API Gateway (REST API)
- Name: CloudPG API
- Stage: pre-prod
- Base URL: Check in `pgworld-master/lib/utils/config.dart`

**Validation Steps:**
```bash
# Check API configuration in app
cat pgworld-master/lib/utils/config.dart | grep -i "api\|url"
cat pgworldtenant-master/lib/utils/config.dart | grep -i "api\|url"
```

Expected configuration:
```dart
class Config {
  static const String baseURL = "YOUR_API_GATEWAY_URL";
  static const String apiVersion = "v1";
  // ... other config
}
```

### 2. Database Configuration

**RDS MySQL:**
- Instance: CloudPG Database
- Engine: MySQL 5.7+
- Access: Via Lambda functions (not direct)

**Tables Required:**
- `admins` - Admin users
- `users` - Tenant users
- `hostels` - Property listings
- `rooms` - Room inventory
- `bills` - Billing records
- `employees` - Staff records
- `notes` - Notices/Announcements
- `issues` - Tenant complaints
- `admin_permissions` - RBAC permissions

**Validation:**
```bash
# Check if backend API is accessible
curl -I YOUR_API_GATEWAY_URL/health

# Expected: HTTP/1.1 200 OK
```

### 3. S3 Storage Configuration

**Bucket:** CloudPG Media Storage

**Used for:**
- User profile photos
- User documents (ID proof, etc.)
- Room photos
- Bill attachments

**Access:** Via pre-signed URLs from Lambda

**Bucket Structure:**
```
cloudpg-media/
├── users/
│   ├── {user_id}/
│   │   ├── profile.jpg
│   │   └── documents/
├── rooms/
│   └── {room_id}/
│       └── photos/
└── bills/
    └── {bill_id}/
        └── attachments/
```

**Validation:**
```bash
# Check if media URLs are accessible
# Example from app config
echo $MEDIA_URL
```

### 4. Authentication (Cognito)

**User Pool:** CloudPG Users

**Configuration:**
- Sign-in: Username + Password
- MFA: Optional
- Password Policy: Configured
- Email Verification: Enabled

**App Clients:**
- Admin App Client
- Tenant App Client

**Validation:**
```bash
# Check Cognito config in app
cat pgworld-master/lib/aws_exports.dart 2>/dev/null || echo "No Cognito config found"
cat pgworldtenant-master/lib/aws_exports.dart 2>/dev/null || echo "No Cognito config found"
```

### 5. Lambda Functions

**Functions Required:**
- `cloudpg-admin-api` - Admin operations
- `cloudpg-tenant-api` - Tenant operations
- `cloudpg-auth` - Authentication
- `cloudpg-media-upload` - File uploads

**Runtime:** Node.js 18.x or Python 3.9+

**Validation:**
```bash
# Check Lambda function names
aws lambda list-functions --query 'Functions[?contains(FunctionName, `cloudpg`)].FunctionName' 2>/dev/null || echo "AWS CLI not configured"
```

---

## 🔍 Configuration Files to Check

### Admin Portal Config

**File:** `pgworld-master/lib/utils/config.dart`

**Key Settings:**
```dart
class Config {
  static const String baseURL = ""; // API Gateway URL
  static const String mediaURL = ""; // S3 CloudFront/direct URL
  static const String version = "1.0.0";
  
  // Status codes
  static const String STATUS_200 = "200";
  static const String STATUS_403 = "403";
  static const String STATUS_400 = "400";
  static const String STATUS_500 = "500";
  
  // Pagination
  static const String defaultLimit = "20";
  static const String defaultOffset = "0";
}

class API {
  static const String USER = '/user';
  static const String ROOM = '/room';
  static const String BILL = '/bill';
  static const String EMPLOYEE = '/employee';
  static const String NOTE = '/note';
  static const String ISSUE = '/issue';
  // ... other endpoints
}
```

### Tenant Portal Config

**File:** `pgworldtenant-master/lib/utils/config.dart`

**Key Settings:**
```dart
class Config {
  static const String baseURL = ""; // Same API Gateway
  static const String mediaURL = ""; // Same S3 URL
  static const String version = "1.0.0";
  
  // Similar structure to admin
}

class API {
  static const String USER = '/user';
  static const String ROOM = '/room';
  static const String RENT = '/rent';  // Bills for tenants
  static const String SUPPORT = '/support';
  // ... other endpoints
}
```

---

## ✅ Pre-Deployment Validation Checklist

### Backend Services
- [ ] API Gateway is accessible
- [ ] Lambda functions are deployed and active
- [ ] RDS database is running
- [ ] Database has all required tables
- [ ] S3 bucket exists and is accessible
- [ ] Cognito User Pool is configured

### App Configuration
- [ ] `baseURL` is set to correct API Gateway endpoint
- [ ] `mediaURL` is set to correct S3/CloudFront URL
- [ ] All API endpoints are defined correctly
- [ ] Authentication flow is configured
- [ ] Error handling is in place

### Network & Security
- [ ] API Gateway has CORS enabled
- [ ] Lambda has correct IAM roles
- [ ] S3 bucket has correct policies
- [ ] Cognito has correct app clients
- [ ] Security groups allow necessary traffic

---

## 🚀 Deployment with Configuration

### Option 1: Use Existing Configuration (RECOMMENDED)

The pre-built files from commit `c5266e0` already have the correct configuration embedded. Just deploy as-is:

```bash
bash <(curl -sL "https://raw.githubusercontent.com/siddam01/pgni/main/deploy-clean-version-ec2.sh?$(date +%s)")
```

### Option 2: Update Configuration Before Building

If you need to change API endpoints:

1. **Edit Config Files:**
```bash
# Admin
vi pgworld-master/lib/utils/config.dart

# Tenant
vi pgworldtenant-master/lib/utils/config.dart
```

2. **Rebuild (requires Flutter 2.x):**
```bash
# Note: Current codebase won't compile with Flutter 3.x
# Use pre-built files instead
```

---

## 🔐 Environment Variables (Backend)

**Lambda Functions should have:**

```bash
# Database
DB_HOST=your-rds-endpoint.rds.amazonaws.com
DB_USER=cloudpg_user
DB_PASSWORD=*** (from Secrets Manager)
DB_NAME=cloudpg_db

# S3
S3_BUCKET=cloudpg-media
S3_REGION=us-east-1

# Cognito
COGNITO_USER_POOL_ID=us-east-1_XXXXXXXXX
COGNITO_CLIENT_ID_ADMIN=***
COGNITO_CLIENT_ID_TENANT=***

# API
API_STAGE=pre-prod
CORS_ORIGIN=*
```

---

## 📊 Post-Deployment Configuration Verification

### 1. Check API Connectivity

```bash
# From EC2 instance
curl -X GET "YOUR_API_GATEWAY_URL/health" -H "Content-Type: application/json"

# Expected response:
# {"status": "ok", "version": "1.0.0"}
```

### 2. Check Media URLs

```bash
# Test S3 access
curl -I "YOUR_S3_URL/test.jpg"

# Expected: HTTP/1.1 200 OK or 403 if private
```

### 3. Test Authentication Flow

```bash
# Test login endpoint
curl -X POST "YOUR_API_GATEWAY_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"test@cloudpg.com","password":"Test123!"}' 

# Expected: JWT token or Cognito token
```

---

## 🛠️ Configuration Issues & Solutions

### Issue 1: API Not Accessible

**Symptoms:**
- App shows "Network Error"
- Cannot load data

**Solution:**
```bash
# Check API Gateway
aws apigateway get-rest-apis

# Check Lambda functions
aws lambda list-functions --query 'Functions[?contains(FunctionName, `cloudpg`)]'

# Check if API is deployed to stage
aws apigateway get-stages --rest-api-id YOUR_API_ID
```

### Issue 2: CORS Errors

**Symptoms:**
- Browser console shows CORS error
- Preflight requests fail

**Solution:**
```bash
# Enable CORS on API Gateway
# OR add CORS headers in Lambda response:
{
  "headers": {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "Content-Type,Authorization",
    "Access-Control-Allow-Methods": "GET,POST,PUT,DELETE,OPTIONS"
  }
}
```

### Issue 3: Media Files Not Loading

**Symptoms:**
- Images show broken
- Documents won't download

**Solution:**
```bash
# Check S3 bucket policy
aws s3api get-bucket-policy --bucket cloudpg-media

# Check if bucket allows public read (if needed)
# OR implement pre-signed URLs in Lambda
```

### Issue 4: Authentication Fails

**Symptoms:**
- Cannot login
- Token expired errors

**Solution:**
```bash
# Check Cognito User Pool
aws cognito-idp describe-user-pool --user-pool-id YOUR_POOL_ID

# Check app clients
aws cognito-idp list-user-pool-clients --user-pool-id YOUR_POOL_ID

# Verify credentials in app config
```

---

## 📝 Configuration Best Practices

1. **Never Hardcode Credentials**
   - Use AWS Secrets Manager
   - Use environment variables
   - Use IAM roles where possible

2. **Use Separate Configurations**
   - Dev, Staging, Prod environments
   - Different Cognito pools
   - Different S3 buckets

3. **Enable Logging**
   - CloudWatch Logs for Lambda
   - API Gateway access logs
   - Application logs

4. **Monitor Resources**
   - Set up CloudWatch alarms
   - Monitor API Gateway throttling
   - Monitor Lambda errors
   - Monitor RDS connections

5. **Implement Caching**
   - Use API Gateway caching
   - Use CloudFront for media
   - Cache static assets

---

## ✅ Configuration Summary

**Current State:**
- ✅ Pre-built files have embedded configuration
- ✅ Configuration tested and working (commit c5266e0)
- ✅ All AWS services already set up
- ✅ No new resources needed

**What to Validate:**
1. API Gateway endpoint is accessible
2. Database is running and populated
3. S3 bucket has media files
4. Cognito User Pool has users

**Ready to Deploy:**
```bash
bash <(curl -sL "https://raw.githubusercontent.com/siddam01/pgni/main/deploy-clean-version-ec2.sh?$(date +%s)")
```

---

**Note:** The pre-built files from commit `c5266e0` already have all configuration embedded. You don't need to modify anything unless your AWS endpoints have changed.

