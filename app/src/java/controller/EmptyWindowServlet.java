package controller;

import dao.EmptyWindowDAO;
import dao.UserDAO;
import java.io.IOException;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.List;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
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

    private int getRoomParam(HttpServletRequest request) {
        int id = Web.intParam(request, "roomId", 0);
        if (id <= 0) {
            id = Web.intParam(request, "stationId", 0);
        }
        return id;
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        int roomId = getRoomParam(request);

        String action = action(request);
        if ("/create".equals(action)) { 
            showForm(request, response, null, roomId);
            return; 
        }
        
        if ("/edit".equals(action)) {

            int emptyWindowId = Web.intParam(request, "id", 0);

            if (emptyWindowId <= 0 || roomId <= 0) {
                Web.flash(request, "Invalid empty window information");
                response.sendRedirect(request.getContextPath() + "/admin/rooms");
                return;
            }

            EmptyWindow ew = emptyWindows.findById(emptyWindowId);

            if (ew == null) {
                Web.flash(request, "Empty window not found");
                response.sendRedirect(request.getContextPath() + "/admin/emptyWindows?roomId=" + roomId);
                return;
            }

            // Kiểm tra EmptyWindow có thuộc room này không
            if (ew.getRoomId() != roomId) {
                Web.flash(request, "Empty window does not belong to this room");
                response.sendRedirect(request.getContextPath() + "/admin/emptyWindows?roomId=" + roomId);
                return;
            }

            showForm(request, response, ew, roomId);
            return;
        }
        
        showList(request, response);
    }
    
    private void showList(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        int roomId = getRoomParam(request);

        List<EmptyWindow> rows = emptyWindows.search(roomId);
        int total = emptyWindows.count(roomId);

        request.setAttribute("rows", rows);
        request.setAttribute("total", Integer.valueOf(total));
        request.setAttribute("roomId", roomId);
        request.setAttribute("stationId", roomId);

        request.getRequestDispatcher("/WEB-INF/views/emptyWindowList.jsp").forward(request, response);
    }
    
    private void showForm(HttpServletRequest request, HttpServletResponse response, EmptyWindow ew, int roomId)
            throws ServletException, IOException {
        request.setAttribute("editEmptyWindow", ew);
        request.setAttribute("roomId", roomId);
        request.setAttribute("stationId", roomId);

        List<AppUser> emptyWindowUsers = users.findCalibrationUser();
        request.setAttribute("emptyWindowUsers", emptyWindowUsers);
        
        request.getRequestDispatcher("/WEB-INF/views/emptyWindowForm.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        String action = action(request);
        int roomId = getRoomParam(request);
        
        if ("/save".equals(action)) {

            int emptyWindowId = Web.intParam(request, "emptyWindowId", 0);
            
            HttpSession session = request.getSession(false);
            if (session == null) {
                Web.flash(request, "Session expired. Please recalculate baseline.");
                response.sendRedirect(request.getContextPath() + "/admin/rooms");
                return;
            }

            // Kiểm tra người dùng đã đăng nhập.
            AppUser me = (AppUser) session.getAttribute("user");
            int userId = (me != null) ? me.getUserId() : 0;

            String code = Web.trimmed(request, "code");
            String name = Web.trimmed(request, "name");
            String startText = Web.trimmed(request, "startAt");
            String endText = Web.trimmed(request, "endAt");
            String note = Web.trimmed(request, "note");

            // Kiểm tra dữ liệu bắt buộc
            if (roomId <= 0 || userId <= 0
                    || code.isEmpty() || name.isEmpty()
                    || startText.isEmpty() || endText.isEmpty()) {

                Web.flash(request, "Please enter all required empty window details");

                response.sendRedirect(request.getContextPath() + "/admin/emptyWindows?roomId=" + roomId);
                return;
            }

            try {
                LocalDateTime startAt = LocalDateTime.parse(startText, DATE_TIME_FORMATTER);
                LocalDateTime endAt = LocalDateTime.parse(endText, DATE_TIME_FORMATTER);

                // Thời gian kết thúc phải sau thời gian bắt đầu
                if (!endAt.isAfter(startAt)) {
                    Web.flash(request, "End time must be after start time");
                    response.sendRedirect(request.getContextPath() + "/admin/emptyWindows?roomId=" + roomId);
                    return;
                }

                EmptyWindow ew = new EmptyWindow();

                ew.setEmptyWindowId(emptyWindowId);
                ew.setRoomId(roomId);
                ew.setCode(code);
                ew.setName(name);
                ew.setStartAt(startAt);
                ew.setEndAt(endAt);
                ew.setMarkedBy(userId);
                ew.setNote(note);

                // INSERT
                if (emptyWindowId == 0) {
                    if (emptyWindows.insert(ew)) {
                        Web.flash(request, "Added empty window " + ew.getName());
                    } else {
                        Web.flash(request, "Failed to add empty window");
                    }

                } else {
                    // UPDATE: kiểm tra bản ghi tồn tại và thuộc đúng room
                    EmptyWindow existing = emptyWindows.findById(emptyWindowId);

                    if (existing == null || existing.getRoomId() != roomId) {
                        Web.flash(request, "Empty window not found for this room");
                    } else if (emptyWindows.update(ew)) {
                        Web.flash(request, "Empty window changes saved successfully");
                    } else {
                        Web.flash(request, "Failed to save empty window changes");
                    }
                }

            } catch (DateTimeParseException e) { 
                Web.flash(request, "Invalid date/time format");
            }
            
        } 
        else if ("/delete".equals(action)) {

            int emptyWindowId = Web.intParam(request, "emptyWindowId", 0);

            if (emptyWindowId > 0 && roomId > 0) {
                if (emptyWindows.delete(emptyWindowId, roomId)) {
                    Web.flash(request, "Empty window deleted successfully");
                } else {
                    Web.flash(request, "Empty window not found for this room");
                }
            } else {
                Web.flash(request, "Invalid deletion request");
            }
        }
        
        response.sendRedirect(request.getContextPath() + "/admin/emptyWindows?roomId=" + roomId);
        
    } 

    private String action(HttpServletRequest request) {
        String path = request.getRequestURI().substring(request.getContextPath().length());
        return path.substring("/admin/emptyWindows".length());
    }

}
