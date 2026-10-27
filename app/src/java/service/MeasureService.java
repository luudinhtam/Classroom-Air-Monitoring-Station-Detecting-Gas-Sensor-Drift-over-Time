package service;

import dao.AirSessionDAO;
import dao.AlertDAO;
import dao.DeviceCommandDAO;
import dao.DeviceDAO;
import dao.RoomDAO;
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.List;
import model.AirAlert;
import model.AirSession;
import model.Device;
import model.DeviceCommand;
import model.MeasureResult;
import model.Room;
import util.DBContext;

public class MeasureService {

    // Thoi gian het han lenh (giay)
    public static final int PENDING_TIMEOUT_SECONDS = 15;
    public static final int SENT_TIMEOUT_SECONDS = 30;

    // Bien do so do hop ly (Validation Range)
    public static final double TEMP_MIN = -10.0;
    public static final double TEMP_MAX = 80.0;
    public static final double HUMID_MIN = 0.0;
    public static final double HUMID_MAX = 100.0;
    public static final int CO_MIN = 0;
    public static final int CO_MAX = 1000;
    public static final int CO2_MIN = 0;
    public static final int CO2_MAX = 10000;

    private final DeviceCommandDAO commandDAO;
    private final DeviceDAO deviceDAO;
    private final RoomDAO roomDAO;
    private final AirSessionDAO sessionDAO;
    private final AlertDAO alertDAO;

    public MeasureService() {
        this.commandDAO = new DeviceCommandDAO();
        this.deviceDAO = new DeviceDAO();
        this.roomDAO = RoomDAO.getInstance();
        this.sessionDAO = new AirSessionDAO();
        this.alertDAO = new AlertDAO();
    }

    public MeasureService(DeviceCommandDAO commandDAO, DeviceDAO deviceDAO, RoomDAO roomDAO,
                          AirSessionDAO sessionDAO, AlertDAO alertDAO) {
        this.commandDAO = commandDAO;
        this.deviceDAO = deviceDAO;
        this.roomDAO = roomDAO;
        this.sessionDAO = sessionDAO;
        this.alertDAO = alertDAO;
    }

    /**
     * 1. startMeasure(roomId)
     * Khoi tao lenh do thu cong cho mot phong hoc.
     */
    public int startMeasure(int roomId) {
        if (roomId < 0) {
            throw new MeasureException(MeasureException.ErrorCode.NOT_FOUND, "Mã phòng học không hợp lệ: " + roomId);
        }

        // Don dep cac lenh da qua han truoc khi kiem tra
        cleanExpiredCommands();

        // Tim thiet bi hoat dong cua phong
        Device device = deviceDAO.findActiveByRoom(roomId);
        if (device == null) {
            throw new MeasureException(MeasureException.ErrorCode.NO_DEVICE, "Phòng chưa có thiết bị hoạt động");
        }

        // Kiem tra xem thiet bi co dang ban thuc hien lenh do khong
        if (commandDAO.existsActive(device.getDeviceId())) {
            throw new MeasureException(MeasureException.ErrorCode.DEVICE_BUSY, "Thiết bị đang đo, vui lòng chờ");
        }

        // Tao lenh START voi trang thai PENDING
        int commandId = commandDAO.insert(device.getDeviceId(), roomId);
        if (commandId < 0) {
            throw new MeasureException(MeasureException.ErrorCode.SYSTEM_ERROR, "Không thể tạo lệnh đo trên hệ thống");
        }
        return commandId;
    }

    /**
     * Overload: Khoi tao lenh do bang room_code (theo chuan URL dinh danh phong).
     */
    public int startMeasureByRoomCode(String roomCode) {
        if (roomCode == null || roomCode.trim().isEmpty()) {
            throw new MeasureException(MeasureException.ErrorCode.NOT_FOUND, "Mã phòng (room_code) không được rỗng");
        }
        Room r = roomDAO.findByCode(roomCode.trim());
        if (r == null) {
            throw new MeasureException(MeasureException.ErrorCode.NOT_FOUND, "Không tìm thấy phòng với mã: " + roomCode);
        }
        return startMeasure(r.getRoomId());
    }

    /**
     * 2. getCommandForDevice(device)
     * Thiet bi hoi lenh. Neu co lenh PENDING thi chuyen sang SENT va tra ve cho thiet bi.
     */
    public DeviceCommand getCommandForDevice(Device device) {
        if (device == null || !device.isIsActive()) {
            return null;
        }

        // Don dep lenh qua han
        cleanExpiredCommands();

        // Atomically claim lenh PENDING cu nhat thanh SENT
        return commandDAO.claimPendingForDevice(device.getDeviceId());
    }

