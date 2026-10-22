package controller;

import dao.CalibrationDAO;
import dao.EmptyWindowDAO;
import java.io.IOException;
import java.time.Duration;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.ThreadLocalRandom;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import model.AppUser;
import model.Calibration;
import model.EmptyWindow;
import util.Web;

@WebServlet(name = "BaseLineServlet",
        urlPatterns = {"/admin/emptyWindows/baseline"})
public class BaseLineServlet extends HttpServlet {

    private final EmptyWindowDAO emptyWindows = new EmptyWindowDAO();
    private final CalibrationDAO calibrations = new CalibrationDAO();

    private static final int MAX_SAMPLES = 1440;
    private static final String PREVIEW_KEY = "baselinePreview";

    private int getRoomParam(HttpServletRequest request) {
        int id = Web.intParam(request, "roomId", 0);
        if (id <= 0) {
            id = Web.intParam(request, "stationId", 0);
        }
        return id;
    }

    @Override
    protected void doGet(HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        int roomId = getRoomParam(request);
        int emptyWindowId = Web.intParam(request, "emptyWindowId", 0);

        if (roomId <= 0 || emptyWindowId <= 0) {
            Web.flash(request,
                    "Thông tin phòng hoặc khoảng phòng trống không hợp lệ");
            response.sendRedirect(
                    request.getContextPath() + "/admin/rooms");
            return;
        }

        EmptyWindow ew = emptyWindows.findById(emptyWindowId);

        if (ew == null || ew.getRoomId() != roomId) {
            Web.flash(request, "Khoảng phòng trống không hợp lệ");
            response.sendRedirect(request.getContextPath()
                    + "/admin/emptyWindows?roomId=" + roomId);
            return;
        }

        LocalDateTime startAt = ew.getStartAt();
        LocalDateTime endAt = ew.getEndAt();

        // Kiểm tra thời gian kết thúc phải sau thời gian bắt đầu.
        if (startAt == null || endAt == null || !endAt.isAfter(startAt)) {
            Web.flash(request,
                    "Thời gian bắt đầu và kết thúc không hợp lệ");
            response.sendRedirect(request.getContextPath()
                    + "/admin/emptyWindows?roomId=" + roomId);
            return;
        }

        // Sinh dữ liệu cảm biến giả lập trong khoảng phòng trống.
        List<SensorSample> samples =
                generateMockSamples(startAt, endAt);

        if (samples.isEmpty()) {
            Web.flash(request,
                    "Không thể tạo dữ liệu mẫu cho khoảng thời gian này");
            response.sendRedirect(request.getContextPath()
                    + "/admin/emptyWindows?roomId=" + roomId);
            return;
        }

        // Tính giá trị trung bình mức nền.
        double avgCO = samples.stream()
                .mapToDouble(SensorSample::getCoValue)
                .average()
                .orElse(0.0);

        double avgCO2 = samples.stream()
                .mapToDouble(SensorSample::getCo2Value)
                .average()
                .orElse(0.0);

        double baselineCO =
                Math.round(avgCO * 100.0) / 100.0;
        double baselineCO2 =
                Math.round(avgCO2 * 100.0) / 100.0;

        BaselinePreview preview = new BaselinePreview(
                roomId, ew, samples, baselineCO, baselineCO2);

        // Lưu kết quả xem trước vào session để dùng khi người dùng xác nhận lưu.
        request.getSession().setAttribute(PREVIEW_KEY, preview);

        showPreview(request, response, preview, null);
    }

    @Override
    protected void doPost(HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);

        if (session == null) {
            Web.flash(request,
                    "Session expired. Please recalculate baseline.");
            response.sendRedirect(
                    request.getContextPath() + "/admin/rooms");
            return;
        }

        // Kiểm tra người dùng đã đăng nhập.
        AppUser me = (AppUser) session.getAttribute("user");

        if (me == null) {
            response.sendError(HttpServletResponse.SC_UNAUTHORIZED);
            return;
        }

        // Lấy kết quả đã xem trước từ session.
        Object value = session.getAttribute(PREVIEW_KEY);

        if (!(value instanceof BaselinePreview)) {
            Web.flash(request,
                    "Preview results not found. Please recalculate baseline.");
            response.sendRedirect(
                    request.getContextPath() + "/admin/rooms");
            return;
        }

        BaselinePreview preview = (BaselinePreview) value;

        // Tạo Calibration từ đúng kết quả đã hiển thị.
        Calibration calibration = new Calibration();

