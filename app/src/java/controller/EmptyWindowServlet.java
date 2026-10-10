
package controller;

import dao.EmptyWindowDAO;
import dao.UserDAO;
import java.io.IOException;
import java.io.PrintWriter;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.List;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import model.AppUser;
import model.EmptyWindow;
import util.Web;


@WebServlet(name = "EmptyWindowServlet", 
        urlPatterns = {"/admin/emptyWindows", 
                       "/admin/emptyWindows/create", 
                       "/admin/emptyWindows/edit",
                       "/admin/emptyWindows/save",
                       "/admin/emptyWindows/delete" })
public class EmptyWindowServlet extends HttpServlet {

    private final EmptyWindowDAO emptyWindows = new EmptyWindowDAO();
    private final UserDAO users = new UserDAO();
    private static final DateTimeFormatter DATE_TIME_FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm");

    
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

            int emptyWindowId = Web.intParam(request, "id", 0);

            if (emptyWindowId <= 0 || stationId <= 0) {
                Web.flash(request,
                        "Thong tin khoang phong trong khong hop le");
                response.sendRedirect(
                        request.getContextPath() + "/admin/stations");
                return;
            }

            EmptyWindow ew = emptyWindows.findById(emptyWindowId);

            if (ew == null) {
                Web.flash(request,
                        "Khong tim thay khoang phong trong");
                response.sendRedirect(
                        request.getContextPath()
                        + "/admin/emptyWindows?stationId=" + stationId);
                return;
            }

            // Kiểm tra EmptyWindow có thuộc station này không
            if (ew.getStationId() != stationId) {
                Web.flash(request,
                        "Khoang phong trong khong thuoc tram nay");
                response.sendRedirect(
                        request.getContextPath()
                        + "/admin/emptyWindows?stationId=" + stationId);
                return;
            }

            showForm(request, response, ew, stationId);
            return;
        }
        
        
        showList(request, response);
    }
    
    private void showList(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        int stationId = Web.intParam(request, "stationId", 0);

        List<EmptyWindow> rows = emptyWindows.search(stationId);
        int total = emptyWindows.count(stationId);

        request.setAttribute("rows", rows);
        request.setAttribute("total", Integer.valueOf(total));
        request.setAttribute("stationId", stationId);

        request.getRequestDispatcher("/WEB-INF/views/emptyWindowList.jsp").forward(request, response);
    }
    
    private void showForm(HttpServletRequest request, HttpServletResponse response, EmptyWindow ew, int stationId)
            throws ServletException, IOException {
        request.setAttribute("editEmptyWindow", ew);
        request.setAttribute("stationId", stationId);

        List<AppUser> emptyWindowUsers = users.findCalibrationUser();
        request.setAttribute("emptyWindowUsers", emptyWindowUsers);
        
        request.getRequestDispatcher("/WEB-INF/views/emptyWindowForm.jsp").forward(request, response);
    }

    
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        String action = action(request);
        int stationId = Web.intParam(request, "stationId", 0);

        // SAVE: CREATE hoặc UPDATE
        if ("/save".equals(action)) {

            int emptyWindowId = Web.intParam(request, "emptyWindowId", 0);
            int userId = Web.intParam(request, "userId", 0);

            String code = Web.trimmed(request, "code");
            String name = Web.trimmed(request, "name");
            String startText = Web.trimmed(request, "startAt");
            String endText = Web.trimmed(request, "endAt");
            String note = Web.trimmed(request, "note");

            // Kiểm tra dữ liệu bắt buộc
            if (stationId <= 0 || userId <= 0
                    || code.isEmpty() || name.isEmpty()
                    || startText.isEmpty() || endText.isEmpty()) {

                Web.flash(request,
                        "Vui long nhap day du thong tin khoang phong trong");

                response.sendRedirect(
                        request.getContextPath()
                        + "/admin/emptyWindows?stationId=" + stationId);
                return;
            }

            try {
                LocalDateTime startAt = LocalDateTime.parse(startText, DATE_TIME_FORMATTER);
                LocalDateTime endAt = LocalDateTime.parse(endText, DATE_TIME_FORMATTER);

                // Thời gian kết thúc phải sau thời gian bắt đầu
                if (!endAt.isAfter(startAt)) {
                    Web.flash(request, "Thoi gian ket thuc phai sau thoi gian bat dau");
                    response.sendRedirect(request.getContextPath() + "/admin/emptyWindows?stationId=" + stationId);
                    return;
                }

                EmptyWindow ew = new EmptyWindow();

                ew.setEmptyWindowId(emptyWindowId);
                ew.setStationId(stationId);
                ew.setCode(code);
                ew.setName(name);
                ew.setStartAt(startAt);
                ew.setEndAt(endAt);
                ew.setMarkedBy(userId);
                ew.setNote(note);

                // INSERT
                if (emptyWindowId == 0) {
                    if (emptyWindows.insert(ew)) {
                        Web.flash(request, "Da them khoang phong trong " + ew.getName());
                    } else {
                        Web.flash(request, "Loi khi them khoang phong trong");
                    }

                } else {
                    // UPDATE: kiểm tra bản ghi tồn tại và thuộc đúng station
                    EmptyWindow existing = emptyWindows.findById(emptyWindowId);

                    if (existing == null || existing.getStationId() != stationId) {
                        Web.flash(request, "Khong tim thay khoang phong trong cua tram nay");
                    } else if (emptyWindows.update(ew)) {
                        Web.flash(request, "Da luu thay doi");
                    } else {
                        Web.flash(request, "Loi khi luu khoang phong trong");
                    }
                }

            } catch (DateTimeParseException e) { 
                Web.flash(request, "Dinh dang thoi gian khong hop le");
            }
            
        } 
        else if ("/delete".equals(action)) {

            int emptyWindowId = Web.intParam(request, "emptyWindowId", 0);

            if (emptyWindowId > 0 && stationId > 0) {
                if (emptyWindows.delete(emptyWindowId, stationId)) {
                    Web.flash(request, "Da xoa khoang phong trong");
                } else {
                    Web.flash(request,
                            "Khong tim thay khoang phong trong cua tram nay");
                }
            } else {
                Web.flash(request, "Thong tin xoa khong hop le");
            }
        }
        
        
        
        response.sendRedirect(request.getContextPath() + "/admin/emptyWindows?stationId=" + stationId);
        
    } 

    private String action(HttpServletRequest request) {

        String path = request.getRequestURI().substring(request.getContextPath().length());
        return path.substring("/admin/emptyWindows".length());
    }

}
