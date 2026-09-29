package dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import util.DBContext;

public class DeviceDAO {
    
    public Integer findIdByCodeAndKey(String code, String key) {
        String sql = "SELECT device_id FROM Device WHERE device_code = ? AND api_key = ?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, code);
            ps.setString(2, key);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt(1);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }
    
    public void logRejected(String body, String code, String reason) {
        String sql = "INSERT INTO RejectedPacket(raw_body, device_code, reason) VALUES (?, ?, ?)";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, body);
            ps.setString(2, code);
            ps.setString(3, reason);
            ps.executeUpdate();
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }
    
    public void touch(int deviceId) {
        String sql = "UPDATE Device SET last_seen = SYSDATETIME() WHERE device_id = ?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, deviceId);
            ps.executeUpdate();
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }
}
