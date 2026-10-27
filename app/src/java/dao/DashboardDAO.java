package dao;

import java.sql.*;
import java.util.*;
import model.DashboardStats;
import model.DashboardStats.*;
import util.DBContext;

public class DashboardDAO {

    private static DashboardDAO instance;

    public static synchronized DashboardDAO getInstance() {
        if (instance == null) {
            instance = new DashboardDAO();
        }
        return instance;
    }

    /**
     * Thu thập toàn bộ số liệu thống kê cho Bảng điều khiển (Mục IX).
     * TỐI ƯU HIỆU NĂNG: Tái sử dụng 1 Connection duy nhất cho toàn bộ quá trình nạp.
     */
    public DashboardStats getDashboardStats() {
        DashboardStats stats = new DashboardStats();

        try (Connection cn = DBContext.getConnection()) {
            loadLatestReadings(cn, stats);
            loadGeneralAndDriftMetrics(cn, stats);
            loadAlertMetrics(cn, stats);
            loadOpenAlertsList(cn, stats);
        } catch (SQLException e) {
            e.printStackTrace();
        }

        return stats;
    }

    /**
     * Nạp các giá trị quan trắc tức thời gần nhất từ bảng Air_Session
     */
    private void loadLatestReadings(Connection cn, DashboardStats stats) {
        String sql = "SELECT TOP 1 " +
                     "  co, co2, temperature, humid, measured_at " +
                     "FROM Air_Session " +
                     "ORDER BY measured_at DESC, session_id DESC";

        try (Statement st = cn.createStatement();
             ResultSet rs = st.executeQuery(sql)) {
            if (rs.next()) {
                int co2 = rs.getInt("co2");
                stats.setLatestGasARaw(rs.wasNull() ? 0 : co2);
                int co = rs.getInt("co");
                stats.setLatestGasBRaw(rs.wasNull() ? 0 : co);

                double temp = rs.getDouble("temperature");
                stats.setLatestTempC(rs.wasNull() ? 0.0 : Math.round(temp * 10.0) / 10.0);

                double humid = rs.getDouble("humid");
                stats.setLatestHumidPct(rs.wasNull() ? 0.0 : Math.round(humid * 10.0) / 10.0);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }

    /**
     * 1. Thống kê tổng quan phiên đo, thiết bị, phòng học
     */
    private void loadGeneralAndDriftMetrics(Connection cn, DashboardStats stats) {
        String sql = "SELECT " +
                     "  COUNT(*) AS total_sessions, " +
                     "  AVG(CAST(temperature AS FLOAT)) AS avg_temp, " +
                     "  AVG(CAST(humid AS FLOAT)) AS avg_humid " +
                     "FROM Air_Session";

        try (PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) {
                stats.setTotalSessions(rs.getInt("total_sessions"));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }

        // Đếm thiết bị & phòng
        try (Statement st = cn.createStatement()) {
            String devSql = "SELECT " +
                            "  COUNT(*) AS total_dev, " +
                            "  SUM(CASE WHEN is_active = 1 THEN 1 ELSE 0 END) AS active_dev, " +
                            "  SUM(CASE WHEN is_active = 0 THEN 1 ELSE 0 END) AS inactive_dev " +
                            "FROM Device";
            try (ResultSet rs = st.executeQuery(devSql)) {
                if (rs.next()) {
                    stats.setTotalDevices(rs.getInt("total_dev"));
                    stats.setActiveDevices(rs.getInt("active_dev"));
                    stats.setInactiveDevices(rs.getInt("inactive_dev"));
                }
            }

            try (ResultSet rs = st.executeQuery("SELECT COUNT(*) FROM Room")) {
                if (rs.next()) stats.setTotalRooms(rs.getInt(1));
            }

            try (ResultSet rs = st.executeQuery("SELECT COUNT(*) FROM AppUser")) {
                if (rs.next()) stats.setTotalUsers(rs.getInt(1));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }

        // Đếm cảnh báo đang mở (OPENING hoặc OPEN)
        String alertSql = "SELECT COUNT(*) FROM Air_Alert WHERE status IN ('OPENING', 'OPEN')";
        try (Statement st = cn.createStatement();
             ResultSet rs = st.executeQuery(alertSql)) {
            if (rs.next()) {
                int openCnt = rs.getInt(1);
                stats.setOpenAlerts(openCnt);
                stats.setDriftedCount(openCnt);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }

    /**
     * 2. Phân bố nhãn/cảnh báo
     */
    private void loadLabelDistribution(Connection cn, DashboardStats stats) {
        String sql = "SELECT alert_code, COUNT(*) as cnt FROM Air_Alert GROUP BY alert_code ORDER BY cnt DESC";
        Map<String, Integer> dist = new LinkedHashMap<>();
        try (Statement st = cn.createStatement();
             ResultSet rs = st.executeQuery(sql)) {
            while (rs.next()) {
                dist.put(rs.getString("alert_code"), rs.getInt("cnt"));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        stats.setLabelDistribution(dist);
    }

    /**
     * 3. Thống kê số lần cảnh báo theo loại & trạng thái duyệt
     */
    private void loadAlertMetrics(Connection cn, DashboardStats stats) {
        String sql = "SELECT " +
                     "  COUNT(*) AS total_alerts, " +
                     "  SUM(CASE WHEN status IN ('OPENING', 'OPEN') THEN 1 ELSE 0 END) AS open_alerts, " +
                     "  SUM(CASE WHEN status IN ('APPROVED', 'ACKED') THEN 1 ELSE 0 END) AS acked_alerts, " +
                     "  SUM(CASE WHEN status = 'REJECTED' THEN 1 ELSE 0 END) AS rejected_alerts " +
                     "FROM Air_Alert";

        try (Statement st = cn.createStatement();
             ResultSet rs = st.executeQuery(sql)) {
            if (rs.next()) {
                stats.setTotalAlerts(rs.getInt("total_alerts"));
                stats.setOpenAlerts(rs.getInt("open_alerts"));
                stats.setAckedAlerts(rs.getInt("acked_alerts"));
                stats.setRejectedAlerts(rs.getInt("rejected_alerts"));

                if (stats.getTotalAlerts() > 0) {
                    double rejRate = (stats.getRejectedAlerts() * 100.0) / stats.getTotalAlerts();
                    stats.setAlertRejectionRate(Math.round(rejRate * 100.0) / 100.0);
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }

        // Đếm theo từng loại alert_code
        String typeSql = "SELECT alert_code, COUNT(*) as cnt FROM Air_Alert GROUP BY alert_code ORDER BY cnt DESC";
        Map<String, Integer> byType = new LinkedHashMap<>();
        try (Statement st = cn.createStatement();
             ResultSet rs = st.executeQuery(typeSql)) {
            while (rs.next()) {
                byType.put(rs.getString("alert_code"), rs.getInt("cnt"));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        stats.setAlertsByType(byType);
    }

    /**
     * Nạp danh sách các cảnh báo gần đây nhất từ database
     */
    private void loadOpenAlertsList(Connection cn, DashboardStats stats) {
        String sql = "SELECT TOP 10 " +
                     "  a.alert_id, a.session_id, a.alert_code, a.message, a.status, " +
                     "  CONVERT(VARCHAR(16), a.created_at, 120) AS created_time, " +
                     "  COALESCE(r.room_code, d.device_code, 'Session #' + CAST(a.session_id AS VARCHAR)) AS room_code " +
                     "FROM Air_Alert a " +
                     "LEFT JOIN Air_Session s ON s.session_id = a.session_id " +
                     "LEFT JOIN Device d ON d.device_id = s.device_id " +
                     "LEFT JOIN Room r ON (r.room_id = d.room_id OR (r.device_code IS NOT NULL AND r.device_code = d.device_code)) " +
                     "ORDER BY a.created_at DESC, a.alert_id DESC";

        List<OpenAlertInfo> list = new ArrayList<>();
        try (Statement st = cn.createStatement();
             ResultSet rs = st.executeQuery(sql)) {
            while (rs.next()) {
                String alertCode = rs.getString("alert_code");
                String severity = "WARNING";
                if ("TEMPERATURE".equalsIgnoreCase(alertCode) || "CO".equalsIgnoreCase(alertCode)) {
                    severity = "CRITICAL";
                }
                String stStr = rs.getString("status");
                list.add(new OpenAlertInfo(
                    rs.getInt("alert_id"),
                    rs.getInt("session_id"),
                    alertCode,
                    severity,
                    rs.getString("message"),
                    rs.getString("created_time"),
                    rs.getString("room_code"),
                    stStr != null ? stStr : "OPENING"
                ));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        stats.setOpenAlertsList(list);
    }

    /**
     * Nạp lịch sử đo tức thời từ bảng Air_Session phục vụ vẽ biểu đồ xu hướng thực tế
     */
    public List<java.util.Map<String, Object>> getRecentSessions() {
        List<java.util.Map<String, Object>> list = new ArrayList<>();
        String sql = "SELECT " +
                     "  temperature, humid, co, co2, " +
                     "  SUBSTRING(CONVERT(VARCHAR(16), measured_at, 120), 12, 5) AS time_str " +
                     "FROM Air_Session " +
                     "ORDER BY measured_at ASC, session_id ASC";
        try (Connection cn = util.DBContext.getConnection();
             Statement st = cn.createStatement();
             ResultSet rs = st.executeQuery(sql)) {
            while (rs.next()) {
                java.util.Map<String, Object> m = new java.util.HashMap<>();
                m.put("time", rs.getString("time_str"));
                Object t = rs.getObject("temperature");
                m.put("temp", t != null ? Math.round(rs.getDouble("temperature") * 10.0) / 10.0 : null);
                Object h = rs.getObject("humid");
                m.put("humid", h != null ? Math.round(rs.getDouble("humid") * 10.0) / 10.0 : null);
                Object co2 = rs.getObject("co2");
                m.put("co2", co2 != null ? rs.getInt("co2") : null);
                Object co = rs.getObject("co");
                m.put("co", co != null ? Math.round(rs.getDouble("co") * 10.0) / 10.0 : null);
                list.add(m);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }

    /**
     * Nạp danh sách các phòng học kèm nhiệt độ, độ ẩm mới nhất và lịch sử thực tế từ database
     * phục vụ giao diện Dashboard.
     */
    public List<model.ClassroomTempInfo> getClassroomTempList() {
        List<model.ClassroomTempInfo> list = new ArrayList<>();
        String sql = 
            "SELECT r.room_id, r.room_code, r.name, r.location, r.device_code, " +
            "  r.temp_warning_threshold, r.humid_warning_threshold, r.co_warning_threshold, r.co2_warning_threshold, " +
            "  latest.temperature, latest.humid, latest.co2, latest.co, latest.measured_at " +
            "FROM Room r " +
            "OUTER APPLY ( " +
            "  SELECT TOP 1 s.temperature, s.humid, s.co2, s.co, s.measured_at " +
            "  FROM Air_Session s " +
            "  JOIN Device d ON d.device_id = s.device_id " +
            "  WHERE d.room_id = r.room_id OR (r.device_code IS NOT NULL AND d.device_code = r.device_code) " +
            "  ORDER BY s.measured_at DESC, s.session_id DESC " +
            ") latest " +
            "WHERE (r.is_active = 1 OR r.is_active IS NULL) " +
            "ORDER BY r.room_id ASC";

        try (Connection cn = util.DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                model.ClassroomTempInfo info = new model.ClassroomTempInfo();
                int roomId = rs.getInt("room_id");
                info.setRoomId(roomId);
                info.setRoomCode(rs.getString("room_code"));
                info.setRoomName(rs.getString("name"));
                info.setDeviceCode(rs.getString("device_code"));

                // Phân tích vị trí Tòa nhà và Tầng
                String name = rs.getString("name");
                String building = "Tòa A";
                int floor = 1;

                if (name != null) {
                    if (name.contains("Tòa B") || name.contains("Hội trường B") || name.contains("Sân thượng B") || name.contains("20")) {
                        building = "Tòa B";
                    } else if (name.contains("Tòa C") || name.contains("30")) {
                        building = "Tòa C";
                    }
                    if (name.contains("tầng 2") || name.contains("Tầng 2") || name.contains("20")) {
                        floor = 2;
                    } else if (name.contains("tầng 3") || name.contains("Tầng 3") || name.contains("30")) {
                        floor = 3;
                    }
                }
                info.setBuilding(building);
                info.setFloor(floor);
                info.setLocation(building + " - Tầng " + floor);

                Object tempObj = rs.getObject("temperature");
                if (tempObj == null) {
                    // Phòng chưa có dữ liệu đo từ cảm biến
                    info.setHasData(false);
                    info.setTemperature(null);
                    info.setHumidity(null);
                    info.setCo2(null);
                    info.setCo(null);
                    info.setStatus("NO_DATA");
                    info.setTempHistory(new ArrayList<>());
                } else {
                    info.setHasData(true);
                    double temp = Math.round(rs.getDouble("temperature") * 10.0) / 10.0;
                    info.setTemperature(temp);

                    double humid = Math.round(rs.getDouble("humid") * 10.0) / 10.0;
                    info.setHumidity(humid);

                    int co2 = rs.getInt("co2");
                    info.setCo2(rs.wasNull() ? null : co2);

                    double co = Math.round(rs.getDouble("co") * 10.0) / 10.0;
                    info.setCo(rs.wasNull() ? null : co);

                    // Ngưỡng cảnh báo theo cấu hình phòng
                    double tempThresh = rs.getDouble("temp_warning_threshold");
                    if (tempThresh <= 0) tempThresh = 32.0;

                    double co2Thresh = rs.getDouble("co2_warning_threshold");
                    if (co2Thresh <= 0) co2Thresh = 1000.0;

                    if (temp > tempThresh) {
                        info.setStatus("DANGER");
                    } else if (temp >= 28.0 || (info.getCo2() != null && info.getCo2() > co2Thresh)) {
                        info.setStatus("WARNING");
                    } else {
                        info.setStatus("NORMAL");
                    }

                    // Lịch sử nhiệt độ thực tế
                    List<Double> history = getRoomTempHistory(cn, roomId, info.getDeviceCode());
                    info.setTempHistory(history);
                }

                info.setImageUrl("assets/images/classroom_default.png");
                list.add(info);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }

        return list;
    }

    private List<Double> getRoomTempHistory(Connection cn, int roomId, String deviceCode) {
        List<Double> list = new ArrayList<>();
        String sql = 
            "SELECT TOP 20 s.temperature " +
            "FROM Air_Session s " +
            "JOIN Device d ON d.device_id = s.device_id " +
            "WHERE (d.room_id = ? OR (d.device_code = ? AND ? IS NOT NULL)) " +
            "  AND s.temperature IS NOT NULL " +
            "ORDER BY s.measured_at DESC, s.session_id DESC";

        try (PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, roomId);
            ps.setString(2, deviceCode);
            ps.setString(3, deviceCode);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(Math.round(rs.getDouble(1) * 10.0) / 10.0);
                }
            }
        } catch (SQLException e) {
            // bỏ qua
        }

        // Đảo ngược mảng để theo thứ tự thời gian từ cũ -> mới
        Collections.reverse(list);
        return list;
    }
}

