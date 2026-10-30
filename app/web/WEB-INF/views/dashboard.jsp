<%@page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@page import="java.util.*, model.AppUser, model.DashboardStats, model.ClassroomTempInfo, util.Web, dao.AlertDAO"%>
<%
    String ctx = request.getContextPath();
    AppUser me = (AppUser) session.getAttribute("user");
    String userName = (me != null && me.getFullName() != null) ? me.getFullName() : "Admin";
    String userRole = (me != null && me.getRoleCode() != null) ? me.getRoleCode() : "ADMIN";
    boolean isAdmin = "ADMIN".equals(userRole);
    int openAlertCount = AlertDAO.getOpeningAlertCount();

    DashboardStats stats = (DashboardStats) request.getAttribute("stats");
    if (stats == null) stats = new DashboardStats();

    List<ClassroomTempInfo> classroomList = (List<ClassroomTempInfo>) request.getAttribute("classroomList");
    if (classroomList == null) classroomList = new ArrayList<>();

    java.time.ZonedDateTime nowZdt = java.time.ZonedDateTime.now(java.time.ZoneId.of("Asia/Ho_Chi_Minh"));
    String jDateStr = nowZdt.format(java.time.format.DateTimeFormatter.ofPattern("EEEE, d MMMM yyyy", java.util.Locale.ENGLISH));
    String jTimeStr = nowZdt.format(java.time.format.DateTimeFormatter.ofPattern("HH:mm"));
    String jSidebarDateTime = nowZdt.format(java.time.format.DateTimeFormatter.ofPattern("EEEE, dd/MM/yyyy, HH:mm", java.util.Locale.ENGLISH));

    // Calculate stats directly from real database room list
    int totalRoomsCount = classroomList.size();
    int normalRooms = 0;
    int warningRooms = 0;
    int dangerRooms = 0;
    int noDataRooms = 0;

    double sumTemp = 0, sumHum = 0, sumCo = 0;
    long sumCo2 = 0;
    int roomsWithDataCount = 0;

    String defaultImg = ctx + "/assets/images/classroom_default.png";
    StringBuilder roomsJson = new StringBuilder("[");
    for (int i = 0; i < classroomList.size(); i++) {
        ClassroomTempInfo c = classroomList.get(i);
        String code = (c.getRoomCode() != null && !c.getRoomCode().trim().isEmpty()) ? c.getRoomCode().trim() : ("R" + c.getRoomId());
        String name = (c.getRoomName() != null && !c.getRoomName().trim().isEmpty()) ? c.getRoomName().trim() : code;
        String bld = (c.getBuilding() != null) ? c.getBuilding() : "A";
        int flr = c.getFloor() > 0 ? c.getFloor() : 1;
        boolean hasData = c.isHasData();
        Double temp = c.getTemperature();
        Double hum = c.getHumidity();
        Integer co2 = c.getCo2();
        Double co = c.getCo();
        String status = c.getStatus() != null ? c.getStatus() : "NO_DATA";

        if (hasData) {
            roomsWithDataCount++;
            if (temp != null) sumTemp += temp;
            if (hum != null) sumHum += hum;
            if (co2 != null) sumCo2 += co2;
            if (co != null) sumCo += co;

            if ("NORMAL".equalsIgnoreCase(status)) normalRooms++;
            else if ("WARNING".equalsIgnoreCase(status)) warningRooms++;
            else if ("DANGER".equalsIgnoreCase(status)) dangerRooms++;
            else normalRooms++;
        } else {
            noDataRooms++;
        }

        code = code.replace("\\", "\\\\").replace("\"", "\\\"");
        name = name.replace("\\", "\\\\").replace("\"", "\\\"");

        if (i > 0) roomsJson.append(",");
        roomsJson.append("{")
                 .append("\"dbId\":").append(c.getRoomId()).append(",")
                 .append("\"id\":\"").append(code).append("\",")
                 .append("\"name\":\"").append(name).append("\",")
                 .append("\"building\":\"").append(bld).append("\",")
                 .append("\"floor\":").append(flr).append(",")
                 .append("\"hasData\":").append(hasData).append(",")
                 .append("\"temp\":").append(temp != null ? String.format(Locale.US, "%.1f", temp) : "null").append(",")
                 .append("\"humidity\":").append(hum != null ? String.format(Locale.US, "%.0f", hum) : "null").append(",")
                 .append("\"co2\":").append(co2 != null ? co2 : "null").append(",")
                 .append("\"co\":").append(co != null ? String.format(Locale.US, "%.1f", co) : "null").append(",")
                 .append("\"status\":\"").append(status).append("\",")
                 .append("\"image\":\"").append(defaultImg).append("\"")
                 .append("}");
    }
    roomsJson.append("]");

    // Sensor & Classroom counts from database
    int displayTotalRooms = stats.getTotalRooms() > 0 ? stats.getTotalRooms() : totalRoomsCount;

    // Recent alerts serialization from database
    StringBuilder alertsJson = new StringBuilder("[");
    List<DashboardStats.OpenAlertInfo> openAlerts = stats.getOpenAlertsList();
    if (openAlerts != null && !openAlerts.isEmpty()) {
        for (int i = 0; i < openAlerts.size(); i++) {
            DashboardStats.OpenAlertInfo a = openAlerts.get(i);
            String rawType = a.getRuleCode() != null ? a.getRuleCode() : "Alert";
            String dispType = rawType;
            if ("TEMPERATURE".equalsIgnoreCase(rawType)) dispType = "Overheat";
            else if ("CO2".equalsIgnoreCase(rawType)) dispType = "CO₂ High";
            else if ("CO".equalsIgnoreCase(rawType)) dispType = "CO High";
            else if ("HUMID".equalsIgnoreCase(rawType)) dispType = "Humid High";

            String timeStr = "--:--";
            if (a.getCreatedAt() != null && a.getCreatedAt().length() >= 16) {
                timeStr = a.getCreatedAt().substring(11, 16);
            }
            String roomStr = (a.getRoomCode() != null && !a.getRoomCode().isEmpty()) ? a.getRoomCode() : ("Session #" + a.getSessionId());
            String valStr = a.getMessage() != null ? a.getMessage() : rawType;
            String st = a.getStatus() != null ? a.getStatus() : "OPEN";

            valStr = valStr.replace("\\", "\\\\").replace("\"", "\\\"").replace("\r", " ").replace("\n", " ");
            roomStr = roomStr.replace("\\", "\\\\").replace("\"", "\\\"").replace("\r", " ").replace("\n", " ");
            dispType = dispType.replace("\\", "\\\\").replace("\"", "\\\"").replace("\r", " ").replace("\n", " ");
            st = st.replace("\\", "\\\\").replace("\"", "\\\"").replace("\r", " ").replace("\n", " ");

            if (i > 0) alertsJson.append(",");
            alertsJson.append("{")
                      .append("\"time\":\"").append(timeStr).append("\",")
                      .append("\"room\":\"").append(roomStr).append("\",")
                      .append("\"type\":\"").append(dispType).append("\",")
                      .append("\"value\":\"").append(valStr).append("\",")
                      .append("\"status\":\"").append(st).append("\"")
                      .append("}");
        }
    }
    alertsJson.append("]");

    // Recent session history serialization from database
    List<java.util.Map<String, Object>> sessionHistory = (List<java.util.Map<String, Object>>) request.getAttribute("sessionHistory");
    StringBuilder historyJson = new StringBuilder("[");
    if (sessionHistory != null) {
        for (int i = 0; i < sessionHistory.size(); i++) {
            java.util.Map<String, Object> m = sessionHistory.get(i);
            if (i > 0) historyJson.append(",");
            historyJson.append("{")
                       .append("\"time\":\"").append(m.get("time")).append("\",")
                       .append("\"temp\":").append(m.get("temp") != null ? m.get("temp") : "null").append(",")
                       .append("\"humidity\":").append(m.get("humid") != null ? m.get("humid") : "null").append(",")
                       .append("\"co2\":").append(m.get("co2") != null ? m.get("co2") : "null").append(",")
                       .append("\"co\":").append(m.get("co") != null ? m.get("co") : "null")
                       .append("}");
        }
    }
    historyJson.append("]");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dashboard – Classroom Air Monitoring System</title>
    <link rel="shortcut icon" href="<%= ctx %>/favicon.ico" type="image/x-icon">
    <!-- Google Fonts: Inter -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="<%= ctx %>/assets/css/dashboard.css">
