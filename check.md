# TIẾN ĐỘ THỰC HIỆN TÍNH NĂNG MEASURE (DAO + SERVICE)

- [x] **Bước 1: Tạo Entity & Exception/DTO**
  - Tạo `model.DeviceCommand`: Ánh xạ cấu trúc bảng `Device_Command` (command_id, device_id, room_id, command, status, created_at, sent_at, done_at, session_id).
  - Tạo `service.MeasureException`: Định nghĩa các mã lỗi `NO_DEVICE`, `DEVICE_BUSY`, `NOT_FOUND`, `INVALID_COMMAND`, `INVALID_DATA`, `SYSTEM_ERROR`.
  - Tạo `model.MeasureResult`: Chứa kết quả đo gồm status, sessionId, 4 chỉ số và danh sách cảnh báo.

- [x] **Bước 2: Tạo DeviceCommandDAO**
  - `insert(deviceId, roomId)`: Tạo lệnh START PENDING, trả về `command_id`.
  - `findById(commandId)`: Tra cứu thông tin lệnh.
  - `existsActive(deviceId)`: Kiểm tra lệnh PENDING hoặc SENT của thiết bị.
  - `claimPendingForDevice(deviceId)`: Dùng CTE UPDATE + OUTPUT lấy lệnh PENDING cũ nhất thành SENT an toàn concurrency.
  - `markDone(commandId, sessionId, conn)`: Cập nhật SENT -> DONE trong transaction dùng chung.
  - `timeoutExpired(pendingSeconds, sentSeconds)`: Chuyển các lệnh quá hạn sang TIMEOUT.
  - `getMeasurementResult(commandId)`: Lấy 4 chỉ số và danh sách cảnh báo phát sinh từ phiên đo.

- [x] **Bước 3: Bổ sung các DAO có sẵn**
  - `dao.DeviceDAO`:
    - Bổ sung `authenticate(deviceCode, apiKey)`: Kiểm tra đúng code, đúng key và `is_active = 1`, cập nhật `last_seen`.
    - Bổ sung `findActiveByRoom(roomId)`: Tìm thiết bị `is_active = 1` của phòng (qua `room_id` hoặc fallback `r.device_code`).
  - `dao.AirSessionDAO`:
    - Bổ sung `insert(AirSession o, Connection cn)`: Tự động tính `device_seq = MAX(device_seq) + 1` của thiết bị trong cùng transaction, gán `measured_at = SYSDATETIME()` nếu null.
  - `dao.AlertDAO`:
    - Bổ sung `insert(sessionId, alertType, message, Connection cn)`: Tự động sinh `alert_code` dạng `A001...`, gán `status = 'OPENING'` trong cùng transaction.
  - `dao.RoomDAO`: Đã có sẵn `findByCode(code)` và `findById(id)`.

- [x] **Bước 4: Tạo MeasureService**
  - `startMeasure(roomId)` & `startMeasureByRoomCode(roomCode)`: Dọn timeout -> Kiểm tra thiết bị active của phòng -> Kiểm tra bận đo -> Tạo lệnh PENDING.
  - `getCommandForDevice(device)`: Dọn timeout -> Lấy atomic lệnh PENDING cũ nhất và chuyển thành SENT.
  - `getStatus(commandId, roomId)` & `getStatusByRoomCode(commandId, roomCode)`: Dọn timeout -> Kiểm tra lệnh đúng phòng -> Nếu DONE thì nạp số đo và cảnh báo.
  - `processDeviceData(device, commandId, temp, humid, co, co2)`: Thực thi trong 1 transaction khép kín (kiểm tra status SENT, validate biên độ chỉ số, so ngưỡng phòng sinh cảnh báo, insert Air_Session, insert Air_Alert, markDone, commit/rollback an toàn).

- [x] **Bước 5: Kiểm thử biên dịch (Build & Verification)**
  - Đã biên dịch toàn bộ các file mới và sửa bằng `javac -encoding UTF-8`: Hoàn tất 100% với 0 lỗi (Exit Code 0).

