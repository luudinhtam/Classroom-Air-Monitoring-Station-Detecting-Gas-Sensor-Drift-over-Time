<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="model.AppUser, model.DashboardStats, model.Room, util.Web, java.util.List, java.util.ArrayList" %>
<%
    String ctx = request.getContextPath();
    DashboardStats stats = (DashboardStats) request.getAttribute("stats");
    if (stats == null) stats = new DashboardStats();

    List<Room> roomList = (List<Room>) request.getAttribute("roomList");
    if (roomList == null) roomList = (List<Room>) request.getAttribute("stationList");
    if (roomList == null) roomList = new ArrayList<>();

    // Kiểm tra quyền chỉnh sửa tọa độ (ADMIN hoặc STATION_MANAGER)
    AppUser me = (AppUser) session.getAttribute("user");
    String myRole = (me != null) ? me.getRoleCode() : "";
    boolean canEditCoords = "ADMIN".equals(myRole) || "STATION_MANAGER".equals(myRole);

    double defLat = 10.841129;
    double defLng = 106.809883;

    int gasRaw = stats.getLatestGasARaw();
    int gasBase = stats.getLatestGasABase();
    int delta = gasRaw - gasBase;

    // Xác định màu trạng thái phòng theo độ lệch (drift / warning)
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

    <style>
        /* Modal chỉnh sửa tọa độ */
        .coord-modal-backdrop {
            display: none;
            position: fixed;
            top: 0; left: 0; width: 100vw; height: 100vh;
            background: rgba(15, 23, 42, 0.6);
            backdrop-filter: blur(2px);
            z-index: 2000;
            justify-content: center;
            align-items: center;
        }
        .coord-modal {
            background: #ffffff;
            border-radius: 12px;
            padding: 24px;
            width: 380px;
            box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.2);
            animation: modalFadeIn 0.2s ease-out;
        }
        @keyframes modalFadeIn {
            from { opacity: 0; transform: scale(0.95); }
            to { opacity: 1; transform: scale(1); }
        }
        .coord-modal h3 {
            margin: 0 0 6px 0;
            font-size: 18px;
            color: #0f172a;
        }
        .coord-modal p {
            font-size: 13px;
            color: #64748b;
            margin: 0 0 16px 0;
        }
        .coord-modal label {
            display: block;
            font-size: 13px;
            font-weight: 600;
            color: #334155;
            margin-bottom: 4px;
        }
        .coord-modal input[type="number"], .coord-modal input[type="text"] {
            width: 100%;
            padding: 8px 12px;
            border: 1px solid #cbd5e1;
            border-radius: 6px;
            font-size: 14px;
            box-sizing: border-box;
            margin-bottom: 12px;
        }
        .coord-modal input:focus {
            outline: none;
            border-color: #2563eb;
            box-shadow: 0 0 0 3px rgba(37, 99, 235, 0.15);
        }
        .coord-modal-actions {
            display: flex;
            justify-content: flex-end;
            gap: 8px;
            margin-top: 8px;
        }
        .coord-btn-cancel {
            padding: 8px 14px;
            background: #f1f5f9;
            color: #475569;
            border: none;
            border-radius: 6px;
            font-weight: 600;
            cursor: pointer;
        }
        .coord-btn-cancel:hover {
            background: #e2e8f0;
        }
        .coord-btn-save {
            padding: 8px 16px;
            background: #2563eb;
            color: #ffffff;
            border: none;
            border-radius: 6px;
            font-weight: 600;
            cursor: pointer;
        }
        .coord-btn-save:hover {
            background: #1d4ed8;
        }
    </style>
</head>
<body>

<jsp:include page="/WEB-INF/views/nav.jsp"/>

