package dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import util.DBContext;

public class LabelDAO {
    
    public void insert(int sessionId, String labelCode, String source, String reason, Integer labeledBy) {
        String sql = "INSERT INTO Air_Label(session_id, label_code, source, reason, labeled_by) VALUES (?, ?, ?, ?, ?)";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, sessionId);
            ps.setString(2, labelCode);
            ps.setString(3, source);
            ps.setString(4, reason);
            if (labeledBy != null) {
                ps.setInt(5, labeledBy);
            } else {
                ps.setNull(5, java.sql.Types.INTEGER);
            }
            ps.executeUpdate();
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }
}