- [x] **Bước 6: Khắc phục lỗi chặn request /device/* tại AuthFilter**
  - Cập nhật whitelist trong `filter.AuthFilter` bổ sung `path.startsWith("/device/")`.
  - Cho phép các request IoT (`/device/command`, `/device/data`) đi qua filter mà không bị chuyển hướng sang `/login`.
  - Bảo toàn 100% cơ chế kiểm tra session và phân quyền Role cho `/admin/*`, `/sessions/*`, `/alerts`.

- [x] **Bước 7: Khắc phục lỗi 404 cho /device/command và /device/data**
  - Tạo `controller.DeviceCommandServlet` (`@WebServlet("/device/command")`): Nhận GET, xác thực header `X-Device-Code` và `X-API-Key`, trả về 200 `{"command":"NONE"}` hoặc `{"command":"START","commandId":...}`, sai key trả 401.
  - Tạo `controller.DeviceDataServlet` (`@WebServlet("/device/data")`): Nhận POST, xác thực header, phân giải dữ liệu đo 5s, gọi `MeasureService`, map lỗi chuẩn (409 Conflict cho lệnh sai/timeout, 400 Bad Request cho dữ liệu sai, 401 cho sai key).
  - Đã biên dịch thành công 2 servlet ra `build/web/WEB-INF/classes/controller/`.

- [x] **Bước 8: Sửa lỗi tính device_seq khi device_id = 0**
  - `AirSessionDAO.java`: Sửa điều kiện `o.getDeviceId() >= 0` (thay vì `> 0`) và câu truy vấn `ISNULL(MAX(device_seq), 0) + 1` để chạy câu lệnh MAX với `device_id = 0`, sinh ra đúng `device_seq = 11`.
  - `MeasureService.java`: Sửa các điều kiện kiểm tra `roomId < 0`, `commandId < 0`, `sessionId < 0` để chấp nhận `0` là ID hợp lệ trong DB.
  - `DeviceCommandDAO.java`: Sửa `res.getSessionId() >= 0` để nạp cảnh báo khi `sessionId = 0`.
  - `DeviceDataServlet.java`: Chấp nhận `commandId = 0`.

- [x] **Bước 9: Viết Web Servlets cho tính năng Measure & phân quyền AuthFilter**
  - Tạo `controller.MeasureWebUtil`: Tiện ích dùng chung ghi response JSON, parse ID/tham số, ánh xạ `MeasureException` -> HTTP status và format số thực, ngày giờ `yyyy-MM-dd HH:mm:ss`.
  - Tạo `controller.RoomMeasureStartServlet` (`POST /admin/rooms/measure/start`): Nhận `id` (room_code), gọi `MeasureService.startMeasureByRoomCode`, trả 200 `{"commandId":..,"status":"PENDING"}`. GET trả 405.
  - Tạo `controller.RoomMeasureStatusServlet` (`GET /admin/rooms/measure/status`): Nhận `id` và `commandId`, set `Cache-Control: no-store`, gọi `MeasureService.getStatusByRoomCode`, bổ sung `measuredAt`, `thresholds` (từ `RoomDAO`) và `alerts` khi status = DONE. POST trả 405.
  - Cập nhật `filter.AuthFilter`: Phân quyền `/admin/rooms/measure/start` cho `ADMIN`, `STATION_MANAGER`, `OPERATOR`; `/admin/rooms/measure/status` cho mọi role đã đăng nhập xem phòng. Trả về JSON 401 khi chưa đăng nhập và JSON 403 khi thiếu quyền đối với `/admin/rooms/measure/*`.
  - Bỏ qua endpoint `/admin/rooms/measure/history` do servlet Room Detail (`RoomServlet.java`) đã nạp sẵn 100 phiên đo gần nhất của phòng vào request attribute `recentSessions`.
  - Biên dịch thành công 100% với Exit Code 0.
  - Đã chạy kiểm thử trực tiếp trên Tomcat (Postman/curl suite): xác nhận 13/13 kịch bản đạt chuẩn (401 unauth, 403 viewer forbidden, 302 login redirect, start PENDING, claim SENT, post data DONE kèm 4 chỉ số, thresholds, alerts, DEVICE_BUSY, TIMEOUT, 400, 404, 405).

- [x] **Bước 10: Xây dựng Giao diện Tab Measure (JSP, CSS, JavaScript)**
  - Cập nhật `RoomServlet.java`: Hỗ trợ tham số `id` là `room_code` hoặc số nguyên `roomId`, lấy `activeDevice` từ `DeviceDAO.findActiveByRoom` và nhận biết tham số `tab=measure`.
  - Tạo `app/web/assets/css/room-measure.css`: Thiết kế stepper ngang (Pending -> Measuring -> Done), đếm giây timer, 4 metric cards hiển thị vượt ngưỡng, banners và bảng lịch sử đo.
  - Tạo `app/web/assets/js/room-measure.js`: Quản lý nút Start (chặn double-click), polling status mỗi 1s, timeout tối đa 50s, thử lại mạng thoáng qua 3 lần, xử lý 401/403/409, lưu trữ/phục hồi `commandId` qua `sessionStorage`, an toàn XSS qua `textContent`.
  - Cập nhật `roomDetail.jsp` & `room-detail.js`: Thêm nút tab "Measure", tích hợp HTML `#tab-measure`, đồng bộ URL query param `?tab=measure`, phân quyền role hiển thị nút Start / thông báo quyền.
  - Sửa lỗi lồng thẻ HTML: Bổ sung thẻ đóng `</div>` cho `#tab-charts` trước khi mở `#tab-measure`, khắc phục lỗi `#tab-measure` bị lồng vào tab Charts khiến tab Measure bị ẩn (`display: none`) khi bấm chuyển tab.
  - Biên dịch và đồng bộ vào `app/build/web`: Đã kiểm tra trực tiếp trên Tomcat bằng tài khoản ADMIN và VIEWER, giao diện render chính xác.
