# ❌ DATABASE MIGRATION ERROR - QUICK FIX

## 🔍 **Problem Identified**

Your deployment failed with this error:
```
ERROR 1064 (42000) at line 31: You have an error in your SQL syntax
```

**Root Cause**: The deployment script is using `ADD COLUMN IF NOT EXISTS` syntax which is **NOT supported** in your MySQL version.

**Solution**: Run the fixed migration script below.

---

## ✅ **QUICK FIX - Run These Commands on EC2**

### **Step 1: Download the Fix Script**
On your EC2 server, run:
```bash
curl -sL https://raw.githubusercontent.com/siddam01/pgni/main/FIX_EC2_DATABASE.sh -o /tmp/fix_db.sh
chmod +x /tmp/fix_db.sh
```

### **Step 2: Run the Fix**
```bash
/tmp/fix_db.sh
```

When prompted:
- **Enter Database Password**: [your RDS password]

The script will:
1. ✅ Test database connection
2. ✅ Apply MySQL-compatible migrations
3. ✅ Add RBAC columns safely
4. ✅ Create permissions table
5. ✅ Verify all changes

### **Step 3: Re-run Your Deployment**
After the fix completes, re-run your original deployment command.

---

## 🔧 **Manual Fix (If Script Fails)**

If the automatic script doesn't work, run this SQL directly:

```sql
-- Connect to your database
mysql -h database-pgni.cezawkgguojl.us-east-1.rds.amazonaws.com \
      -u admin \
      -p \
      pgworld

-- Then run these commands:

USE pgworld;

-- Add 'role' column if missing
SET @col_exists := (
  SELECT COUNT(*) 
  FROM INFORMATION_SCHEMA.COLUMNS 
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'admins' 
    AND COLUMN_NAME = 'role'
);

SET @sql := IF(@col_exists = 0, 
  'ALTER TABLE admins ADD COLUMN role VARCHAR(20) DEFAULT "owner" COMMENT "owner or manager";',
  'SELECT "✓ Column role already exists" AS Info;'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Add 'parent_admin_id' column if missing
SET @col_exists := (
  SELECT COUNT(*) 
  FROM INFORMATION_SCHEMA.COLUMNS 
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'admins' 
    AND COLUMN_NAME = 'parent_admin_id'
);

SET @sql := IF(@col_exists = 0, 
  'ALTER TABLE admins ADD COLUMN parent_admin_id VARCHAR(50) NULL COMMENT "For managers: owner admin ID";',
  'SELECT "✓ Column parent_admin_id already exists" AS Info;'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Add 'assigned_hostel_ids' column if missing
SET @col_exists := (
  SELECT COUNT(*) 
  FROM INFORMATION_SCHEMA.COLUMNS 
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'admins' 
    AND COLUMN_NAME = 'assigned_hostel_ids'
);

SET @sql := IF(@col_exists = 0, 
  'ALTER TABLE admins ADD COLUMN assigned_hostel_ids TEXT NULL COMMENT "For managers: comma-separated hostel IDs";',
  'SELECT "✓ Column assigned_hostel_ids already exists" AS Info;'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Create admin_permissions table
CREATE TABLE IF NOT EXISTS admin_permissions (
    id VARCHAR(50) PRIMARY KEY,
    admin_id VARCHAR(50) NOT NULL,
    hostel_id VARCHAR(50) NOT NULL,
    can_view_dashboard BOOLEAN DEFAULT TRUE,
    can_manage_rooms BOOLEAN DEFAULT FALSE,
    can_manage_tenants BOOLEAN DEFAULT FALSE,
    can_manage_bills BOOLEAN DEFAULT FALSE,
    can_view_financials BOOLEAN DEFAULT FALSE,
    can_manage_employees BOOLEAN DEFAULT FALSE,
    can_view_reports BOOLEAN DEFAULT FALSE,
    can_manage_notices BOOLEAN DEFAULT FALSE,
    can_manage_issues BOOLEAN DEFAULT FALSE,
    can_manage_payments BOOLEAN DEFAULT FALSE,
    status VARCHAR(1) DEFAULT '1',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_admin_id (admin_id),
    INDEX idx_hostel_id (hostel_id),
    INDEX idx_status (status),
    UNIQUE KEY unique_admin_hostel (admin_id, hostel_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Verify
SELECT 
    COLUMN_NAME, 
    DATA_TYPE, 
    COLUMN_DEFAULT,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME = 'admins'
  AND COLUMN_NAME IN ('role', 'parent_admin_id', 'assigned_hostel_ids');
```

---

## 📋 **What This Fix Does**

1. **Checks if columns exist** before attempting to add them
2. **Uses MySQL-compatible syntax** (PREPARE/EXECUTE pattern)
3. **Adds RBAC columns** to `admins` table:
   - `role` - owner or manager
   - `parent_admin_id` - For managers: which owner they report to
   - `assigned_hostel_ids` - For managers: which hostels they can manage
4. **Creates `admin_permissions` table** for granular permissions
5. **Idempotent** - Safe to run multiple times

---

## ✅ **Verification**

After running the fix, verify it worked:

```bash
mysql -h database-pgni.cezawkgguojl.us-east-1.rds.amazonaws.com \
      -u admin \
      -p \
      pgworld \
      -e "DESCRIBE admins;"
```

You should see the new columns:
- `role`
- `parent_admin_id`
- `assigned_hostel_ids`

---

## 🚀 **After Fix - Continue Deployment**

Once the database fix is complete:

1. ✅ Database is fixed
2. ✅ Re-run your deployment script
3. ✅ Continue with backend + frontend deployment

The deployment should now proceed without errors!

---

## 🐛 **Why This Happened**

The original deployment script used:
```sql
ALTER TABLE admins 
ADD COLUMN IF NOT EXISTS role ...
```

This syntax is **NOT supported** in MySQL 5.7 (which AWS RDS often uses by default).

The correct approach for MySQL compatibility is:
```sql
SET @col_exists := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS ...);
SET @sql := IF(@col_exists = 0, 'ALTER TABLE ...', 'SELECT ...');
PREPARE stmt FROM @sql;
EXECUTE stmt;
```

---

## 🆘 **Troubleshooting**

### Error: "Access denied"
- Check database password
- Verify user has ALTER privileges
- Try: `SHOW GRANTS FOR 'admin'@'%';`

### Error: "Table 'admins' doesn't exist"
- Run base schema first
- Check if you're in the correct database: `USE pgworld;`

### Error: "Unknown database 'pgworld'"
- Create database first: `CREATE DATABASE IF NOT EXISTS pgworld;`

---

## 📞 **Need Help?**

If the fix doesn't work:
1. Copy the **full error message**
2. Check MySQL version: `mysql --version`
3. Verify you can connect: `mysql -h [RDS_ENDPOINT] -u admin -p`
4. Create a GitHub issue with details

---

**Status**: ⚠️ Database migration error - Fix available
**Action**: Run the fix script above and re-deploy

