package util;

import javax.servlet.http.HttpServletRequest;
import model.AppUser;

/** Small helpers every controller needs, kept out of the servlets themselves. */
public class Web {

    public static AppUser currentUser(HttpServletRequest req) {
        return (AppUser) req.getSession().getAttribute("user");
    }

    public static Integer currentUserId(HttpServletRequest req) {
        AppUser u = currentUser(req);
        return (u == null) ? null : Integer.valueOf(u.getUserId());
    }

    /** Reads an int parameter, falling back to a default when absent or malformed. */
    public static int intParam(HttpServletRequest req, String name, int fallback) {
        String s = req.getParameter(name);
        if (s == null || s.trim().length() == 0) return fallback;
        try { return Integer.parseInt(s.trim()); }
        catch (NumberFormatException e) { return fallback; }
    }

    /** Reads an optional int parameter, returning null when the field was left blank. */
    public static Integer optionalInt(HttpServletRequest req, String name) {
        String s = req.getParameter(name);
        if (s == null || s.trim().length() == 0) return null;
        try { return Integer.valueOf(s.trim()); }
        catch (NumberFormatException e) { return null; }
    }

    public static String trimmed(HttpServletRequest req, String name) {
        String s = req.getParameter(name);
        return (s == null) ? "" : s.trim();
    }

    public static void flash(HttpServletRequest req, String message) {
        req.getSession().setAttribute("flash", message);
    }

    /** Escapes the five characters that would otherwise break the page markup. */
    public static String esc(String s) {
        if (s == null) return "";
        StringBuilder sb = new StringBuilder(s.length() + 16);
        for (int i = 0; i < s.length(); i++) {
            char c = s.charAt(i);
            if (c == '&') sb.append("&amp;");
            else if (c == '<') sb.append("&lt;");
            else if (c == '>') sb.append("&gt;");
            else if (c == '"') sb.append("&quot;");
            else if (c == '\'') sb.append("&#39;");
            else sb.append(c);
        }
        return sb.toString();
    }

    public static String clientIp(HttpServletRequest req) {
        String h = req.getHeader("X-Forwarded-For");
        if (h != null && h.length() > 0) return h.split(",")[0].trim();
        return req.getRemoteAddr();
    }
}
