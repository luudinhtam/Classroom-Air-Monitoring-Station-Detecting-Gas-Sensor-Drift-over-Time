package controller;

import dao.RoomDAO;
import dao.DeviceDAO;
import java.io.IOException;
import java.util.List;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import model.Room;
import util.Web;

@WebServlet(urlPatterns = {
    "/admin/rooms", 
    "/admin/rooms/create", 
    "/admin/rooms/edit", 
    "/admin/rooms/save", 
    "/admin/rooms/delete", 
    "/admin/rooms/lock",
    "/admin/rooms/detail",
    "/admin/rooms/update-coords"
})
public class RoomServlet extends HttpServlet {

    private final RoomDAO rooms = new RoomDAO();
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        String action = action(request);
        if ("/create".equals(action)) { 
            showForm(request, response, null);
            return; 
        }
        
        if ("/edit".equals(action)) {
            Room r = rooms.findById(Web.intParam(request, "id", 0));
            if (r == null) {
                Web.flash(request, "Room not found");
                response.sendRedirect(request.getContextPath() + "/admin/rooms");
                return;
            }
            showForm(request, response, r);
            return;
        }
        
        if ("/detail".equals(action)) {
            Room r = rooms.findById(Web.intParam(request, "id", 0));
            if (r == null) {
                Web.flash(request, "Room not found");
                response.sendRedirect(request.getContextPath() + "/admin/rooms");
                return;
            }
            showDetail(request, response, r);
            return;
        }
        
        String keyword = Web.trimmed(request, "keyword");
        String status = Web.trimmed(request, "status");
        
        List<Room> rows = rooms.search(keyword, status);
        request.setAttribute("rows", rows);
        request.setAttribute("keyword", keyword);
        request.setAttribute("status", status);
        request.setAttribute("total", rooms.count());
        
        request.getRequestDispatcher("/WEB-INF/views/roomList.jsp").forward(request, response);
    }
    
    private void showForm(HttpServletRequest request, HttpServletResponse response, Room r)
            throws ServletException, IOException {
        DeviceDAO deviceDAO = new DeviceDAO();
        request.setAttribute("deviceList", deviceDAO.getActiveDevices());
        request.setAttribute("editRoom", r);
        request.getRequestDispatcher("/WEB-INF/views/roomForm.jsp").forward(request, response);
    }
    
    private void showDetail(HttpServletRequest request, HttpServletResponse response, Room r)
            throws ServletException, IOException {
        request.setAttribute("detail", r);
        request.getRequestDispatcher("/WEB-INF/views/roomDetail.jsp").forward(request, response);
    }
    
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");
        
        String action = action(request);

        if ("/update-coords".equals(action)) {
            int id = Web.intParam(request, "roomId", 0);
            try {
                double lat = Double.parseDouble(request.getParameter("lat"));
                double lng = Double.parseDouble(request.getParameter("lng"));
                boolean ok = rooms.updateCoordinates(id, lat, lng);
                response.setContentType("application/json");
                response.setCharacterEncoding("UTF-8");
                response.getWriter().write("{\"success\":" + ok + "}");
                return;
            } catch (Exception e) {
                response.setStatus(400);
                response.setContentType("application/json");
                response.getWriter().write("{\"success\":false,\"error\":\"" + e.getMessage() + "\"}");
                return;
            }
        }

        if ("/save".equals(action)) {
            int id = Web.intParam(request, "roomId", 0);
            Room r = new Room();
            r.setRoomId(id);
            r.setCode(Web.trimmed(request, "code"));
            r.setName(Web.trimmed(request, "name"));
            r.setLocation(Web.trimmed(request, "location"));
            r.setCoWarningThreshold(Web.intParam(request, "coThreshold", 0));
            r.setCo2WarningThreshold(Web.intParam(request, "co2Threshold", 0));
            r.setMaxBaselineDrift(Web.intParam(request, "maxBaselineDrift", 15));
            r.setDeviceCode(Web.trimmed(request, "deviceCode"));
            r.setNote(Web.trimmed(request, "note"));

            String latStr = request.getParameter("latitude");
            if (latStr != null && !latStr.trim().isEmpty()) {
                try { r.setLatitude(Double.parseDouble(latStr.trim())); } catch (Exception ignored) {}
            }
            String lngStr = request.getParameter("longitude");
            if (lngStr != null && !lngStr.trim().isEmpty()) {
                try { r.setLongitude(Double.parseDouble(lngStr.trim())); } catch (Exception ignored) {}
            }

            if (id == 0) {
                if (rooms.insert(r)) Web.flash(request, "Added room " + r.getName());
                else Web.flash(request, "Failed to add room, room code might already exist");
            } else {
                if (rooms.update(r)) Web.flash(request, "Room changes saved successfully");
                else Web.flash(request, "Failed to save room changes");
            }
        }
        
        else if ("/lock".equals(action)) {
            int id = Web.intParam(request, "id", 0);
            Room r = rooms.findById(id);
            if (r != null) {
                rooms.lock(id, !r.isActive());
                Web.flash(request, "Successfully " + (r.isActive() ? "deactivated " : "activated ") + r.getName());
            }
        }
        
        else if ("/delete".equals(action)) {
            int id = Web.intParam(request, "id", 0);
            if (rooms.delete(id)) {
                Web.flash(request, "Room deleted successfully");
            } else {
                Web.flash(request, "Failed to delete room");
            }
        }
        
        response.sendRedirect(request.getContextPath() + "/admin/rooms");
    }
    
    private String action(HttpServletRequest req) {
        String path = req.getRequestURI().substring(req.getContextPath().length());
        return path.substring("/admin/rooms".length());
    }
}
