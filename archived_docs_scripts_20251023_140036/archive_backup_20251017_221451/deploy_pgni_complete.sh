#!/bin/bash
#===============================================================================
# PGNI Flutter Web - Complete Infrastructure-Aware Deployment
# Senior DevOps & Flutter Build Engineer Edition
#===============================================================================
set -euo pipefail

# Configuration
readonly SCRIPT_VERSION="2.0.0"
readonly PROJECT_ROOT="/home/ec2-user/pgni"
readonly LOG_DIR="/home/ec2-user/pgni/logs"
readonly DEPLOYMENT_ID="deploy_$(date +%Y%m%d_%H%M%S)"
readonly LOG_FILE="$LOG_DIR/${DEPLOYMENT_ID}.log"

# Performance thresholds
readonly MIN_RAM_MB=4096
readonly RECOMMENDED_RAM_MB=8192
readonly MIN_VCPUS=2
readonly MIN_DISK_GB=5
readonly MIN_SWAP_MB=4096
readonly BUILD_TIME_WARNING=600  # 10 minutes

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly MAGENTA='\033[0;35m'
readonly NC='\033[0m'

# Logging
mkdir -p "$LOG_DIR"
exec > >(tee -a "$LOG_FILE") 2>&1

#===============================================================================
# HELPER FUNCTIONS
#===============================================================================

log() { echo -e "${GREEN}[$(date +'%H:%M:%S')]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }
info() { echo -e "${CYAN}[INFO]${NC} $*"; }
section() { echo -e "\n${BLUE}═══════════════════════════════════════════════════════${NC}\n${BLUE}$*${NC}\n${BLUE}═══════════════════════════════════════════════════════${NC}\n"; }
subsection() { echo -e "\n${MAGENTA}▶ $*${NC}\n"; }

# Track metrics
INFRA_SCORE=0
NEEDS_UPGRADE=false
BUILD_START_TIME=0
BUILD_END_TIME=0

cleanup() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        error "Deployment failed with exit code: $exit_code"
        error "Check log: $LOG_FILE"
    fi
    exit $exit_code
}
trap cleanup EXIT INT TERM

#===============================================================================
# PHASE 1: SYSTEM HEALTH & INFRASTRUCTURE VALIDATION
#===============================================================================

