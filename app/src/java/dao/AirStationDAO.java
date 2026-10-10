package dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import model.AirStation;
import util.DBContext;


public class AirStationDAO {
    
    private static final String SELECT_BASE =
        "SELECT a.station_id, a.code, a.name, a.location, " +
        "a.co_warning_threshold, a.co2_warning_threshold, " +
        "a.max_baseline_drift, a.device_key, a.note, " +
        "a.is_active, a.created_at " +
        "FROM Air_Station a ";
    
    
    public AirStation findById(int id) {
        Connection cn = null; PreparedStatement ps = null; ResultSet rs = null;
        try {
            cn = DBContext.getConnection();
            ps = cn.prepareStatement(SELECT_BASE + "WHERE a.station_id = ?");
            ps.setInt(1, id);
            rs = ps.executeQuery();
            if (rs.next()) return map(rs);
        } catch (SQLException e) { e.printStackTrace(); }
        finally { close(rs, ps, cn); }
        return null;
    }
    
    
    public List<AirStation> search(String keyword, String status) {
        
        List<AirStation> out = new ArrayList<>();
        StringBuilder sql = new StringBuilder(SELECT_BASE).append("WHERE 1 = 1 ");
        if (keyword != null && !keyword.trim().isEmpty()) {
            sql.append("AND a.name LIKE ? ");
        }
        if ("ACTIVE".equals(status)) {
            sql.append("AND a.is_active = 1 ");
        } else if ("INACTIVE".equals(status)) {
            sql.append("AND a.is_active = 0 ");
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
    
    public int count() {
        
        StringBuilder sql = new StringBuilder("SELECT COUNT(*) FROM Air_Station");
        
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
    
    public boolean insert(AirStation a) {
        String sql = "INSERT INTO Air_Station(code, name, location, note) VALUES (?, ?, ?, ?)";
        Connection cn = null; PreparedStatement ps = null;
        try {
            cn = DBContext.getConnection();
            ps = cn.prepareStatement(sql);
            ps.setString(1, a.getCode());
            ps.setString(2, a.getName());
            ps.setString(3, a.getLocation());
            ps.setString(4, a.getNote());
            return ps.executeUpdate() > 0;
        } catch (SQLException e) { e.printStackTrace(); }
        finally { close(null, ps, cn); }
        return false;
    }
    
    public boolean update(AirStation a) {

        String sql = "UPDATE Air_Station SET "
                + "name = ?, "
                + "location = ?, "
                + "co_warning_threshold = ?, "
                + "co2_warning_threshold = ?, "
                + "max_baseline_drift = ?, "
                + "device_key = ?, "
                + "note = ? "
                + "WHERE station_id = ?";

        Connection cn = null;
        PreparedStatement ps = null;

        try {
            cn = DBContext.getConnection();
            ps = cn.prepareStatement(sql);

            ps.setString(1, a.getName());
            ps.setString(2, a.getLocation());
            ps.setFloat(3, a.getCoWarningThreshold());
            ps.setFloat(4, a.getCo2WarningThreshold());
            ps.setFloat(5, a.getMaxBaselineDrift());
            ps.setString(6, a.getDeviceKey());
            ps.setString(7, a.getNote());
            ps.setInt(8, a.getStationId());

            return ps.executeUpdate() > 0;

        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            close(null, ps, cn);
        }

        return false;
    }
    
    public boolean delete(int id) {
        
        String sql = "DELETE FROM Air_Station WHERE station_id = ?";
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
        String sql = "UPDATE Air_Station SET is_active = ? WHERE station_id = ?";
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
    
    private AirStation map(ResultSet rs) throws SQLException {
        AirStation a = new AirStation(
                rs.getInt("station_id"),
                rs.getString("code"),
                rs.getString("name"),
                rs.getString("location"),
                rs.getFloat("co_warning_threshold"),
                rs.getFloat("co2_warning_threshold"),
                rs.getFloat("max_baseline_drift"),
                rs.getString("device_key"),
                rs.getString("note"),
                rs.getBoolean("is_active"),
                rs.getTimestamp("created_at")
        );

    return a;
}
    
    private void close(ResultSet rs, PreparedStatement ps, Connection cn) {
        try { if (rs != null) rs.close(); } catch (Exception e) {}
        try { if (ps != null) ps.close(); } catch (Exception e) {}
        try { if (cn != null) cn.close(); } catch (Exception e) {}
    }
}
