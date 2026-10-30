package controller;

import java.io.IOException;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import service.MeasureException;
import service.MeasureService;

/**
 * Servlet tiếp nhận yêu cầu dừng đo từ giao diện Web.
 * URL: POST /admin/rooms/measure/stop
 * Tham số form: id=<room_code>, commandId=<optional>
 */
@WebServlet("/admin/rooms/measure/stop")
public class RoomMeasureStopServlet extends HttpServlet {

    private final MeasureService measureService = new MeasureService();

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");

        String roomCode = req.getParameter("id");
        if (roomCode == null || roomCode.trim().isEmpty()) {
            roomCode = req.getParameter("roomCode");
        }

        if (!MeasureWebUtil.isValidRoomCode(roomCode)) {
            MeasureWebUtil.writeError(resp, HttpServletResponse.SC_BAD_REQUEST,
                    "INVALID_DATA", "Mã phòng (id) không hợp lệ hoặc bị để trống");
            return;
        }

        String commandIdParam = req.getParameter("commandId");
        Integer commandId = null;
        if (commandIdParam != null && !commandIdParam.trim().isEmpty()) {
            commandId = MeasureWebUtil.parseCommandId(commandIdParam);
        }

        try {
            boolean stopped = measureService.stopMeasureByRoomCode(roomCode.trim(), commandId);
            String json = "{\"success\":true,\"status\":\"DONE\",\"stopped\":" + stopped + "}";
            MeasureWebUtil.writeJson(resp, HttpServletResponse.SC_OK, json);
        } catch (MeasureException me) {
            MeasureWebUtil.handleMeasureException(resp, me);
        } catch (Exception e) {
            e.printStackTrace();
            MeasureWebUtil.writeError(resp, HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                    "SYSTEM_ERROR", "Lỗi hệ thống khi dừng đo");
        }
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        MeasureWebUtil.writeError(resp, HttpServletResponse.SC_METHOD_NOT_ALLOWED,
                "METHOD_NOT_ALLOWED", "Phương thức GET không được hỗ trợ cho endpoint stop. Hãy sử dụng POST.");
    }
}