validate_infrastructure() {
    section "PHASE 1: INFRASTRUCTURE VALIDATION & HEALTH CHECK"
    
    subsection "1.1 System Information"
    
    # CPU Info
    log "CPU Information:"
    CPU_MODEL=$(lscpu | grep 'Model name' | cut -d':' -f2 | xargs)
    CPU_CORES=$(nproc)
    log "  Model: $CPU_MODEL"
    log "  vCPUs: $CPU_CORES"
    
    if [ "$CPU_CORES" -ge "$MIN_VCPUS" ]; then
        log "  ✓ CPU cores sufficient ($CPU_CORES ≥ $MIN_VCPUS)"
        ((INFRA_SCORE+=20))
    else
        warn "  ⚠ CPU cores below minimum ($CPU_CORES < $MIN_VCPUS)"
        NEEDS_UPGRADE=true
    fi
    
    # Memory Info
    subsection "1.2 Memory Configuration"
    TOTAL_RAM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    TOTAL_RAM_MB=$((TOTAL_RAM_KB / 1024))
    AVAILABLE_RAM_KB=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
    AVAILABLE_RAM_MB=$((AVAILABLE_RAM_KB / 1024))
    
    log "Memory Status:"
    log "  Total: ${TOTAL_RAM_MB}MB"
    log "  Available: ${AVAILABLE_RAM_MB}MB"
    
    if [ "$TOTAL_RAM_MB" -ge "$RECOMMENDED_RAM_MB" ]; then
        log "  ✓ RAM optimal ($TOTAL_RAM_MB MB ≥ $RECOMMENDED_RAM_MB MB)"
        ((INFRA_SCORE+=30))
    elif [ "$TOTAL_RAM_MB" -ge "$MIN_RAM_MB" ]; then
        warn "  ⚠ RAM adequate but below recommended ($TOTAL_RAM_MB MB)"
        ((INFRA_SCORE+=15))
    else
        warn "  ✗ RAM below minimum ($TOTAL_RAM_MB MB < $MIN_RAM_MB MB)"
        NEEDS_UPGRADE=true
    fi
    
    # Swap Configuration
    subsection "1.3 Swap Configuration"
    SWAP_TOTAL_KB=$(grep SwapTotal /proc/meminfo | awk '{print $2}')
    SWAP_TOTAL_MB=$((SWAP_TOTAL_KB / 1024))
    
    log "Swap Status:"
    log "  Total: ${SWAP_TOTAL_MB}MB"
    
    if [ "$SWAP_TOTAL_MB" -ge "$MIN_SWAP_MB" ]; then
        log "  ✓ Swap configured ($SWAP_TOTAL_MB MB ≥ $MIN_SWAP_MB MB)"
        ((INFRA_SCORE+=15))
    elif [ "$SWAP_TOTAL_MB" -gt 0 ]; then
        warn "  ⚠ Swap below recommended ($SWAP_TOTAL_MB MB)"
        ((INFRA_SCORE+=5))
    else
        warn "  ✗ No swap configured - will create"
        create_swap
    fi
    
    # Disk Space
    subsection "1.4 Disk Space"
    DISK_AVAIL_GB=$(df -BG /home/ec2-user | awk 'NR==2 {print $4}' | sed 's/G//')
    DISK_USED_PERCENT=$(df -h /home/ec2-user | awk 'NR==2 {print $5}' | sed 's/%//')
    
    log "Disk Status:"
    log "  Available: ${DISK_AVAIL_GB}GB"
    log "  Used: ${DISK_USED_PERCENT}%"
    
    if [ "$DISK_AVAIL_GB" -ge "$MIN_DISK_GB" ]; then
        log "  ✓ Disk space sufficient ($DISK_AVAIL_GB GB ≥ $MIN_DISK_GB GB)"
        ((INFRA_SCORE+=15))
    else
        error "  ✗ Insufficient disk space ($DISK_AVAIL_GB GB < $MIN_DISK_GB GB)"
        exit 1
    fi
    
    # System Info
    subsection "1.5 System Details"
    log "Operating System:"
    uname -a
    
    # EC2 Instance Type Detection
    subsection "1.6 EC2 Instance Type"
    if command -v ec2-metadata &> /dev/null; then
        INSTANCE_TYPE=$(ec2-metadata --instance-type | cut -d' ' -f2)
        log "Current Instance: $INSTANCE_TYPE"
        
        # Check if instance needs upgrade
        case "$INSTANCE_TYPE" in
            t2.micro|t3.micro|t3a.micro)
                warn "⚠ Instance type too small for optimal builds"
                warn "  Recommended: t3.medium or larger"
                NEEDS_UPGRADE=true
                ;;
            t2.small|t3.small|t3a.small)
                warn "⚠ Instance adequate but not optimal"
                warn "  Recommended: t3.large for faster builds"
                ((INFRA_SCORE+=10))
                ;;
            t3.medium|t3a.medium)
                log "✓ Instance type acceptable for builds"
                ((INFRA_SCORE+=15))
                ;;
            t3.large|t3a.large|t3.xlarge|t3a.xlarge)
                log "✓ Instance type optimal for builds"
                ((INFRA_SCORE+=20))
                ;;
            *)
                info "Instance type: $INSTANCE_TYPE"
                ((INFRA_SCORE+=10))
                ;;
        esac
    else
        info "Not running on EC2 or ec2-metadata not available"
    fi
    
    # Infrastructure Score
    section "INFRASTRUCTURE HEALTH SCORE"
    log "Score: ${INFRA_SCORE}/100"
    
    if [ "$INFRA_SCORE" -ge 80 ]; then
        log "✓ Infrastructure: EXCELLENT"
    elif [ "$INFRA_SCORE" -ge 60 ]; then
        warn "⚠ Infrastructure: GOOD (minor improvements recommended)"
    elif [ "$INFRA_SCORE" -ge 40 ]; then
        warn "⚠ Infrastructure: ADEQUATE (upgrades recommended)"
    else
        error "✗ Infrastructure: POOR (upgrades required)"
    fi
    
    if [ "$NEEDS_UPGRADE" = true ]; then
        provide_upgrade_recommendations
    fi
}

