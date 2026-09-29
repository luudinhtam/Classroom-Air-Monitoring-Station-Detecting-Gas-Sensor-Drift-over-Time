package controller;

import java.io.IOException;
import java.util.List;
import javax.servlet.*;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import dao.AirSessionDAO;
import model.AirSession;

/**
 * One controller for the session list. It never writes HTML: it reads the
 * query string, calls the DAO and forwards to the JSP. This is the MVC2 shape
 * the subject asks for.
 */
@WebServlet("/sessions")
public class AirSessionListServlet extends HttpServlet {

    private static final int PAGE_SIZE = 20;
    private final AirSessionDAO dao = new AirSessionDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String label = req.getParameter("label");
        Integer deviceId = null;
        String dev = req.getParameter("device");
        
        if (dev != null && !dev.isEmpty()) {
            try { deviceId = Integer.valueOf(dev); } catch (NumberFormatException ignored) { }
        }
        
        int page = 1;
        try { page = Integer.parseInt(req.getParameter("page")); } catch (Exception ignored) { }
        if (page < 1) page = 1;

        List<AirSession> rows = dao.search(label, deviceId, page, PAGE_SIZE);
        int total = dao.count(label, deviceId);
        int pages = (total + PAGE_SIZE - 1) / PAGE_SIZE;

        req.setAttribute("rows", rows);
        req.setAttribute("page", Integer.valueOf(page));
        req.setAttribute("pages", Integer.valueOf(pages));
        req.setAttribute("total", Integer.valueOf(total));
        req.setAttribute("label", label);
        
        req.getRequestDispatcher("/WEB-INF/views/sessionList.jsp").forward(req, resp);
    }
}
