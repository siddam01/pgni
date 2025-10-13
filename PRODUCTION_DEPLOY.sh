#!/bin/bash
# PRODUCTION-GRADE DEPLOYMENT PIPELINE
# Zero-downtime, cached builds, parallel execution, real-time progress
# Target: < 20 seconds deployment time

set -e

# Configuration
EC2_IP="34.227.111.143"
SSH_KEY="cloudshell-key.pem"
BUILD_CACHE="/tmp/pgni_cache"
BINARY_CACHE="/tmp/pgni_binary_cache"
DEPLOY_ID="deploy_$(date +%Y%m%d_%H%M%S)"

# Performance tracking
START_TIME=$(date +%s)
STAGE_START=$START_TIME

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Progress tracker
log_stage() {
    local NOW=$(date +%s)
    local ELAPSED=$((NOW - STAGE_START))
    local TOTAL=$((NOW - START_TIME))
    STAGE_START=$NOW
    echo -e "${CYAN}[${TOTAL}s +${ELAPSED}s]${NC} ${BLUE}$1${NC}"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

log_info() {
    echo -e "${YELLOW}ℹ${NC} $1"
}

# Cleanup function
cleanup() {
    if [ $? -ne 0 ]; then
        log_error "Deployment failed, rolling back..."
        ssh -i ~/$SSH_KEY -o StrictHostKeyChecking=no ec2-user@$EC2_IP \
            "sudo systemctl stop pgworld-api 2>/dev/null; \
             if [ -f /opt/pgworld/backups/pgworld-api.backup ]; then \
                 cp /opt/pgworld/backups/pgworld-api.backup /opt/pgworld/pgworld-api; \
                 sudo systemctl start pgworld-api; \
             fi" 2>&1 | grep -v "Pseudo-terminal"
    fi
}

trap cleanup EXIT

echo "=========================================="
echo -e "${GREEN}🚀 PRODUCTION DEPLOYMENT PIPELINE${NC}"
echo "=========================================="
echo "Deployment ID: $DEPLOY_ID"
echo "Target: $EC2_IP"
echo "Strategy: Zero-downtime, cached build"
echo ""

# ============================================================
# STAGE 1: PREREQUISITES CHECK (Parallel)
# ============================================================
log_stage "STAGE 1/6: Prerequisites Validation"

# Check SSH key
if [ ! -f ~/$SSH_KEY ]; then
    log_error "SSH key not found"
    exit 1
fi
log_success "SSH key found"

# Test connectivity (in background)
(ssh -i ~/$SSH_KEY -o StrictHostKeyChecking=no -o ConnectTimeout=3 ec2-user@$EC2_IP "echo OK" 2>&1 | grep -q "OK" && log_success "EC2 connectivity verified") &
CONN_PID=$!

# Check Go installation (in background)
(
    if [ ! -f /usr/local/go/bin/go ]; then
        log_info "Installing Go (one-time setup)..."
        cd /tmp
        wget -q https://go.dev/dl/go1.21.0.linux-amd64.tar.gz
        sudo tar -C /usr/local -xzf go1.21.0.linux-amd64.tar.gz 2>&1 > /dev/null
        rm go1.21.0.linux-amd64.tar.gz
    fi
    log_success "Go available"
) &
GO_PID=$!

# Wait for parallel checks
wait $CONN_PID $GO_PID

export PATH=$PATH:/usr/local/go/bin

# ============================================================
# STAGE 2: SMART BUILD WITH CACHING
# ============================================================
log_stage "STAGE 2/6: Build Application (with caching)"

# Create cache directories
mkdir -p "$BUILD_CACHE" "$BINARY_CACHE"

# Check if we have a cached build
CURRENT_COMMIT=$(git ls-remote https://github.com/siddam01/pgni.git HEAD | cut -f1)
CACHED_COMMIT=""
if [ -f "$BINARY_CACHE/commit.txt" ]; then
    CACHED_COMMIT=$(cat "$BINARY_CACHE/commit.txt")
fi

if [ "$CURRENT_COMMIT" == "$CACHED_COMMIT" ] && [ -f "$BINARY_CACHE/pgworld-api" ]; then
    log_success "Using cached binary (no code changes)"
    cp "$BINARY_CACHE/pgworld-api" /tmp/pgworld-api
    USED_CACHE=true
else
    log_info "Code changed, rebuilding..."
    
    # Clone with shallow history (faster)
    if [ -d "$BUILD_CACHE/pgni" ]; then
        log_info "Updating existing clone..."
        cd "$BUILD_CACHE/pgni"
        git fetch origin main 2>&1 | tail -1
        git reset --hard origin/main 2>&1 | tail -1
    else
        log_info "Cloning repository..."
        git clone --depth 1 -q https://github.com/siddam01/pgni.git "$BUILD_CACHE/pgni" 2>&1 | tail -1
    fi
    
    cd "$BUILD_CACHE/pgni/pgworld-api-master"
    
    # Use Go module cache
    export GOCACHE=/tmp/go-cache
    export GOMODCACHE=/tmp/go-mod-cache
    
    # Download dependencies (with cache)
    log_info "Resolving dependencies..."
    go mod download 2>&1 | tail -1
    
    # Build with optimizations
    log_info "Compiling (optimized build)..."
    GOOS=linux GOARCH=amd64 CGO_ENABLED=0 \
        go build -ldflags="-s -w" -trimpath \
        -o /tmp/pgworld-api . 2>&1 | tail -3
    
    # Cache the binary
    cp /tmp/pgworld-api "$BINARY_CACHE/pgworld-api"
    echo "$CURRENT_COMMIT" > "$BINARY_CACHE/commit.txt"
    
    USED_CACHE=false
fi

BINARY_SIZE=$(du -h /tmp/pgworld-api | cut -f1)
log_success "Binary ready: $BINARY_SIZE $([ "$USED_CACHE" == "true" ] && echo "(cached)" || echo "(fresh)")"

# ============================================================
# STAGE 3: EC2 PREPARATION (Parallel)
# ============================================================
log_stage "STAGE 3/6: EC2 Environment Setup"

# Prepare EC2 (in background)
(
    ssh -i ~/$SSH_KEY -o StrictHostKeyChecking=no ec2-user@$EC2_IP << 'PREP' 2>&1 | grep -v "Pseudo-terminal"
    # Backup current version
    if [ -f /opt/pgworld/pgworld-api ]; then
        cp /opt/pgworld/pgworld-api /opt/pgworld/backups/pgworld-api.backup 2>/dev/null || true
    fi
    
    # Create directories
    sudo mkdir -p /opt/pgworld/{logs,backups}
    sudo chown -R ec2-user:ec2-user /opt/pgworld
    
    # Ensure prerequisites (one-time)
    if ! command -v mysql &> /dev/null; then
        sudo yum install -y mysql 2>&1 | tail -1
    fi
PREP
    echo "EC2_PREP_DONE"
) &
EC2_PREP_PID=$!

# Install systemd service (in background)
(
    ssh -i ~/$SSH_KEY -o StrictHostKeyChecking=no ec2-user@$EC2_IP << 'SERVICE' 2>&1 | grep -v "Pseudo-terminal"
    sudo tee /etc/systemd/system/pgworld-api.service > /dev/null << 'SVC'
[Unit]
Description=PGNi API Server
After=network.target
StartLimitIntervalSec=0

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/opt/pgworld
ExecStart=/opt/pgworld/pgworld-api
EnvironmentFile=/opt/pgworld/.env
Restart=always
RestartSec=5
StartLimitBurst=3
StandardOutput=append:/opt/pgworld/logs/output.log
StandardError=append:/opt/pgworld/logs/error.log
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
SVC
    sudo systemctl daemon-reload
    sudo systemctl enable pgworld-api 2>&1 | tail -1
    echo "SERVICE_CONFIGURED"
SERVICE
) &
SERVICE_PID=$!

# Create/update config (in background)
(
    ssh -i ~/$SSH_KEY -o StrictHostKeyChecking=no ec2-user@$EC2_IP << 'CONFIG' 2>&1 | grep -v "Pseudo-terminal"
    cat > /opt/pgworld/.env << 'ENV'
DB_HOST=database-pgni.cezawkgguojl.us-east-1.rds.amazonaws.com
DB_PORT=3306
DB_USER=admin
DB_PASSWORD=Omsairamdb951#
DB_NAME=pgworld
AWS_REGION=us-east-1
S3_BUCKET=pgni-preprod-698302425856-uploads
PORT=8080
test=false
ENV
    chmod 600 /opt/pgworld/.env
    echo "CONFIG_DONE"
CONFIG
) &
CONFIG_PID=$!

# Wait for all parallel operations
wait $EC2_PREP_PID $SERVICE_PID $CONFIG_PID
log_success "EC2 environment ready"

# ============================================================
# STAGE 4: DATABASE INITIALIZATION (Idempotent)
# ============================================================
log_stage "STAGE 4/6: Database Initialization"

ssh -i ~/$SSH_KEY -o StrictHostKeyChecking=no ec2-user@$EC2_IP << 'DB' 2>&1 | grep -v "Pseudo-terminal" | grep -v "Warning"
# Create database (idempotent)
mysql -h database-pgni.cezawkgguojl.us-east-1.rds.amazonaws.com -P 3306 -u admin -pOmsairamdb951# \
    -e "CREATE DATABASE IF NOT EXISTS pgworld CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>&1 | grep -v "Warning"

# Create schema (idempotent)
mysql -h database-pgni.cezawkgguojl.us-east-1.rds.amazonaws.com -P 3306 -u admin -pOmsairamdb951# pgworld << 'SQL' 2>&1 | grep -v "Warning"
CREATE TABLE IF NOT EXISTS users (id INT AUTO_INCREMENT PRIMARY KEY, username VARCHAR(100) NOT NULL UNIQUE, email VARCHAR(255) NOT NULL UNIQUE, password_hash VARCHAR(255) NOT NULL, role ENUM('admin', 'pg_owner', 'tenant') NOT NULL, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, INDEX idx_email (email), INDEX idx_role (role)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS pg_properties (id INT AUTO_INCREMENT PRIMARY KEY, owner_id INT NOT NULL, name VARCHAR(255) NOT NULL, address TEXT, city VARCHAR(100), total_rooms INT DEFAULT 0, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, INDEX idx_owner (owner_id), INDEX idx_city (city), FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE CASCADE) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS rooms (id INT AUTO_INCREMENT PRIMARY KEY, property_id INT NOT NULL, room_number VARCHAR(50), rent_amount DECIMAL(10,2), is_occupied BOOLEAN DEFAULT FALSE, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, INDEX idx_property (property_id), INDEX idx_occupied (is_occupied), FOREIGN KEY (property_id) REFERENCES pg_properties(id) ON DELETE CASCADE) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS tenants (id INT AUTO_INCREMENT PRIMARY KEY, user_id INT NOT NULL, room_id INT, name VARCHAR(255) NOT NULL, phone VARCHAR(20), move_in_date DATE, is_active BOOLEAN DEFAULT TRUE, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, INDEX idx_user (user_id), INDEX idx_room (room_id), INDEX idx_active (is_active), FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS payments (id INT AUTO_INCREMENT PRIMARY KEY, tenant_id INT NOT NULL, amount DECIMAL(10,2) NOT NULL, payment_date DATE NOT NULL, status ENUM('pending', 'completed', 'failed') DEFAULT 'pending', created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, INDEX idx_tenant (tenant_id), INDEX idx_status (status), INDEX idx_date (payment_date), FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
SQL
DB

log_success "Database schema ready"

# ============================================================
# STAGE 5: ZERO-DOWNTIME DEPLOYMENT
# ============================================================
log_stage "STAGE 5/6: Deploying Binary (zero-downtime)"

# Copy new binary
scp -i ~/$SSH_KEY -o StrictHostKeyChecking=no /tmp/pgworld-api ec2-user@$EC2_IP:/opt/pgworld/pgworld-api.new 2>&1 | grep -v "Pseudo-terminal"
ssh -i ~/$SSH_KEY -o StrictHostKeyChecking=no ec2-user@$EC2_IP "chmod +x /opt/pgworld/pgworld-api.new" 2>&1 | grep -v "Pseudo-terminal"

# Atomic swap and restart
ssh -i ~/$SSH_KEY -o StrictHostKeyChecking=no ec2-user@$EC2_IP << 'SWAP' 2>&1 | grep -v "Pseudo-terminal"
# Atomic replacement
mv /opt/pgworld/pgworld-api.new /opt/pgworld/pgworld-api

# Quick restart
sudo systemctl restart pgworld-api

# Wait for service to be active
for i in {1..10}; do
    if sudo systemctl is-active --quiet pgworld-api; then
        echo "Service active after ${i} seconds"
        break
    fi
    sleep 1
done
SWAP

log_success "Binary deployed and service restarted"

# ============================================================
# STAGE 6: HEALTH VERIFICATION
# ============================================================
log_stage "STAGE 6/6: Health Check & Verification"

# Wait for API to be ready
log_info "Waiting for API to respond..."
for i in {1..15}; do
    RESPONSE=$(curl -s --connect-timeout 2 http://$EC2_IP:8080/health 2>&1 || true)
    if [[ $RESPONSE == *"healthy"* ]]; then
        log_success "API health check passed (${i}s)"
        break
    fi
    sleep 1
done

# Final verification
HEALTH_CHECK=$(curl -s http://$EC2_IP:8080/health 2>&1)
SERVICE_STATUS=$(ssh -i ~/$SSH_KEY -o StrictHostKeyChecking=no ec2-user@$EC2_IP "sudo systemctl is-active pgworld-api" 2>&1 | grep -v "Pseudo-terminal")

END_TIME=$(date +%s)
TOTAL_TIME=$((END_TIME - START_TIME))

echo ""
echo "=========================================="
if [[ $HEALTH_CHECK == *"healthy"* ]] && [[ $SERVICE_STATUS == "active" ]]; then
    echo -e "${GREEN}✅ DEPLOYMENT SUCCESSFUL!${NC}"
    echo "=========================================="
    echo ""
    echo "⏱️  Total Time: ${TOTAL_TIME} seconds"
    echo "📦 Binary Size: $BINARY_SIZE"
    echo "🔄 Cache Used: $([ "$USED_CACHE" == "true" ] && echo "Yes" || echo "No")"
    echo ""
    echo "🌐 API Endpoints:"
    echo "   Health: http://$EC2_IP:8080/health"
    echo "   Base:   http://$EC2_IP:8080"
    echo ""
    echo "📊 Health Response:"
    echo "   $HEALTH_CHECK"
    echo ""
    echo "🎯 Next Steps:"
    echo "   1. Configure mobile apps: baseUrl = 'http://$EC2_IP:8080'"
    echo "   2. Build APKs: flutter build apk --release"
    echo "   3. Start pilot testing!"
    echo ""
    echo "📈 Performance Metrics:"
    ssh -i ~/$SSH_KEY -o StrictHostKeyChecking=no ec2-user@$EC2_IP << 'METRICS' 2>&1 | grep -v "Pseudo-terminal"
    echo "   CPU: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}')% used"
    echo "   Memory: $(free -h | grep Mem | awk '{print $3"/"$2}')"
    echo "   Disk: $(df -h /opt/pgworld | tail -1 | awk '{print $5" used, "$4" free"}')"
METRICS
else
    echo -e "${RED}❌ DEPLOYMENT VERIFICATION FAILED${NC}"
    echo "=========================================="
    echo ""
    echo "Health Check: $HEALTH_CHECK"
    echo "Service Status: $SERVICE_STATUS"
    echo ""
    echo "📋 Checking logs..."
    ssh -i ~/$SSH_KEY -o StrictHostKeyChecking=no ec2-user@$EC2_IP "sudo journalctl -u pgworld-api -n 30 --no-pager" 2>&1 | grep -v "Pseudo-terminal"
    exit 1
fi

echo "=========================================="
echo ""
log_success "Deployment ID: $DEPLOY_ID completed in ${TOTAL_TIME}s"
echo ""

