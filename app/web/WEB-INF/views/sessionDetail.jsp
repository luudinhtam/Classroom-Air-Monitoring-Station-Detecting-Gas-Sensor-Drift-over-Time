<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
    <%@ page import="java.util.List, model.AirSession, model.Device, model.AirLabel, util.Web" %>
        <% AirSession item=(AirSession) request.getAttribute("detail"); Device device=(Device)
            request.getAttribute("device"); List<AirSession> timeline = (List<AirSession>)
                request.getAttribute("timeline");
                List<AirLabel> labelHistory = (List<AirLabel>) request.getAttribute("labelHistory");
                        String ctx = request.getContextPath();

                        if (item == null) {
                        response.sendRedirect(ctx + "/sessions");
                        return;
                        }

                        String lbl = item.getLabelCode() != null ? item.getLabelCode() : "–";
                        double driftPct = item.getBaseShift();
                        String driftColor = "#2b3a55";
                        if (Math.abs(driftPct) > 20.0 || "DRIFTED".equals(lbl) || "HIGH".equals(lbl)) {
                        driftColor = "#d9534f"; // Đỏ cảnh báo
                        } else if (Math.abs(driftPct) > 10.0 || "RAISED".equals(lbl)) {
                        driftColor = "#f0ad4e"; // Vàng chú ý
                        } else {
                        driftColor = "#3c763d"; // Xanh an toàn
                        }
                        %>
                        <!DOCTYPE html>
                        <html>

                        <head>
                            <meta charset="UTF-8">
                            <title>Chi tiết phiên đo #<%= item.getSessionId() %> - Air Monitoring</title>
                            <link rel="stylesheet" href="<%= ctx %>/css/app.css">
                            <link rel="stylesheet" href="<%= ctx %>/css/sessionDetail.css">
                        </head>

                        <body>
                            <jsp:include page="/WEB-INF/views/nav.jsp" />

                            <div class="wrap">
                                <!-- TIÊU ĐỀ & NÚT THAO TÁC -->
                                <div class="detail-header">
                                    <div>
                                        <h2>Phiên đo #<%= item.getSessionId() %>
                                        </h2>
                                        <div class="muted">
                                            Thời điểm đo: <b>
                                                <%= item.getMeasuredAt() !=null ? item.getMeasuredAt() : "–" %>
                                            </b>
                                            &bull; Thiết bị: <b>
                                                <%= device !=null ? Web.esc(device.getDeviceCode()) + " (" +
                                                    Web.esc(device.getLocation()) + ")" : "Device #" +
                                                    item.getDeviceId() %>
                                            </b>
                                        </div>
                                    </div>
                                    <div class="actions" style="margin: 0;">
                                        <a href="<%= ctx %>/sessions/edit?id=<%= item.getSessionId() %>"
                                            class="btn">Chỉnh sửa / Đổi nhãn</a>
                                        <a href="<%= ctx %>/sessions" class="btn ghost">&larr; Danh sách phiên</a>
                                    </div>
                                </div>

                                <!-- CÁC THẺ CHỈ SỐ QUAN TRỌNG -->
                                <div class="metric-cards">
                                    <div class="m-card">
                                        <div class="label">Cảm biến Gas A (Raw)</div>
                                        <div class="val" style="color: #2b5cb8;">
                                            <%= item.getGasARaw() %>
                                        </div>
                                        <div class="sub">Mức nền Base: <b>
                                                <%= item.getGasABase() %>
                                            </b> (Delta: <%= item.getGasADelta()>= 0 ? "+" : "" %><%=
                                                    item.getGasADelta() %>)</div>
                                    </div>

                                    <div class="m-card">
                                        <div class="label">Độ lệch Base Shift (%)</div>
                                        <div class="val" style="color: <%= driftColor %>;">
                                            <%= item.getBaseShift()>= 0 ? "+" : "" %><%= String.format("%.2f",
                                                    item.getBaseShift()) %>%
                                        </div>
                                        <div class="sub">
                                            <% if (Math.abs(item.getBaseShift())> 20.0) { %>
                                                <span style="color: #d9534f; font-weight: bold;">⚠ Cảnh báo lệch cảm
                                                    biến cao</span>
                                                <% } else if (Math.abs(item.getBaseShift())> 10.0) { %>
                                                    <span style="color: #f0ad4e; font-weight: bold;">Cần theo dõi độ
                                                        trôi</span>
                                                    <% } else { %>
                                                        <span style="color: #3c763d;">Trong ngưỡng an toàn</span>
                                                        <% } %>
                                        </div>
                                    </div>

                                    <div class="m-card">
                                        <div class="label">Nhiệt độ & Độ ẩm</div>
                                        <div class="val">
                                            <%= item.getTempC() %>°C
                                        </div>
                                        <div class="sub">Độ ẩm không khí: <b>
                                                <%= item.getHumidPct() %>%
                                            </b></div>
                                    </div>

                                    <div class="m-card">
                                        <div class="label">Nhãn phân loại hiện tại</div>
                                        <div class="val" style="font-size: 20px;">
                                            <span class="tag" style="background: <%= " DRIFTED".equals(lbl) ? "#fbeaea"
                                                : ("HIGH".equals(lbl) ? "#fff1e0" : "#eef3fb" ) %>; font-size: 16px;
                                                padding: 4px 10px; border-radius: 4px;">
                                                <%= Web.esc(lbl) %>
                                            </span>
                                        </div>
                                        <div class="sub">Gas B Raw: <b>
                                                <%= item.getGasBRaw() %>
                                            </b></div>
                                    </div>
                                </div>

                                <!-- KHUNG VẼ BIỂU ĐỒ BẰNG HTML5 CANVAS -->
                                <div class="chart-box">
                                    <div class="chart-header">
                                        <h3 style="margin: 0; font-size: 16px;">📈 Biểu đồ trực quan hóa độ lệch cảm
                                            biến theo thời gian (Gas Drift Trend)</h3>
                                        <div class="chart-legend">
                                            <div class="legend-item">
                                                <span class="legend-dot" style="background: #2b5cb8;"></span>
                                                <span>Tín hiệu Gas A Raw</span>
                                            </div>
                                            <div class="legend-item">
                                                <span class="legend-dot" style="background: #e07a5f;"></span>
                                                <span>Mức nền Gas Base</span>
                                            </div>
                                            <div class="legend-item">
                                                <span class="legend-dot"
                                                    style="background: #d9534f; border-radius: 50%;"></span>
                                                <span>Điểm phiên đo này (#<%= item.getSessionId() %>)</span>
                                            </div>
                                        </div>
                                    </div>

                                    <canvas id="driftCanvas" width="1080" height="320"
                                        style="width: 100%; height: auto; display: block;"></canvas>
                                    <div class="hint" style="margin-top: 8px; text-align: right;">
                                        * Biểu đồ hiển thị chuỗi <%= timeline !=null ? timeline.size() : 0 %> phiên đo
                                            gần nhất của thiết bị để phát hiện xu hướng trôi cảm biến (Sensor Drift).
                                    </div>
                                </div>

                                <!-- THÔNG TIN CHI TIẾT & LỊCH SỬ THAY ĐỔI -->
                                <div class="info-grid">
                                    <!-- BẢNG CHI TIẾT THÔNG SỐ -->
                                    <div class="info-panel">
                                        <h3>📋 Thông số kỹ thuật phiên đo</h3>
                                        <div class="info-row">
                                            <span class="info-label">Mã phiên đo</span>
                                            <span class="info-val">#<%= item.getSessionId() %></span>
                                        </div>
                                        <div class="info-row">
                                            <span class="info-label">Sequence No</span>
                                            <span class="info-val">
                                                <%= item.getDeviceSeq() %>
                                            </span>
                                        </div>
                                        <div class="info-row">
                                            <span class="info-label">Thời điểm đo</span>
                                            <span class="info-val">
                                                <%= item.getMeasuredAt() !=null ? item.getMeasuredAt() : "–" %>
                                            </span>
                                        </div>
                                        <div class="info-row">
                                            <span class="info-label">Thời điểm nạp </span>
                                            <span class="info-val">
                                                <%= item.getIngestedAt() !=null ? item.getIngestedAt() : "–" %>
                                            </span>
                                        </div>
                                        <div class="info-row">
                                            <span class="info-label">Cảm biến sấy nóng</span>
                                            <span class="info-val">
                                                <%= item.isWarm() ? "Đã làm nóng (Yes)" : "Chưa (No)" %>
                                            </span>
                                        </div>
                                        <div class="info-row">
                                            <span class="info-label">Nguồn dữ liệu</span>
                                            <span class="info-val">
                                                <%= item.isSample() ? "Dữ liệu mẫu (Seeded UCI)"
                                                    : "Thiết bị gửi trực tiếp (Live)" %>
                                            </span>
                                        </div>
                                        <div class="info-row">
                                            <span class="info-label">Thiết bị đo</span>
                                            <span class="info-val">
                                                <%= device !=null ? Web.esc(device.getDeviceCode()) : "ID #" +
                                                    item.getDeviceId() %>
                                            </span>
                                        </div>
                                        <div class="info-row">
                                            <span class="info-label">Vị trí trạm / phòng</span>
                                            <span class="info-val">
                                                <%= device !=null && device.getLocation() !=null ?
                                                    Web.esc(device.getLocation()) : "Chưa xác định" %>
                                            </span>
                                        </div>
                                    </div>

                                    <!-- BẢNG LỊCH SỬ ĐỔI NHÃN -->
                                    <div class="info-panel">
                                        <h3>📜 Lịch sử gán & sửa nhãn (Audit Trail)</h3>
                                        <% if (labelHistory !=null && !labelHistory.isEmpty()) { %>
                                            <table class="grid" style="font-size: 13px;">
                                                <thead>
                                                    <tr>
                                                        <th>Nhãn</th>
                                                        <th>Nguồn</th>
                                                        <th>Lý do</th>
                                                        <th>Người thực hiện</th>
                                                        <th>Thời gian</th>
                                                    </tr>
                                                </thead>
                                                <tbody>
                                                    <% 
                                                        for (AirLabel al : labelHistory) { 
                                                            String r = al.getReason(); 
                                                            if (r != null) { 
                                                                if (r.contains("----------------")) {
                                                                    r = r.split("----------------")[0]; 
                                                                } 
                                                                r = r.replaceFirst("^\\[[^\\]]+\\]\\s*", ""); 
                                                                r = r.replace("\r", "").replace("\n", " ").trim(); 
                                                                r = r.replaceAll("[-=]+$", "").trim(); 
                                                            } 
                                                    %>
                                                        <tr>
                                                            <td><span class="tag">
                                                                    <%= Web.esc(al.getLabelCode()) %>
                                                                </span></td>
                                                            <td><code><%= Web.esc(al.getSource()) %></code></td>
                                                            <td>
                                                                <%= (r !=null && !r.isEmpty()) ? Web.esc(r) : "–" %>
                                                            </td>
                                                            <td>
                                                                <%= al.getUsername() !=null ? Web.esc(al.getUsername())
                                                                    : "Hệ thống" %>
                                                            </td>
                                                            <td class="muted">
                                                                <%= al.getLabeledAt() !=null ? al.getLabeledAt() : "–"
                                                                    %>
                                                            </td>
                                                        </tr>
                                                        <% } %>
                                                </tbody>
                                            </table>
                                            <% } else { %>
                                                <p class="muted">Chưa có bản ghi nhãn nào trong bảng Air_Label cho phiên
                                                    đo này.</p>
                                                <% } %>

                                                    <% if (item.getNote() !=null && !item.getNote().trim().isEmpty()) {
                                                        %>
                                                        <h4 style="margin: 14px 0 6px; font-size: 13px; color: #555;">
                                                            Ghi chú lịch sử phiên:</h4>
                                                        <div
                                                            style="background: #fcfcfc; border: 1px solid #e5e5e5; border-radius: 4px; padding: 10px; font-size: 12px; white-space: pre-wrap; max-height: 160px; overflow-y: auto;">
                                                            <%= Web.esc(item.getNote()) %>
                                                        </div>
                                                        <% } %>
                                    </div>
                                </div>
                            </div>

                            <!-- SCRIPT VẼ BIỂU ĐỒ BẰNG CANVAS (VANILLA JS THUẦN TÚY, CHẠY OFFLINE) -->
                            <script>
                                (function () {
                                    // Dữ liệu dòng thời gian từ servlet
                                    var data = [
        <% 
            if (timeline != null && !timeline.isEmpty()) {
                                        for (int i = 0; i < timeline.size(); i++) {
                    AirSession s = timeline.get(i);
                    String timeStr = s.getMeasuredAt() != null ? s.getMeasuredAt().toString() : "";
                                            if (timeStr.length() >= 16) {
                                                timeStr = timeStr.substring(11, 16); // Lấy HH:mm
                                            }
        %>
                                                {
                                                    id: <%= s.getSessionId() %>,
                                                    time: "<%= timeStr %>",
                                                    gasRaw: <%= s.getGasARaw() %>,
                                                    gasBase: <%= s.getGasABase() %>,
                                                    shift: <%= s.getBaseShift() %>,
                                                    label: "<%= s.getLabelCode() != null ? s.getLabelCode() : "" %>",
                                                    isCurrent: <%= (s.getSessionId() == item.getSessionId()) %>
        }<%= (i < timeline.size() - 1 ? "," : "") %>
        <% 
                }
                                } else {
        %>
                                    {
                                        id: <%= item.getSessionId() %>,
                                        time: "Hiện tại",
                                        gasRaw: <%= item.getGasARaw() %>,
                                        gasBase: <%= item.getGasABase() %>,
                                        shift: <%= item.getBaseShift() %>,
                                        label: "<%= lbl %>",
                                        isCurrent: true
                                    }
                                        <% } %>
    ];

                                var canvas = document.getElementById('driftCanvas');
                                if (!canvas) return;
                                var ctx = canvas.getContext('2d');
                                var w = canvas.width;
                                var h = canvas.height;

                                // Khoảng đệm biểu đồ
                                var padLeft = 60;
                                var padRight = 40;
                                var padTop = 35;
                                var padBottom = 45;

                                // Tìm giá trị min/max của Gas A Raw và Gas A Base để scale trục Y
                                var minVal = 999999;
                                var maxVal = -999999;

                                data.forEach(function (d) {
                                    if (d.gasRaw < minVal) minVal = d.gasRaw;
                                    if (d.gasRaw > maxVal) maxVal = d.gasRaw;
                                    if (d.gasBase < minVal) minVal = d.gasBase;
                                    if (d.gasBase > maxVal) maxVal = d.gasBase;
                                });

                                if (minVal === maxVal) {
                                    minVal -= 50;
                                    maxVal += 50;
                                }

                                // Thêm biên độ 15% để đồ thị đẹp mắt không bị dính sát lề
                                var range = maxVal - minVal;
                                minVal = Math.floor(Math.max(0, minVal - range * 0.15));
                                maxVal = Math.ceil(maxVal + range * 0.15);

                                // Xóa nền
                                ctx.clearRect(0, 0, w, h);

                                // Vẽ lưới tọa độ ngang
                                var gridSteps = 5;
                                ctx.font = '11px Segoe UI, Arial, sans-serif';
                                ctx.textAlign = 'right';
                                ctx.textBaseline = 'middle';

                                for (var i = 0; i <= gridSteps; i++) {
                                    var yVal = Math.round(minVal + (maxVal - minVal) * (i / gridSteps));
                                    var yPos = (h - padBottom) - (i / gridSteps) * (h - padTop - padBottom);

                                    ctx.strokeStyle = '#eef0f4';
                                    ctx.lineWidth = 1;
                                    ctx.beginPath();
                                    ctx.moveTo(padLeft, yPos);
                                    ctx.lineTo(w - padRight, yPos);
                                    ctx.stroke();

                                    ctx.fillStyle = '#6b7280';
                                    ctx.fillText(yVal, padLeft - 10, yPos);
                                }

                                // Tính tọa độ X, Y cho từng điểm
                                var numPoints = data.length;
                                var stepX = (w - padLeft - padRight) / Math.max(1, numPoints - 1);

                                function getY(val) {
                                    return (h - padBottom) - ((val - minVal) / (maxVal - minVal)) * (h - padTop - padBottom);
                                }
                                function getX(index) {
                                    return numPoints === 1 ? (padLeft + (w - padLeft - padRight) / 2) : (padLeft + index * stepX);
                                }

                                // 1. VẼ ĐƯỜNG MỨC NỀN (GAS BASE - ĐƯỜNG NÉT ĐỨT CAM/XÁM)
                                ctx.strokeStyle = '#e07a5f';
                                ctx.lineWidth = 2;
                                ctx.setLineDash([5, 4]);
                                ctx.beginPath();
                                for (var j = 0; j < numPoints; j++) {
                                    var px = getX(j);
                                    var py = getY(data[j].gasBase);
                                    if (j === 0) ctx.moveTo(px, py);
                                    else ctx.lineTo(px, py);
                                }
                                ctx.stroke();
                                ctx.setLineDash([]); // Bỏ nét đứt

                                // 2. VẼ VÙNG ĐỔ BÓNG DƯỚI ĐƯỜNG GAS RAW (GRADIENT FILL)
                                var grad = ctx.createLinearGradient(0, padTop, 0, h - padBottom);
                                grad.addColorStop(0, 'rgba(43, 92, 184, 0.22)');
                                grad.addColorStop(1, 'rgba(43, 92, 184, 0.01)');

                                ctx.fillStyle = grad;
                                ctx.beginPath();
                                ctx.moveTo(getX(0), h - padBottom);
                                for (var k = 0; k < numPoints; k++) {
                                    ctx.lineTo(getX(k), getY(data[k].gasRaw));
                                }
                                ctx.lineTo(getX(numPoints - 1), h - padBottom);
                                ctx.closePath();
                                ctx.fill();

                                // 3. VẼ ĐƯỜNG TÍN HIỆU CẢM BIẾN (GAS A RAW - ĐƯỜNG XANH DƯƠNG ĐẬM)
                                ctx.strokeStyle = '#2b5cb8';
                                ctx.lineWidth = 2.5;
                                ctx.beginPath();
                                for (var m = 0; m < numPoints; m++) {
                                    var mx = getX(m);
                                    var my = getY(data[m].gasRaw);
                                    if (m === 0) ctx.moveTo(mx, my);
                                    else ctx.lineTo(mx, my);
                                }
                                ctx.stroke();

                                // 4. VẼ CÁC ĐIỂM DỮ LIỆU & NHÃN TRỤC X
                                ctx.textAlign = 'center';
                                ctx.textBaseline = 'top';

                                for (var n = 0; n < numPoints; n++) {
                                    var pt = data[n];
                                    var nx = getX(n);
                                    var ny = getY(pt.gasRaw);

                                    // Nhãn thời gian trục X
                                    ctx.fillStyle = pt.isCurrent ? '#b91c1c' : '#6b7280';
                                    ctx.font = pt.isCurrent ? 'bold 11px Segoe UI, Arial' : '11px Segoe UI, Arial';
                                    ctx.fillText(pt.time || ('#' + pt.id), nx, h - padBottom + 10);

                                    if (pt.isCurrent) {
                                        // NỔI BẬT ĐIỂM ĐO HIỆN TẠI (HIỆN VÒNG TRÒN ĐỎ VÀ GIÁ TRỊ)
                                        // Đường dóng thẳng đứng
                                        ctx.strokeStyle = 'rgba(217, 83, 79, 0.5)';
                                        ctx.lineWidth = 1.5;
                                        ctx.setLineDash([3, 3]);
                                        ctx.beginPath();
                                        ctx.moveTo(nx, padTop);
                                        ctx.lineTo(nx, h - padBottom);
                                        ctx.stroke();
                                        ctx.setLineDash([]);

                                        // Vòng tròn hào quang
                                        ctx.fillStyle = 'rgba(217, 83, 79, 0.2)';
                                        ctx.beginPath();
                                        ctx.arc(nx, ny, 11, 0, Math.PI * 2);
                                        ctx.fill();

                                        // Điểm đỏ tâm
                                        ctx.fillStyle = '#d9534f';
                                        ctx.beginPath();
                                        ctx.arc(nx, ny, 5.5, 0, Math.PI * 2);
                                        ctx.fill();
                                        ctx.strokeStyle = '#fff';
                                        ctx.lineWidth = 2;
                                        ctx.stroke();

                                        // Nhãn giá trị nổi bật trên đỉnh
                                        ctx.fillStyle = '#d9534f';
                                        ctx.font = 'bold 12px Segoe UI, Arial';
                                        ctx.textBaseline = 'bottom';
                                        ctx.fillText(pt.gasRaw + ' (Đang xem)', nx, ny - 10);
                                        ctx.textBaseline = 'top';
                                    } else {
                                        // Điểm dữ liệu thông thường
                                        ctx.fillStyle = '#2b5cb8';
                                        ctx.beginPath();
                                        ctx.arc(nx, ny, 3.5, 0, Math.PI * 2);
                                        ctx.fill();
                                        ctx.strokeStyle = '#fff';
                                        ctx.lineWidth = 1.5;
                                        ctx.stroke();
                                    }
                                }
}) ();
                            </script>
                        </body>

                        </html>
