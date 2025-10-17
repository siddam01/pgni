#!/bin/bash
#===============================================================================
# PGNI Flutter Web - Production Deployment Script
# Optimized for AWS EC2 with Enterprise Best Practices
#===============================================================================
set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Configuration
readonly SCRIPT_VERSION="1.0.0"
readonly PROJECT_ROOT="/home/ec2-user/pgni"
readonly CACHE_DIR="/home/ec2-user/.flutter-build-cache"
readonly LOG_DIR="/home/ec2-user/pgni/logs"
readonly DEPLOYMENT_ID="deploy_$(date +%Y%m%d_%H%M%S)"
readonly BUILD_TIMEOUT=1800  # 30 minutes

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Logging
mkdir -p "$LOG_DIR"
readonly LOG_FILE="$LOG_DIR/${DEPLOYMENT_ID}.log"
exec > >(tee -a "$LOG_FILE") 2>&1

#===============================================================================
# HELPER FUNCTIONS
#===============================================================================

log() { echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }
section() { echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n${BLUE}$*${NC}\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"; }

# Graceful exit handler
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
# PRE-DEPLOYMENT CHECKS
#===============================================================================

pre_deployment_checks() {
    section "PRE-DEPLOYMENT CHECKS"
    
    # 1. Check Flutter SDK
    log "Checking Flutter SDK..."
    if ! command -v flutter &> /dev/null; then
        error "Flutter SDK not found. Please install Flutter."
        exit 1
    fi
    
    flutter --version | head -5
    dart --version
    
    # Extract versions
    FLUTTER_VERSION=$(flutter --version | grep "Flutter" | awk '{print $2}')
    DART_VERSION=$(flutter --version | grep "Dart" | awk '{print $4}')
    
    log "Flutter: $FLUTTER_VERSION | Dart: $DART_VERSION"
    
    # 2. Run flutter doctor
    log "Running flutter doctor..."
    flutter doctor -v || warn "Some flutter doctor checks failed (non-critical)"
    
    # 3. Check system resources
    log "Checking system resources..."
    
    AVAILABLE_MEM=$(free -m | awk 'NR==2 {print $7}')
    TOTAL_MEM=$(free -m | awk 'NR==2 {print $2}')
    DISK_FREE=$(df -h /home/ec2-user | awk 'NR==2 {print $4}')
    CPU_CORES=$(nproc)
    
    log "Memory: ${AVAILABLE_MEM}MB available / ${TOTAL_MEM}MB total"
    log "Disk: ${DISK_FREE} free"
    log "CPU Cores: ${CPU_CORES}"
    
    if [ "$AVAILABLE_MEM" -lt 1500 ]; then
        warn "Low memory detected. Build may be slower."
        # Set conservative memory limits
        export DART_VM_OPTIONS="--old_gen_heap_size=1536"
    else
        # Optimal memory settings
        export DART_VM_OPTIONS="--old_gen_heap_size=2048"
    fi
    
    # 4. Check if source code is up to date
    log "Checking Git status..."
    cd "$PROJECT_ROOT"
    
    if [ -d ".git" ]; then
        git fetch origin main --quiet
        LOCAL=$(git rev-parse HEAD)
        REMOTE=$(git rev-parse origin/main)
        
        if [ "$LOCAL" != "$REMOTE" ]; then
            warn "Local code is behind remote. Pulling latest..."
            git pull origin main
        else
            log "Code is up to date"
        fi
    fi
    
    # 5. Verify dependencies checksum
    log "Checking dependencies..."
    mkdir -p "$CACHE_DIR"
    
    # Generate checksum of pubspec files
    ADMIN_CHECKSUM=$(md5sum "$PROJECT_ROOT/pgworld-master/pubspec.yaml" | awk '{print $1}')
    TENANT_CHECKSUM=$(md5sum "$PROJECT_ROOT/pgworldtenant-master/pubspec.yaml" | awk '{print $1}')
    
    # Store for later comparison
    echo "$ADMIN_CHECKSUM" > "$CACHE_DIR/admin_deps.md5"
    echo "$TENANT_CHECKSUM" > "$CACHE_DIR/tenant_deps.md5"
    
    log "Pre-deployment checks complete ✓"
}

#===============================================================================
# INTELLIGENT BUILD STRATEGY
#===============================================================================

should_rebuild() {
    local app_name=$1
    local current_checksum=$2
    local cache_file="$CACHE_DIR/${app_name}_deps.md5.last"
    
    # Force rebuild if no cache
    if [ ! -f "$cache_file" ]; then
        log "$app_name: No previous build cache found"
        return 0  # true
    fi
    
    # Check if dependencies changed
    local last_checksum=$(cat "$cache_file")
    if [ "$current_checksum" != "$last_checksum" ]; then
        log "$app_name: Dependencies changed, rebuild required"
        return 0  # true
    fi
    
    # Check if build output exists
    if [ ! -d "$PROJECT_ROOT/$app_name/build/web" ]; then
        log "$app_name: Build output missing, rebuild required"
        return 0  # true
    fi
    
    log "$app_name: Build cache valid, incremental build possible"
    return 1  # false
}

#===============================================================================
# BUILD ADMIN APP
#===============================================================================

build_admin_app() {
    section "BUILD ADMIN APP"
    
    cd "$PROJECT_ROOT/pgworld-master"
    
    # Update config
    log "Updating config.dart..."
    mkdir -p lib/utils
    cat > lib/utils/config.dart << 'EOF'
class Config {
  static const String URL = "34.227.111.143:8080";
  static const String BASE_URL = "http://34.227.111.143:8080";
  static const String APP_VERSION = "1.0.0";
  static const String BUILD_ID = "DEPLOYMENT_ID_PLACEHOLDER";
}
EOF
    
    # Replace placeholder with actual deployment ID
    sed -i "s/DEPLOYMENT_ID_PLACEHOLDER/${DEPLOYMENT_ID}/" lib/utils/config.dart
    
    # Check if full rebuild needed
    local admin_checksum=$(cat "$CACHE_DIR/admin_deps.md5")
    
    if should_rebuild "pgworld-master" "$admin_checksum"; then
        log "Performing FULL build..."
        
        # Clean only if dependencies changed
        flutter clean
        rm -rf .dart_tool build
        
        # Get fresh dependencies
        log "Resolving dependencies..."
        flutter pub get
        
        # Save checksum for next build
        echo "$admin_checksum" > "$CACHE_DIR/admin_deps.md5.last"
    else
        log "Performing INCREMENTAL build..."
        
        # Just update dependencies (faster)
        flutter pub get --offline || flutter pub get
    fi
    
    # Build with optimized flags
    log "Building for web (this may take 5-10 minutes)..."
    
    local build_start=$(date +%s)
    
    # Use optimal build flags based on resources
    if [ "$AVAILABLE_MEM" -lt 2000 ]; then
        # Memory-constrained build
        flutter build web \
            --release \
            --web-renderer html \
            --no-tree-shake-icons \
            --no-source-maps \
            --dart-define=dart.vm.product=true
    else
        # Optimal build
        flutter build web \
            --release \
            --web-renderer canvaskit \
            --no-source-maps \
            --dart-define=dart.vm.product=true
    fi
    
    local build_end=$(date +%s)
    local build_time=$((build_end - build_start))
    
    # Verify build output
    if [ ! -d "build/web" ] || [ ! -f "build/web/index.html" ]; then
        error "Admin build failed - output not created"
        exit 1
    fi
    
    local file_count=$(ls build/web | wc -l)
    local build_size=$(du -sh build/web | cut -f1)
    
    log "✓ Admin built successfully"
    log "  Files: $file_count"
    log "  Size: $build_size"
    log "  Time: ${build_time}s"
    
    # Check build size (warn if too large)
    local size_mb=$(du -sm build/web | cut -f1)
    if [ "$size_mb" -gt 50 ]; then
        warn "Build size is large (${size_mb}MB). Consider optimizing assets."
    fi
}

#===============================================================================
# BUILD TENANT APP
#===============================================================================

build_tenant_app() {
    section "BUILD TENANT APP"
    
    cd "$PROJECT_ROOT/pgworldtenant-master"
    
    # Update config
    log "Updating config.dart..."
    mkdir -p lib/utils
    cat > lib/utils/config.dart << 'EOF'
class Config {
  static const String URL = "34.227.111.143:8080";
  static const String BASE_URL = "http://34.227.111.143:8080";
  static const String APP_VERSION = "1.0.0";
  static const String BUILD_ID = "DEPLOYMENT_ID_PLACEHOLDER";
}
EOF
    
    sed -i "s/DEPLOYMENT_ID_PLACEHOLDER/${DEPLOYMENT_ID}/" lib/utils/config.dart
    
    # Check if full rebuild needed
    local tenant_checksum=$(cat "$CACHE_DIR/tenant_deps.md5")
    
    if should_rebuild "pgworldtenant-master" "$tenant_checksum"; then
        log "Performing FULL build..."
        flutter clean
        rm -rf .dart_tool build
        flutter pub get
        echo "$tenant_checksum" > "$CACHE_DIR/tenant_deps.md5.last"
    else
        log "Performing INCREMENTAL build..."
        flutter pub get --offline || flutter pub get
    fi
    
    log "Building for web..."
    local build_start=$(date +%s)
    
    if [ "$AVAILABLE_MEM" -lt 2000 ]; then
        flutter build web \
            --release \
            --web-renderer html \
            --no-tree-shake-icons \
            --no-source-maps \
            --dart-define=dart.vm.product=true
    else
        flutter build web \
            --release \
            --web-renderer canvaskit \
            --no-source-maps \
            --dart-define=dart.vm.product=true
    fi
    
    local build_end=$(date +%s)
    local build_time=$((build_end - build_start))
    
    if [ ! -d "build/web" ] || [ ! -f "build/web/index.html" ]; then
        error "Tenant build failed - output not created"
        exit 1
    fi
    
    local file_count=$(ls build/web | wc -l)
    local build_size=$(du -sh build/web | cut -f1)
    
    log "✓ Tenant built successfully"
    log "  Files: $file_count"
    log "  Size: $build_size"
    log "  Time: ${build_time}s"
}

#===============================================================================
# DEPLOYMENT
#===============================================================================

deploy_to_nginx() {
    section "DEPLOYMENT TO NGINX"
    
    # Install Nginx if not present
    if ! command -v nginx &> /dev/null; then
        log "Installing Nginx..."
        sudo yum install -y nginx
    fi
    
    # Backup current deployment
    log "Creating backup..."
    if [ -d "/usr/share/nginx/html/admin" ]; then
        sudo tar -czf "/home/ec2-user/backups/admin_$(date +%Y%m%d_%H%M%S).tar.gz" \
            -C /usr/share/nginx/html admin 2>/dev/null || true
    fi
    
    if [ -d "/usr/share/nginx/html/tenant" ]; then
        sudo tar -czf "/home/ec2-user/backups/tenant_$(date +%Y%m%d_%H%M%S).tar.gz" \
            -C /usr/share/nginx/html tenant 2>/dev/null || true
    fi
    
    # Deploy new builds
    log "Deploying Admin app..."
    sudo rm -rf /usr/share/nginx/html/admin
    sudo mkdir -p /usr/share/nginx/html/admin
    sudo cp -r "$PROJECT_ROOT/pgworld-master/build/web/"* /usr/share/nginx/html/admin/
    
    log "Deploying Tenant app..."
    sudo rm -rf /usr/share/nginx/html/tenant
    sudo mkdir -p /usr/share/nginx/html/tenant
    sudo cp -r "$PROJECT_ROOT/pgworldtenant-master/build/web/"* /usr/share/nginx/html/tenant/
    
    # Set permissions
    sudo chown -R nginx:nginx /usr/share/nginx/html
    sudo chmod -R 755 /usr/share/nginx/html
    
    # Configure Nginx
    log "Configuring Nginx..."
    sudo bash -c 'cat > /etc/nginx/conf.d/pgni.conf << "NGINXEOF"
server {
    listen 80 default_server;
    server_name _;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml;
    
    location = / {
        return 301 /admin/;
    }
    
    location /admin/ {
        alias /usr/share/nginx/html/admin/;
        index index.html;
        try_files $uri $uri/ /admin/index.html;
        
        # Cache static assets
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
        
        # No cache for index.html
        location = /admin/index.html {
            add_header Cache-Control "no-cache, no-store, must-revalidate";
        }
    }
    
    location /tenant/ {
        alias /usr/share/nginx/html/tenant/;
        index index.html;
        try_files $uri $uri/ /tenant/index.html;
        
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
        
        location = /tenant/index.html {
            add_header Cache-Control "no-cache, no-store, must-revalidate";
        }
    }
}
NGINXEOF'
    
    sudo rm -f /etc/nginx/conf.d/default.conf
    
    # Test Nginx config
    log "Testing Nginx configuration..."
    if ! sudo nginx -t; then
        error "Nginx configuration test failed"
        exit 1
    fi
    
    # Reload Nginx
    log "Reloading Nginx..."
    sudo systemctl enable nginx
    sudo systemctl reload nginx
    
    log "✓ Deployment complete"
}

#===============================================================================
# POST-DEPLOYMENT CHECKS
#===============================================================================

post_deployment_checks() {
    section "POST-DEPLOYMENT CHECKS"
    
    # Wait for Nginx to stabilize
    sleep 3
    
    # 1. Smoke tests
    log "Running smoke tests..."
    
    local admin_status=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/admin/ || echo "000")
    local tenant_status=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/tenant/ || echo "000")
    local api_status=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/health || echo "000")
    
    if [ "$admin_status" = "200" ]; then
        log "✓ Admin portal: HTTP $admin_status"
    else
        error "✗ Admin portal: HTTP $admin_status"
    fi
    
    if [ "$tenant_status" = "200" ]; then
        log "✓ Tenant portal: HTTP $tenant_status"
    else
        error "✗ Tenant portal: HTTP $tenant_status"
    fi
    
    if [ "$api_status" = "200" ]; then
        log "✓ Backend API: HTTP $api_status"
    else
        warn "⚠ Backend API: HTTP $api_status"
    fi
    
    # 2. Check asset sizes
    log "Checking asset sizes..."
    
    local admin_size=$(du -sm /usr/share/nginx/html/admin | cut -f1)
    local tenant_size=$(du -sm /usr/share/nginx/html/tenant | cut -f1)
    
    log "Admin: ${admin_size}MB"
    log "Tenant: ${tenant_size}MB"
    
    # 3. Verify critical files
    log "Verifying critical files..."
    
    local critical_files=(
        "/usr/share/nginx/html/admin/index.html"
        "/usr/share/nginx/html/admin/main.dart.js"
        "/usr/share/nginx/html/tenant/index.html"
        "/usr/share/nginx/html/tenant/main.dart.js"
    )
    
    for file in "${critical_files[@]}"; do
        if [ -f "$file" ]; then
            log "✓ $(basename $file)"
        else
            error "✗ Missing: $file"
        fi
    done
    
    # 4. Create deployment manifest
    log "Creating deployment manifest..."
    cat > "$LOG_DIR/${DEPLOYMENT_ID}_manifest.json" << EOF
{
  "deployment_id": "${DEPLOYMENT_ID}",
  "timestamp": "$(date -Iseconds)",
  "flutter_version": "${FLUTTER_VERSION}",
  "dart_version": "${DART_VERSION}",
  "admin_size_mb": ${admin_size},
  "tenant_size_mb": ${tenant_size},
  "admin_status": ${admin_status},
  "tenant_status": ${tenant_status},
  "api_status": ${api_status},
  "git_commit": "$(cd $PROJECT_ROOT && git rev-parse HEAD)"
}
EOF
    
    log "✓ Manifest saved: ${DEPLOYMENT_ID}_manifest.json"
}

