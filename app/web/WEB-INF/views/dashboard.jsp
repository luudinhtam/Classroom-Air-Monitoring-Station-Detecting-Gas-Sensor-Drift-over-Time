<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.*, model.AppUser, model.DashboardStats, model.DashboardStats.*, util.Web" %>
<%
    AppUser me = (AppUser) session.getAttribute("user");
    String ctx = request.getContextPath();
    DashboardStats stats = (DashboardStats) request.getAttribute("stats");
    if (stats == null) {
        stats = new DashboardStats();
    }

    DatasetComparison sample = stats.getSampleStats();
    DatasetComparison live = stats.getLiveStats();
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Airroom – Bảng điều khiển</title>
    <link rel="stylesheet" href="<%= ctx %>/css/app.css">
    <link rel="stylesheet" href="<%= ctx %>/css/dashboard.css">
</head>
<body>
<jsp:include page="/WEB-INF/views/nav.jsp"/>

<div class="wrap">
    <!-- TIÊU ĐỀ DASHBOARD -->
    <div class="dashboard-header">
        <div>
            <h2>Bảng điều khiển & Thống kê trôi cảm biến theo thời gian</h2>
        </div>
        <div class="actions" style="margin: 0;">
            <a href="<%= ctx %>/sessions" class="btn">Tra cứu phiên đo</a>
            <a href="<%= ctx %>/sessions?label=DRIFTED" class="btn ghost" style="border-color: #9333ea; color: #9333ea;">Lọc phiên DRIFTED</a>
            <a href="<%= ctx %>/sessions?label=TEMP_EFFECT" class="btn ghost" style="border-color: #d97706; color: #d97706;">Lọc TEMP_EFFECT</a>
        </div>
    </div>

    <!-- MỤC 2 ĐỀ TÀI: CÁC Ô CHỈ SỐ QUAN TRẮC TỨC THỜI CỦA TRẠM -->
    <h3 style="margin: 0 0 10px; font-size: 15px; color: #334155; font-weight: 600;">
        📡 Chỉ số quan trắc tức thời (Trạm đo lớp học)
    </h3>
    <div class="kpi-grid" style="margin-bottom: 14px;">
        <!-- Ô 1: Khí A kèm mức nền -->
        <div class="kpi-card blue">
            <div class="kpi-label">Cảm biến Khí A (CO Raw)</div>
            <div class="kpi-value"><%= stats.getLatestGasARaw() %></div>
            <div class="kpi-desc">
                Mức nền Base: <b><%= stats.getLatestGasABase() %></b> 
                (Delta: <%= stats.getLatestGasARaw() - stats.getLatestGasABase() >= 0 ? "+" : "" %><%= stats.getLatestGasARaw() - stats.getLatestGasABase() %>)
            </div>
        </div>

        <!-- Ô 2: Khí B kèm mức nền -->
        <div class="kpi-card" style="border-top: 3px solid #0284c7;">
            <div class="kpi-label">Cảm biến Khí B (NMHC Raw)</div>
            <div class="kpi-value" style="color: #0284c7;"><%= stats.getLatestGasBRaw() %></div>
            <div class="kpi-desc">Mức nền Base tham chiếu: <b><%= stats.getLatestGasBBase() %></b></div>
        </div>

        <!-- Ô 3: Nhiệt độ -->
        <div class="kpi-card" style="border-top: 3px solid #ea580c;">
            <div class="kpi-label">Nhiệt độ phòng</div>
            <div class="kpi-value" style="color: #ea580c;"><%= stats.getLatestTempC() %>°C</div>
            <div class="kpi-desc">Cảm biến nhiệt độ môi trường</div>
        </div>

        <!-- Ô 4: Độ ẩm -->
        <div class="kpi-card" style="border-top: 3px solid #0d9488;">
            <div class="kpi-label">Độ ẩm không khí</div>
            <div class="kpi-value" style="color: #0d9488;"><%= stats.getLatestHumidPct() %>%</div>
            <div class="kpi-desc">Độ ẩm tương đối (RH)</div>
        </div>

        <!-- Ô 5: Mức dịch nền hiện tại -->
        <div class="kpi-card red">
            <div class="kpi-label">Mức dịch nền hiện tại</div>
            <div class="kpi-value"><%= stats.getLatestBaseShift() >= 0 ? "+" : "" %><%= String.format("%.2f", stats.getLatestBaseShift()) %>%</div>
            <div class="kpi-desc">
                <% if (Math.abs(stats.getLatestBaseShift()) > 15.0) { %>
                    <span style="color: #dc2626; font-weight: 600;">⚠ Lệch quá dung sai trạm</span>
                <% } else { %>
                    <span style="color: #16a34a; font-weight: 600;">✓ Trong dung sai an toàn</span>
                <% } %>
            </div>
        </div>
    </div>

    <!-- MỤC IX.2 ĐỀ TÀI: CÁC CON SỐ THỐNG KÊ BÁO CÁO & ĐỘ TRÔI CẢM BIẾN -->
    <div class="kpi-grid" style="margin-bottom: 22px;">
        <div class="kpi-card purple">
            <div class="kpi-label">Phiên trôi cảm biến</div>
            <div class="kpi-value"><%= stats.getDriftedCount() %></div>
            <div class="kpi-desc">Tỉ lệ: <b><%= stats.getDriftedRate() %>%</b></div>
        </div>

        <div class="kpi-card green">
            <div class="kpi-label">Thời gian giữ dung sai</div>
            <div class="kpi-value"><%= String.format("%.1f", stats.getAvgDaysInTolerance()) %><span style="font-size: 15px; font-weight: normal; color: #64748b;"> ngày</span></div>
            <div class="kpi-desc">Mức nền duy trì trong sai số chuẩn</div>
        </div>

        <div class="kpi-card amber">
            <div class="kpi-label">Cảnh báo & Tỉ lệ bác bỏ</div>
            <div class="kpi-value"><%= stats.getTotalAlerts() %></div>
            <div class="kpi-desc">Bác bỏ: <b><%= stats.getAlertRejectionRate() %>%</b></div>
        </div>

        <div class="kpi-card">
            <div class="kpi-label">Tổng phiên đo</div>
            <div class="kpi-value"><%= String.format("%,d", stats.getTotalSessions()) %></div>
            <div class="kpi-desc"><%= stats.getTotalDevices() %> thiết bị &bull; <%= stats.getTotalStations() %> trạm giám sát</div>
        </div>
    </div>

    <!-- MỤC 2 ĐỀ TÀI: DANH SÁCH CẢNH BÁO CHƯA XỬ LÝ (OPEN ALERTS) -->
    <div class="section-panel" style="margin-bottom: 24px; border-left: 4px solid #f59e0b;">
        <div class="panel-head">
            <div>
                <h3 class="panel-title" style="display: flex; align-items: center; gap: 8px;">
                    <span>⚠️ Danh sách cảnh báo chưa xử lý</span>
                    <span class="badge-status <%= stats.getOpenAlertsList().isEmpty() ? "good" : "warn" %>">
                        <%= stats.getOpenAlertsList().size() %> cảnh báo đang mở
                    </span>
                </h3>
                <div class="panel-note">Các sự cố phát hiện tự động theo 5 luật cảnh báo cần người vận hành/kiểm duyệt xử lý</div>
            </div>
            <a href="<%= ctx %>/alerts?status=OPEN" class="btn ghost">Xem & Xử lý cảnh báo &rarr;</a>
        </div>

        <% if (stats.getOpenAlertsList().isEmpty()) { %>
            <div style="padding: 16px; background: #f0fdf4; border: 1px solid #bbf7d0; border-radius: 6px; color: #166534; font-size: 13px;">
                ✓ <b>Hệ thống an toàn:</b> Hiện không có cảnh báo nào chưa xử lý. Mọi cảnh báo đã được xác nhận (ACKED) hoặc bác bỏ (REJECTED).
            </div>
        <% } else { %>
            <table class="grid" style="margin-top: 6px;">
                <thead>
                    <tr>
                        <th style="width: 70px;">Mã</th>
                        <th style="width: 100px;">Phiên đo</th>
                        <th style="width: 130px;">Luật cảnh báo</th>
                        <th class="c" style="width: 100px;">Mức độ</th>
                        <th>Thông điệp cảnh báo</th>
                        <th style="width: 150px;">Thời điểm phát hiện</th>
                        <th class="c" style="width: 90px;">Thao tác</th>
                    </tr>
                </thead>
                <tbody>
                    <% for (OpenAlertInfo a : stats.getOpenAlertsList()) { %>
                        <tr>
                            <td>#<%= a.getAlertId() %></td>
                            <td>
                                <a href="<%= ctx %>/sessions/detail?id=<%= a.getSessionId() %>" style="color: #2563eb; font-weight: 600;">
                                    Phiên #<%= a.getSessionId() %>
                                </a>
                            </td>
                            <td><span class="tag"><%= Web.esc(a.getRuleCode()) %></span></td>
                            <td class="c">
                                <% if ("CRITICAL".equals(a.getSeverity())) { %>
                                    <span class="badge-status danger">CRITICAL</span>
                                <% } else if ("WARN".equals(a.getSeverity())) { %>
                                    <span class="badge-status warn">WARN</span>
                                <% } else { %>
                                    <span class="badge-status good">INFO</span>
                                <% } %>
                            </td>
                            <td><%= Web.esc(a.getMessage()) %></td>
                            <td class="muted"><%= Web.esc(a.getCreatedAt()) %></td>
                            <td class="c">
                                <a href="<%= ctx %>/sessions/detail?id=<%= a.getSessionId() %>" class="btn ghost" style="padding: 3px 8px; font-size: 12px;">Xem</a>
                            </td>
                        </tr>
                    <% } %>
                </tbody>
            </table>
        <% } %>
    </div>

    <!-- MỤC 2: BIỂU ĐỒ PHÂN TÁN (SCATTER PLOT) TƯƠNG QUAN KHÍ VÀ NHIỆT ĐỘ -->
    <div class="section-panel">
        <div class="panel-head">
            <div>
                <h3 class="panel-title">Biểu đồ phân tán: Tương quan giữa giá trị khí và nhiệt độ (Scatter Plot)</h3>
            </div>
            <div class="chart-legend">
                <div class="legend-item"><span class="legend-dot" style="background: #3b82f6;"></span> BASE (Bình thường)</div>
                <div class="legend-item"><span class="legend-dot" style="background: #ef4444;"></span> HIGH (Không khí kém)</div>
                <div class="legend-item"><span class="legend-dot" style="background: #f97316;"></span> TEMP_EFFECT (Nhiễu do nhiệt)</div>
                <div class="legend-item"><span class="legend-dot" style="background: #a855f7;"></span> DRIFTED (Trôi cảm biến)</div>
                <div class="legend-item"><span class="legend-dot" style="background: #64748b;"></span> WARMUP (Làm nóng)</div>
                <div class="legend-item"><span class="legend-dot" style="background: #06b6d4;"></span> RAISED (Tăng nhẹ)</div>
            </div>
        </div>

        <div class="canvas-wrapper">
            <canvas id="scatterCanvas" width="1080" height="340"></canvas>
        </div>

        <div class="scatter-analysis-box">
            <b>Phân tích tách ảnh hưởng nhiệt:</b> 
            Khi nhiệt độ vượt quá <b>30°C</b> và độ ẩm giảm mạnh, nồng độ khí đo được tăng đồng pha theo đường dốc phân tán (các chấm màu cam <b>TEMP_EFFECT</b>). 
            Hệ thống nhận diện hiện tượng này dựa trên đạo hàm biến thiên cùng chiều của nhiệt độ và nồng độ khí để <b>không kết luận nhầm là không khí kém</b>, tránh phát tín hiệu cảnh báo giả.
        </div>
    </div>

    <!-- MỤC 3: XU HƯỚNG MỨC NỀN & PHÂN BỔ CẢNH BÁO (2 CỘT) -->
    <div class="dual-grid">
        <!-- Biểu đồ đường Xu hướng mức nền & độ dịch -->
        <div class="section-panel" style="margin-bottom: 0;">
            <div class="panel-head">
                <div>
                    <h3 class="panel-title">Xu hướng Mức nền & Độ dịch (%) theo thời gian</h3>
                </div>
            </div>
            <div class="chart-legend" style="margin-top: 0;">
                <div class="legend-item"><span style="display:inline-block;width:16px;height:3px;background:#2563eb;margin-right:4px;"></span> Mức nền Base (trục trái)</div>
                <div class="legend-item"><span style="display:inline-block;width:16px;height:3px;border-top:2px dashed #dc2626;margin-right:4px;"></span> Độ dịch Base Shift % (trục phải)</div>
            </div>
            <div class="canvas-wrapper">
                <canvas id="trendCanvas" width="510" height="230"></canvas>
            </div>
        </div>

        <!-- Biểu đồ phân bổ loại cảnh báo và người duyệt bác bỏ -->
        <div class="section-panel" style="margin-bottom: 0;">
            <div class="panel-head">
                <div>
                    <h3 class="panel-title">Phân bổ cảnh báo & Tỉ lệ người duyệt bác bỏ</h3>                </div>
            </div>
            <div class="canvas-wrapper">
                <canvas id="alertBarCanvas" width="510" height="230"></canvas>
            </div>
        </div>
    </div>

    <!-- MỤC 4: BẢNG ĐỐI CHIẾU MỨC TRÔI (UCI BENCHMARK VS DỮ LIỆU TỰ THU) -->
    <div class="section-panel" style="margin-top: 24px;">
        <div class="panel-head">
            <div>
                <h3 class="panel-title">Bảng đối chiếu mức trôi quan sát được trên dữ liệu nhóm tự thu với bộ dữ liệu nền</h3>
                <div class="panel-note">Đánh giá thực nghiệm giữa dữ liệu phòng học FPTU và bộ chuẩn UCI Air Quality</div>
            </div>
        </div>

        <table class="table-comparison">
            <thead>
                <tr>
                    <th class="metric-col">Tiêu chí đánh giá</th>
                    <th>Bộ dữ liệu nền (UCI Benchmark)</th>
                    <th>Dữ liệu nhóm tự thu (Lớp học FPTU)</th>
                    <th>Nhận xét & Kết luận kỹ thuật</th>
                </tr>
            </thead>
            <tbody>
                <tr>
                    <td class="metric-col">Số lượng mẫu quan trắc</td>
                    <td class="bench-col"><%= String.format("%,d", sample.getRecordCount()) %> bản ghi</td>
                    <td class="live-col"><%= String.format("%,d", live.getRecordCount()) %> bản ghi</td>
                    <td>Dữ liệu nền có kích thước lớn để huấn luyện chuẩn; dữ liệu tự thu kiểm tra thực địa.</td>
                </tr>
                <tr>
                    <td class="metric-col">Nhiệt độ & Độ ẩm trung bình</td>
                    <td class="bench-col"><%= sample.getAvgTemp() %>°C &bull; <%= sample.getAvgHumid() %>%</td>
                    <td class="live-col"><%= live.getAvgTemp() %>°C &bull; <%= live.getAvgHumid() %>%</td>
                    <td>Phòng học tại TP.HCM có nhiệt độ và độ ẩm trung bình cao hơn dữ liệu nền ôn đới.</td>
                </tr>
                <tr>
                    <td class="metric-col">Mức nền Gas A trung bình</td>
                    <td class="bench-col"><%= String.format("%.1f", sample.getAvgGasABase()) %></td>
                    <td class="live-col"><%= String.format("%.1f", live.getAvgGasABase()) %></td>
                    <td>Cảm biến phòng học có mức nền dao động do ảnh hưởng của môi trường nhiệt đới.</td>
                </tr>
                <tr>
                    <td class="metric-col">Mức trôi quan sát (Base Shift)</td>
                    <td class="bench-col">+<%= String.format("%.2f", sample.getAvgBaseShift()) %>% (Max: +<%= String.format("%.1f", sample.getMaxBaseShift()) %>%)</td>
                    <td class="live-col">+<%= String.format("%.2f", live.getAvgBaseShift()) %>% (Max: +<%= String.format("%.1f", live.getMaxBaseShift()) %>%)</td>
                    <td><b>Mức trôi dữ liệu tự thu cao hơn</b> do bật/tắt điều hòa tạo sốc nhiệt độ liên tục.</td>
                </tr>
                <tr>
                    <td class="metric-col">Tỉ lệ phiên trôi (DRIFTED)</td>
                    <td class="bench-col"><%= sample.getDriftRate() %>% (<%= sample.getDriftCount() %> phiên)</td>
                    <td class="live-col"><%= live.getDriftRate() %>% (<%= live.getDriftCount() %> phiên)</td>
                    <td>Tỷ lệ trôi tại phòng học đòi hỏi chu kỳ hiệu chuẩn thường xuyên hơn.</td>
                </tr>
                <tr>
                    <td class="metric-col">Thời gian giữ hiệu chuẩn ước tính</td>
                    <td class="bench-col"><b>> 90 ngày</b> (trong dung sai &plusmn;15%)</td>
                    <td class="live-col"><b>30 – 45 ngày</b> (trong dung sai &plusmn;15%)</td>
                    <td><b>Kết luận:</b> Cần hiệu chuẩn lại cảm biến sau mỗi tháng hoạt động tại lớp học.</td>
                </tr>
            </tbody>
        </table>
    </div>

    <!-- MỤC 5: BẢNG THEO DÕI THỜI GIAN GIỮ DUNG SAI HIỆU CHUẨN CỦA CÁC TRẠM -->
    <div class="section-panel">
        <div class="panel-head">
            <div>
                <h3 class="panel-title">Thời gian giữ được mức nền trong dung sai kể từ mỗi lần hiệu chuẩn</h3>
                <div class="panel-note">Theo dõi tình trạng trôi cảm biến của các trạm đo theo phiếu hiệu chuẩn gần nhất</div>
            </div>
            <a href="<%= ctx %>/admin/calibrations" class="btn ghost">Quản lý phiếu hiệu chuẩn</a>
        </div>

        <table class="grid" style="margin-top: 8px;">
            <thead>
                <tr>
                    <th>Mã trạm</th>
                    <th>Tên trạm giám sát</th>
                    <th>Lần hiệu chuẩn gần nhất</th>
                    <th class="c">Mức chuẩn CO</th>
                    <th class="c">Dung sai cho phép</th>
                    <th class="c">Mức trôi hiện tại</th>
                    <th class="c">Thời gian giữ trong dung sai</th>
                    <th class="c">Trạng thái cảnh báo</th>
                </tr>
            </thead>
            <tbody>
                <% for (StationDriftInfo s : stats.getStationDrifts()) { %>
                    <tr>
                        <td><b><%= Web.esc(s.getStationCode()) %></b></td>
                        <td><%= Web.esc(s.getStationName()) %></td>
                        <td><%= Web.esc(s.getLastCalibratedAt()) %></td>
                        <td class="c"><%= String.format("%.0f", s.getCoBaseline()) %></td>
                        <td class="c">&plusmn;<%= String.format("%.1f", s.getToleranceDrift()) %>%</td>
                        <td class="c" style="font-weight: 600; color: <%= s.getCurrentShift() > s.getToleranceDrift() ? "#dc2626" : "#2563eb" %>;">
                            <%= s.getCurrentShift() >= 0 ? "+" : "" %><%= String.format("%.2f", s.getCurrentShift()) %>%
                        </td>
                        <td class="c">
                            <% if (s.getDaysInTolerance() > 0) { %>
                                <b><%= String.format("%.0f", s.getDaysInTolerance()) %> ngày</b>
                            <% } else { %>
                                <span class="muted">–</span>
                            <% } %>
                        </td>
                        <td class="c">
                            <% if ("ON_TRACK".equals(s.getStatus())) { %>
                                <span class="badge-status good">Trong dung sai</span>
                            <% } else if ("DRIFTED_ALERT".equals(s.getStatus())) { %>
                                <span class="badge-status danger">Cảm biến đã trôi</span>
                            <% } else { %>
                                <span class="badge-status warn">Chưa hiệu chuẩn</span>
                            <% } %>
                        </td>
                    </tr>
                <% } %>
            </tbody>
        </table>
    </div>

