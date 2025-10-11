#!/bin/bash
################################################################################
# PGNI API - COMPLETE DEPLOYMENT & VALIDATION SOLUTION
# Senior Technical Expert - End-to-End Automation
#
# This script will:
# 1. Validate AWS infrastructure
# 2. Check security groups and networking
# 3. Deploy API to EC2
# 4. Configure systemd service
# 5. Initialize database
# 6. Perform health checks
# 7. Test all endpoints
# 8. Generate comprehensive validation report
# 9. Provide mobile app configuration
################################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
EC2_IP="34.227.111.143"
EC2_USER="ec2-user"
DB_HOST="database-pgni.cezawkgguojl.us-east-1.rds.amazonaws.com"
DB_PORT="3306"
DB_NAME="pgworld"
DB_USER="admin"
DB_PASS="Omsairamdb951#"
REPO_URL="https://github.com/siddam01/pgni.git"
API_PORT="8080"
REGION="us-east-1"

# Report file
REPORT_FILE="deployment_validation_report_$(date +%Y%m%d_%H%M%S).txt"

################################################################################
# Utility Functions
################################################################################

log() {
    echo -e "${CYAN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" >> "$REPORT_FILE"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
    echo "✅ $1" >> "$REPORT_FILE"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
    echo "❌ $1" >> "$REPORT_FILE"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
    echo "⚠️  $1" >> "$REPORT_FILE"
}

log_header() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    echo "" >> "$REPORT_FILE"
    echo "==========================================" >> "$REPORT_FILE"
    echo "$1" >> "$REPORT_FILE"
    echo "==========================================" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
}

################################################################################
# PHASE 1: Infrastructure Validation
################################################################################

validate_infrastructure() {
    log_header "PHASE 1: INFRASTRUCTURE VALIDATION"
    
    # Check AWS CLI
    log "Checking AWS CLI..."
    if command -v aws &> /dev/null; then
        AWS_VERSION=$(aws --version 2>&1)
        log_success "AWS CLI installed: $AWS_VERSION"
    else
        log_error "AWS CLI not found. Installing..."
        curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
        unzip -q awscliv2.zip
        sudo ./aws/install
        rm -rf aws awscliv2.zip
        log_success "AWS CLI installed"
    fi
    
    # Check EC2 instance
    log "Validating EC2 instance..."
    EC2_STATUS=$(aws ec2 describe-instances \
        --filters "Name=ip-address,Values=$EC2_IP" \
        --query "Reservations[0].Instances[0].State.Name" \
        --output text \
        --region $REGION 2>/dev/null || echo "unknown")
    
    if [ "$EC2_STATUS" = "running" ]; then
        log_success "EC2 instance is running (IP: $EC2_IP)"
    else
        log_error "EC2 instance not running (Status: $EC2_STATUS)"
        return 1
    fi
    
    # Check security group
    log "Validating security group for port $API_PORT..."
    SG_ID=$(aws ec2 describe-instances \
        --filters "Name=ip-address,Values=$EC2_IP" \
        --query "Reservations[0].Instances[0].SecurityGroups[0].GroupId" \
        --output text \
        --region $REGION 2>/dev/null)
    
    PORT_OPEN=$(aws ec2 describe-security-groups \
        --group-ids $SG_ID \
        --query "SecurityGroups[0].IpPermissions[?FromPort==\`$API_PORT\`].FromPort" \
        --output text \
        --region $REGION 2>/dev/null)
    
    if [ "$PORT_OPEN" = "$API_PORT" ]; then
        log_success "Security group allows port $API_PORT"
    else
        log_warning "Port $API_PORT may not be open in security group"
    fi
    
    # Test EC2 connectivity
    log "Testing EC2 connectivity..."
    if ping -c 1 -W 2 $EC2_IP &> /dev/null; then
        log_success "EC2 is reachable"
    else
        log_warning "EC2 ping failed (may be blocked by firewall)"
    fi
    
    # Check RDS
    log "Validating RDS database..."
    if mysql -h $DB_HOST -P $DB_PORT -u $DB_USER -p$DB_PASS -e "SELECT 1" &> /dev/null; then
        log_success "RDS database is accessible"
    else
        log_error "Cannot connect to RDS database"
        return 1
    fi
}

################################################################################
# PHASE 2: SSH Key Setup
################################################################################

