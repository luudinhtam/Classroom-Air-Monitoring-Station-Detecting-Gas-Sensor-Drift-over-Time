package controller;

import java.io.IOException;
import java.sql.Timestamp;
import java.text.SimpleDateFormat;
import java.util.Locale;
import javax.servlet.http.HttpServletResponse;
import service.MeasureException;

/**
 * Tiện ích dùng chung cho các Servlet Web phục vụ chức năng Measure.
 * Định dạng JSON chuẩn, ánh xạ lỗi và thiết lập Header đồng nhất.
 */
public class MeasureWebUtil {

    private static final String DATE_PATTERN = "yyyy-MM-dd HH:mm:ss";

    public static void writeJson(HttpServletResponse resp, int statusCode, String jsonBody) throws IOException {
        resp.setStatus(statusCode);
        resp.setContentType("application/json;charset=UTF-8");
        resp.setCharacterEncoding("UTF-8");
        resp.setHeader("Cache-Control", "no-store, no-cache, must-revalidate");
        resp.setHeader("Pragma", "no-cache");
        resp.getWriter().write(jsonBody);
    }

    public static void writeError(HttpServletResponse resp, int statusCode, String errorCode, String message) throws IOException {
        String safeMsg = escapeJson(message != null ? message : "");
        String safeCode = escapeJson(errorCode != null ? errorCode : "ERROR");
        String json = "{\"error\":\"" + safeCode + "\",\"message\":\"" + safeMsg + "\"}";
        writeJson(resp, statusCode, json);
    }

    public static void handleMeasureException(HttpServletResponse resp, MeasureException ex) throws IOException {
        MeasureException.ErrorCode code = ex.getCode();
        int httpStatus;
        switch (code) {
            case NO_DEVICE:
            case DEVICE_BUSY:
                httpStatus = HttpServletResponse.SC_CONFLICT; // 409
                break;
            case NOT_FOUND:
                httpStatus = HttpServletResponse.SC_NOT_FOUND; // 404
                break;
            case INVALID_COMMAND:
            case INVALID_DATA:
                httpStatus = HttpServletResponse.SC_BAD_REQUEST; // 400
                break;
            case SYSTEM_ERROR:
            default:
                httpStatus = HttpServletResponse.SC_INTERNAL_SERVER_ERROR; // 500
                break;
        }
        writeError(resp, httpStatus, code.name(), ex.getMessage());
    }

    public static String formatDate(Timestamp ts) {
        if (ts == null) return "";
        SimpleDateFormat sdf = new SimpleDateFormat(DATE_PATTERN, Locale.US);
        return sdf.format(ts);
    }

    public static String formatDecimal(Double val) {
        if (val == null) return "null";
        return String.format(Locale.US, "%.1f", val);
    }

    public static String formatDecimal(Float val) {
        if (val == null) return "null";
        return String.format(Locale.US, "%.1f", val);
    }

    public static boolean isValidRoomCode(String code) {
        if (code == null) return false;
        String trimmed = code.trim();
        return trimmed.length() >= 1 && trimmed.length() <= 32 && trimmed.matches("^[A-Za-z0-9_-]+$");
    }

    public static Integer parseCommandId(String param) {
        if (param == null || param.trim().isEmpty()) return null;
        try {
            int val = Integer.parseInt(param.trim());
            return val >= 0 ? val : null;
        } catch (NumberFormatException e) {
            return null;
        }
    }

    public static String escapeJson(String s) {
        if (s == null) return "";
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < s.length(); i++) {
            char ch = s.charAt(i);
            switch (ch) {
                case '"': sb.append("\\\""); break;
                case '\\': sb.append("\\\\"); break;
                case '\b': sb.append("\\b"); break;
                case '\f': sb.append("\\f"); break;
                case '\n': sb.append("\\n"); break;
                case '\r': sb.append("\\r"); break;
                case '\t': sb.append("\\t"); break;
                default:
                    if (ch <= '\u001F') {
                        sb.append(String.format("\\u%04x", (int) ch));
                    } else {
                        sb.append(ch);
                    }
                    break;
            }
        }
        return sb.toString();
    }
}
