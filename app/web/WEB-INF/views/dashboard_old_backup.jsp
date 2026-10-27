<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.*, model.AppUser, model.DashboardStats, model.ClassroomTempInfo, util.Web" %>
<%
    AppUser me = (AppUser) session.getAttribute("user");
    String ctx = request.getContextPath();
    DashboardStats stats = (DashboardStats) request.getAttribute("stats");
    if (stats == null) stats = new DashboardStats();

    List<ClassroomTempInfo> classroomList = (List<ClassroomTempInfo>) request.getAttribute("classroomList");
    if (classroomList == null) classroomList = new ArrayList<>();

    String role = (me != null) ? me.getRoleCode() : "";
    boolean isAdmin = "ADMIN".equals(role);
%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Classroom Temp – Monitoring System</title>
    <link rel="shortcut icon" href="<%= ctx %>/favicon.ico" type="image/x-icon">
    <!-- Google Fonts: Be Vietnam Pro -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Be+Vietnam+Pro:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="<%= ctx %>/style.css">
    <style>
        /* CSS hỗ trợ đồng bộ hiển thị và dropdown user */
        .user-dropdown-menu {
            display: none;
            position: absolute;
            top: 50px;
            right: 0;
            background: #ffffff;
            border: 1px solid var(--border-light);
            border-radius: var(--radius-md);
            box-shadow: var(--shadow-card-hover);
            min-width: 150px;
            padding: 6px 0;
            z-index: 200;
        }
        .user-dropdown-menu.show {
            display: block;
        }
        .user-dropdown-item {
            display: block;
            padding: 8px 16px;
            font-size: 13px;
            color: var(--text-primary);
            text-decoration: none;
            transition: background 0.2s ease;
        }
        .user-dropdown-item:hover {
            background: #f1f5f9;
            color: var(--primary-blue);
        }
        .user-dropdown-item.logout {
            color: var(--status-red);
            border-top: 1px solid var(--border-light);
        }
    </style>