setup_ssh_key() {
    log_header "PHASE 2: SSH KEY SETUP"
    
    # Get SSH key from SSM Parameter Store
    log "Retrieving SSH private key from SSM..."
    aws ssm get-parameter \
        --name "/pgni/preprod/ssh_private_key" \
        --with-decryption \
        --query "Parameter.Value" \
        --output text \
        --region $REGION > ec2-key.pem 2>/dev/null || {
        log_warning "Could not retrieve from SSM, checking local files..."
        if [ ! -f "ec2-key.pem" ]; then
            log_error "SSH key not found. Please provide ec2-key.pem"
            return 1
        fi
    }
    
    chmod 600 ec2-key.pem
    log_success "SSH key configured"
    
    # Test SSH connection
    log "Testing SSH connection..."
    if ssh -i ec2-key.pem -o StrictHostKeyChecking=no -o ConnectTimeout=10 \
        $EC2_USER@$EC2_IP "echo 'SSH connection successful'" &> /dev/null; then
        log_success "SSH connection established"
    else
        log_error "SSH connection failed"
        return 1
    fi
}

################################################################################
# PHASE 3: Prerequisites Installation
################################################################################

install_prerequisites() {
    log_header "PHASE 3: PREREQUISITES INSTALLATION"
    
    log "Installing prerequisites on EC2..."
    
    ssh -i ec2-key.pem -o StrictHostKeyChecking=no $EC2_USER@$EC2_IP << 'PREREQUISITES'
set -e

echo "Updating system packages..."
sudo yum update -y > /dev/null 2>&1

echo "Installing Git..."
sudo yum install -y git > /dev/null 2>&1

echo "Installing wget..."
sudo yum install -y wget > /dev/null 2>&1

echo "Installing MySQL client..."
sudo yum install -y mysql > /dev/null 2>&1

# Install Go if not present
if [ ! -f /usr/local/go/bin/go ]; then
    echo "Installing Go 1.21.0..."
    cd /tmp
    wget -q https://go.dev/dl/go1.21.0.linux-amd64.tar.gz
    sudo tar -C /usr/local -xzf go1.21.0.linux-amd64.tar.gz
    rm go1.21.0.linux-amd64.tar.gz
    echo "export PATH=\$PATH:/usr/local/go/bin" >> ~/.bashrc
fi

echo "✅ Prerequisites installed successfully"
PREREQUISITES
    
    if [ $? -eq 0 ]; then
        log_success "Prerequisites installed on EC2"
    else
        log_error "Failed to install prerequisites"
        return 1
    fi
}

################################################################################
# PHASE 4: API Deployment
################################################################################

deploy_api() {
    log_header "PHASE 4: API DEPLOYMENT"
    
    log "Deploying API to EC2..."
    
    # Create environment file locally
    cat > preprod.env << EOF
DB_HOST=$DB_HOST
DB_PORT=$DB_PORT
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASS
DB_NAME=$DB_NAME
AWS_REGION=$REGION
S3_BUCKET=pgni-preprod-698302425856-uploads
PORT=$API_PORT
test=false
EOF
    
    # Upload environment file
    log "Uploading environment file..."
    scp -i ec2-key.pem -o StrictHostKeyChecking=no preprod.env $EC2_USER@$EC2_IP:~/
    rm preprod.env
    
    # Deploy API
    ssh -i ec2-key.pem -o StrictHostKeyChecking=no $EC2_USER@$EC2_IP << 'DEPLOY'
set -e

export PATH=$PATH:/usr/local/go/bin

echo "Cloning repository..."
rm -rf /tmp/pgni
cd /tmp
git clone https://github.com/siddam01/pgni.git > /dev/null 2>&1

echo "Building API..."
cd pgni/pgworld-api-master
go mod download > /dev/null 2>&1
go build -o pgworld-api .

if [ ! -f pgworld-api ]; then
    echo "❌ Build failed!"
    exit 1
fi

echo "✅ Build successful"

# Stop existing service
echo "Stopping existing service (if any)..."
sudo systemctl stop pgworld-api 2>/dev/null || true
sleep 2

# Deploy files
echo "Deploying API..."
sudo mkdir -p /opt/pgworld/logs
sudo chown -R ec2-user:ec2-user /opt/pgworld

cp pgworld-api /opt/pgworld/
cp ~/preprod.env /opt/pgworld/.env
chmod 600 /opt/pgworld/.env
chmod +x /opt/pgworld/pgworld-api

# Create systemd service
echo "Configuring systemd service..."
sudo tee /etc/systemd/system/pgworld-api.service > /dev/null << 'SERVICE'
[Unit]
Description=PGNi API Server
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/opt/pgworld
ExecStart=/opt/pgworld/pgworld-api
EnvironmentFile=/opt/pgworld/.env
Restart=always
RestartSec=10
StandardOutput=append:/opt/pgworld/logs/output.log
StandardError=append:/opt/pgworld/logs/error.log

[Install]
WantedBy=multi-user.target
SERVICE

# Start service
echo "Starting PGNi API service..."
sudo systemctl daemon-reload
sudo systemctl enable pgworld-api
sudo systemctl start pgworld-api

# Wait for startup
echo "Waiting for service to start..."
sleep 5

echo "✅ API deployed successfully"
DEPLOY
    
    if [ $? -eq 0 ]; then
        log_success "API deployed to EC2"
    else
        log_error "API deployment failed"
        return 1
    fi
}

