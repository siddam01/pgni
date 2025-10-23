#!/bin/bash
set -e

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║      CLEANUP: Remove Non-Essential Documentation & Scripts    ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

REPO_ROOT="/home/ec2-user/pgni"
cd "$REPO_ROOT"

echo -e "${BLUE}[1/4] Creating archive for documentation and scripts...${NC}"
ARCHIVE_DIR="docs_scripts_archive_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$ARCHIVE_DIR"
echo -e "${GREEN}✓ Archive directory created: $ARCHIVE_DIR${NC}"

echo ""
echo -e "${BLUE}[2/4] Moving non-essential files to archive...${NC}"

# Count files before
TOTAL_MD=$(find . -maxdepth 1 -name "*.md" -not -name "README.md" | wc -l)
TOTAL_SH=$(find . -maxdepth 1 -name "*.sh" | wc -l)
TOTAL_PS1=$(find . -maxdepth 1 -name "*.ps1" | wc -l)
TOTAL_BAT=$(find . -maxdepth 1 -name "*.bat" | wc -l)
TOTAL_TXT=$(find . -maxdepth 1 -name "*.txt" | wc -l)

echo "Found:"
echo "  - $TOTAL_MD documentation files (.md, excluding README.md)"
echo "  - $TOTAL_SH shell scripts (.sh)"
echo "  - $TOTAL_PS1 PowerShell scripts (.ps1)"
echo "  - $TOTAL_BAT batch files (.bat)"
echo "  - $TOTAL_TXT text files (.txt)"
echo ""

# Move documentation files (keep only README.md)
echo "Moving .md files (keeping README.md)..."
find . -maxdepth 1 -name "*.md" -not -name "README.md" -exec mv {} "$ARCHIVE_DIR/" \;

# Move all script files
echo "Moving .sh files..."
find . -maxdepth 1 -name "*.sh" -exec mv {} "$ARCHIVE_DIR/" \;

echo "Moving .ps1 files..."
find . -maxdepth 1 -name "*.ps1" -exec mv {} "$ARCHIVE_DIR/" \;

echo "Moving .bat files..."
find . -maxdepth 1 -name "*.bat" -exec mv {} "$ARCHIVE_DIR/" \;

echo "Moving .txt files..."
find . -maxdepth 1 -name "*.txt" -exec mv {} "$ARCHIVE_DIR/" \;

# Move old archive directories
echo "Moving old archive directories..."
find . -maxdepth 1 -type d -name "archive*" -not -name "$ARCHIVE_DIR" -exec mv {} "$ARCHIVE_DIR/" \; 2>/dev/null || true
find . -maxdepth 1 -type d -name "*backup*" -not -name "$ARCHIVE_DIR" -exec mv {} "$ARCHIVE_DIR/" \; 2>/dev/null || true

echo -e "${GREEN}✓ Files moved to archive${NC}"

echo ""
echo -e "${BLUE}[3/4] Creating simplified README.md...${NC}"

cat > README.md << 'EOF'
# CloudPG - PG/Hostel Management System

A comprehensive solution for managing PG accommodations and hostels.

## 🏢 System Components

### **1. Admin Portal**
- **Location**: `pgworld-master/`
- **Purpose**: PG Owner/Admin management interface
- **Features**: Manage hostels, rooms, tenants, bills, employees, notices, reports
- **Technology**: Flutter (Mobile & Web)

### **2. Tenant Portal**
- **Location**: `pgworldtenant-master/`
- **Purpose**: Tenant/Resident mobile app
- **Features**: View room details, bills, notices, submit issues, food menu
- **Technology**: Flutter (Mobile & Web)

### **3. API Backend**
- **Location**: `pgworld-master/` (Go files)
- **Purpose**: REST API server
- **Technology**: Go (Golang)
- **Database**: MySQL

## 🚀 Quick Start

### **Prerequisites**
- Flutter SDK ≥ 3.24.x
- Dart SDK ≥ 3.4.x
- Go ≥ 1.19
- MySQL ≥ 5.7
- Nginx (for web deployment)

### **Admin Portal - Local Development**
```bash
cd pgworld-master
flutter pub get
flutter run
```

### **Tenant Portal - Local Development**
```bash
cd pgworldtenant-master
flutter pub get
flutter run
```

### **API Backend - Local Development**
```bash
cd pgworld-master
go run main.go
```

## 📱 Deployment URLs

### **Production (AWS EC2)**
- **Admin Portal**: http://54.227.101.30/admin/
- **Tenant Portal**: http://54.227.101.30/tenant/
- **API Backend**: http://54.227.101.30:8080

