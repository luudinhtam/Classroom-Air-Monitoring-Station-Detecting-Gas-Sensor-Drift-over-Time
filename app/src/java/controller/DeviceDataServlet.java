package controller;

import dao.DeviceDAO;
import java.io.BufferedReader;
import java.io.IOException;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import model.Device;
import model.MeasureResult;
import service.MeasureException;
import service.MeasureService;

/**
 * Servlet tiếp nhận dữ liệu đo gửi về từ thiết bị IoT sau 5 giây đo.
 * URL: POST /device/data
 * Header xác thực: X-Device-Code, X-API-Key
 */
@WebServlet("/device/data")
public class DeviceDataServlet extends HttpServlet {

    private final DeviceDAO deviceDAO = new DeviceDAO();
    private final MeasureService measureService = new MeasureService();

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        resp.setContentType("application/json;charset=UTF-8");

        String deviceCode = req.getHeader("X-Device-Code");
        String apiKey = req.getHeader("X-API-Key");

        // Xác thực thiết bị qua API Key và Device Code
        Device dev = deviceDAO.authenticate(deviceCode, apiKey);
        if (dev == null) {
            resp.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            resp.getWriter().write("{\"ok\":false,\"error\":\"auth\",\"message\":\"Unauthorized device or invalid API key\"}");
            return;
        }

        String body = readBody(req);
        Integer commandId = optInt(body, "commandId");
        if (commandId == null) commandId = optInt(body, "command_id");

        Double temp = optNum(body, "temperature");
        if (temp == null) temp = optNum(body, "temp");

        Double humid = optNum(body, "humid");
        if (humid == null) humid = optNum(body, "humidity");

        Integer co = optInt(body, "co");
        Integer co2 = optInt(body, "co2");

        if (commandId == null || commandId < 0) {
            resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            resp.getWriter().write("{\"ok\":false,\"error\":\"invalid_data\",\"message\":\"Missing or invalid commandId\"}");
            return;
        }

        try {
            MeasureResult result = measureService.processDeviceData(dev, commandId, temp, humid, co, co2);
            resp.setStatus(HttpServletResponse.SC_OK);
            resp.getWriter().write("{\"ok\":true,\"sessionId\":" + result.getSessionId() + ",\"alertsCount\":" + result.getAlerts().size() + "}");
        } catch (MeasureException me) {
            // Lệnh không tồn tại, sai thiết bị hoặc không ở status SENT -> 409 Conflict
            if (me.getCode() == MeasureException.ErrorCode.INVALID_COMMAND || me.getCode() == MeasureException.ErrorCode.NOT_FOUND) {
                resp.setStatus(HttpServletResponse.SC_CONFLICT);
                resp.getWriter().write("{\"ok\":false,\"error\":\"conflict\",\"message\":\"" + me.getMessage() + "\"}");
            } else if (me.getCode() == MeasureException.ErrorCode.INVALID_DATA) {
                // Dữ liệu đo sai hoặc nằm ngoài dải hợp lý -> 400 Bad Request
                resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                resp.getWriter().write("{\"ok\":false,\"error\":\"invalid_data\",\"message\":\"" + me.getMessage() + "\"}");
            } else {
                resp.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
                resp.getWriter().write("{\"ok\":false,\"error\":\"system_error\",\"message\":\"" + me.getMessage() + "\"}");
            }
        } catch (Exception e) {
            resp.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            resp.getWriter().write("{\"ok\":false,\"error\":\"system_error\",\"message\":\"" + e.getMessage() + "\"}");
        }
    }

    private String readBody(HttpServletRequest req) throws IOException {
        StringBuilder sb = new StringBuilder();
        BufferedReader r = req.getReader();
        String line;
        while ((line = r.readLine()) != null) sb.append(line);
        return sb.toString();
    }

    private Double optNum(String json, String field) {
        String needle = "\"" + field + "\"";
        int i = json.indexOf(needle);
        if (i < 0) return null;
        int c = json.indexOf(':', i + needle.length());
        if (c < 0) return null;
        int s = c + 1;
        while (s < json.length() && Character.isWhitespace(json.charAt(s))) s++;
        int e = s;
        while (e < json.length() && "-+.0123456789eE".indexOf(json.charAt(e)) >= 0) e++;
        if (s == e) return null;
        try {
            return Double.parseDouble(json.substring(s, e));
        } catch (Exception ex) {
            return null;
        }
    }

    private Integer optInt(String json, String field) {
        Double d = optNum(json, field);
        return d != null ? d.intValue() : null;
    }
}
