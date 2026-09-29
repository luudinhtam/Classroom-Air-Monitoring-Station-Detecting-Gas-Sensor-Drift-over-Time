IF DB_ID('UserManagementDB') IS NULL
    CREATE DATABASE AirRoomDB;
GO

USE AirRoomDB;
GO

-- ===== 1. Nguoi dung va vai tro =====
CREATE TABLE AppRole (
    role_id   INT IDENTITY(1,1) PRIMARY KEY,
    role_code NVARCHAR(32)  NOT NULL UNIQUE,
    role_name NVARCHAR(100) NOT NULL
);
 
CREATE TABLE AppUser (
    user_id    INT IDENTITY(1,1) PRIMARY KEY,
    username   NVARCHAR(64)  NOT NULL UNIQUE,
    pass_hash  NVARCHAR(200) NOT NULL,   -- PBKDF2 value, never the plain text
    full_name  NVARCHAR(150) NOT NULL,
    role_id    INT NOT NULL FOREIGN KEY REFERENCES AppRole(role_id),
    is_locked  BIT NOT NULL DEFAULT 0,
    created_at DATETIME2(0) NOT NULL DEFAULT SYSDATETIME()
);
