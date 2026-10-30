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
            String idStr = Web.trimmed(request, "id");
            Room r = null;
            try {
                r = rooms.findById(Integer.parseInt(idStr));
            } catch (Exception ignored) {}
            if (r == null && !idStr.isEmpty()) {
                r = rooms.findByCode(idStr);
            }
            if (r == null) {
                Web.flash(request, "Room not found");
                response.sendRedirect(request.getContextPath() + "/admin/rooms");
                return;
            }
            showForm(request, response, r);
            return;
        }
        
        if ("/detail".equals(action)) {
            String idStr = Web.trimmed(request, "id");
            Room r = null;
            try {
                r = rooms.findById(Integer.parseInt(idStr));
            } catch (Exception ignored) {}
            if (r == null && !idStr.isEmpty()) {
                r = rooms.findByCode(idStr);
            }
            if (r == null) {
                Web.flash(request, "Room not found");
                response.sendRedirect(request.getContextPath() + "/admin/rooms");
                return;
            }
            showDetail(request, response, r);
            return;
        }
        
        String keyword = Web.trimmed(request, "keyword");
        
        List<Room> rows = rooms.search(keyword, null);
        request.setAttribute("rows", rows);
        request.setAttribute("keyword", keyword);
        request.setAttribute("total", rooms.count());
        
        request.getRequestDispatcher("/WEB-INF/views/roomList.jsp").forward(request, response);
    }
    
    private void showForm(HttpServletRequest request, HttpServletResponse response, Room r)
            throws ServletException, IOException {
        DeviceDAO deviceDAO = new DeviceDAO();
        String currentDevCode = (r != null) ? r.getDeviceCode() : null;
        request.setAttribute("deviceList", deviceDAO.getUnassignedDevices(currentDevCode));
        request.setAttribute("editRoom", r);
        request.getRequestDispatcher("/WEB-INF/views/roomForm.jsp").forward(request, response);
    }
    
    private void showDetail(HttpServletRequest request, HttpServletResponse response, Room r)
            throws ServletException, IOException {
        request.setAttribute("detail", r);
        List<model.AirSession> recentSessions = new java.util.ArrayList<>();
        if (r != null) {
            String devCode = r.getDeviceCode();
            if (devCode == null || devCode.trim().isEmpty()) {
                dao.DeviceDAO devDAO = new dao.DeviceDAO();
                for (model.Device dev : devDAO.getActiveDevices()) {
                    if (dev.getRoomId() != null && dev.getRoomId() == r.getRoomId()) {
                        devCode = dev.getDeviceCode();
                        r.setDeviceCode(devCode);
                        break;
                    }
                }
            }
            if (devCode != null && !devCode.trim().isEmpty()) {
                dao.AirSessionDAO sessionDAO = new dao.AirSessionDAO();
                recentSessions = sessionDAO.search(null, devCode.trim(), 1, 100);
                if (!recentSessions.isEmpty()) {
                    request.setAttribute("latestSession", recentSessions.get(0));
                }
            }
        }
        request.setAttribute("recentSessions", recentSessions);

        dao.AlertDAO alertDAO = new dao.AlertDAO();
        int roomId = (r != null) ? r.getRoomId() : 0;
        String devCode = (r != null) ? r.getDeviceCode() : null;
        List<model.AirAlert> alerts = alertDAO.getAlertsByRoom(roomId, devCode, 50);
        request.setAttribute("recentAlerts", alerts != null ? alerts : new java.util.ArrayList<>());

        // Thiết bị active của phòng cho tính năng Measure
        dao.DeviceDAO devDAO = new dao.DeviceDAO();
        model.Device activeDevice = (r != null) ? devDAO.findActiveByRoom(r.getRoomId()) : null;
        request.setAttribute("activeDevice", activeDevice);

        // Tham số tab đang chọn (ví dụ: tab=measure)
        String tab = Web.trimmed(request, "tab");
        request.setAttribute("activeTab", tab.isEmpty() ? "charts" : tab);

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
            String isEditStr = Web.trimmed(request, "isEdit");
            String idStr = Web.trimmed(request, "roomId");
            int id = -1;
            try {
                id = Integer.parseInt(idStr);
            } catch (Exception ignored) {}

            String code = Web.trimmed(request, "code");
            Room existing = rooms.findByCode(code);
            boolean isEdit = "1".equals(isEditStr) || "true".equalsIgnoreCase(isEditStr) || (id >= 0) || (existing != null);
            if (isEdit && id < 0 && existing != null) {
                id = existing.getRoomId();
            }

            Room r = new Room();
            r.setRoomId(id);
            r.setCode(code);
            r.setName(Web.trimmed(request, "name"));
            r.setLocation(Web.trimmed(request, "location"));

            float tempThreshold = 32.0f;
            try {
                String s = request.getParameter("tempThreshold");
                if (s != null && !s.trim().isEmpty()) tempThreshold = Float.parseFloat(s.trim());
            } catch (Exception ignored) {}
            r.setTempWarningThreshold(tempThreshold);

            float humidThreshold = 80.0f;
            try {
                String s = request.getParameter("humidThreshold");
                if (s != null && !s.trim().isEmpty()) humidThreshold = Float.parseFloat(s.trim());
            } catch (Exception ignored) {}
            r.setHumidWarningThreshold(humidThreshold);

            float coThreshold = 9.0f;
            try {
                String s = request.getParameter("coThreshold");
                if (s != null && !s.trim().isEmpty()) coThreshold = Float.parseFloat(s.trim());
            } catch (Exception ignored) {}
            r.setCoWarningThreshold(coThreshold);

            float co2Threshold = 1000.0f;
            try {
                String s = request.getParameter("co2Threshold");
                if (s != null && !s.trim().isEmpty()) co2Threshold = Float.parseFloat(s.trim());
            } catch (Exception ignored) {}
            r.setCo2WarningThreshold(co2Threshold);

            String devCode = Web.trimmed(request, "deviceCode");
            if (devCode.isEmpty()) {
                devCode = null;
            }
            r.setDeviceCode(devCode);
            r.setNote(Web.trimmed(request, "note"));

            DeviceDAO deviceDAO = new DeviceDAO();
            if (!isEdit) {
                if (rooms.insert(r)) {
                    int effectiveRoomId = r.getRoomId();
                    if (effectiveRoomId < 0) {
                        Room inserted = rooms.findByCode(r.getCode());
                        if (inserted != null) effectiveRoomId = inserted.getRoomId();
                    }
                    if (effectiveRoomId >= 0 && devCode != null && !devCode.isEmpty()) {
                        deviceDAO.assignRoomToDevice(devCode, effectiveRoomId);
                    }
                    Web.flash(request, "Added room " + r.getName());
                } else {
                    Web.flash(request, "Failed to add room, room code might already exist");
                }
            } else {
                if (rooms.update(r)) {
                    deviceDAO.unassignRoom(id);
                    if (devCode != null && !devCode.isEmpty()) {
                        deviceDAO.assignRoomToDevice(devCode, id);
                    }
                    Web.flash(request, "Room changes saved successfully");
                } else {
                    Web.flash(request, "Failed to save room changes");
                }
            }
        }
        
        else if ("/lock".equals(action)) {
            String idStr = Web.trimmed(request, "id");
            Room r = null;
            try {
                r = rooms.findById(Integer.parseInt(idStr));
            } catch (Exception ignored) {}
            if (r == null && !idStr.isEmpty()) {
                r = rooms.findByCode(idStr);
            }
            if (r != null) {
                rooms.lock(r.getRoomId(), !r.isActive());
                Web.flash(request, "Successfully " + (r.isActive() ? "deactivated " : "activated ") + r.getName());
            }
        }
        
        else if ("/delete".equals(action)) {
            String idStr = Web.trimmed(request, "id");
            Room r = null;
            try {
                r = rooms.findById(Integer.parseInt(idStr));
            } catch (Exception ignored) {}
            if (r == null && !idStr.isEmpty()) {
                r = rooms.findByCode(idStr);
            }
            int effectiveId = (r != null) ? r.getRoomId() : -1;
            if (effectiveId >= 0 && rooms.delete(effectiveId)) {
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
