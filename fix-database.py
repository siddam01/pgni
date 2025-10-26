#!/usr/bin/env python3
"""
PG/Hostel Management System - Database Migration Script
Fixes schema issues and sets up complete database structure
Compatible with MySQL on AWS RDS
"""

import mysql.connector
from mysql.connector import Error
import sys
from datetime import datetime, timedelta

# ANSI Color codes for pretty output
GREEN = '\033[92m'
RED = '\033[91m'
YELLOW = '\033[93m'
BLUE = '\033[94m'
CYAN = '\033[96m'
RESET = '\033[0m'

def print_success(message):
    print(f"{GREEN}✅ {message}{RESET}")

def print_error(message):
    print(f"{RED}❌ {message}{RESET}")

def print_info(message):
    print(f"{BLUE}ℹ️  {message}{RESET}")

def print_warning(message):
    print(f"{YELLOW}⚠️  {message}{RESET}")

def print_header(message):
    print(f"\n{CYAN}{'='*60}")
    print(f"{message}")
    print(f"{'='*60}{RESET}\n")

def connect_to_database(host, user, password, database):
    """
    Establish connection to MySQL database
    """
    try:
        connection = mysql.connector.connect(
            host=host,
            user=user,
            password=password,
            database=database,
            autocommit=False
        )
        
        if connection.is_connected():
            db_info = connection.get_server_info()
            print_success(f"Connected to MySQL Server version {db_info}")
            cursor = connection.cursor()
            cursor.execute("SELECT DATABASE();")
            record = cursor.fetchone()
            print_success(f"Connected to database: {record[0]}")
            cursor.close()
            return connection
        
    except Error as e:
        print_error(f"Error connecting to MySQL: {e}")
        return None

def column_exists(connection, table_name, column_name):
    """
    Check if a column exists in a table
    """
    try:
        cursor = connection.cursor()
        query = """
            SELECT COUNT(*) 
            FROM INFORMATION_SCHEMA.COLUMNS 
            WHERE TABLE_SCHEMA = DATABASE() 
            AND TABLE_NAME = %s 
            AND COLUMN_NAME = %s
        """
        cursor.execute(query, (table_name, column_name))
        result = cursor.fetchone()
        cursor.close()
        return result[0] > 0
    except Error as e:
        print_error(f"Error checking column existence: {e}")
        return False

def table_exists(connection, table_name):
    """
    Check if a table exists
    """
    try:
        cursor = connection.cursor()
        query = """
            SELECT COUNT(*) 
            FROM INFORMATION_SCHEMA.TABLES 
            WHERE TABLE_SCHEMA = DATABASE() 
            AND TABLE_NAME = %s
        """
        cursor.execute(query, (table_name,))
        result = cursor.fetchone()
        cursor.close()
        return result[0] > 0
    except Error as e:
        print_error(f"Error checking table existence: {e}")
        return False

def create_table_admins(connection):
    """
    Create admins table with RBAC columns
    """
    try:
        cursor = connection.cursor()
        
        query = """
        CREATE TABLE IF NOT EXISTS admins (
            id VARCHAR(50) PRIMARY KEY,
            username VARCHAR(100) NOT NULL UNIQUE,
            password VARCHAR(255) NOT NULL,
            name VARCHAR(100),
            email VARCHAR(100),
            phone VARCHAR(20),
            hostel_ids TEXT,
            role VARCHAR(20) DEFAULT 'owner',
            parent_admin_id VARCHAR(50) NULL,
            assigned_hostel_ids TEXT NULL,
            status VARCHAR(1) DEFAULT '1',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            INDEX idx_username (username),
            INDEX idx_status (status)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
        """
        
        cursor.execute(query)
        connection.commit()
        cursor.close()
        print_success("Table 'admins' created/verified")
        return True
        
    except Error as e:
        print_error(f"Error creating admins table: {e}")
        return False

def create_table_hostels(connection):
    """
    Create hostels table
    """
    try:
        cursor = connection.cursor()
        
        query = """
        CREATE TABLE IF NOT EXISTS hostels (
            id VARCHAR(50) PRIMARY KEY,
            admin_id VARCHAR(50) NOT NULL,
            name VARCHAR(200) NOT NULL,
            address TEXT,
            phone VARCHAR(20),
            email VARCHAR(100),
            amenities TEXT,
            document TEXT,
            expiry_date_time DATETIME,
            status VARCHAR(1) DEFAULT '1',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            INDEX idx_admin_id (admin_id),
            INDEX idx_status (status)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
        """
        
        cursor.execute(query)
        connection.commit()
        cursor.close()
        print_success("Table 'hostels' created/verified")
        return True
        
    except Error as e:
        print_error(f"Error creating hostels table: {e}")
        return False

