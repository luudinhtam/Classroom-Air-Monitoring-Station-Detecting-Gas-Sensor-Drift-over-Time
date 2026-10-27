Không sử dụng dữ liệu giả lập, phải lấy từ database
Không được sửa file schema.sql và sample_data.sql
Không được sửa database
Không thêm file sql
Đọc file check.md và AGENTS.md trước khi code
Làm xong 1 bước là phải tóm tắt ngắn gọn vào file check.md

GHI CHÚ SCHEMA (bắt buộc tuân theo)
- Bảng thiết bị tên là Device (số ít). Khóa chính các bảng là INT:
  Device.device_id, Room.room_id, Air_Session.session_id.
- Trên URL, phòng được định danh bằng Room.room_code (ví dụ 'P001'). Method
  nhận room_code thì phải tra ra room_id.
- Ngưỡng nằm ở Room: temp_warning_threshold, humid_warning_threshold,
  co_warning_threshold, co2_warning_threshold.
- Air_Session không có room_id; phòng suy ra từ Device.room_id. Cột
  device_seq là NOT NULL và UNIQUE theo (device_id, device_seq): service tự
  sinh bằng MAX(device_seq)+1 của thiết bị đó, trong cùng transaction. Cột
  measured_at gán SYSDATETIME() phía server. co, co2 là INT; temperature,
  humid là DECIMAL.
- Air_Alert: alert_code NOT NULL UNIQUE (dạng A001...), message NOT NULL do
  service tạo, alert_type chỉ nhận TEMPERATURE | HUMID | CO2 | CO.
- Device có is_active và last_seen: authenticate chỉ chấp nhận is_active = 1,
  và cập nhật last_seen mỗi lần thiết bị gọi hợp lệ.
- Device_Command.device_id, room_id, session_id đều là INT có FOREIGN KEY.