### **Login Credentials**
**Admin:**
- Email: admin@example.com
- Password: admin123

**Tenant:**
- Email: priya@example.com
- Password: password123

## 📂 Project Structure

```
pgni/
├── pgworld-master/           # Admin Portal & API Backend
│   ├── lib/                  # Flutter source code
│   │   ├── screens/         # UI screens
│   │   ├── utils/           # Models, API, Config
│   │   └── main.dart        # Entry point
│   ├── main.go              # Go API server
│   ├── config.go            # API configuration
│   ├── user.go              # User management
│   └── pubspec.yaml         # Flutter dependencies
│
├── pgworldtenant-master/    # Tenant Portal
│   ├── lib/                 # Flutter source code
│   │   ├── screens/        # UI screens
│   │   ├── config/         # Configuration
│   │   ├── services/       # API services
│   │   └── main.dart       # Entry point
│   └── pubspec.yaml        # Flutter dependencies
│
└── README.md               # This file
```

## 🛠️ Technology Stack

- **Frontend**: Flutter 3.x, Dart 3.x
- **Backend**: Go (Golang)
- **Database**: MySQL
- **Web Server**: Nginx
- **Hosting**: AWS EC2
- **State Management**: Provider, SharedPreferences
- **HTTP Client**: Dart http package

## 📋 Key Features

### **Admin Portal**
✅ Dashboard with analytics
✅ Hostels Management (CRUD)
✅ Rooms Management
✅ Tenants/Users Management
✅ Bills & Payments
✅ Employee Management
✅ Notices & Announcements
✅ Reports & Analytics
✅ Settings & Configuration

### **Tenant Portal**
✅ Login & Profile
✅ Dashboard
✅ View Room Details
✅ Bills & Payment History
✅ Submit Issues/Complaints
✅ View Notices
✅ Food Menu
✅ Documents
✅ Settings

### **API Backend**
✅ RESTful API
✅ User Authentication
✅ CRUD Operations for all entities
✅ Data validation
✅ Error handling
✅ MySQL integration

## 🔧 Configuration

### **Database Setup**
```sql
CREATE DATABASE pgworld;
-- Tables will be created automatically or via migration scripts
```

### **Environment Variables**
Configure in `config.go` or `.env`:
- `DB_HOST`: Database host
- `DB_NAME`: Database name
- `DB_USER`: Database username
- `DB_PASS`: Database password
- `API_PORT`: API server port (default: 8080)

## 📞 Support

For issues or questions, contact the development team.

## 📄 License

Proprietary - All rights reserved.
EOF

echo -e "${GREEN}✓ README.md created${NC}"

echo ""
echo -e "${BLUE}[4/4] Summary of cleanup...${NC}"

# Count what's left
REMAINING_MD=$(find . -maxdepth 1 -name "*.md" | wc -l)
REMAINING_SH=$(find . -maxdepth 1 -name "*.sh" | wc -l)
REMAINING_PS1=$(find . -maxdepth 1 -name "*.ps1" | wc -l)
REMAINING_BAT=$(find . -maxdepth 1 -name "*.bat" | wc -l)

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                    CLEANUP COMPLETE! ✓                         ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo -e "${GREEN}📊 SUMMARY:${NC}"
echo ""
echo "Files Archived:"
echo "  📄 Markdown files:    $TOTAL_MD → $REMAINING_MD ($(($TOTAL_MD - $REMAINING_MD)) archived)"
echo "  🔧 Shell scripts:     $TOTAL_SH → $REMAINING_SH ($(($TOTAL_SH - $REMAINING_SH)) archived)"
echo "  💻 PowerShell scripts: $TOTAL_PS1 → $REMAINING_PS1 ($(($TOTAL_PS1 - $REMAINING_PS1)) archived)"
echo "  📦 Batch files:       $TOTAL_BAT → $REMAINING_BAT ($(($TOTAL_BAT - $REMAINING_BAT)) archived)"
echo ""
echo -e "${YELLOW}📁 Archived files location:${NC}"
echo "  $REPO_ROOT/$ARCHIVE_DIR/"
echo ""
echo -e "${GREEN}✅ Repository is now clean with only essential application files!${NC}"
echo ""
echo "Kept files:"
echo "  ✅ README.md (simplified)"
echo "  ✅ pgworld-master/ (Admin Portal & API)"
echo "  ✅ pgworldtenant-master/ (Tenant Portal)"
echo "  ✅ .git/ (version control)"
echo "  ✅ .gitignore"
echo ""
echo "You can safely delete the archive directory later if not needed:"
echo "  rm -rf $ARCHIVE_DIR"
echo ""
echo "═══════════════════════════════════════════════════════════════"