################################################################################
# PHASE 5: Database Initialization
################################################################################

initialize_database() {
    log_header "PHASE 5: DATABASE INITIALIZATION"
    
    log "Creating database and schema..."
    
    mysql -h $DB_HOST -P $DB_PORT -u $DB_USER -p$DB_PASS << 'SQL' 2>/dev/null
CREATE DATABASE IF NOT EXISTS pgworld CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE pgworld;

-- Create tables if they don't exist
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(100) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role ENUM('admin', 'pg_owner', 'tenant') NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_email (email),
    INDEX idx_role (role)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS pg_properties (
    id INT AUTO_INCREMENT PRIMARY KEY,
    owner_id INT NOT NULL,
    name VARCHAR(255) NOT NULL,
    address TEXT,
    city VARCHAR(100),
    state VARCHAR(100),
    pincode VARCHAR(20),
    total_rooms INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_owner (owner_id),
    INDEX idx_city (city)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS rooms (
    id INT AUTO_INCREMENT PRIMARY KEY,
    property_id INT NOT NULL,
    room_number VARCHAR(50) NOT NULL,
    room_type VARCHAR(50),
    rent_amount DECIMAL(10,2),
    is_occupied BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (property_id) REFERENCES pg_properties(id) ON DELETE CASCADE,
    INDEX idx_property (property_id),
    INDEX idx_occupied (is_occupied)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS tenants (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    room_id INT,
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    email VARCHAR(255),
    id_proof_type VARCHAR(50),
    id_proof_number VARCHAR(100),
    move_in_date DATE,
    move_out_date DATE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (room_id) REFERENCES rooms(id) ON DELETE SET NULL,
    INDEX idx_user (user_id),
    INDEX idx_room (room_id),
    INDEX idx_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS payments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    tenant_id INT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    payment_date DATE NOT NULL,
    payment_type ENUM('rent', 'deposit', 'maintenance', 'other') DEFAULT 'rent',
    status ENUM('pending', 'completed', 'failed') DEFAULT 'pending',
    transaction_id VARCHAR(255),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE,
    INDEX idx_tenant (tenant_id),
    INDEX idx_date (payment_date),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SELECT 'Database initialized successfully' as Status;
SQL
    
    if [ $? -eq 0 ]; then
        log_success "Database initialized"
    else
        log_error "Database initialization failed"
        return 1
    fi
}

################################################################################
# PHASE 6: Health Checks and Validation
################################################################################

validate_deployment() {
    log_header "PHASE 6: HEALTH CHECKS & VALIDATION"
    
    # Check service status
    log "Checking service status on EC2..."
    SERVICE_STATUS=$(ssh -i ec2-key.pem -o StrictHostKeyChecking=no $EC2_USER@$EC2_IP \
        "sudo systemctl is-active pgworld-api" 2>/dev/null || echo "inactive")
    
    if [ "$SERVICE_STATUS" = "active" ]; then
        log_success "Service is running"
    else
        log_error "Service is not running"
        ssh -i ec2-key.pem $EC2_USER@$EC2_IP "sudo journalctl -u pgworld-api -n 20 --no-pager"
        return 1
    fi
    
    # Check if port is listening
    log "Checking if port $API_PORT is listening..."
    PORT_LISTENING=$(ssh -i ec2-key.pem -o StrictHostKeyChecking=no $EC2_USER@$EC2_IP \
        "sudo netstat -tlnp | grep :$API_PORT | wc -l" 2>/dev/null || echo "0")
    
    if [ "$PORT_LISTENING" -gt 0 ]; then
        log_success "Port $API_PORT is listening"
    else
        log_error "Port $API_PORT is not listening"
        return 1
    fi
    
    # Test internal health check
    log "Testing health endpoint (internal)..."
    INTERNAL_HEALTH=$(ssh -i ec2-key.pem -o StrictHostKeyChecking=no $EC2_USER@$EC2_IP \
        "curl -s http://localhost:$API_PORT/health" 2>/dev/null || echo "failed")
    
    if [[ "$INTERNAL_HEALTH" == *"healthy"* ]]; then
        log_success "Internal health check passed"
    else
        log_error "Internal health check failed: $INTERNAL_HEALTH"
    fi
    
    # Test external health check
    log "Testing health endpoint (external)..."
    EXTERNAL_HEALTH=$(curl -s --connect-timeout 10 http://$EC2_IP:$API_PORT/health 2>/dev/null || echo "failed")
    
    if [[ "$EXTERNAL_HEALTH" == *"healthy"* ]]; then
        log_success "External health check passed: $EXTERNAL_HEALTH"
    else
        log_error "External health check failed: $EXTERNAL_HEALTH"
        log_warning "Waiting 10 seconds and retrying..."
        sleep 10
        EXTERNAL_HEALTH=$(curl -s --connect-timeout 10 http://$EC2_IP:$API_PORT/health 2>/dev/null || echo "failed")
        if [[ "$EXTERNAL_HEALTH" == *"healthy"* ]]; then
            log_success "External health check passed on retry: $EXTERNAL_HEALTH"
        else
            log_error "External health check still failing"
            return 1
        fi
    fi
}

################################################################################
# PHASE 7: API Endpoint Testing
################################################################################

test_api_endpoints() {
    log_header "PHASE 7: API ENDPOINT TESTING"
    
    BASE_URL="http://$EC2_IP:$API_PORT"
    
    # Test health endpoint
    log "Testing /health endpoint..."
    HEALTH_RESPONSE=$(curl -s -w "\n%{http_code}" $BASE_URL/health 2>/dev/null || echo "failed")
    HEALTH_CODE=$(echo "$HEALTH_RESPONSE" | tail -1)
    
    if [ "$HEALTH_CODE" = "200" ]; then
        log_success "GET /health - Status: 200"
    else
        log_error "GET /health - Status: $HEALTH_CODE"
    fi
    
    # Test other common endpoints
    ENDPOINTS=("/api/v1/users" "/api/v1/properties" "/api/v1/rooms" "/api/v1/tenants" "/api/v1/payments")
    
    for endpoint in "${ENDPOINTS[@]}"; do
        log "Testing $endpoint endpoint..."
        RESPONSE_CODE=$(curl -s -o /dev/null -w "%{http_code}" $BASE_URL$endpoint 2>/dev/null || echo "000")
        
        if [ "$RESPONSE_CODE" = "401" ] || [ "$RESPONSE_CODE" = "200" ]; then
            log_success "GET $endpoint - Status: $RESPONSE_CODE (endpoint exists)"
        elif [ "$RESPONSE_CODE" = "404" ]; then
            log_warning "GET $endpoint - Status: 404 (not found)"
        else
            log_warning "GET $endpoint - Status: $RESPONSE_CODE"
        fi
    done
}

################################################################################
# PHASE 8: Generate Reports and Documentation
################################################################################

generate_reports() {
    log_header "PHASE 8: REPORTS & DOCUMENTATION"
    
    log "Generating comprehensive deployment report..."
    
    cat >> "$REPORT_FILE" << EOF

========================================
DEPLOYMENT SUCCESS SUMMARY
========================================

🎉 API Successfully Deployed and Validated!

========================================
ACCESS INFORMATION
========================================

API Base URL: http://$EC2_IP:$API_PORT

Health Check: http://$EC2_IP:$API_PORT/health
  - Test in browser or via curl:
    curl http://$EC2_IP:$API_PORT/health

API Endpoints:
  - Users: http://$EC2_IP:$API_PORT/api/v1/users
  - Properties: http://$EC2_IP:$API_PORT/api/v1/properties
  - Rooms: http://$EC2_IP:$API_PORT/api/v1/rooms
  - Tenants: http://$EC2_IP:$API_PORT/api/v1/tenants
  - Payments: http://$EC2_IP:$API_PORT/api/v1/payments

========================================
INFRASTRUCTURE DETAILS
========================================

EC2 Instance:
  - Public IP: $EC2_IP
  - Region: $REGION
  - User: $EC2_USER

RDS Database:
  - Endpoint: $DB_HOST
  - Database: $DB_NAME
  - Port: $DB_PORT

S3 Bucket:
  - Name: pgni-preprod-698302425856-uploads
  - Region: $REGION

========================================
SERVICE MANAGEMENT
========================================

SSH to EC2:
  ssh -i ec2-key.pem $EC2_USER@$EC2_IP

Service Commands (on EC2):
  sudo systemctl status pgworld-api    # Check status
  sudo systemctl stop pgworld-api      # Stop service
  sudo systemctl start pgworld-api     # Start service
  sudo systemctl restart pgworld-api   # Restart service

View Logs (on EC2):
  sudo journalctl -u pgworld-api -f    # Follow logs
  sudo journalctl -u pgworld-api -n 50 # Last 50 lines
  tail -f /opt/pgworld/logs/output.log # Application logs
  tail -f /opt/pgworld/logs/error.log  # Error logs

========================================
MOBILE APP CONFIGURATION
========================================

📱 Android App Configuration:

1. Update API Base URL in your Flutter/Android apps:

   File: lib/config/api_config.dart (or similar)
   
   class ApiConfig {
     static const String baseUrl = 'http://$EC2_IP:$API_PORT';
     static const String healthCheck = '\${baseUrl}/health';
     static const String apiV1 = '\${baseUrl}/api/v1';
   }

2. Update Android Manifest for HTTP (if not using HTTPS):

   File: android/app/src/main/AndroidManifest.xml
   
   <application
       android:usesCleartextTraffic="true"
       ...>
   </application>
   
   <uses-permission android:name="android.permission.INTERNET" />

3. Build APKs:

   Admin App:
     cd pgworld-master
     flutter clean
     flutter pub get
     flutter build apk --release
     
   Tenant App:
     cd pgworldtenant-master
     flutter clean
     flutter pub get
     flutter build apk --release

4. APK Locations:
   - Admin: pgworld-master/build/app/outputs/flutter-apk/app-release.apk
   - Tenant: pgworldtenant-master/build/app/outputs/flutter-apk/app-release.apk

========================================
USER ROLES & GUIDES
========================================

📚 Complete Documentation Available:

- Getting Started: USER_GUIDES/0_GETTING_STARTED.md
- PG Owner Guide: USER_GUIDES/1_PG_OWNER_GUIDE.md
- Tenant Guide: USER_GUIDES/2_TENANT_GUIDE.md
- Admin Guide: USER_GUIDES/3_ADMIN_GUIDE.md
- Mobile Config: USER_GUIDES/4_MOBILE_APP_CONFIGURATION.md

========================================
CI/CD PIPELINE
========================================

GitHub Actions Pipelines:
  - Main Deploy: .github/workflows/deploy.yml
  - Parallel Validation: .github/workflows/parallel-validation.yml

Pipeline Documentation:
  - Architecture: PIPELINE_ARCHITECTURE.md
  - Best Practices: ENTERPRISE_PIPELINE_GUIDE.md
  - Secrets Setup: GITHUB_SECRETS_SETUP.md

To Enable Auto-Deployment:
  1. Go to: https://github.com/siddam01/pgni/settings/secrets/actions
  2. Add these secrets:
     - PRODUCTION_HOST: $EC2_IP
     - PRODUCTION_SSH_KEY: (from terraform output -raw ssh_private_key)
     - AWS_ACCESS_KEY_ID: (your AWS access key)
     - AWS_SECRET_ACCESS_KEY: (your AWS secret key)
  3. Push to main branch → auto-deploys

========================================
TESTING THE DEPLOYMENT
========================================

1. Browser Test:
   Open: http://$EC2_IP:$API_PORT/health
   Expected: {"status":"healthy","service":"PGWorld API"}

2. Command Line Test:
   curl http://$EC2_IP:$API_PORT/health

3. Mobile App Test:
   - Install APKs on Android devices
   - Launch app
   - Try login/registration
   - All features should work

========================================
TROUBLESHOOTING
========================================

If API is not accessible:

1. Check service status:
   ssh -i ec2-key.pem $EC2_USER@$EC2_IP
   sudo systemctl status pgworld-api

2. Check logs:
   sudo journalctl -u pgworld-api -n 100

3. Check if port is listening:
   sudo netstat -tlnp | grep $API_PORT

4. Test internal connectivity:
   curl http://localhost:$API_PORT/health

5. Check security group (allow port $API_PORT from 0.0.0.0/0)

6. Restart service if needed:
   sudo systemctl restart pgworld-api

========================================
NEXT STEPS
========================================

✅ Phase 1: Infrastructure - COMPLETED
✅ Phase 2: API Deployment - COMPLETED
✅ Phase 3: Database Setup - COMPLETED
✅ Phase 4: Health Validation - COMPLETED

📱 Phase 5: Mobile Apps (DO THIS NOW)
   1. Update API URLs in Flutter apps
   2. Build APKs
   3. Test on devices
   4. Deploy to users

🚀 Phase 6: Production Enhancements (OPTIONAL)
   1. Configure custom domain
   2. Add SSL/TLS certificate
   3. Set up monitoring/alerts
   4. Enable auto-scaling
   5. Configure backups

========================================
SUPPORT & MAINTENANCE
========================================

Regular Maintenance:
  - Monitor logs daily
  - Check disk space weekly
  - Update packages monthly
  - Backup database regularly

Performance Monitoring:
  - API response times
  - Database query performance
  - EC2 CPU/memory usage
  - Error rates

Security:
  - Keep packages updated
  - Review access logs
  - Rotate credentials quarterly
  - Regular security audits

========================================
DEPLOYMENT COMPLETED SUCCESSFULLY! 🎉
========================================

Date: $(date)
Report: $REPORT_FILE

Your PGNi application is now LIVE and ready to use!

EOF
    
    log_success "Comprehensive report generated: $REPORT_FILE"
}

################################################################################
# PHASE 9: Display Summary
################################################################################

display_summary() {
    log_header "DEPLOYMENT COMPLETE!"
    
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}🎉 SUCCESS! API IS LIVE AND ACCESSIBLE${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo -e "${CYAN}📋 Quick Access:${NC}"
    echo ""
    echo -e "  🌐 API URL:"
    echo -e "     ${YELLOW}http://$EC2_IP:$API_PORT${NC}"
    echo ""
    echo -e "  ❤️  Health Check:"
    echo -e "     ${YELLOW}http://$EC2_IP:$API_PORT/health${NC}"
    echo ""
    echo -e "  📱 Mobile Apps:"
    echo -e "     Update API URL to: ${YELLOW}http://$EC2_IP:$API_PORT${NC}"
    echo ""
    echo -e "${CYAN}📄 Full Report:${NC}"
    echo -e "  ${YELLOW}$REPORT_FILE${NC}"
    echo ""
    echo -e "${GREEN}Next Steps:${NC}"
    echo -e "  1. Test in browser: http://$EC2_IP:$API_PORT/health"
    echo -e "  2. Update mobile apps with API URL"
    echo -e "  3. Build and test mobile apps"
    echo -e "  4. Deploy to users"
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo ""
}

################################################################################
# MAIN EXECUTION
################################################################################

main() {
    echo ""
    echo "========================================="
    echo "🚀 PGNI API - COMPLETE DEPLOYMENT"
    echo "========================================="
    echo ""
    echo "Starting deployment at $(date)"
    echo ""
    
    # Initialize report
    echo "PGNI API Deployment & Validation Report" > "$REPORT_FILE"
    echo "Generated: $(date)" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    # Execute all phases
    validate_infrastructure || exit 1
    setup_ssh_key || exit 1
    install_prerequisites || exit 1
    deploy_api || exit 1
    initialize_database || exit 1
    validate_deployment || exit 1
    test_api_endpoints
    generate_reports
    display_summary
    
    log ""
    log "🎉 All phases completed successfully!"
    log "📄 Detailed report: $REPORT_FILE"
    log ""
}

# Run main function
main "$@"