    /**
     * 3. getStatus(commandId, roomId)
     * Web hoi trang thai lenh moi giay. Tra ve trang thai va ket qua neu da DONE.
     */
    public MeasureResult getStatus(int commandId, int roomId) {
        cleanExpiredCommands();

        DeviceCommand cmd = commandDAO.findById(commandId);
        if (cmd == null || cmd.getRoomId() != roomId) {
            throw new MeasureException(MeasureException.ErrorCode.NOT_FOUND, "Không tìm thấy lệnh đo của phòng này");
        }

        // Neu da hoan thanh, lay day du so do va canh bao tu session
        if ("DONE".equalsIgnoreCase(cmd.getStatus())) {
            MeasureResult res = commandDAO.getMeasurementResult(commandId);
            if (res != null) {
                return res;
            }
        }

        return new MeasureResult(commandId, cmd.getStatus());
    }

    /**
     * Overload: Tra cuu trang thai bang roomCode.
     */
    public MeasureResult getStatusByRoomCode(int commandId, String roomCode) {
        if (roomCode == null || roomCode.trim().isEmpty()) {
            throw new MeasureException(MeasureException.ErrorCode.NOT_FOUND, "Mã phòng không hợp lệ");
        }
        Room r = roomDAO.findByCode(roomCode.trim());
        if (r == null) {
            throw new MeasureException(MeasureException.ErrorCode.NOT_FOUND, "Không tìm thấy phòng: " + roomCode);
        }
        return getStatus(commandId, r.getRoomId());
    }

    /**
     * 4. processDeviceData(device, commandId, temp, humid, co, co2)
     * Thiet bi gui 4 chi so sau khi do xong 5 giay.
     * Chay trong 1 Transaction duy nhat: validate -> so nguong -> luu Session -> luu Alerts -> markDone.
     */
    public MeasureResult processDeviceData(Device device, int commandId,
                                          Double temp, Double humid, Integer co, Integer co2) {
        if (device == null) {
            throw new MeasureException(MeasureException.ErrorCode.INVALID_COMMAND, "Thiết bị không hợp lệ");
        }

        // Validate so do khong null, khong am va nam trong khoang cho phep
        validateMetrics(temp, humid, co, co2);

        Connection conn = null;
        try {
            conn = DBContext.getConnection();
            conn.setAutoCommit(false); // Bat dau Transaction

            // a. Kiem tra tinh hop le cua lenh trong Transaction
            DeviceCommand cmd = commandDAO.findById(commandId);
            if (cmd == null || cmd.getDeviceId() != device.getDeviceId() || !"SENT".equalsIgnoreCase(cmd.getStatus())) {
                throw new MeasureException(MeasureException.ErrorCode.INVALID_COMMAND,
                        "Lệnh không tồn tại, sai thiết bị hoặc không ở trạng thái SENT");
            }

            // Lay thong tin phong va nguong canh bao
            Room room = roomDAO.findById(cmd.getRoomId());
            if (room == null) {
                throw new MeasureException(MeasureException.ErrorCode.NOT_FOUND, "Phòng học của lệnh đo không tồn tại");
            }

            // b. So voi nguong phong hoc de xac dinh cac canh bao can phat sinh
            List<AlertDraft> alertsToCreate = detectThresholdViolations(room, temp, humid, co, co2);

            // c. Luu mot dong Air_Session
            AirSession session = new AirSession();
            session.setDeviceId(device.getDeviceId());
            session.setMeasuredAt(new Timestamp(System.currentTimeMillis()));
            session.setTemperature(temp);
            session.setHumid(humid);
            session.setCo(co);
            session.setCo2(co2);
            session.setNote("Manual measure via Command #" + commandId);

            int sessionId = sessionDAO.insert(session, conn);
            if (sessionId < 0) {
                throw new SQLException("Không thể lưu phiên đo Air_Session");
            }

            // d. Luu cac Air_Alert neu co chi so vuot nguong
            List<AirAlert> createdAlerts = new ArrayList<>();
            for (AlertDraft draft : alertsToCreate) {
                AirAlert alert = alertDAO.insert(sessionId, draft.alertType, draft.message, conn);
                if (alert != null) {
                    createdAlerts.add(alert);
                }
            }

            // e. Doi lenh sang DONE
            boolean marked = commandDAO.markDone(commandId, sessionId, conn);
            if (!marked) {
                throw new MeasureException(MeasureException.ErrorCode.INVALID_COMMAND,
                        "Không thể cập nhật trạng thái lệnh sang DONE (có thể lệnh đã bị timeout)");
            }

            conn.commit(); // Hoan tat Transaction thanh cong

            // f. Tra ve doi tuong ket qua
            MeasureResult result = new MeasureResult(commandId, "DONE");
            result.setSessionId(sessionId);
            result.setMeasuredAt(session.getMeasuredAt());
            result.setTemperature(temp);
            result.setHumid(humid);
            result.setCo(co);
            result.setCo2(co2);
            result.setAlerts(createdAlerts);
            return result;

        } catch (MeasureException me) {
            rollbackQuietly(conn);
            throw me;
        } catch (Exception e) {
            rollbackQuietly(conn);
            e.printStackTrace();
            throw new MeasureException(MeasureException.ErrorCode.SYSTEM_ERROR, "Lỗi hệ thống khi xử lý kết quả đo: " + e.getMessage(), e);
        } finally {
            closeConnection(conn);
        }
    }

