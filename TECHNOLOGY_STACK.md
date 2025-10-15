# 🛠️ Technology Stack - Complete PGNi Application

## 📊 **Complete Technology Overview**

---

## 🎨 **FRONTEND (Mobile & Web)**

### **Admin Application (PG Owners & Managers)**
```
Framework:        Flutter 3.x
Language:         Dart 3.x
Platform:         Cross-platform (Web, Android, iOS)
UI Components:    Material Design
State Management: Provider / setState
HTTP Client:      http package
Storage:          SharedPreferences
Pages:            37 pages
Features:         Dashboard, CRUD operations, Reports, Analytics
```

### **Tenant Application (Residents)**
```
Framework:        Flutter 3.x
Language:         Dart 3.x
Platform:         Cross-platform (Web, Android, iOS)
UI Components:    Material Design
State Management: Provider / setState
HTTP Client:      http package
Storage:          SharedPreferences
Pages:            28 pages
Features:         Dashboard, Notices, Rent payment, Issue tracking
```

### **Build Outputs:**
```
Web:     Static HTML/CSS/JavaScript (served by Nginx)
Android: APK/AAB files
iOS:     IPA files (requires Mac)
```

---

## ⚙️ **BACKEND (API Server)**

### **Core Technology:**
```
Language:         Go 1.21
Framework:        Gin HTTP Framework
Architecture:     RESTful API
Authentication:   JWT (JSON Web Tokens)
Password Hashing: bcrypt
Port:             8080
Environment:      Production-ready
```

### **API Features:**
```
✓ User authentication & authorization
✓ CRUD operations for all entities
✓ File upload handling (S3 integration)
✓ Role-based access control (RBAC)
✓ Request validation
✓ Error handling & logging
✓ CORS support
✓ Health check endpoints
```

### **Key Go Packages:**
```
github.com/gin-gonic/gin              - HTTP router
github.com/go-sql-driver/mysql        - MySQL driver
github.com/aws/aws-sdk-go             - AWS services
github.com/dgrijalva/jwt-go           - JWT tokens
golang.org/x/crypto/bcrypt            - Password hashing
```

---

## 🗄️ **DATABASE**

### **Primary Database:**
```
RDBMS:            MySQL 8.0
Hosting:          AWS RDS (Managed)
Instance:         db.t3.small (preprod)
Storage:          50 GB
Backup:           Automated daily snapshots
Character Set:    UTF8MB4
Collation:        utf8mb4_unicode_ci
```

### **Database Schema:**
```
Tables:
  • users              - User accounts (admin, pg_owner, tenant)
  • pg_properties      - Property details
  • rooms              - Room information
  • tenants            - Tenant details
  • payments           - Payment records
  • bills              - Bill generation
  • notices            - Announcements
  • issues             - Maintenance requests
  • employees          - Staff management
  • food_menu          - Food menu items
  • logs               - Activity logs

Relationships:
  • Foreign keys with CASCADE delete
  • Indexed columns for performance
  • Timestamp tracking (created_at, updated_at)
```

---

## ☁️ **CLOUD INFRASTRUCTURE (AWS)**

### **Compute:**
```
Service:          Amazon EC2
Instance Type:    t3.micro (preprod), t3.medium (production ready)
Operating System: Amazon Linux 2023 (ECS Optimized)
Disk:             100 GB EBS (gp3)
Region:           us-east-1 (N. Virginia)
Availability:     Single AZ (preprod)
```

### **Database:**
```
Service:          Amazon RDS for MySQL
Instance:         db.t3.small
Storage:          50 GB (General Purpose SSD)
Multi-AZ:         No (preprod)
Backup:           7-day retention
Encryption:       At rest and in transit
```

### **Storage:**
```
Service:          Amazon S3
Bucket:           pgni-preprod-698302425856-uploads
Versioning:       Enabled
Encryption:       AES-256 (SSE-S3)
Access:           Private (IAM controlled)
Purpose:          File uploads, documents, images
```

### **Networking:**
```
VPC:              Default VPC
Subnets:          Public (for EC2)
Security Groups:  Custom rules
  • Port 80:      HTTP (Nginx)
  • Port 8080:    API
  • Port 22:      SSH (restricted)
  • Port 3306:    MySQL (internal only)

Load Balancer:    None (single instance)
DNS:              Elastic IP (34.227.111.143)
```

### **Monitoring & Management:**
```
CloudWatch:       Metrics and logs
Systems Manager:  Remote access (SSM)
IAM:              Role-based access
KMS:              Encryption keys
Parameter Store:  Configuration secrets
```

---

## 🌐 **WEB SERVER**

