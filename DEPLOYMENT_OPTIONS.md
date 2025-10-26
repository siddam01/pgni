# 🚀 Database Setup - Choose Your Method

## 📋 You Have 3 Options

All three methods do the same thing - set up your database with all tables and demo data. Choose based on your preference:

---

## **Option 1: Python Script (Recommended for You)** 🐍

### **Why This One?**
- ✅ Works on any operating system
- ✅ Handles passwords with special characters (`Omsairam951#`)
- ✅ Detailed, color-coded output
- ✅ Easy to customize if needed
- ✅ Most reliable

### **How to Run:**

```bash
# On your EC2 instance

# 1. Install Python MySQL connector
sudo pip3 install mysql-connector-python

# 2. Download and run the script
curl -O https://raw.githubusercontent.com/siddam01/pgni/main/fix-database.py
python3 fix-database.py
```

**When prompted:**
- RDS Endpoint: (from your `~/.pgni-config`)
- Database User: `admin`
- Database Password: `Omsairam951#`
- Database Name: `pgworld`

**Time:** ~2-3 minutes

---

## **Option 2: Bash Fix Script** 🔧

### **Why This One?**
- ✅ Automated - less input needed
- ✅ Handles passwords securely (credentials file)
- ✅ Also builds and deploys backend
- ✅ All-in-one solution

### **How to Run:**

```bash
bash <(curl -sL https://raw.githubusercontent.com/siddam01/pgni/main/fix-and-deploy.sh)
```

**When prompted:**
- Database Password: `Omsairam951#` (won't show - that's normal)

**Does:**
1. Tests database connection
2. Creates all tables
3. Inserts demo data
4. Builds Go backend
5. Starts API service

**Time:** ~5-7 minutes

---

## **Option 3: Manual SQL** 📝

### **Why This One?**
- ✅ Maximum control
- ✅ See exactly what's happening
- ✅ Can modify queries before running

### **How to Run:**

```bash
# 1. Get the SQL file
cd ~/pgni-deployment
rm -rf temp-repo
git clone https://github.com/siddam01/pgni.git temp-repo
cp temp-repo/pgworld-api-master/setup-database-simple.sql .

# 2. Run it
mysql -h YOUR_RDS_ENDPOINT -u admin -p pgworld < setup-database-simple.sql
# Enter password: Omsairam951#
```

**Time:** ~1-2 minutes (just database, no backend)

---

## 🎯 What All Methods Create

### **Tables (12 total):**
```
✅ admins (with RBAC columns)
✅ hostels
✅ rooms
✅ users (tenants)
✅ bills
✅ issues
✅ notices
✅ employees
✅ payments
✅ food
✅ otps
✅ admin_permissions (RBAC)
```

### **Demo Data:**
```
✅ 1 Admin
   - Username: admin
   - Password: admin123
   - Role: owner

✅ 1 Hostel
   - Name: Demo PG Hostel
   - Address: Hyderabad, Telangana

✅ 4 Rooms
   - 101 (Single, ₹5000)
   - 102 (Double, ₹4000)
   - 103 (Triple, ₹3500)
   - 104 (Single, ₹5500)

✅ 1 Tenant
   - Name: John Doe
   - Room: 101
   - Phone: 9123456789
```

---

## 📊 Quick Comparison

| Feature | Python | Bash | Manual SQL |
|---------|--------|------|------------|
| **Setup Time** | 2-3 min | 5-7 min | 1-2 min |
| **Deploys Backend** | ❌ No | ✅ Yes | ❌ No |
| **Password Handling** | ✅ Secure | ✅ Secure | ⚠️ Visible |
| **Error Messages** | ✅ Detailed | ✅ Good | ⚠️ Basic |
| **Cross-platform** | ✅ Yes | ❌ Linux only | ❌ Linux only |
| **Customizable** | ✅ Easy | ⚠️ Limited | ✅ Easy |
| **Dependency** | Python + pip | Bash + mysql | mysql client |

---

## 🎯 My Recommendation

Based on your situation:

### **Use Python Script** if:
- You want the most reliable method
- You're comfortable with Python
- You want detailed progress output
- You might need to customize later

### **Use Bash Script** if:
- You want one command to do everything
- You're okay with less visibility
- You want backend deployed automatically

### **Use Manual SQL** if:
- You want full control
- You're experienced with MySQL
- You want to see/modify the SQL first

---

## ⚡ Quick Start (Python - Recommended)

**Copy-paste this on your EC2:**

```bash
sudo pip3 install mysql-connector-python && \
curl -O https://raw.githubusercontent.com/siddam01/pgni/main/fix-database.py && \
python3 fix-database.py
```

Then enter your RDS details when prompted.

---

## 🔍 After Database Setup

Once your database is set up (whichever method), you need to deploy the backend:

```bash
cd ~/pgni-deployment/pgworld-api-master

# Create .env file (use your actual values)
cat > .env << EOF
DB_HOST=your-rds-endpoint.us-east-1.rds.amazonaws.com
DB_PORT=3306
DB_USER=admin
DB_PASSWORD=Omsairam951#
DB_NAME=pgworld
PORT=8080
CONNECTION_POOL=10
ENV=production
S3_BUCKET=pgworld-admin-uploads
AWS_REGION=us-east-1
EOF

chmod 600 .env

# Build backend
/usr/local/go/bin/go build -o pgworld-api main.go

# Start service
sudo systemctl restart pgworld-api

# Test
curl http://localhost:8080/

# Check logs
sudo journalctl -u pgworld-api -f
```

---

## 🧪 Verify Database Setup

After running any method:

```bash
# Check connection
mysql -h YOUR_RDS_ENDPOINT -u admin -p

# Once connected:
USE pgworld;
SHOW TABLES;  -- Should show 12 tables
SELECT * FROM admins;  -- Should show 1 admin
SELECT * FROM rooms;  -- Should show 4 rooms
exit
```

---

## 📞 Support

**Database setup successful?** → Continue with backend deployment  
**Getting errors?** → Share the error message and which method you used

---

## ✅ All Files Committed and Pushed

**Commit:** `c58ed5b`  
**Branch:** `main`  
**GitHub:** https://github.com/siddam01/pgni

**Files Added:**
- `fix-database.py` - Python migration script
- `PYTHON_MIGRATION_GUIDE.md` - Comprehensive Python guide
- `FOREIGN_KEY_FIX.md` - Foreign key issue explanation
- `DATABASE_SETUP_FIXED.md` - Database setup guide

**Previous Files:**
- `fix-and-deploy.sh` - Bash automated deployment
- `test-db-connection.sh` - Connection test utility
- `EC2_DEPLOY_MASTER.sh` - Full deployment script
- `setup-database-simple.sql` - SQL migration file

---

## 🎉 Ready to Go!

**Pick your method above and run it. Your database will be set up in a few minutes!**

All three methods have been tested and work. Choose the one that makes you most comfortable. 💪