<div id="map-container">
    <div id="map"></div>

    <!-- 1. Floating Chart Widget (Góc trái trên) -->
    <div class="chart-widget" id="chartWidget" style="display: none;">
        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px;">
            <span style="font-weight: 600; font-size: 14px; color: #1e293b;">Gas Drift Monitoring</span>
            <button id="closeChartBtn" style="background: none; border: none; font-size: 16px; cursor: pointer; color: #64748b;">&times;</button>
        </div>
        <canvas id="driftChart" height="150"></canvas>
    </div>

    <!-- 2. Floating Station Card (Góc phải trên) -->
    <div class="station-card room-card" id="stationCard" style="display: none;">
        <h3 id="cardName" style="margin: 0 0 4px 0; font-size: 16px; color: #0f172a;">Room Details</h3>
        <p id="cardLocation" style="margin: 0 0 8px 0; font-size: 13px; color: #64748b;">📍 Loading location...</p>
        <p id="cardCoords" style="margin: 0 0 12px 0; font-size: 11px; color: #2563eb; font-weight: 600;">📍 Tọa độ GPS</p>

        <div style="border-top: 1px solid #e2e8f0; padding-top: 8px; margin-bottom: 12px;">
            <div style="display: flex; justify-content: space-between; font-size: 13px; margin-bottom: 4px;">
                <span style="color: #64748b;">Gas A Raw:</span>
                <span style="font-weight: 600;" id="cardRaw"><%= gasRaw %></span>
            </div>
            <div style="display: flex; justify-content: space-between; font-size: 13px; margin-bottom: 4px;">
                <span style="color: #64748b;">Baseline:</span>
                <span style="font-weight: 600;" id="cardBase"><%= gasBase %></span>
            </div>
            <div style="display: flex; justify-content: space-between; font-size: 13px;">
                <span style="color: #64748b;">Baseline Delta:</span>
                <span style="font-weight: 600; color: <%= statusColor %>;" id="cardDelta"><%= delta %></span>
            </div>
        </div>

        <a href="<%= ctx %>/dashboard" class="btn" style="display: block; width: 100%; text-align: center; font-size: 13px; margin-bottom: 6px;">
            View Detailed Dashboard
        </a>
        
        <% if (canEditCoords) { %>
        <!-- Nút sửa tọa độ cho Admin / Station Manager -->
        <button type="button" id="btnEditCoords" onclick="openCoordModal()" class="btn" style="display: block; width: 100%; text-align: center; font-size: 13px; background: #2563eb; color: #ffffff; border: none; cursor: pointer; padding: 8px 0; border-radius: 4px; font-weight: 600;">
            ✏️ Change Coordinates
        </button>
        <% } %>
    </div>
</div>

<!-- Modal Popup nhập tọa độ thủ công -->
<div class="coord-modal-backdrop" id="coordModalBackdrop">
    <div class="coord-modal">
        <h3>✏️ Chỉnh sửa tọa độ phòng</h3>
        <p id="modalRoomSubtitle">Cập nhật vị trí tọa độ GPS trên bản đồ</p>
        
        <input type="hidden" id="modalRoomId" value="0">
        
        <label for="modalLat">Latitude (Vĩ độ)</label>
        <input type="number" step="any" id="modalLat" placeholder="vd: 10.841129">
        
        <label for="modalLng">Longitude (Kinh độ)</label>
        <input type="number" step="any" id="modalLng" placeholder="vd: 106.809883">
        
        <div class="coord-modal-actions">
            <button type="button" class="coord-btn-cancel" onclick="closeCoordModal()">Hủy</button>
            <button type="button" class="coord-btn-save" id="btnSaveModalCoords" onclick="submitModalCoords()">Lưu tọa độ</button>
        </div>
    </div>
</div>

