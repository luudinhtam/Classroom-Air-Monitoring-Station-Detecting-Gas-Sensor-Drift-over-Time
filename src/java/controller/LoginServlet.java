package controller;

import java.io.IOException;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import dao.UserDAO;
import model.AppUser;
import util.PasswordUtil;
import util.Web;

@WebServlet("/login")
public class LoginServlet extends HttpServlet {

    private final UserDAO users = new UserDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        if (req.getSession().getAttribute("user") != null) {
            resp.sendRedirect(req.getContextPath() + "/dashboard");
            return;
        }
        req.getRequestDispatcher("/WEB-INF/views/login.jsp").forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String username = Web.trimmed(req, "username");
        String password = req.getParameter("password");

        AppUser u = users.findByUsername(username);

        if (u == null) {
            fail(req, resp, "Sai ten dang nhap hoac mat khau");
            return;
        }
        if (u.isLocked()) {
            fail(req, resp, "Tai khoan da bi khoa, lien he quan tri vien");
            return;
        }
        if (password == null || !PasswordUtil.verify(password, u.getPassHash())) {
            fail(req, resp, "Sai ten dang nhap hoac mat khau");
            return;
        }

        u.setPassHash(null); // never keep the hash in session
        req.getSession().setAttribute("user", u);
        resp.sendRedirect(req.getContextPath() + "/dashboard");
    }

    private void fail(HttpServletRequest req, HttpServletResponse resp, String msg)
            throws ServletException, IOException {
        req.setAttribute("error", msg);
        req.getRequestDispatcher("/WEB-INF/views/login.jsp").forward(req, resp);
    }
}
