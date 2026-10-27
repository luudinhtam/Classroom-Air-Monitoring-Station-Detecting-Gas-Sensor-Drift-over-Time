package dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
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
        "SELECT r.room_id, r.room_code, r.name, r.location, " +
        "r.temp_warning_threshold, r.humid_warning_threshold, " +
        "r.co_warning_threshold, r.co2_warning_threshold, " +
        "r.device_code, r.note, r.is_active, r.created_at " +
        "FROM Room r ";

    private static final String SELECT_SEARCH =
        "SELECT r.room_id, r.room_code, r.name, r.location, " +
        "r.temp_warning_threshold, r.humid_warning_threshold, " +
        "r.co_warning_threshold, r.co2_warning_threshold, " +
        "r.device_code, r.note, r.is_active, r.created_at, " +
        "d.device_id, d.device_code AS matched_dev_code, d.is_active AS dev_active, d.last_seen AS dev_last_seen, " +
        "latest.temperature, latest.humid, latest.co2, latest.co, latest.measured_at, " +
        "alert_info.open_alerts " +
        "FROM Room r " +
        "OUTER APPLY ( " +
        "    SELECT TOP 1 d.device_id, d.device_code, d.is_active, d.last_seen " +
        "    FROM Device d " +
        "    WHERE d.room_id = r.room_id OR (r.device_code IS NOT NULL AND r.device_code != '' AND r.device_code = d.device_code) " +
        "    ORDER BY d.is_active DESC, d.last_seen DESC, d.device_id DESC " +
        ") d " +
        "OUTER APPLY ( " +
        "    SELECT TOP 1 s.temperature, s.humid, s.co2, s.co, s.measured_at " +
        "    FROM Air_Session s " +
        "    WHERE s.device_id = d.device_id " +
        "    ORDER BY s.measured_at DESC, s.session_id DESC " +
        ") latest " +
        "OUTER APPLY ( " +
        "    SELECT COUNT(*) AS open_alerts " +
        "    FROM Air_Alert a " +
        "    JOIN Air_Session s ON a.session_id = s.session_id " +
        "    JOIN Device dev ON s.device_id = dev.device_id " +
        "    WHERE (dev.room_id = r.room_id OR (r.device_code IS NOT NULL AND r.device_code != '' AND r.device_code = dev.device_code) OR s.device_id = d.device_id) " +
        "      AND a.status IN ('OPENING', 'OPEN') " +
        ") alert_info ";

    public Room findById(int id) {
        Connection cn = null; PreparedStatement ps = null; ResultSet rs = null;
        try {
            cn = DBContext.getConnection();
            ps = cn.prepareStatement(SELECT_SEARCH + "WHERE r.room_id = ?");
            ps.setInt(1, id);
            rs = ps.executeQuery();
            if (rs.next()) {
                Room r = map(rs);
                populateTelemetry(r, rs);
                return r;
            }
        } catch (SQLException e) { e.printStackTrace(); }
        finally { close(rs, ps, cn); }
        return null;
    }

    public List<Room> search(String keyword, String status) {
        List<Room> out = new ArrayList<>();
        StringBuilder sql = new StringBuilder(SELECT_SEARCH).append("WHERE 1 = 1 ");
        if (keyword != null && !keyword.trim().isEmpty()) {
            sql.append("AND (r.name LIKE ? OR r.room_code LIKE ? OR r.location LIKE ?) ");
        }
        if ("ACTIVE".equals(status)) {
            sql.append("AND r.is_active = 1 ");
        } else if ("INACTIVE".equals(status)) {
            sql.append("AND r.is_active = 0 ");
        }
        sql.append("ORDER BY r.room_code ASC, r.room_id ASC");

        Connection cn = null; PreparedStatement ps = null; ResultSet rs = null;
        try {
            cn = DBContext.getConnection();
            ps = cn.prepareStatement(sql.toString());

            if (keyword != null && !keyword.trim().isEmpty()) {
                String kw = "%" + keyword.trim() + "%";
                ps.setString(1, kw);
                ps.setString(2, kw);
                ps.setString(3, kw);
            }

            rs = ps.executeQuery();
            while (rs.next()) {
                Room r = map(rs);
                populateTelemetry(r, rs);
                out.add(r);
            }
        } catch (SQLException e) { e.printStackTrace(); }
        finally { close(rs, ps, cn); }
        return out;
    }

    private void populateTelemetry(Room r, ResultSet rs) throws SQLException {
        Object devIdObj = rs.getObject("device_id");
        if (devIdObj != null) {
            boolean devActive = rs.getBoolean("dev_active");
            Timestamp measuredAt = rs.getTimestamp("measured_at");
            r.setSensorOnline(devActive && measuredAt != null);
            r.setTemp(rs.getObject("temperature") != null ? rs.getDouble("temperature") : null);
            r.setHumidity(rs.getObject("humid") != null ? rs.getDouble("humid") : null);
            r.setCo2(rs.getObject("co2") != null ? rs.getDouble("co2") : null);
            r.setCo(rs.getObject("co") != null ? rs.getDouble("co") : null);
            r.setOpenAlertsCount(rs.getInt("open_alerts"));
            r.setLastMeasuredAt(measuredAt);
            if (r.getDeviceCode() == null || r.getDeviceCode().trim().isEmpty()) {
                String matchedDevCode = rs.getString("matched_dev_code");
                if (matchedDevCode != null && !matchedDevCode.trim().isEmpty()) {
                    r.setDeviceCode(matchedDevCode);
                }
            }
        } else {
            r.setSensorOnline(false);
            r.setOpenAlertsCount(rs.getInt("open_alerts"));
        }
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
        String sql = "INSERT INTO Room(room_code, name, location, temp_warning_threshold, humid_warning_threshold, co_warning_threshold, co2_warning_threshold, device_code, note) "
                   + "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)";
        Connection cn = null; PreparedStatement ps = null; ResultSet rs = null;
        try {
            cn = DBContext.getConnection();
            ps = cn.prepareStatement(sql, java.sql.Statement.RETURN_GENERATED_KEYS);
            ps.setString(1, r.getCode());
            ps.setString(2, r.getName());
            ps.setString(3, r.getLocation());
            ps.setFloat(4, r.getTempWarningThreshold() > 0 ? r.getTempWarningThreshold() : 32.0f);
            ps.setFloat(5, r.getHumidWarningThreshold() > 0 ? r.getHumidWarningThreshold() : 80.0f);
            ps.setFloat(6, r.getCoWarningThreshold() > 0 ? r.getCoWarningThreshold() : 9.0f);
            ps.setFloat(7, r.getCo2WarningThreshold() > 0 ? r.getCo2WarningThreshold() : 1000.0f);
            if (r.getDeviceCode() != null && !r.getDeviceCode().trim().isEmpty()) {
                ps.setString(8, r.getDeviceCode().trim());
            } else {
                ps.setNull(8, Types.VARCHAR);
            }
            ps.setString(9, r.getNote());
            int affected = ps.executeUpdate();
            if (affected > 0) {
                rs = ps.getGeneratedKeys();
                if (rs != null && rs.next()) {
                    r.setRoomId(rs.getInt(1));
                }
                return true;
            }
        } catch (SQLException e) { e.printStackTrace(); }
        finally { close(rs, ps, cn); }
        return false;
    }

    public Room findByCode(String code) {
        Connection cn = null; PreparedStatement ps = null; ResultSet rs = null;
        try {
            cn = DBContext.getConnection();
            ps = cn.prepareStatement(SELECT_SEARCH + "WHERE r.room_code = ?");
            ps.setString(1, code);
            rs = ps.executeQuery();
            if (rs.next()) {
                Room r = map(rs);
                populateTelemetry(r, rs);
                return r;
            }
        } catch (SQLException e) { e.printStackTrace(); }
        finally { close(rs, ps, cn); }
        return null;
    }

    public boolean update(Room r) {
        String sql = "UPDATE Room SET "
                + "name = ?, "
                + "location = ?, "
                + "temp_warning_threshold = ?, "
                + "humid_warning_threshold = ?, "
                + "co_warning_threshold = ?, "
                + "co2_warning_threshold = ?, "
                + "device_code = ?, "
                + "note = ? "
                + "WHERE room_id = ?";

        Connection cn = null;
        PreparedStatement ps = null;

        try {
            cn = DBContext.getConnection();
            ps = cn.prepareStatement(sql);

            ps.setString(1, r.getName());
            ps.setString(2, r.getLocation());
            ps.setFloat(3, r.getTempWarningThreshold() > 0 ? r.getTempWarningThreshold() : 32.0f);
            ps.setFloat(4, r.getHumidWarningThreshold() > 0 ? r.getHumidWarningThreshold() : 80.0f);
            ps.setFloat(5, r.getCoWarningThreshold() > 0 ? r.getCoWarningThreshold() : 9.0f);
            ps.setFloat(6, r.getCo2WarningThreshold() > 0 ? r.getCo2WarningThreshold() : 1000.0f);
            if (r.getDeviceCode() != null && !r.getDeviceCode().trim().isEmpty()) {
                ps.setString(7, r.getDeviceCode().trim());
            } else {
                ps.setNull(7, Types.VARCHAR);
            }
            ps.setString(8, r.getNote());
            ps.setInt(9, r.getRoomId());

            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            close(null, ps, cn);
        }

        return false;
    }

    public boolean updateCoordinates(int roomId, double latitude, double longitude) {
        return true;
    }

    public boolean delete(int id) {
        Connection conn = null;
        PreparedStatement ptm = null;
        try {
            conn = DBContext.getConnection();
            if (conn != null) {
                String unassignSql = "UPDATE Device SET room_id = NULL WHERE room_id = ?";
                try (PreparedStatement uPtm = conn.prepareStatement(unassignSql)) {
                    uPtm.setInt(1, id);
                    uPtm.executeUpdate();
                }
                String sql = "DELETE FROM Room WHERE room_id = ?";
                ptm = conn.prepareStatement(sql);
                ptm.setInt(1, id);
                return ptm.executeUpdate() > 0;
            }
        } catch (SQLException e) { e.printStackTrace(); }
        finally { close(null, ptm, conn); }
        return false;
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
        Room r = new Room();
        r.setRoomId(rs.getInt("room_id"));
        r.setCode(rs.getString("room_code"));
        r.setName(rs.getString("name"));
        r.setLocation(rs.getString("location"));
        r.setTempWarningThreshold(rs.getFloat("temp_warning_threshold"));
        r.setHumidWarningThreshold(rs.getFloat("humid_warning_threshold"));
        r.setCoWarningThreshold(rs.getFloat("co_warning_threshold"));
        r.setCo2WarningThreshold(rs.getFloat("co2_warning_threshold"));
        r.setDeviceCode(rs.getString("device_code"));
        r.setNote(rs.getString("note"));
        r.setActive(rs.getBoolean("is_active"));
        r.setCreatedAt(rs.getTimestamp("created_at"));
        return r;
    }

    private void close(ResultSet rs, PreparedStatement ps, Connection cn) {
        try { if (rs != null) rs.close(); } catch (Exception e) {}
        try { if (ps != null) ps.close(); } catch (Exception e) {}
        try { if (cn != null) cn.close(); } catch (Exception e) {}
    }
}