</head>
<body>

    <!-- 1. FIXED LEFT SIDEBAR (235px) -->
    <aside class="sidebar" id="sidebar">
        <!-- Logo Header -->
        <div class="sidebar-logo">
            <div class="logo-box">
                <!-- Thermometer SVG Icon -->
                <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#2563eb" stroke-width="2.3" stroke-linecap="round" stroke-linejoin="round">
                    <path d="M14 14.76V3.5a2.5 2.5 0 0 0-5 0v11.26a4.5 4.5 0 1 0 5 0z"/>
                    <circle cx="11.5" cy="17.5" r="1.5" fill="#2563eb"/>
                </svg>
            </div>
            <div class="logo-text">
                <span class="brand-title">Classroom Temp</span>
                <span class="brand-sub">Monitoring System</span>
            </div>
        </div>

        <!-- Vertical Menu Navigation -->
        <nav class="sidebar-menu">
            <!-- ACTIVE: Dashboard -->
            <a href="<%= ctx %>/dashboard" class="menu-item active" title="Dashboard">
                <svg class="menu-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/>
                    <polyline points="9 22 9 12 15 12 15 22"/>
                </svg>
                <span>Dashboard</span>
            </a>

            <!-- Classrooms -->
            <a href="<%= ctx %>/admin/rooms" class="menu-item" title="Classrooms">
                <svg class="menu-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <rect x="3" y="3" width="7" height="7" rx="1.5"/>
                    <rect x="14" y="3" width="7" height="7" rx="1.5"/>
                    <rect x="14" y="14" width="7" height="7" rx="1.5"/>
                    <rect x="3" y="14" width="7" height="7" rx="1.5"/>
                </svg>
                <span>Classrooms</span>
            </a>

            <!-- Alerts -->
            <a href="<%= ctx %>/alerts" class="menu-item" title="Alerts">
                <svg class="menu-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/>
                    <path d="M13.73 21a2 2 0 0 1-3.46 0"/>
                </svg>
                <span>Alerts</span>
                <span class="sidebar-badge" id="sidebarAlertBadge"><%= openAlertCount %></span>
            </a>

            <!-- Devices -->
            <% if (isAdmin) { %>
            <a href="<%= ctx %>/admin/devices" class="menu-item" title="Devices">
                <svg class="menu-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <rect x="4" y="4" width="16" height="16" rx="2"/>
                    <rect x="9" y="9" width="6" height="6"/>
                    <line x1="9" y1="1" x2="9" y2="4"/>
                    <line x1="15" y1="1" x2="15" y2="4"/>
                    <line x1="9" y1="20" x2="9" y2="23"/>
                    <line x1="15" y1="20" x2="15" y2="23"/>
                    <line x1="20" y1="9" x2="23" y2="9"/>
                    <line x1="20" y1="14" x2="23" y2="14"/>
                    <line x1="1" y1="9" x2="4" y2="9"/>
                    <line x1="1" y1="14" x2="4" y2="14"/>
                </svg>
                <span>Devices</span>
            </a>

            <!-- Users -->
            <a href="<%= ctx %>/admin/users" class="menu-item" title="Users">
                <svg class="menu-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/>
                    <circle cx="9" cy="7" r="4"/>
                    <path d="M23 21v-2a4 4 0 0 0-3-3.87"/>
                    <path d="M16 3.13a4 4 0 0 1 0 7.75"/>
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
    <main class="main-content" id="mainContent">
        <!-- TOP BAR -->
        <header class="top-bar">
            <!-- Left: Hamburger Toggle & Breadcrumb -->
            <div class="top-bar-left">
                <button class="hamburger-btn" id="btnSidebarToggle" title="Toggle Sidebar">
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#2563eb" stroke-width="2.3" stroke-linecap="round" stroke-linejoin="round">
                        <line x1="3" y1="12" x2="21" y2="12"/>
                        <line x1="3" y1="6" x2="21" y2="6"/>
                        <line x1="3" y1="18" x2="21" y2="18"/>
                    </svg>
                </button>

                <nav class="breadcrumb">
                    <a href="<%= ctx %>/dashboard" class="breadcrumb-item breadcrumb-home" title="Home">
                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                            <path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/>
                            <polyline points="9 22 9 12 15 12 15 22"/>
                        </svg>
                    </a>
                    <span class="breadcrumb-separator">
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                            <polyline points="9 18 15 12 9 6"/>
                        </svg>
                    </span>
                    <span class="breadcrumb-item breadcrumb-current">Dashboard</span>
                </nav>
            </div>

            <!-- Right: Notifications & User Profile -->
            <div class="top-bar-right">
                <a href="javascript:void(0)" class="icon-btn-round" title="Notification" onclick="return false;" style="cursor: default;">
                    <svg width="19" height="19" viewBox="0 0 24 24" fill="none" stroke="#4b5563" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/>
                        <path d="M13.73 21a2 2 0 0 1-3.46 0"/>
                    </svg>
                    <span class="notif-badge" id="topBellBadge"><%= openAlertCount %></span>
                </a>

                <div class="user-profile-badge" id="userMenuToggle">
                    <div class="user-avatar-circle">
                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#ffffff" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                            <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/>
                            <circle cx="12" cy="7" r="4"/>
                        </svg>
                    </div>
                    <span class="user-name"><%= Web.esc(userName) %></span>
                    <svg class="dropdown-chevron" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                        <polyline points="6 9 12 15 18 9"/>
                    </svg>

                    <!-- User Dropdown Menu -->
                    <div class="user-dropdown-menu" id="userDropdownMenu">
                        <div class="user-dropdown-header">
                            Role: <%= Web.esc(userRole) %>
                        </div>
                        <a href="<%= ctx %>/logout" class="user-dropdown-item logout">
                            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/>
                                <polyline points="16 17 21 12 16 7"/>
                                <line x1="21" y1="12" x2="9" y2="12"/>
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
                    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#ffffff" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                        <rect x="3" y="3" width="7" height="7" rx="1.5"/>
                        <rect x="14" y="3" width="7" height="7" rx="1.5"/>
                        <rect x="14" y="14" width="7" height="7" rx="1.5"/>
                        <rect x="3" y="14" width="7" height="7" rx="1.5"/>
                    </svg>
                </div>
                <div class="title-text-group">
                    <h1 class="page-main-heading">Dashboard</h1>
                    <p class="page-subheading">Overview of classroom environment and system status</p>
                </div>
            </div>

            <!-- Date & Time Card -->
            <div class="datetime-card">
                <div class="datetime-item">
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#6b7280" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                        <rect x="3" y="4" width="18" height="18" rx="2" ry="2"/>
                        <line x1="16" y1="2" x2="16" y2="6"/>
                        <line x1="8" y1="2" x2="8" y2="6"/>
                        <line x1="3" y1="10" x2="21" y2="10"/>
                    </svg>
                    <span class="datetime-date" id="currentDateText"><%= jDateStr %></span>
                </div>
                <div class="datetime-divider"></div>
                <div class="datetime-item">
                    <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="#2563eb" stroke-width="2.3" stroke-linecap="round" stroke-linejoin="round">
                        <circle cx="12" cy="12" r="10"/>
                        <polyline points="12 6 12 12 16 14"/>
                    </svg>
                    <span class="datetime-time" id="currentTimeText"><%= jTimeStr %></span>
                </div>
            </div>
        </section>

        <!-- 4. FOUR STATS CARDS -->
        <section class="stats-cards-grid">
            <!-- Card 1: Total Rooms -->
            <div class="stat-card">
                <div class="stat-icon-wrapper bg-blue-soft">
                    <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#2563eb" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                        <rect x="4" y="2" width="16" height="20" rx="2" ry="2"/>
                        <path d="M9 22v-4h6v4"/>
                        <path d="M8 6h.01M16 6h.01M8 10h.01M16 10h.01M8 14h.01M16 14h.01"/>
                    </svg>
                </div>
                <div class="stat-info">
                    <span class="stat-label">Total Rooms</span>
                    <div class="stat-number-row">
                        <span class="stat-big-num" id="statTotal"><%= displayTotalRooms %></span>
                    </div>
                    <span class="stat-subtext">All rooms in system</span>
                </div>
            </div>

            <!-- Card 2: Total Opening Alerts -->
            <div class="stat-card">
                <div class="stat-icon-wrapper bg-amber-soft">
                    <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#f59e0b" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/>
                        <line x1="12" y1="9" x2="12" y2="13"/>
                        <line x1="12" y1="17" x2="12.01" y2="17"/>
                    </svg>
                </div>
                <div class="stat-info">
                    <span class="stat-label">Opening Alerts</span>
                    <div class="stat-number-row">
                        <span class="stat-big-num" id="statOpeningAlerts" style="color: #f59e0b;"><%= stats.getOpenAlerts() %></span>
                    </div>
                    <span class="stat-subtext">Requires immediate attention</span>
                </div>
            </div>

            <!-- Card 3: Active / Inactive Devices (Combined) -->
            <div class="stat-card">
                <div class="stat-icon-wrapper bg-green-soft">
                    <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#16a34a" stroke-width="2.3" stroke-linecap="round" stroke-linejoin="round">
                        <rect x="4" y="4" width="16" height="16" rx="2"/>
                        <rect x="9" y="9" width="6" height="6"/>
                        <line x1="9" y1="1" x2="9" y2="4"/>
                        <line x1="15" y1="1" x2="15" y2="4"/>
                        <line x1="9" y1="20" x2="9" y2="23"/>
                        <line x1="15" y1="20" x2="15" y2="23"/>
                        <line x1="20" y1="9" x2="23" y2="9"/>
                        <line x1="20" y1="14" x2="23" y2="14"/>
                        <line x1="1" y1="9" x2="4" y2="9"/>
                        <line x1="1" y1="14" x2="4" y2="14"/>
                    </svg>
                </div>
                <div class="stat-info">
                    <span class="stat-label">Active / Inactive Devices</span>
                    <div class="stat-number-row" style="display: flex; align-items: baseline; gap: 6px;">
                        <span class="stat-big-num" id="statActiveDevices" style="color: #16a34a;"><%= stats.getActiveDevices() %></span>
                        <span style="font-size: 13px; font-weight: 600; color: #16a34a; margin-right: 2px;">Active</span>
                        <span style="color: #cbd5e1; font-weight: 300; font-size: 20px;">/</span>
                        <span class="stat-big-num" id="statInactiveDevices" style="color: #64748b; font-size: 22px;"><%= stats.getInactiveDevices() %></span>
                        <span style="font-size: 13px; font-weight: 600; color: #64748b;">Inactive</span>
                    </div>
                    <span class="stat-subtext">Total <%= stats.getTotalDevices() %> registered devices</span>
                </div>
            </div>

            <!-- Card 4: Total Users -->
            <div class="stat-card">
                <div class="stat-icon-wrapper" style="background: #f5f3ff;">
                    <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#7c3aed" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/>
                        <circle cx="9" cy="7" r="4"/>
                        <path d="M23 21v-2a4 4 0 0 0-3-3.87"/>
                        <path d="M16 3.13a4 4 0 0 1 0 7.75"/>
                    </svg>
                </div>
                <div class="stat-info">
                    <span class="stat-label">Total Users</span>
                    <div class="stat-number-row">
                        <span class="stat-big-num" id="statTotalUsers" style="color: #7c3aed;"><%= stats.getTotalUsers() %></span>
                    </div>
                    <span class="stat-subtext">All users in system</span>
                </div>
            </div>
        </section>

        <!-- 5. MAIN TWO-COLUMN DASHBOARD LAYOUT -->
        <div class="dashboard-main-grid">
            <!-- LEFT COLUMN (~780px) -->
            <div class="dashboard-left-col">
                <!-- A. AIR QUALITY OVERVIEW -->
                <section class="content-card">
                    <div class="card-header">
                        <div class="card-header-left">
                            <div class="mini-icon-circle bg-green-soft">
                                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#16a34a" stroke-width="2.3" stroke-linecap="round" stroke-linejoin="round">
                                    <path d="M11 20A7 7 0 0 1 9.8 6.1C15.5 5 17 4.48 19 2c1 2 2 4.18 2 8 0 5.5-4.78 10-10 10Z"/>
                                    <path d="M2 21c0-3 1.85-5.36 5.08-6C9.5 14.52 12 13 13 12"/>
                                </svg>
                            </div>
                            <div>
                                <h2 class="card-title">Air Quality Overview</h2>
                                <p class="card-subtitle">Current average values across classrooms with active data</p>
                            </div>
                        </div>
                    </div>

                    <!-- 4 Horizontal Metric Blocks -->
                    <div class="air-metrics-row">
                        <!-- Metric 1: CO2 -->
                        <div class="air-metric-box">
                            <div class="air-box-top">
                                <div class="metric-mini-circle bg-green-soft">
                                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#16a34a" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                                        <path d="M17.5 19H9a7 7 0 1 1 6.71-9h1.79a4.5 4.5 0 1 1 0 9Z"/>
                                    </svg>
                                </div>
                                <span class="air-metric-label">CO₂</span>
                            </div>
                            <div class="air-metric-val-wrap">
                                <span class="air-metric-val" id="avgCo2Val"><%= roomsWithDataCount > 0 ? String.valueOf(Math.round((double)sumCo2 / roomsWithDataCount)) : "--" %></span>
                                <span class="air-metric-unit">ppm</span>
                            </div>
                            <span class="air-metric-range" id="avgCo2Range">(≤ 1000 ppm)</span>
                        </div>

                        <!-- Metric 2: CO -->
                        <div class="air-metric-box">
                            <div class="air-box-top">
                                <div class="metric-mini-circle bg-purple-soft">
                                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#8b5cf6" stroke-width="2.3" stroke-linecap="round" stroke-linejoin="round">
                                        <circle cx="12" cy="12" r="9"/>
                                        <path d="M12 7v10M7 12h10"/>
                                    </svg>
                                </div>
                                <span class="air-metric-label">CO</span>
                            </div>
                            <div class="air-metric-val-wrap">
                                <span class="air-metric-val" id="avgCoVal"><%= roomsWithDataCount > 0 ? String.format(Locale.US, "%.1f", sumCo / roomsWithDataCount) : "--" %></span>
                                <span class="air-metric-unit">ppm</span>
                            </div>
                            <span class="air-metric-range" id="avgCoRange">(≤ 10 ppm)</span>
                        </div>

                        <!-- Metric 3: Temperature -->
                        <div class="air-metric-box">
                            <div class="air-box-top">
                                <div class="metric-mini-circle bg-blue-soft">
                                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#2563eb" stroke-width="2.3" stroke-linecap="round" stroke-linejoin="round">
                                        <path d="M14 14.76V3.5a2.5 2.5 0 0 0-5 0v11.26a4.5 4.5 0 1 0 5 0z"/>
                                        <circle cx="11.5" cy="17.5" r="1.5" fill="#2563eb"/>
                                    </svg>
                                </div>
                                <span class="air-metric-label">Temperature</span>
                            </div>
                            <div class="air-metric-val-wrap">
                                <span class="air-metric-val" id="avgTempVal"><%= roomsWithDataCount > 0 ? String.format(Locale.US, "%.1f", sumTemp / roomsWithDataCount) : "--" %></span>
                                <span class="air-metric-unit">&deg;C</span>
                            </div>
                            <span class="air-metric-range" id="avgTempRange">(20 &ndash; 28&deg;C)</span>
                        </div>

                        <!-- Metric 4: Humidity -->
                        <div class="air-metric-box">
                            <div class="air-box-top">
                                <div class="metric-mini-circle bg-blue-soft">
                                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#2563eb" stroke-width="2.3" stroke-linecap="round" stroke-linejoin="round">
                                        <path d="M12 2.69l5.66 5.66a8 8 0 1 1-11.31 0z"/>
                                    </svg>
                                </div>
                                <span class="air-metric-label">Humidity</span>
                            </div>
                            <div class="air-metric-val-wrap">
                                <span class="air-metric-val" id="avgHumidVal"><%= roomsWithDataCount > 0 ? String.valueOf(Math.round(sumHum / roomsWithDataCount)) : "--" %></span>
                                <span class="air-metric-unit">%</span>
                            </div>
                            <span class="air-metric-range" id="avgHumidRange">(40 – 70%)</span>
                        </div>
                    </div>
                </section>

                <!-- B. ENVIRONMENT TREND -->
                <section class="content-card">
                    <div class="card-header trend-header">
                        <div class="card-header-left">
                            <div class="mini-icon-circle bg-blue-soft">
                                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#2563eb" stroke-width="2.3" stroke-linecap="round" stroke-linejoin="round">
                                    <polyline points="22 12 18 12 15 21 9 3 6 12 2 12"/>
                                </svg>
                            </div>
                            <div>
                                <h2 class="card-title">Environment Trend <span class="trend-range-subtitle" id="trendSubtitle">(Last 24 hours)</span></h2>
                            </div>
                        </div>

                        <!-- Metric pills & Time range dropdown -->
                        <div class="trend-controls">
                            <div class="metric-pill-group" id="metricPills">
                                <button class="metric-pill active" data-metric="co2">CO₂</button>
                                <button class="metric-pill" data-metric="co">CO</button>
                                <button class="metric-pill" data-metric="temp">Temperature</button>
                                <button class="metric-pill" data-metric="humidity">Humidity</button>
                            </div>
                            <div class="range-select-wrapper">
                                <select id="rangeSelect" class="trend-range-select">
                                    <option value="6h">Last 6 hours</option>
                                    <option value="24h" selected>Last 24 hours</option>
                                    <option value="7d">Last 7 days</option>
                                </select>
                                <svg class="select-chevron" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="#6b7280" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                                    <polyline points="6 9 12 15 18 9"/>
                                </svg>
                            </div>
                        </div>
                    </div>

                    <!-- Trend Card Body: Chart (~510px) + Summary (~230px) -->
                    <div class="trend-body-layout">
                        <!-- Left: Pure SVG Chart -->
                        <div class="chart-container" id="chartContainer">
                            <div class="chart-y-title" id="chartYTitle">CO₂ (ppm)</div>
                            <svg class="trend-svg" id="trendSvg" viewBox="0 0 510 240" preserveAspectRatio="none">
                                <!-- Populated dynamically by script.js -->
                            </svg>
                            <!-- Interactive Guide Line and Tooltip -->
                            <div class="chart-guide-line" id="chartGuideLine"></div>
                            <div class="chart-tooltip" id="chartTooltip"></div>

                            <!-- Legend -->
                            <div class="chart-legend">
                                <div class="legend-item"><span class="legend-dot dot-blue"></span>Average of All Classrooms</div>
                            </div>
                        </div>

                        <!-- Right: Trend Summary Card (~230px) -->
                        <div class="trend-summary-card">
                            <div class="summary-top-row">
                                <div class="metric-mini-circle" id="summaryIconBox">
                                    <!-- Populated by JS -->
                                </div>
                                <span class="summary-metric-name" id="summaryMetricName">CO₂</span>
                            </div>
                            <div class="summary-current-row">
                                <span class="summary-val" id="summaryMetricVal">688</span>
                                <span class="summary-unit" id="summaryMetricUnit">ppm</span>
                            </div>
                            <div class="summary-range-text" id="summaryRangeText">Allowed: ≤ 1000 ppm</div>

                            <!-- Mini Sparkline SVG -->
                            <div class="sparkline-wrapper">
                                <svg class="sparkline-svg" id="sparklineSvg" viewBox="0 0 200 50" preserveAspectRatio="none">
                                    <!-- Populated by JS -->
                                </svg>
                            </div>

                            <!-- Suggestion Box with hand pointer -->
                            <div class="suggestion-box">
                                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#2563eb" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                    <path d="M18 11V6a2 2 0 0 0-2-2v0a2 2 0 0 0-2 2v0"/>
                                    <path d="M14 10V4a2 2 0 0 0-2-2v0a2 2 0 0 0-2 2v2"/>
                                    <path d="M10 10.5V6a2 2 0 0 0-2-2v0a2 2 0 0 0-2 2v8"/>
                                    <path d="M18 8a2 2 0 1 1 4 0v6a8 8 0 0 1-8 8h-2c-2.8 0-4.5-.86-5.99-2.34l-3.6-3.6a2 2 0 0 1 2.83-2.82L7 15"/>
                                </svg>
                                <span>Select another metric to view its trend</span>
                            </div>
                        </div>
                    </div>
                </section>
            </div>

            <!-- RIGHT COLUMN (~480px): CLASSROOM OVERVIEW -->
            <div class="dashboard-right-col">
                <section class="content-card classroom-overview-card">
                    <div class="card-header">
                        <div class="card-header-left">
                            <div class="mini-icon-circle bg-blue-soft">
                                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#2563eb" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                                    <rect x="4" y="2" width="16" height="20" rx="2" ry="2"/>
                                    <path d="M9 22v-4h6v4"/>
                                    <path d="M8 6h.01M16 6h.01M8 10h.01M16 10h.01M8 14h.01M16 14h.01"/>
                                </svg>
                            </div>
                            <div>
                                <h2 class="card-title">Classroom Overview</h2>
                                <p class="card-subtitle">Current status of classrooms</p>
                            </div>
                        </div>
                        <a href="<%= ctx %>/admin/rooms" class="card-view-all">
                            <span>View all (<%= totalRoomsCount %>)</span>
                            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                                <polyline points="9 18 15 12 9 6"/>
                            </svg>
                        </a>
                    </div>

                    <!-- Room Cards Grid / List -->
                    <div class="classroom-overview-grid" id="classroomOverviewGrid">
                        <!-- Populated by JS -->
                    </div>
                </section>
            </div>
        </div>
    </main>

    <!-- Global dynamic data injected for dashboard.js -->
    <script>
        window.DASHBOARD_DATA = {
            now: "<%= nowZdt.format(java.time.format.DateTimeFormatter.ISO_OFFSET_DATE_TIME) %>",
            contextPath: "<%= ctx %>",
            roomDetailUrl: "<%= ctx %>/admin/rooms/detail",
            defaultImage: "<%= defaultImg %>",
            devicesUrl: "<%= ctx %>/admin/devices",
            alertsUrl: "<%= ctx %>/alerts",
            stats: {
                totalRooms: <%= displayTotalRooms %>,
                openAlerts: <%= openAlertCount %>,
                activeDevices: <%= stats.getActiveDevices() %>,
                inactiveDevices: <%= stats.getInactiveDevices() %>,
                totalUsers: <%= stats.getTotalUsers() %>
            },
            rooms: <%= roomsJson.toString() %>,
            alerts: <%= alertsJson.toString() %>,
            history: <%= historyJson.toString() %>
        };
    </script>
    <script src="<%= ctx %>/assets/js/dashboard.js?v=<%= System.currentTimeMillis() %>" charset="UTF-8"></script>
    <script>
        (function() {
            function updateLiveClock() {
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
            }
            window.renderHeaderDate = updateLiveClock;
            updateLiveClock();
            setInterval(updateLiveClock, 1000);
        })();
    </script>
</body>
</html>
