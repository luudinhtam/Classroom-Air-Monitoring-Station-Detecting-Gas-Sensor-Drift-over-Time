package controller;

import dao.AlertDAO;
import java.io.IOException;
import java.util.List;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import model.AirAlert;
import model.AppUser;

@WebServlet("/alerts")
public class AlertServlet extends HttpServlet {

    private final AlertDAO alertDAO = new AlertDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String status = req.getParameter("status");
        if (status != null && status.trim().isEmpty()) status = null;
        if ("OPEN".equalsIgnoreCase(status)) status = "OPENING";
        else if ("ACKED".equalsIgnoreCase(status)) status = "APPROVED";

        String ruleCode = req.getParameter("ruleCode");
        if (ruleCode != null && ruleCode.trim().isEmpty()) ruleCode = null;

        String severity = req.getParameter("severity");
        if (severity != null && severity.trim().isEmpty()) severity = null;

        Integer roomId = null;
        try {
            String rStr = req.getParameter("roomId");
            if (rStr != null && !rStr.trim().isEmpty()) {
                int parsed = Integer.parseInt(rStr.trim());
                if (parsed > 0) roomId = parsed;
            }
        } catch (NumberFormatException ignored) {}

        int page = 1;
        try {
            String pStr = req.getParameter("page");
            if (pStr != null) page = Integer.parseInt(pStr);
            if (page < 1) page = 1;
        } catch (NumberFormatException ignored) {}

        int size = 10;

        List<model.Room> roomList = dao.RoomDAO.getInstance().search(null, null);
        req.setAttribute("roomList", roomList);
        req.setAttribute("currentRoomId", roomId);

        List<AirAlert> alerts = alertDAO.search(status, ruleCode, roomId, page, size);
        int total = alertDAO.count(status, ruleCode, roomId);
        int totalPages = (int) Math.ceil((double) total / size);
        if (totalPages < 1) totalPages = 1;

        // Thống kê số lượng theo trạng thái chuẩn trong database (theo phòng nếu có lọc)
        int openCount = alertDAO.count("OPENING", null, roomId);
        int ackedCount = alertDAO.count("APPROVED", null, roomId);
        int rejectedCount = alertDAO.count("REJECTED", null, roomId);
        int allCount = alertDAO.count(null, null, roomId);

        req.setAttribute("alerts", alerts);
        req.setAttribute("page", page);
        req.setAttribute("size", size);
        req.setAttribute("total", total);
        req.setAttribute("totalPages", totalPages);

        req.setAttribute("currentStatus", status);
        req.setAttribute("currentRuleCode", ruleCode);
        req.setAttribute("currentSeverity", severity);

        req.setAttribute("openCount", openCount);
        req.setAttribute("ackedCount", ackedCount);
        req.setAttribute("rejectedCount", rejectedCount);
        req.setAttribute("allCount", allCount);

        req.getRequestDispatcher("/WEB-INF/views/alertList.jsp").forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        AppUser me = (AppUser) req.getSession().getAttribute("user");
        if (me == null) {
            resp.sendRedirect(req.getContextPath() + "/login");
            return;
        }

        // Kiểm tra quyền: VIEWER chỉ có quyền xem
        if ("VIEWER".equals(me.getRoleCode())) {
            resp.sendError(HttpServletResponse.SC_FORBIDDEN, "You do not have permission to handle alerts.");
            return;
        }

        req.setCharacterEncoding("UTF-8");
        String action = req.getParameter("action");
        String idStr = req.getParameter("alertId");
        String note = req.getParameter("handledNote");
        String statusParam = req.getParameter("status");
        if (note != null) note = note.trim();

        if (idStr != null) {
            try {
                int alertId = Integer.parseInt(idStr);
                String newStatus = "APPROVED";
                String actionText = "approved";

                if (statusParam != null && !statusParam.trim().isEmpty()) {
                    if ("REJECTED".equalsIgnoreCase(statusParam) || "reject".equalsIgnoreCase(statusParam)) {
                        newStatus = "REJECTED";
                        actionText = "rejected";
                    } else if ("APPROVED".equalsIgnoreCase(statusParam) || "approve".equalsIgnoreCase(statusParam) || "ack".equalsIgnoreCase(statusParam)) {
                        newStatus = "APPROVED";
                        actionText = "approved";
                    } else if ("OPENING".equalsIgnoreCase(statusParam) || "OPEN".equalsIgnoreCase(statusParam)) {
                        newStatus = "OPENING";
                        actionText = "updated to opening";
                    }
                } else if ("reject".equalsIgnoreCase(action)) {
                    newStatus = "REJECTED";
                    actionText = "rejected";
                } else {
                    newStatus = "APPROVED";
                    actionText = "approved";
                }

                if (note == null || note.isEmpty()) {
                    if ("REJECTED".equals(newStatus)) {
                        note = "Rejected alert (False alarm / Noise)";
                    } else if ("APPROVED".equals(newStatus)) {
                        note = "Incident confirmed / Approved";
                    }
                }

                boolean ok = alertDAO.updateStatus(alertId, newStatus, me.getUserId(), note);
                if (ok) {
                    req.getSession().setAttribute("flash", "Alert #" + alertId + " " + actionText + " successfully.");
                } else {
                    req.getSession().setAttribute("flashError", "Could not update alert #" + alertId + ".");
                }
            } catch (NumberFormatException ignored) {}
        }

        String backStatus = req.getParameter("backStatus");
        String backRoomId = req.getParameter("backRoomId");
        StringBuilder redirectUrl = new StringBuilder(req.getContextPath()).append("/alerts?");
        if (backStatus != null && !backStatus.isEmpty()) {
            redirectUrl.append("status=").append(backStatus).append("&");
        }
        if (backRoomId != null && !backRoomId.isEmpty()) {
            redirectUrl.append("roomId=").append(backRoomId).append("&");
        }
        String finalUrl = redirectUrl.toString();
        if (finalUrl.endsWith("?") || finalUrl.endsWith("&")) {
            finalUrl = finalUrl.substring(0, finalUrl.length() - 1);
        }
        resp.sendRedirect(finalUrl);
    }
}
