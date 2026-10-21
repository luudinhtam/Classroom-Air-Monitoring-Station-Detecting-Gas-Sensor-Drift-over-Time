package controller;

import dao.AirStationDAO;
import dao.DashboardDAO;
import model.AirStation;
import model.DashboardStats;
import java.io.IOException;
import java.util.List;
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

        // Lấy danh sách trạm đang hoạt động để vẽ marker trên bản đồ
        List<AirStation> stationList = AirStationDAO.getInstance().findAllActive();
        req.setAttribute("stationList", stationList);

        // Chuyển hướng sang giao diện bản đồ
        req.getRequestDispatcher("/WEB-INF/views/map.jsp").forward(req, resp);
    }
}
