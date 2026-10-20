package controller;

import dao.DashboardDAO;
import model.DashboardStats;
import java.io.IOException;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

@WebServlet(name = "MapServlet", urlPatterns = {"/map"})
public class MapServlet extends HttpServlet {
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        
        // Lấy số liệu mới nhất của trạm để hiển thị màu và giá trị tức thời
        DashboardStats stats = DashboardDAO.getInstance().getDashboardStats();
        req.setAttribute("stats", stats);

        // Chuyển hướng sang giao diện bản đồ
        req.getRequestDispatcher("/WEB-INF/views/map.jsp").forward(req, resp);
    }
}