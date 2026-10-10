
package dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import model.Calibration;
import util.DBContext;



public class CalibrationDAO {
    
    private static final String SELECT_BASE =
        "SELECT c.calibration_id, c.code, c.name, " +
        "c.station_id, c.co_baseline, c.co2_baseline, " +
        "c.performed_by, u.username AS performed_by_username, " +
        "c.calibrated_at, c.note " +
        "FROM Air_Calibration c " +
        "JOIN AppUser u ON u.user_id = c.performed_by ";
    
    public Calibration findById(int id) {
        Connection cn = null; PreparedStatement ps = null; ResultSet rs = null;
        try {
            cn = DBContext.getConnection();
            ps = cn.prepareStatement(SELECT_BASE + "WHERE c.calibration_id = ?");
            ps.setInt(1, id);
            rs = ps.executeQuery();
            if (rs.next()) return map(rs);
        } catch (SQLException e) { e.printStackTrace(); }
        finally { close(rs, ps, cn); }
        return null;
    }
    
    public List<Calibration> search(int stationId) {
        
        List<Calibration> out = new ArrayList<>();
        StringBuilder sql = new StringBuilder(SELECT_BASE);
        sql.append("WHERE c.station_id = ? ");
        
        Connection cn = null; PreparedStatement ps = null; ResultSet rs = null;
        try {
            cn = DBContext.getConnection();
            ps = cn.prepareStatement(sql.toString());
            ps.setInt(1, stationId);
            
            rs = ps.executeQuery();
            while (rs.next()) out.add(map(rs));
        } catch (SQLException e) { e.printStackTrace(); }
        finally { close(rs, ps, cn); }
        return out;
    }
    
    public int count(int stationId) {
        
        StringBuilder sql = new StringBuilder("SELECT COUNT(*) FROM Air_Calibration a WHERE a.station_id = ?");
        
        Connection cn = null; PreparedStatement ps = null; ResultSet rs = null;
        try {
            cn = DBContext.getConnection();
            ps = cn.prepareStatement(sql.toString());
            ps.setInt(1, stationId);
            rs = ps.executeQuery();
            if (rs.next()) return rs.getInt(1);
        } catch (SQLException e) { e.printStackTrace(); }
        finally { close(rs, ps, cn); }
        return 0;
    }
    
    
    public boolean insert(Calibration c) {
        String sql = "INSERT INTO Air_Calibration(code, name, note, station_id, performed_by) VALUES (?, ?, ?, ?, ?)";
        Connection cn = null; PreparedStatement ps = null;
        try {
            cn = DBContext.getConnection();
            ps = cn.prepareStatement(sql);
            ps.setString(1, c.getCode());
            ps.setString(2, c.getName());
            ps.setString(3, c.getNote());
            ps.setInt(4, c.getStationId());
            ps.setInt(5, c.getPerformedBy());
            return ps.executeUpdate() > 0;
        } catch (SQLException e) { e.printStackTrace(); }
        finally { close(null, ps, cn); }
        return false;
    }
    
    public boolean update(Calibration c) {
        String sql = "UPDATE Air_Calibration SET " +
                     "name = ?, " +
                     "co_baseline = ?, " +
                     "co2_baseline = ?, " +
                     "performed_by = ?, " +
                     "note = ? " +
                     "WHERE calibration_id = ? " +
                     "AND station_id = ?";

        Connection cn = null;
        PreparedStatement ps = null;

        try {
            cn = DBContext.getConnection();
            ps = cn.prepareStatement(sql);

            ps.setString(1, c.getName());
            ps.setFloat(2, c.getCoBaseLine());
            ps.setFloat(3, c.getCo2BaseLine());
            ps.setInt(4, c.getPerformedBy());
            ps.setString(5, c.getNote());
            ps.setInt(6, c.getCalibrationId());
            ps.setInt(7, c.getStationId());

            return ps.executeUpdate() > 0;

        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            close(null, ps, cn);
        }

        return false;
    }
    
    public boolean delete(int calibrationId, int stationId) {
        String sql = "DELETE FROM Air_Calibration " +
                     "WHERE calibration_id = ? AND station_id = ?";

        Connection cn = null;
        PreparedStatement ps = null;

        try {
            cn = DBContext.getConnection();
            ps = cn.prepareStatement(sql);

            ps.setInt(1, calibrationId);
            ps.setInt(2, stationId);

            return ps.executeUpdate() > 0;

        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        } finally {
            close(null, ps, cn);
        }
    }
    
    
    private Calibration map(ResultSet rs) throws SQLException {
        Calibration c = new Calibration();
        c.setCalibrationId(rs.getInt("calibration_id"));
        c.setCode(rs.getString("code"));
        c.setName(rs.getString("name"));
        c.setStationId(rs.getInt("station_id"));
        c.setCoBaseLine(rs.getFloat("co_baseline"));
        c.setCo2BaseLine(rs.getFloat("co2_baseline"));
        c.setPerformedBy(rs.getInt("performed_by"));
        c.setPerformedByUsername(rs.getString("performed_by_username"));
        c.setCalibratedAt(rs.getTimestamp("calibrated_at"));
        c.setNote(rs.getString("note"));
        return c;
    }
    
    private void close(ResultSet rs, PreparedStatement ps, Connection cn) {
        try { if (rs != null) rs.close(); } catch (Exception e) {}
        try { if (ps != null) ps.close(); } catch (Exception e) {}
        try { if (cn != null) cn.close(); } catch (Exception e) {}
    }
}
