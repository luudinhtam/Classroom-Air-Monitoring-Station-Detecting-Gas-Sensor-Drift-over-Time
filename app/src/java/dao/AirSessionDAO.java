package dao;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import model.AirSession;
import util.DBContext;

public class AirSessionDAO {

    private static final String SELECT_BASE = 
        "SELECT s.session_id, s.device_id, s.device_seq, s.measured_at, s.ingested_at, " +
        "s.is_sample, s.gas_a_raw, s.gas_b_raw, s.gas_a_base, s.gas_a_delta, s.temp_c, s.humid_pct, s.base_shift, s.warm, s.note, " +
        "(SELECT TOP 1 l.label_code FROM Air_Label l WHERE l.session_id = s.session_id ORDER BY l.label_id DESC) AS label_code, " +
        "(SELECT d.device_code FROM Device d WHERE d.device_id = s.device_id) AS device_code " + 
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
    
    public List<model.Device> listDevices() {
    List<model.Device> list = new ArrayList<>();
    String sql = "SELECT device_id, device_code, location FROM Device";
    try (java.sql.Connection cn = util.DBContext.getConnection();
         java.sql.PreparedStatement ps = cn.prepareStatement(sql);
         java.sql.ResultSet rs = ps.executeQuery()) {
        while (rs.next()) {
            model.Device d = new model.Device();
            d.setDeviceId(rs.getInt("device_id"));
            d.setDeviceCode(rs.getString("device_code"));
            d.setLocation(rs.getString("location"));
            list.add(d);
        }
    } catch (Exception e) {
        e.printStackTrace();
    }
    return list;
      }
    
    

    /** CREATE. Returns the new key, or -1 when the sequence number already exists. */
    /** CREATE. Returns the new key, or -1 when the sequence number already exists. */
    public int insert(AirSession o) {
        // Đã bổ sung is_sample và note vào lệnh INSERT để đồng bộ với DB
        String sqlSession = "INSERT INTO Air_Session(device_id, device_seq, measured_at, is_sample, gas_a_raw, gas_b_raw, gas_a_base, "
                   + "gas_a_delta, temp_c, humid_pct, base_shift, warm, note) "
                   + "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
                   
        String sqlLabel = "INSERT INTO Air_Label(session_id, label_code) VALUES (?, ?)";

        java.sql.Connection cn = null; 
        java.sql.PreparedStatement ps = null; 
        java.sql.ResultSet rs = null;
        try {
            cn = util.DBContext.getConnection();
            cn.setAutoCommit(false); 
            
            // 1. Insert vào bảng Air_Session
            ps = cn.prepareStatement(sqlSession, java.sql.Statement.RETURN_GENERATED_KEYS);
            ps.setInt(1, o.getDeviceId());
            ps.setInt(2, o.getDeviceSeq()); 
            ps.setTimestamp(3, o.getMeasuredAt());
            ps.setBoolean(4, o.isSample()); 
            ps.setInt(5, o.getGasARaw());
            ps.setInt(6, o.getGasBRaw());
            ps.setInt(7, o.getGasABase());
            ps.setDouble(8, o.getGasADelta());
            ps.setDouble(9, o.getTempC());
            ps.setDouble(10, o.getHumidPct());
            ps.setDouble(11, o.getBaseShift());
            ps.setBoolean(12, o.isWarm());
            ps.setString(13, o.getNote()); 
            ps.executeUpdate();
            
            // Lấy ID vừa được tạo
            rs = ps.getGeneratedKeys();
            int newSessionId = -1;
            if (rs.next()) {
                newSessionId = rs.getInt(1);
            }
            rs.close();
            ps.close();

            // 2. Insert nhãn
            if (newSessionId > 0 && o.getLabelCode() != null && !o.getLabelCode().isEmpty()) {
                ps = cn.prepareStatement(sqlLabel);
                ps.setInt(1, newSessionId);
                ps.setString(2, o.getLabelCode());
                ps.executeUpdate();
                ps.close();
            }

            cn.commit(); 
            return newSessionId;

        } catch (Exception e) {
            try { if (cn != null) cn.rollback(); } catch (Exception ignored) {}
            System.out.println("====== LỖI KHI THÊM MỚI PHIÊN ĐO ======");
            e.printStackTrace();
        } finally {
            // Đóng tài nguyên
            try { if (rs != null) rs.close(); } catch (Exception ignored) {}
            try { if (ps != null) ps.close(); } catch (Exception ignored) {}
            try { if (cn != null) cn.close(); } catch (Exception ignored) {}
        }
        return -1;
    }

