USE AirroomDB;
GO

-- 1. Lấy ID của thiết bị Air-01 và số sequence lớn nhất
DECLARE @dev INT = (SELECT TOP 1 device_id FROM Device WHERE device_code = N'Air-01');
DECLARE @seq INT = ISNULL((SELECT MAX(device_seq) FROM Air_Session WHERE device_id = @dev), 0);

-- 2. Chép dữ liệu từ Temp_AirQuality sang Air_Session
INSERT INTO Air_Session (
    device_id, 
    device_seq, 
    measured_at, 
    gas_a_raw,    -- PT08_S1_CO
    gas_b_raw,    -- PT08_S2_NMHC
    gas_a_base,   
    gas_a_delta,  
    temp_c,       -- T
    humid_pct,    -- RH
    base_shift,   
    warm,         
    is_sample     
)
SELECT 
    @dev,
    @seq + ROW_NUMBER() OVER (ORDER BY [Date], [Time]) AS device_seq,
    
    -- Ghép Ngày và Giờ trực tiếp thành DATETIME2
    CAST(CONCAT(CAST([Date] AS VARCHAR(10)), ' ', CAST([Time] AS VARCHAR(8))) AS DATETIME2(0)) AS measured_at,
    
    -- Xử lý ép kiểu dữ liệu cảm biến & nhiệt ẩm
    CAST(REPLACE(CAST([PT08_S1_CO] AS VARCHAR(50)), ',', '.') AS INT) AS gas_a_raw,
    CAST(REPLACE(CAST([PT08_S2_NMHC] AS VARCHAR(50)), ',', '.') AS INT) AS gas_b_raw,
    
    1200 AS gas_a_base,
    CAST(REPLACE(CAST([PT08_S1_CO] AS VARCHAR(50)), ',', '.') AS DECIMAL(9,2)) - 1200 AS gas_a_delta,
    CAST(REPLACE(CAST([T] AS VARCHAR(50)), ',', '.') AS DECIMAL(9,2)) AS temp_c,
    CAST(REPLACE(CAST([RH] AS VARCHAR(50)), ',', '.') AS DECIMAL(9,2)) AS humid_pct,
    0.00 AS base_shift,
    1 AS warm,
    1 AS is_sample
FROM Tenp_AirQuality
-- LỌC BỎ DÒNG LỖI -200 THEO ĐÚNG YÊU CẦU ĐỀ TÀI
WHERE [Date] IS NOT NULL 
  AND TRY_CAST(REPLACE(CAST([PT08_S1_CO] AS VARCHAR(50)), ',', '.') AS FLOAT) <> -200 
  AND TRY_CAST(REPLACE(CAST([PT08_S2_NMHC] AS VARCHAR(50)), ',', '.') AS FLOAT) <> -200 
  AND TRY_CAST(REPLACE(CAST([T] AS VARCHAR(50)), ',', '.') AS FLOAT) <> -200 
  AND TRY_CAST(REPLACE(CAST([RH] AS VARCHAR(50)), ',', '.') AS FLOAT) <> -200;

-- 3. Gán nhãn BASE mặc định cho dữ liệu vừa nạp
INSERT INTO Air_Label (session_id, label_code, source, reason)
SELECT s.session_id, N'BASE', N'RULE', N'Nạp từ bộ dữ liệu nền UCI 360'
FROM Air_Session s
LEFT JOIN Air_Label l ON l.session_id = s.session_id
WHERE s.is_sample = 1 AND l.label_id IS NULL;