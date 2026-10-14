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

        String ruleCode = req.getParameter("ruleCode");
        if (ruleCode != null && ruleCode.trim().isEmpty()) ruleCode = null;

        String severity = req.getParameter("severity");
        if (severity != null && severity.trim().isEmpty()) severity = null;

        int page = 1;
        try {
            String pStr = req.getParameter("page");
            if (pStr != null) page = Integer.parseInt(pStr);
            if (page < 1) page = 1;
        } catch (NumberFormatException ignored) {}

        int size = 20;

        List<AirAlert> alerts = alertDAO.search(status, ruleCode, severity, page, size);
        int total = alertDAO.count(status, ruleCode, severity);
        int totalPages = (int) Math.ceil((double) total / size);
        if (totalPages < 1) totalPages = 1;

        // Thống kê nhanh số lượng theo trạng thái để hiển thị tabs
        int openCount = alertDAO.count("OPEN", null, null);
        int ackedCount = alertDAO.count("ACKED", null, null);
        int rejectedCount = alertDAO.count("REJECTED", null, null);
        int allCount = alertDAO.count(null, null, null);

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
        if (note != null) note = note.trim();

        if (idStr != null && action != null) {
            try {
                int alertId = Integer.parseInt(idStr);
                String newStatus = "ACKED";
                String actionText = "acknowledged";

                if ("reject".equalsIgnoreCase(action)) {
                    newStatus = "REJECTED";
                    actionText = "rejected";
                    if (note == null || note.isEmpty()) {
                        note = "Rejected alert (False alarm / Noise)";
                    }
                } else {
                    if (note == null || note.isEmpty()) {
                        note = "Incident confirmed";
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
        String redirectUrl = req.getContextPath() + "/alerts";
        if (backStatus != null && !backStatus.isEmpty()) {
            redirectUrl += "?status=" + backStatus;
        }
        resp.sendRedirect(redirectUrl);
    }
}
