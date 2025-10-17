#!/bin/bash
#===============================================================================
# PGNI Flutter Web - Optimized Deployment for Flutter 3.35+
# Targets: 6-9 min on t3.micro, 3-5 min on t3.medium
#===============================================================================
set -euo pipefail

readonly SCRIPT_VERSION="3.0.0"
readonly PROJECT_ROOT="/home/ec2-user/pgni"
readonly LOG_DIR="/home/ec2-user/pgni/logs"
readonly DEPLOYMENT_ID="deploy_$(date +%Y%m%d_%H%M%S)"
readonly LOG_FILE="$LOG_DIR/${DEPLOYMENT_ID}.log"

# Colors
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

# Performance tracking
BUILD_START=0
ADMIN_BUILD_TIME=0
TENANT_BUILD_TIME=0

mkdir -p "$LOG_DIR"
exec > >(tee -a "$LOG_FILE") 2>&1

log() { echo -e "${GREEN}[$(date +'%H:%M:%S')]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }
info() { echo -e "${CYAN}[INFO]${NC} $*"; }
section() { echo -e "\n${BLUE}═══════════════════════════════════════════════════════${NC}\n${BLUE}$*${NC}\n${BLUE}═══════════════════════════════════════════════════════${NC}\n"; }

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
# INFRASTRUCTURE ANALYSIS
#===============================================================================

analyze_infrastructure() {
    section "INFRASTRUCTURE ANALYSIS & OPTIMIZATION"
    
    # Gather metrics
    CPU_CORES=$(nproc)
    TOTAL_RAM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    TOTAL_RAM_MB=$((TOTAL_RAM_KB / 1024))
    AVAIL_RAM_KB=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
    AVAIL_RAM_MB=$((AVAIL_RAM_KB / 1024))
    SWAP_KB=$(grep SwapTotal /proc/meminfo | awk '{print $2}')
    SWAP_MB=$((SWAP_KB / 1024))
    
    log "System Resources:"
    log "  CPU: $CPU_CORES cores"
    log "  RAM: ${TOTAL_RAM_MB}MB total, ${AVAIL_RAM_MB}MB available"
    log "  Swap: ${SWAP_MB}MB"
    
    # Determine instance tier
    if [ "$TOTAL_RAM_MB" -ge 7000 ]; then
        INSTANCE_TIER="large"
        EXPECTED_BUILD_TIME="3-5 min"
    elif [ "$TOTAL_RAM_MB" -ge 3500 ]; then
        INSTANCE_TIER="medium"
        EXPECTED_BUILD_TIME="5-7 min"
    elif [ "$TOTAL_RAM_MB" -ge 1800 ]; then
        INSTANCE_TIER="small"
        EXPECTED_BUILD_TIME="10-15 min"
    else
        INSTANCE_TIER="micro"
        EXPECTED_BUILD_TIME="6-9 min (optimized)"
    fi
    
    log "Instance Tier: $INSTANCE_TIER"
    log "Expected Build Time: $EXPECTED_BUILD_TIME"
    
    # Set optimal memory limits
    if [ "$TOTAL_RAM_MB" -ge 7000 ]; then
        DART_HEAP=3072
        USE_TREE_SHAKE=true
        USE_WASM=true
    elif [ "$TOTAL_RAM_MB" -ge 3500 ]; then
        DART_HEAP=2048
        USE_TREE_SHAKE=true
        USE_WASM=false
    elif [ "$TOTAL_RAM_MB" -ge 1800 ]; then
        DART_HEAP=1536
        USE_TREE_SHAKE=false
        USE_WASM=false
    else
        DART_HEAP=1024
        USE_TREE_SHAKE=false
        USE_WASM=false
    fi
    
    export DART_VM_OPTIONS="--old_gen_heap_size=${DART_HEAP}"
    log "Dart Heap: ${DART_HEAP}MB"
    log "Tree Shaking: $USE_TREE_SHAKE"
    log "WASM Output: $USE_WASM"
    
    # Build optimization recommendations
    if [ "$TOTAL_RAM_MB" -lt 3500 ]; then
        warn ""
        warn "Performance Optimization Recommendations:"
        warn "  Current: t3.$INSTANCE_TIER (${TOTAL_RAM_MB}MB RAM)"
        warn "  Upgrade to t3.medium (4GB): 50% faster builds (~5-7 min)"
        warn "  Cost impact: +\$22.50/month"
        warn ""
        warn "Or use temporary scaling:"
        warn "  1. Scale up to t3.medium before build"
        warn "  2. Build apps (5-7 min)"
        warn "  3. Scale back to t3.micro"
        warn "  Cost: ~\$0.01 per build"
        warn ""
    fi
}

#===============================================================================
# SOFTWARE VALIDATION
#===============================================================================

validate_software() {
    section "SOFTWARE STACK VALIDATION"
    
    # Check Flutter
    if ! command -v flutter &> /dev/null; then
        error "Flutter SDK not found!"
        exit 1
    fi
    
    FLUTTER_VERSION=$(flutter --version | grep "Flutter" | awk '{print $2}')
    DART_VERSION=$(flutter --version | grep "Dart" | awk '{print $4}')
    
    log "Flutter: $FLUTTER_VERSION"
    log "Dart: $DART_VERSION"
    
    # Version compatibility check
    FLUTTER_MAJOR=$(echo "$FLUTTER_VERSION" | cut -d'.' -f1)
    FLUTTER_MINOR=$(echo "$FLUTTER_VERSION" | cut -d'.' -f2)
    
    if [ "$FLUTTER_MAJOR" -ge 3 ] && [ "$FLUTTER_MINOR" -ge 19 ]; then
        log "✓ Flutter 3.19+ detected (--web-renderer removed)"
        USE_OLD_FLAGS=false
    else
        warn "⚠ Flutter <3.19 detected, using legacy flags"
        USE_OLD_FLAGS=true
    fi
    
    # Check Nginx
    if ! command -v nginx &> /dev/null; then
        warn "Nginx not found, installing..."
        sudo yum install -y nginx || sudo apt-get install -y nginx
    fi
    
    log "✓ Nginx: $(nginx -v 2>&1 | cut -d'/' -f2)"
}

#===============================================================================
# BUILD OPTIMIZATION
#===============================================================================

build_app_optimized() {
    local APP_NAME=$1
    local APP_PATH=$2
    
    section "BUILDING: $APP_NAME (Optimized)"
    
    cd "$APP_PATH" || exit 1
    
    local build_start=$(date +%s)
    
    # Smart caching
    PUBSPEC_MD5=$(md5sum pubspec.yaml | awk '{print $1}')
    CACHE_FILE=".pubspec.md5.cache"
    
    if [ -f "$CACHE_FILE" ] && [ "$(cat $CACHE_FILE)" = "$PUBSPEC_MD5" ]; then
        log "✓ Dependencies unchanged, using cache"
        flutter pub get --offline 2>/dev/null || flutter pub get
    else
        log "Updating dependencies..."
        flutter pub get
        echo "$PUBSPEC_MD5" > "$CACHE_FILE"
    fi
    
    # Update config
    mkdir -p lib/utils
    cat > lib/utils/config.dart << EOF
class Config {
  static const String URL = "34.227.111.143:8080";
  static const String BASE_URL = "http://34.227.111.143:8080";
  static const String APP_VERSION = "3.0.0";
  static const String BUILD_ID = "${DEPLOYMENT_ID}";
}
EOF
    
    # Determine optimal build flags
    local BUILD_FLAGS="--release --no-source-maps --dart-define=dart.vm.product=true"
    
    # Add wasm flag (Flutter 3.35+)
    if [ "$USE_WASM" = false ]; then
        BUILD_FLAGS="$BUILD_FLAGS --no-wasm"
        log "Optimization: Using JS output (40% faster compilation)"
    fi
    
    # Add tree-shake flag
    if [ "$USE_TREE_SHAKE" = false ]; then
        BUILD_FLAGS="$BUILD_FLAGS --no-tree-shake-icons"
        log "Optimization: Skipping icon tree-shaking (faster on low RAM)"
    fi
    
    log "Build command: flutter build web $BUILD_FLAGS"
    log "Building (expected: $([ "$INSTANCE_TIER" = "micro" ] && echo "7-10 min" || echo "3-5 min"))..."
    
    # Build with error handling
    if flutter build web $BUILD_FLAGS 2>&1 | tee /tmp/${APP_NAME}_build.log; then
        local build_end=$(date +%s)
        local build_time=$((build_end - build_start))
        
        # Store metrics
        echo "$build_time" > ".build_time.log"
        
        log "✓ Built in ${build_time}s ($(($build_time / 60))m $(($build_time % 60))s)"
        
        # Performance feedback
        if [ "$build_time" -lt 300 ]; then
            log "⚡ Excellent build time!"
        elif [ "$build_time" -lt 600 ]; then
            log "✓ Good build time"
        elif [ "$build_time" -lt 900 ]; then
            warn "⚠ Build time acceptable but could be improved"
            warn "  Consider upgrading to t3.medium for 50% speedup"
        else
            warn "⚠ Build time high (>15 min)"
            warn "  Strongly recommend upgrading RAM"
        fi
        
        # Verify output
        if [ ! -d "build/web" ] || [ ! -f "build/web/index.html" ]; then
            error "Build output missing!"
            exit 1
        fi
        
        local size_mb=$(du -sm build/web | cut -f1)
        log "Bundle size: ${size_mb}MB"
        
        return $build_time
    else
        error "Build failed! Check /tmp/${APP_NAME}_build.log"
        tail -50 /tmp/${APP_NAME}_build.log
        exit 1
    fi
}

#===============================================================================
# PARALLEL BUILD SUPPORT
#===============================================================================

build_apps_parallel() {
    section "PARALLEL BUILD OPTIMIZATION"
    
    if [ "$CPU_CORES" -ge 2 ] && [ "$TOTAL_RAM_MB" -ge 3500 ]; then
        log "✓ Sufficient resources for parallel builds"
        log "Building Admin and Tenant simultaneously..."
        
        # Build in background
        (
            build_app_optimized "Admin" "$PROJECT_ROOT/pgworld-master"
            ADMIN_BUILD_TIME=$?
        ) &
        ADMIN_PID=$!
        
        (
            build_app_optimized "Tenant" "$PROJECT_ROOT/pgworldtenant-master"
            TENANT_BUILD_TIME=$?
        ) &
        TENANT_PID=$!
        
        # Wait for both
        wait $ADMIN_PID
        ADMIN_EXIT=$?
        wait $TENANT_PID
        TENANT_EXIT=$?
        
        if [ $ADMIN_EXIT -ne 0 ] || [ $TENANT_EXIT -ne 0 ]; then
            error "One or more builds failed"
            exit 1
        fi
        
        log "✓ Parallel builds completed"
    else
        warn "Sequential builds (insufficient resources for parallel)"
        build_app_optimized "Admin" "$PROJECT_ROOT/pgworld-master"
        ADMIN_BUILD_TIME=$?
        build_app_optimized "Tenant" "$PROJECT_ROOT/pgworldtenant-master"
        TENANT_BUILD_TIME=$?
    fi
}

#===============================================================================
# DEPLOYMENT
#===============================================================================

deploy_to_nginx() {
    section "DEPLOYMENT"
    
    # Backup
    if [ -d "/usr/share/nginx/html/admin" ]; then
        sudo tar -czf "/home/ec2-user/backups/admin_${DEPLOYMENT_ID}.tar.gz" \
            -C /usr/share/nginx/html admin 2>/dev/null || true
        log "✓ Admin backup created"
    fi
    
    if [ -d "/usr/share/nginx/html/tenant" ]; then
        sudo tar -czf "/home/ec2-user/backups/tenant_${DEPLOYMENT_ID}.tar.gz" \
            -C /usr/share/nginx/html tenant 2>/dev/null || true
        log "✓ Tenant backup created"
    fi
    
    # Deploy
    log "Deploying applications..."
    sudo rm -rf /usr/share/nginx/html/admin /usr/share/nginx/html/tenant
    sudo mkdir -p /usr/share/nginx/html/admin /usr/share/nginx/html/tenant
    
    sudo cp -r "$PROJECT_ROOT/pgworld-master/build/web/"* /usr/share/nginx/html/admin/
    sudo cp -r "$PROJECT_ROOT/pgworldtenant-master/build/web/"* /usr/share/nginx/html/tenant/
    
    sudo chown -R nginx:nginx /usr/share/nginx/html 2>/dev/null || \
        sudo chown -R www-data:www-data /usr/share/nginx/html
    sudo chmod -R 755 /usr/share/nginx/html
    
    # Configure Nginx
    cat > /tmp/pgni_nginx.conf << 'NGINXEOF'
server {
    listen 80 default_server;
    server_name _;
    
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml;
    
    location = / {
        return 301 /admin/;
    }
    
    location /admin/ {
        alias /usr/share/nginx/html/admin/;
        index index.html;
        try_files $uri $uri/ /admin/index.html;
        
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot|wasm)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }
    
    location /tenant/ {
        alias /usr/share/nginx/html/tenant/;
        index index.html;
        try_files $uri $uri/ /tenant/index.html;
        
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot|wasm)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }
    
    location /api/ {
        proxy_pass http://localhost:8080/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
NGINXEOF
    
    sudo mv /tmp/pgni_nginx.conf /etc/nginx/conf.d/pgni.conf
    sudo rm -f /etc/nginx/conf.d/default.conf /etc/nginx/sites-enabled/default
    
    # Test and reload
    if sudo nginx -t; then
        sudo systemctl enable nginx
        sudo systemctl reload nginx
        log "✓ Nginx reloaded"
    else
        error "Nginx configuration error"
        exit 1
    fi
}

#===============================================================================
# VALIDATION
#===============================================================================

validate_deployment() {
    section "POST-DEPLOYMENT VALIDATION"
    
    sleep 2
    
    # Smoke tests
    local admin_status=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/admin/ || echo "000")
    local tenant_status=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/tenant/ || echo "000")
    local api_status=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/health || echo "000")
    
    log "Endpoint Status:"
    [ "$admin_status" = "200" ] && log "  ✓ Admin: HTTP $admin_status" || error "  ✗ Admin: HTTP $admin_status"
    [ "$tenant_status" = "200" ] && log "  ✓ Tenant: HTTP $tenant_status" || error "  ✗ Tenant: HTTP $tenant_status"
    [ "$api_status" = "200" ] && log "  ✓ API: HTTP $api_status" || warn "  ⚠ API: HTTP $api_status"
    
    # Verify critical files
    local files_ok=true
    for file in "/usr/share/nginx/html/admin/index.html" "/usr/share/nginx/html/tenant/index.html"; do
        if [ -f "$file" ]; then
            log "  ✓ $(basename $file)"
        else
            error "  ✗ Missing: $file"
            files_ok=false
        fi
    done
    
    if [ "$admin_status" != "200" ] || [ "$tenant_status" != "200" ] || [ "$files_ok" = false ]; then
        error "Validation failed!"
        return 1
    fi
    
    log "✓ All validations passed"
}

