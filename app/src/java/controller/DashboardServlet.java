package controller;

import dao.DashboardDAO;
import java.io.IOException;
import java.util.List;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import model.DashboardStats;

@WebServlet("/dashboard")
public class DashboardServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        
        DashboardDAO dao = DashboardDAO.getInstance();
        DashboardStats stats = dao.getDashboardStats();

        // Đặt stats object vào request
        req.setAttribute("stats", stats);

        // Nạp danh sách các phòng học kèm nhiệt độ, độ ẩm phục vụ giao diện Classroom Temp Monitoring
        List<model.ClassroomTempInfo> classroomList = dao.getClassroomTempList();
        req.setAttribute("classroomList", classroomList);

        // Nạp chuỗi lịch sử đo từ database phục vụ biểu đồ xu hướng
        List<java.util.Map<String, Object>> sessionHistory = dao.getRecentSessions();
        req.setAttribute("sessionHistory", sessionHistory);

        // Các thuộc tính tiện ích tương thích ngược nếu có file jsp nào gọi
        req.setAttribute("totalSessions", stats.getTotalSessions());
        req.setAttribute("totalAlerts", stats.getTotalAlerts());
        req.setAttribute("totalDrifted", stats.getDriftedCount());
        req.setAttribute("totalDevices", stats.getTotalDevices());
        req.setAttribute("totalUsers", stats.getTotalUsers());

        req.getRequestDispatcher("/WEB-INF/views/dashboard.jsp").forward(req, resp);
    }
}