create_swap() {
    log "Creating 4GB swap file..."
    
    if [ -f /swapfile ]; then
        warn "Swap file already exists, checking size..."
        CURRENT_SWAP=$(du -h /swapfile | cut -f1)
        log "Current swap file: $CURRENT_SWAP"
        return 0
    fi
    
    log "Allocating swap space (this may take 1-2 minutes)..."
    if sudo fallocate -l 4G /swapfile 2>/dev/null; then
        sudo chmod 600 /swapfile
        sudo mkswap /swapfile
        sudo swapon /swapfile
        
        # Make permanent
        if ! grep -q '/swapfile' /etc/fstab; then
            echo '/swapfile swap swap defaults 0 0' | sudo tee -a /etc/fstab
        fi
        
        log "✓ Swap created and activated"
        ((INFRA_SCORE+=10))
    else
        warn "Failed to create swap with fallocate, trying dd..."
        sudo dd if=/dev/zero of=/swapfile bs=1M count=4096 status=progress
        sudo chmod 600 /swapfile
        sudo mkswap /swapfile
        sudo swapon /swapfile
        echo '/swapfile swap swap defaults 0 0' | sudo tee -a /etc/fstab
        log "✓ Swap created via dd"
        ((INFRA_SCORE+=10))
    fi
}

provide_upgrade_recommendations() {
    section "INFRASTRUCTURE UPGRADE RECOMMENDATIONS"
    
    warn "Current infrastructure is suboptimal for Flutter web builds."
    warn ""
    warn "Recommended Actions:"
    
    if [ "$TOTAL_RAM_MB" -lt "$MIN_RAM_MB" ]; then
        warn "1. Upgrade EC2 Instance for More RAM"
        warn "   Current: ${TOTAL_RAM_MB}MB"
        warn "   Recommended: t3.large (8GB) or t3.xlarge (16GB)"
        warn ""
        warn "   AWS CLI Command:"
        warn "   aws ec2 modify-instance-attribute \\"
        warn "     --instance-id \$(ec2-metadata --instance-id | cut -d' ' -f2) \\"
        warn "     --instance-type t3.large"
    fi
    
    if [ "$CPU_CORES" -lt "$MIN_VCPUS" ]; then
        warn "2. Upgrade vCPUs"
        warn "   Current: ${CPU_CORES} vCPUs"
        warn "   Recommended: 2+ vCPUs (t3.medium or larger)"
    fi
    
    warn ""
    warn "Cost Optimization Tip:"
    warn "  - Use t3.large ONLY during builds (scale down after)"
    warn "  - Or use AWS Lambda/Fargate for builds (pay per second)"
    warn ""
    
    read -p "Continue with current infrastructure? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        error "Deployment cancelled by user"
        exit 1
    fi
}

#===============================================================================
# PHASE 2: SOFTWARE STACK VALIDATION
#===============================================================================