#===============================================================================
# DEPLOYMENT SUMMARY
#===============================================================================

deployment_summary() {
    section "DEPLOYMENT SUMMARY"
    
    local total_end=$(date +%s)
    local total_time=$((total_end - DEPLOYMENT_START))
    
    echo ""
    echo "╔════════════════════════════════════════════════╗"
    echo "║      🎉 DEPLOYMENT SUCCESSFUL! 🎉             ║"
    echo "╟────────────────────────────────────────────────╢"
    echo "║ Deployment ID: ${DEPLOYMENT_ID}                ║"
    echo "║ Total Time:    ${total_time}s                 ║"
    echo "║ Flutter:       ${FLUTTER_VERSION}             ║"
    echo "║ Dart:          ${DART_VERSION}                ║"
    echo "╟────────────────────────────────────────────────╢"
    echo "║ Access URLs:                                   ║"
    echo "║  Admin:  http://34.227.111.143/admin/         ║"
    echo "║  Tenant: http://34.227.111.143/tenant/        ║"
    echo "║  API:    http://34.227.111.143:8080/health    ║"
    echo "╟────────────────────────────────────────────────╢"
    echo "║ Login: admin@pgworld.com / Admin@123          ║"
    echo "║ Log:   $LOG_FILE                               ║"
    echo "╚════════════════════════════════════════════════╝"
    echo ""
}

#===============================================================================
# MAIN EXECUTION
#===============================================================================

main() {
    readonly DEPLOYMENT_START=$(date +%s)
    
    log "Starting PGNI Web Deployment v${SCRIPT_VERSION}"
    log "Deployment ID: ${DEPLOYMENT_ID}"
    
    # Create necessary directories
    mkdir -p "$CACHE_DIR" "$LOG_DIR" /home/ec2-user/backups
    
    # Execute deployment stages
    pre_deployment_checks
    build_admin_app
    build_tenant_app
    deploy_to_nginx
    post_deployment_checks
    deployment_summary
    
    log "Deployment completed successfully ✓"
}

# Run main function
main "$@"

