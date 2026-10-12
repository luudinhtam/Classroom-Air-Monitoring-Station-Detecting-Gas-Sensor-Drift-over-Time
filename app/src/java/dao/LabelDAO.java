package dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;
import model.AirLabel;
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

    public List<AirLabel> findBySessionId(int sessionId) {
        List<AirLabel> list = new ArrayList<>();
        String sql = "SELECT l.label_id, l.session_id, l.label_code, l.source, l.reason, l.labeled_by, "
                   + "u.username, l.labeled_at "
                   + "FROM Air_Label l "
                   + "LEFT JOIN AppUser u ON l.labeled_by = u.user_id "
                   + "WHERE l.session_id = ? ORDER BY l.label_id ASC";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, sessionId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    AirLabel item = new AirLabel();
                    item.setLabelId(rs.getInt("label_id"));
                    item.setSessionId(rs.getInt("session_id"));
                    item.setLabelCode(rs.getString("label_code"));
                    item.setSource(rs.getString("source"));
                    item.setReason(rs.getString("reason"));
                    int uid = rs.getInt("labeled_by");
                    if (!rs.wasNull()) item.setLabeledBy(uid);
                    item.setUsername(rs.getString("username"));
                    item.setLabeledAt(rs.getTimestamp("labeled_at"));
                    list.add(item);
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }
}