def create_table_rooms(connection):
    """
    Create rooms table
    """
    try:
        cursor = connection.cursor()
        
        query = """
        CREATE TABLE IF NOT EXISTS rooms (
            id VARCHAR(50) PRIMARY KEY,
            hostel_id VARCHAR(50) NOT NULL,
            roomno VARCHAR(50) NOT NULL,
            type VARCHAR(50),
            size VARCHAR(50),
            capacity INT,
            rent DECIMAL(10,2),
            amenities TEXT,
            document TEXT,
            status VARCHAR(1) DEFAULT '1',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            INDEX idx_hostel_id (hostel_id),
            INDEX idx_roomno (roomno),
            INDEX idx_status (status)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
        """
        
        cursor.execute(query)
        connection.commit()
        cursor.close()
        print_success("Table 'rooms' created/verified")
        return True
        
    except Error as e:
        print_error(f"Error creating rooms table: {e}")
        return False

def create_table_users(connection):
    """
    Create users (tenants) table
    """
    try:
        cursor = connection.cursor()
        
        query = """
        CREATE TABLE IF NOT EXISTS users (
            id VARCHAR(50) PRIMARY KEY,
            hostel_id VARCHAR(50) NOT NULL,
            room_id VARCHAR(50),
            name VARCHAR(100) NOT NULL,
            phone VARCHAR(20) NOT NULL UNIQUE,
            email VARCHAR(100),
            address TEXT,
            roomno VARCHAR(50),
            rent DECIMAL(10,2),
            food VARCHAR(500),
            document TEXT,
            emer_contact VARCHAR(100),
            emer_phone VARCHAR(20),
            joining_date_time DATETIME,
            last_paid_date_time DATETIME,
            expiry_date_time DATETIME,
            vacate_date_time DATETIME,
            payment_status VARCHAR(1) DEFAULT '0',
            status VARCHAR(1) DEFAULT '1',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            INDEX idx_hostel_id (hostel_id),
            INDEX idx_room_id (room_id),
            INDEX idx_phone (phone),
            INDEX idx_status (status)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
        """
        
        cursor.execute(query)
        connection.commit()
        cursor.close()
        print_success("Table 'users' created/verified")
        return True
        
    except Error as e:
        print_error(f"Error creating users table: {e}")
        return False

def create_remaining_tables(connection):
    """
    Create remaining tables (bills, issues, notices, employees, etc.)
    """
    try:
        cursor = connection.cursor()
        
        tables = [
            # Bills table
            """
            CREATE TABLE IF NOT EXISTS bills (
                id VARCHAR(50) PRIMARY KEY,
                hostel_id VARCHAR(50) NOT NULL,
                type VARCHAR(50) NOT NULL,
                amount DECIMAL(10,2) NOT NULL,
                description TEXT,
                bill_date DATETIME,
                document TEXT,
                status VARCHAR(1) DEFAULT '1',
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                INDEX idx_hostel_id (hostel_id),
                INDEX idx_type (type),
                INDEX idx_status (status)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
            """,
            
            # Issues table
            """
            CREATE TABLE IF NOT EXISTS issues (
                id VARCHAR(50) PRIMARY KEY,
                hostel_id VARCHAR(50) NOT NULL,
                user_id VARCHAR(50),
                room_id VARCHAR(50),
                type VARCHAR(50) NOT NULL,
                title VARCHAR(200),
                description TEXT,
                document TEXT,
                status VARCHAR(1) DEFAULT '1',
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                INDEX idx_hostel_id (hostel_id),
                INDEX idx_user_id (user_id),
                INDEX idx_type (type),
                INDEX idx_status (status)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
            """,
            
            # Notices table
            """
            CREATE TABLE IF NOT EXISTS notices (
                id VARCHAR(50) PRIMARY KEY,
                hostel_id VARCHAR(50) NOT NULL,
                title VARCHAR(200) NOT NULL,
                description TEXT,
                document TEXT,
                status VARCHAR(1) DEFAULT '1',
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                INDEX idx_hostel_id (hostel_id),
                INDEX idx_status (status)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
            """,
            
            # Employees table
            """
            CREATE TABLE IF NOT EXISTS employees (
                id VARCHAR(50) PRIMARY KEY,
                hostel_id VARCHAR(50) NOT NULL,
                name VARCHAR(100) NOT NULL,
                phone VARCHAR(20),
                email VARCHAR(100),
                role VARCHAR(50),
                salary DECIMAL(10,2),
                joining_date DATETIME,
                document TEXT,
                status VARCHAR(1) DEFAULT '1',
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                INDEX idx_hostel_id (hostel_id),
                INDEX idx_status (status)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
            """,
            
            # OTPs table
            """
            CREATE TABLE IF NOT EXISTS otps (
                id INT AUTO_INCREMENT PRIMARY KEY,
                phone VARCHAR(20) NOT NULL,
                otp VARCHAR(10) NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                expires_at TIMESTAMP,
                verified BOOLEAN DEFAULT FALSE,
                INDEX idx_phone (phone),
                INDEX idx_created_at (created_at)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
            """,
            
            # Payments table
            """
            CREATE TABLE IF NOT EXISTS payments (
                id VARCHAR(50) PRIMARY KEY,
                user_id VARCHAR(50) NOT NULL,
                hostel_id VARCHAR(50) NOT NULL,
                amount DECIMAL(10,2) NOT NULL,
                payment_type VARCHAR(50),
                payment_id VARCHAR(100),
                order_id VARCHAR(100),
                payment_date DATETIME,
                status VARCHAR(1) DEFAULT '1',
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                INDEX idx_user_id (user_id),
                INDEX idx_hostel_id (hostel_id),
                INDEX idx_status (status)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
            """,
            
            # Food table
            """
            CREATE TABLE IF NOT EXISTS food (
                id VARCHAR(50) PRIMARY KEY,
                hostel_id VARCHAR(50) NOT NULL,
                name VARCHAR(200) NOT NULL,
                price DECIMAL(10,2),
                description TEXT,
                type VARCHAR(50),
                status VARCHAR(1) DEFAULT '1',
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                INDEX idx_hostel_id (hostel_id),
                INDEX idx_status (status)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
            """,
            
            # Admin Permissions table (RBAC)
            """
            CREATE TABLE IF NOT EXISTS admin_permissions (
                id VARCHAR(50) PRIMARY KEY,
                admin_id VARCHAR(50) NOT NULL,
                hostel_id VARCHAR(50) NOT NULL,
                role VARCHAR(20) NOT NULL DEFAULT 'manager',
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
                assigned_by VARCHAR(50),
                status VARCHAR(1) DEFAULT '1',
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                INDEX idx_admin_id (admin_id),
                INDEX idx_hostel_id (hostel_id),
                INDEX idx_role (role),
                INDEX idx_status (status),
                UNIQUE KEY unique_admin_hostel (admin_id, hostel_id)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
            """
        ]
        
        for table_query in tables:
            cursor.execute(table_query)
            connection.commit()
        
        cursor.close()
        print_success("All remaining tables created/verified")
        return True
        
    except Error as e:
        print_error(f"Error creating remaining tables: {e}")
        return False

