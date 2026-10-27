package dao;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import model.AirAlert;
import util.DBContext;

public class AlertDAO {

    private static final String SELECT_BASE =
        "SELECT a.alert_id, a.session_id, a.alert_code, a.alert_type, a.message, " +
        "a.status, a.handled_by, COALESCE(u.full_name, u.username) AS handled_by_name, a.note, a.created_at, " +
        "d.device_code, r.room_id, r.room_code " +
        "FROM Air_Alert a " +
        "LEFT JOIN AppUser u ON u.user_id = a.handled_by " +
        "LEFT JOIN Air_Session s ON s.session_id = a.session_id " +
        "LEFT JOIN Device d ON d.device_id = s.device_id " +
        "LEFT JOIN Room r ON (r.room_id = d.room_id OR (d.room_id IS NULL AND r.device_code = d.device_code)) ";

    public synchronized String generateNextAlertCode(Connection cn) {
        String sql = "SELECT TOP 1 alert_code FROM Air_Alert WHERE alert_code LIKE 'A%' ORDER BY alert_id DESC";
        try (Statement st = cn.createStatement();
             ResultSet rs = st.executeQuery(sql)) {
            if (rs.next()) {
                String lastCode = rs.getString(1);
                if (lastCode != null && lastCode.startsWith("A")) {
                    try {
                        int num = Integer.parseInt(lastCode.substring(1).trim());
                        return String.format("A%03d", num + 1);
                    } catch (Exception ignored) {}
                }
            }
        } catch (Exception ignored) {}
        return "A001";
    }

    private String normalizeAlertType(String raw) {
        if (raw == null) return "CO2";
        String upper = raw.trim().toUpperCase();
        if (upper.contains("TEMP")) return "TEMPERATURE";
        if (upper.contains("HUMID")) return "HUMID";
        if (upper.equals("CO")) return "CO";
        if (upper.contains("CO2") || upper.contains("CARBON")) return "CO2";
        return "CO2";
    }

    public void insert(int sessionId, String alertType, String message) {
        try (Connection cn = DBContext.getConnection()) {
            insert(sessionId, alertType, message, cn);
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }

    /**
     * Insert một Air_Alert nhận Connection từ ngoài để chạy trong transaction.
     * alert_code được tự động sinh dạng A001...
     */
    public AirAlert insert(int sessionId, String alertType, String message, Connection cn) throws SQLException {
        String type = normalizeAlertType(alertType);
        String sql = "INSERT INTO Air_Alert(session_id, alert_code, alert_type, message, status) VALUES (?, ?, ?, ?, 'OPENING')";
        String code = generateNextAlertCode(cn);
        try (PreparedStatement ps = cn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setInt(1, sessionId);
            ps.setString(2, code);
            ps.setString(3, type);
            ps.setString(4, message);
            ps.executeUpdate();

            AirAlert a = new AirAlert();
            try (ResultSet rs = ps.getGeneratedKeys()) {
                if (rs.next()) {
                    a.setAlertId(rs.getInt(1));
                }
            }
            a.setSessionId(sessionId);
            a.setAlertCode(code);
            a.setAlertType(type);
            a.setMessage(message);
            a.setStatus("OPENING");
            return a;
        }
    }

    public void insert(int sessionId, String alertCode, String alertType, String message) {
        String type = normalizeAlertType(alertType != null ? alertType : alertCode);
        String sql = "INSERT INTO Air_Alert(session_id, alert_code, alert_type, message, status) VALUES (?, ?, ?, ?, 'OPENING')";
        try (Connection cn = DBContext.getConnection()) {
            String code = (alertCode != null && alertCode.matches("(?i)A\\d+")) ? alertCode : generateNextAlertCode(cn);
            try (PreparedStatement ps = cn.prepareStatement(sql)) {
                ps.setInt(1, sessionId);
                ps.setString(2, code);
                ps.setString(3, type);
                ps.setString(4, message);
                ps.executeUpdate();
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }

    public List<AirAlert> search(String status, String alertCode, Integer roomId, int page, int size) {
        List<AirAlert> list = new ArrayList<>();
        StringBuilder sql = new StringBuilder(SELECT_BASE).append("WHERE 1=1 ");

        if (status != null && !status.isEmpty()) sql.append("AND a.status = ? ");
        if (alertCode != null && !alertCode.isEmpty()) sql.append("AND (a.alert_type = ? OR a.alert_code = ?) ");
        if (roomId != null && roomId > 0) sql.append("AND (r.room_id = ? OR d.room_id = ?) ");

        sql.append("ORDER BY a.created_at DESC, a.alert_id DESC OFFSET ? ROWS FETCH NEXT ? ROWS ONLY");

        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql.toString())) {
            int i = 1;
            if (status != null && !status.isEmpty()) ps.setString(i++, status);
            if (alertCode != null && !alertCode.isEmpty()) {
                ps.setString(i++, alertCode);
                ps.setString(i++, alertCode);
            }
            if (roomId != null && roomId > 0) {
                ps.setInt(i++, roomId);
                ps.setInt(i++, roomId);
            }
            ps.setInt(i++, (page - 1) * size);
            ps.setInt(i++, size);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(map(rs));
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }

    public List<AirAlert> search(String status, String alertCode, int page, int size) {
        return search(status, alertCode, (Integer) null, page, size);
    }

    public List<AirAlert> search(String status, String alertCode, String severity, int page, int size) {
        return search(status, alertCode, (Integer) null, page, size);
    }

    /**
     * Lấy danh sách cảnh báo của riêng một phòng học theo roomId hoặc deviceCode
     */
    public List<AirAlert> getAlertsByRoom(int roomId, String deviceCode, int limit) {
        List<AirAlert> list = new ArrayList<>();
        if (roomId <= 0 && (deviceCode == null || deviceCode.trim().isEmpty())) {
            return list;
        }
        String sql = SELECT_BASE + 
            "WHERE (d.room_id = ? " +
            "   OR (? IS NOT NULL AND ? != '' AND d.device_code = ?) " +
            "   OR d.device_code IN (SELECT r.device_code FROM Room r WHERE r.room_id = ? AND r.device_code IS NOT NULL AND r.device_code != '')) " +
            "ORDER BY a.created_at DESC, a.alert_id DESC " +
            "OFFSET 0 ROWS FETCH NEXT ? ROWS ONLY";

        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, roomId);
            ps.setString(2, deviceCode);
            ps.setString(3, deviceCode);
            ps.setString(4, deviceCode);
            ps.setInt(5, roomId);
            ps.setInt(6, limit > 0 ? limit : 50);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(map(rs));
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }

    public int count(String status, String alertCode, Integer roomId) {
        StringBuilder sql;
        if (roomId != null && roomId > 0) {
            sql = new StringBuilder("SELECT COUNT(*) FROM Air_Alert a ")
                    .append("LEFT JOIN Air_Session s ON s.session_id = a.session_id ")
                    .append("LEFT JOIN Device d ON d.device_id = s.device_id ")
                    .append("LEFT JOIN Room r ON (r.room_id = d.room_id OR (d.room_id IS NULL AND r.device_code = d.device_code)) ")
                    .append("WHERE 1=1 ");
        } else {
            sql = new StringBuilder("SELECT COUNT(*) FROM Air_Alert a WHERE 1=1 ");
        }

        if (status != null && !status.isEmpty()) sql.append("AND a.status = ? ");
        if (alertCode != null && !alertCode.isEmpty()) sql.append("AND (a.alert_type = ? OR a.alert_code = ?) ");
        if (roomId != null && roomId > 0) sql.append("AND (r.room_id = ? OR d.room_id = ?) ");

        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql.toString())) {
            int i = 1;
            if (status != null && !status.isEmpty()) ps.setString(i++, status);
            if (alertCode != null && !alertCode.isEmpty()) {
                ps.setString(i++, alertCode);
                ps.setString(i++, alertCode);
            }
            if (roomId != null && roomId > 0) {
                ps.setInt(i++, roomId);
                ps.setInt(i++, roomId);
            }

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt(1);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return 0;
    }