validate_software_stack() {
    section "PHASE 2: SOFTWARE STACK VALIDATION"
    
    subsection "2.1 Flutter SDK"
    if ! command -v flutter &> /dev/null; then
        error "Flutter SDK not found!"
        error "Install Flutter: https://docs.flutter.dev/get-started/install/linux"
        exit 1
    fi
    
    FLUTTER_VERSION=$(flutter --version | grep "Flutter" | awk '{print $2}')
    DART_VERSION=$(flutter --version | grep "Dart" | awk '{print $4}')
    
    log "Flutter: $FLUTTER_VERSION"
    log "Dart: $DART_VERSION"
    
    # Check Flutter version
    FLUTTER_MAJOR=$(echo "$FLUTTER_VERSION" | cut -d'.' -f1)
    FLUTTER_MINOR=$(echo "$FLUTTER_VERSION" | cut -d'.' -f2)
    
    if [ "$FLUTTER_MAJOR" -ge 3 ] && [ "$FLUTTER_MINOR" -ge 24 ]; then
        log "✓ Flutter version meets requirements (≥3.24.x)"
    else
        warn "⚠ Flutter version below recommended (3.24.x)"
        warn "  Upgrading Flutter..."
        flutter upgrade
    fi
    
    # Check Dart version
    DART_MAJOR=$(echo "$DART_VERSION" | cut -d'.' -f1)
    DART_MINOR=$(echo "$DART_VERSION" | cut -d'.' -f2)
    
    if [ "$DART_MAJOR" -ge 3 ] && [ "$DART_MINOR" -ge 4 ]; then
        log "✓ Dart version meets requirements (≥3.4.x)"
    else
        warn "⚠ Dart version below recommended (3.4.x)"
        info "  Dart is bundled with Flutter, upgrade complete"
    fi
    
    # Flutter Doctor
    subsection "2.2 Flutter Doctor"
    log "Running diagnostics..."
    flutter doctor -v || warn "Some checks failed (may be non-critical)"
    
    subsection "2.3 Nginx"
    if ! command -v nginx &> /dev/null; then
        warn "Nginx not found, installing..."
        sudo yum install -y nginx || sudo apt-get install -y nginx
    fi
    
    NGINX_VERSION=$(nginx -v 2>&1 | cut -d'/' -f2)
    log "✓ Nginx: $NGINX_VERSION"
    
    subsection "2.4 AWS CLI"
    if command -v aws &> /dev/null; then
        AWS_VERSION=$(aws --version | cut -d' ' -f1 | cut -d'/' -f2)
        log "✓ AWS CLI: $AWS_VERSION"
        
        # Check AWS credentials
        if aws sts get-caller-identity &> /dev/null; then
            AWS_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
            log "✓ AWS Credentials: Valid (Account: $AWS_ACCOUNT)"
        else
            warn "⚠ AWS credentials not configured or invalid"
        fi
    else
        info "AWS CLI not installed (optional)"
    fi
    
    subsection "2.5 Node.js (Optional)"
    if command -v node &> /dev/null; then
        NODE_VERSION=$(node -v | sed 's/v//')
        log "Node.js: $NODE_VERSION"
        
        NODE_MAJOR=$(echo "$NODE_VERSION" | cut -d'.' -f1)
        if [ "$NODE_MAJOR" -ge 18 ]; then
            log "✓ Node.js version adequate (≥18)"
        else
            warn "⚠ Node.js version below recommended (≥18)"
        fi
    else
        info "Node.js not installed (not required for Flutter web)"
    fi
}

#===============================================================================
# PHASE 3: INTELLIGENT BUILD PROCESS
#===============================================================================

prepare_environment() {
    section "PHASE 3: BUILD ENVIRONMENT PREPARATION"
    
    subsection "3.1 Environment Variables"
    export PUB_CACHE=/home/ec2-user/.pub-cache
    export FLUTTER_ROOT=/home/ec2-user/flutter
    
    log "✓ PUB_CACHE: $PUB_CACHE"
    log "✓ FLUTTER_ROOT: $FLUTTER_ROOT"
    
    # Set memory limits based on available RAM
    if [ "$AVAILABLE_RAM_MB" -ge 8000 ]; then
        export DART_VM_OPTIONS="--old_gen_heap_size=3072"
        log "✓ Dart heap size: 3GB (optimal)"
    elif [ "$AVAILABLE_RAM_MB" -ge 4000 ]; then
        export DART_VM_OPTIONS="--old_gen_heap_size=2048"
        log "✓ Dart heap size: 2GB (standard)"
    else
        export DART_VM_OPTIONS="--old_gen_heap_size=1536"
        warn "⚠ Dart heap size: 1.5GB (conservative)"
    fi
    
    subsection "3.2 Project Directories"
    cd "$PROJECT_ROOT" || exit 1
    log "✓ Working directory: $PROJECT_ROOT"
    
    subsection "3.3 Git Status"
    if [ -d ".git" ]; then
        log "Checking for updates..."
        git fetch origin main --quiet 2>/dev/null || true
        
        if [ -n "$(git status --porcelain)" ]; then
            warn "⚠ Uncommitted changes detected"
            git status --short
        fi
        
        LOCAL=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
        log "Current commit: ${LOCAL:0:8}"
    fi
}

