USE AirRoomDB;
GO

-- 1. Xóa toàn bộ nhãn cũ của dữ liệu mẫu để tránh bị trùng lặp
DELETE FROM Air_Label 
WHERE session_id IN (SELECT session_id FROM Air_Session WHERE is_sample = 1);

-- 2. Phân loại lại nhãn dựa theo đúng logic của lớp AirRuleEngine
INSERT INTO Air_Label (session_id, label_code, source, reason)
SELECT 
    session_id,
    CASE 
        WHEN gas_a_raw >= 620 AND gas_a_delta >= 300 AND gas_b_raw >= 340 THEN 'HIGH'
        WHEN base_shift >= 14 AND gas_a_base >= 300 AND gas_a_raw >= 300 THEN 'DRIFTED'
        WHEN temp_c >= 33 AND gas_a_delta >= 30 AND humid_pct <= 58 THEN 'TEMP_EFFECT'
        WHEN warm = 0 AND gas_a_raw >= 420 AND gas_a_delta >= 150 THEN 'WARMUP'
        WHEN gas_a_raw >= 300 AND gas_a_delta >= 60 THEN 'RAISED'
        ELSE 'BASE'
    END AS label_code,
    'RULE' AS source,
    N'Phân loại bằng SQL cho Front-end' AS reason
FROM Air_Session
WHERE is_sample = 1;