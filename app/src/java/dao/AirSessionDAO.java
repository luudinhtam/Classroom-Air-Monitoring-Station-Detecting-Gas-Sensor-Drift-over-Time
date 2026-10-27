package dao;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import model.AirSession;
import util.DBContext;

public class AirSessionDAO {

    private static final String SELECT_BASE = 
        "SELECT s.session_id, s.device_id, s.device_seq, s.measured_at, " +
        "s.co, s.co2, s.temperature, s.humid, s.note, " +
        "d.device_code " +
        "FROM Air_Session s " +
        "LEFT JOIN Device d ON d.device_id = s.device_id ";

    /** READ, one page of rows with optional filters. */
    public List<AirSession> search(String label, String deviceCode, Integer deviceId, int page, int size) {
        List<AirSession> out = new ArrayList<AirSession>();
        StringBuilder sb = new StringBuilder(SELECT_BASE).append("WHERE 1 = 1 ");
        
        if (deviceCode != null && !deviceCode.trim().isEmpty()) {
            sb.append("AND d.device_code = ? ");
        }
        
        if (deviceId != null) sb.append("AND s.device_id = ? ");
        
        sb.append("ORDER BY s.measured_at DESC OFFSET ? ROWS FETCH NEXT ? ROWS ONLY");
        
        Connection cn = null; PreparedStatement ps = null; ResultSet rs = null;
        try {
            cn = DBContext.getConnection();
            ps = cn.prepareStatement(sb.toString());
            int i = 1;
            if (deviceCode != null && !deviceCode.trim().isEmpty()) ps.setString(i++, deviceCode.trim());
            if (deviceId != null) ps.setInt(i++, deviceId.intValue());
            ps.setInt(i++, (page - 1) * size);
            ps.setInt(i++, size);
            rs = ps.executeQuery();
            while (rs.next()) out.add(map(rs));
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            close(rs, ps, cn);
        }
        return out;
    }

    public List<AirSession> search(String label, Integer deviceId, int page, int size) {
        return search(label, null, deviceId, page, size);
    }

    public List<AirSession> search(String label, String deviceCode, int page, int size) {
        return search(label, deviceCode, null, page, size);
    }

    public int count(String label, String deviceCode, Integer deviceId) {
        String sql = "SELECT COUNT(*) FROM Air_Session s LEFT JOIN Device d ON d.device_id = s.device_id WHERE 1 = 1 "
            + (deviceCode != null && !deviceCode.trim().isEmpty() ? "AND d.device_code = ? " : "")
            + (deviceId != null ? "AND s.device_id = ? " : "");
            
        Connection cn = null; PreparedStatement ps = null; ResultSet rs = null;
        try {
            cn = DBContext.getConnection();
            ps = cn.prepareStatement(sql);
            int i = 1;
            if (deviceCode != null && !deviceCode.trim().isEmpty()) ps.setString(i++, deviceCode.trim());
            if (deviceId != null) ps.setInt(i++, deviceId.intValue());
            rs = ps.executeQuery();
            if (rs.next()) return rs.getInt(1);
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            close(rs, ps, cn);
        }
        return 0;
    }

    public int count(String label, Integer deviceId) {
        return count(label, null, deviceId);
    }

    public int count(String label, String deviceCode) {
        return count(label, deviceCode, null);
    }

    public AirSession findById(int id) {
        Connection cn = null; PreparedStatement ps = null; ResultSet rs = null;
        try {
            cn = DBContext.getConnection();
            ps = cn.prepareStatement(SELECT_BASE + "WHERE s.session_id = ?");
            ps.setInt(1, id);
            rs = ps.executeQuery();
            if (rs.next()) return map(rs);
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            close(rs, ps, cn);
        }
        return null;
    }
    