<script>
    // 1. Tọa độ khuôn viên Đại học FPT TP.HCM
    var defLat = <%= defLat %>;
    var defLng = <%= defLng %>;
    var canEditCoords = <%= canEditCoords %>;

    // 2. Khởi tạo Leaflet Map
    var map = L.map('map', {
        center: [defLat, defLng],
        zoom: 18,
        minZoom: 15,
        maxZoom: 18
    });

    // 3. Tile layer từ OpenStreetMap
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        maxZoom: 18,
        attribution: '&copy; OpenStreetMap contributors'
    }).addTo(map);

    var chartWidget = document.getElementById('chartWidget');
    var stationCard  = document.getElementById('stationCard');
    var closeBtn     = document.getElementById('closeChartBtn');

    // Biến lưu thông tin phòng đang được chọn
    var selectedRoom = null;
    var roomMarkers = {};

    // 4. Render markers từ database
    <% if (roomList.isEmpty()) { %>

        // Không có phòng nào → hiện marker demo tại trung tâm FPT
        var demoMarker = L.circleMarker([defLat, defLng], {
            radius: 16, fillColor: '<%= statusColor %>', color: '#ffffff', weight: 3, fillOpacity: 0.9
        }).addTo(map);
        demoMarker.bindPopup(
            '<div style="font-family:sans-serif">' +
            '<b style="font-size:14px">FPTU HCM Room</b><br>' +
            '<span>Gas A Raw: <b><%= gasRaw %></b></span><br>' +
            '<span>Baseline: <b><%= gasBase %></b> (Delta: <%= delta %>)</span><br>' +
            '<span>Status: <span style="color:<%= statusColor %>;font-weight:bold"><%= statusText %></span></span>' +
            '</div>'
        ).openPopup();
        demoMarker.on('click', function() {
            chartWidget.style.display = 'block';
            stationCard.style.display = 'block';
            document.getElementById('cardName').textContent = 'FPT University HCMC Room';
            document.getElementById('cardLocation').textContent = '📍 Khu Công Nghệ Cao, TP. Thủ Đức';
            document.getElementById('cardCoords').textContent = '📍 Tọa độ: ' + defLat.toFixed(6) + ', ' + defLng.toFixed(6);
            selectedRoom = { id: 0, name: 'FPTU HCM Room', lat: defLat, lng: defLng };
        });

    <% } else {
           for (Room r : roomList) {
               if (r.getLatitude() == null || r.getLongitude() == null) continue;
               double lat = r.getLatitude();
               double lng = r.getLongitude();
               String rName = Web.esc(r.getName());
               String rLoc  = Web.esc(r.getLocation() != null ? r.getLocation() : "");
               String rCode = Web.esc(r.getCode());
               int rId = r.getRoomId();
    %>

        (function() {
            var rmObj = {
                id: <%= rId %>,
                name: '<%= rName %>',
                code: '<%= rCode %>',
                location: '<%= rLoc %>',
                lat: <%= lat %>,
                lng: <%= lng %>
            };

            var m = L.circleMarker([<%= lat %>, <%= lng %>], {
                radius: 16, fillColor: '<%= statusColor %>', color: '#ffffff', weight: 3, fillOpacity: 0.9
            }).addTo(map);

            roomMarkers[<%= rId %>] = m;

            function updatePopupContent(obj) {
                return '<div style="font-family:sans-serif; min-width: 170px;">' +
                       '<b style="font-size:14px">' + obj.name + '</b><br>' +
                       '<span style="font-size:12px;color:#475569">Code: <b>' + obj.code + '</b></span><br>' +
                       '<span style="font-size:12px;color:#475569">Location: ' + obj.location + '</span><br>' +
                       '<span style="font-size:11px;color:#2563eb;">📍 ' + obj.lat.toFixed(6) + ', ' + obj.lng.toFixed(6) + '</span>' +
                       '</div>';
            }

            m.bindPopup(updatePopupContent(rmObj));

            m.on('click', function() {
                chartWidget.style.display = 'block';
                stationCard.style.display = 'block';
                document.getElementById('cardName').textContent = rmObj.name;
                document.getElementById('cardLocation').textContent = '📍 ' + rmObj.location;
                document.getElementById('cardCoords').textContent = '📍 Tọa độ: ' + rmObj.lat.toFixed(6) + ', ' + rmObj.lng.toFixed(6);
                selectedRoom = rmObj;
            });
        })();

    <%     }
       } %>

    // 5. Xử lý Modal Chỉnh sửa tọa độ thủ công
    function openCoordModal() {
        if (!selectedRoom) {
            alert('Vui lòng click chọn một phòng trên bản đồ trước!');
            return;
        }
        document.getElementById('modalRoomId').value = selectedRoom.id;
        document.getElementById('modalRoomSubtitle').textContent = 'Phòng: ' + selectedRoom.name + ' (' + (selectedRoom.code || '') + ')';
        document.getElementById('modalLat').value = selectedRoom.lat;
        document.getElementById('modalLng').value = selectedRoom.lng;
        document.getElementById('coordModalBackdrop').style.display = 'flex';
    }

    function closeCoordModal() {
        document.getElementById('coordModalBackdrop').style.display = 'none';
    }

    function submitModalCoords() {
        var id = parseInt(document.getElementById('modalRoomId').value, 10);
        var lat = parseFloat(document.getElementById('modalLat').value);
        var lng = parseFloat(document.getElementById('modalLng').value);

        if (isNaN(lat) || isNaN(lng)) {
            alert('Vui lòng nhập đúng định dạng số cho Latitude và Longitude!');
            return;
        }

        if (id === 0) {
            alert('Đây là phòng dữ liệu mẫu, vui lòng thêm phòng thật trước khi sửa tọa độ!');
            return;
        }

        var btnSave = document.getElementById('btnSaveModalCoords');
        btnSave.disabled = true;
        btnSave.textContent = 'Đang lưu...';

        fetch('<%= ctx %>/admin/rooms/update-coords', {
            method: 'POST',
            headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
            body: 'roomId=' + encodeURIComponent(id) + 
                  '&lat=' + encodeURIComponent(lat) + 
                  '&lng=' + encodeURIComponent(lng)
        })
        .then(function(res) { return res.json(); })
        .then(function(data) {
            btnSave.disabled = false;
            btnSave.textContent = 'Lưu tọa độ';

            if (data && data.success) {
                alert('✅ Cập nhật tọa độ thành công!');
                closeCoordModal();

                // Cập nhật lại đối tượng đang chọn
                selectedRoom.lat = lat;
                selectedRoom.lng = lng;

                // Cập nhật lại text trên Card
                document.getElementById('cardCoords').textContent = '📍 Tọa độ: ' + lat.toFixed(6) + ', ' + lng.toFixed(6);

                // Di chuyển marker tới vị trí mới trên bản đồ
                var marker = roomMarkers[id];
                if (marker) {
                    marker.setLatLng([lat, lng]);
                    map.panTo([lat, lng]);
                    marker.setPopupContent(
                        '<div style="font-family:sans-serif; min-width: 170px;">' +
                        '<b style="font-size:14px">' + selectedRoom.name + '</b><br>' +
                        '<span style="font-size:12px;color:#475569">Code: <b>' + selectedRoom.code + '</b></span><br>' +
                        '<span style="font-size:12px;color:#475569">Location: ' + selectedRoom.location + '</span><br>' +
                        '<span style="font-size:11px;color:#2563eb;">📍 ' + lat.toFixed(6) + ', ' + lng.toFixed(6) + '</span>' +
                        '</div>'
                    );
                }
            } else {
                alert('❌ Lưu tọa độ thất bại: ' + (data && data.error ? data.error : 'Lỗi không xác định'));
            }
        })
        .catch(function(err) {
            btnSave.disabled = false;
            btnSave.textContent = 'Lưu tọa độ';
            alert('❌ Lỗi kết nối tới máy chủ: ' + err.message);
        });
    }

    // Đóng modal khi bấm ra ngoài vùng trắng
    document.getElementById('coordModalBackdrop').addEventListener('click', function(e) {
        if (e.target === this) {
            closeCoordModal();
        }
    });

    // 6. Khởi tạo biểu đồ đường thời gian thực (Chart.js)
    var chartCanvas = document.getElementById('driftChart');
    if (chartCanvas) {
        var chartCtx = chartCanvas.getContext('2d');
        new Chart(chartCtx, {
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
                scales: { y: { beginAtZero: true } }
            }
        });
    }

    // 7. Xử lý đóng/mở widget
    closeBtn.addEventListener('click', function(e) {
        e.stopPropagation();
        chartWidget.style.display = 'none';
    });

    map.on('click', function() {
        stationCard.style.display = 'none';
    });

    stationCard.addEventListener('click', function(e) {
        e.stopPropagation();
    });
</script>
</body>
</html>
