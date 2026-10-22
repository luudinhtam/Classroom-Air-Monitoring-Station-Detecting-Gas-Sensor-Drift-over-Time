package filter;

import java.io.IOException;
import java.util.*;
import javax.servlet.*;
import javax.servlet.annotation.WebFilter;
import javax.servlet.http.*;
import model.AppUser;

@WebFilter("/*")
public class AuthFilter implements Filter {

    private static final Map<String, Set<String>> ALLOWED = new LinkedHashMap<>();

    static {
        // 1. CHỈ ADMIN: Quản lý người dùng và thiết bị
        ALLOWED.put("/admin/users", roles("ADMIN"));
        ALLOWED.put("/admin/devices", roles("ADMIN"));
        
        // 2. PHÒNG, HIỆU CHUẨN, PHÒNG TRỐNG
        ALLOWED.put("/admin/rooms/create", roles("ADMIN", "STATION_MANAGER", "OPERATOR"));
        ALLOWED.put("/admin/rooms/edit", roles("ADMIN", "STATION_MANAGER", "OPERATOR"));
        ALLOWED.put("/admin/rooms/save", roles("ADMIN", "STATION_MANAGER", "OPERATOR"));
        ALLOWED.put("/admin/rooms/delete", roles("ADMIN", "STATION_MANAGER", "OPERATOR"));
        ALLOWED.put("/admin/rooms/lock", roles("ADMIN", "STATION_MANAGER", "OPERATOR"));
        ALLOWED.put("/admin/rooms/update-coords", roles("ADMIN", "STATION_MANAGER", "OPERATOR"));
        
        ALLOWED.put("/admin/calibrations/create", roles("ADMIN", "STATION_MANAGER", "OPERATOR"));
        ALLOWED.put("/admin/calibrations/edit", roles("ADMIN", "STATION_MANAGER", "OPERATOR"));
        ALLOWED.put("/admin/calibrations/save", roles("ADMIN", "STATION_MANAGER", "OPERATOR"));
        ALLOWED.put("/admin/calibrations/delete", roles("ADMIN", "STATION_MANAGER", "OPERATOR"));
        
        ALLOWED.put("/admin/emptyWindows/create", roles("ADMIN", "STATION_MANAGER", "OPERATOR"));
        ALLOWED.put("/admin/emptyWindows/edit", roles("ADMIN", "STATION_MANAGER", "OPERATOR"));
        ALLOWED.put("/admin/emptyWindows/save", roles("ADMIN", "STATION_MANAGER", "OPERATOR"));
        ALLOWED.put("/admin/emptyWindows/delete", roles("ADMIN", "STATION_MANAGER", "OPERATOR"));
        ALLOWED.put("/admin/emptyWindows/baseline", roles("ADMIN", "STATION_MANAGER", "OPERATOR"));

        // 3. QUYỀN XEM PHÒNG, HIỆU CHUẨN, PHÒNG TRỐNG
        ALLOWED.put("/admin/rooms/detail", roles("ADMIN", "STATION_MANAGER", "OPERATOR", "REVIEWER", "VIEWER"));
        ALLOWED.put("/admin/rooms", roles("ADMIN", "STATION_MANAGER", "OPERATOR", "REVIEWER", "VIEWER"));
        ALLOWED.put("/admin/calibrations", roles("ADMIN", "STATION_MANAGER", "OPERATOR", "REVIEWER", "VIEWER"));
        ALLOWED.put("/admin/emptyWindows", roles("ADMIN", "STATION_MANAGER", "OPERATOR", "REVIEWER", "VIEWER"));

        // 4. PHIÊN ĐO (Sử dụng đường dẫn gốc không có /admin)
        ALLOWED.put("/alerts", roles("ADMIN", "STATION_MANAGER", "OPERATOR", "REVIEWER", "VIEWER")); 
        ALLOWED.put("/sessions/create", roles("ADMIN"));
        ALLOWED.put("/sessions/delete", roles("ADMIN"));
        ALLOWED.put("/sessions/edit", roles("ADMIN", "STATION_MANAGER", "OPERATOR", "REVIEWER")); 
        ALLOWED.put("/sessions/save", roles("ADMIN", "STATION_MANAGER", "OPERATOR", "REVIEWER"));
        ALLOWED.put("/sessions/detail", roles("ADMIN", "STATION_MANAGER", "OPERATOR", "REVIEWER", "VIEWER"));
        ALLOWED.put("/sessions/export", roles("ADMIN", "STATION_MANAGER", "OPERATOR", "REVIEWER", "VIEWER"));
        ALLOWED.put("/sessions", roles("ADMIN", "STATION_MANAGER", "OPERATOR", "REVIEWER", "VIEWER"));
        
        // 5. LABEL & DASHBOARD
        ALLOWED.put("/label/correct", roles("ADMIN", "REVIEWER")); 
        ALLOWED.put("/dashboard", roles("ADMIN", "STATION_MANAGER", "OPERATOR", "REVIEWER", "VIEWER"));
    }

    private static Set<String> roles(String... names) {
        return new HashSet<>(Arrays.asList(names));
    }

    @Override
    public void doFilter(ServletRequest rq, ServletResponse rp, FilterChain chain)
            throws IOException, ServletException {

        HttpServletRequest req = (HttpServletRequest) rq;
        HttpServletResponse resp = (HttpServletResponse) rp;
        String path = req.getRequestURI().substring(req.getContextPath().length());

        if (path.startsWith("/api/") || path.startsWith("/login")
            || path.startsWith("/assets/") || path.startsWith("/css/") || path.startsWith("/js/")) {
            chain.doFilter(rq, rp);
            return;
        }

        AppUser me = (AppUser) req.getSession().getAttribute("user");
        if (me == null) {
            resp.sendRedirect(req.getContextPath() + "/login");
            return;
        }

        boolean isAllowed = false;
        String matchedPath = "";
        
        for (Map.Entry<String, Set<String>> e : ALLOWED.entrySet()) {
            if (path.startsWith(e.getKey()) && e.getKey().length() > matchedPath.length()) {
                matchedPath = e.getKey();
                isAllowed = e.getValue().contains(me.getRoleCode());
            }
        }

        if (!matchedPath.isEmpty() && !isAllowed) {
            req.setAttribute("neededPerm", matchedPath);
            req.getRequestDispatcher("/WEB-INF/views/denied.jsp").forward(req, resp);
            return;
        }

        chain.doFilter(rq, rp);
    }

    @Override public void init(FilterConfig c) { }
    @Override public void destroy() { }
}