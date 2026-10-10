package filter;

import java.io.IOException;
import java.util.*;
import javax.servlet.*;
import javax.servlet.annotation.WebFilter;
import javax.servlet.http.*;
import model.AppUser;

/**
 * One filter guards every page. The map says which roles may reach which path
 * prefix, so adding a screen means adding one line here instead of scattering
 * role checks through the servlets.
 */
@WebFilter("/*")
public class AuthFilter implements Filter {

    private static final Map<String, Set<String>> ALLOWED = new LinkedHashMap<String, Set<String>>();

    static {
        ALLOWED.put("/admin", roles("ADMIN"));
        ALLOWED.put("/master", roles("ADMIN", "STATION_MANAGER", "OPERATOR"));
        ALLOWED.put("/label", roles("ADMIN", "STATION_MANAGER", "OPERATOR", "REVIEWER"));
        ALLOWED.put("/sessions", roles("ADMIN", "STATION_MANAGER", "OPERATOR", "REVIEWER", "VIEWER"));
        ALLOWED.put("/session", roles("ADMIN", "STATION_MANAGER", "OPERATOR", "REVIEWER", "VIEWER"));
        ALLOWED.put("/dashboard", roles("ADMIN", "STATION_MANAGER", "OPERATOR", "REVIEWER", "VIEWER"));
        ALLOWED.put("/export", roles("ADMIN", "STATION_MANAGER", "OPERATOR", "REVIEWER", "VIEWER"));
    }

    private static Set<String> roles(String... names) {
        return new HashSet<String>(Arrays.asList(names));
    }

    @Override
    public void doFilter(ServletRequest rq, ServletResponse rp, FilterChain chain)
            throws IOException, ServletException {
        HttpServletRequest req = (HttpServletRequest) rq;
        HttpServletResponse resp = (HttpServletResponse) rp;
        String path = req.getRequestURI().substring(req.getContextPath().length());

        // the device endpoint and the public files carry their own check
        if (path.startsWith("/api/") || path.startsWith("/login")
                || path.startsWith("/css/") || path.startsWith("/js/")) {
                chain.doFilter(rq, rp);
            return;
        }

        AppUser me = (AppUser) req.getSession().getAttribute("user");
        if (me == null) {
            resp.sendRedirect(req.getContextPath() + "/login");
            return;
        }

        for (Map.Entry<String, Set<String>> e : ALLOWED.entrySet()) {
            if (path.startsWith(e.getKey())) {
                if (!e.getValue().contains(me.getRoleCode())) {
                    resp.sendError(HttpServletResponse.SC_FORBIDDEN,
                            me.getRoleCode() + " không có quyền truy cập trang này!");
                    return;
                }
                break;
            }
        }
        chain.doFilter(rq, rp);
    }

    @Override public void init(FilterConfig c) { }
    @Override public void destroy() { }
}
