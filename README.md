# CloudPG - PG/Hostel Management System

A comprehensive solution for managing PG (Paying Guest) accommodations and hostels.

## 🏢 System Components

### 1. Admin Portal
- **Location**: `pgworld-master/`
- **Purpose**: PG Owner/Admin management interface
- **Features**: Manage hostels, rooms, tenants, bills, employees, notices, reports
- **Technology**: Flutter (Mobile & Web)
- **Deployed**: http://54.227.101.30/admin/

### 2. Tenant Portal
- **Location**: `pgworldtenant-master/`
- **Purpose**: Tenant/Resident mobile app
- **Features**: View room details, bills, notices, submit issues, food menu
- **Technology**: Flutter (Mobile & Web)
- **Deployed**: http://54.227.101.30/tenant/

### 3. API Backend
- **Location**: `pgworld-api-master/`
- **Purpose**: REST API server
- **Technology**: Go (Golang)
- **Database**: MySQL (AWS RDS)
- **API URL**: http://54.227.101.30:8080

## 🚀 Quick Start

### Prerequisites
- Flutter SDK ≥ 3.24.x
- Dart SDK ≥ 3.4.x
- Go ≥ 1.19
- MySQL ≥ 5.7

### Admin Portal - Local Development
```bash
cd pgworld-master
flutter pub get
flutter run
```

### Tenant Portal - Local Development
```bash
cd pgworldtenant-master
flutter pub get
flutter run
```

### API Backend - Local Development
```bash
cd pgworld-api-master
go run main.go
```

## 📱 Production Deployment

### Login Credentials

**Admin Portal:**
- URL: http://54.227.101.30/admin/
- Email: admin@example.com
- Password: admin123

**Tenant Portal:**
- URL: http://54.227.101.30/tenant/
- Email: priya@example.com
- Password: password123

## 📂 Project Structure

```
pgni/
├── pgworld-master/              # Admin Portal (Flutter + Go API)
│   ├── lib/                     # Flutter source code
│   │   ├── screens/            # UI screens (37 screens)
│   │   ├── utils/              # Models, API, Config
│   │   └── main.dart           # Entry point
│   ├── main_solution.go        # Go API server
│   ├── config.go               # API configuration
│   ├── user.go                 # User management
│   └── pubspec.yaml            # Flutter dependencies
│
├── pgworldtenant-master/       # Tenant Portal (Flutter)
│   ├── lib/                    # Flutter source code
│   │   ├── screens/           # UI screens (16 screens)
│   │   ├── config/            # Configuration
│   │   └── main.dart          # Entry point
│   └── pubspec.yaml           # Flutter dependencies
│
├── pgworld-api-master/         # Go API Backend
│   ├── main.go                # Main server
│   ├── user.go                # User routes
│   ├── hostel.go              # Hostel routes
│   └── ...                    # Other route handlers
│
├── terraform/                  # Infrastructure as Code
│   ├── main.tf                # AWS infrastructure
│   └── ...                    # Terraform configs
│
└── USER_GUIDES/               # User Documentation
    ├── 1_PG_OWNER_GUIDE.md   # For PG owners
    ├── 2_TENANT_GUIDE.md     # For tenants
    └── ...                    # Other guides
```

## 🛠️ Technology Stack

- **Frontend**: Flutter 3.x, Dart 3.x
- **Backend**: Go (Golang)
- **Database**: MySQL (AWS RDS)
- **Web Server**: Nginx
- **Hosting**: AWS EC2
- **Infrastructure**: Terraform
- **State Management**: Provider, SharedPreferences
- **HTTP Client**: Dart http package

## 📋 Key Features

### Admin Portal
✅ Dashboard with analytics  
✅ Hostels Management (CRUD)  
✅ Rooms Management  
✅ Tenants/Users Management  
✅ Bills & Payments  
✅ Employee Management  
✅ Notices & Announcements  
✅ Reports & Analytics  
✅ Settings & Configuration  

### Tenant Portal
✅ Login & Profile  
✅ Dashboard  
✅ View Room Details  
✅ Bills & Payment History  
✅ Submit Issues/Complaints  
✅ View Notices  
✅ Food Menu  
✅ Documents  
✅ Settings  

### API Backend
✅ RESTful API  
✅ User Authentication  
✅ CRUD Operations for all entities  
✅ Data validation  
✅ Error handling  
✅ MySQL integration  

## 🔧 Configuration

### Database
- Host: database-pgni.cezawkgguojl.us-east-1.rds.amazonaws.com
- Database: pgworld
- Configured in: `pgworld-api-master/config.go`

### Environment Variables
Set in `config.go`:
- `DB_HOST`: Database host
- `DB_NAME`: Database name
- `DB_USER`: Database username
- `DB_PASS`: Database password
- `API_PORT`: API server port (default: 8080)

## 📚 Documentation

Detailed guides are available in the `USER_GUIDES/` directory:

- **Getting Started**: `0_GETTING_STARTED.md`
- **PG Owner Guide**: `1_PG_OWNER_GUIDE.md`
- **Tenant Guide**: `2_TENANT_GUIDE.md`
- **Admin Guide**: `3_ADMIN_GUIDE.md`
- **Mobile App Configuration**: `4_MOBILE_APP_CONFIGURATION.md`

## 🚀 Deployment

### Automated Deployment to EC2

The application is deployed on AWS EC2 using Nginx. To deploy updates:

1. **Connect to EC2** (via SSH or AWS Session Manager)
2. **Navigate to project**: `cd /home/ec2-user/pgni`
3. **Pull latest code**: `git pull origin main`
4. **Build & Deploy**: Run deployment scripts in `pgworld-master/`

### Infrastructure Management

Infrastructure is managed using Terraform in the `terraform/` directory.

## 📊 Architecture

```
┌─────────────┐         ┌─────────────┐         ┌─────────────┐
│   Admin     │         │   Tenant    │         │  API Server │
│   Portal    │────────▶│   Portal    │────────▶│   (Go)      │
│  (Flutter)  │         │  (Flutter)  │         │             │
└─────────────┘         └─────────────┘         └──────┬──────┘
                                                        │
                                                        │
                                                        ▼
                                                 ┌─────────────┐
                                                 │   MySQL DB  │
                                                 │  (AWS RDS)  │
                                                 └─────────────┘
```

## 📞 Support

For technical support or questions, refer to the documentation in the `USER_GUIDES/` directory.

## 📄 License

Proprietary - All rights reserved.

---

## 📁 Archived Files

Documentation and deployment scripts have been archived in:
- `archived_docs_scripts_YYYYMMDD_HHMMSS/`

This folder contains all previous documentation, deployment scripts, and historical files that were moved to keep the repository clean.