    public int count(String status, String alertCode) {
        return count(status, alertCode, (Integer) null);
    }

    public int count(String status, String alertCode, String severity) {
        return count(status, alertCode, (Integer) null);
    }

    public boolean updateStatus(int alertId, String status, int handledBy, String note) {
        String sql = "UPDATE Air_Alert SET status = ?, handled_by = ?, note = ? WHERE alert_id = ?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, status);
            if (handledBy > 0) ps.setInt(2, handledBy); else ps.setNull(2, Types.INTEGER);
            ps.setString(3, note);
            ps.setInt(4, alertId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }

    public AirAlert findById(int alertId) {
        String sql = SELECT_BASE + "WHERE a.alert_id = ?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, alertId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return map(rs);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }

    private AirAlert map(ResultSet rs) throws SQLException {
        AirAlert a = new AirAlert();
        a.setAlertId(rs.getInt("alert_id"));
        int sessId = rs.getInt("session_id");
        if (!rs.wasNull()) a.setSessionId(sessId);
        String code = rs.getString("alert_code");
        a.setAlertCode(code);
        try {
            a.setAlertType(rs.getString("alert_type"));
        } catch (SQLException ignored) {}
        a.setRuleCode(a.getAlertType() != null ? a.getAlertType() : code);
        a.setSeverity(a.getAlertType() != null ? a.getAlertType() : (code != null ? code : "WARNING"));
        a.setMessage(rs.getString("message"));
        a.setStatus(rs.getString("status"));
        int uid = rs.getInt("handled_by");
        if (!rs.wasNull()) a.setHandledBy(uid);
        a.setHandledByName(rs.getString("handled_by_name"));
        a.setNote(rs.getString("note"));
        a.setHandledNote(rs.getString("note"));
        a.setCreatedAt(rs.getTimestamp("created_at"));
        try {
            a.setDeviceCode(rs.getString("device_code"));
        } catch (SQLException ignored) {}
        try {
            a.setRoomCode(rs.getString("room_code"));
            int rId = rs.getInt("room_id");
            if (!rs.wasNull()) a.setRoomId(rId);
        } catch (SQLException ignored) {}
        return a;
    }
}