    /**
     * Kiem tra tinh hop le cua 4 thong so do.
     */
    private void validateMetrics(Double temp, Double humid, Integer co, Integer co2) {
        if (temp == null || humid == null || co == null || co2 == null) {
            throw new MeasureException(MeasureException.ErrorCode.INVALID_DATA, "Các chỉ số đo không được để trống");
        }
        if (temp < TEMP_MIN || temp > TEMP_MAX) {
            throw new MeasureException(MeasureException.ErrorCode.INVALID_DATA,
                    String.format("Nhiệt độ (%.1f°C) không hợp lệ (cho phép: %.1f..%.1f)", temp, TEMP_MIN, TEMP_MAX));
        }
        if (humid < HUMID_MIN || humid > HUMID_MAX) {
            throw new MeasureException(MeasureException.ErrorCode.INVALID_DATA,
                    String.format("Độ ẩm (%.1f%%) không hợp lệ (cho phép: %.1f..%.1f)", humid, HUMID_MIN, HUMID_MAX));
        }
        if (co < CO_MIN || co > CO_MAX) {
            throw new MeasureException(MeasureException.ErrorCode.INVALID_DATA,
                    String.format("Chỉ số CO (%d ppm) không hợp lệ (cho phép: %d..%d)", co, CO_MIN, CO_MAX));
        }
        if (co2 < CO2_MIN || co2 > CO2_MAX) {
            throw new MeasureException(MeasureException.ErrorCode.INVALID_DATA,
                    String.format("Chỉ số CO2 (%d ppm) không hợp lệ (cho phép: %d..%d)", co2, CO2_MIN, CO2_MAX));
        }
    }

    /**
     * So sanh so do voi nguong cua phong hoc de phat hien vi pham.
     */
    private List<AlertDraft> detectThresholdViolations(Room room, Double temp, Double humid, Integer co, Integer co2) {
        List<AlertDraft> list = new ArrayList<>();
        if (room == null) return list;

        double tempLimit = room.getTempWarningThreshold() > 0 ? room.getTempWarningThreshold() : 32.0;
        double humidLimit = room.getHumidWarningThreshold() > 0 ? room.getHumidWarningThreshold() : 80.0;
        double coLimit = room.getCoWarningThreshold() > 0 ? room.getCoWarningThreshold() : 9.0;
        double co2Limit = room.getCo2WarningThreshold() > 0 ? room.getCo2WarningThreshold() : 1000.0;

        if (temp > tempLimit) {
            list.add(new AlertDraft("TEMPERATURE",
                    String.format("Nhiệt độ đo được %.1f°C vượt ngưỡng an toàn %.1f°C", temp, tempLimit)));
        }
        if (humid > humidLimit) {
            list.add(new AlertDraft("HUMID",
                    String.format("Độ ẩm đo được %.1f%% vượt ngưỡng an toàn %.1f%%", humid, humidLimit)));
        }
        if (co > coLimit) {
            list.add(new AlertDraft("CO",
                    String.format("Nồng độ CO đo được %d ppm vượt ngưỡng an toàn %.1f ppm", co, coLimit)));
        }
        if (co2 > co2Limit) {
            list.add(new AlertDraft("CO2",
                    String.format("Nồng độ CO2 đo được %d ppm vượt ngưỡng an toàn %.1f ppm", co2, co2Limit)));
        }
        return list;
    }

    private void cleanExpiredCommands() {
        try {
            commandDAO.timeoutExpired(PENDING_TIMEOUT_SECONDS, SENT_TIMEOUT_SECONDS);
        } catch (Exception ignored) {
        }
    }

    private void rollbackQuietly(Connection conn) {
        if (conn != null) {
            try {
                conn.rollback();
            } catch (SQLException ignored) {
            }
        }
    }

    private void closeConnection(Connection conn) {
        if (conn != null) {
            try {
                conn.setAutoCommit(true);
                conn.close();
            } catch (SQLException ignored) {
            }
        }
    }

    private static class AlertDraft {
        final String alertType;
        final String message;

        AlertDraft(String alertType, String message) {
            this.alertType = alertType;
            this.message = message;
        }
    }
}
