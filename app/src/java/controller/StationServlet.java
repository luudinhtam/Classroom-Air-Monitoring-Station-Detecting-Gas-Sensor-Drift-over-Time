package controller;

import dao.AirStationDAO;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.List;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import model.AirStation;
import util.Web;

@WebServlet(urlPatterns = { "/admin/stations", 
                            "/admin/stations/create", 
                            "/admin/stations/edit",
                            "/admin/stations/save",
                            "/admin/stations/lock",
                            "/admin/stations/detail",
                            "/admin/stations/delete" })

public class StationServlet extends HttpServlet {

    private final AirStationDAO stations = new AirStationDAO();
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        String action = action(request);
        if ("/create".equals(action)) { 
            showForm(request, response, null);
            return; 
        }
        
        if ("/edit".equals(action)) {
            AirStation a = stations.findById(Web.intParam(request, "id", 0));
            if (a == null) {
                Web.flash(request, "Khong tim thay tram");
                response.sendRedirect(request.getContextPath() + "/admin/stations");
                return;
            }
            showForm(request, response, a);
            return;
        }
        
        if ("/detail".equals(action)) { 
            AirStation a = stations.findById(Web.intParam(request, "id", 0));
            if (a == null) {
                Web.flash(request, "Khong tim thay tram");
                response.sendRedirect(request.getContextPath() + "/admin/stations");
                return;
            }
            showDetail(request, response, a);
            return; 
        }
        
        showList(request, response);
    }
    
    private void showList(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        String keyword = Web.trimmed(request, "keyword");
        String status = Web.trimmed(request, "status");
        
        List<AirStation> rows = stations.search(keyword, status);
        int total = stations.count();
        
        request.setAttribute("rows", rows);
        request.setAttribute("total", Integer.valueOf(total));
        request.setAttribute("keyword", keyword);
        request.setAttribute("status", status);

        request.getRequestDispatcher("/WEB-INF/views/stationList.jsp").forward(request, response);
    }
    
    private void showForm(HttpServletRequest request, HttpServletResponse response, AirStation a)
            throws ServletException, IOException {
        request.setAttribute("editStation", a);
        request.getRequestDispatcher("/WEB-INF/views/stationForm.jsp").forward(request, response);
    }
    
    private void showDetail(HttpServletRequest request, HttpServletResponse response, AirStation a)
            throws ServletException, IOException {
        request.setAttribute("detail", a);
        request.getRequestDispatcher("/WEB-INF/views/stationDetail.jsp").forward(request, response);
    }
    
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        String action = action(request);

        if ("/save".equals(action)) {
            int id = Web.intParam(request, "stationId", 0);
            AirStation a = new AirStation();
            a.setStationId(id);
            a.setCode(Web.trimmed(request, "code"));
            a.setName(Web.trimmed(request, "name"));
            a.setLocation(Web.trimmed(request, "location"));
            a.setCoWarningThreshold(Web.intParam(request, "coThreshold", 0));
            a.setCo2WarningThreshold(Web.intParam(request, "co2Threshold", 0));
            a.setMaxBaselineDrift(Web.intParam(request, "maxBaselineDrift", 0));
            a.setDeviceKey(Web.trimmed(request, "deviceKey"));
            a.setNote(Web.trimmed(request, "note"));

            if (id == 0) {
                if (stations.insert(a)) Web.flash(request, "Da them tram " + a.getName());
                else Web.flash(request, "Loi khi them, co the ma tram da ton tai");
            } else {
                if (stations.update(a)) Web.flash(request, "Da luu thay doi");
                else Web.flash(request, "Loi khi luu");
            }
        }
        
        else if ("/lock".equals(action)) {
            int id = Web.intParam(request, "id", 0);
            AirStation a = stations.findById(id);
            if (a != null) {
                stations.lock(id, !a.isActive());
                Web.flash(request, "Da " + (a.isActive() ? "tat tram " : "kich hoat tram ") + a.getName());
            }
        }
        
        else if ("/delete".equals(action)) {
            int id = Web.intParam(request, "id", 0);
            if (stations.delete(id)) {
                Web.flash(request, "Da xoa tram");
            } else {
                Web.flash(request, "Loi khi xoa tram");
            }
        }
        
        response.sendRedirect(request.getContextPath() + "/admin/stations");
        
    }
    
    private String action(HttpServletRequest req) {
        String path = req.getRequestURI().substring(req.getContextPath().length());
        return path.substring("/admin/stations".length());
    }

}