</head>
<body>

    <!-- 1. SIDEBAR CỐ ĐỊNH BÊN TRÁI -->
    <aside class="sidebar">
        <!-- Logo thương hiệu -->
        <div class="sidebar-logo">
            <div class="logo-icon">
                <!-- SVG Icon Nhiệt kế -->
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#2563eb" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <path d="M14 14.76V3.5a2.5 2.5 0 0 0-5 0v11.26a4.5 4.5 0 1 0 5 0z"/>
                    <circle cx="11.5" cy="17.5" r="1.5" fill="#2563eb"/>
                </svg>
            </div>
            <div class="logo-text">
                <span class="brand-title">Classroom Temp</span>
                <span class="brand-sub">Monitoring System</span>
            </div>
        </div>

        <!-- Menu điều hướng dọc liên kết các tính năng thực tế của AirRoom -->
        <nav class="sidebar-menu">
            <a href="<%= ctx %>/dashboard" class="menu-item active" title="Danh sách phòng học">
                <!-- Icon Tòa nhà -->
                <svg class="menu-icon" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <rect x="4" y="2" width="16" height="20" rx="2" ry="2"/>
                    <path d="M9 22v-4h6v4"/>
                    <path d="M8 6h.01M16 6h.01M8 10h.01M16 10h.01M8 14h.01M16 14h.01"/>
                </svg>
                <span>Phòng học</span>
            </a>

            <a href="<%= ctx %>/sessions" class="menu-item" title="Phiên đo & Lịch sử">
                <!-- Icon Biểu đồ đường -->
                <svg class="menu-icon" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <polyline points="22 12 18 12 15 21 9 3 6 12 2 12"/>
                </svg>
                <span>Phiên đo (Sessions)</span>
            </a>

            <a href="<%= ctx %>/alerts" class="menu-item" title="Cảnh báo">
                <!-- Icon Chuông -->
                <svg class="menu-icon" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/>
                    <path d="M13.73 21a2 2 0 0 1-3.46 0"/>
                </svg>
                <span>Cảnh báo (Alerts)</span>
                <span class="sidebar-badge" id="sidebarAlertBadge"><%= stats.getOpenAlerts() %></span>
            </a>

            <a href="<%= ctx %>/map" class="menu-item" title="Bản đồ các phòng">
                <!-- Icon Ghim bản đồ -->
                <svg class="menu-icon" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"/>
                    <circle cx="12" cy="10" r="3"/>
                </svg>
                <span>Bản đồ (Map)</span>
            </a>

            <% if (isAdmin) { %>
            <a href="<%= ctx %>/admin/devices" class="menu-item" title="Quản lý thiết bị">
                <!-- Icon Thiết bị / Hardware -->
                <svg class="menu-icon" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <rect x="2" y="2" width="20" height="8" rx="2" ry="2"/>
                    <rect x="2" y="14" width="20" height="8" rx="2" ry="2"/>
                    <line x1="6" y1="6" x2="6.01" y2="6"/>
                    <line x1="6" y1="18" x2="6.01" y2="18"/>
                </svg>
                <span>Thiết bị (Devices)</span>
            </a>

            <a href="<%= ctx %>/admin/users" class="menu-item" title="Quản lý người dùng">
                <!-- Icon Người dùng -->
                <svg class="menu-icon" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/>
                    <circle cx="9" cy="7" r="4"/>
                    <path d="M23 21v-2a4 4 0 0 0-3-3.87"/>
                    <path d="M16 3.13a4 4 0 0 1 0 7.75"/>
                </svg>
                <span>Người dùng (Users)</span>
            </a>
            <% } %>

            <a href="<%= ctx %>/admin/rooms" class="menu-item" title="Cài đặt cấu hình phòng">
                <!-- Icon Bánh răng -->
                <svg class="menu-icon" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <circle cx="12" cy="12" r="3"/>
                    <path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1 0 2.83 2 2 0 0 1-2.83 0l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-2 2 2 2 0 0 1-2-2v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83 0 2 2 0 0 1 0-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1-2-2 2 2 0 0 1 2-2h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 0-2.83 2 2 0 0 1 2.83 0l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 2-2 2 2 0 0 1 2 2v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 0 2 2 0 0 1 0 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 2 2 2 2 0 0 1-2 2h-.09a1.65 1.65 0 0 0-1.51 1z"/>
                </svg>
                <span>Cài đặt phòng</span>
            </a>
        </nav>

        <!-- Trạng thái hệ thống ở chân sidebar -->
        <div class="sidebar-footer">
            <div class="status-live">
                <span class="live-dot"></span>
                <span class="live-text">Hệ thống đang hoạt động</span>
            </div>
            <div class="status-time">FPT University HCMC</div>
        </div>
    </aside>

    <!-- 2. VÙNG NỘI DUNG CHÍNH (BÊN PHẢI) -->
    <main class="main-content">
        <!-- HEADER TRANG -->
        <header class="page-header">
            <div class="header-left">
                <h1 class="page-title">Danh sách phòng học</h1>
                <p class="page-subtitle">Theo dõi nhiệt độ và môi trường các phòng học theo thời gian thực</p>
            </div>
            <div class="header-right">
                <!-- Icon Chuông thông báo dẫn về Alerts -->
                <div class="header-bell-wrapper">
                    <a href="<%= ctx %>/alerts" class="header-icon-btn" aria-label="Thông báo" title="Xem cảnh báo">
                        <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#0f1b3d" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                            <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/>
                            <path d="M13.73 21a2 2 0 0 1-3.46 0"/>
                        </svg>
                        <span class="bell-badge" id="headerBellBadge"><%= stats.getOpenAlerts() %></span>
                    </a>
                </div>

                <!-- Avatar User Profile Dropdown -->
                <div class="user-profile-container" style="position: relative;">
                    <div class="user-profile" id="userProfileBtn">
                        <div class="user-avatar">
                            <!-- Icon người màu trắng -->
                            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#ffffff" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/>
                                <circle cx="12" cy="7" r="4"/>
                            </svg>
                        </div>
                        <span class="user-name"><%= me != null ? Web.esc(me.getFullName()) : "Admin" %></span>
                        <!-- Mũi tên dropdown nhỏ -->
                        <svg class="dropdown-arrow" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#6b7280" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                            <polyline points="6 9 12 15 18 9"/>
                        </svg>
                    </div>

                    <div class="user-dropdown-menu" id="userDropdownMenu">
                        <div style="padding: 6px 16px; font-size: 11px; color: var(--text-muted); text-transform: uppercase;">
                            Vai trò: <%= role %>
                        </div>
                        <a href="<%= ctx %>/logout" class="user-dropdown-item logout">Đăng xuất</a>
                    </div>
                </div>
            </div>
        </header>

        <!-- 3. BỐN THẺ THỐNG KÊ (STATS CARDS) -->
        <section class="stats-grid">
            <!-- Thẻ 1: Tổng số phòng học -->
            <div class="stat-card">
                <div class="stat-icon-wrapper bg-blue-light">
                    <!-- Icon Tòa nhà -->
                    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#2563eb" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <rect x="4" y="2" width="16" height="20" rx="2" ry="2"/>
                        <path d="M9 22v-4h6v4"/>
                        <path d="M8 6h.01M16 6h.01M8 10h.01M16 10h.01M8 14h.01M16 14h.01"/>
                    </svg>
                </div>
                <div class="stat-data">
                    <span class="stat-label">Tổng số phòng học</span>
                    <span class="stat-value" id="statTotalRooms">0</span>
                </div>
            </div>

            <!-- Thẻ 2: Phòng bình thường -->
            <div class="stat-card">
                <div class="stat-icon-wrapper bg-green-light">
                    <!-- Icon Nhiệt kế xanh lá -->
                    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#16a34a" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M14 14.76V3.5a2.5 2.5 0 0 0-5 0v11.26a4.5 4.5 0 1 0 5 0z"/>
                        <circle cx="11.5" cy="17.5" r="1.5" fill="#16a34a"/>
                    </svg>
                </div>
                <div class="stat-data">
                    <span class="stat-label">Phòng bình thường</span>
                    <span class="stat-value" id="statNormalRooms">0</span>
                </div>
            </div>

            <!-- Thẻ 3: Phòng cảnh báo -->
            <div class="stat-card">
                <div class="stat-icon-wrapper bg-yellow-light">
                    <!-- Icon Tam giác cảnh báo vàng -->
                    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#f59e0b" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/>
                        <line x1="12" y1="9" x2="12" y2="13"/>
                        <line x1="12" y1="17" x2="12.01" y2="17"/>
                    </svg>
                </div>
                <div class="stat-data">
                    <span class="stat-label">Phòng cảnh báo</span>
                    <span class="stat-value" id="statWarningRooms">0</span>
                </div>
            </div>

            <!-- Thẻ 4: Phòng quá nhiệt -->
            <div class="stat-card">
                <div class="stat-icon-wrapper bg-red-light">
                    <!-- Icon Tam giác cảnh báo đỏ -->
                    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#ef4444" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/>
                        <line x1="12" y1="9" x2="12" y2="13"/>
                        <line x1="12" y1="17" x2="12.01" y2="17"/>
                    </svg>
                </div>
                <div class="stat-data">
                    <span class="stat-label">Phòng quá nhiệt</span>
                    <span class="stat-value" id="statDangerRooms">0</span>
                </div>
            </div>
        </section>

        <!-- 4. THANH CÔNG CỤ LỌC & TÌM KIẾM -->
        <section class="toolbar-section">
            <div class="search-box">
                <!-- Icon Kính lúp -->
                <svg class="search-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#6b7280" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <circle cx="11" cy="11" r="8"/>
                    <line x1="21" y1="21" x2="16.65" y2="16.65"/>
                </svg>
                <input type="text" id="searchInput" placeholder="Tìm kiếm theo tên phòng...">
            </div>

            <div class="filter-select-wrapper">
                <select id="statusFilter" class="filter-select">
                    <option value="ALL">Tất cả trạng thái</option>
                    <option value="NORMAL">Bình thường</option>
                    <option value="WARNING">Cảnh báo</option>
                    <option value="DANGER">Quá nhiệt</option>
                </select>
            </div>

            <div class="filter-select-wrapper">
                <select id="buildingFilter" class="filter-select">
                    <option value="ALL">Tất cả tòa nhà</option>
                    <option value="Tòa A">Tòa A</option>
                    <option value="Tòa B">Tòa B</option>
                    <option value="Tòa C">Tòa C</option>
                </select>
            </div>

            <div class="view-mode-toggle">
                <button type="button" class="btn-toggle active" id="btnGridView" title="Xem dạng lưới (Grid)">
                    <!-- Icon Grid -->
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <rect x="3" y="3" width="7" height="7"/>
                        <rect x="14" y="3" width="7" height="7"/>
                        <rect x="14" y="14" width="7" height="7"/>
                        <rect x="3" y="14" width="7" height="7"/>
                    </svg>
                </button>
                <button type="button" class="btn-toggle" id="btnListView" title="Xem dạng danh sách (List)">
                    <!-- Icon List -->
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <line x1="8" y1="6" x2="21" y2="6"/>
                        <line x1="8" y1="12" x2="21" y2="12"/>
                        <line x1="8" y1="18" x2="21" y2="18"/>
                        <line x1="3" y1="6" x2="3.01" y2="6"/>
                        <line x1="3" y1="12" x2="3.01" y2="12"/>
                        <line x1="3" y1="18" x2="3.01" y2="18"/>
                    </svg>
                </button>
            </div>
        </section>

        <!-- 5. DANH SÁCH THẺ PHÒNG HỌC (GRID HOẶC LIST) -->
        <section id="roomsContainer" class="rooms-container grid-mode">
            <!-- Render động bằng Javascript -->
        </section>

        <!-- 6. PHÂN TRANG -->
        <section class="pagination-section">
            <div id="paginationContainer" class="pagination-wrapper">
                <!-- Nút phân trang render bằng Javascript -->
            </div>
        </section>
    </main>

    <!-- 7. MODAL XEM CHI TIẾT PHÒNG HỌC (TẠM THỜI) -->
    <div id="roomDetailModal" class="modal-overlay">
        <div class="modal-card">
            <div class="modal-header">
                <h3 class="modal-title" id="modalRoomTitle">Chi tiết phòng học</h3>
                <button class="modal-close-btn" id="modalCloseBtn" aria-label="Đóng">&times;</button>
            </div>
            <div class="modal-body" id="modalRoomBody">
                <!-- Nội dung chi tiết phòng học -->
            </div>
            <div class="modal-footer">
                <button class="btn-modal-close" id="modalActionBtn">Đóng</button>
            </div>
        </div>
    </div>

    <!-- Nhúng AI Chatbot Widget -->
    <jsp:include page="/WEB-INF/views/chatbot.jsp"/>

    <!-- CHUYỂN DỮ LIỆU TỪ SERVER JSP SANG JAVASCRIPT OBJECTS -->
    <script>
        // Dữ liệu danh sách phòng từ Database SQL Server
        const serverClassroomData = [
            <%
                for (int i = 0; i < classroomList.size(); i++) {
                    ClassroomTempInfo c = classroomList.get(i);
            %>
            {
                id: <%= c.getRoomId() %>,
                name: '<%= Web.esc(c.getRoomName()) %>',
                building: '<%= Web.esc(c.getBuilding()) %>',
                floor: <%= c.getFloor() %>,
                location: '<%= Web.esc(c.getLocation()) %>',
                temp: <%= c.getTemperature() %>,
                humid: <%= c.getHumidity() %>,
                image: '<%= ctx %>/<%= c.getImageUrl() %>',
                history: [
                    <%
                        List<Double> hist = c.getTempHistory();
                        for (int h = 0; h < hist.size(); h++) {
                    %>
                    <%= hist.get(h) %><%= (h < hist.size() - 1) ? "," : "" %>
                    <% } %>
                ]
            }<%= (i < classroomList.size() - 1) ? "," : "" %>
            <% } %>
        ];

        // Fallback sang dữ liệu mẫu nếu Database phòng học chưa có dữ liệu
        window.DASHBOARD_ROOMS_DATA = (serverClassroomData && serverClassroomData.length > 0) 
            ? serverClassroomData 
            : null;

        // Toggle user dropdown
        (function() {
            const btn = document.getElementById('userProfileBtn');
            const menu = document.getElementById('userDropdownMenu');
            if (btn && menu) {
                btn.addEventListener('click', function(e) {
                    e.stopPropagation();
                    menu.classList.toggle('show');
                });
                document.addEventListener('click', function() {
                    menu.classList.remove('show');
                });
            }
        })();
    </script>
    <script src="<%= ctx %>/script.js"></script>
</body>
</html>
