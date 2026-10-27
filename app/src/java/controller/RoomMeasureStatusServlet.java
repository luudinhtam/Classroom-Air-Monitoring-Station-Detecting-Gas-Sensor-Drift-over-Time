package controller;

import dao.AirSessionDAO;
import dao.RoomDAO;
import java.io.IOException;
import java.sql.Timestamp;
import java.util.List;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import model.AirAlert;
import model.AirSession;
import model.MeasureResult;
import model.Room;
import service.MeasureException;
import service.MeasureService;

/**
 * Servlet cung cấp trạng thái và kết quả đo thời gian thực cho Web (polling mỗi giây).
 * URL: GET /admin/rooms/measure/status?id=<room_code>&commandId=<số nguyên >= 0>
 */
@WebServlet("/admin/rooms/measure/status")
public class RoomMeasureStatusServlet extends HttpServlet {

    private final MeasureService measureService = new MeasureService();
    private final RoomDAO roomDAO = RoomDAO.getInstance();
    private final AirSessionDAO sessionDAO = new AirSessionDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");

        String roomCode = req.getParameter("id");
        if (roomCode == null || roomCode.trim().isEmpty()) {
            roomCode = req.getParameter("roomCode");
        }

        String commandIdParam = req.getParameter("commandId");

        // 1. Validate tham số id (room_code)
        if (!MeasureWebUtil.isValidRoomCode(roomCode)) {
            MeasureWebUtil.writeError(resp, HttpServletResponse.SC_BAD_REQUEST,
                    "INVALID_DATA", "Mã phòng (id) không hợp lệ hoặc bị để trống");
            return;
        }

        // 2. Validate tham số commandId (phải là số nguyên >= 0)
        Integer commandId = MeasureWebUtil.parseCommandId(commandIdParam);
        if (commandId == null) {
            MeasureWebUtil.writeError(resp, HttpServletResponse.SC_BAD_REQUEST,
                    "INVALID_DATA", "Mã lệnh (commandId) không hợp lệ (phải là số nguyên >= 0)");
            return;
        }

        try {
            MeasureResult result = measureService.getStatusByRoomCode(commandId, roomCode.trim());
            String status = result != null ? result.getStatus() : "UNKNOWN";

            StringBuilder json = new StringBuilder();
            json.append("{");
            json.append("\"commandId\":").append(commandId).append(",");
            json.append("\"status\":\"").append(MeasureWebUtil.escapeJson(status)).append("\",");

            if ("DONE".equalsIgnoreCase(status) && result != null) {
                // Lấy thông tin phòng để nạp ngưỡng an toàn
                Room room = roomDAO.findByCode(roomCode.trim());
                float tempTh = (room != null && room.getTempWarningThreshold() > 0) ? room.getTempWarningThreshold() : 32.0f;
                float humidTh = (room != null && room.getHumidWarningThreshold() > 0) ? room.getHumidWarningThreshold() : 80.0f;
                float coTh = (room != null && room.getCoWarningThreshold() > 0) ? room.getCoWarningThreshold() : 9.0f;
                float co2Th = (room != null && room.getCo2WarningThreshold() > 0) ? room.getCo2WarningThreshold() : 1000.0f;

                // Lấy thời điểm đo: ưu tiên từ result, fallback từ Air_Session nếu null
                Timestamp measuredAt = result.getMeasuredAt();
                if (measuredAt == null && result.getSessionId() != null && result.getSessionId() >= 0) {
                    AirSession sess = sessionDAO.findById(result.getSessionId());
                    if (sess != null) {
                        measuredAt = sess.getMeasuredAt();
                    }
                }
                String measuredAtStr = MeasureWebUtil.formatDate(measuredAt);

                json.append("\"result\":{");
                json.append("\"sessionId\":").append(result.getSessionId() != null ? result.getSessionId() : "null").append(",");
                json.append("\"measuredAt\":\"").append(MeasureWebUtil.escapeJson(measuredAtStr)).append("\",");
                json.append("\"temp\":").append(MeasureWebUtil.formatDecimal(result.getTemperature())).append(",");
                json.append("\"humid\":").append(MeasureWebUtil.formatDecimal(result.getHumid())).append(",");
                json.append("\"co\":").append(result.getCo() != null ? result.getCo() : "null").append(",");
                json.append("\"co2\":").append(result.getCo2() != null ? result.getCo2() : "null").append(",");

                // Ngưỡng cảnh báo của phòng
                json.append("\"thresholds\":{");
                json.append("\"temp\":").append(MeasureWebUtil.formatDecimal(tempTh)).append(",");
                json.append("\"humid\":").append(MeasureWebUtil.formatDecimal(humidTh)).append(",");
                json.append("\"co\":").append(MeasureWebUtil.formatDecimal(coTh)).append(",");
                json.append("\"co2\":").append(MeasureWebUtil.formatDecimal(co2Th));
                json.append("},");

                // Danh sách cảnh báo phát sinh
                json.append("\"alerts\":[");
                List<AirAlert> alerts = result.getAlerts();
                if (alerts != null && !alerts.isEmpty()) {
                    for (int i = 0; i < alerts.size(); i++) {
                        AirAlert a = alerts.get(i);
                        if (i > 0) json.append(",");
                        json.append("{");
                        json.append("\"alertCode\":\"").append(MeasureWebUtil.escapeJson(a.getAlertCode())).append("\",");
                        json.append("\"type\":\"").append(MeasureWebUtil.escapeJson(a.getAlertType() != null ? a.getAlertType() : "")).append("\",");
                        json.append("\"message\":\"").append(MeasureWebUtil.escapeJson(a.getMessage())).append("\",");
                        json.append("\"status\":\"").append(MeasureWebUtil.escapeJson(a.getStatus() != null ? a.getStatus() : "OPENING")).append("\"");
                        json.append("}");
                    }
                }
                json.append("]");
                json.append("}");
            } else {
                json.append("\"result\":null");
            }

            json.append("}");
            MeasureWebUtil.writeJson(resp, HttpServletResponse.SC_OK, json.toString());

        } catch (MeasureException me) {
            MeasureWebUtil.handleMeasureException(resp, me);
        } catch (Exception e) {
            e.printStackTrace();
            MeasureWebUtil.writeError(resp, HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                    "SYSTEM_ERROR", "Lỗi hệ thống khi tra cứu trạng thái đo");
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        MeasureWebUtil.writeError(resp, HttpServletResponse.SC_METHOD_NOT_ALLOWED,
                "METHOD_NOT_ALLOWED", "Phương thức POST không được hỗ trợ cho endpoint status. Hãy sử dụng GET.");
    }
}