        calibration.setCode("CAL-" + UUID.randomUUID()
                .toString().replace("-", "")
                .substring(0, 16).toUpperCase());

        calibration.setName(
                "Baseline - " + preview.getEmptyWindow().getName());

        calibration.setNote(
                "Created from empty window "
                + preview.getEmptyWindow().getName()
                + " (simulated sensor data)");

        calibration.setRoomId(preview.getRoomId());
        calibration.setPerformedBy(me.getUserId());
        calibration.setCoBaseLine((float) preview.getBaselineCO());
        calibration.setCo2BaseLine((float) preview.getBaselineCO2());

        boolean inserted = calibrations.insert(calibration);

        if (!inserted) {
            showPreview(request, response, preview,
                    "Unable to save calibration. Please try again.");
            return;
        }

        // Chỉ xóa kết quả xem trước sau khi lưu thành công.
        session.removeAttribute(PREVIEW_KEY);

        Web.flash(request, "New baseline saved successfully");

        response.sendRedirect(request.getContextPath()
                + "/admin/calibrations?roomId="
                + preview.getRoomId());
    }

    private void showPreview(HttpServletRequest request,
            HttpServletResponse response,
            BaselinePreview preview,
            String errorMessage)
            throws ServletException, IOException {

        request.setAttribute("emptyWindow",
                preview.getEmptyWindow());
        request.setAttribute("roomId",
                preview.getRoomId());
        request.setAttribute("stationId",
                preview.getRoomId());
        request.setAttribute("samples",
                preview.getSamples());
        request.setAttribute("sampleCount",
                preview.getSamples().size());
        request.setAttribute("baselineCO",
                preview.getBaselineCO());
        request.setAttribute("baselineCO2",
                preview.getBaselineCO2());
        request.setAttribute("errorMessage", errorMessage);

        request.getRequestDispatcher(
                "/WEB-INF/views/baseline.jsp")
                .forward(request, response);
    }

    private List<SensorSample> generateMockSamples(
            LocalDateTime startAt,
            LocalDateTime endAt) {

        List<SensorSample> samples = new ArrayList<>();

        long durationSeconds =
                Duration.between(startAt, endAt).getSeconds();
        long durationMinutes =
                Duration.between(startAt, endAt).toMinutes();

        if (durationMinutes <= 0 || durationSeconds <= 0) {
            return samples;
        }

        int sampleCount =
                (int) Math.min(durationMinutes, MAX_SAMPLES);

        for (int i = 0; i < sampleCount; i++) {
            long offsetSeconds =
                    durationSeconds * i / sampleCount;

            LocalDateTime measuredAt =
                    startAt.plusSeconds(offsetSeconds);

            double coValue = randomValue(1.8, 2.5);
            double co2Value = randomValue(405.0, 425.0);

            samples.add(new SensorSample(
                    measuredAt, coValue, co2Value));
        }

        return samples;
    }

    private double randomValue(double min, double max) {
        return ThreadLocalRandom.current()
                .nextDouble(min, max);
    }

    // Lưu dữ liệu xem trước trong HttpSession.
    private static class BaselinePreview {

        private final int roomId;
        private final EmptyWindow emptyWindow;
        private final List<SensorSample> samples;
        private final double baselineCO;
        private final double baselineCO2;

        BaselinePreview(int roomId,
                EmptyWindow emptyWindow,
                List<SensorSample> samples,
                double baselineCO,
                double baselineCO2) {

            this.roomId = roomId;
            this.emptyWindow = emptyWindow;
            this.samples = samples;
            this.baselineCO = baselineCO;
            this.baselineCO2 = baselineCO2;
        }

        int getRoomId() {
            return roomId;
        }

        int getStationId() {
            return roomId;
        }

        EmptyWindow getEmptyWindow() {
            return emptyWindow;
        }

        List<SensorSample> getSamples() {
            return samples;
        }

        double getBaselineCO() {
            return baselineCO;
        }

        double getBaselineCO2() {
            return baselineCO2;
        }
    }

    public static class SensorSample {

        private final LocalDateTime measuredAt;
        private final double coValue;
        private final double co2Value;

        public SensorSample(LocalDateTime measuredAt,
                double coValue,
                double co2Value) {
            this.measuredAt = measuredAt;
            this.coValue = coValue;
            this.co2Value = co2Value;
        }

        public LocalDateTime getMeasuredAt() {
            return measuredAt;
        }

        public double getCoValue() {
            return coValue;
        }

        public double getCo2Value() {
            return co2Value;
        }
    }
}
