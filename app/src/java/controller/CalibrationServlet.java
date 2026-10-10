
package controller;

import dao.CalibrationDAO;
import dao.UserDAO;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.List;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import model.AppUser;
import model.Calibration;
import util.Web;


@WebServlet(name = "CalibrationServlet", 
        urlPatterns = {"/admin/calibrations", 
                       "/admin/calibrations/create", 
                       "/admin/calibrations/edit",
                       "/admin/calibrations/save",
                       "/admin/calibrations/delete" })

public class CalibrationServlet extends HttpServlet {

    private final CalibrationDAO calibrations = new CalibrationDAO();
    private final UserDAO users = new UserDAO();
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        int stationId = Web.intParam(request, "stationId", 0);
        
        String action = action(request);
        if ("/create".equals(action)) { 
            showForm(request, response, null, stationId);
            return; 
        }
        
        if ("/edit".equals(action)) {

            int calibrationId = Web.intParam(request, "id", 0);

            // Kiểm tra calibrationId và stationId
            if (calibrationId <= 0 || stationId <= 0) {
                Web.flash(request, "Thong tin hieu chuan khong hop le");
                response.sendRedirect(request.getContextPath() + "/admin/stations");
                return;
            }

            Calibration c = calibrations.findById(calibrationId);

            // Không tìm thấy calibration
            if (c == null) {
                Web.flash(request, "Khong tim thay hieu chuan");
                response.sendRedirect(request.getContextPath() + "/admin/stations");
                return;
            }

            // Calibration không thuộc station hiện tại
            if (c.getStationId() != stationId) {
                Web.flash(request, "Hieu chuan khong thuoc tram nay");
                response.sendRedirect(request.getContextPath() + "/admin/stations");
                return;
            }

            showForm(request, response, c, stationId);
            return;
        }
        
        
        showList(request, response);
        
    }
    
    private void showList(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        int stationId = Web.intParam(request, "stationId", 0);
        
        List<Calibration> rows = calibrations.search(stationId);
        int total = calibrations.count(stationId);
        
        request.setAttribute("rows", rows);
        request.setAttribute("total", Integer.valueOf(total));
        request.setAttribute("stationId", stationId);

        request.getRequestDispatcher("/WEB-INF/views/calibrationList.jsp").forward(request, response);
    }
    
    private void showForm(HttpServletRequest request, HttpServletResponse response, Calibration c, int stationId)
            throws ServletException, IOException {
        request.setAttribute("editCalibration", c);
        request.setAttribute("stationId", stationId);
        
        List<AppUser> calibrationUsers = users.findCalibrationUser();
        request.setAttribute("calibrationUsers", calibrationUsers);
        
        request.getRequestDispatcher("/WEB-INF/views/calibrationForm.jsp").forward(request, response);
    }

    
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        String action = action(request);
        int stationId = Web.intParam(request, "stationId", 0);
        
        if ("/save".equals(action)) {
            
            int calibrationId = Web.intParam(request, "calibrationId", 0);
            int userId = Web.intParam(request, "userId", 0);
            
            Calibration c = new Calibration();
            
            c.setCalibrationId(calibrationId);
            c.setStationId(stationId);
            
            c.setCode(Web.trimmed(request, "code"));
            c.setName(Web.trimmed(request, "name"));
            c.setCoBaseLine(Web.intParam(request, "coBaseline", 0));
            c.setCo2BaseLine(Web.intParam(request, "co2Baseline", 0));
            
            // Phan tham chieu den AppUser
            c.setPerformedBy(userId);
            
            c.setNote(Web.trimmed(request, "note"));

            if (calibrationId == 0) {
                if (calibrations.insert(c)) Web.flash(request, "Da them hieu chuan " + c.getName());
                else Web.flash(request, "Loi khi them, khong biet");
            } else {
                if (calibrations.update(c)) Web.flash(request, "Da luu thay doi");
                else Web.flash(request, "Loi khi luu");
            }
        }
        
        if ("/delete".equals(action)) {
            int calibrationId = Web.intParam(request, "calibrationId", 0);

            if (calibrationId > 0 && stationId > 0) {
                if (calibrations.delete(calibrationId, stationId)) {
                    Web.flash(request, "Da xoa hieu chuan");
                } else {
                    Web.flash(request, "Khong tim thay hieu chuan cua station nay");
                }
            }
            else {
                Web.flash(request, "Thong tin xoa khong hop le");
            }
        }
        
        response.sendRedirect(request.getContextPath() + "/admin/calibrations?stationId=" + stationId);
        
    }
    
    private String action(HttpServletRequest req) {
        String path = req.getRequestURI().substring(req.getContextPath().length());
        return path.substring("/admin/calibrations".length());
    }

}
