package dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;
import model.AirAlert;
import model.DeviceCommand;
import model.MeasureResult;
import util.DBContext;

public class DeviceCommandDAO {

    private static final String SELECT_BASE =
        "SELECT command_id, device_id, room_id, command, status, created_at, sent_at, done_at, session_id " +
        "FROM Device_Command ";

    /**
     * Tao mot lenh START trang thai PENDING cho thiet bi o phong chi dinh.
     * Tra ve commandId vua sinh.
     */
    public int insert(int deviceId, int roomId) {
        String sql = "INSERT INTO Device_Command(device_id, room_id, command, status, created_at) " +
                     "VALUES (?, ?, 'START', 'PENDING', SYSDATETIME())";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setInt(1, deviceId);
            ps.setInt(2, roomId);
            ps.executeUpdate();
            try (ResultSet rs = ps.getGeneratedKeys()) {
                if (rs.next()) {
                    return rs.getInt(1);
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return -1;
    }

    /**
     * Tim lenh theo commandId.
     */
    public DeviceCommand findById(int commandId) {
        String sql = SELECT_BASE + "WHERE command_id = ?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, commandId);
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

    /**
     * Kiem tra thiet bi co lenh nao dang hoat dong (PENDING hoac SENT) khong.
     */
    public boolean existsActive(int deviceId) {
        String sql = "SELECT COUNT(1) FROM Device_Command WHERE device_id = ? AND status IN ('PENDING', 'SENT')";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, deviceId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt(1) > 0;
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }

    /**
     * Tim lenh PENDING cu nhat cua thiet bi va chuyen thanh SENT (ghi sent_at = SYSDATETIME()).
     * Su dung 1 cau UPDATE atomic kem OUTPUT de tranh race condition giua 2 lan polling cung luc.
     */
    public DeviceCommand claimPendingForDevice(int deviceId) {
        String sql = 
            "WITH NextCmd AS ( " +
            "    SELECT TOP 1 command_id, device_id, room_id, command, status, created_at, sent_at, done_at, session_id " +
            "    FROM Device_Command " +
            "    WHERE device_id = ? AND status = 'PENDING' " +
            "    ORDER BY created_at ASC, command_id ASC " +
            ") " +
            "UPDATE NextCmd " +
            "SET status = 'SENT', sent_at = SYSDATETIME() " +
            "OUTPUT INSERTED.command_id, INSERTED.device_id, INSERTED.room_id, INSERTED.command, " +
            "       INSERTED.status, INSERTED.created_at, INSERTED.sent_at, INSERTED.done_at, INSERTED.session_id";

        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, deviceId);
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

    /**
     * Cap nhat lenh tu SENT sang DONE, ghi done_at va session_id.
     * Nhan Connection tu ngoai de chay trong transaction cua service.
     */
    public boolean markDone(int commandId, int sessionId, Connection connection) throws SQLException {
        String sql = "UPDATE Device_Command SET status = 'DONE', done_at = SYSDATETIME(), session_id = ? " +
                     "WHERE command_id = ? AND status = 'SENT'";
        try (PreparedStatement ps = connection.prepareStatement(sql)) {
            ps.setInt(1, sessionId);
            ps.setInt(2, commandId);
            return ps.executeUpdate() > 0;
        }
    }

    /**
     * Chuyen sang TIMEOUT cac lenh qua han (PENDING qua pendingSeconds, SENT qua sentSeconds).
     * Tra ve so dong da doi trang thai.
     */
    public int timeoutExpired(int pendingSeconds, int sentSeconds) {
        String sql = 
            "UPDATE Device_Command " +
            "SET status = 'TIMEOUT' " +
            "WHERE (status = 'PENDING' AND DATEDIFF(SECOND, created_at, SYSDATETIME()) > ?) " +
            "   OR (status = 'SENT' AND DATEDIFF(SECOND, sent_at, SYSDATETIME()) > ?)";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, pendingSeconds);
            ps.setInt(2, sentSeconds);
            return ps.executeUpdate();
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return 0;
    }

    /**
     * Lay ket qua do cua mot lenh da DONE dua tren session_id:
     * tra ve 4 chi so, thoi diem do va danh sach canh bao phat sinh tu session do.
     */
    public MeasureResult getMeasurementResult(int commandId) {
        String sql = 
            "SELECT c.command_id, c.status, c.session_id, " +
            "       s.measured_at, s.temperature, s.humid, s.co, s.co2 " +
            "FROM Device_Command c " +
            "LEFT JOIN Air_Session s ON s.session_id = c.session_id " +
            "WHERE c.command_id = ?";

        MeasureResult res = null;
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, commandId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    res = new MeasureResult();
                    res.setCommandId(rs.getInt("command_id"));
                    res.setStatus(rs.getString("status"));
                    int sessId = rs.getInt("session_id");
                    if (!rs.wasNull()) {
                        res.setSessionId(sessId);
                        res.setMeasuredAt(rs.getTimestamp("measured_at"));
                        double temp = rs.getDouble("temperature");
                        if (!rs.wasNull()) res.setTemperature(temp);
                        double humid = rs.getDouble("humid");
                        if (!rs.wasNull()) res.setHumid(humid);
                        int co = rs.getInt("co");
                        if (!rs.wasNull()) res.setCo(co);
                        int co2 = rs.getInt("co2");
                        if (!rs.wasNull()) res.setCo2(co2);
                    }
                }
            }

            // Neu co sessionId thi lay danh sach Air_Alert phat sinh tu session do
            if (res != null && res.getSessionId() != null && res.getSessionId() >= 0) {
                String sqlAlerts = 
                    "SELECT alert_id, session_id, alert_code, alert_type, message, status, created_at " +
                    "FROM Air_Alert WHERE session_id = ? ORDER BY alert_id ASC";
                try (PreparedStatement psAlert = cn.prepareStatement(sqlAlerts)) {
                    psAlert.setInt(1, res.getSessionId());
                    try (ResultSet rsAlert = psAlert.executeQuery()) {
                        List<AirAlert> alertList = new ArrayList<>();
                        while (rsAlert.next()) {
                            AirAlert a = new AirAlert();
                            a.setAlertId(rsAlert.getInt("alert_id"));
                            a.setSessionId(rsAlert.getInt("session_id"));
                            a.setAlertCode(rsAlert.getString("alert_code"));
                            a.setAlertType(rsAlert.getString("alert_type"));
                            a.setMessage(rsAlert.getString("message"));
                            a.setStatus(rsAlert.getString("status"));
                            a.setCreatedAt(rsAlert.getTimestamp("created_at"));
                            alertList.add(a);
                        }
                        res.setAlerts(alertList);
                    }
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return res;
    }

    private DeviceCommand map(ResultSet rs) throws SQLException {
        DeviceCommand cmd = new DeviceCommand();
        cmd.setCommandId(rs.getInt("command_id"));
        cmd.setDeviceId(rs.getInt("device_id"));
        cmd.setRoomId(rs.getInt("room_id"));
        cmd.setCommand(rs.getString("command"));
        cmd.setStatus(rs.getString("status"));
        cmd.setCreatedAt(rs.getTimestamp("created_at"));
        cmd.setSentAt(rs.getTimestamp("sent_at"));
        cmd.setDoneAt(rs.getTimestamp("done_at"));
        int sid = rs.getInt("session_id");
        if (!rs.wasNull()) {
            cmd.setSessionId(sid);
        }
        return cmd;
    }
}
