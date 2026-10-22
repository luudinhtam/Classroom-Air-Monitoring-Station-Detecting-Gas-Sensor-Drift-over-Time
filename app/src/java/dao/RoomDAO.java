package dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;
import java.util.ArrayList;
import java.util.List;
import model.Room;
import util.DBContext;

public class RoomDAO {
    
    private static final RoomDAO INSTANCE = new RoomDAO();
    public static RoomDAO getInstance() {
        return INSTANCE;
    }

    private static final String SELECT_BASE =
        "SELECT r.room_id, r.code, r.name, r.location, " +
        "r.co_warning_threshold, r.co2_warning_threshold, " +
        "r.max_baseline_drift, r.device_code, r.note, " +
        "r.is_active, r.created_at, r.latitude, r.longitude " +
        "FROM Room r ";

    public Room findById(int id) {
        Connection cn = null; PreparedStatement ps = null; ResultSet rs = null;
        try {
            cn = DBContext.getConnection();
            ps = cn.prepareStatement(SELECT_BASE + "WHERE r.room_id = ?");
            ps.setInt(1, id);
            rs = ps.executeQuery();
            if (rs.next()) return map(rs);
        } catch (SQLException e) { e.printStackTrace(); }
        finally { close(rs, ps, cn); }
        return null;
    }

    public List<Room> search(String keyword, String status) {
        List<Room> out = new ArrayList<>();
        StringBuilder sql = new StringBuilder(SELECT_BASE).append("WHERE 1 = 1 ");
        if (keyword != null && !keyword.trim().isEmpty()) {
            sql.append("AND r.name LIKE ? ");
        }
        if ("ACTIVE".equals(status)) {
            sql.append("AND r.is_active = 1 ");
        } else if ("INACTIVE".equals(status)) {
            sql.append("AND r.is_active = 0 ");
        }

        Connection cn = null; PreparedStatement ps = null; ResultSet rs = null;
        try {
            cn = DBContext.getConnection();
            ps = cn.prepareStatement(sql.toString());

            if (keyword != null && !keyword.trim().isEmpty()) {
                ps.setString(1, "%" + keyword.trim() + "%");
            }

            rs = ps.executeQuery();
            while (rs.next()) out.add(map(rs));
        } catch (SQLException e) { e.printStackTrace(); }
        finally { close(rs, ps, cn); }
        return out;
    }

    public List<Room> findAllActive() {
        return search(null, "ACTIVE");
    }

    public int count() {
        StringBuilder sql = new StringBuilder("SELECT COUNT(*) FROM Room");
        Connection cn = null; PreparedStatement ps = null; ResultSet rs = null;
        try {
            cn = DBContext.getConnection();
            ps = cn.prepareStatement(sql.toString());
            rs = ps.executeQuery();
            if (rs.next()) return rs.getInt(1);
        } catch (SQLException e) { e.printStackTrace(); }
        finally { close(rs, ps, cn); }
        return 0;
    }

    public boolean insert(Room r) {
        String sql = "INSERT INTO Room(code, name, location, co_warning_threshold, co2_warning_threshold, max_baseline_drift, device_code, note, latitude, longitude) "
                   + "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
        Connection cn = null; PreparedStatement ps = null;
        try {
            cn = DBContext.getConnection();
            ps = cn.prepareStatement(sql);
            ps.setString(1, r.getCode());
            ps.setString(2, r.getName());
            ps.setString(3, r.getLocation());
            ps.setFloat(4, r.getCoWarningThreshold());
            ps.setFloat(5, r.getCo2WarningThreshold());
            ps.setFloat(6, r.getMaxBaselineDrift());
            ps.setString(7, r.getDeviceCode());
            ps.setString(8, r.getNote());
            if (r.getLatitude() != null) {
                ps.setDouble(9, r.getLatitude());
            } else {
                ps.setNull(9, Types.DECIMAL);
            }
            if (r.getLongitude() != null) {
                ps.setDouble(10, r.getLongitude());
            } else {
                ps.setNull(10, Types.DECIMAL);
            }
            return ps.executeUpdate() > 0;
        } catch (SQLException e) { e.printStackTrace(); }
        finally { close(null, ps, cn); }
        return false;
    }

