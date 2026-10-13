-- Chay mot lan de co du lieu lam viec truoc khi thiet bi hoat dong.
-- Moi dong sinh ra co is_sample = 1 nen xoa het bang mot cau lenh duy nhat.
DECLARE @dev INT = (SELECT TOP 1 device_id FROM Device WHERE device_code = N'Air-01');
DECLARE @seq INT = ISNULL((SELECT MAX(device_seq) FROM Air_Session WHERE device_id = @dev), 0);
 
-- BASE: 500 phien mau
INSERT INTO Air_Session(device_id, device_seq, measured_at, gas_a_raw, gas_b_raw, gas_a_base, gas_a_delta, temp_c, humid_pct, base_shift, warm, is_sample)
SELECT
        @dev,
        @seq + ROW_NUMBER() OVER (ORDER BY (SELECT NULL)),
        DATEADD(SECOND, 0 - 60 * (ROW_NUMBER() OVER (ORDER BY (SELECT NULL))), SYSDATETIME()),
        120 + ABS(CHECKSUM(NEWID())) % 141 AS gas_a_raw,
        90 + ABS(CHECKSUM(NEWID())) % 121 AS gas_b_raw,
        120 + ABS(CHECKSUM(NEWID())) % 131 AS gas_a_base,
        CAST(-15 + RAND(CHECKSUM(NEWID())) * 40 AS DECIMAL(9,2)) AS gas_a_delta,
        CAST(26 + RAND(CHECKSUM(NEWID())) * 5 AS DECIMAL(9,2)) AS temp_c,
        CAST(55 + RAND(CHECKSUM(NEWID())) * 20 AS DECIMAL(9,2)) AS humid_pct,
        CAST(-4 + RAND(CHECKSUM(NEWID())) * 8 AS DECIMAL(9,2)) AS base_shift,
        (CASE WHEN ABS(CHECKSUM(NEWID())) % 2 = 0 THEN N'1' ELSE N'0' END) AS warm,
        1
FROM (SELECT TOP (500) 1 AS x FROM sys.all_objects a CROSS JOIN sys.all_objects b) AS n;
 
SET @seq = @seq + 500;
 
INSERT INTO Air_Label(session_id, label_code, source, reason)
SELECT s.session_id, N'BASE', N'RULE', N'Nhan gan san cho du lieu mau'
FROM Air_Session s
LEFT JOIN Air_Label l ON l.session_id = s.session_id
WHERE s.is_sample = 1 AND l.label_id IS NULL;
 
-- RAISED: 80 phien mau
INSERT INTO Air_Session(device_id, device_seq, measured_at, gas_a_raw, gas_b_raw, gas_a_base, gas_a_delta, temp_c, humid_pct, base_shift, warm, is_sample)
SELECT
        @dev,
        @seq + ROW_NUMBER() OVER (ORDER BY (SELECT NULL)),
        DATEADD(SECOND, -90000 - 60 * (ROW_NUMBER() OVER (ORDER BY (SELECT NULL))), SYSDATETIME()),
        300 + ABS(CHECKSUM(NEWID())) % 221 AS gas_a_raw,
        90 + ABS(CHECKSUM(NEWID())) % 121 AS gas_b_raw,
        120 + ABS(CHECKSUM(NEWID())) % 131 AS gas_a_base,
        CAST(60 + RAND(CHECKSUM(NEWID())) * 130 AS DECIMAL(9,2)) AS gas_a_delta,
        CAST(26 + RAND(CHECKSUM(NEWID())) * 5 AS DECIMAL(9,2)) AS temp_c,
        CAST(55 + RAND(CHECKSUM(NEWID())) * 20 AS DECIMAL(9,2)) AS humid_pct,
        CAST(-4 + RAND(CHECKSUM(NEWID())) * 8 AS DECIMAL(9,2)) AS base_shift,
        (CASE WHEN ABS(CHECKSUM(NEWID())) % 2 = 0 THEN N'1' ELSE N'0' END) AS warm,
        1
FROM (SELECT TOP (80) 1 AS x FROM sys.all_objects a CROSS JOIN sys.all_objects b) AS n;
 
SET @seq = @seq + 80;
 