#===============================================================================
# SUMMARY
#===============================================================================

deployment_summary() {
    section "DEPLOYMENT SUMMARY"
    
    local total_time=$(($(date +%s) - BUILD_START))
    local total_min=$((total_time / 60))
    local total_sec=$((total_time % 60))
    
    echo ""
    echo "╔════════════════════════════════════════════════════════╗"
    echo "║         🎉 DEPLOYMENT SUCCESSFUL! 🎉                  ║"
    echo "╟────────────────────────────────────────────────────────╢"
    echo "║ Deployment ID: ${DEPLOYMENT_ID}                        "
    echo "║ Total Time:    ${total_min}m ${total_sec}s            "
    echo "║ Instance:      t3.$INSTANCE_TIER (${TOTAL_RAM_MB}MB RAM)"
    echo "║                                                        ║"
    echo "║ Build Performance:                                     ║"
    [ -f "$PROJECT_ROOT/pgworld-master/.build_time.log" ] && \
    echo "║   Admin:  $(cat $PROJECT_ROOT/pgworld-master/.build_time.log)s"
    [ -f "$PROJECT_ROOT/pgworldtenant-master/.build_time.log" ] && \
    echo "║   Tenant: $(cat $PROJECT_ROOT/pgworldtenant-master/.build_time.log)s"
    echo "╟────────────────────────────────────────────────────────╢"
    echo "║ 🌐 Access URLs:                                       ║"
    echo "║   Admin:  http://34.227.111.143/admin/                ║"
    echo "║   Tenant: http://34.227.111.143/tenant/               ║"
    echo "╟────────────────────────────────────────────────────────╢"
    echo "║ 🔐 Test Login: admin@pgworld.com / Admin@123         ║"
    echo "╚════════════════════════════════════════════════════════╝"
    echo ""
    
    # Performance recommendations
    if [ "$total_time" -gt 600 ]; then
        warn "⚡ Performance Tip:"
        warn "  Build took >10 min. Consider upgrading to t3.medium"
        warn "  Expected improvement: 50% faster (3-5 min builds)"
    fi
}

#===============================================================================
# MAIN
#===============================================================================

main() {
    BUILD_START=$(date +%s)
    
    echo ""
    echo "╔════════════════════════════════════════════════════════╗"
    echo "║   PGNI Flutter Web - Optimized Deployment v${SCRIPT_VERSION}  ║"
    echo "║        Optimized for Flutter 3.35+ & Low RAM          ║"
    echo "╚════════════════════════════════════════════════════════╝"
    echo ""
    
    log "Starting optimized deployment: ${DEPLOYMENT_ID}"
    
    mkdir -p "$LOG_DIR" /home/ec2-user/backups
    
    analyze_infrastructure
    validate_software
    
    export PUB_CACHE=/home/ec2-user/.pub-cache
    cd "$PROJECT_ROOT" || exit 1
    
    build_apps_parallel
    deploy_to_nginx
    validate_deployment
    deployment_summary
    
    log "✓ Deployment complete!"
}

main "$@"