build_flutter_app() {
    local APP_NAME=$1
    local APP_PATH=$2
    
    section "BUILDING: $APP_NAME"
    
    cd "$APP_PATH" || exit 1
    
    subsection "Dependencies"
    
    # Check if dependencies changed
    CURRENT_MD5=$(md5sum pubspec.yaml | awk '{print $1}')
    CACHE_FILE=".pubspec.md5.cache"
    
    if [ -f "$CACHE_FILE" ]; then
        CACHED_MD5=$(cat "$CACHE_FILE")
        if [ "$CURRENT_MD5" = "$CACHED_MD5" ]; then
            log "✓ Dependencies unchanged, using cache"
            flutter pub get --offline 2>/dev/null || flutter pub get
        else
            log "Dependencies changed, full update"
            flutter clean
            rm -rf .dart_tool build
            flutter pub get
            echo "$CURRENT_MD5" > "$CACHE_FILE"
        fi
    else
        log "First build, fetching dependencies"
        flutter pub get
        echo "$CURRENT_MD5" > "$CACHE_FILE"
    fi
    
    subsection "Configuration"
    
    # Update config.dart
    mkdir -p lib/utils
    cat > lib/utils/config.dart << EOF
class Config {
  static const String URL = "34.227.111.143:8080";
  static const String BASE_URL = "http://34.227.111.143:8080";
  static const String APP_VERSION = "2.0.0";
  static const String BUILD_ID = "${DEPLOYMENT_ID}";
  static const String BUILD_DATE = "$(date -Iseconds)";
}
EOF
    log "✓ Configuration updated"
    
    subsection "Compilation"
    
    # Determine optimal build flags
    # Note: Flutter 3.19+ removed --web-renderer flag (auto-detects now)
    # Note: Flutter 3.35+ auto-detects wasm vs JS (no flag needed)
    
    if [ "$TOTAL_RAM_MB" -ge 8000 ]; then
        BUILD_FLAGS="--release --no-source-maps --dart-define=dart.vm.product=true"
        log "Build mode: Optimal (full optimization)"
    elif [ "$TOTAL_RAM_MB" -ge 4000 ]; then
        BUILD_FLAGS="--release --no-source-maps --no-tree-shake-icons --dart-define=dart.vm.product=true"
        log "Build mode: Standard (with icon preservation)"
    else
        BUILD_FLAGS="--release --no-source-maps --no-tree-shake-icons --dart-define=dart.vm.product=true"
        log "Build mode: Conservative (memory-safe)"
    fi
    
    log "Build flags: $BUILD_FLAGS"
    
    # Build with timing
    local build_start=$(date +%s)
    
    log "Compiling (this may take 5-10 minutes)..."
    
    if flutter build web $BUILD_FLAGS --verbose 2>&1 | tee /tmp/${APP_NAME}_build.log; then
        local build_end=$(date +%s)
        local build_time=$((build_end - build_start))
        
        log "✓ Build completed in ${build_time}s"
        
        # Check build time
        if [ "$build_time" -gt "$BUILD_TIME_WARNING" ]; then
            warn "⚠ Build time exceeded 10 minutes ($build_time s)"
            warn "  Consider upgrading instance or enabling more caching"
        fi
        
        # Verify output
        if [ ! -d "build/web" ] || [ ! -f "build/web/index.html" ]; then
            error "Build output missing!"
            exit 1
        fi
        
        # Calculate size
        local file_count=$(find build/web -type f | wc -l)
        local total_size=$(du -sh build/web | cut -f1)
        local size_mb=$(du -sm build/web | cut -f1)
        
        log "Build artifacts:"
        log "  Files: $file_count"
        log "  Size: $total_size"
        
        if [ "$size_mb" -gt 10 ]; then
            warn "⚠ Bundle size is large (${size_mb}MB)"
            warn "  Consider optimizing assets or using CDN"
        fi
        
        # Store metrics
        echo "$build_time" > ".build_time.log"
        echo "$size_mb" > ".build_size.log"
        
        return 0
    else
        error "Build failed!"
        error "Check log: /tmp/${APP_NAME}_build.log"
        tail -50 /tmp/${APP_NAME}_build.log
        exit 1
    fi
}

#===============================================================================
# PHASE 4: DEPLOYMENT
#===============================================================================

