
package dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.List;
import model.EmptyWindow;
import util.DBContext;


public class EmptyWindowDAO {
    
    private static final String SELECT_BASE =
        "SELECT e.empty_window_id, e.code, e.name, " +
        "e.station_id, e.start_at, e.end_at, " +
        "e.marked_by, u.username, e.note, e.created_at " +
        "FROM Air_EmptyWindow e " +
        "JOIN AppUser u ON e.marked_by = u.user_id ";
    
    public EmptyWindow findById(int emptyWindowId) {
        String sql = SELECT_BASE + "WHERE e.empty_window_id = ?";

        Connection cn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            cn = DBContext.getConnection();
            ps = cn.prepareStatement(sql);
            ps.setInt(1, emptyWindowId);
            rs = ps.executeQuery();
            if (rs.next()) {
                return map(rs);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            close(rs, ps, cn);
        }
        return null;
    }
    
    
    public List<EmptyWindow> search(int stationId) {
        List<EmptyWindow> list = new ArrayList<>();

        String sql = SELECT_BASE
                + "WHERE e.station_id = ? "
                + "ORDER BY e.start_at DESC";

        Connection cn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            cn = DBContext.getConnection();
            ps = cn.prepareStatement(sql);

            ps.setInt(1, stationId);

            rs = ps.executeQuery();

            while (rs.next()) {
                list.add(map(rs));
            }

        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            close(rs, ps, cn);
        }

        return list;
    }
    
    public int count(int stationId) {
        
        StringBuilder sql = new StringBuilder("SELECT COUNT(*) FROM Air_EmptyWindow e WHERE e.station_id = ?");
        
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
    
    public boolean insert(EmptyWindow ew) {
        String sql = "INSERT INTO Air_EmptyWindow "
                + "(code, name, station_id, start_at, end_at, marked_by, note) "
                + "VALUES (?, ?, ?, ?, ?, ?, ?)";

        Connection cn = null;
        PreparedStatement ps = null;

        try {
            cn = DBContext.getConnection();
            ps = cn.prepareStatement(sql);

            ps.setString(1, ew.getCode());
            ps.setString(2, ew.getName());
            ps.setInt(3, ew.getStationId());
            ps.setTimestamp(4, Timestamp.valueOf(ew.getStartAt()));
            ps.setTimestamp(5, Timestamp.valueOf(ew.getEndAt()));
            ps.setInt(6, ew.getMarkedBy());
            ps.setString(7, ew.getNote());

            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        } finally {
            close(null, ps, cn);
        }
    }
    
    public boolean update(EmptyWindow ew) {
        String sql = "UPDATE Air_EmptyWindow SET "
                + "code = ?, "
                + "name = ?, "
                + "start_at = ?, "
                + "end_at = ?, "
                + "marked_by = ?, "
                + "note = ? "
                + "WHERE empty_window_id = ? "
                + "AND station_id = ?";

        Connection cn = null;
        PreparedStatement ps = null;

        try {
            cn = DBContext.getConnection();
            ps = cn.prepareStatement(sql);

            ps.setString(1, ew.getCode());
            ps.setString(2, ew.getName());
            ps.setTimestamp(3, Timestamp.valueOf(ew.getStartAt()));
            ps.setTimestamp(4, Timestamp.valueOf(ew.getEndAt()));
            ps.setInt(5, ew.getMarkedBy());
            ps.setString(6, ew.getNote());
            ps.setInt(7, ew.getEmptyWindowId());
            ps.setInt(8, ew.getStationId());

            return ps.executeUpdate() > 0;

        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        } finally {
            close(null, ps, cn);
        }
    }
    
    private EmptyWindow map(ResultSet rs) throws SQLException {

        EmptyWindow ew = new EmptyWindow();

        ew.setEmptyWindowId(rs.getInt("empty_window_id"));
        ew.setCode(rs.getString("code"));
        ew.setName(rs.getString("name"));
        ew.setStationId(rs.getInt("station_id"));
        ew.setStartAt(rs.getTimestamp("start_at").toLocalDateTime());
        ew.setEndAt(rs.getTimestamp("end_at").toLocalDateTime());
        ew.setMarkedBy(rs.getInt("marked_by"));
        ew.setMarkedByUsername(rs.getString("username"));
        ew.setNote(rs.getString("note"));
        ew.setCreatedAt(rs.getTimestamp("created_at").toLocalDateTime());

        return ew;
    }
    
    private void close(ResultSet rs, PreparedStatement ps, Connection cn) {
        try { if (rs != null) rs.close(); } catch (Exception e) {}
        try { if (ps != null) ps.close(); } catch (Exception e) {}
        try { if (cn != null) cn.close(); } catch (Exception e) {}
    }
    
}
