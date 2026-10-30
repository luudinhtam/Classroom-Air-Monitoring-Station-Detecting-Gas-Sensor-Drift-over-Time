USE master;
GO

IF DB_ID('AirRoomDB') IS NOT NULL
BEGIN
    ALTER DATABASE AirRoomDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE AirRoomDB;
END
GO

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
    pass_hash  NVARCHAR(200) NOT NULL,   -- PBKDF2: iterations:salt:hash
    full_name  NVARCHAR(150) NOT NULL,
    role_id    INT NOT NULL FOREIGN KEY REFERENCES AppRole(role_id),
    is_locked  BIT NOT NULL DEFAULT 0,
    created_at DATETIME2(0) NOT NULL DEFAULT SYSDATETIME()
);

-- ===== 2. Phong hoc =====
CREATE TABLE Room (
    room_id                 INT IDENTITY(1,1) PRIMARY KEY,
    room_code               NVARCHAR(32)  NOT NULL UNIQUE,
    name                    NVARCHAR(150) NOT NULL,
    location                NVARCHAR(250) NOT NULL,

    temp_warning_threshold  DECIMAL(10,2) NOT NULL DEFAULT 32,    -- do C
    humid_warning_threshold DECIMAL(10,2) NOT NULL DEFAULT 80,    -- %
    co_warning_threshold    DECIMAL(10,2) NOT NULL DEFAULT 9,     -- ppm
    co2_warning_threshold   DECIMAL(10,2) NOT NULL DEFAULT 1000,  -- ppm

    device_code             NVARCHAR(128) NULL,  -- trung voi Device.room_id, giu de tuong thich DAO
    note                    NVARCHAR(400) NULL,
    is_active               BIT NOT NULL DEFAULT 1,
    created_at              DATETIME2(0) NOT NULL DEFAULT SYSDATETIME()
);

-- ===== 3. Thiet bi =====
CREATE TABLE Device (
    device_id   INT IDENTITY(1,1) PRIMARY KEY,
    device_code NVARCHAR(32)  NOT NULL UNIQUE,
    api_key     NVARCHAR(64)  NOT NULL,   -- board gui qua header X-API-Key
    note        NVARCHAR(150) NULL,
    last_seen   DATETIME2(0)  NULL,
    is_active   BIT NOT NULL DEFAULT 1,
    room_id     INT NULL,
    CONSTRAINT FK_Device_Room FOREIGN KEY (room_id) REFERENCES Room(room_id)
);

CREATE TABLE RejectedPacket (
    reject_id   INT IDENTITY(1,1) PRIMARY KEY,
    raw_body    NVARCHAR(MAX) NULL,
    device_code NVARCHAR(32)  NULL,
    reason      NVARCHAR(200) NOT NULL,
    received_at DATETIME2(0)  NOT NULL DEFAULT SYSDATETIME()
);

-- ===== 4. Phien do (bang chinh cua de tai) =====
CREATE TABLE Air_Session (
    session_id  INT IDENTITY(1,1) PRIMARY KEY,
    device_id   INT NOT NULL FOREIGN KEY REFERENCES Device(device_id),
    device_seq  INT NOT NULL,            -- bo dem tren board, dung de loai ban ghi trung
    measured_at DATETIME2(0) NOT NULL,   -- thoi diem board do
    co          INT NULL,
    co2         INT NULL,
    temperature DECIMAL(9,2) NULL,
    humid       DECIMAL(9,2) NULL,
    note        NVARCHAR(1000) NULL,
    CONSTRAINT UQ_Air_Session_seq UNIQUE (device_id, device_seq)
);

CREATE INDEX IX_Air_Session_measured ON Air_Session(measured_at DESC);
CREATE INDEX IX_Air_Session_device   ON Air_Session(device_id, measured_at DESC);

-- Command --
CREATE TABLE Device_Command (
    command_id INT IDENTITY(1,1) PRIMARY KEY,
    device_id  INT NOT NULL FOREIGN KEY REFERENCES Device(device_id),
    room_id    INT NOT NULL FOREIGN KEY REFERENCES Room(room_id),
    command    NVARCHAR(16) NOT NULL DEFAULT N'START',
    status     NVARCHAR(16) NOT NULL DEFAULT N'PENDING',
    created_at DATETIME2(0) NOT NULL DEFAULT SYSDATETIME(),
    sent_at    DATETIME2(0) NULL,
    done_at    DATETIME2(0) NULL,
    session_id INT NULL FOREIGN KEY REFERENCES Air_Session(session_id),
    CONSTRAINT CK_Device_Command_status
        CHECK (status IN (N'PENDING', N'SENT', N'DONE', N'TIMEOUT'))
);
CREATE INDEX IX_Device_Command_poll ON Device_Command(device_id, status, created_at);

-- ===== 5. Canh bao =====
CREATE TABLE Air_Alert (
    alert_id    INT IDENTITY(1,1) PRIMARY KEY,
    session_id  INT NULL FOREIGN KEY REFERENCES Air_Session(session_id),
    alert_code  NVARCHAR(16)  NOT NULL UNIQUE,   -- A001, A002, ...
    alert_type  NVARCHAR(16)  NOT NULL,          -- TEMPERATURE, HUMID, CO2, CO
    message     NVARCHAR(400) NOT NULL,
    status      NVARCHAR(16)  NOT NULL DEFAULT N'OPENING',  -- OPENING, APPROVED, REJECTED
    handled_by  INT NULL FOREIGN KEY REFERENCES AppUser(user_id),
    note        NVARCHAR(400) NULL,
    created_at  DATETIME2(0)  NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT CK_Air_Alert_type   CHECK (alert_type IN (N'TEMPERATURE', N'HUMID', N'CO2', N'CO')),
    CONSTRAINT CK_Air_Alert_status CHECK (status IN (N'OPENING', N'APPROVED', N'REJECTED'))
);

CREATE INDEX IX_Air_Alert_status  ON Air_Alert(status, created_at DESC);
CREATE INDEX IX_Air_Alert_session ON Air_Alert(session_id);
GO

-- ===== 6. Du lieu khoi tao =====
INSERT INTO AppRole(role_code, role_name) VALUES
    (N'ADMIN',           N'ADMIN'),
    (N'OPERATOR',        N'OPERATOR'),
    (N'VIEWER',          N'VIEWER');

-- Moi tai khoan co mat khau 123456.
DECLARE @h NVARCHAR(200) = N'20000:a0dee5aba0d8cc258ed13fa22d6b729e:7cc4e6fd505db9217ae726189980404174314d771379ca4d98798889d015a124';

INSERT INTO AppUser(username, pass_hash, full_name, role_id)
SELECT v.u, @h, v.n, r.role_id
FROM (VALUES
    (N'admin',           N'Tai khoan ADMIN',           N'ADMIN'),
    (N'operator',        N'Tai khoan OPERATOR',        N'OPERATOR'),
    (N'viewer',          N'Tai khoan VIEWER',          N'VIEWER')
) AS v(u, n, rc)
JOIN AppRole r ON r.role_code = v.rc;
GO