package dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import model.AppUser;
import util.DBContext;

public class UserDAO {

    private static final String SELECT_BASE =
        "SELECT u.user_id, u.username, u.pass_hash, u.full_name, u.role_id, u.is_locked, u.created_at, " +
        "       r.role_code, r.role_name " +
        "FROM AppUser u " +
        "JOIN AppRole r ON r.role_id = u.role_id ";
    
    
    public List<AppUser> findCalibrationUser() {
        List<AppUser> out = new ArrayList<>();

        Connection cn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            cn = DBContext.getConnection();
            ps = cn.prepareStatement(SELECT_BASE + "WHERE u.role_id IN (1, 2, 3)");
            rs = ps.executeQuery();

            while (rs.next()) {
                out.add(map(rs));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            close(rs, ps, cn);
        }
        return out;
    }
    
    public List<model.AppRole> listRoles() {
        List<model.AppRole> roles = new ArrayList<>();
        Connection cn = null; PreparedStatement ps = null; ResultSet rs = null;
        try {
            cn = DBContext.getConnection();
            ps = cn.prepareStatement("SELECT role_id, role_code, role_name FROM AppRole ORDER BY role_id ");
            rs = ps.executeQuery();
            while (rs.next()) {
                model.AppRole r = new model.AppRole();
                r.setRoleId(rs.getInt("role_id"));
                r.setRoleCode(rs.getString("role_code"));
                r.setRoleName(rs.getString("role_name"));
                roles.add(r);
            }
        } catch (SQLException e) { e.printStackTrace(); }
        finally { close(rs, ps, cn); }
        return roles;
    }

    public AppUser findByUsername(String username) {
        Connection cn = null; PreparedStatement ps = null; ResultSet rs = null;
        try {
            cn = DBContext.getConnection();
            ps = cn.prepareStatement(SELECT_BASE + "WHERE u.username = ?");
            ps.setString(1, username);
            rs = ps.executeQuery();
            if (rs.next()) return map(rs);
        } catch (SQLException e) { e.printStackTrace(); }
        finally { close(rs, ps, cn); }
        return null;
    }
    
    public AppUser findById(int id) {
        Connection cn = null; PreparedStatement ps = null; ResultSet rs = null;
        try {
            cn = DBContext.getConnection();
            ps = cn.prepareStatement(SELECT_BASE + "WHERE u.user_id = ?");
            ps.setInt(1, id);
            rs = ps.executeQuery();
            if (rs.next()) return map(rs);
        } catch (SQLException e) { e.printStackTrace(); }
        finally { close(rs, ps, cn); }
        return null;
    }

