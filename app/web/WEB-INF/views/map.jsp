<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="model.AppUser, model.DashboardStats" %>
<%
    String ctx = request.getContextPath();
    DashboardStats stats = (DashboardStats) request.getAttribute("stats");
    if (stats == null) stats = new DashboardStats();

    int gasRaw = stats.getLatestGasARaw();
    int gasBase = stats.getLatestGasABase();
    int delta = gasRaw - gasBase;

    // Xác định màu trạng thái trạm theo độ lệch (drift / warning)
    String statusColor = "#10b981"; // Xanh (Tốt)
    String statusText = "Good - Normal Baseline";
    if (delta > 50) {
        statusColor = "#ef4444"; // Đỏ (Drift nặng / Ô nhiễm)
        statusText = "Warning - Significant Drift";
    } else if (delta > 20) {
        statusColor = "#f59e0b"; // Vàng (Cảnh báo nhẹ)
        statusText = "Moderate - Slight Shift";
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Air Quality Map</title>
    <link rel="stylesheet" href="<%= ctx %>/assets/css/app.css">
    <link rel="shortcut icon" href="<%= ctx %>/favicon.ico" type="image/x-icon">
    
    <!-- 1. Thư viện Leaflet CSS & JS -->
    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
    <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
    
    <!-- 2. Thư viện Chart.js vẽ biểu đồ -->
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>

    <link rel="stylesheet" href="<%= ctx %>/assets/css/map.css">
</head>
<body>
<jsp:include page="/WEB-INF/views/nav.jsp"/>

<div id="map-container">
    <!-- Bản đồ -->
    <div id="map"></div>

        <!-- Widget biểu đồ bên trái -->
    <div class="chart-widget" id="chartWidget">
        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 10px;">
            <h4 style="margin: 0; font-size: 14px; color: #1e293b;">
                📈 Real-Time Sensor Telemetry (FPTU HCM)
            </h4>
            <button type="button" id="closeChartBtn" style="
                background: none;
                border: none;
                font-size: 20px;
                color: #64748b;
                cursor: pointer;
                line-height: 1;
                padding: 0 4px;
            " title="Close">&times;</button>
        </div>
        <canvas id="driftChart" height="200"></canvas>
    </div>

    <!-- Card thông tin trạm bên phải -->
    <div class="station-card" id="stationCard" style="display: none;">
        <div style="font-size: 12px; color: #64748b; text-transform: uppercase; font-weight: 700;">Air Station</div>
        <h3 style="margin: 4px 0 8px; color: #0f172a;">FPT University HCMC Station </h3>
        <p style="margin: 0 0 6px; font-size: 13px; color: #475569;">📍 Khu Công Nghệ Cao, TP. Thủ Đức</p>
        <div style="margin: 12px 0; padding: 8px; background: #f8fafc; border-radius: 6px;">
            <div style="font-size: 12px; color: #64748b;">Air Quality:</div>
            <div style="font-size: 24px; font-weight: 700; color: <%= statusColor %>;"><%= gasRaw %></div>
            <div style="font-size: 12px; color: #64748b;">Status: <b><%= statusText %></b></div>
        </div>
        <a href="<%= ctx %>/sessions" class="btn" style="display: block; text-align: center; font-size: 13px;">Lookup details</a>
    </div>
</div>

<script>
    // 1. Tọa độ khuôn viên Đại học FPT TP.HCM
    const fptLat = 10.841129;
    const fptLng = 106.809883;

            // 2. Khởi tạo Leaflet Map (cho phép zoom sâu tới mức 20)
       // 2. Khởi tạo Leaflet Map: Đặt maxZoom là 18 (mức chi tiết và nét nhất của khuôn viên FPT)
    const map = L.map('map', {
        center: [fptLat, fptLng],
        zoom: 18,
        minZoom: 15,
        maxZoom: 18
    });

    // 3. Tile layer từ OpenStreetMap
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        maxZoom: 18,
        attribution: '&copy; OpenStreetMap contributors'
    }).addTo(map);
       

    // 4. Marker tròn tại vị trí trạm (tự đổi màu theo biến Java statusColor)
    const marker = L.circleMarker([fptLat, fptLng], {
        radius: 16,
        fillColor: '<%= statusColor %>',
        color: '#ffffff',
        weight: 3,
        fillOpacity: 0.9
    }).addTo(map);

    marker.bindPopup(`
        <div style="font-family: sans-serif;">
            <b style="font-size: 14px;">FPTU HCM Station</b><br>
            <span>Gas A Raw: <b><%= gasRaw %></b></span><br>
            <span>Baseline: <b><%= gasBase %></b> (Delta: <%= delta %>)</span><br>
            <span>Status: <span style="color:<%= statusColor %>; font-weight:bold;"><%= statusText %></span></span>
        </div>
    `).openPopup();

    // 5. Khởi tạo biểu đồ đường thời gian thực (Chart.js)
    const ctx = document.getElementById('driftChart').getContext('2d');
    new Chart(ctx, {
        type: 'line',
        data: {
            labels: ['10m', '8m', '6m', '4m', '2m', 'current'],
            datasets: [{
                label: 'Gas A Delta',
                data: [<%= delta - 4 %>, <%= delta - 2 %>, <%= delta - 5 %>, <%= delta - 1 %>, <%= delta + 2 %>, <%= delta %>],
                borderColor: '<%= statusColor %>',
                backgroundColor: '<%= statusColor %>22',
                fill: true,
                tension: 0.3
            }]
        },
        options: {
            responsive: true,
            plugins: { legend: { display: false } },
            scales: {
                y: { beginAtZero: true }
            }
        }
    });
    
        // XỬ LÝ ĐÓNG / MỞ BẢNG BIỂU ĐỒ BÊN TRÁI
        // XỬ LÝ ĐÓNG / MỞ BIỂU ĐỒ VÀ CARD THÔNG TIN
    const chartWidget = document.getElementById('chartWidget');
    const closeBtn = document.getElementById('closeChartBtn');
    const stationCard = document.getElementById('stationCard');

    // 1. Bấm nút [x] ở biểu đồ -> Ẩn biểu đồ
    closeBtn.addEventListener('click', function(e) {
        e.stopPropagation();
        chartWidget.style.display = 'none';
    });

    // 2. Bấm vào chấm tròn trạm trên map -> Hiển thị cả biểu đồ và card thông tin
    marker.on('click', function() {
        chartWidget.style.display = 'block';
        stationCard.style.display = 'block';
    });

    // 3. Bấm ra vùng khác ngoài bản đồ -> Tự động ẩn card bên phải
    map.on('click', function() {
        stationCard.style.display = 'none';
    });

    // Ngăn sự kiện click bên trong card làm tắt card
    stationCard.addEventListener('click', function(e) {
        e.stopPropagation();
    });
    
</script>
</body>
</html>
