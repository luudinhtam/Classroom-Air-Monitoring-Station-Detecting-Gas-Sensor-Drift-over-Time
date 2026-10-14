package controller;

import java.io.IOException;
import java.util.List;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import dao.UserDAO;
import model.AppRole;
import model.AppUser;
import util.PasswordUtil;
import util.Web;

@WebServlet(urlPatterns = { "/admin/users", 
                            "/admin/users/create", 
                            "/admin/users/edit", 
                            "/admin/users/save",
                            "/admin/users/delete", 
                            "/admin/users/lock", 
                            "/admin/users/reset"})
public class UserServlet extends HttpServlet {

    private static final int PAGE_SIZE = 10;
    private static final String DEFAULT_PASSWORD = "123456";
    private final UserDAO users = new UserDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String action = action(req);
        if ("/create".equals(action)) { 
            showForm(req, resp, null); 
            return; 
        }
        
        if ("/edit".equals(action)) {
            AppUser u = users.findById(Web.intParam(req, "id", 0));
            if (u == null) {
                Web.flash(req, "User not found");
                resp.sendRedirect(req.getContextPath() + "/admin/users");
                return;
            }
            showForm(req, resp, u);
            return;
        }
        showList(req, resp);
    }

    private void showList(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String keyword = Web.trimmed(req, "keyword");
        Integer roleId = Web.optionalInt(req, "roleId");
        String lockState = Web.trimmed(req, "lockState");
        int page = Web.intParam(req, "page", 1);
        if (page < 1) page = 1;

        int offset = (page - 1) * PAGE_SIZE;
        List<AppUser> rows = users.search(keyword, roleId, lockState, offset, PAGE_SIZE);
        int total = users.count(keyword, roleId, lockState);
        int pages = (total + PAGE_SIZE - 1) / PAGE_SIZE;

        req.setAttribute("rows", rows);
        req.setAttribute("roles", users.listRoles());
        
        req.setAttribute("keyword", keyword);
        req.setAttribute("roleId", roleId);
        req.setAttribute("lockState", lockState);
        req.setAttribute("page", Integer.valueOf(page));
        req.setAttribute("pages", Integer.valueOf(pages));
        req.setAttribute("total", Integer.valueOf(total));

        req.getRequestDispatcher("/WEB-INF/views/userList.jsp").forward(req, resp);
    }

    private void showForm(HttpServletRequest req, HttpServletResponse resp, AppUser u)
            throws ServletException, IOException {
        req.setAttribute("roles", users.listRoles());
        req.setAttribute("editUser", u);
        req.getRequestDispatcher("/WEB-INF/views/userForm.jsp").forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String action = action(req);

        if ("/save".equals(action)) {
            int id = Web.intParam(req, "userId", 0);
            AppUser u = new AppUser();
            u.setUserId(id);
            u.setUsername(Web.trimmed(req, "username"));
            u.setFullName(Web.trimmed(req, "fullName"));
            u.setRoleId(Web.intParam(req, "roleId", 0));

            if (id == 0) {
                u.setPassHash(PasswordUtil.hash(DEFAULT_PASSWORD));
                if (users.insert(u)) Web.flash(req, "Added user " + u.getUsername());
                else Web.flash(req, "Failed to add user, username might already exist");
            } else {
                if (users.update(u)) Web.flash(req, "User changes saved successfully");
                else Web.flash(req, "Failed to save user changes");
            }
        }
        else if ("/lock".equals(action)) {
            int id = Web.intParam(req, "id", 0);
            AppUser u = users.findById(id);
            if (u != null) {
                users.lock(id, !u.isLocked());
                Web.flash(req, "Successfully " + (u.isLocked() ? "unlocked " : "locked ") + u.getUsername());
            }
        }
        else if ("/reset".equals(action)) {
            int id = Web.intParam(req, "id", 0);
            if (users.resetPassword(id, PasswordUtil.hash(DEFAULT_PASSWORD))) {
                Web.flash(req, "Password reset successfully");
            }
        }
        else if ("/delete".equals(action)) {
            int id = Web.intParam(req, "id", 0);
            if (users.delete(id)) {
                Web.flash(req, "User deleted successfully");
            } else {
                Web.flash(req, "Failed to delete user");
            }
        }
        resp.sendRedirect(req.getContextPath() + "/admin/users");
    }

    private String action(HttpServletRequest req) {
        String path = req.getRequestURI().substring(req.getContextPath().length());
        return path.substring("/admin/users".length());
    }
}
