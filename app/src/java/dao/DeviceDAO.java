package dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import model.Device;
import util.DBContext;

public class DeviceDAO {
    
    private static final String SELECT_BASE = 
        "SELECT device_id, device_code, api_key, location, last_seen, is_active " +
        "FROM Device ";

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

    public Device findById(int id) {
        Connection cn = null; PreparedStatement ps = null; ResultSet rs = null;
        try {
            cn = DBContext.getConnection();
            ps = cn.prepareStatement(SELECT_BASE + "WHERE device_id = ?");
            ps.setInt(1, id);
            rs = ps.executeQuery();
            if (rs.next()) return map(rs);
        } catch (SQLException e) { e.printStackTrace(); }
        finally { close(rs, ps, cn); }
        return null;
    }

    public List<Device> search(String keyword, String activeState, int offset, int limit) {
        List<Device> out = new ArrayList<>();
        StringBuilder sql = new StringBuilder(SELECT_BASE).append("WHERE 1 = 1 ");

        if (keyword != null && !keyword.trim().isEmpty()) {
            sql.append("AND (device_code LIKE ? OR location LIKE ?) ");
        }
        if ("ACTIVE".equals(activeState)) {
            sql.append("AND is_active = 1 ");
        } else if ("INACTIVE".equals(activeState)) {
            sql.append("AND is_active = 0 ");
        }
        sql.append("ORDER BY device_id ASC OFFSET ? ROWS FETCH NEXT ? ROWS ONLY");

        Connection cn = null; PreparedStatement ps = null; ResultSet rs = null;
        try {
            cn = DBContext.getConnection();
            ps = cn.prepareStatement(sql.toString());
            int i = 1;
            if (keyword != null && !keyword.trim().isEmpty()) {
                String kw = "%" + keyword.trim() + "%";
                ps.setString(i++, kw);
                ps.setString(i++, kw);
            }
            ps.setInt(i++, offset);
            ps.setInt(i++, limit);
            rs = ps.executeQuery();
            while (rs.next()) out.add(map(rs));
        } catch (SQLException e) { e.printStackTrace(); }
        finally { close(rs, ps, cn); }
        return out;
    }

    public int count(String keyword, String activeState) {
        StringBuilder sql = new StringBuilder("SELECT COUNT(*) FROM Device WHERE 1 = 1 ");
        if (keyword != null && !keyword.trim().isEmpty()) {
            sql.append("AND (device_code LIKE ? OR location LIKE ?) ");
        }
        if ("ACTIVE".equals(activeState)) {
            sql.append("AND is_active = 1 ");
        } else if ("INACTIVE".equals(activeState)) {
            sql.append("AND is_active = 0 ");
        }

        Connection cn = null; PreparedStatement ps = null; ResultSet rs = null;
        try {
            cn = DBContext.getConnection();
            ps = cn.prepareStatement(sql.toString());
            int i = 1;
            if (keyword != null && !keyword.trim().isEmpty()) {
                String kw = "%" + keyword.trim() + "%";
                ps.setString(i++, kw);
                ps.setString(i++, kw);
            }
            rs = ps.executeQuery();
            if (rs.next()) return rs.getInt(1);
        } catch (SQLException e) { e.printStackTrace(); }
        finally { close(rs, ps, cn); }
        return 0;
    }

    public boolean insert(Device d) {
        String sql = "INSERT INTO Device(device_code, api_key, location, is_active) VALUES (?, ?, ?, ?)";
        Connection cn = null; PreparedStatement ps = null;
        try {
            cn = DBContext.getConnection();
            ps = cn.prepareStatement(sql);
            ps.setString(1, d.getDeviceCode());
            ps.setString(2, d.getApiKey());
            ps.setString(3, d.getLocation());
            ps.setBoolean(4, d.isIsActive());
            return ps.executeUpdate() > 0;
        } catch (SQLException e) { e.printStackTrace(); }
        finally { close(null, ps, cn); }
        return false;
    }

    public boolean update(Device d) {
        String sql = "UPDATE Device SET api_key = ?, location = ?, is_active = ? WHERE device_id = ?";
        Connection cn = null; PreparedStatement ps = null;
        try {
            cn = DBContext.getConnection();
            ps = cn.prepareStatement(sql);
            ps.setString(1, d.getApiKey());
            ps.setString(2, d.getLocation());
            ps.setBoolean(3, d.isIsActive());
            ps.setInt(4, d.getDeviceId());
            return ps.executeUpdate() > 0;
        } catch (SQLException e) { e.printStackTrace(); }
        finally { close(null, ps, cn); }
        return false;
    }

    public boolean setActive(int id, boolean active) {
        String sql = "UPDATE Device SET is_active = ? WHERE device_id = ?";
        Connection cn = null; PreparedStatement ps = null;
        try {
            cn = DBContext.getConnection();
            ps = cn.prepareStatement(sql);
            ps.setBoolean(1, active);
            ps.setInt(2, id);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) { e.printStackTrace(); }
        finally { close(null, ps, cn); }
        return false;
    }

    public boolean delete(int id) {
        String sql = "DELETE FROM Device WHERE device_id = ?";
        Connection cn = null; PreparedStatement ps = null;
        try {
            cn = DBContext.getConnection();
            ps = cn.prepareStatement(sql);
            ps.setInt(1, id);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) { e.printStackTrace(); }
        finally { close(null, ps, cn); }
        return false;
    }

    private Device map(ResultSet rs) throws SQLException {
        Device d = new Device();
        d.setDeviceId(rs.getInt("device_id"));
        d.setDeviceCode(rs.getString("device_code"));
        d.setApiKey(rs.getString("api_key"));
        d.setLocation(rs.getString("location"));
        d.setLastSeen(rs.getTimestamp("last_seen"));
        d.setIsActive(rs.getBoolean("is_active"));
        return d;
    }

    private void close(ResultSet rs, PreparedStatement ps, Connection cn) {
        try { if (rs != null) rs.close(); } catch (Exception e) {}
        try { if (ps != null) ps.close(); } catch (Exception e) {}
        try { if (cn != null) cn.close(); } catch (Exception e) {}
    }
}