def insert_demo_data(connection):
    """
    Insert demo data safely
    """
    try:
        cursor = connection.cursor()
        
        # Insert demo admin
        print_info("Inserting demo admin...")
        admin_query = """
        INSERT INTO admins (id, username, password, name, email, phone, hostel_ids, role, status) 
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
        ON DUPLICATE KEY UPDATE username=username
        """
        cursor.execute(admin_query, (
            'admin001', 'admin', 'admin123', 'Admin User', 
            'admin@pgworld.com', '9876543210', 'hostel001', 'owner', '1'
        ))
        connection.commit()
        print_success("Demo admin inserted")
        
        # Insert demo hostel
        print_info("Inserting demo hostel...")
        expiry_date = (datetime.now() + timedelta(days=365)).strftime('%Y-%m-%d %H:%M:%S')
        hostel_query = """
        INSERT INTO hostels (id, admin_id, name, address, phone, email, amenities, expiry_date_time, status)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
        ON DUPLICATE KEY UPDATE name=name
        """
        cursor.execute(hostel_query, (
            'hostel001', 'admin001', 'Demo PG Hostel',
            '123 Main Street, Hyderabad, Telangana, India',
            '9876543210', 'contact@demopg.com',
            'Wifi,AC,TV,Bathroom,Power Backup,Washing Machine,Geyser,Laundry',
            expiry_date, '1'
        ))
        connection.commit()
        print_success("Demo hostel inserted")
        
        # Insert demo rooms
        print_info("Inserting demo rooms...")
        rooms_data = [
            ('room001', 'hostel001', '101', 'Single', '120 sq ft', 1, 5000.00, 'Wifi,AC,TV,Bathroom', '1'),
            ('room002', 'hostel001', '102', 'Double', '150 sq ft', 2, 4000.00, 'Wifi,Bathroom,Power Backup', '1'),
            ('room003', 'hostel001', '103', 'Triple', '180 sq ft', 3, 3500.00, 'Wifi,Bathroom,TV', '1'),
            ('room004', 'hostel001', '104', 'Single', '120 sq ft', 1, 5500.00, 'Wifi,AC,TV,Bathroom,Geyser', '1')
        ]
        
        room_query = """
        INSERT INTO rooms (id, hostel_id, roomno, type, size, capacity, rent, amenities, status)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
        ON DUPLICATE KEY UPDATE roomno=roomno
        """
        
        for room_data in rooms_data:
            cursor.execute(room_query, room_data)
        
        connection.commit()
        print_success(f"Demo rooms inserted ({len(rooms_data)} rooms)")
        
        # Insert demo tenant
        print_info("Inserting demo tenant...")
        joining_date = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        expiry_date = (datetime.now() + timedelta(days=30)).strftime('%Y-%m-%d %H:%M:%S')
        
        user_query = """
        INSERT INTO users (id, hostel_id, room_id, name, phone, email, address, roomno, rent, 
                          joining_date_time, last_paid_date_time, expiry_date_time, payment_status, status)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        ON DUPLICATE KEY UPDATE name=name
        """
        cursor.execute(user_query, (
            'user001', 'hostel001', 'room001', 'John Doe', '9123456789',
            'john.doe@email.com', '456 Park Avenue, Hyderabad', '101', 5000.00,
            joining_date, joining_date, expiry_date, '1', '1'
        ))
        connection.commit()
        print_success("Demo tenant inserted")
        
        cursor.close()
        return True
        
    except Error as e:
        print_error(f"Error inserting demo data: {e}")
        connection.rollback()
        return False