deploy_to_nginx() {
    section "PHASE 4: DEPLOYMENT TO NGINX"
    
    subsection "4.1 Pre-Deployment Backup"
    
    if [ -d "/usr/share/nginx/html/admin" ]; then
        local backup_file="/home/ec2-user/backups/admin_$(date +%Y%m%d_%H%M%S).tar.gz"
        sudo tar -czf "$backup_file" -C /usr/share/nginx/html admin 2>/dev/null || true
        log "✓ Admin backup: $(basename $backup_file)"
    fi
    
    if [ -d "/usr/share/nginx/html/tenant" ]; then
        local backup_file="/home/ec2-user/backups/tenant_$(date +%Y%m%d_%H%M%S).tar.gz"
        sudo tar -czf "$backup_file" -C /usr/share/nginx/html tenant 2>/dev/null || true
        log "✓ Tenant backup: $(basename $backup_file)"
    fi
    
    subsection "4.2 Deploy Applications"
    
    # Deploy Admin
    log "Deploying Admin app..."
    sudo rm -rf /usr/share/nginx/html/admin
    sudo mkdir -p /usr/share/nginx/html/admin
    sudo cp -r "$PROJECT_ROOT/pgworld-master/build/web/"* /usr/share/nginx/html/admin/
    
    # Deploy Tenant
    log "Deploying Tenant app..."
    sudo rm -rf /usr/share/nginx/html/tenant
    sudo mkdir -p /usr/share/nginx/html/tenant
    sudo cp -r "$PROJECT_ROOT/pgworldtenant-master/build/web/"* /usr/share/nginx/html/tenant/
    
    # Set permissions
    sudo chown -R nginx:nginx /usr/share/nginx/html 2>/dev/null || \
        sudo chown -R www-data:www-data /usr/share/nginx/html
    sudo chmod -R 755 /usr/share/nginx/html
    
    log "✓ Files deployed"
    
    subsection "4.3 Nginx Configuration"
    
    # Create optimized Nginx config
    cat > /tmp/pgni_nginx.conf << 'NGINXEOF'
server {
    listen 80 default_server;
    server_name _;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml application/javascript application/json application/xml+rss text/javascript;
    gzip_comp_level 6;
    
    # Root redirect
    location = / {
        return 301 /admin/;
    }
    
    # Admin app
    location /admin/ {
        alias /usr/share/nginx/html/admin/;
        index index.html;
        try_files $uri $uri/ /admin/index.html;
        
        # Cache static assets aggressively
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
            access_log off;
        }
        
        # Don't cache HTML
        location ~* \.html$ {
            add_header Cache-Control "no-cache, no-store, must-revalidate";
            add_header Pragma "no-cache";
            add_header Expires "0";
        }
    }
    
    # Tenant app
    location /tenant/ {
        alias /usr/share/nginx/html/tenant/;
        index index.html;
        try_files $uri $uri/ /tenant/index.html;
        
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
            access_log off;
        }
        
        location ~* \.html$ {
            add_header Cache-Control "no-cache, no-store, must-revalidate";
            add_header Pragma "no-cache";
            add_header Expires "0";
        }
    }
    
    # API proxy (if needed)
    location /api/ {
        proxy_pass http://localhost:8080/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
NGINXEOF
    
    # Move config to Nginx directory
    sudo mv /tmp/pgni_nginx.conf /etc/nginx/conf.d/pgni.conf
    
    # Remove default config
    sudo rm -f /etc/nginx/conf.d/default.conf
    sudo rm -f /etc/nginx/sites-enabled/default
    
    # Test configuration
    log "Testing Nginx configuration..."
    if sudo nginx -t; then
        log "✓ Nginx configuration valid"
    else
        error "Nginx configuration test failed!"
        exit 1
    fi
    
    subsection "4.4 Service Restart"
    
    sudo systemctl enable nginx
    sudo systemctl restart nginx
    
    # Wait for service to start
    sleep 3
    
    if sudo systemctl is-active --quiet nginx; then
        log "✓ Nginx restarted successfully"
    else
        error "Nginx failed to start!"
        sudo systemctl status nginx
        exit 1
    fi
}

#===============================================================================
# PHASE 5: POST-DEPLOYMENT VALIDATION
#===============================================================================