INSERT INTO Air_Label(session_id, label_code, source, reason)
SELECT s.session_id, N'RAISED', N'RULE', N'Nhan gan san cho du lieu mau'
FROM Air_Session s
LEFT JOIN Air_Label l ON l.session_id = s.session_id
WHERE s.is_sample = 1 AND l.label_id IS NULL;
 
-- HIGH: 60 phien mau
INSERT INTO Air_Session(device_id, device_seq, measured_at, gas_a_raw, gas_b_raw, gas_a_base, gas_a_delta, temp_c, humid_pct, base_shift, warm, is_sample)
SELECT
        @dev,
        @seq + ROW_NUMBER() OVER (ORDER BY (SELECT NULL)),
        DATEADD(SECOND, -180000 - 60 * (ROW_NUMBER() OVER (ORDER BY (SELECT NULL))), SYSDATETIME()),
        620 + ABS(CHECKSUM(NEWID())) % 481 AS gas_a_raw,
        340 + ABS(CHECKSUM(NEWID())) % 421 AS gas_b_raw,
        120 + ABS(CHECKSUM(NEWID())) % 131 AS gas_a_base,
        CAST(300 + RAND(CHECKSUM(NEWID())) * 550 AS DECIMAL(9,2)) AS gas_a_delta,
        CAST(26 + RAND(CHECKSUM(NEWID())) * 5 AS DECIMAL(9,2)) AS temp_c,
        CAST(55 + RAND(CHECKSUM(NEWID())) * 20 AS DECIMAL(9,2)) AS humid_pct,
        CAST(-4 + RAND(CHECKSUM(NEWID())) * 8 AS DECIMAL(9,2)) AS base_shift,
        (CASE WHEN ABS(CHECKSUM(NEWID())) % 2 = 0 THEN N'1' ELSE N'0' END) AS warm,
        1
FROM (SELECT TOP (60) 1 AS x FROM sys.all_objects a CROSS JOIN sys.all_objects b) AS n;
 
SET @seq = @seq + 60;
 
INSERT INTO Air_Label(session_id, label_code, source, reason)
SELECT s.session_id, N'HIGH', N'RULE', N'Nhan gan san cho du lieu mau'
FROM Air_Session s
LEFT JOIN Air_Label l ON l.session_id = s.session_id
WHERE s.is_sample = 1 AND l.label_id IS NULL;
 
-- DRIFTED: 120 phien mau
INSERT INTO Air_Session(device_id, device_seq, measured_at, gas_a_raw, gas_b_raw, gas_a_base, gas_a_delta, temp_c, humid_pct, base_shift, warm, is_sample)
SELECT
        @dev,
        @seq + ROW_NUMBER() OVER (ORDER BY (SELECT NULL)),
        DATEADD(SECOND, -270000 - 60 * (ROW_NUMBER() OVER (ORDER BY (SELECT NULL))), SYSDATETIME()),
        300 + ABS(CHECKSUM(NEWID())) % 141 AS gas_a_raw,
        90 + ABS(CHECKSUM(NEWID())) % 121 AS gas_b_raw,
        300 + ABS(CHECKSUM(NEWID())) % 131 AS gas_a_base,
        CAST(-15 + RAND(CHECKSUM(NEWID())) * 40 AS DECIMAL(9,2)) AS gas_a_delta,
        CAST(26 + RAND(CHECKSUM(NEWID())) * 5 AS DECIMAL(9,2)) AS temp_c,
        CAST(55 + RAND(CHECKSUM(NEWID())) * 20 AS DECIMAL(9,2)) AS humid_pct,
        CAST(14 + RAND(CHECKSUM(NEWID())) * 32 AS DECIMAL(9,2)) AS base_shift,
        (CASE WHEN ABS(CHECKSUM(NEWID())) % 2 = 0 THEN N'1' ELSE N'0' END) AS warm,
        1
FROM (SELECT TOP (120) 1 AS x FROM sys.all_objects a CROSS JOIN sys.all_objects b) AS n;
 
SET @seq = @seq + 120;
 
INSERT INTO Air_Label(session_id, label_code, source, reason)
SELECT s.session_id, N'DRIFTED', N'RULE', N'Nhan gan san cho du lieu mau'
FROM Air_Session s
LEFT JOIN Air_Label l ON l.session_id = s.session_id
WHERE s.is_sample = 1 AND l.label_id IS NULL;
 