    /** UPDATE, used by the screens that let a staff member fix a reading. */
    public boolean update(AirSession o) {
        String sqlSession = "UPDATE Air_Session SET device_id = ?, gas_a_raw = ?, gas_b_raw = ?, gas_a_base = ?, gas_a_delta = ?, temp_c = ?, "
                          + "humid_pct = ?, base_shift = ?, warm = ?, note = ? WHERE session_id = ?";
        
        Connection cn = null; 
        PreparedStatement psSession = null;
        PreparedStatement psLabel = null;
        
        try {
            cn = DBContext.getConnection();
            cn.setAutoCommit(false); 
            
            // --- 1. Cập nhật bảng Phiên đo ---
            psSession = cn.prepareStatement(sqlSession);
            psSession.setInt(1, o.getDeviceId());
            psSession.setInt(2, o.getGasARaw());
            psSession.setInt(3, o.getGasBRaw());
            psSession.setInt(4, o.getGasABase());
            psSession.setDouble(5, o.getGasADelta());
            psSession.setDouble(6, o.getTempC());
            psSession.setDouble(7, o.getHumidPct());
            psSession.setDouble(8, o.getBaseShift());
            psSession.setBoolean(9, o.isWarm());
            psSession.setString(10, o.getNote());
            psSession.setInt(11, o.getSessionId());
            int updated = psSession.executeUpdate();
            
            // --- 2. Cập nhật bảng Nhãn mới (Nếu có đổi) ---
            if (o.getLabelCode() != null && !o.getLabelCode().isEmpty()) {
                String currentLabel = "";
                try (PreparedStatement psCheck = cn.prepareStatement("SELECT TOP 1 label_code FROM Air_Label WHERE session_id = ? ORDER BY label_id DESC")) {
                    psCheck.setInt(1, o.getSessionId());
                    try (ResultSet rs = psCheck.executeQuery()) {
                        if (rs.next()) currentLabel = rs.getString("label_code");
                    }
                }
                
                if (!o.getLabelCode().equals(currentLabel)) {
                    psLabel = cn.prepareStatement("INSERT INTO Air_Label(session_id, label_code) VALUES (?, ?)");
                    psLabel.setInt(1, o.getSessionId());
                    psLabel.setString(2, o.getLabelCode());
                    psLabel.executeUpdate();
                }
            }
            
            cn.commit(); 
            return updated > 0;
            
        } catch (SQLException e) {
            try { if (cn != null) cn.rollback(); } catch (Exception ex) {}
            e.printStackTrace(); // In lỗi ra Output của NetBeans
            return false;
        } finally {
            try { if (psLabel != null) psLabel.close(); } catch (Exception ex) {}
            try { if (psSession != null) psSession.close(); } catch (Exception ex) {}
            try { if (cn != null) cn.close(); } catch (Exception ex) {}
        }
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
        o.setNote(rs.getString("note"));
        o.setDeviceCode(rs.getString("device_code"));
        return o;
    }

    private void close(ResultSet rs, PreparedStatement ps, Connection cn) {
        try { if (rs != null) rs.close(); } catch (SQLException ignored) { }
        try { if (ps != null) ps.close(); } catch (SQLException ignored) { }
        try { if (cn != null) cn.close(); } catch (SQLException ignored) { }
    }
}