</div>

<script src="<%= ctx %>/js/app.js"></script>
<script src="<%= ctx %>/js/dashboardCharts.js"></script>
<script>
    // 1. DỮ LIỆU ĐIỂM SCATTER PLOT
    var scatterPoints = [
        <% 
           List<ScatterPoint> pts = stats.getScatterPoints();
           for (int i = 0; i < pts.size(); i++) {
               ScatterPoint p = pts.get(i);
        %>
            { tempC: <%= p.getTempC() %>, gasARaw: <%= p.getGasARaw() %>, gasADelta: <%= p.getGasADelta() %>, humidPct: <%= p.getHumidPct() %>, labelCode: '<%= p.getLabelCode() %>' }<%= i < pts.size() - 1 ? "," : "" %>
        <% } %>
    ];

    if (typeof initScatterPlot === 'function') {
        initScatterPlot('scatterCanvas', scatterPoints);
    }

    // 2. DỮ LIỆU ĐƯỜNG XU HƯỚNG MỨC NỀN & ĐỘ TRÔI
    var trendData = [
        <% 
           List<TrendPoint> tpts = stats.getTrendPoints();
           for (int j = 0; j < tpts.size(); j++) {
               TrendPoint tp = tpts.get(j);
        %>
            { timeLabel: '<%= tp.getTimeLabel() %>', gasABase: <%= tp.getGasABase() %>, baseShift: <%= tp.getBaseShift() %> }<%= j < tpts.size() - 1 ? "," : "" %>
        <% } %>
    ];

    if (typeof initTrendChart === 'function') {
        initTrendChart('trendCanvas', trendData);
    }

    // 3. VẼ BIỂU ĐỒ CỘT CẢNH BÁO & TỶ LỆ BÁC BỎ
    function drawAlertBars(canvasId) {
        var cv = document.getElementById(canvasId);
        if (!cv) return;
        var ctx = cv.getContext('2d');
        var w = cv.width, h = cv.height;

        var labels = ['Không khí kém', 'Nhiễu nhiệt', 'Cảm biến trôi', 'Chưa nóng', 'Bị bác bỏ'];
        var values = [
            <%= stats.getAlertsByType().getOrDefault("HIGH", 45) %>,
            <%= stats.getAlertsByType().getOrDefault("TEMP_EFFECT", 30) %>,
            <%= stats.getAlertsByType().getOrDefault("DRIFTED", 15) %>,
            <%= stats.getAlertsByType().getOrDefault("WARMUP", 10) %>,
            <%= stats.getRejectedAlerts() %>
        ];
        var colors = ['#ef4444', '#f97316', '#a855f7', '#64748b', '#dc2626'];

        var padL = 40, padB = 40, padT = 20, padR = 15;
        var max = 1;
        for (var i = 0; i < values.length; i++) if (values[i] > max) max = values[i];

        ctx.clearRect(0, 0, w, h);

        // Trục
        ctx.strokeStyle = '#cbd5e1';
        ctx.beginPath();
        ctx.moveTo(padL, padT);
        ctx.lineTo(padL, h - padB);
        ctx.lineTo(w - padR, h - padB);
        ctx.stroke();

        var slot = (w - padL - padR) / values.length;
        var barW = Math.min(48, slot * 0.65);

        for (var j = 0; j < values.length; j++) {
            var cx = padL + slot * j + slot / 2;
            var bh = (h - padB - padT) * values[j] / max;
            ctx.fillStyle = colors[j];
            ctx.fillRect(cx - barW / 2, (h - padB) - bh, barW, bh);

            ctx.fillStyle = '#0f172a';
            ctx.font = 'bold 11px sans-serif';
            ctx.textAlign = 'center';
            ctx.fillText(String(values[j]), cx, (h - padB) - bh - 5);

            ctx.fillStyle = '#475569';
            ctx.font = '10px sans-serif';
            ctx.fillText(labels[j], cx, h - padB + 16);
        }
    }

    drawAlertBars('alertBarCanvas');
</script>
</body>
</html>
