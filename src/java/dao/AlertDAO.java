package dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import util.DBContext;

public class AlertDAO {
    
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
}
