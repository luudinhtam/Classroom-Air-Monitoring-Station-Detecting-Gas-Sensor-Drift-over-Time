USE AirRoomDB;
GO

-- ===== 0. Don du lieu cu (dung thu tu khoa ngoai) =====
DELETE FROM Air_Alert;
DELETE FROM Air_Session;
DELETE FROM RejectedPacket;
UPDATE Device SET room_id = NULL;
DELETE FROM Device;
DELETE FROM Room;

DBCC CHECKIDENT ('Air_Alert',   RESEED, 0);
DBCC CHECKIDENT ('Air_Session', RESEED, 0);
DBCC CHECKIDENT ('Device',      RESEED, 0);
DBCC CHECKIDENT ('Room',        RESEED, 0);
GO

-- ===== 1. Phong P001 (nguong: temp 32, humid 80, CO 9, CO2 1000) =====
INSERT INTO Room (room_code, name, location, device_code, note)
VALUES (N'P001', N'Phòng P001', N'Tòa A - Tầng 1', N'D001', N'Phòng demo');
GO

-- ===== 2. Thiet bi D001 cua phong P001 =====
DECLARE @roomId INT = (SELECT room_id FROM Room WHERE room_code = N'P001');

INSERT INTO Device (device_code, api_key, note, room_id)
VALUES (N'D001', N'demo-key-d001', N'Phòng P001', @roomId);
GO

-- ===== 3. 10 phien do cua P001 =====
-- Phien 3, 4, 5, 6 moi phien vuot dung 1 chi so; phien 1, 2, 7, 8, 9, 10 khong vuot chi so nao
DECLARE @dev INT = (SELECT device_id FROM Device WHERE device_code = N'D001');

INSERT INTO Air_Session (device_id, device_seq, measured_at, co, co2, temperature, humid, note)
VALUES
(@dev,  1, '2026-10-23 07:00:00',  2,  480, 26.00, 62.00, N'Đầu giờ sáng - không khí trong lành'),
(@dev,  2, '2026-10-23 08:30:00',  3,  650, 27.00, 60.00, N'Tiết 1 - môi trường ổn định'),
(@dev,  3, '2026-10-23 09:45:00',  4, 1250, 28.50, 63.00, N'Phòng đông sinh viên, đóng cửa - CO2 vượt ngưỡng'),
(@dev,  4, '2026-10-23 11:00:00',  3,  820, 33.80, 55.00, N'Trưa nắng, tắt máy lạnh - nhiệt độ vượt ngưỡng'),
(@dev,  5, '2026-10-23 12:15:00', 12,  900, 30.00, 58.00, N'CO tăng đột biến - vượt ngưỡng'),
(@dev,  6, '2026-10-23 13:30:00',  2,  700, 29.00, 83.50, N'Trời mưa - độ ẩm vượt ngưỡng'),
(@dev,  7, '2026-10-23 14:45:00',  3,  760, 28.00, 65.00, N'Chỉ số trở lại bình thường'),
(@dev,  8, '2026-10-23 16:00:00',  4,  840, 27.50, 61.00, N'Tiết cuối - phòng còn ít người'),
(@dev,  9, '2026-10-23 17:15:00',  2,  560, 26.50, 59.00, N'Tan học - phòng trống'),
(@dev, 10, '2026-10-23 18:30:00',  2,  500, 26.00, 60.00, N'Buổi tối - môi trường ổn định');
GO

-- ===== 4. Canh bao: moi phien co chi so vuot nguong deu co canh bao =====
DECLARE @dev     INT = (SELECT device_id FROM Device WHERE device_code = N'D001');
DECLARE @adminId INT = (SELECT user_id FROM AppUser WHERE username = N'admin');

-- Phien 3: CO2 = 1250 > 1000 (APPROVED)
INSERT INTO Air_Alert (session_id, alert_code, alert_type, message, status, handled_by, note, created_at)
SELECT session_id, N'A001', N'CO2',
       N'CO2 vượt ngưỡng tại P001 (1250 ppm, ngưỡng 1000 ppm)',
       N'APPROVED', @adminId, N'Đã mở cửa thông gió, CO2 giảm về mức an toàn', measured_at
FROM Air_Session WHERE device_id = @dev AND device_seq = 3;

-- Phien 4: Nhiet do = 33.8 > 32 (OPENING)
INSERT INTO Air_Alert (session_id, alert_code, alert_type, message, status, handled_by, note, created_at)
SELECT session_id, N'A002', N'TEMPERATURE',
       N'Nhiệt độ vượt ngưỡng tại P001 (33.8°C, ngưỡng 32°C)',
       N'OPENING', NULL, NULL, measured_at
FROM Air_Session WHERE device_id = @dev AND device_seq = 4;

-- Phien 5: CO = 12 > 9 (OPENING)
INSERT INTO Air_Alert (session_id, alert_code, alert_type, message, status, handled_by, note, created_at)
SELECT session_id, N'A003', N'CO',
       N'CO vượt ngưỡng tại P001 (12 ppm, ngưỡng 9 ppm)',
       N'OPENING', NULL, NULL, measured_at
FROM Air_Session WHERE device_id = @dev AND device_seq = 5;

-- Phien 6: Do am = 83.5 > 80 (REJECTED)
INSERT INTO Air_Alert (session_id, alert_code, alert_type, message, status, handled_by, note, created_at)
SELECT session_id, N'A004', N'HUMID',
       N'Độ ẩm vượt ngưỡng tại P001 (83.5%, ngưỡng 80%)',
       N'REJECTED', @adminId, N'Báo động giả: trời mưa, độ ẩm giảm sau ít phút', measured_at
FROM Air_Session WHERE device_id = @dev AND device_seq = 6;
GO

-- ===== 5. Kiem tra so luong: Room 1, Device 1, Air_Session 10, Air_Alert 4 =====
SELECT 'Room' AS TableName, COUNT(*) AS TotalRows FROM Room
UNION ALL SELECT 'Device',      COUNT(*) FROM Device
UNION ALL SELECT 'Air_Session', COUNT(*) FROM Air_Session
UNION ALL SELECT 'Air_Alert',   COUNT(*) FROM Air_Alert;
GO

-- ===== 6. Kiem tra rang buoc: phai tra ve 0 dong =====
-- Neu co dong, phien do do vuot nguong nhung chua co canh bao
SELECT s.session_id, s.device_seq, v.code AS chi_so_vuot_nguong
FROM Air_Session s
JOIN Device d ON d.device_id = s.device_id
JOIN Room   r ON r.room_id   = d.room_id
CROSS APPLY (VALUES
    (N'CO2',         CAST(s.co2         AS DECIMAL(10,2)), r.co2_warning_threshold),
    (N'CO',          CAST(s.co          AS DECIMAL(10,2)), r.co_warning_threshold),
    (N'TEMPERATURE', CAST(s.temperature AS DECIMAL(10,2)), r.temp_warning_threshold),
    (N'HUMID',       CAST(s.humid       AS DECIMAL(10,2)), r.humid_warning_threshold)
) AS v(code, val, thr)
WHERE v.val > v.thr
  AND NOT EXISTS (
      SELECT 1 FROM Air_Alert a
      WHERE a.session_id = s.session_id AND a.alert_type = v.code
  );
GO