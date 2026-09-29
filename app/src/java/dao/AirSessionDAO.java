package dao;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import model.AirSession;
import util.DBContext;

public class AirSessionDAO {

    private static final String SELECT_BASE = 
        "SELECT s.session_id, s.device_id, s.device_seq, s.measured_at, s.ingested_at, " +
        "s.is_sample, s.gas_a_raw, s.gas_b_raw, s.gas_a_base, s.gas_a_delta, s.temp_c, s.humid_pct, s.base_shift, s.warm, " +
        "(SELECT TOP 1 l.label_code FROM Air_Label l " +
        " WHERE l.session_id = s.session_id ORDER BY l.label_id DESC) AS label_code " +
        "FROM Air_Session s ";

    /** READ, one page of rows with optional filters. */
    public List<AirSession> search(String label, Integer deviceId, int page, int size) {
        List<AirSession> out = new ArrayList<AirSession>();
        StringBuilder sb = new StringBuilder(SELECT_BASE).append("WHERE 1 = 1 ");
        
        if (label != null && !label.isEmpty()) {
            sb.append("AND EXISTS (SELECT 1 FROM Air_Label l2 WHERE l2.session_id = s.session_id ")
              .append("AND l2.label_code = ? AND l2.label_id = ")
              .append("(SELECT MAX(l3.label_id) FROM Air_Label l3 WHERE l3.session_id = s.session_id)) ");
        }
        
        if (deviceId != null) sb.append("AND s.device_id = ? ");
        
        sb.append("ORDER BY s.measured_at DESC OFFSET ? ROWS FETCH NEXT ? ROWS ONLY");
        
        Connection cn = null; PreparedStatement ps = null; ResultSet rs = null;
        try {
            cn = DBContext.getConnection();
            ps = cn.prepareStatement(sb.toString());
            int i = 1;
            if (label != null && !label.isEmpty()) ps.setString(i++, label);
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

    public int count(String label, Integer deviceId) {
        String sql = "SELECT COUNT(*) FROM Air_Session s WHERE 1 = 1 "
            + (label != null && !label.isEmpty()
                ? "AND EXISTS (SELECT 1 FROM Air_Label l2 WHERE l2.session_id = s.session_id AND l2.label_code = ?) " : "")
            + (deviceId != null ? "AND s.device_id = ? " : "");
            
        Connection cn = null; PreparedStatement ps = null; ResultSet rs = null;
        try {
            cn = DBContext.getConnection();
            ps = cn.prepareStatement(sql);
            int i = 1;
            if (label != null && !label.isEmpty()) ps.setString(i++, label);
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

    /** CREATE. Returns the new key, or -1 when the sequence number already exists. */
    public int insert(AirSession o) {
        String sql = "INSERT INTO Air_Session(device_id, device_seq, measured_at, gas_a_raw, gas_b_raw, gas_a_base, "
                   + "gas_a_delta, temp_c, humid_pct, base_shift, warm) "
                   + "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
        Connection cn = null; PreparedStatement ps = null; ResultSet rs = null;
        try {
            cn = DBContext.getConnection();
            ps = cn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS);
            ps.setInt(1, o.getDeviceId());
            ps.setInt(2, o.getDeviceSeq());
            ps.setTimestamp(3, o.getMeasuredAt());
            ps.setInt(4, o.getGasARaw());
            ps.setInt(5, o.getGasBRaw());
            ps.setInt(6, o.getGasABase());
            ps.setDouble(7, o.getGasADelta());
            ps.setDouble(8, o.getTempC());
            ps.setDouble(9, o.getHumidPct());
            ps.setDouble(10, o.getBaseShift());
            ps.setBoolean(11, o.isWarm());
            ps.executeUpdate();
            rs = ps.getGeneratedKeys();
            if (rs.next()) return rs.getInt(1);
        } catch (SQLIntegrityConstraintViolationException dup) {
            return -1; // the unique key rejected a resent packet
        } catch (SQLException e) {
            if (e.getMessage() != null && e.getMessage().contains("UQ_Air_Session_seq")) return -1;
            e.printStackTrace();
        } finally {
            close(rs, ps, cn);
        }
        return 0;
    }

    /** UPDATE, used by the screens that let a staff member fix a reading. */
    public boolean update(AirSession o) {
        String sql = "UPDATE Air_Session SET gas_a_raw = ?, gas_b_raw = ?, gas_a_base = ?, gas_a_delta = ?, temp_c = ?, "
                   + "humid_pct = ?, base_shift = ?, warm = ? WHERE session_id = ?";
        Connection cn = null; PreparedStatement ps = null;
        try {
            cn = DBContext.getConnection();
            ps = cn.prepareStatement(sql);
            ps.setInt(1, o.getGasARaw());
            ps.setInt(2, o.getGasBRaw());
            ps.setInt(3, o.getGasABase());
            ps.setDouble(4, o.getGasADelta());
            ps.setDouble(5, o.getTempC());
            ps.setDouble(6, o.getHumidPct());
            ps.setDouble(7, o.getBaseShift());
            ps.setBoolean(8, o.isWarm());
            ps.setInt(9, o.getSessionId());
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            close(null, ps, cn);
        }
        return false;
    }

    /** DELETE. Children go first because they point back at this row. */
    public boolean delete(int id) {
        Connection cn = null;
        try {
            cn = DBContext.getConnection();
            cn.setAutoCommit(false);
            exec(cn, "DELETE FROM Air_Alert WHERE session_id = ?", id);
            exec(cn, "DELETE FROM Air_Label WHERE session_id = ?", id);
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
        o.setIngestedAt(rs.getTimestamp("ingested_at"));
        o.setSample(rs.getBoolean("is_sample"));
        o.setLabelCode(rs.getString("label_code"));
        o.setGasARaw(rs.getInt("gas_a_raw"));
        o.setGasBRaw(rs.getInt("gas_b_raw"));
        o.setGasABase(rs.getInt("gas_a_base"));
        o.setGasADelta(rs.getDouble("gas_a_delta"));
        o.setTempC(rs.getDouble("temp_c"));
        o.setHumidPct(rs.getDouble("humid_pct"));
        o.setBaseShift(rs.getDouble("base_shift"));
        o.setWarm(rs.getBoolean("warm"));
        return o;
    }

    private void close(ResultSet rs, PreparedStatement ps, Connection cn) {
        try { if (rs != null) rs.close(); } catch (SQLException ignored) { }
        try { if (ps != null) ps.close(); } catch (SQLException ignored) { }
        try { if (cn != null) cn.close(); } catch (SQLException ignored) { }
    }
}
