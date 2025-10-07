-- PG World Database Setup Script
-- This script creates the database and all required tables

-- Create database if it doesn't exist
CREATE DATABASE IF NOT EXISTS pgworld_db;
USE pgworld_db;

-- Admins table
CREATE TABLE IF NOT EXISTS admins (
    id VARCHAR(50) PRIMARY KEY,
    username VARCHAR(100) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    name VARCHAR(100),
    email VARCHAR(100),
    phone VARCHAR(20),
    hostel_ids TEXT,
    status VARCHAR(1) DEFAULT '1',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_username (username),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Hostels table
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
    FOREIGN KEY (admin_id) REFERENCES admins(id),
    INDEX idx_admin_id (admin_id),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Rooms table
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
    FOREIGN KEY (hostel_id) REFERENCES hostels(id),
    INDEX idx_hostel_id (hostel_id),
    INDEX idx_roomno (roomno),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Users (Tenants) table
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
    FOREIGN KEY (hostel_id) REFERENCES hostels(id),
    FOREIGN KEY (room_id) REFERENCES rooms(id),
    INDEX idx_hostel_id (hostel_id),
    INDEX idx_room_id (room_id),
    INDEX idx_phone (phone),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Bills table
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
    FOREIGN KEY (hostel_id) REFERENCES hostels(id),
    INDEX idx_hostel_id (hostel_id),
    INDEX idx_type (type),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Issues table
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
    FOREIGN KEY (hostel_id) REFERENCES hostels(id),
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (room_id) REFERENCES rooms(id),
    INDEX idx_hostel_id (hostel_id),
    INDEX idx_user_id (user_id),
    INDEX idx_type (type),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Notices table
CREATE TABLE IF NOT EXISTS notices (
    id VARCHAR(50) PRIMARY KEY,
    hostel_id VARCHAR(50) NOT NULL,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    document TEXT,
    status VARCHAR(1) DEFAULT '1',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (hostel_id) REFERENCES hostels(id),
    INDEX idx_hostel_id (hostel_id),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Employees table
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
    FOREIGN KEY (hostel_id) REFERENCES hostels(id),
    INDEX idx_hostel_id (hostel_id),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- OTP table for tenant authentication
CREATE TABLE IF NOT EXISTS otps (
    id INT AUTO_INCREMENT PRIMARY KEY,
    phone VARCHAR(20) NOT NULL,
    otp VARCHAR(10) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP,
    verified BOOLEAN DEFAULT FALSE,
    INDEX idx_phone (phone),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Payments table
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
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (hostel_id) REFERENCES hostels(id),
    INDEX idx_user_id (user_id),
    INDEX idx_hostel_id (hostel_id),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Insert demo admin user
INSERT INTO admins (id, username, password, name, email, phone, hostel_ids, status) 
VALUES (
    'admin001', 
    'admin', 
    'admin123', 
    'Admin User', 
    'admin@pgworld.com', 
    '9876543210',
    '',
    '1'
) ON DUPLICATE KEY UPDATE username=username;

-- Insert demo hostel
INSERT INTO hostels (id, admin_id, name, address, phone, email, amenities, expiry_date_time, status)
VALUES (
    'hostel001',
    'admin001',
    'Demo PG Hostel',
    '123 Main Street, Hyderabad, Telangana, India',
    '9876543210',
    'contact@demopg.com',
    'Wifi,AC,TV,Bathroom,Power Backup,Washing Machine,Geyser,Laundry',
    DATE_ADD(NOW(), INTERVAL 1 YEAR),
    '1'
) ON DUPLICATE KEY UPDATE name=name;

-- Insert demo rooms
INSERT INTO rooms (id, hostel_id, roomno, type, size, capacity, rent, amenities, status)
VALUES 
    ('room001', 'hostel001', '101', 'Single', '120 sq ft', 1, 5000.00, 'Wifi,AC,TV,Bathroom', '1'),
    ('room002', 'hostel001', '102', 'Double', '150 sq ft', 2, 4000.00, 'Wifi,Bathroom,Power Backup', '1'),
    ('room003', 'hostel001', '103', 'Triple', '180 sq ft', 3, 3500.00, 'Wifi,Bathroom,TV', '1'),
    ('room004', 'hostel001', '104', 'Single', '120 sq ft', 1, 5500.00, 'Wifi,AC,TV,Bathroom,Geyser', '1')
ON DUPLICATE KEY UPDATE roomno=roomno;

-- Insert demo tenant
INSERT INTO users (id, hostel_id, room_id, name, phone, email, address, roomno, rent, joining_date_time, last_paid_date_time, expiry_date_time, payment_status, status)
VALUES (
    'user001',
    'hostel001',
    'room001',
    'John Doe',
    '9123456789',
    'john.doe@email.com',
    '456 Park Avenue, Hyderabad',
    '101',
    5000.00,
    NOW(),
    NOW(),
    DATE_ADD(NOW(), INTERVAL 30 DAY),
    '1',
    '1'
) ON DUPLICATE KEY UPDATE name=name;

-- Create uploads directory structure
-- (This will be handled by the application)

SELECT 'Database setup completed successfully!' AS Status;
SELECT COUNT(*) AS AdminsCount FROM admins;
SELECT COUNT(*) AS HostelsCount FROM hostels;
SELECT COUNT(*) AS RoomsCount FROM rooms;
SELECT COUNT(*) AS UsersCount FROM users;

