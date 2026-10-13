
package controller;

import dao.EmptyWindowDAO;
import java.io.IOException;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ThreadLocalRandom;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import model.EmptyWindow;
import util.Web;

@WebServlet(name = "BaseLineServlet",
        urlPatterns = {"/admin/emptyWindows/baseline"})
public class BaseLineServlet extends HttpServlet {

    private final EmptyWindowDAO emptyWindows = new EmptyWindowDAO();

    // Giới hạn số mẫu giả lập cho một lần tính toán
    private static final int MAX_SAMPLES = 1440;

    @Override
    protected void doGet(HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        // Lay cac tham so tu request
        int stationId = Web.intParam(request, "stationId", 0);
        int emptyWindowId = Web.intParam(request, "emptyWindowId", 0);

        // Kiểm tra tham số
        if (stationId <= 0 || emptyWindowId <= 0) {
            Web.flash(request, "Thong tin tram hoac khoang phong trong khong hop le");
            response.sendRedirect(request.getContextPath() + "/admin/stations");
            return;
        }

        // Tìm khoảng phòng trống
        EmptyWindow ew = emptyWindows.findById(emptyWindowId);

        if (ew == null) {
            Web.flash(request, "Khong tim thay khoang phong trong");
            response.sendRedirect(request.getContextPath() + "/admin/emptyWindows?stationId=" + stationId);
            return;
        }

        // Kiểm tra khoảng phòng trống có thuộc trạm này không
        if (ew.getStationId() != stationId) {
            Web.flash(request, "Khoang phong trong khong thuoc tram nay");
            response.sendRedirect(request.getContextPath() + "/admin/emptyWindows?stationId=" + stationId);
            return;
        }

        LocalDateTime startAt = ew.getStartAt();
        LocalDateTime endAt = ew.getEndAt();

        if (startAt == null || endAt == null || !endAt.isAfter(startAt)) {
            Web.flash(request, "Khoang thoi gian khong hop le");
            response.sendRedirect(request.getContextPath() + "/admin/emptyWindows?stationId=" + stationId);
            return;
        }

        // Tạo dữ liệu cảm biến giả lập
        List<SensorSample> samples = generateMockSamples(startAt, endAt);

        if (samples.isEmpty()) {
            Web.flash(request, "Khong co du lieu de tinh muc nen");
            response.sendRedirect(request.getContextPath() + "/admin/emptyWindows?stationId=" + stationId);
            return;
        }

        // Tính mức nền trung bình
        double totalCO = 0;
        double totalCO2 = 0;

            // Tinh tong
        for (SensorSample sample : samples) {
            totalCO += sample.getCoValue();
            totalCO2 += sample.getCo2Value();
        }
            // Chia trung binh
        double baselineCO = totalCO / samples.size();
        double baselineCO2 = totalCO2 / samples.size();

        // Gửi dữ liệu sang JSP
        request.setAttribute("emptyWindow", ew);
        request.setAttribute("stationId", stationId);
        request.setAttribute("samples", samples);
        request.setAttribute("sampleCount", samples.size());
        request.setAttribute("baselineCO", baselineCO);
        request.setAttribute("baselineCO2", baselineCO2);

        request.getRequestDispatcher("/WEB-INF/views/baseline.jsp").forward(request, response);
    }

    /**
     * Sinh dữ liệu giả lập, mỗi phút một mẫu.
     * Không lấy dữ liệu từ cảm biến thật.
     */
    private List<SensorSample> generateMockSamples(
            LocalDateTime startAt,
            LocalDateTime endAt) {

        List<SensorSample> samples = new ArrayList<>();

        long durationMinutes = java.time.Duration.between(startAt, endAt).toMinutes();

        if (durationMinutes <= 0) {
            return samples;
        }

        int sampleCount = (int) Math.min(durationMinutes, MAX_SAMPLES);

        // Chia đều mẫu trong khoảng thời gian đã chọn
        long intervalSeconds = java.time.Duration.between(startAt, endAt).getSeconds();

        for (int i = 0; i < sampleCount; i++) {
            long offsetSeconds = intervalSeconds * i / sampleCount;

            LocalDateTime measuredAt = startAt.plusSeconds(offsetSeconds);

            // Giá trị minh họa; thay bằng dữ liệu thật sau này
            double coValue = randomValue(1.8, 2.5);
            double co2Value = randomValue(405.0, 425.0);

            samples.add(new SensorSample(measuredAt, coValue, co2Value));
        }

        return samples;
    }

    private double randomValue(double min, double max) {
        return ThreadLocalRandom.current().nextDouble(min, max);
    }

    /**
     * Model nhỏ dùng để hiển thị từng mẫu đo trên baseline.jsp.
     */
    public static class SensorSample {

        private final LocalDateTime measuredAt;
        private final double coValue;
        private final double co2Value;

        public SensorSample(LocalDateTime measuredAt,
                double coValue, double co2Value) {
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
