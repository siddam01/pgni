-- Create pgworld database
CREATE DATABASE IF NOT EXISTS pgworld CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Use the database
USE pgworld;

-- Show success message
SELECT 'Database pgworld created successfully!' AS Status;

-- Show all databases
SHOW DATABASES;

