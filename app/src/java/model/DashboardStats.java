package model;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Model chứa toàn bộ dữ liệu thống kê và giám sát tức thời cho Bảng điều khiển (Dashboard)
 * theo đúng quy chuẩn Mục 2 (Trang bảng điều khiển) và Mục IX của đề tài.
 */
public class DashboardStats {

    // 1. Các con số quan trắc tức thời hiện tại (Mục 2 đề tài)
    private int latestGasARaw;
    private int latestGasABase;
    private int latestGasBRaw;
    private int latestGasBBase;
    private double latestTempC;
    private double latestHumidPct;
    private double latestBaseShift;

    // 2. Các con số tổng quan hệ thống
    private int totalSessions;
    private int sampleSessions;
    private int liveSessions;
    private int totalDevices;
    private int activeDevices;
    private int inactiveDevices;
    private int totalRooms;
    private int totalUsers;

    // 3. Mức nền & Độ trôi cảm biến (Mục IX.2)
    private double avgGasABase;
    private double avgBaseShift;
    private double maxBaseShift;
    private int driftedCount;
    private double driftedRate; // %
    private double avgDaysInTolerance; // Thời gian giữ mức nền trong dung sai (ngày)

    // 4. Cảnh báo và tỷ lệ bác bỏ
    private int totalAlerts;
    private int openAlerts;
    private int ackedAlerts;
    private int rejectedAlerts;
    private double alertRejectionRate; // %
    private List<OpenAlertInfo> openAlertsList = new ArrayList<>();

    // 5. Phân bổ theo loại cảnh báo và nhãn
    private Map<String, Integer> alertsByType = new LinkedHashMap<>();
    private Map<String, Integer> labelDistribution = new LinkedHashMap<>();

    // 6. Dữ liệu biểu đồ phân tán (Khí vs Nhiệt độ)
    private List<ScatterPoint> scatterPoints = new ArrayList<>();

    // 7. Dữ liệu biểu đồ xu hướng mức nền theo thời gian
    private List<TrendPoint> trendPoints = new ArrayList<>();

    // 8. Bảng đối chiếu mức trôi (Dữ liệu tự thu vs Dữ liệu nền)
    private DatasetComparison sampleStats = new DatasetComparison();
    private DatasetComparison liveStats = new DatasetComparison();

    // 9. Danh sách theo dõi hiệu chuẩn các phòng
    private List<RoomDriftInfo> roomDrifts = new ArrayList<>();

    // === LỚP CON DTO ===

    public static class OpenAlertInfo {
        private int alertId;
        private int sessionId;
        private String ruleCode;
        private String severity;
        private String message;
        private String createdAt;
        private String roomCode;
        private String status;

        public OpenAlertInfo() {}
        public OpenAlertInfo(int alertId, int sessionId, String ruleCode, String severity, String message, String createdAt) {
            this(alertId, sessionId, ruleCode, severity, message, createdAt, "", "OPENING");
        }
        public OpenAlertInfo(int alertId, int sessionId, String ruleCode, String severity, String message, String createdAt, String roomCode) {
            this(alertId, sessionId, ruleCode, severity, message, createdAt, roomCode, "OPENING");
        }
        public OpenAlertInfo(int alertId, int sessionId, String ruleCode, String severity, String message, String createdAt, String roomCode, String status) {
            this.alertId = alertId;
            this.sessionId = sessionId;
            this.ruleCode = ruleCode;
            this.severity = severity;
            this.message = message;
            this.createdAt = createdAt;
            this.roomCode = roomCode;
            this.status = status;
        }

