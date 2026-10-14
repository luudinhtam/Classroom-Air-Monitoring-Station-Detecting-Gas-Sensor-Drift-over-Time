package controller;

import java.io.IOException;
import javax.servlet.*;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import dao.LabelDAO;
import model.AppUser;

/**
 * Lets a reviewer correct a label. The old label row is kept, a new one is
 * appended with source REVIEWER, so the history of every correction survives
 * and the report can count how often the rule engine was wrong.
 */
@WebServlet("/label/correct")
public class LabelCorrectServlet extends HttpServlet {

    private final LabelDAO labels = new LabelDAO();

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        AppUser me = (AppUser) req.getSession().getAttribute("user");
        int sessionId = Integer.parseInt(req.getParameter("sessionId"));
        String newLabel = req.getParameter("labelCode");
        String reason = req.getParameter("reason");

        if (reason == null || reason.trim().length() < 5) {
            req.getSession().setAttribute("flash", "A reason is required to correct the label (at least 5 characters)");
            resp.sendRedirect(req.getContextPath() + "/session/detail?id=" + sessionId);
            return;
        }

        labels.insert(sessionId, newLabel, "REVIEWER", reason.trim(),
                Integer.valueOf(me.getUserId()));
        req.getSession().setAttribute("flash", "Label updated to " + newLabel);
        resp.sendRedirect(req.getContextPath() + "/session/detail?id=" + sessionId);
    }
}