validate_deployment() {
    section "PHASE 5: POST-DEPLOYMENT VALIDATION"
    
    subsection "5.1 HTTP Status Checks"
    
    local all_passed=true
    
    # Check Admin
    local admin_status=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/admin/ || echo "000")
    if [ "$admin_status" = "200" ]; then
        log "✓ Admin portal: HTTP $admin_status"
    else
        error "✗ Admin portal: HTTP $admin_status"
        all_passed=false
    fi
    
    # Check Tenant
    local tenant_status=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/tenant/ || echo "000")
    if [ "$tenant_status" = "200" ]; then
        log "✓ Tenant portal: HTTP $tenant_status"
    else
        error "✗ Tenant portal: HTTP $tenant_status"
        all_passed=false
    fi
    
    # Check API (if running)
    local api_status=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/health || echo "000")
    if [ "$api_status" = "200" ]; then
        log "✓ Backend API: HTTP $api_status"
    else
        warn "⚠ Backend API: HTTP $api_status (may not be running)"
    fi
    
    subsection "5.2 Critical Files Verification"
    
    local critical_files=(
        "/usr/share/nginx/html/admin/index.html"
        "/usr/share/nginx/html/admin/main.dart.js"
        "/usr/share/nginx/html/tenant/index.html"
        "/usr/share/nginx/html/tenant/main.dart.js"
    )
    
    for file in "${critical_files[@]}"; do
        if [ -f "$file" ]; then
            local size=$(du -h "$file" | cut -f1)
            log "✓ $(basename $file) ($size)"
        else
            error "✗ Missing: $file"
            all_passed=false
        fi
    done
    
    subsection "5.3 Asset Integrity"
    
    # Check main.dart.js integrity
    local admin_js="/usr/share/nginx/html/admin/main.dart.js"
    if [ -f "$admin_js" ]; then
        local first_line=$(head -1 "$admin_js")
        if [[ "$first_line" == *"DOCTYPE"* ]] || [[ "$first_line" == *"<html"* ]]; then
            error "✗ Admin JS file is corrupted (HTML instead of JS)"
            all_passed=false
        else
            log "✓ Admin JS file integrity OK"
        fi
    fi
    
    subsection "5.4 System Resource Usage"
    
    log "Current resource usage:"
    CURRENT_MEM=$(free -m | awk 'NR==2 {printf "%.1f%%", $3*100/$2}')
    CURRENT_DISK=$(df -h /home/ec2-user | awk 'NR==2 {print $5}')
    log "  Memory: $CURRENT_MEM used"
    log "  Disk: $CURRENT_DISK used"
    
    subsection "5.5 Deployment Manifest"
    
    local manifest_file="$LOG_DIR/${DEPLOYMENT_ID}_manifest.json"
    
    cat > "$manifest_file" << EOF
{
  "deployment_id": "${DEPLOYMENT_ID}",
  "timestamp": "$(date -Iseconds)",
  "infrastructure": {
    "cpu_cores": ${CPU_CORES},
    "total_ram_mb": ${TOTAL_RAM_MB},
    "available_ram_mb": ${AVAILABLE_RAM_MB},
    "swap_mb": ${SWAP_TOTAL_MB},
    "disk_available_gb": ${DISK_AVAIL_GB},
    "instance_type": "${INSTANCE_TYPE:-unknown}",
    "infra_score": ${INFRA_SCORE}
  },
  "software": {
    "flutter_version": "${FLUTTER_VERSION}",
    "dart_version": "${DART_VERSION}",
    "nginx_version": "${NGINX_VERSION:-unknown}"
  },
  "build_metrics": {
    "admin_build_time_s": $(cat "$PROJECT_ROOT/pgworld-master/.build_time.log" 2>/dev/null || echo "0"),
    "tenant_build_time_s": $(cat "$PROJECT_ROOT/pgworldtenant-master/.build_time.log" 2>/dev/null || echo "0"),
    "admin_size_mb": $(cat "$PROJECT_ROOT/pgworld-master/.build_size.log" 2>/dev/null || echo "0"),
    "tenant_size_mb": $(cat "$PROJECT_ROOT/pgworldtenant-master/.build_size.log" 2>/dev/null || echo "0")
  },
  "validation": {
    "admin_status": ${admin_status},
    "tenant_status": ${tenant_status},
    "api_status": ${api_status},
    "all_tests_passed": $([ "$all_passed" = true ] && echo "true" || echo "false")
  },
  "git_commit": "$(cd $PROJECT_ROOT && git rev-parse HEAD 2>/dev/null || echo 'unknown')"
}
EOF
    
    log "✓ Manifest: ${DEPLOYMENT_ID}_manifest.json"
    
    if [ "$all_passed" = false ]; then
        error "Some validation checks failed!"
        return 1
    fi
    
    return 0
}

