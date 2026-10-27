<%@page contentType="text/html" pageEncoding="UTF-8" %>
    <%@page import="java.util.List, java.util.Locale, java.text.SimpleDateFormat, model.Room, model.AppUser, util.Web"
        %>
        <% List<Room> rows = (List<Room>) request.getAttribute("rows");
                String keyword = (String) request.getAttribute("keyword");
                String status = (String) request.getAttribute("status");
                String ctx = request.getContextPath();

                AppUser me = (AppUser) session.getAttribute("user");
                String userName = (me != null && me.getFullName() != null) ? me.getFullName() : "Admin User";
                String userRole = (me != null && me.getRoleCode() != null) ? me.getRoleCode() : "ADMIN";
                boolean isAdmin = "ADMIN".equals(userRole);
                boolean canManageRoom = "ADMIN".equals(userRole) || "STATION_MANAGER".equals(userRole) ||
                "OPERATOR".equals(userRole);

                int openAlertCount = 6;
                try {
                dao.DashboardDAO dashDAO = dao.DashboardDAO.getInstance();
                openAlertCount = dashDAO.getDashboardStats().getOpenAlerts();
                } catch (Exception ignored) {}

                java.time.ZonedDateTime nowZdt = java.time.ZonedDateTime.now(java.time.ZoneId.of("Asia/Ho_Chi_Minh"));
                String jDateStr = nowZdt.format(java.time.format.DateTimeFormatter.ofPattern("EEEE, d MMMM yyyy",
                java.util.Locale.ENGLISH));
                String jTimeStr = nowZdt.format(java.time.format.DateTimeFormatter.ofPattern("HH:mm"));
                String jSidebarDateTime = nowZdt.format(java.time.format.DateTimeFormatter.ofPattern("EEEE, dd/MM/yyyy, HH:mm", java.util.Locale.ENGLISH));

                // Serialize database rooms to JSON for dynamic rendering if available
                StringBuilder roomsJson = new StringBuilder("[");
                if (rows != null && !rows.isEmpty()) {
                    String defaultImg = ctx + "/assets/images/classroom_default.png";
                    SimpleDateFormat timeSdf = new SimpleDateFormat("HH:mm");
                    for (int i = 0; i < rows.size(); i++) {
                        Room r = rows.get(i);
                        String code = (r.getCode() != null && !r.getCode().trim().isEmpty()) ? r.getCode().trim() : ("R" + r.getRoomId());
                        String name = (r.getName() != null && !r.getName().trim().isEmpty()) ? r.getName().trim() : code;
                        String loc = (r.getLocation() != null && !r.getLocation().trim().isEmpty()) ? r.getLocation().trim() : "";
                        code = code.replace("\\", "\\\\").replace("\"", "\\\"");
                        name = name.replace("\\", "\\\\").replace("\"", "\\\"");
                        loc = loc.replace("\\", "\\\\").replace("\"", "\\\"");

                        Double temp = r.getTemp();
                        Double hum = r.getHumidity();
                        Double co2 = r.getCo2();
                        Double co = r.getCo();
                        boolean sensorOnline = Boolean.TRUE.equals(r.isSensorOnline());
                        int openAlerts = (r.getOpenAlertsCount() != null) ? r.getOpenAlertsCount() : 0;
                        String updatedTime = (r.getLastMeasuredAt() != null) ? timeSdf.format(r.getLastMeasuredAt()) : null;

                        if (i > 0) roomsJson.append(",");
                        roomsJson.append("{")
                                .append("\"dbId\":").append(r.getRoomId()).append(",")
                                .append("\"id\":\"").append(code).append("\",")
                                .append("\"name\":\"").append(name).append("\",")
                                .append("\"location\":\"").append(loc).append("\",")
                                .append("\"temp\":").append(temp != null ? String.format(Locale.US, "%.1f", temp) : "null").append(",")
                                .append("\"humidity\":").append(hum != null ? String.format(Locale.US, "%.0f", hum) : "null").append(",")
                                .append("\"co2\":").append(co2 != null ? String.format(Locale.US, "%.0f", co2) : "null").append(",")
                                .append("\"co\":").append(co != null ? String.format(Locale.US, "%.1f", co) : "null").append(",")
                                .append("\"sensorOnline\":").append(sensorOnline).append(",")
                                .append("\"openAlerts\":").append(openAlerts).append(",")
                                .append("\"tempWarningThreshold\":").append(r.getTempWarningThreshold()).append(",")
                                .append("\"humidWarningThreshold\":").append(r.getHumidWarningThreshold()).append(",")
                                .append("\"coWarningThreshold\":").append(r.getCoWarningThreshold()).append(",")
                                .append("\"co2WarningThreshold\":").append(r.getCo2WarningThreshold()).append(",")
                                .append("\"updatedAt\":").append(updatedTime != null ? "\"" + updatedTime + "\"" : "null").append(",")
                                .append("\"image\":\"").append(defaultImg).append("\"")
                                .append("}");
                    }
                }
                roomsJson.append("]"); %>
                    <!DOCTYPE html>
                    <html lang="en">

                    <head>
                        <meta charset="UTF-8">
                        <meta name="viewport" content="width=device-width, initial-scale=1.0">
                        <title>Classrooms – Classroom Temp Monitoring System</title>
                        <link rel="shortcut icon" href="<%= ctx %>/favicon.ico" type="image/x-icon">
                        <!-- Google Fonts: Inter -->
                        <link rel="preconnect" href="https://fonts.googleapis.com">
                        <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
                        <link
                            href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap"
                            rel="stylesheet">
                        <link rel="stylesheet"
                            href="<%= ctx %>/assets/css/classrooms.css?v=<%= System.currentTimeMillis() %>">
                        <style>
                            .title-left-group {
                                display: flex;
                                align-items: center;
                                gap: 14px;
                            }

                            .datetime-card {
                                background: #ffffff;
                                border: 1px solid #e2e8f0;
                                border-radius: 12px;
                                padding: 8px 16px;
                                display: flex;
                                align-items: center;
                                gap: 14px;
                                box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.03), 0 2px 4px -1px rgba(0, 0, 0, 0.02);
                            }

                            .datetime-item {
                                display: flex;
                                align-items: center;
                                gap: 8px;
                            }

                            .datetime-date {
                                font-size: 12.5px;
                                font-weight: 500;
                                color: #64748b;
                            }

                            .datetime-divider {
                                width: 1px;
                                height: 22px;
                                background: #e2e8f0;
                            }

                            .datetime-time {
                                font-size: 16px;
                                font-weight: 700;
                                color: #2563eb;
                            }

                            .filter-card {
                                display: flex;
                                align-items: center;
                                gap: 14px;
                                flex-wrap: nowrap;
                            }

                            .search-input-group {
                                flex: 1;
                                min-width: 220px;
                                margin: 0;
                            }

                            .select-field-group,
                            .btn-refresh,
                            .btn-add-room {
                                flex-shrink: 0;
                                margin: 0 !important;
                            }
                        </style>
                    </head>

                    <body>

                        <!-- 1. FIXED LEFT SIDEBAR (235px) -->
                        <aside class="sidebar">
                            <!-- Logo Header -->
                            <div class="sidebar-logo">
                                <div class="logo-box">
                                    <!-- Inline SVG Thermometer Icon -->
                                    <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#2563eb"
                                        stroke-width="2.3" stroke-linecap="round" stroke-linejoin="round">
                                        <path d="M14 14.76V3.5a2.5 2.5 0 0 0-5 0v11.26a4.5 4.5 0 1 0 5 0z" />
                                        <circle cx="11.5" cy="17.5" r="1.5" fill="#2563eb" />
                                    </svg>
                                </div>
                                <div class="logo-text">
                                    <span class="brand-title">Classroom Temp</span>
                                    <span class="brand-sub">Monitoring System</span>
                                </div>
                            </div>

                            <!-- Vertical Menu Navigation -->
                            <nav class="sidebar-menu">
                                <a href="<%= ctx %>/dashboard" class="menu-item" title="Dashboard">
                                    <svg class="menu-icon" width="18" height="18" viewBox="0 0 24 24" fill="none"
                                        stroke="currentColor" stroke-width="2" stroke-linecap="round"
                                        stroke-linejoin="round">
                                        <path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z" />
                                        <polyline points="9 22 9 12 15 12 15 22" />
                                    </svg>
                                    <span>Dashboard</span>
                                </a>

                                <!-- ACTIVE ITEM: Classrooms -->
                                <a href="<%= ctx %>/admin/rooms" class="menu-item active" title="Classrooms">
                                    <svg class="menu-icon" width="18" height="18" viewBox="0 0 24 24" fill="none"
                                        stroke="currentColor" stroke-width="2" stroke-linecap="round"
                                        stroke-linejoin="round">
                                        <rect x="3" y="3" width="7" height="7" rx="1.5" />
                                        <rect x="14" y="3" width="7" height="7" rx="1.5" />
                                        <rect x="14" y="14" width="7" height="7" rx="1.5" />
                                        <rect x="3" y="14" width="7" height="7" rx="1.5" />
                                    </svg>
                                    <span>Classrooms</span>
                                </a>

                                <!-- Alerts -->
                                <a href="<%= ctx %>/alerts" class="menu-item" title="Alerts">
                                    <svg class="menu-icon" width="18" height="18" viewBox="0 0 24 24" fill="none"
                                        stroke="currentColor" stroke-width="2" stroke-linecap="round"
                                        stroke-linejoin="round">
                                        <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9" />
                                        <path d="M13.73 21a2 2 0 0 1-3.46 0" />
                                    </svg>
                                    <span>Alerts</span>
                                    <span class="sidebar-badge" id="sidebarAlertBadge">
                                        <%= openAlertCount> 0 ? openAlertCount : 6 %>
                                    </span>
                                </a>

                                <!-- Devices -->
                                <% if (isAdmin) { %>
                                    <a href="<%= ctx %>/admin/devices" class="menu-item" title="Devices">
                                        <svg class="menu-icon" width="18" height="18" viewBox="0 0 24 24" fill="none"
                                            stroke="currentColor" stroke-width="2" stroke-linecap="round"
                                            stroke-linejoin="round">
                                            <rect x="4" y="4" width="16" height="16" rx="2" />
                                            <rect x="9" y="9" width="6" height="6" />
                                            <path d="M9 1v3M15 1v3M9 20v3M15 20v3M20 9h3M20 14h3M1 9h3M1 14h3" />
                                        </svg>
                                        <span>Devices</span>
                                    </a>

                                    <!-- Users -->
                                    <a href="<%= ctx %>/admin/users" class="menu-item" title="Users">
                                        <svg class="menu-icon" width="18" height="18" viewBox="0 0 24 24" fill="none"
                                            stroke="currentColor" stroke-width="2" stroke-linecap="round"
                                            stroke-linejoin="round">
                                            <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" />
                                            <circle cx="9" cy="7" r="4" />
                                            <path d="M23 21v-2a4 4 0 0 0-3-3.87" />
                                            <path d="M16 3.13a4 4 0 0 1 0 7.75" />
                                        </svg>
                                        <span>Users</span>
                                    </a>
                                    <% } %>
                            </nav>

                            <!-- Sidebar Footer Status -->
                            <div class="sidebar-footer">
                                <div class="status-live">
                                    <span class="live-dot"></span>
                                    <span class="live-text">System Online</span>
                                </div>
                                <div class="status-time" id="sidebarLastUpdate"><%= jSidebarDateTime %></div>
                            </div>
                        </aside>

                        <!-- 2. MAIN CONTENT AREA -->
                        <main class="main-content">
                            <!-- TOP BAR -->
                            <header class="top-bar">
                                <!-- Left: Hamburger Toggle & Breadcrumb -->
                                <div class="top-bar-left">
                                    <button class="hamburger-btn" id="btnSidebarToggle" title="Toggle Sidebar">
                                        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#2563eb"
                                            stroke-width="2.3" stroke-linecap="round" stroke-linejoin="round">
                                            <line x1="3" y1="12" x2="21" y2="12" />
                                            <line x1="3" y1="6" x2="21" y2="6" />
                                            <line x1="3" y1="18" x2="21" y2="18" />
                                        </svg>
                                    </button>

                                    <nav class="breadcrumb">
                                        <a href="<%= ctx %>/dashboard" class="breadcrumb-item breadcrumb-home"
                                            title="Home">
                                            <svg width="16" height="16" viewBox="0 0 24 24" fill="none"
                                                stroke="currentColor" stroke-width="2" stroke-linecap="round"
                                                stroke-linejoin="round">
                                                <path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z" />
                                                <polyline points="9 22 9 12 15 12 15 22" />
                                            </svg>
                                        </a>
                                        <span class="breadcrumb-separator">
                                            <svg width="14" height="14" viewBox="0 0 24 24" fill="none"
                                                stroke="currentColor" stroke-width="2" stroke-linecap="round"
                                                stroke-linejoin="round">
                                                <polyline points="9 18 15 12 9 6" />
                                            </svg>
                                        </span>
                                        <span class="breadcrumb-item breadcrumb-current">Classrooms</span>
                                    </nav>
                                </div>

                                <!-- Right: Notifications & User Profile -->
                                <div class="top-bar-right">
                                    <a href="<%= ctx %>/alerts" class="icon-btn-round" title="Notifications">
                                        <svg width="19" height="19" viewBox="0 0 24 24" fill="none" stroke="#4b5563"
                                            stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                            <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9" />
                                            <path d="M13.73 21a2 2 0 0 1-3.46 0" />
                                        </svg>
                                        <span class="notif-badge" id="topBellBadge">
                                            <%= openAlertCount> 0 ? openAlertCount : 6 %>
                                        </span>
                                    </a>

                                    <div class="user-profile-badge" id="userMenuToggle">
                                        <div class="user-avatar-circle">
                                            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#ffffff"
                                                stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                                                <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" />
                                                <circle cx="12" cy="7" r="4" />
                                            </svg>
                                        </div>
                                        <span class="user-name">
                                            <%= Web.esc(userName) %>
                                        </span>
                                        <svg class="dropdown-chevron" width="14" height="14" viewBox="0 0 24 24"
                                            fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round"
                                            stroke-linejoin="round">
                                            <polyline points="6 9 12 15 18 9" />
                                        </svg>

                                        <!-- User Dropdown Menu -->
                                        <div class="user-dropdown-menu" id="userDropdownMenu">
                                            <div class="user-dropdown-header">
                                                Role: <%= Web.esc(userRole) %>
                                            </div>
                                            <a href="<%= ctx %>/logout" class="user-dropdown-item logout">
                                                <svg width="15" height="15" viewBox="0 0 24 24" fill="none"
                                                    stroke="currentColor" stroke-width="2" stroke-linecap="round"
                                                    stroke-linejoin="round">
                                                    <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" />
                                                    <polyline points="16 17 21 12 16 7" />
                                                    <line x1="21" y1="12" x2="9" y2="12" />
                                                </svg>
                                                <span>Logout</span>
                                            </a>
                                        </div>
                                    </div>
                                </div>
                            </header>

                            <!-- 3. PAGE TITLE SECTION -->
                            <section class="page-title-section">
                                <div class="title-left-group">
                                    <div class="title-icon-box">
                                        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#ffffff"
                                            stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                                            <rect x="3" y="3" width="7" height="7" rx="1.5" />
                                            <rect x="14" y="3" width="7" height="7" rx="1.5" />
                                            <rect x="14" y="14" width="7" height="7" rx="1.5" />
                                            <rect x="3" y="14" width="7" height="7" rx="1.5" />
                                        </svg>
                                    </div>
                                    <div class="title-text-group">
                                        <h1 class="page-main-heading">Classrooms</h1>
                                        <p class="page-subheading">Monitor and manage the environmental conditions of
                                            all classrooms in real-time.</p>
                                    </div>
                                </div>

                                <!-- Date & Time Card -->
                                <div class="datetime-card">
                                    <div class="datetime-item">
                                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#6b7280"
                                            stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                                            <rect x="3" y="4" width="18" height="18" rx="2" ry="2" />
                                            <line x1="16" y1="2" x2="16" y2="6" />
                                            <line x1="8" y1="2" x2="8" y2="6" />
                                            <line x1="3" y1="10" x2="21" y2="10" />
                                        </svg>
                                        <span class="datetime-date" id="currentDateText">
                                            <%= jDateStr %>
                                        </span>
                                    </div>
                                    <div class="datetime-divider"></div>
                                    <div class="datetime-item">
                                        <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="#2563eb"
                                            stroke-width="2.3" stroke-linecap="round" stroke-linejoin="round">
                                            <circle cx="12" cy="12" r="10" />
                                            <polyline points="12 6 12 12 16 14" />
                                        </svg>
                                        <span class="datetime-time" id="currentTimeText">
                                            <%= jTimeStr %>
                                        </span>
                                    </div>
                                </div>
                            </section>

                            <!-- 4. FOUR STATS CARDS -->
                            <section class="stats-cards-grid">
                                <!-- Card 1: Total Classrooms -->
                                <div class="stat-card active" id="cardFilterAll" data-status="ALL" title="Click to show all classrooms">
                                    <div class="stat-icon-wrapper bg-blue-soft">
                                        <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#2563eb"
                                            stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                                            <rect x="4" y="2" width="16" height="20" rx="2" ry="2" />
                                            <path d="M9 22v-4h6v4" />
                                            <path d="M8 6h.01M16 6h.01M8 10h.01M16 10h.01M8 14h.01M16 14h.01" />
                                        </svg>
                                    </div>
                                    <div class="stat-info">
                                        <span class="stat-label">Total Classrooms</span>
                                        <div class="stat-number-row">
                                            <span class="stat-big-num" id="statTotal"><%= (rows != null) ? rows.size() : 0 %></span>
                                        </div>
                                    </div>
                                </div>

                                <!-- Card 2: Normal -->
                                <div class="stat-card" id="cardFilterNormal" data-status="NORMAL" title="Click to filter Normal classrooms">
                                    <div class="stat-icon-wrapper green">
                                        <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                                            <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/>
                                            <polyline points="22 4 12 14.01 9 11.01"/>
                                        </svg>
                                    </div>
                                    <div class="stat-info">
                                         <span class="stat-label">Normal</span>
                                         <div class="stat-number-row">
                                             <span class="stat-big-num" id="statNormal">0</span>
                                             <span class="stat-percent" id="statNormalPct">0%</span>
                                         </div>
                                     </div>
                                 </div>

                                <!-- Card 3: Warning -->
                                <div class="stat-card" id="cardFilterWarning" data-status="WARNING" title="Click to filter Warning classrooms">
                                    <div class="stat-icon-wrapper bg-amber-soft">
                                        <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#f59e0b"
                                            stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                                            <path
                                                d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z" />
                                            <line x1="12" y1="9" x2="12" y2="13" />
                                            <line x1="12" y1="17" x2="12.01" y2="17" />
                                        </svg>
                                    </div>
                                    <div class="stat-info">
                                         <span class="stat-label">Warning</span>
                                         <div class="stat-number-row">
                                             <span class="stat-big-num" id="statWarning">0</span>
                                             <span class="stat-percent" id="statWarningPct">0%</span>
                                         </div>
                                     </div>
                                 </div>

                            </section>

                            <!-- 5. FILTER BAR -->
                            <section class="filter-card">
                                <!-- Search Input -->
                                <div class="search-input-group">
                                    <svg class="search-icon" width="18" height="18" viewBox="0 0 24 24" fill="none"
                                        stroke="#6b7280" stroke-width="2" stroke-linecap="round"
                                        stroke-linejoin="round">
                                        <circle cx="11" cy="11" r="8" />
                                        <line x1="21" y1="21" x2="16.65" y2="16.65" />
                                    </svg>
                                    <input type="text" id="searchInput" class="search-input"
                                        placeholder="Search by room number or name..." value="<%= Web.esc(keyword) %>">
                                </div>

                                <!-- Refresh Button -->
                                <button type="button" class="btn-refresh" id="btnRefresh">
                                    <svg class="refresh-icon" id="refreshSvg" width="16" height="16" viewBox="0 0 24 24"
                                        fill="none" stroke="#2563eb" stroke-width="2.3" stroke-linecap="round"
                                        stroke-linejoin="round">
                                        <polyline points="23 4 23 10 17 10" />
                                        <polyline points="1 20 1 14 7 14" />
                                        <path
                                            d="M3.51 9a9 9 0 0 1 14.85-3.36L23 10M1 14l4.64 4.36A9 9 0 0 0 20.49 15" />
                                    </svg>
                                    <span>Refresh</span>
                                </button>

                                <% if (canManageRoom) { %>
                                    <a href="<%= ctx %>/admin/rooms/create" class="btn-add-room"
                                        title="Add New Classroom">
                                        <svg width="15" height="15" viewBox="0 0 24 24" fill="none"
                                            stroke="currentColor" stroke-width="2.5" stroke-linecap="round"
                                            stroke-linejoin="round">
                                            <line x1="12" y1="5" x2="12" y2="19"></line>
                                            <line x1="5" y1="12" x2="19" y2="12"></line>
                                        </svg>
                                        <span>Add Room</span>
                                    </a>
                                    <% } %>
                            </section>

                            <!-- 6. CLASSROOMS GRID (3x3 = 9 CARDS PER PAGE) -->
                            <section class="classrooms-grid" id="classroomsGrid">
                                <!-- Populated dynamically by classrooms.js -->
                            </section>

                            <!-- Empty Results Message (Hidden by default) -->
                            <div class="no-results-box" id="noResultsBox" style="display: none;">
                                <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="#94a3b8"
                                    stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
                                    <circle cx="11" cy="11" r="8" />
                                    <line x1="21" y1="21" x2="16.65" y2="16.65" />
                                </svg>
                                <p class="no-results-title">No classrooms found</p>
                                <p class="no-results-sub">Try adjusting your keyword or filter options.</p>
                            </div>

                            <!-- 7. GRID FOOTER & PAGINATION -->
                            <section class="grid-footer-section">
                                <div class="footer-count-text" id="footerCountText">
                                    Showing classrooms...
                                </div>
                                <div class="pagination-controls" id="paginationControls">
                                    <!-- Populated dynamically by classrooms.js -->
                                </div>
                            </section>
                        </main>

                        <!-- Pass context path & server data to JavaScript -->
                        <script>
                            window.APP_CTX = "<%= ctx %>";
                            window.SERVER_CLASSROOMS_DATA = <%= roomsJson.toString() %>;

                            // Dynamic live clock for header
                            (function () {
                                function updateClock() {
                                    const now = new Date();
                                    const days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
                                    const months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
                                    const dEl = document.getElementById("currentDateText");
                                    const tEl = document.getElementById("currentTimeText");
                                    if (dEl) dEl.innerText = days[now.getDay()] + ", " + now.getDate() + " " + months[now.getMonth()] + " " + now.getFullYear();
                                    if (tEl) {
                                        const hh = String(now.getHours()).padStart(2, '0');
                                        const mm = String(now.getMinutes()).padStart(2, '0');
                                        tEl.innerText = hh + ":" + mm;
                                    }
                                    const sEl = document.getElementById("sidebarLastUpdate");
                                    if (sEl) {
                                        const dd = String(now.getDate()).padStart(2, '0');
                                        const mm = String(now.getMonth() + 1).padStart(2, '0');
                                        const yyyy = now.getFullYear();
                                        const hh = String(now.getHours()).padStart(2, '0');
                                        const min = String(now.getMinutes()).padStart(2, '0');
                                        sEl.innerText = days[now.getDay()] + ", " + dd + "/" + mm + "/" + yyyy + ", " + hh + ":" + min;
                                    }
                                }
                                setInterval(updateClock, 10000);
                            })();
                        </script>
                        <script src="<%= ctx %>/assets/js/classrooms.js?v=<%= System.currentTimeMillis() %>"></script>
                    </body>

                    </html>