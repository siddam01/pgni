# PowerShell script to cleanup non-essential files locally

Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   LOCAL CLEANUP: Remove Non-Essential Documentation & Scripts ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

$repoRoot = "C:\MyFolder\Mytest\pgworld-master"
Set-Location $repoRoot

Write-Host "[1/4] Creating archive for documentation and scripts..." -ForegroundColor Blue
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$archiveDir = "docs_scripts_archive_$timestamp"
New-Item -ItemType Directory -Path $archiveDir -Force | Out-Null
Write-Host "✓ Archive directory created: $archiveDir" -ForegroundColor Green

Write-Host ""
Write-Host "[2/4] Moving non-essential files to archive..." -ForegroundColor Blue

# Count files before
$mdFiles = Get-ChildItem -Path . -Filter "*.md" -File | Where-Object { $_.Name -ne "README.md" }
$shFiles = Get-ChildItem -Path . -Filter "*.sh" -File
$ps1Files = Get-ChildItem -Path . -Filter "*.ps1" -File | Where-Object { $_.Name -ne "CLEANUP_EXTRA_FILES_LOCAL.ps1" }
$batFiles = Get-ChildItem -Path . -Filter "*.bat" -File
$txtFiles = Get-ChildItem -Path . -Filter "*.txt" -File

Write-Host "Found:"
Write-Host "  - $($mdFiles.Count) documentation files (.md, excluding README.md)"
Write-Host "  - $($shFiles.Count) shell scripts (.sh)"
Write-Host "  - $($ps1Files.Count) PowerShell scripts (.ps1)"
Write-Host "  - $($batFiles.Count) batch files (.bat)"
Write-Host "  - $($txtFiles.Count) text files (.txt)"
Write-Host ""

# Move files
Write-Host "Moving .md files (keeping README.md)..."
$mdFiles | Move-Item -Destination $archiveDir -Force

Write-Host "Moving .sh files..."
$shFiles | Move-Item -Destination $archiveDir -Force

Write-Host "Moving .ps1 files (keeping this script)..."
$ps1Files | Move-Item -Destination $archiveDir -Force

Write-Host "Moving .bat files..."
$batFiles | Move-Item -Destination $archiveDir -Force

Write-Host "Moving .txt files..."
$txtFiles | Move-Item -Destination $archiveDir -Force

# Move old archive/backup directories
Write-Host "Moving old archive/backup directories..."
Get-ChildItem -Path . -Directory | Where-Object { 
    ($_.Name -like "archive*" -or $_.Name -like "*backup*") -and 
    ($_.Name -ne $archiveDir)
} | ForEach-Object {
    Move-Item -Path $_.FullName -Destination $archiveDir -Force -ErrorAction SilentlyContinue
}

Write-Host "✓ Files moved to archive" -ForegroundColor Green

Write-Host ""
Write-Host "[3/4] Creating simplified README.md..." -ForegroundColor Blue

$readmeContent = @"
# CloudPG - PG/Hostel Management System

A comprehensive solution for managing PG accommodations and hostels.

## 🏢 System Components

### **1. Admin Portal**
- **Location**: ``pgworld-master/``
- **Purpose**: PG Owner/Admin management interface
- **Features**: Manage hostels, rooms, tenants, bills, employees, notices, reports
- **Technology**: Flutter (Mobile & Web)

### **2. Tenant Portal**
- **Location**: ``pgworldtenant-master/``
- **Purpose**: Tenant/Resident mobile app
- **Features**: View room details, bills, notices, submit issues, food menu
- **Technology**: Flutter (Mobile & Web)

### **3. API Backend**
- **Location**: ``pgworld-master/`` (Go files)
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
``````bash
cd pgworld-master
flutter pub get
flutter run
``````

### **Tenant Portal - Local Development**
``````bash
cd pgworldtenant-master
flutter pub get
flutter run
``````

### **API Backend - Local Development**
``````bash
cd pgworld-master
go run main.go
``````

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

``````
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
``````

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
``````sql
CREATE DATABASE pgworld;
-- Tables will be created automatically or via migration scripts
``````

### **Environment Variables**
Configure in ``config.go`` or ``.env``:
- ``DB_HOST``: Database host
- ``DB_NAME``: Database name
- ``DB_USER``: Database username
- ``DB_PASS``: Database password
- ``API_PORT``: API server port (default: 8080)

## 📞 Support

For issues or questions, contact the development team.

## 📄 License

Proprietary - All rights reserved.
"@

Set-Content -Path "README.md" -Value $readmeContent -Force
Write-Host "✓ README.md created" -ForegroundColor Green

Write-Host ""
Write-Host "[4/4] Summary of cleanup..." -ForegroundColor Blue

$remainingMd = (Get-ChildItem -Path . -Filter "*.md" -File).Count
$remainingSh = (Get-ChildItem -Path . -Filter "*.sh" -File).Count
$remainingPs1 = (Get-ChildItem -Path . -Filter "*.ps1" -File).Count
$remainingBat = (Get-ChildItem -Path . -Filter "*.bat" -File).Count

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                    CLEANUP COMPLETE! ✓                         ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "📊 SUMMARY:" -ForegroundColor Green
Write-Host ""
Write-Host "Files Archived:"
Write-Host "  📄 Markdown files:     $($mdFiles.Count) → $remainingMd ($($mdFiles.Count - $remainingMd) archived)"
Write-Host "  🔧 Shell scripts:      $($shFiles.Count) → $remainingSh ($($shFiles.Count - $remainingSh) archived)"
Write-Host "  💻 PowerShell scripts: $($ps1Files.Count) → $remainingPs1 ($($ps1Files.Count - $remainingPs1) archived)"
Write-Host "  📦 Batch files:        $($batFiles.Count) → $remainingBat ($($batFiles.Count - $remainingBat) archived)"
Write-Host ""
Write-Host "📁 Archived files location:" -ForegroundColor Yellow
Write-Host "  $repoRoot\$archiveDir\"
Write-Host ""
Write-Host "✅ Repository is now clean with only essential application files!" -ForegroundColor Green
Write-Host ""
Write-Host "Kept files:"
Write-Host "  ✅ README.md (simplified)"
Write-Host "  ✅ pgworld-master/ (Admin Portal & API)"
Write-Host "  ✅ pgworldtenant-master/ (Tenant Portal)"
Write-Host "  ✅ .git/ (version control)"
Write-Host "  ✅ .gitignore"
Write-Host ""
Write-Host "You can safely delete the archive directory later if not needed:"
Write-Host "  Remove-Item -Recurse -Force $archiveDir"
Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════════"
Write-Host ""
Write-Host "Press any key to continue..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

