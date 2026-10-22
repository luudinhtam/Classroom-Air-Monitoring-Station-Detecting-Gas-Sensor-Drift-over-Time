USE AirRoomDB;
GO
-- Thêm 2 cột lưu tọa độ GPS (mặc định lấy tọa độ khuôn viên ĐH FPT TP.HCM)
ALTER TABLE Room ADD latitude DECIMAL(10, 6) DEFAULT 10.841129;
ALTER TABLE Room ADD longitude DECIMAL(10, 6) DEFAULT 106.809883;
GO