-- TEMP_EFFECT: 70 phien mau
INSERT INTO Air_Session(device_id, device_seq, measured_at, gas_a_raw, gas_b_raw, gas_a_base, gas_a_delta, temp_c, humid_pct, base_shift, warm, is_sample)
SELECT
        @dev,
        @seq + ROW_NUMBER() OVER (ORDER BY (SELECT NULL)),
        DATEADD(SECOND, -360000 - 60 * (ROW_NUMBER() OVER (ORDER BY (SELECT NULL))), SYSDATETIME()),
        120 + ABS(CHECKSUM(NEWID())) % 141 AS gas_a_raw,
        90 + ABS(CHECKSUM(NEWID())) % 121 AS gas_b_raw,
        120 + ABS(CHECKSUM(NEWID())) % 131 AS gas_a_base,
        CAST(30 + RAND(CHECKSUM(NEWID())) * 65 AS DECIMAL(9,2)) AS gas_a_delta,
        CAST(33 + RAND(CHECKSUM(NEWID())) * 6 AS DECIMAL(9,2)) AS temp_c,
        CAST(42 + RAND(CHECKSUM(NEWID())) * 16 AS DECIMAL(9,2)) AS humid_pct,
        CAST(-4 + RAND(CHECKSUM(NEWID())) * 8 AS DECIMAL(9,2)) AS base_shift,
        (CASE WHEN ABS(CHECKSUM(NEWID())) % 2 = 0 THEN N'1' ELSE N'0' END) AS warm,
        1
FROM (SELECT TOP (70) 1 AS x FROM sys.all_objects a CROSS JOIN sys.all_objects b) AS n;
 
SET @seq = @seq + 70;
 
INSERT INTO Air_Label(session_id, label_code, source, reason)
SELECT s.session_id, N'TEMP_EFFECT', N'RULE', N'Nhan gan san cho du lieu mau'
FROM Air_Session s
LEFT JOIN Air_Label l ON l.session_id = s.session_id
WHERE s.is_sample = 1 AND l.label_id IS NULL;
 
-- WARMUP: 50 phien mau
INSERT INTO Air_Session(device_id, device_seq, measured_at, gas_a_raw, gas_b_raw, gas_a_base, gas_a_delta, temp_c, humid_pct, base_shift, warm, is_sample)
SELECT
        @dev,
        @seq + ROW_NUMBER() OVER (ORDER BY (SELECT NULL)),
        DATEADD(SECOND, -450000 - 60 * (ROW_NUMBER() OVER (ORDER BY (SELECT NULL))), SYSDATETIME()),
        420 + ABS(CHECKSUM(NEWID())) % 481 AS gas_a_raw,
        90 + ABS(CHECKSUM(NEWID())) % 121 AS gas_b_raw,
        120 + ABS(CHECKSUM(NEWID())) % 131 AS gas_a_base,
        CAST(150 + RAND(CHECKSUM(NEWID())) * 550 AS DECIMAL(9,2)) AS gas_a_delta,
        CAST(26 + RAND(CHECKSUM(NEWID())) * 5 AS DECIMAL(9,2)) AS temp_c,
        CAST(55 + RAND(CHECKSUM(NEWID())) * 20 AS DECIMAL(9,2)) AS humid_pct,
        CAST(-4 + RAND(CHECKSUM(NEWID())) * 8 AS DECIMAL(9,2)) AS base_shift,
        (CASE WHEN ABS(CHECKSUM(NEWID())) % 2 = 0 THEN N'1' ELSE N'0' END) AS warm,
        1
FROM (SELECT TOP (50) 1 AS x FROM sys.all_objects a CROSS JOIN sys.all_objects b) AS n;
 
SET @seq = @seq + 50;
 
INSERT INTO Air_Label(session_id, label_code, source, reason)
SELECT s.session_id, N'WARMUP', N'RULE', N'Nhan gan san cho du lieu mau'
FROM Air_Session s
LEFT JOIN Air_Label l ON l.session_id = s.session_id
WHERE s.is_sample = 1 AND l.label_id IS NULL;
 
-- Kiem tra nhanh so dong theo tung nhan
SELECT l.label_code, COUNT(*) AS so_phien
FROM Air_Session s JOIN Air_Label l ON l.session_id = s.session_id
WHERE s.is_sample = 1
GROUP BY l.label_code
ORDER BY so_phien DESC;