def show_summary(connection):
    """
    Show database summary
    """
    try:
        cursor = connection.cursor()
        
        print_header("DATABASE SUMMARY")
        
        # Count records in each table
        tables = ['admins', 'hostels', 'rooms', 'users', 'bills', 'issues', 
                 'notices', 'employees', 'payments', 'admin_permissions']
        
        for table in tables:
            cursor.execute(f"SELECT COUNT(*) FROM {table}")
            count = cursor.fetchone()[0]
            print(f"  {table.ljust(20)}: {count} records")
        
        print()
        print_header("DEMO LOGIN CREDENTIALS")
        cursor.execute("SELECT username, password, role, name FROM admins WHERE id = 'admin001'")
        admin = cursor.fetchone()
        
        if admin:
            print(f"  Username: {admin[0]}")
            print(f"  Password: {admin[1]}")
            print(f"  Role: {admin[2]}")
            print(f"  Name: {admin[3]}")
        
        cursor.close()
        print()
        
    except Error as e:
        print_error(f"Error showing summary: {e}")

def main():
    """
    Main execution function
    """
    print(f"{CYAN}")
    print("╔═══════════════════════════════════════════════════════════╗")
    print("║                                                           ║")
    print("║    PG/Hostel Management - Database Migration             ║")
    print("║    Python Edition                                        ║")
    print("║                                                           ║")
    print("╚═══════════════════════════════════════════════════════════╝")
    print(f"{RESET}")
    
    # Get database credentials
    print_info("Enter database connection details:")
    print()
    
    host = input(f"{BLUE}RDS Endpoint: {RESET}").strip()
    user = input(f"{BLUE}Database User [admin]: {RESET}").strip() or "admin"
    password = input(f"{BLUE}Database Password: {RESET}")
    database = input(f"{BLUE}Database Name [pgworld]: {RESET}").strip() or "pgworld"
    
    print()
    print_header("STEP 1: Connecting to Database")
    
    # Connect to database
    connection = connect_to_database(host, user, password, database)
    
    if not connection:
        print_error("Failed to connect to database. Exiting.")
        sys.exit(1)
    
    try:
        # Create tables in order
        print_header("STEP 2: Creating Base Tables")
        
        if not create_table_admins(connection):
            raise Exception("Failed to create admins table")
        
        if not create_table_hostels(connection):
            raise Exception("Failed to create hostels table")
        
        if not create_table_rooms(connection):
            raise Exception("Failed to create rooms table")
        
        if not create_table_users(connection):
            raise Exception("Failed to create users table")
        
        print_header("STEP 3: Creating Remaining Tables")
        
        if not create_remaining_tables(connection):
            raise Exception("Failed to create remaining tables")
        
        print_header("STEP 4: Inserting Demo Data")
        
        if not insert_demo_data(connection):
            print_warning("Demo data insertion had some issues, but tables are ready")
        
        print_header("STEP 5: Database Summary")
        
        show_summary(connection)
        
        print(f"{GREEN}")
        print("╔═══════════════════════════════════════════════════════════╗")
        print("║                                                           ║")
        print("║         ✅ MIGRATION COMPLETED SUCCESSFULLY! ✅           ║")
        print("║                                                           ║")
        print("╚═══════════════════════════════════════════════════════════╝")
        print(f"{RESET}")
        
        print_success("Database is ready for your application!")
        print_info("You can now proceed with deploying your backend.")
        print()
        
    except Exception as e:
        print_error(f"Migration failed: {e}")
        sys.exit(1)
    
    finally:
        if connection and connection.is_connected():
            connection.close()
            print_info("Database connection closed.")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print()
        print_warning("Migration cancelled by user.")
        sys.exit(0)