        public int getAlertId() { return alertId; }
        public void setAlertId(int alertId) { this.alertId = alertId; }
        public int getSessionId() { return sessionId; }
        public void setSessionId(int sessionId) { this.sessionId = sessionId; }
        public String getRuleCode() { return ruleCode; }
        public void setRuleCode(String ruleCode) { this.ruleCode = ruleCode; }
        public String getSeverity() { return severity; }
        public void setSeverity(String severity) { this.severity = severity; }
        public String getMessage() { return message; }
        public void setMessage(String message) { this.message = message; }
        public String getCreatedAt() { return createdAt; }
        public void setCreatedAt(String createdAt) { this.createdAt = createdAt; }
        public String getRoomCode() { return roomCode != null ? roomCode : ""; }
        public void setRoomCode(String roomCode) { this.roomCode = roomCode; }
        public String getStatus() { return status != null ? status : "OPENING"; }
        public void setStatus(String status) { this.status = status; }
    }

    public static class ScatterPoint {
        private double tempC;
        private int gasARaw;
        private double gasADelta;
        private double humidPct;
        private String labelCode;

        public ScatterPoint() {}
        public ScatterPoint(double tempC, int gasARaw, double gasADelta, double humidPct, String labelCode) {
            this.tempC = tempC;
            this.gasARaw = gasARaw;
            this.gasADelta = gasADelta;
            this.humidPct = humidPct;
            this.labelCode = labelCode;
        }

        public double getTempC() { return tempC; }
        public void setTempC(double tempC) { this.tempC = tempC; }
        public int getGasARaw() { return gasARaw; }
        public void setGasARaw(int gasARaw) { this.gasARaw = gasARaw; }
        public double getGasADelta() { return gasADelta; }
        public void setGasADelta(double gasADelta) { this.gasADelta = gasADelta; }
        public double getHumidPct() { return humidPct; }
        public void setHumidPct(double humidPct) { this.humidPct = humidPct; }
        public String getLabelCode() { return labelCode; }
        public void setLabelCode(String labelCode) { this.labelCode = labelCode; }
    }

    public static class TrendPoint {
        private String timeLabel;
        private double gasABase;
        private double baseShift;

        public TrendPoint() {}
        public TrendPoint(String timeLabel, double gasABase, double baseShift) {
            this.timeLabel = timeLabel;
            this.gasABase = gasABase;
            this.baseShift = baseShift;
        }

        public String getTimeLabel() { return timeLabel; }
        public void setTimeLabel(String timeLabel) { this.timeLabel = timeLabel; }
        public double getGasABase() { return gasABase; }
        public void setGasABase(double gasABase) { this.gasABase = gasABase; }
        public double getBaseShift() { return baseShift; }
        public void setBaseShift(double baseShift) { this.baseShift = baseShift; }
    }

    public static class DatasetComparison {
        private String datasetName;
        private int recordCount;
        private double avgGasARaw;
        private double avgGasABase;
        private double avgBaseShift;
        private double maxBaseShift;
        private double avgTemp;
        private double avgHumid;
        private int driftCount;
        private double driftRate;
        private String conclusion;

        public String getDatasetName() { return datasetName; }
        public void setDatasetName(String datasetName) { this.datasetName = datasetName; }
        public int getRecordCount() { return recordCount; }
        public void setRecordCount(int recordCount) { this.recordCount = recordCount; }
        public double getAvgGasARaw() { return avgGasARaw; }
        public void setAvgGasARaw(double avgGasARaw) { this.avgGasARaw = avgGasARaw; }
        public double getAvgGasABase() { return avgGasABase; }
        public void setAvgGasABase(double avgGasABase) { this.avgGasABase = avgGasABase; }
        public double getAvgBaseShift() { return avgBaseShift; }
        public void setAvgBaseShift(double avgBaseShift) { this.avgBaseShift = avgBaseShift; }
        public double getMaxBaseShift() { return maxBaseShift; }
        public void setMaxBaseShift(double maxBaseShift) { this.maxBaseShift = maxBaseShift; }
        public double getAvgTemp() { return avgTemp; }
        public void setAvgTemp(double avgTemp) { this.avgTemp = avgTemp; }
        public double getAvgHumid() { return avgHumid; }
        public void setAvgHumid(double avgHumid) { this.avgHumid = avgHumid; }
        public int getDriftCount() { return driftCount; }
        public void setDriftCount(int driftCount) { this.driftCount = driftCount; }
        public double getDriftRate() { return driftRate; }
        public void setDriftRate(double driftRate) { this.driftRate = driftRate; }
        public String getConclusion() { return conclusion; }
        public void setConclusion(String conclusion) { this.conclusion = conclusion; }
    }

