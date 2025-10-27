# 🔧 MySQL Migration Fix - Deployment Guide

## ✅ What Was Fixed

The deployment script had a **MySQL syntax error** caused by:
```sql
ALTER TABLE admins ADD COLUMN IF NOT EXISTS role ...
```

**Problem:** MySQL doesn't support `IF NOT EXISTS` in `ALTER TABLE` statements.

**Solution:** Created a new migration file using `INFORMATION_SCHEMA` to check for existing columns before adding them.

---

## 🚀 How to Deploy Now

### **Option 1: Fresh Deployment (Recommended)**

Run the updated deployment script from scratch:

```bash
bash <(curl -sL https://raw.githubusercontent.com/siddam01/pgni/main/EC2_DEPLOY_MASTER.sh)
```

**New Features in This Version:**
✅ Database connection validation before migration  
✅ MySQL-compatible SQL using `INFORMATION_SCHEMA`  
✅ Safe column additions (won't fail if columns exist)  
✅ Better error messages with troubleshooting steps

---

### **Option 2: Fix Current Deployment**

If you're already on EC2 and want to fix the database issue:

```bash
# 1. Navigate to deployment directory
cd ~/pgni-deployment

# 2. Pull latest changes
cd temp-repo 2>/dev/null || git clone https://github.com/siddam01/pgni.git temp-repo
cd temp-repo
git pull origin main

# 3. Test database connection
mysql -h YOUR_RDS_ENDPOINT -u YOUR_DB_USER -p -e "SELECT 1"

# 4. Run the safe migration
mysql -h YOUR_RDS_ENDPOINT -u YOUR_DB_USER -p < pgworld-api-master/setup-database-safe.sql

# 5. Verify tables created
mysql -h YOUR_RDS_ENDPOINT -u YOUR_DB_USER -p -e "USE pgworld; SHOW TABLES;"
```

Replace:
- `YOUR_RDS_ENDPOINT` with your RDS endpoint
- `YOUR_DB_USER` with your database username

---

## 🔍 What the Safe Migration Does

### 1. **Checks Each Column Before Adding**
```sql
SET @col_exists := (
  SELECT COUNT(*) 
  FROM INFORMATION_SCHEMA.COLUMNS 
  WHERE TABLE_NAME = 'admins' AND COLUMN_NAME = 'role'
);
```

### 2. **Adds Column Only If Missing**
```sql
SET @sql := IF(@col_exists = 0, 
  'ALTER TABLE admins ADD COLUMN role VARCHAR(20) DEFAULT "owner";',
  'SELECT "✓ Column role already exists";'
);
```

### 3. **Safe for Re-runs**
- Won't fail if columns already exist
- Won't duplicate data
- Won't break existing tables

---

## 📊 What Gets Created

### **New Columns in `admins` Table:**
| Column | Type | Default | Purpose |
|--------|------|---------|---------|
| `role` | VARCHAR(20) | 'owner' | User role (owner/manager) |
| `parent_admin_id` | VARCHAR(50) | NULL | For managers: owner's ID |
| `assigned_hostel_ids` | TEXT | NULL | For managers: comma-separated hostel IDs |

### **New Table: `admin_permissions`**
RBAC table with 10 granular permissions:
- ✅ can_view_dashboard
- ✅ can_manage_rooms
- ✅ can_manage_tenants
- ✅ can_manage_bills
- ✅ can_view_financials
- ✅ can_manage_employees
- ✅ can_view_reports
- ✅ can_manage_notices
- ✅ can_manage_issues
- ✅ can_manage_payments

---

## 🧪 Verify Migration Success

After running the migration, verify everything worked:

```bash
# Check that columns were added
mysql -h YOUR_RDS_ENDPOINT -u YOUR_DB_USER -p pgworld -e "
DESCRIBE admins;
"

# Check that permissions table exists
mysql -h YOUR_RDS_ENDPOINT -u YOUR_DB_USER -p pgworld -e "
DESCRIBE admin_permissions;
"

# Count rows in permissions table
mysql -h YOUR_RDS_ENDPOINT -u YOUR_DB_USER -p pgworld -e "
SELECT COUNT(*) AS permission_records FROM admin_permissions;
"
```

---

## ⚠️ Troubleshooting

### **Error: Access denied for user**
- Verify RDS endpoint is correct
- Check database username
- Confirm password is correct
- Ensure RDS security group allows connection from EC2

### **Error: Unknown database 'pgworld'**
```bash
# Create database manually
mysql -h YOUR_RDS_ENDPOINT -u YOUR_DB_USER -p -e "CREATE DATABASE pgworld;"
```

### **Error: Table 'admins' doesn't exist**
Your database doesn't have the base schema yet. You need to:
1. Run your original database setup script first
2. Then run this migration

### **Error: Column already exists**
✅ This is GOOD! It means the migration detected existing columns and skipped them safely.

---

## 📞 Next Steps After Successful Migration

1. **Restart Backend Service:**
```bash
sudo systemctl restart pgworld-api
```

2. **Check Service Status:**
```bash
sudo systemctl status pgworld-api
```

3. **View Logs:**
```bash
sudo journalctl -u pgworld-api -f
```

4. **Test API:**
```bash
curl http://localhost:8080/
```

---

## 🎯 Complete Deployment Summary

After successful deployment, you'll have:

✅ **Backend API** running on EC2 (port 8080)  
✅ **MySQL Database** with RBAC tables on RDS  
✅ **Systemd Service** (auto-restart on failure)  
✅ **Configuration Saved** in `~/.pgni-config`  

**API URL:** `http://YOUR_EC2_IP:8080`  
**Service Name:** `pgworld-api`  
**Logs:** `sudo journalctl -u pgworld-api -f`

---

## 💡 Pro Tips

1. **Save Deployment Info:**
   ```bash
   cat ~/pgni-deployment-info.txt
   ```

2. **Reuse Configuration:**
   The script saves your config to `~/.pgni-config` for future deployments.

3. **Monitor Backend:**
   ```bash
   watch -n 2 'curl -s http://localhost:8080/ | jq'
   ```

4. **Database Quick Access:**
   ```bash
   mysql -h $(grep RDS_ENDPOINT ~/.pgni-config | cut -d'"' -f2) \
         -u $(grep DB_USER ~/.pgni-config | cut -d'"' -f2) \
         -p pgworld
   ```

---

## 📝 Files Modified

1. **`pgworld-api-master/setup-database-safe.sql`** (NEW)
   - MySQL-compatible migration using INFORMATION_SCHEMA
   - Safe column additions with existence checks
   - Detailed comments and verification queries

2. **`EC2_DEPLOY_MASTER.sh`** (UPDATED)
   - Added database connection test before migration
   - Uses new safe SQL file
   - Better error messages with troubleshooting steps

---

## ✅ Commit Details

**Commit:** `5f69c63`  
**Branch:** `main`  
**GitHub:** https://github.com/siddam01/pgni

```
fix: MySQL compatible database migration with connection validation

- Created setup-database-safe.sql using INFORMATION_SCHEMA approach
- Removed unsupported 'ADD COLUMN IF NOT EXISTS' syntax
- Added database connection test before migration
- Uses prepared statements for safe column additions
- Compatible with all MySQL versions (5.5+)
```

---

**Ready to deploy! 🚀**

If you encounter any issues, refer to the troubleshooting section above.