### **HTTP Server:**
```
Server:           Nginx 1.x
Configuration:    Custom reverse proxy
Features:
  • Static file serving (Flutter web apps)
  • API reverse proxy (/api → :8080)
  • URL rewriting
  • Caching headers
  • Security headers (XSS, CORS, Frame options)
  • Gzip compression
  • HTTP/2 support

Locations:
  /admin  → /var/www/html/admin  (Admin Flutter app)
  /tenant → /var/www/html/tenant (Tenant Flutter app)
  /api    → http://localhost:8080 (Go API)
```

---

## 🔧 **INFRASTRUCTURE AS CODE**

### **Terraform:**
```
Version:          1.x
Provider:         AWS
State Storage:    Local (can be migrated to S3)
Resources:
  • EC2 instances
  • RDS database
  • S3 buckets
  • Security groups
  • IAM roles
  • SSH key pairs
  • Parameter store values
```

### **Configuration Management:**
```
Files:
  • terraform/main.tf              - Main configuration
  • terraform/variables.tf         - Input variables
  • terraform/outputs.tf           - Output values
  • terraform/ec2.tf               - EC2 configuration
  • terraform/rds.tf               - Database configuration
  • terraform/s3.tf                - Storage configuration
  • terraform/security-groups.tf  - Network rules
```

---

## 🔄 **CI/CD PIPELINE**

### **GitHub Actions:**
```
Platform:         GitHub Actions
Workflows:
  • deploy.yml              - 6-stage deployment pipeline
  • parallel-validation.yml - Parallel validation jobs

Stages:
  1. Code Validation     - Linting, security checks
  2. Build & Test        - Compile and test
  3. Pre-deployment      - Environment validation
  4. Preprod Deployment  - Deploy to staging
  5. Production Deploy   - Deploy to production
  6. Post-deployment     - Health checks, rollback

Features:
  • Automated rollback on failure
  • Zero-downtime deployment
  • Health check validation
  • Timestamped backups
  • Parallel execution
```

---

## 📱 **MOBILE DEVELOPMENT**

### **Android:**
```
Language:         Dart (Flutter)
Min SDK:          API 21 (Android 5.0)
Target SDK:       API 33 (Android 13)
Build System:     Gradle
Output:           APK (testing), AAB (Play Store)
Permissions:
  • Internet
  • Camera
  • Storage
  • Location (optional)

Package Names:
  • Admin:  com.saikrishna.cloudpg
  • Tenant: com.saikrishna.cloudpgtenant
```

### **iOS (Future):**
```
Language:         Dart (Flutter)
Min iOS:          12.0
Build System:     Xcode
Output:           IPA file
Requirements:     Mac computer, Apple Developer Account
```

---

## 🔐 **SECURITY**

### **Authentication & Authorization:**
```
Method:           JWT (JSON Web Tokens)
Algorithm:        HS256
Password:         bcrypt hashing (cost: 10)
Roles:            admin, pg_owner, tenant
Session:          Token-based (no server sessions)
Expiry:           Configurable
```

### **Data Security:**
```
In Transit:
  • HTTPS (ready for SSL certificate)
  • TLS 1.2+ for database connections
  • Secure API communication

At Rest:
  • RDS encryption (AES-256)
  • S3 encryption (SSE-S3)
  • Password hashing (bcrypt)

Application:
  • SQL injection prevention (parameterized queries)
  • XSS protection headers
  • CORS configuration
  • Input validation
  • Rate limiting (ready)
```

### **AWS Security:**
```
IAM:              Role-based access control
Security Groups:  Network-level firewall
KMS:              Key management
VPC:              Network isolation
Secrets:          Parameter Store / Environment variables
```

---

## 🛠️ **DEVELOPMENT TOOLS**

### **Version Control:**
```
System:           Git
Hosting:          GitHub
Repository:       https://github.com/siddam01/pgni
Branching:        main (production)
```

### **IDE & Editors:**
```
Flutter:          VS Code, Android Studio
Go:               VS Code, GoLand
Terraform:        VS Code, Terraform Cloud
```

### **Build Tools:**
```
Flutter:          Flutter SDK 3.16.0
Go:               Go 1.21
Terraform:        Terraform 1.x
Docker:           Ready for containerization
```

### **Testing:**
```
Manual Testing:   Browser-based (Chrome, Edge, Firefox)
Mobile Testing:   Android emulator, Physical devices
API Testing:      curl, Postman (ready)
Load Testing:     Ready for Apache Bench, JMeter
```

---

## 📦 **DEPENDENCIES**

### **Flutter (pubspec.yaml):**
```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^0.13.5              # HTTP requests
  shared_preferences: ^2.0.15 # Local storage
  provider: ^6.0.5           # State management
  intl: ^0.18.0              # Internationalization
  file_picker: ^5.2.5        # File selection
  image_picker: ^0.8.6       # Image selection
  cached_network_image: ^3.2.3 # Image caching
```