    public static class RoomDriftInfo {
        private String roomCode;
        private String roomName;
        private String lastCalibratedAt;
        private double coBaseline;
        private double toleranceDrift;
        private double currentShift;
        private double daysInTolerance;
        private String status;

        public String getRoomCode() { return roomCode; }
        public void setRoomCode(String roomCode) { this.roomCode = roomCode; }
        public String getRoomName() { return roomName; }
        public void setRoomName(String roomName) { this.roomName = roomName; }
        public String getLastCalibratedAt() { return lastCalibratedAt; }
        public void setLastCalibratedAt(String lastCalibratedAt) { this.lastCalibratedAt = lastCalibratedAt; }
        public double getCoBaseline() { return coBaseline; }
        public void setCoBaseline(double coBaseline) { this.coBaseline = coBaseline; }
        public double getToleranceDrift() { return toleranceDrift; }
        public void setToleranceDrift(double toleranceDrift) { this.toleranceDrift = toleranceDrift; }
        public double getCurrentShift() { return currentShift; }
        public void setCurrentShift(double currentShift) { this.currentShift = currentShift; }
        public double getDaysInTolerance() { return daysInTolerance; }
        public void setDaysInTolerance(double daysInTolerance) { this.daysInTolerance = daysInTolerance; }
        public String getStatus() { return status; }
        public void setStatus(String status) { this.status = status; }

        // Aliases for compatibility
        public String getStationCode() { return roomCode; }
        public void setStationCode(String code) { this.roomCode = code; }
        public String getStationName() { return roomName; }
        public void setStationName(String name) { this.roomName = name; }
    }

    public static class StationDriftInfo extends RoomDriftInfo {
    }

    // === GETTERS / SETTERS ===

    public int getLatestGasARaw() { return latestGasARaw; }
    public void setLatestGasARaw(int latestGasARaw) { this.latestGasARaw = latestGasARaw; }
    public int getLatestGasABase() { return latestGasABase; }
    public void setLatestGasABase(int latestGasABase) { this.latestGasABase = latestGasABase; }
    public int getLatestGasBRaw() { return latestGasBRaw; }
    public void setLatestGasBRaw(int latestGasBRaw) { this.latestGasBRaw = latestGasBRaw; }
    public int getLatestGasBBase() { return latestGasBBase; }
    public void setLatestGasBBase(int latestGasBBase) { this.latestGasBBase = latestGasBBase; }
    public double getLatestTempC() { return latestTempC; }
    public void setLatestTempC(double latestTempC) { this.latestTempC = latestTempC; }
    public double getLatestHumidPct() { return latestHumidPct; }
    public void setLatestHumidPct(double latestHumidPct) { this.latestHumidPct = latestHumidPct; }
    public double getLatestBaseShift() { return latestBaseShift; }
    public void setLatestBaseShift(double latestBaseShift) { this.latestBaseShift = latestBaseShift; }

    public int getTotalSessions() { return totalSessions; }
    public void setTotalSessions(int totalSessions) { this.totalSessions = totalSessions; }
    public int getSampleSessions() { return sampleSessions; }
    public void setSampleSessions(int sampleSessions) { this.sampleSessions = sampleSessions; }
    public int getLiveSessions() { return liveSessions; }
    public void setLiveSessions(int liveSessions) { this.liveSessions = liveSessions; }
    public int getTotalDevices() { return totalDevices; }
    public void setTotalDevices(int totalDevices) { this.totalDevices = totalDevices; }
    public int getActiveDevices() { return activeDevices; }
    public void setActiveDevices(int activeDevices) { this.activeDevices = activeDevices; }
    public int getInactiveDevices() { return inactiveDevices; }
    public void setInactiveDevices(int inactiveDevices) { this.inactiveDevices = inactiveDevices; }
    public int getTotalRooms() { return totalRooms; }
    public void setTotalRooms(int totalRooms) { this.totalRooms = totalRooms; }
    public int getTotalStations() { return totalRooms; }
    public void setTotalStations(int totalStations) { this.totalRooms = totalStations; }
    public int getTotalUsers() { return totalUsers; }
    public void setTotalUsers(int totalUsers) { this.totalUsers = totalUsers; }

