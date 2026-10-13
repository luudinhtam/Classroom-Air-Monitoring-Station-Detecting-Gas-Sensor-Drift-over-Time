package dao;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import model.AirAlert;
import util.DBContext;

public class AlertDAO {

    private static final String SELECT_BASE =
        "SELECT a.alert_id, a.session_id, a.rule_code, a.severity, a.message, " +
        "a.status, a.handled_by, u.full_name AS handled_by_name, a.handled_note, a.created_at " +
        "FROM Air_Alert a " +
        "LEFT JOIN AppUser u ON u.user_id = a.handled_by ";

    public void insert(int sessionId, String labelCode, String severity, String message) {
        String sql = "INSERT INTO Air_Alert(session_id, rule_code, severity, message) VALUES (?, ?, ?, ?)";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, sessionId);
            ps.setString(2, labelCode);
            ps.setString(3, severity);
            ps.setString(4, message);
            ps.executeUpdate();
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }

    public List<AirAlert> search(String status, String ruleCode, String severity, int page, int size) {
        List<AirAlert> list = new ArrayList<>();
        StringBuilder sql = new StringBuilder(SELECT_BASE).append("WHERE 1=1 ");

        if (status != null && !status.isEmpty()) sql.append("AND a.status = ? ");
        if (ruleCode != null && !ruleCode.isEmpty()) sql.append("AND a.rule_code = ? ");
        if (severity != null && !severity.isEmpty()) sql.append("AND a.severity = ? ");

        sql.append("ORDER BY a.alert_id DESC OFFSET ? ROWS FETCH NEXT ? ROWS ONLY");

        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql.toString())) {
            int i = 1;
            if (status != null && !status.isEmpty()) ps.setString(i++, status);
            if (ruleCode != null && !ruleCode.isEmpty()) ps.setString(i++, ruleCode);
            if (severity != null && !severity.isEmpty()) ps.setString(i++, severity);
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

    public int count(String status, String ruleCode, String severity) {
        StringBuilder sql = new StringBuilder("SELECT COUNT(*) FROM Air_Alert a WHERE 1=1 ");

        if (status != null && !status.isEmpty()) sql.append("AND a.status = ? ");
        if (ruleCode != null && !ruleCode.isEmpty()) sql.append("AND a.rule_code = ? ");
        if (severity != null && !severity.isEmpty()) sql.append("AND a.severity = ? ");

        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql.toString())) {
            int i = 1;
            if (status != null && !status.isEmpty()) ps.setString(i++, status);
            if (ruleCode != null && !ruleCode.isEmpty()) ps.setString(i++, ruleCode);
            if (severity != null && !severity.isEmpty()) ps.setString(i++, severity);

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt(1);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return 0;
    }

    public boolean updateStatus(int alertId, String status, int handledBy, String handledNote) {
        String sql = "UPDATE Air_Alert SET status = ?, handled_by = ?, handled_note = ? WHERE alert_id = ?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, status);
            ps.setInt(2, handledBy);
            ps.setString(3, handledNote);
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
        a.setRuleCode(rs.getString("rule_code"));
        a.setSeverity(rs.getString("severity"));
        a.setMessage(rs.getString("message"));
        a.setStatus(rs.getString("status"));
        int uid = rs.getInt("handled_by");
        if (!rs.wasNull()) a.setHandledBy(uid);
        a.setHandledByName(rs.getString("handled_by_name"));
        a.setHandledNote(rs.getString("handled_note"));
        a.setCreatedAt(rs.getTimestamp("created_at"));
        return a;
    }
}
