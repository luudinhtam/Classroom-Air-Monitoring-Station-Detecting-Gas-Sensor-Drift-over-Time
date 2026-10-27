package controller;

import dao.DeviceDAO;
import java.io.IOException;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import model.Device;
import model.DeviceCommand;
import service.MeasureService;

/**
 * Servlet tiếp nhận polling kiểm tra lệnh đo từ thiết bị IoT.
 * URL: GET /device/command
 * Header xác thực: X-Device-Code, X-API-Key
 */
@WebServlet("/device/command")
public class DeviceCommandServlet extends HttpServlet {

    private final DeviceDAO deviceDAO = new DeviceDAO();
    private final MeasureService measureService = new MeasureService();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
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

        // Lấy lệnh đang chờ thực thi cho thiết bị
        DeviceCommand cmd = measureService.getCommandForDevice(dev);
        if (cmd == null) {
            resp.setStatus(HttpServletResponse.SC_OK);
            resp.getWriter().write("{\"command\":\"NONE\"}");
            return;
        }

        resp.setStatus(HttpServletResponse.SC_OK);
        resp.getWriter().write("{\"command\":\"START\",\"commandId\":" + cmd.getCommandId() + "}");
    }
}