    public double getAvgGasABase() { return avgGasABase; }
    public void setAvgGasABase(double avgGasABase) { this.avgGasABase = avgGasABase; }
    public double getAvgBaseShift() { return avgBaseShift; }
    public void setAvgBaseShift(double avgBaseShift) { this.avgBaseShift = avgBaseShift; }
    public double getMaxBaseShift() { return maxBaseShift; }
    public void setMaxBaseShift(double maxBaseShift) { this.maxBaseShift = maxBaseShift; }
    public int getDriftedCount() { return driftedCount; }
    public void setDriftedCount(int driftedCount) { this.driftedCount = driftedCount; }
    public double getDriftedRate() { return driftedRate; }
    public void setDriftedRate(double driftedRate) { this.driftedRate = driftedRate; }
    public double getAvgDaysInTolerance() { return avgDaysInTolerance; }
    public void setAvgDaysInTolerance(double avgDaysInTolerance) { this.avgDaysInTolerance = avgDaysInTolerance; }

    public int getTotalAlerts() { return totalAlerts; }
    public void setTotalAlerts(int totalAlerts) { this.totalAlerts = totalAlerts; }
    public int getOpenAlerts() { return openAlerts; }
    public void setOpenAlerts(int openAlerts) { this.openAlerts = openAlerts; }
    public int getAckedAlerts() { return ackedAlerts; }
    public void setAckedAlerts(int ackedAlerts) { this.ackedAlerts = ackedAlerts; }
    public int getRejectedAlerts() { return rejectedAlerts; }
    public void setRejectedAlerts(int rejectedAlerts) { this.rejectedAlerts = rejectedAlerts; }
    public double getAlertRejectionRate() { return alertRejectionRate; }
    public void setAlertRejectionRate(double alertRejectionRate) { this.alertRejectionRate = alertRejectionRate; }

    public List<OpenAlertInfo> getOpenAlertsList() { return openAlertsList; }
    public void setOpenAlertsList(List<OpenAlertInfo> openAlertsList) { this.openAlertsList = openAlertsList; }

    public Map<String, Integer> getAlertsByType() { return alertsByType; }
    public void setAlertsByType(Map<String, Integer> alertsByType) { this.alertsByType = alertsByType; }
    public Map<String, Integer> getLabelDistribution() { return labelDistribution; }
    public void setLabelDistribution(Map<String, Integer> labelDistribution) { this.labelDistribution = labelDistribution; }

    public List<ScatterPoint> getScatterPoints() { return scatterPoints; }
    public void setScatterPoints(List<ScatterPoint> scatterPoints) { this.scatterPoints = scatterPoints; }
    public List<TrendPoint> getTrendPoints() { return trendPoints; }
    public void setTrendPoints(List<TrendPoint> trendPoints) { this.trendPoints = trendPoints; }

    public DatasetComparison getSampleStats() { return sampleStats; }
    public void setSampleStats(DatasetComparison sampleStats) { this.sampleStats = sampleStats; }
    public DatasetComparison getLiveStats() { return liveStats; }
    public void setLiveStats(DatasetComparison liveStats) { this.liveStats = liveStats; }

    public List<RoomDriftInfo> getRoomDrifts() { return roomDrifts; }
    public void setRoomDrifts(List<RoomDriftInfo> roomDrifts) { this.roomDrifts = roomDrifts; }
    public List<RoomDriftInfo> getStationDrifts() { return roomDrifts; }
    public void setStationDrifts(List<RoomDriftInfo> drifts) { this.roomDrifts = drifts; }
}
