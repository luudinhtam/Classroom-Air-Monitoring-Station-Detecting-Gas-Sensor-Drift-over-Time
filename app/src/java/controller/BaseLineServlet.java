
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

    @Override
    protected void doGet(HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        int stationId = Web.intParam(request, "stationId", 0);
        int emptyWindowId = Web.intParam(request, "emptyWindowId", 0);

        if (stationId <= 0 || emptyWindowId <= 0) {
            Web.flash(request,
                    "Thong tin tram hoac khoang phong trong khong hop le");
            response.sendRedirect(
                    request.getContextPath() + "/admin/stations");
            return;
        }

        EmptyWindow ew = emptyWindows.findById(emptyWindowId);

        if (ew == null || ew.getStationId() != stationId) {
            Web.flash(request, "Khoang phong trong khong hop le");
            response.sendRedirect(request.getContextPath()
                    + "/admin/emptyWindows?stationId=" + stationId);
            return;
        }

        LocalDateTime startAt = ew.getStartAt();
        LocalDateTime endAt = ew.getEndAt();

        if (startAt == null || endAt == null
                || !endAt.isAfter(startAt)) {
            Web.flash(request, "Khoang thoi gian khong hop le");
            response.sendRedirect(request.getContextPath()
                    + "/admin/emptyWindows?stationId=" + stationId);
            return;
        }

        // Sinh dữ liệu giả lập một lần cho kết quả xem trước.
        List<SensorSample> samples =
                generateMockSamples(startAt, endAt);

        if (samples.isEmpty()) {
            Web.flash(request, "Khong co du lieu de tinh muc nen");
            response.sendRedirect(request.getContextPath()
                    + "/admin/emptyWindows?stationId=" + stationId);
            return;
        }

        // Tính baseline CO và CO2.
        double totalCO = 0;
        double totalCO2 = 0;

        for (SensorSample sample : samples) {
            totalCO += sample.getCoValue();
            totalCO2 += sample.getCo2Value();
        }

        double baselineCO = totalCO / samples.size();
        double baselineCO2 = totalCO2 / samples.size();

        // Lưu kết quả xem trước vào session, không dùng token.
        BaselinePreview preview = new BaselinePreview(
                stationId,
                ew,
                samples,
                baselineCO,
                baselineCO2
        );

        HttpSession session = request.getSession();
        session.setAttribute(PREVIEW_KEY, preview);

        showPreview(request, response, preview, null);
    }

    @Override
    protected void doPost(HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        HttpSession session = request.getSession(false);

        if (session == null) {
            Web.flash(request,
                    "Phien lam viec da het han. Vui long tinh lai baseline.");
            response.sendRedirect(
                    request.getContextPath() + "/admin/stations");
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
                    "Khong tim thay ket qua xem truoc. Vui long tinh lai baseline.");
            response.sendRedirect(
                    request.getContextPath() + "/admin/stations");
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
                "Tao tu khoang phong trong "
                + preview.getEmptyWindow().getName()
                + " (du lieu cam bien gia lap)");

        calibration.setStationId(preview.getStationId());
        calibration.setPerformedBy(me.getUserId());
        calibration.setCoBaseLine((float) preview.getBaselineCO());
        calibration.setCo2BaseLine((float) preview.getBaselineCO2());

        boolean inserted = calibrations.insert(calibration);

        if (!inserted) {
            showPreview(request, response, preview,
                    "Khong the luu Calibration. Vui long thu lai.");
            return;
        }

        // Chỉ xóa kết quả xem trước sau khi lưu thành công.
        session.removeAttribute(PREVIEW_KEY);

        Web.flash(request, "Da luu muc nen moi thanh cong");

        response.sendRedirect(request.getContextPath()
                + "/admin/calibrations?stationId="
                + preview.getStationId());
    }

    private void showPreview(HttpServletRequest request,
            HttpServletResponse response,
            BaselinePreview preview,
            String errorMessage)
            throws ServletException, IOException {

        request.setAttribute("emptyWindow",
                preview.getEmptyWindow());
        request.setAttribute("stationId",
                preview.getStationId());
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

        private final int stationId;
        private final EmptyWindow emptyWindow;
        private final List<SensorSample> samples;
        private final double baselineCO;
        private final double baselineCO2;

        BaselinePreview(int stationId,
                EmptyWindow emptyWindow,
                List<SensorSample> samples,
                double baselineCO,
                double baselineCO2) {

            this.stationId = stationId;
            this.emptyWindow = emptyWindow;
            this.samples = samples;
            this.baselineCO = baselineCO;
            this.baselineCO2 = baselineCO2;
        }

        int getStationId() {
            return stationId;
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