    public List<AppUser> search(String keyword, Integer roleId, String lockState, int offset, int limit) {
        List<AppUser> out = new ArrayList<>();
        StringBuilder sql = new StringBuilder(SELECT_BASE).append("WHERE 1 = 1 ");
        
        if (keyword != null && !keyword.trim().isEmpty()) {
            sql.append("AND (u.username LIKE ? OR u.full_name LIKE ?) ");
        }
        if (roleId != null) {
            sql.append("AND u.role_id = ? ");
        }
        if ("LOCKED".equals(lockState)) {
            sql.append("AND u.is_locked = 1 ");
        } else if ("ACTIVE".equals(lockState)) {
            sql.append("AND u.is_locked = 0 ");
        }
        sql.append("ORDER BY u.user_id ASC OFFSET ? ROWS FETCH NEXT ? ROWS ONLY");

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
            if (roleId != null) ps.setInt(i++, roleId);
            ps.setInt(i++, offset);
            ps.setInt(i++, limit);
            rs = ps.executeQuery();
            while (rs.next()) out.add(map(rs));
        } catch (SQLException e) { e.printStackTrace(); }
        finally { close(rs, ps, cn); }
        return out;
    }

    public int count(String keyword, Integer roleId, String lockState) {
        StringBuilder sql = new StringBuilder("SELECT COUNT(*) FROM AppUser u WHERE 1 = 1 ");
        if (keyword != null && !keyword.trim().isEmpty()) {
            sql.append("AND (u.username LIKE ? OR u.full_name LIKE ?) ");
        }
        if (roleId != null) {
            sql.append("AND u.role_id = ? ");
        }
        if ("LOCKED".equals(lockState)) {
            sql.append("AND u.is_locked = 1 ");
        } else if ("ACTIVE".equals(lockState)) {
            sql.append("AND u.is_locked = 0 ");
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
            if (roleId != null) ps.setInt(i++, roleId);
            rs = ps.executeQuery();
            if (rs.next()) return rs.getInt(1);
        } catch (SQLException e) { e.printStackTrace(); }
        finally { close(rs, ps, cn); }
        return 0;
    }

    public boolean insert(AppUser u) {
        String sql = "INSERT INTO AppUser(username, pass_hash, full_name, role_id) VALUES (?, ?, ?, ?)";
        Connection cn = null; PreparedStatement ps = null;
        try {
            cn = DBContext.getConnection();
            ps = cn.prepareStatement(sql);
            ps.setString(1, u.getUsername());
            ps.setString(2, u.getPassHash());
            ps.setString(3, u.getFullName());
            ps.setInt(4, u.getRoleId());
            return ps.executeUpdate() > 0;
        } catch (SQLException e) { e.printStackTrace(); }
        finally { close(null, ps, cn); }
        return false;
    }

    public boolean update(AppUser u) {
        String sql = "UPDATE AppUser SET full_name = ?, role_id = ? WHERE user_id = ?";
        Connection cn = null; PreparedStatement ps = null;
        try {
            cn = DBContext.getConnection();
            ps = cn.prepareStatement(sql);
            ps.setString(1, u.getFullName());
            ps.setInt(2, u.getRoleId());
            ps.setInt(3, u.getUserId());
            return ps.executeUpdate() > 0;
        } catch (SQLException e) { e.printStackTrace(); }
        finally { close(null, ps, cn); }
        return false;
    }

    public boolean lock(int id, boolean locked) {
        String sql = "UPDATE AppUser SET is_locked = ? WHERE user_id = ?";
        Connection cn = null; PreparedStatement ps = null;
        try {
            cn = DBContext.getConnection();
            ps = cn.prepareStatement(sql);
            ps.setBoolean(1, locked);
            ps.setInt(2, id);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) { e.printStackTrace(); }
        finally { close(null, ps, cn); }
        return false;
    }
    
    public boolean resetPassword(int id, String newHash) {
        String sql = "UPDATE AppUser SET pass_hash = ? WHERE user_id = ?";
        Connection cn = null; PreparedStatement ps = null;
        try {
            cn = DBContext.getConnection();
            ps = cn.prepareStatement(sql);
            ps.setString(1, newHash);
            ps.setInt(2, id);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) { e.printStackTrace(); }
        finally { close(null, ps, cn); }
        return false;
    }
    
    public boolean delete(int id) {
        String sql = "DELETE FROM AppUser WHERE user_id = ?";
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

    private AppUser map(ResultSet rs) throws SQLException {
        AppUser u = new AppUser();
        u.setUserId(rs.getInt("user_id"));
        u.setUsername(rs.getString("username"));
        u.setPassHash(rs.getString("pass_hash"));
        u.setFullName(rs.getString("full_name"));
        u.setRoleId(rs.getInt("role_id"));
        u.setLocked(rs.getBoolean("is_locked"));
        u.setCreatedAt(rs.getTimestamp("created_at"));
        u.setRoleCode(rs.getString("role_code"));
        u.setRoleName(rs.getString("role_name"));
        return u;
    }

    private void close(ResultSet rs, PreparedStatement ps, Connection cn) {
        try { if (rs != null) rs.close(); } catch (Exception e) {}
        try { if (ps != null) ps.close(); } catch (Exception e) {}
        try { if (cn != null) cn.close(); } catch (Exception e) {}
    }


    public boolean delete(String user_id) throws SQLException, ClassNotFoundException {
        String sql = "DELETE FROM AppUser WHERE user_id = ?";
        boolean check = false;
        Connection conn = null;
        PreparedStatement ptm = null;
        try {
            conn = DBContext.getConnection();
            if (conn != null) {
                ptm = conn.prepareStatement(sql);
                ptm.setString(1, user_id);
                check = ptm.executeUpdate() > 0;
            }
        } catch (SQLException e) { e.printStackTrace(); }
        finally { close(null, ptm, conn); }
        return check;
    }
}
