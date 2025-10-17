# PG World - PG Management System

A comprehensive Paying Guest (PG) management system with Admin, Tenant, and PG Owner portals.

## 🚀 Quick Start

### **Your Application URL:**
```
http://13.221.117.236/admin/
```

### **Login Credentials:**
```
Email:    admin@pgworld.com
Password: Admin@123
```

---

## 📁 Project Structure

```
pgworld-master/
├── pgworld-api-master/        # Backend API (Go)
├── pgworld-master/            # Admin App (Flutter)
├── pgworldtenant-master/      # Tenant App (Flutter)
├── terraform/                 # AWS Infrastructure
├── .github/workflows/         # CI/CD Pipelines
│
├── FIX_WITH_MANUAL_IP.sh      # ⭐ Main deployment script
├── SIMPLE_BUILD_AND_DEPLOY.sh # Alternative deployment
└── FIX_NGINX_ACCESS.sh        # Network troubleshooting
```

---

## 🔧 Deployment

### **Full Deployment - Both Apps (Recommended)**

Run this on your EC2 instance to fix blank screens and deploy both apps:

```bash
bash <(curl -sL https://raw.githubusercontent.com/siddam01/pgni/main/FIX_BOTH_APPS.sh)
```

This will:
- ✅ Configure both Admin & Tenant apps with correct IP
- ✅ Build both apps with proper base-href
- ✅ Deploy to Nginx at /admin/ and /tenant/
- ✅ Fix blank screen issues
- ✅ Verify all services

**⏱️ Time: 6-8 minutes (parallel builds)**

---

## 🌐 Access Points

| Application | URL | Purpose |
|-------------|-----|---------|
| **Admin Portal** | http://13.221.117.236/admin/ | Main admin dashboard |
| **Tenant Portal** | http://13.221.117.236/tenant/ | Tenant application |
| **Backend API** | http://13.221.117.236:8080/ | REST API |

---

## 🔐 User Accounts

| Role | Email | Password |
|------|-------|----------|
| Admin | admin@pgworld.com | Admin@123 |
| PG Owner | owner@pgworld.com | Owner@123 |
| Tenant | tenant@pgworld.com | Tenant@123 |

---

## 🏗️ Infrastructure

- **Provider:** AWS
- **Instance:** c3.large (EC2)
- **Database:** RDS MySQL
- **Storage:** S3
- **Web Server:** Nginx
- **Region:** us-east-1

---

## 🛠️ Technology Stack

### Backend
- **Language:** Go 1.21
- **Database:** MySQL 8.0
- **API:** RESTful

### Frontend
- **Framework:** Flutter 3.35.6
- **Language:** Dart 3.9.2
- **Platforms:** Web, Android, iOS

### DevOps
- **IaC:** Terraform
- **CI/CD:** GitHub Actions
- **Web Server:** Nginx
- **SSL:** (To be configured)

---

## 📚 Features

### Admin Portal
- Dashboard with analytics
- User management (PG owners, tenants)
- Property management
- Room allocation
- Billing & payments
- Reports & analytics
- Notice board
- Issue tracking

### Tenant Portal
- Room details
- Rent payment status
- Issue reporting
- Notice viewing
- Profile management

### PG Owner Portal
- Property management
- Tenant management
- Room availability
- Revenue tracking
- Maintenance requests

---

## 🔍 Troubleshooting

### App not accessible from outside?

1. **Check Security Group:**
   - Go to AWS Console → EC2 → Security Groups
   - Ensure port 80 (HTTP) is open to 0.0.0.0/0

2. **Verify Nginx:**
   ```bash
   sudo systemctl status nginx
   curl http://localhost/admin/
   ```

3. **Check logs:**
   ```bash
   sudo tail -50 /var/log/nginx/error.log
   ```

### Need to rebuild?

```bash
bash <(curl -sL https://raw.githubusercontent.com/siddam01/pgni/main/SIMPLE_BUILD_AND_DEPLOY.sh)
```

---

## 📞 Support

For issues or questions, check:
- GitHub Issues: https://github.com/siddam01/pgni/issues
- Deployment logs on EC2: `/tmp/pgni_build_logs/`

---

## 📝 License

Proprietary - All rights reserved

---

## 🎯 Next Steps

1. ✅ **Test Admin app:** http://13.221.117.236/admin/
2. ✅ **Test Tenant app:** http://13.221.117.236/tenant/
3. ✅ **Login with test credentials**
4. ⏳ **Set up SSL certificate** (for HTTPS)
5. ⏳ **Configure custom domain**
6. ⏳ **Set up automated backups**
7. ⏳ **Configure production database**

---

## 📦 Archived Files

Old documentation and scripts have been moved to `archive_backup_*/` folders.
These can be safely deleted or kept for reference.

---

**Last Updated:** October 17, 2025
