# 🐍 Python Database Migration Guide

## 📋 Overview

This Python script provides an alternative approach to fix the database schema issues. It's useful if you prefer Python over bash/SQL scripts, or if you want more control over the migration process.

---

## 🚀 Quick Start

### **On Your EC2 Instance:**

```bash
# 1. Install Python MySQL connector
sudo pip3 install mysql-connector-python

# 2. Download the script
curl -O https://raw.githubusercontent.com/siddam01/pgni/main/fix-database.py

# 3. Make it executable
chmod +x fix-database.py

# 4. Run it
python3 fix-database.py
```

### **Interactive Prompts:**

The script will ask for:
- **RDS Endpoint**: Your RDS hostname
- **Database User**: `admin` (default)
- **Database Password**: `Omsairam951#`
- **Database Name**: `pgworld` (default)

---

## 🎯 What the Script Does

### **Step 1: Connection**
- ✅ Connects to your RDS MySQL database
- ✅ Validates connection and permissions
- ✅ Shows MySQL server version

### **Step 2: Table Creation**
Creates all tables in the correct order:
1. ✅ `admins` (with RBAC columns)
2. ✅ `hostels`
3. ✅ `rooms` (with hostel_id column)
4. ✅ `users` (tenants)
5. ✅ `bills`, `issues`, `notices`, `employees`
6. ✅ `otps`, `payments`, `food`
7. ✅ `admin_permissions` (RBAC)

### **Step 3: Demo Data**
Inserts demo data:
- ✅ 1 Admin (username: `admin`, password: `admin123`)
- ✅ 1 Hostel (Demo PG Hostel)
- ✅ 4 Rooms (101, 102, 103, 104)
- ✅ 1 Tenant (John Doe in Room 101)

### **Step 4: Verification**
- ✅ Shows record counts for all tables
- ✅ Displays demo login credentials
- ✅ Confirms successful completion

---

## 💻 Example Run

```bash
$ python3 fix-database.py

╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║    PG/Hostel Management - Database Migration             ║
║    Python Edition                                        ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝

ℹ️  Enter database connection details:

RDS Endpoint: your-db.xxxxxxxxxxxx.us-east-1.rds.amazonaws.com
Database User [admin]: admin
Database Password: Omsairam951#
Database Name [pgworld]: pgworld

============================================================
STEP 1: Connecting to Database
============================================================

✅ Connected to MySQL Server version 8.0.35
✅ Connected to database: pgworld

============================================================
STEP 2: Creating Base Tables
============================================================

✅ Table 'admins' created/verified
✅ Table 'hostels' created/verified
✅ Table 'rooms' created/verified
✅ Table 'users' created/verified

============================================================
STEP 3: Creating Remaining Tables
============================================================

✅ All remaining tables created/verified

============================================================
STEP 4: Inserting Demo Data
============================================================

ℹ️  Inserting demo admin...
✅ Demo admin inserted
ℹ️  Inserting demo hostel...
✅ Demo hostel inserted
ℹ️  Inserting demo rooms...
✅ Demo rooms inserted (4 rooms)
ℹ️  Inserting demo tenant...
✅ Demo tenant inserted

============================================================
STEP 5: Database Summary
============================================================

============================================================
DATABASE SUMMARY
============================================================

  admins              : 1 records
  hostels             : 1 records
  rooms               : 4 records
  users               : 1 records
  bills               : 0 records
  issues              : 0 records
  notices             : 0 records
  employees           : 0 records
  payments            : 0 records
  admin_permissions   : 0 records

============================================================
DEMO LOGIN CREDENTIALS
============================================================

  Username: admin
  Password: admin123
  Role: owner
  Name: Admin User


╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║         ✅ MIGRATION COMPLETED SUCCESSFULLY! ✅           ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝

✅ Database is ready for your application!
ℹ️  You can now proceed with deploying your backend.

ℹ️  Database connection closed.
```

---

## 🎨 Key Features

### **1. Safe Column Checking**
```python
def column_exists(connection, table_name, column_name):
    """Check if column exists before adding"""
    query = """
        SELECT COUNT(*) 
        FROM INFORMATION_SCHEMA.COLUMNS 
        WHERE TABLE_NAME = %s AND COLUMN_NAME = %s
    """
    # Returns True/False
```

### **2. ON DUPLICATE KEY UPDATE**
```python
room_query = """
INSERT INTO rooms (id, hostel_id, roomno, ...)
VALUES (%s, %s, %s, ...)
ON DUPLICATE KEY UPDATE roomno=roomno
"""
# Won't fail if records already exist!
```

### **3. Transaction Management**
```python
connection.autocommit = False  # Manual commits
cursor.execute(query)
connection.commit()  # Explicit commit
# or
connection.rollback()  # Rollback on error
```

### **4. Error Handling**
```python
try:
    cursor.execute(query)
    connection.commit()
    print_success("Operation completed")
except Error as e:
    print_error(f"Error: {e}")
    connection.rollback()
    return False
```

---

## 🔧 Advanced Usage

### **Run with Arguments (No Prompts)**

Edit the script and add at the top:

