INSERT INTO Device (device_code, api_key, location, last_seen, is_active) VALUES
('Air-02', 'demo-key-air-0002', N'Phòng Lab IoT', '2026-10-10 08:15:00', 1),
('Air-03', 'demo-key-air-0003', N'Phòng Thí nghiệm Hóa học', '2026-10-10 09:30:22', 1),
('Air-04', 'demo-key-air-0004', N'Sảnh chính Tòa A', '2026-10-09 18:45:10', 1),
('Air-05', 'demo-key-air-0005', N'Thư viện tầng 2', '2026-10-10 10:00:00', 1),
('Air-06', 'demo-key-air-0006', N'Phòng Máy chủ (Server Room)', '2026-10-10 09:55:00', 1),
('Air-07', 'demo-key-air-0007', N'Căng tin Sinh viên', '2026-10-08 12:30:00', 0),
('Air-08', 'demo-key-air-0008', N'Phòng Hội trường B', '2026-10-10 07:20:15', 1),
('Air-09', 'demo-key-air-0009', N'Khu vực Bãi xe ngầm', NULL, 0),
('Air-10', 'demo-key-air-0010', N'Phòng làm việc Giảng viên', '2026-10-10 09:10:05', 1),
('Air-11', 'demo-key-air-0011', N'Sân thượng Tòa B', '2026-10-10 06:00:00', 1);

-- Đồng bộ room_id tương ứng từ bảng Room
UPDATE d
SET d.room_id = r.room_id
FROM Device d
INNER JOIN Room r ON d.device_code = r.device_code;