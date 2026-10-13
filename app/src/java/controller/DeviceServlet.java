package controller;

import java.io.IOException;
import java.util.List;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import dao.DeviceDAO;
import model.Device;
import util.Web;

@WebServlet(urlPatterns = { "/admin/devices", 
                            "/admin/devices/create", 
                            "/admin/devices/edit", 
                            "/admin/devices/save",
                            "/admin/devices/delete", 
                            "/admin/devices/toggle"})
public class DeviceServlet extends HttpServlet {

    private static final int PAGE_SIZE = 10;
    private final DeviceDAO devices = new DeviceDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String action = action(req);
        if ("/create".equals(action)) { 
            showForm(req, resp, null); 
            return; 
        }
        
        if ("/edit".equals(action)) {
            Device d = devices.findById(Web.intParam(req, "id", 0));
            if (d == null) {
                Web.flash(req, "Khong tim thay thiet bi");
                resp.sendRedirect(req.getContextPath() + "/admin/devices");
                return;
            }
            showForm(req, resp, d);
            return;
        }
        showList(req, resp);
    }

    private void showList(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String keyword = Web.trimmed(req, "keyword");
        String activeState = Web.trimmed(req, "activeState");
        int page = Web.intParam(req, "page", 1);
        if (page < 1) page = 1;

        int offset = (page - 1) * PAGE_SIZE;
        List<Device> rows = devices.search(keyword, activeState, offset, PAGE_SIZE);
        int total = devices.count(keyword, activeState);
        int pages = (total + PAGE_SIZE - 1) / PAGE_SIZE;

        req.setAttribute("rows", rows);
        req.setAttribute("keyword", keyword);
        req.setAttribute("activeState", activeState);
        req.setAttribute("page", Integer.valueOf(page));
        req.setAttribute("pages", Integer.valueOf(pages));
        req.setAttribute("total", Integer.valueOf(total));

        req.getRequestDispatcher("/WEB-INF/views/deviceList.jsp").forward(req, resp);
    }

    private void showForm(HttpServletRequest req, HttpServletResponse resp, Device d)
            throws ServletException, IOException {
        req.setAttribute("editDevice", d);
        req.getRequestDispatcher("/WEB-INF/views/deviceForm.jsp").forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String action = action(req);

        if ("/save".equals(action)) {
            int id = Web.intParam(req, "deviceId", 0);
            Device d = new Device();
            d.setDeviceId(id);
            d.setDeviceCode(Web.trimmed(req, "deviceCode"));
            d.setApiKey(Web.trimmed(req, "apiKey"));
            d.setLocation(Web.trimmed(req, "location"));
            d.setIsActive("1".equals(req.getParameter("isActive")) || "true".equals(req.getParameter("isActive")));

            if (id == 0) {
                if (devices.insert(d)) Web.flash(req, "Da them thiet bi " + d.getDeviceCode());
                else Web.flash(req, "Loi khi them, co the ma thiet bi da ton tai");
            } else {
                if (devices.update(d)) Web.flash(req, "Da luu thay doi thiet bi");
                else Web.flash(req, "Loi khi luu thiet bi");
            }
        }
        else if ("/toggle".equals(action)) {
            int id = Web.intParam(req, "id", 0);
            Device d = devices.findById(id);
            if (d != null) {
                devices.setActive(id, !d.isIsActive());
                Web.flash(req, "Da " + (d.isIsActive() ? "vo hieu hoa " : "kich hoat ") + d.getDeviceCode());
            }
        }
        else if ("/delete".equals(action)) {
            int id = Web.intParam(req, "id", 0);
            if (devices.delete(id)) {
                Web.flash(req, "Da xoa thiet bi");
            } else {
                Web.flash(req, "Loi khi xoa thiet bi (co the do dang co du lieu phien do lien quan)");
            }
        }
        resp.sendRedirect(req.getContextPath() + "/admin/devices");
    }

    private String action(HttpServletRequest req) {
        String path = req.getRequestURI().substring(req.getContextPath().length());
        return path.substring("/admin/devices".length());
    }
}