```python
# Hardcoded credentials (for automation)
HOST = "your-db.xxxxxxxxxxxx.us-east-1.rds.amazonaws.com"
USER = "admin"
PASSWORD = "Omsairam951#"
DATABASE = "pgworld"

# Then in main(), replace input() calls with:
host = HOST
user = USER
password = PASSWORD
database = DATABASE
```

### **Check Specific Column**

```python
from fix_database import column_exists, connect_to_database

connection = connect_to_database(host, user, password, database)

if column_exists(connection, 'rooms', 'hostel_id'):
    print("✅ Column exists!")
else:
    print("❌ Column missing!")
    
connection.close()
```

### **Add Custom Column**

```python
cursor = connection.cursor()

if not column_exists(connection, 'rooms', 'my_custom_field'):
    cursor.execute("""
        ALTER TABLE rooms 
        ADD COLUMN my_custom_field VARCHAR(100) NULL
    """)
    connection.commit()
    print("✅ Custom column added!")
    
cursor.close()
```

---

## ⚠️ Troubleshooting

### **Error: ModuleNotFoundError: No module named 'mysql'**

```bash
# Install the connector
sudo pip3 install mysql-connector-python

# Or using yum (on Amazon Linux 2)
sudo yum install python3-mysql -y
```

### **Error: Access denied for user**

- Verify RDS endpoint is correct
- Check username (usually `admin`)
- Confirm password (special chars like `#` are OK in Python)
- Ensure RDS security group allows EC2 connections

### **Error: Unknown database 'pgworld'**

The script will try to use the database, but won't create it. Create it first:

```python
# Connect without specifying database
connection = mysql.connector.connect(
    host=host, user=user, password=password
)
cursor = connection.cursor()
cursor.execute("CREATE DATABASE IF NOT EXISTS pgworld")
cursor.close()
connection.close()

# Then run the main script
```

### **Script Hangs on Password Input**

Password input is hidden (secure). Just type it and press Enter. You won't see it on screen.

---

## 🆚 Python vs Bash Scripts

| Feature | Python Script | Bash Script |
|---------|--------------|-------------|
| **Column Checking** | ✅ INFORMATION_SCHEMA | ✅ INFORMATION_SCHEMA |
| **Error Handling** | ✅ Try/Except blocks | ✅ Exit codes |
| **Password Security** | ✅ No command line args | ✅ Credentials file |
| **Cross-platform** | ✅ Works anywhere | ❌ Linux/Mac only |
| **Dependencies** | Needs mysql-connector | Needs mysql client |
| **Customization** | ✅ Easy to extend | Limited |
| **Progress Output** | ✅ Colorful & detailed | ✅ Colorful |

---

## 📦 Installation on Different Systems

### **Amazon Linux 2 / CentOS / RHEL:**
```bash
sudo yum install python3 python3-pip -y
sudo pip3 install mysql-connector-python
```

### **Ubuntu / Debian:**
```bash
sudo apt update
sudo apt install python3 python3-pip -y
sudo pip3 install mysql-connector-python
```

### **MacOS:**
```bash
brew install python3
pip3 install mysql-connector-python
```

### **Windows:**
```powershell
# Using Python installer from python.org
pip install mysql-connector-python
```

---

## 🧪 Testing the Script Locally

Before running on production:

```bash
# 1. Test with a local MySQL instance
docker run -d -p 3306:3306 \
  -e MYSQL_ROOT_PASSWORD=root \
  -e MYSQL_DATABASE=pgworld \
  mysql:8.0

# 2. Run script
python3 fix-database.py

# Inputs:
# RDS Endpoint: localhost
# User: root
# Password: root
# Database: pgworld

# 3. Verify tables
mysql -h localhost -u root -proot pgworld -e "SHOW TABLES;"
```

---

## 🎯 After Running This Script

Once the database is set up:

### **1. Build & Deploy Go Backend:**

```bash
cd ~/pgni-deployment/pgworld-api-master

# Create .env file
cat > .env << EOF
DB_HOST=YOUR_RDS_ENDPOINT
DB_PORT=3306
DB_USER=admin
DB_PASSWORD=Omsairam951#
DB_NAME=pgworld
PORT=8080
ENV=production
EOF

# Build
/usr/local/go/bin/go build -o pgworld-api main.go

# Start service
sudo systemctl restart pgworld-api

# Test
curl http://localhost:8080/
```

### **2. Deploy Flutter Frontend:**

```bash
# Update lib/utils/config.dart with EC2 IP
cd pgworld-master
flutter build web --release
aws s3 sync build/web/ s3://YOUR_S3_BUCKET/
```

---

## 📞 Support

**Script works?** → Continue with backend deployment  
**Script fails?** → Share the error message and I'll help immediately

---

## ✅ Advantages of This Approach

1. ✅ **Cross-platform** - Works on Windows, Mac, Linux
2. ✅ **Safer** - Uses parameterized queries (SQL injection proof)
3. ✅ **Detailed logging** - Shows exactly what's happening
4. ✅ **Resumable** - Can run multiple times safely
5. ✅ **Customizable** - Easy to add custom tables/columns
6. ✅ **No shell dependencies** - Pure Python

---

**Ready to use! Run the script and your database will be set up perfectly.** 🎉