    public List<AirSession> findTimeline(int deviceId, int limit) {
        List<AirSession> list = new ArrayList<>();
        String sql = "SELECT TOP (?) s.session_id, s.device_id, s.device_seq, s.measured_at, "
                   + "s.co, s.co2, s.temperature, s.humid, s.note, "
                   + "d.device_code "
                   + "FROM Air_Session s "
                   + "LEFT JOIN Device d ON d.device_id = s.device_id "
                   + "WHERE s.device_id = ? ORDER BY s.measured_at DESC";
        Connection cn = null; PreparedStatement ps = null; ResultSet rs = null;
        try {
            cn = DBContext.getConnection();
            ps = cn.prepareStatement(sql);
            ps.setInt(1, limit);
            ps.setInt(2, deviceId);
            rs = ps.executeQuery();
            while (rs.next()) {
                list.add(0, map(rs));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            close(rs, ps, cn);
        }
        return list;
        
    }
    public List<model.Device> listDevices() {
        List<model.Device> list = new ArrayList<>();
        String sql = "SELECT device_id, device_code, note FROM Device WHERE is_active = 1 ORDER BY device_code";
        try (java.sql.Connection cn = util.DBContext.getConnection();
             java.sql.PreparedStatement ps = cn.prepareStatement(sql);
             java.sql.ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                model.Device d = new model.Device();
                d.setDeviceId(rs.getInt("device_id"));
                d.setDeviceCode(rs.getString("device_code"));
                d.setNote(rs.getString("note"));
                list.add(d);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    /** CREATE. Returns the new key, or -1 when sequence already exists or insert fails. */
    public int insert(AirSession o) {
        if (o == null) return -1;
        try (Connection cn = util.DBContext.getConnection()) {
            return insert(o, cn);
        } catch (Exception e) {
            e.printStackTrace();
            return -1;
        }
    }

    /**
     * Insert mot Air_Session nhan Connection tu ngoai de chay trong transaction.
     * Tu sinh device_seq = MAX(device_seq)+1 cua thiet bi trong transaction.
     */
    public int insert(AirSession o, Connection cn) throws SQLException {
        if (o == null || cn == null) return -1;

        // Tra cứu device_id nếu chưa có nhưng có deviceCode
        if (o.getDeviceId() <= 0 && o.getDeviceCode() != null && !o.getDeviceCode().trim().isEmpty()) {
            String sqlFindDev = "SELECT device_id FROM Device WHERE device_code = ? AND is_active = 1";
            try (PreparedStatement psDev = cn.prepareStatement(sqlFindDev)) {
                psDev.setString(1, o.getDeviceCode().trim());
                try (ResultSet rsDev = psDev.executeQuery()) {
                    if (rsDev.next()) {
                        o.setDeviceId(rsDev.getInt("device_id"));
                    }
                }
            }
        }

        // Tự động sinh device_seq tiếp theo nếu chưa có hoặc <= 0
        if (o.getDeviceSeq() <= 0 && o.getDeviceId() >= 0) {
            String sqlSeq = "SELECT ISNULL(MAX(device_seq), 0) + 1 FROM Air_Session WHERE device_id = ?";
            try (PreparedStatement psSeq = cn.prepareStatement(sqlSeq)) {
                psSeq.setInt(1, o.getDeviceId());
                try (ResultSet rsSeq = psSeq.executeQuery()) {
                    if (rsSeq.next()) {
                        o.setDeviceSeq(rsSeq.getInt(1));
                    }
                }
            }
        }
        if (o.getDeviceSeq() <= 0) {
            o.setDeviceSeq(1);
        }

        String sqlSession = "INSERT INTO Air_Session(device_id, device_seq, measured_at, co, co2, temperature, humid, note) "
                   + "VALUES (?, ?, COALESCE(?, SYSDATETIME()), ?, ?, ?, ?, ?)";

        try (PreparedStatement ps = cn.prepareStatement(sqlSession, Statement.RETURN_GENERATED_KEYS)) {
            ps.setInt(1, o.getDeviceId());
            ps.setInt(2, o.getDeviceSeq());
            if (o.getMeasuredAt() != null) ps.setTimestamp(3, o.getMeasuredAt()); else ps.setNull(3, Types.TIMESTAMP);
            if (o.getCo() != null) ps.setInt(4, o.getCo()); else ps.setNull(4, Types.INTEGER);
            if (o.getCo2() != null) ps.setInt(5, o.getCo2()); else ps.setNull(5, Types.INTEGER);
            if (o.getTemperature() != null) ps.setDouble(6, o.getTemperature()); else ps.setNull(6, Types.DECIMAL);
            if (o.getHumid() != null) ps.setDouble(7, o.getHumid()); else ps.setNull(7, Types.DECIMAL);
            ps.setString(8, o.getNote());
            ps.executeUpdate();

            try (ResultSet rs = ps.getGeneratedKeys()) {
                if (rs.next()) {
                    int newSessionId = rs.getInt(1);
                    o.setSessionId(newSessionId);
                    return newSessionId;
                }
            }
        }
        return -1;
    }


    /** UPDATE, used by the screens that let a staff member fix a reading. */
    public boolean update(AirSession o) {
        String sqlSession = "UPDATE Air_Session SET device_id = ?, co = ?, co2 = ?, temperature = ?, humid = ?, note = ? WHERE session_id = ?";
        Connection cn = null;
        PreparedStatement psSession = null;
        try {
            cn = DBContext.getConnection();
            psSession = cn.prepareStatement(sqlSession);
            psSession.setInt(1, o.getDeviceId());
            if (o.getCo() != null) psSession.setInt(2, o.getCo()); else psSession.setNull(2, Types.INTEGER);
            if (o.getCo2() != null) psSession.setInt(3, o.getCo2()); else psSession.setNull(3, Types.INTEGER);
            if (o.getTemperature() != null) psSession.setDouble(4, o.getTemperature()); else psSession.setNull(4, Types.DECIMAL);
            if (o.getHumid() != null) psSession.setDouble(5, o.getHumid()); else psSession.setNull(5, Types.DECIMAL);
            psSession.setString(6, o.getNote());
            psSession.setInt(7, o.getSessionId());
            return psSession.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace(); 
            return false;
        } finally {
            close(null, psSession, cn);
        }
    }

    /** DELETE. Children go first because they point back at this row. */
    public boolean delete(int id) {
        Connection cn = null;
        try {
            cn = DBContext.getConnection();
            cn.setAutoCommit(false);
            exec(cn, "DELETE FROM Air_Alert WHERE session_id = ?", id);
            exec(cn, "DELETE FROM Air_Session WHERE session_id = ?", id);
            cn.commit();
            return true;
        } catch (SQLException e) {
            try { if (cn != null) cn.rollback(); } catch (SQLException ignored) { }
            e.printStackTrace();
        } finally {
            try { if (cn != null) cn.close(); } catch (SQLException ignored) { }
        }
        return false;
    }

    private void exec(Connection cn, String sql, int id) throws SQLException {
        PreparedStatement ps = cn.prepareStatement(sql);
        ps.setInt(1, id);
        ps.executeUpdate();
        ps.close();
    }

    private AirSession map(ResultSet rs) throws SQLException {
        AirSession o = new AirSession();
        o.setSessionId(rs.getInt("session_id"));
        o.setDeviceId(rs.getInt("device_id"));
        o.setDeviceSeq(rs.getInt("device_seq"));
        o.setMeasuredAt(rs.getTimestamp("measured_at"));
        
        Double temp = rs.getObject("temperature") != null ? rs.getDouble("temperature") : null;
        Double hum = rs.getObject("humid") != null ? rs.getDouble("humid") : null;
        Integer co2 = rs.getObject("co2") != null ? rs.getInt("co2") : null;
        Integer co = rs.getObject("co") != null ? rs.getInt("co") : null;
        
        o.setTemperature(temp);
        o.setHumid(hum);
        o.setCo2(co2);
        o.setCo(co);
        o.setNote(rs.getString("note"));
        try {
            o.setDeviceCode(rs.getString("device_code"));
        } catch (SQLException ignored) {
        }
        return o;
    }

    private void close(ResultSet rs, PreparedStatement ps, Connection cn) {
        try { if (rs != null) rs.close(); } catch (SQLException ignored) { }
        try { if (ps != null) ps.close(); } catch (SQLException ignored) { }
        try { if (cn != null) cn.close(); } catch (SQLException ignored) { }
    }
}
