package dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;
import java.util.ArrayList;
import java.util.List;
import model.Device;
import util.DBContext;

public class DeviceDAO {
    
    private static final String SELECT_BASE = 
        "SELECT device_id, device_code, api_key, note, last_seen, is_active, room_id " +
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

    /**
     * Xác thực thiết bị: đúng device_code, đúng api_key và is_active = 1.
     * Cập nhật last_seen = SYSDATETIME() mỗi lần xác thực thành công.
     */
    public Device authenticate(String deviceCode, String apiKey) {
        if (deviceCode == null || apiKey == null || deviceCode.trim().isEmpty() || apiKey.trim().isEmpty()) {
            return null;
        }
        String sql = SELECT_BASE + "WHERE device_code = ? AND api_key = ? AND is_active = 1";
        Device dev = null;
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, deviceCode.trim());
            ps.setString(2, apiKey.trim());
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    dev = map(rs);
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        if (dev != null) {
            touch(dev.getDeviceId());
        }
        return dev;
    }

    /**
     * Tìm thiết bị đang hoạt động (is_active = 1) gắn với một phòng học (qua room_id).
     */
    public Device findActiveByRoom(int roomId) {
        String sql = SELECT_BASE + 
                     "WHERE is_active = 1 AND (room_id = ? " +
                     "   OR device_code = (SELECT r.device_code FROM Room r WHERE r.room_id = ? AND r.device_code IS NOT NULL)) " +
                     "ORDER BY device_id DESC";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, roomId);
            ps.setInt(2, roomId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return map(rs);
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
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
    
    public List<Device> getActiveDevices() {
        List<Device> list = new ArrayList<>();

        String sql = "SELECT device_id, device_code, api_key, note, "
                   + "last_seen, is_active, room_id "
                   + "FROM Device "
                   + "WHERE is_active = 1 "
                   + "ORDER BY device_code";

        try (Connection con = DBContext.getConnection();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                Device device = new Device();

                device.setDeviceId(rs.getInt("device_id"));
                device.setDeviceCode(rs.getString("device_code"));
                device.setApiKey(rs.getString("api_key"));
                device.setNote(rs.getString("note"));
                device.setLastSeen(rs.getTimestamp("last_seen"));
                device.setIsActive(rs.getBoolean("is_active"));
                device.setRoomId(rs.getObject("room_id") != null ? rs.getInt("room_id") : null);

                list.add(device);
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return list;
    }

    /**
     * Get active devices (is_active = 1) that are not currently assigned to any room.
     */
    public List<Device> getUnassignedDevices() {
        return getUnassignedDevices(null);
    }

    /**
     * Get active devices that are unassigned, or optionally match currentDeviceCode (for edit mode).
     */
    public List<Device> getUnassignedDevices(String currentDeviceCode) {
        List<Device> list = new ArrayList<>();
        StringBuilder sql = new StringBuilder();
        sql.append("SELECT d.device_id, d.device_code, d.api_key, d.note, d.last_seen, d.is_active, d.room_id ")
           .append("FROM Device d ")
           .append("WHERE d.is_active = 1 ")
           .append("  AND ( ")
           .append("        (d.room_id IS NULL AND NOT EXISTS ( ")
           .append("            SELECT 1 FROM Room r ")
           .append("            WHERE r.device_code IS NOT NULL ")
           .append("              AND r.device_code != '' ")
           .append("              AND r.device_code = d.device_code ")
           .append("        )) ");
        if (currentDeviceCode != null && !currentDeviceCode.trim().isEmpty()) {
            sql.append("     OR d.device_code = ? ");
        }
        sql.append("  ) ")
           .append("ORDER BY d.device_code ASC");

        try (Connection con = DBContext.getConnection();
             PreparedStatement ps = con.prepareStatement(sql.toString())) {

            if (currentDeviceCode != null && !currentDeviceCode.trim().isEmpty()) {
                ps.setString(1, currentDeviceCode.trim());
            }

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Device device = new Device();
                    device.setDeviceId(rs.getInt("device_id"));
                    device.setDeviceCode(rs.getString("device_code"));
                    device.setApiKey(rs.getString("api_key"));
                    device.setNote(rs.getString("note"));
                    device.setLastSeen(rs.getTimestamp("last_seen"));
                    device.setIsActive(rs.getBoolean("is_active"));
                    device.setRoomId(rs.getObject("room_id") != null ? rs.getInt("room_id") : null);
                    list.add(device);
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }

        return list;
    }

    public List<Device> getAllDevicesWithDetails() {
        List<Device> list = new ArrayList<>();
        String sql = "SELECT d.device_id, d.device_code, d.api_key, d.note, d.last_seen, d.is_active, d.room_id, "
                   + "       r.room_code AS room_code, r.name AS room_name "
                   + "FROM Device d "
                   + "LEFT JOIN Room r ON (d.room_id IS NOT NULL AND d.room_id = r.room_id) "
                   + "                 OR (d.room_id IS NULL AND r.device_code IS NOT NULL AND r.device_code = d.device_code) "
                   + "ORDER BY d.device_code ASC";

        try (Connection con = DBContext.getConnection();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                Device d = new Device();
                d.setDeviceId(rs.getInt("device_id"));
                d.setDeviceCode(rs.getString("device_code"));
                d.setApiKey(rs.getString("api_key"));
                d.setNote(rs.getString("note"));
                d.setLastSeen(rs.getTimestamp("last_seen"));
                boolean active = rs.getBoolean("is_active");
                d.setIsActive(active);
                d.setRoomId(rs.getObject("room_id") != null ? rs.getInt("room_id") : null);

                String rCode = rs.getString("room_code");
                String rName = rs.getString("room_name");
                d.setRoomCode(rCode != null ? rCode : "-");
                d.setRoomName(rName != null ? rName : d.getRoomCode());

                // Status strictly based on is_active: Active (1) or Inactive (0)
                d.setStatus(active ? "Active" : "Inactive");

                list.add(d);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }

    public List<Device> search(String keyword, String activeState, int offset, int limit) {
        List<Device> out = new ArrayList<>();
        StringBuilder sql = new StringBuilder(SELECT_BASE).append("WHERE 1 = 1 ");

        if (keyword != null && !keyword.trim().isEmpty()) {
            sql.append("AND device_code LIKE ? ");
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
            sql.append("AND device_code LIKE ? ");
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
            }
            rs = ps.executeQuery();
            if (rs.next()) return rs.getInt(1);
        } catch (SQLException e) { e.printStackTrace(); }
        finally { close(rs, ps, cn); }
        return 0;
    }

    public boolean insert(Device d) {
        String sql = "INSERT INTO Device(device_code, api_key, note, is_active, room_id) VALUES (?, ?, ?, ?, ?)";
        Connection cn = null; PreparedStatement ps = null;
        try {
            cn = DBContext.getConnection();
            ps = cn.prepareStatement(sql);
            ps.setString(1, d.getDeviceCode());
            ps.setString(2, d.getApiKey());
            ps.setString(3, d.getNote());
            ps.setBoolean(4, d.isIsActive());
            if (d.getRoomId() != null) {
                ps.setInt(5, d.getRoomId());
            } else {
                ps.setNull(5, Types.INTEGER);
            }
            return ps.executeUpdate() > 0;
        } catch (SQLException e) { e.printStackTrace(); }
        finally { close(null, ps, cn); }
        return false;
    }

    public boolean update(Device d) {
        String sql = "UPDATE Device SET api_key = ?, note = ?, is_active = ?, room_id = ? WHERE device_id = ?";
        Connection cn = null; PreparedStatement ps = null;
        try {
            cn = DBContext.getConnection();
            ps = cn.prepareStatement(sql);
            ps.setString(1, d.getApiKey());
            ps.setString(2, d.getNote());
            ps.setBoolean(3, d.isIsActive());
            if (d.getRoomId() != null) {
                ps.setInt(4, d.getRoomId());
            } else {
                ps.setNull(4, Types.INTEGER);
            }
            ps.setInt(5, d.getDeviceId());
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

    public boolean assignRoomToDevice(String deviceCode, int roomId) {
        if (deviceCode == null || deviceCode.trim().isEmpty()) return false;
        String sql = "UPDATE Device SET room_id = ? WHERE device_code = ?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, roomId);
            ps.setString(2, deviceCode.trim());
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }

    public boolean unassignRoom(int roomId) {
        String sql = "UPDATE Device SET room_id = NULL WHERE room_id = ?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, roomId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }

    private Device map(ResultSet rs) throws SQLException {
        Device d = new Device();
        d.setDeviceId(rs.getInt("device_id"));
        d.setDeviceCode(rs.getString("device_code"));
        d.setApiKey(rs.getString("api_key"));
        try {
            d.setNote(rs.getString("note"));
        } catch (SQLException ignored) {}
        d.setLastSeen(rs.getTimestamp("last_seen"));
        d.setIsActive(rs.getBoolean("is_active"));
        d.setRoomId(rs.getObject("room_id") != null ? rs.getInt("room_id") : null);
        return d;
    }

    private void close(ResultSet rs, PreparedStatement ps, Connection cn) {
        try { if (rs != null) rs.close(); } catch (Exception e) {}
        try { if (ps != null) ps.close(); } catch (Exception e) {}
        try { if (cn != null) cn.close(); } catch (Exception e) {}
    }
}