#===============================================================================
# FINAL SUMMARY
#===============================================================================

deployment_summary() {
    section "DEPLOYMENT SUMMARY"
    
    local total_time=$(($(date +%s) - BUILD_START_TIME))
    local total_min=$((total_time / 60))
    local total_sec=$((total_time % 60))
    
    echo ""
    echo "╔════════════════════════════════════════════════════════╗"
    echo "║         🎉 DEPLOYMENT SUCCESSFUL! 🎉                  ║"
    echo "╟────────────────────────────────────────────────────────╢"
    echo "║ Deployment ID: ${DEPLOYMENT_ID}                        "
    echo "║ Total Time:    ${total_min}m ${total_sec}s            "
    echo "║                                                        ║"
    echo "║ Infrastructure Score: ${INFRA_SCORE}/100              "
    echo "║ Flutter:       ${FLUTTER_VERSION}                     "
    echo "║ Dart:          ${DART_VERSION}                        "
    echo "╟────────────────────────────────────────────────────────╢"
    echo "║ 🌐 Access URLs:                                       ║"
    echo "║   Admin:  http://34.227.111.143/admin/                ║"
    echo "║   Tenant: http://34.227.111.143/tenant/               ║"
    echo "║   API:    http://34.227.111.143:8080/health           ║"
    echo "╟────────────────────────────────────────────────────────╢"
    echo "║ 📊 Build Metrics:                                     ║"
    echo "║   Admin Size:  $(cat "$PROJECT_ROOT/pgworld-master/.build_size.log" 2>/dev/null || echo '?')MB"
    echo "║   Tenant Size: $(cat "$PROJECT_ROOT/pgworldtenant-master/.build_size.log" 2>/dev/null || echo '?')MB"
    echo "╟────────────────────────────────────────────────────────╢"
    echo "║ 🔐 Test Login:                                        ║"
    echo "║   Email:    admin@pgworld.com                         ║"
    echo "║   Password: Admin@123                                 ║"
    echo "╟────────────────────────────────────────────────────────╢"
    echo "║ 📋 Logs:                                              ║"
    echo "║   $LOG_FILE                                            "
    echo "║   $LOG_DIR/${DEPLOYMENT_ID}_manifest.json             "
    echo "╚════════════════════════════════════════════════════════╝"
    echo ""
    
    log "✓ Deployment completed successfully!"
    log ""
    log "Next steps:"
    log "  1. Test the applications at the URLs above"
    log "  2. Review the deployment manifest for metrics"
    log "  3. Monitor logs for any issues"
    log "  4. Consider infrastructure upgrades if build time > 10 min"
}

#===============================================================================
# MAIN EXECUTION
#===============================================================================

main() {
    BUILD_START_TIME=$(date +%s)
    
    echo ""
    echo "╔════════════════════════════════════════════════════════╗"
    echo "║   PGNI Flutter Web - Complete Infrastructure-Aware    ║"
    echo "║              Deployment System v${SCRIPT_VERSION}     ║"
    echo "╚════════════════════════════════════════════════════════╝"
    echo ""
    
    log "Starting deployment: ${DEPLOYMENT_ID}"
    log "Log file: $LOG_FILE"
    
    # Create required directories
    mkdir -p "$LOG_DIR" /home/ec2-user/backups
    
    # Execute all phases
    validate_infrastructure
    validate_software_stack
    prepare_environment
    
    build_flutter_app "Admin" "$PROJECT_ROOT/pgworld-master"
    build_flutter_app "Tenant" "$PROJECT_ROOT/pgworldtenant-master"
    
    deploy_to_nginx
    validate_deployment
    deployment_summary
    
    log "All operations completed successfully! ✓"
}

# Run main function
main "$@"