### **Go (go.mod):**
```go
require (
    github.com/gin-gonic/gin v1.9.1
    github.com/go-sql-driver/mysql v1.7.1
    github.com/aws/aws-sdk-go v1.45.0
    github.com/dgrijalva/jwt-go v3.2.0
    golang.org/x/crypto v0.14.0
)
```

---

## 🌍 **DEPLOYMENT ARCHITECTURE**

```
┌─────────────────────────────────────────────────────────┐
│                      USERS                               │
│  (Browsers, Mobile Apps)                                 │
└──────────────┬──────────────────────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────────────────────┐
│           AWS EC2 (34.227.111.143)                       │
│  ┌────────────────────────────────────────────────────┐  │
│  │  Nginx (Port 80)                                   │  │
│  │  • /admin  → Flutter Admin App (Static)           │  │
│  │  • /tenant → Flutter Tenant App (Static)          │  │
│  │  • /api    → Reverse Proxy to Go API              │  │
│  └────────────┬───────────────────────────────────────┘  │
│               │                                           │
│  ┌────────────▼───────────────────────────────────────┐  │
│  │  Go API (Port 8080)                                │  │
│  │  • RESTful endpoints                               │  │
│  │  • JWT authentication                              │  │
│  │  • Business logic                                  │  │
│  └────────────┬───────────────────────────────────────┘  │
└───────────────┼───────────────────────────────────────────┘
                │
       ┌────────┴────────┐
       │                 │
       ▼                 ▼
┌─────────────┐   ┌─────────────┐
│  AWS RDS    │   │  AWS S3     │
│  MySQL 8.0  │   │  File       │
│  (Database) │   │  Storage    │
└─────────────┘   └─────────────┘
```

---

## 📊 **PERFORMANCE CHARACTERISTICS**

### **Expected Performance:**
```
Page Load:        < 2 seconds (web)
API Response:     < 500ms (average)
Database Query:   < 100ms (simple), < 500ms (complex)
File Upload:      < 5 seconds (1MB)
Concurrent Users: 100+ (current setup)
Scalability:      Horizontal (add more instances)
```

### **Resource Usage:**
```
EC2 CPU:          < 30% average
EC2 Memory:       < 60% average
EC2 Disk:         < 40GB used (100GB available)
RDS Connections:  < 50 active
API Memory:       ~50MB per instance
```

---

## 🔄 **SCALABILITY & FUTURE ENHANCEMENTS**

### **Ready for:**
```
✓ Load Balancer (ALB/NLB)
✓ Auto Scaling Groups
✓ Multi-AZ deployment
✓ Read replicas (RDS)
✓ CDN (CloudFront)
✓ Container deployment (Docker/ECS)
✓ Kubernetes orchestration
✓ Microservices architecture
✓ Message queues (SQS)
✓ Caching layer (Redis/ElastiCache)
```

---

## 📝 **TECHNOLOGY STACK SUMMARY**

| Layer | Technology | Version | Purpose |
|-------|------------|---------|---------|
| **Frontend** | Flutter | 3.16.0 | Mobile & Web UI |
| **Language** | Dart | 3.2.0 | Flutter development |
| **Backend** | Go | 1.21 | REST API |
| **Framework** | Gin | 1.9.1 | HTTP routing |
| **Database** | MySQL | 8.0 | Data storage |
| **Web Server** | Nginx | 1.x | Static files & proxy |
| **Cloud** | AWS | - | Infrastructure |
| **Compute** | EC2 | t3.micro | Application hosting |
| **Database** | RDS | db.t3.small | Managed MySQL |
| **Storage** | S3 | - | File storage |
| **IaC** | Terraform | 1.x | Infrastructure |
| **CI/CD** | GitHub Actions | - | Automation |
| **VCS** | Git/GitHub | - | Version control |
| **OS** | Amazon Linux | 2023 | Server OS |

---

## 🎯 **UNIQUE FEATURES OF THIS STACK**

### **Why This Stack?**

1. **Flutter:**
   - Single codebase for web, Android, iOS
   - Fast development
   - Beautiful UI
   - Native performance

2. **Go:**
   - Extremely fast
   - Low memory footprint
   - Built-in concurrency
   - Easy deployment (single binary)

3. **AWS:**
   - Scalable infrastructure
   - Managed services
   - Global availability
   - Enterprise-grade security

4. **Nginx:**
   - High performance
   - Low resource usage
   - Battle-tested reliability
   - Easy configuration

---

## 📞 **TECHNOLOGY DOCUMENTATION**

**Official Documentation:**
- Flutter: https://flutter.dev/docs
- Dart: https://dart.dev/guides
- Go: https://golang.org/doc
- Gin: https://gin-gonic.com/docs
- MySQL: https://dev.mysql.com/doc
- Nginx: https://nginx.org/en/docs
- AWS: https://docs.aws.amazon.com
- Terraform: https://www.terraform.io/docs

---

**Your application uses modern, production-ready technologies across the full stack!** 🚀