    public boolean update(Room r) {
        String sql = "UPDATE Room SET "
                + "name = ?, "
                + "location = ?, "
                + "co_warning_threshold = ?, "
                + "co2_warning_threshold = ?, "
                + "max_baseline_drift = ?, "
                + "device_code = ?, "
                + "note = ?, "
                + "latitude = ?, "
                + "longitude = ? "
                + "WHERE room_id = ?";

        Connection cn = null;
        PreparedStatement ps = null;

        try {
            cn = DBContext.getConnection();
            ps = cn.prepareStatement(sql);

            ps.setString(1, r.getName());
            ps.setString(2, r.getLocation());
            ps.setFloat(3, r.getCoWarningThreshold());
            ps.setFloat(4, r.getCo2WarningThreshold());
            ps.setFloat(5, r.getMaxBaselineDrift());
            ps.setString(6, r.getDeviceCode());
            ps.setString(7, r.getNote());
            if (r.getLatitude() != null) {
                ps.setDouble(8, r.getLatitude());
            } else {
                ps.setNull(8, Types.DECIMAL);
            }
            if (r.getLongitude() != null) {
                ps.setDouble(9, r.getLongitude());
            } else {
                ps.setNull(9, Types.DECIMAL);
            }
            ps.setInt(10, r.getRoomId());

            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            close(null, ps, cn);
        }

        return false;
    }

    public boolean updateCoordinates(int roomId, double latitude, double longitude) {
        String sql = "UPDATE Room SET latitude = ?, longitude = ? WHERE room_id = ?";
        Connection cn = null;
        PreparedStatement ps = null;
        try {
            cn = DBContext.getConnection();
            ps = cn.prepareStatement(sql);
            ps.setDouble(1, latitude);
            ps.setDouble(2, longitude);
            ps.setInt(3, roomId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            close(null, ps, cn);
        }
        return false;
    }

    public boolean delete(int id) {
        String sql = "DELETE FROM Room WHERE room_id = ?";
        boolean check = false;
        Connection conn = null;
        PreparedStatement ptm = null;
        try {
            conn = DBContext.getConnection();
            if (conn != null) {
                ptm = conn.prepareStatement(sql);
                ptm.setInt(1, id);
                check = ptm.executeUpdate() > 0;
            }
        } catch (SQLException e) { e.printStackTrace(); }
        finally { close(null, ptm, conn); }
        return check;
    }

    public boolean lock(int id, boolean inactive) {
        String sql = "UPDATE Room SET is_active = ? WHERE room_id = ?";
        Connection cn = null; PreparedStatement ps = null;
        try {
            cn = DBContext.getConnection();
            ps = cn.prepareStatement(sql);
            ps.setBoolean(1, inactive);
            ps.setInt(2, id);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) { e.printStackTrace(); }
        finally { close(null, ps, cn); }
        return false;
    }

    private Room map(ResultSet rs) throws SQLException {
        Double lat = rs.getObject("latitude") != null ? rs.getDouble("latitude") : null;
        Double lng = rs.getObject("longitude") != null ? rs.getDouble("longitude") : null;

        Room r = new Room(
                rs.getInt("room_id"),
                rs.getString("code"),
                rs.getString("name"),
                rs.getString("location"),
                rs.getFloat("co_warning_threshold"),
                rs.getFloat("co2_warning_threshold"),
                rs.getFloat("max_baseline_drift"),
                rs.getString("device_code"),
                rs.getString("note"),
                rs.getBoolean("is_active"),
                rs.getTimestamp("created_at"),
                lat,
                lng
        );

        return r;
    }

    private void close(ResultSet rs, PreparedStatement ps, Connection cn) {
        try { if (rs != null) rs.close(); } catch (Exception e) {}
        try { if (ps != null) ps.close(); } catch (Exception e) {}
        try { if (cn != null) cn.close(); } catch (Exception e) {}
    }
}
