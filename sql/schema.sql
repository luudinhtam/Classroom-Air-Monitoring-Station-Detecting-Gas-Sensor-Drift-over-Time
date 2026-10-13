IF DB_ID('AirRoomDB') IS NULL
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
 
-- ===== 2. Thiet bi =====
CREATE TABLE Device (
    device_id   INT IDENTITY(1,1) PRIMARY KEY,
    device_code NVARCHAR(32)  NOT NULL UNIQUE,
    api_key     NVARCHAR(64)  NOT NULL,  -- sent by the board in the X-API-Key header
    location    NVARCHAR(150) NULL,
    last_seen   DATETIME2(0)  NULL,
    is_active   BIT NOT NULL DEFAULT 1
);
 
CREATE TABLE RejectedPacket (
    reject_id   INT IDENTITY(1,1) PRIMARY KEY,
    raw_body    NVARCHAR(MAX) NULL,
    device_code NVARCHAR(32)  NULL,
    reason      NVARCHAR(200) NOT NULL,
    received_at DATETIME2(0)  NOT NULL DEFAULT SYSDATETIME()
);
 
-- ===== 3. Bang phien, bang chinh cua de tai =====
CREATE TABLE Air_Session (
    session_id  INT IDENTITY(1,1) PRIMARY KEY,
    device_id   INT NOT NULL FOREIGN KEY REFERENCES Device(device_id),
    device_seq  INT NOT NULL,             -- counter kept by the board, used to drop duplicates
    measured_at DATETIME2(0) NOT NULL,    -- when the board took the measurement
    ingested_at DATETIME2(0) NOT NULL DEFAULT SYSDATETIME(),
    gas_a_raw INT NULL,
    gas_b_raw INT NULL,
    gas_a_base INT NULL,
    gas_a_delta DECIMAL(9,2) NULL,
    temp_c DECIMAL(9,2) NULL,
    humid_pct DECIMAL(9,2) NULL,
    base_shift DECIMAL(9,2) NULL,
    warm BIT NULL,
    is_sample   BIT NOT NULL DEFAULT 0,   -- 1 for seeded rows, 0 for rows from the device
    CONSTRAINT UQ_Air_Session_seq UNIQUE (device_id, device_seq)
);
 
CREATE INDEX IX_Air_Session_measured ON Air_Session(measured_at DESC);
 
-- ===== 4. Bang nhan, tach rieng khoi bang phien =====
CREATE TABLE Air_Label (
    label_id   INT IDENTITY(1,1) PRIMARY KEY,
    session_id INT NOT NULL FOREIGN KEY REFERENCES Air_Session(session_id),
    label_code NVARCHAR(24) NOT NULL,
    source     NVARCHAR(16) NOT NULL,     -- RULE when set by the engine, REVIEWER when corrected
    reason     NVARCHAR(400) NULL,
    labeled_by INT NULL FOREIGN KEY REFERENCES AppUser(user_id),
    labeled_at DATETIME2(0) NOT NULL DEFAULT SYSDATETIME()
);
 
CREATE INDEX IX_Air_Label_session ON Air_Label(session_id, label_id DESC);
 
-- ===== 5. Bang canh bao =====
CREATE TABLE Air_Alert (
    alert_id    INT IDENTITY(1,1) PRIMARY KEY,
    session_id  INT NULL FOREIGN KEY REFERENCES Air_Session(session_id),
    rule_code   NVARCHAR(32)  NOT NULL,
    severity    NVARCHAR(16)  NOT NULL,   -- INFO, WARN, CRITICAL
    message     NVARCHAR(400) NOT NULL,
    status      NVARCHAR(16)  NOT NULL DEFAULT 'OPEN',  -- OPEN, ACKED, REJECTED
    handled_by  INT NULL FOREIGN KEY REFERENCES AppUser(user_id),
    handled_note NVARCHAR(400) NULL,
    created_at  DATETIME2(0) NOT NULL DEFAULT SYSDATETIME()
);
 
