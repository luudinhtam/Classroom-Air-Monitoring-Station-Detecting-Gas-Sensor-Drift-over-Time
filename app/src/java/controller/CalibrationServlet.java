package controller;

import dao.CalibrationDAO;
import dao.UserDAO;
import java.io.IOException;
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
            "/admin/calibrations/edit",
            "/admin/calibrations/save",
            "/admin/calibrations/delete"})

public class CalibrationServlet extends HttpServlet {

    private final CalibrationDAO calibrations = new CalibrationDAO();
    private final UserDAO users = new UserDAO();

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

            int calibrationId = Web.intParam(request, "id", 0);

            // Kiểm tra calibrationId và roomId
            if (calibrationId <= 0 || roomId <= 0) {
                Web.flash(request, "Invalid calibration information");
                response.sendRedirect(request.getContextPath() + "/admin/rooms");
                return;
            }

            Calibration c = calibrations.findById(calibrationId);

            // Không tìm thấy calibration
            if (c == null) {
                Web.flash(request, "Calibration record not found");
                response.sendRedirect(request.getContextPath() + "/admin/rooms");
                return;
            }

            // Calibration không thuộc room hiện tại
            if (c.getRoomId() != roomId) {
                Web.flash(request, "Calibration record does not belong to this room");
                response.sendRedirect(request.getContextPath() + "/admin/rooms");
                return;
            }

            showForm(request, response, c, roomId);
            return;
        }

        showList(request, response);

    }

    private void showList(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        int roomId = getRoomParam(request);

        List<Calibration> rows = calibrations.search(roomId);
        int total = calibrations.count(roomId);

        request.setAttribute("rows", rows);
        request.setAttribute("total", Integer.valueOf(total));
        request.setAttribute("roomId", roomId);
        request.setAttribute("stationId", roomId);

        request.getRequestDispatcher("/WEB-INF/views/calibrationList.jsp").forward(request, response);
    }

    private void showForm(HttpServletRequest request, HttpServletResponse response, Calibration c, int roomId)
            throws ServletException, IOException {
        request.setAttribute("editCalibration", c);
        request.setAttribute("roomId", roomId);
        request.setAttribute("stationId", roomId);

        List<AppUser> calibrationUsers = users.findCalibrationUser();
        request.setAttribute("calibrationUsers", calibrationUsers);

        request.getRequestDispatcher("/WEB-INF/views/calibrationForm.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String action = action(request);
        int roomId = getRoomParam(request);

        if ("/save".equals(action)) {

            int calibrationId = Web.intParam(request, "calibrationId", 0);
            int userId = Web.intParam(request, "userId", 0);

            Calibration c = new Calibration();

            c.setCalibrationId(calibrationId);
            c.setRoomId(roomId);

            c.setCode(Web.trimmed(request, "code"));
            c.setName(Web.trimmed(request, "name"));
            c.setCoBaseLine(Web.intParam(request, "coBaseline", 0));
            c.setCo2BaseLine(Web.intParam(request, "co2Baseline", 0));

            // Phan tham chieu den AppUser
            c.setPerformedBy(userId);
            c.setNote(Web.trimmed(request, "note"));

            if (calibrations.update(c)) {
                Web.flash(request, "Calibration changes saved successfully");
            } else {
                Web.flash(request, "Failed to save calibration changes");
            }
        }

        if ("/delete".equals(action)) {
            int calibrationId = Web.intParam(request, "calibrationId", 0);

            if (calibrationId > 0 && roomId > 0) {
                if (calibrations.delete(calibrationId, roomId)) {
                    Web.flash(request, "Calibration record deleted successfully");
                } else {
                    Web.flash(request, "Calibration record not found for this room");
                }
            } else {
                Web.flash(request, "Invalid deletion request");
            }
        }

        response.sendRedirect(request.getContextPath() + "/admin/calibrations?roomId=" + roomId);

    }

    private String action(HttpServletRequest req) {
        String path = req.getRequestURI().substring(req.getContextPath().length());
        return path.substring("/admin/calibrations".length());
    }

}