-- ===== 6. Cac bang rieng cua de tai =====
CREATE TABLE Air_Station (
    station_id INT IDENTITY(1,1) PRIMARY KEY,
    code                    NVARCHAR(32)  NOT NULL UNIQUE,
    name                    NVARCHAR(150) NOT NULL,
    location                NVARCHAR(250) NOT NULL,

    co_warning_threshold    DECIMAL(10,2) NOT NULL DEFAULT 0,
    co2_warning_threshold   DECIMAL(10,2) NOT NULL DEFAULT 0,
    max_baseline_drift      DECIMAL(10,2) NOT NULL DEFAULT 0,

    -- QUAN TRONG: device_key phai la UNIQUE, de phuc vu testing thi hien tai chua sua. Se sua trong tuong lai.
    device_key              NVARCHAR(128) NOT NULL DEFAULT N'123456',

    note                    NVARCHAR(400) NULL,
    is_active               BIT NOT NULL DEFAULT 1,
    created_at              DATETIME2(0) NOT NULL DEFAULT SYSDATETIME()
);

DROP TABLE Air_Station;
 
CREATE TABLE Air_Calibration (
    calibration_id      INT IDENTITY(1,1) PRIMARY KEY,
    code                NVARCHAR(32)  NOT NULL UNIQUE,
    name                NVARCHAR(150) NOT NULL,
    note                NVARCHAR(400) NULL,

    station_id          INT NOT NULL,
    co_baseline         DECIMAL(10,2) NOT NULL DEFAULT 0,
    co2_baseline        DECIMAL(10,2) NOT NULL DEFAULT 0,

    performed_by        INT NOT NULL,
    calibrated_at       DATETIME2(0) NOT NULL DEFAULT SYSDATETIME()

);

ALTER TABLE Air_Calibration
ADD CONSTRAINT FK_Air_Calibration_Station
        FOREIGN KEY (station_id)
        REFERENCES Air_Station(station_id)

ALTER TABLE Air_Calibration
ADD CONSTRAINT FK_Air_Calibration_User
        FOREIGN KEY (performed_by)
        REFERENCES AppUser(user_id)

DROP TABLE Air_Calibration;
 
CREATE TABLE Air_EmptyWindow (
    empty_window_id INT IDENTITY(1,1) PRIMARY KEY,
    code            NVARCHAR(32) NOT NULL UNIQUE,
    name            NVARCHAR(150) NOT NULL,

    station_id      INT NOT NULL,

    start_at        DATETIME2(0) NOT NULL,
    end_at          DATETIME2(0) NOT NULL,

    marked_by       INT NOT NULL,

    note            NVARCHAR(400) NULL,

    created_at      DATETIME2(0) NOT NULL DEFAULT SYSDATETIME(),

    

    CONSTRAINT CK_Air_EmptyWindow_Time
        CHECK (end_at > start_at)
);

ALTER TABLE Air_EmptyWindow
ADD CONSTRAINT FK_Air_EmptyWindow_Station
        FOREIGN KEY (station_id)
        REFERENCES Air_Station(station_id)

ALTER TABLE Air_EmptyWindow
ADD CONSTRAINT CK_Air_EmptyWindow_Time
        CHECK (end_at > start_at)

DROP TABLE Air_EmptyWindow;
 
-- ===== 7. Du lieu khoi tao =====
INSERT INTO AppRole(role_code, role_name) VALUES
    (N'ADMIN', N'ADMIN'),
    (N'STATION_MANAGER', N'STATION_MANAGER'),
    (N'OPERATOR', N'OPERATOR'),
    (N'REVIEWER', N'REVIEWER'),
    (N'VIEWER', N'VIEWER');
 
-- Every seeded account has the password 123456.
-- The value below is a PBKDF2 hash in the form iterations:salt:hash, produced by
-- PasswordUtil.main. Replace it with your own before the defence.
DECLARE @h NVARCHAR(200) = N'20000:a0dee5aba0d8cc258ed13fa22d6b729e:7cc4e6fd505db9217ae726189980404174314d771379ca4d98798889d015a124';
INSERT INTO AppUser(username, pass_hash, full_name, role_id)
SELECT v.u, @h, v.n, r.role_id
FROM (VALUES
    (N'admin', N'Tai khoan ADMIN', N'ADMIN'),
    (N'station_manager', N'Tai khoan STATION_MANAGER', N'STATION_MANAGER'),
    (N'operator', N'Tai khoan OPERATOR', N'OPERATOR'),
    (N'reviewer', N'Tai khoan REVIEWER', N'REVIEWER'),
    (N'viewer', N'Tai khoan VIEWER', N'VIEWER')
) AS v(u, n, rc)
JOIN AppRole r ON r.role_code = v.rc;
 
INSERT INTO Device(device_code, api_key, location) VALUES
    (N'Air-01', N'demo-key-air-0001', N'Ban thuc hanh so 1');
