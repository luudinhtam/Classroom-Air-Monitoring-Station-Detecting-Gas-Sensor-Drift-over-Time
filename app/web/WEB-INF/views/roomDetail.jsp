<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.util.*, java.time.format.DateTimeFormatter, model.*, util.Web"%>
<%
    Room item = (Room) request.getAttribute("detail");
    AirSession latestSession = (AirSession) request.getAttribute("latestSession");
    List<AirSession> recentSessions = (List<AirSession>) request.getAttribute("recentSessions");
    List<AirAlert> recentAlerts = (List<AirAlert>) request.getAttribute("recentAlerts");
    Device activeDevice = (Device) request.getAttribute("activeDevice");
    String activeTab = (String) request.getAttribute("activeTab");
    if (activeTab == null || activeTab.isEmpty()) activeTab = "charts";
    boolean isMeasureTab = "measure".equalsIgnoreCase(activeTab);
    
    AppUser me = (AppUser) session.getAttribute("user");
    String ctx = request.getContextPath();

    String userName = (me != null && me.getFullName() != null) ? me.getFullName() : "Admin User";
    String userRole = (me != null && me.getRoleCode() != null) ? me.getRoleCode() : "ADMIN";
    boolean isAdmin = "ADMIN".equals(userRole);
    boolean canManageRoom = "ADMIN".equals(userRole) || "STATION_MANAGER".equals(userRole) || "OPERATOR".equals(userRole);
    boolean canStartMeasure = "ADMIN".equals(userRole) || "STATION_MANAGER".equals(userRole) || "OPERATOR".equals(userRole);
    boolean hasActiveDevice = (activeDevice != null && activeDevice.isIsActive());

    int openAlertCount = 6;
    try {
        dao.DashboardDAO dashDAO = dao.DashboardDAO.getInstance();
        openAlertCount = dashDAO.getDashboardStats().getOpenAlerts();
    } catch (Exception ignored) {}

    java.time.ZonedDateTime nowZdt = java.time.ZonedDateTime.now(java.time.ZoneId.of("Asia/Ho_Chi_Minh"));
    String jSidebarDateTime = nowZdt.format(java.time.format.DateTimeFormatter.ofPattern("EEEE, dd/MM/yyyy, HH:mm", java.util.Locale.ENGLISH));

    String roomName = (item != null && item.getName() != null) ? item.getName() : "Room";
    String roomCode = (item != null && item.getCode() != null) ? item.getCode() : "";
    String roomLocation = (item != null && item.getLocation() != null) ? item.getLocation() : "Unknown location";
    String rawDeviceCode = (item != null && item.getDeviceCode() != null) ? item.getDeviceCode().trim() : "";
    boolean hasDevice = !rawDeviceCode.isEmpty();
    String deviceCode = hasDevice ? rawDeviceCode : "Not Assigned";
    int roomId = (item != null) ? item.getRoomId() : 0;
    float tempMax = (item != null && item.getTempWarningThreshold() > 0) ? item.getTempWarningThreshold() : 32.0f;
    float humidMax = (item != null && item.getHumidWarningThreshold() > 0) ? item.getHumidWarningThreshold() : 80.0f;
    float coMax = (item != null && item.getCoWarningThreshold() > 0) ? item.getCoWarningThreshold() : 9.0f;
    float co2Max = (item != null && item.getCo2WarningThreshold() > 0) ? item.getCo2WarningThreshold() : 1000.0f;
    
    boolean hasSession = (latestSession != null);
    Double currentTemp = (hasSession && latestSession.getTemperature() != null) ? (Math.round(latestSession.getTemperature() * 10.0) / 10.0) : null;
    Double currentHumid = (hasSession && latestSession.getHumid() != null) ? (Math.round(latestSession.getHumid() * 10.0) / 10.0) : null;
    Integer currentCo2 = (hasSession && latestSession.getCo2() != null) ? latestSession.getCo2() : null;
    Double currentCo = (hasSession && latestSession.getCo() != null) ? latestSession.getCo().doubleValue() : null;

    // Real Sensor / Device Status Lookup
    Device roomDevice = null;
    try (java.sql.Connection cn = util.DBContext.getConnection();
         java.sql.PreparedStatement ps = cn.prepareStatement("SELECT TOP 1 device_id, device_code, api_key, last_seen, is_active, room_id FROM Device WHERE (device_code = ? AND ? != '') OR (room_id = ? AND ? > 0) ORDER BY is_active DESC, last_seen DESC")) {
        ps.setString(1, rawDeviceCode);
        ps.setString(2, rawDeviceCode);
        ps.setInt(3, roomId);
        ps.setInt(4, roomId);
        try (java.sql.ResultSet rs = ps.executeQuery()) {
            if (rs.next()) {
                roomDevice = new Device();
                roomDevice.setDeviceId(rs.getInt("device_id"));
                roomDevice.setDeviceCode(rs.getString("device_code"));
                roomDevice.setIsActive(rs.getBoolean("is_active"));
                roomDevice.setLastSeen(rs.getTimestamp("last_seen"));
                if (!hasDevice && roomDevice.getDeviceCode() != null) {
                    deviceCode = roomDevice.getDeviceCode();
                    hasDevice = true;
                }
            }
        }
    } catch (Exception ignored) {}

    String sensorStatusText;
    String sensorStatusBadgeClass;
    String sensorWifiColor;

    if (!hasDevice) {
        sensorStatusText = "Not Assigned";
        sensorStatusBadgeClass = "status-neutral";
        sensorWifiColor = "#94a3b8";
    } else if (roomDevice == null) {
        sensorStatusText = "Not Found";
        sensorStatusBadgeClass = "status-neutral";
        sensorWifiColor = "#94a3b8";
    } else if (!roomDevice.isIsActive()) {
        sensorStatusText = "Inactive";
        sensorStatusBadgeClass = "status-warning";
        sensorWifiColor = "#ef4444";
    } else if (hasSession) {
        sensorStatusText = "Active";
        sensorStatusBadgeClass = "status-normal";
        sensorWifiColor = "#16a34a";
    } else {
        sensorStatusText = "No Telemetry";
        sensorStatusBadgeClass = "status-neutral";
        sensorWifiColor = "#94a3b8";
    }

    String lastUpdated;
    if (hasSession && latestSession.getMeasuredAt() != null) {
        lastUpdated = latestSession.getMeasuredAt().toString();
    } else if (roomDevice != null && roomDevice.getLastSeen() != null) {
        lastUpdated = roomDevice.getLastSeen().toString();
    } else if (!hasDevice) {
        lastUpdated = "No device assigned";
    } else {
        lastUpdated = "No telemetry recorded";
    }

    String jRoomName = (roomName != null ? roomName : "").replace("\\", "\\\\").replace("\"", "\\\"").replace("\r", " ").replace("\n", " ");
    String jRoomCode = (roomCode != null ? roomCode : "").replace("\\", "\\\\").replace("\"", "\\\"").replace("\r", " ").replace("\n", " ");
    String jRoomLocation = (roomLocation != null ? roomLocation : "").replace("\\", "\\\\").replace("\"", "\\\"").replace("\r", " ").replace("\n", " ");
    String jDeviceCode = (deviceCode != null ? deviceCode : "").replace("\\", "\\\\").replace("\"", "\\\"").replace("\r", " ").replace("\n", " ");
    String jLastUpdated = (lastUpdated != null ? lastUpdated : "").replace("\\", "\\\\").replace("\"", "\\\"").replace("\r", " ").replace("\n", " ");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><%= Web.esc(roomName) %> Detail – Classroom Temp Monitoring System</title>
    <link rel="shortcut icon" href="<%= ctx %>/favicon.ico" type="image/x-icon">
    <!-- Google Fonts: Inter -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="<%= ctx %>/assets/css/room-detail.css">
    <link rel="stylesheet" href="<%= ctx %>/assets/css/room-measure.css">
</head>
<body>

    <!-- 1. FIXED LEFT SIDEBAR (230px) -->
    <aside class="sidebar">
        <!-- Logo Header -->
        <div class="sidebar-logo">
            <div class="logo-box">
                <!-- Inline SVG Thermometer Icon -->
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
            <a href="<%= ctx %>/dashboard" class="menu-item" title="Overview">
                <svg class="menu-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/>
                    <polyline points="9 22 9 12 15 12 15 22"/>
                </svg>
                <span>Overview</span>
            </a>

            <a href="<%= ctx %>/admin/rooms" class="menu-item active" title="Classrooms">
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
                <span class="sidebar-badge" id="sidebarAlertBadge"><%= openAlertCount > 0 ? openAlertCount : 6 %></span>
            </a>

            <!-- Devices -->
            <% if (isAdmin) { %>
            <a href="<%= ctx %>/admin/devices" class="menu-item" title="Devices">
                <svg class="menu-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <rect x="4" y="4" width="16" height="16" rx="2"/>
                    <rect x="9" y="9" width="6" height="6"/>
                    <path d="M9 1v3M15 1v3M9 20v3M15 20v3M20 9h3M20 14h3M1 9h3M1 14h3"/>
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
    <main class="main-content">
        <!-- TOP BAR -->
        <header class="top-bar">
            <!-- Left: Hamburger Toggle & Breadcrumb Navigation -->
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
                    <a href="<%= ctx %>/admin/rooms" class="breadcrumb-item breadcrumb-link">Classrooms</a>
                    <span class="breadcrumb-separator">
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                            <polyline points="9 18 15 12 9 6"/>
                        </svg>
                    </span>
                    <span class="breadcrumb-item breadcrumb-current"><%= Web.esc(roomName) %> Detail</span>
                </nav>
            </div>

            <!-- Right: Actions, Notifications & User Profile -->
            <div class="top-bar-right">
                <% if (roomId > 0 && canManageRoom) { %>
                    <div class="top-action-group">
                        <a href="<%= ctx %>/admin/rooms/edit?id=<%= roomId %>" class="btn-top-edit" title="Edit Classroom">
                            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                                <path d="M12 20h9"/>
                                <path d="M16.5 3.5a2.121 2.121 0 0 1 3 3L7 19l-4 1 1-4L16.5 3.5z"/>
                            </svg>
                            <span>Edit</span>
                        </a>
                        <button type="button" class="btn-top-delete" onclick="openDeleteModal()" title="Delete Classroom">
                            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                                <polyline points="3 6 5 6 21 6"/>
                                <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/>
                                <line x1="10" y1="11" x2="10" y2="17"/>
                                <line x1="14" y1="11" x2="14" y2="17"/>
                            </svg>
                            <span>Delete</span>
                        </button>
                    </div>
                <% } %>
                <a href="<%= ctx %>/alerts" class="icon-btn-round" title="Notifications">
                    <svg width="19" height="19" viewBox="0 0 24 24" fill="none" stroke="#4b5563" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/>
                        <path d="M13.73 21a2 2 0 0 1-3.46 0"/>
                    </svg>
                    <span class="notif-badge" id="topBellBadge"><%= openAlertCount > 0 ? openAlertCount : 6 %></span>
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

        <!-- 3. HEADER SECTION (3 BLOCKS) -->
        <section class="room-header-section">
            <!-- Left Block: Room Title & Status -->
            <div class="header-title-block">
                <div class="room-icon-box">
                    <svg width="30" height="30" viewBox="0 0 24 24" fill="none" stroke="#ffffff" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                        <rect x="4" y="2" width="16" height="20" rx="2" ry="2"/>
                        <path d="M9 22v-4h6v4"/>
                        <path d="M8 6h.01M16 6h.01M8 10h.01M16 10h.01M8 14h.01M16 14h.01"/>
                    </svg>
                </div>
                <div class="room-meta-info">
                    <h1 class="room-main-title" id="roomTitle"><%= Web.esc(roomName) %></h1>
                    <div class="room-location-status">
                        <span class="location-tag">
                            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#6b7280" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"/>
                                <circle cx="12" cy="10" r="3"/>
                            </svg>
                            <span id="roomLocation"><%= Web.esc(roomLocation) %></span>
                        </span>
                        <span class="status-pill <%= hasSession ? "status-normal" : "status-neutral" %>" id="overallRoomStatusBadge">
                            <span class="status-dot"></span>
                            <span id="overallRoomStatusText"><%= hasSession ? "Normal" : "No Data" %></span>
                        </span>
                    </div>
                </div>
            </div>

            <!-- Middle Block: Classroom Photo Thumbnail -->
            <div class="header-photo-block">
                <img src="<%= ctx %>/assets/images/classroom_default.png" 
                     alt="Classroom Photo" 
                     class="room-photo" 
                     onerror="this.src='<%= ctx %>/assets/images/classroom_default.png'">
            </div>

            <!-- Right Block: Sensor Status Card -->
            <div class="header-sensor-card">
                <div class="sensor-card-header">
                    <div class="sensor-title-group">
                        <div class="sensor-icon-circle">
                            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#2563eb" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                <rect x="4" y="4" width="16" height="16" rx="2"/>
                                <rect x="9" y="9" width="6" height="6"/>
                                <path d="M9 1v3M15 1v3M9 20v3M15 20v3M20 9h3M20 14h3M1 9h3M1 14h3"/>
                            </svg>
                        </div>
                        <span class="card-title-text">Sensor Status</span>
                    </div>
                    <!-- Wifi Icon -->
                    <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="<%= sensorWifiColor %>" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M5 12.55a11 11 0 0 1 14.08 0"/>
                        <path d="M1.42 9a16 16 0 0 1 21.16 0"/>
                        <path d="M8.53 16.11a6 6 0 0 1 6.95 0"/>
                        <line x1="12" y1="20" x2="12.01" y2="20"/>
                    </svg>
                </div>

                <div class="sensor-card-body">
                    <div class="sensor-pill-status">
                        <span class="status-pill <%= sensorStatusBadgeClass %>">
                            <span class="status-dot"></span> <%= sensorStatusText %>
                        </span>
                    </div>
                    <div class="sensor-timestamp-group">
                        <span class="timestamp-label">Last updated</span>
                        <span class="timestamp-value" id="lastUpdatedHeader"><%= Web.esc(lastUpdated) %></span>
                    </div>
                </div>
            </div>
        </section>

        <!-- 4. FOUR METRIC CARDS (1 ROW) -->
        <section class="metric-cards-grid">
            <!-- Metric 1: Temperature -->
            <div class="metric-card" id="cardTemp">
                <div class="metric-card-top">
                    <div class="metric-icon-circle bg-blue-light">
                        <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#2563eb" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                            <path d="M14 14.76V3.5a2.5 2.5 0 0 0-5 0v11.26a4.5 4.5 0 1 0 5 0z"/>
                            <circle cx="11.5" cy="17.5" r="1.5" fill="#2563eb"/>
                        </svg>
                    </div>
                    <span class="metric-pill <%= hasSession ? "status-normal" : "status-neutral" %>" id="badgeTemp">
                        <span class="status-dot"></span> <%= hasSession ? "Normal" : "No Data" %>
                    </span>
                </div>
                <div class="metric-data-body">
                    <span class="metric-label">Temperature</span>
                    <span class="metric-big-val" id="valTemp"><%= (currentTemp != null) ? (currentTemp + "°C") : "--" %></span>
                    <span class="metric-allowed-range">(20 – 28°C)</span>
                </div>
            </div>

            <!-- Metric 2: Humidity -->
            <div class="metric-card" id="cardHumid">
                <div class="metric-card-top">
                    <div class="metric-icon-circle bg-blue-light">
                        <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#2563eb" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                            <path d="M12 2.69l5.66 5.66a8 8 0 1 1-11.31 0z"/>
                        </svg>
                    </div>
                    <span class="metric-pill <%= hasSession ? "status-normal" : "status-neutral" %>" id="badgeHumid">
                        <span class="status-dot"></span> <%= hasSession ? "Normal" : "No Data" %>
                    </span>
                </div>
                <div class="metric-data-body">
                    <span class="metric-label">Humidity</span>
                    <span class="metric-big-val" id="valHumid"><%= (currentHumid != null) ? (currentHumid.intValue() + "%") : "--" %></span>
                    <span class="metric-allowed-range">(40 – 70%)</span>
                </div>
            </div>

            <!-- Metric 3: CO2 -->
            <div class="metric-card" id="cardCo2">
                <div class="metric-card-top">
                    <div class="metric-icon-circle bg-green-light">
                        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#16a34a" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                            <path d="M17.5 19H9a7 7 0 1 1 6.71-9h1.79a4.5 4.5 0 1 1 0 9Z"/>
                        </svg>
                    </div>
                    <span class="metric-pill <%= hasSession ? "status-normal" : "status-neutral" %>" id="badgeCo2">
                        <span class="status-dot"></span> <%= hasSession ? "Normal" : "No Data" %>
                    </span>
                </div>
                <div class="metric-data-body">
                    <span class="metric-label">CO₂</span>
                    <span class="metric-big-val" id="valCo2"><%= (currentCo2 != null) ? (currentCo2 + " ppm") : "--" %></span>
                    <span class="metric-allowed-range">(≤ <%= (int)co2Max %> ppm)</span>
                </div>
            </div>

            <!-- Metric 4: CO -->
            <div class="metric-card" id="cardCo">
                <div class="metric-card-top">
                    <div class="metric-icon-circle bg-blue-light">
                        <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#2563eb" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                            <circle cx="12" cy="12" r="9"/>
                            <path d="M12 7v10M7 12h10"/>
                        </svg>
                    </div>
                    <span class="metric-pill <%= hasSession ? "status-normal" : "status-neutral" %>" id="badgeCo">
                        <span class="status-dot"></span> <%= hasSession ? "Normal" : "No Data" %>
                    </span>
                </div>
                <div class="metric-data-body">
                    <span class="metric-label">CO</span>
                    <span class="metric-big-val" id="valCo"><%= (currentCo != null) ? (currentCo + " ppm") : "--" %></span>
                    <span class="metric-allowed-range">(≤ <%= (int)coMax %> ppm)</span>
                </div>
            </div>
        </section>

        <!-- 5. TABS BAR -->
        <section class="main-tabs-card">
            <div class="tabs-nav-bar">
                <button class="main-tab-btn <%= "charts".equals(activeTab) ? "active" : "" %>" data-tab="charts">
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <polyline points="22 12 18 12 15 21 9 3 6 12 2 12"/>
                    </svg>
                    <span>Charts</span>
                </button>
                <button class="main-tab-btn <%= isMeasureTab ? "active" : "" %>" data-tab="measure">
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M13 2L3 14h9l-1 8 10-12h-9l1-8z"/>
                    </svg>
                    <span>Measure</span>
                </button>
                <button class="main-tab-btn <%= "data-history".equals(activeTab) ? "active" : "" %>" data-tab="data-history">
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <rect x="3" y="4" width="18" height="18" rx="2" ry="2"/>
                        <line x1="16" y1="2" x2="16" y2="6"/>
                        <line x1="8" y1="2" x2="8" y2="6"/>
                        <line x1="3" y1="10" x2="21" y2="10"/>
                    </svg>
                    <span>Data History</span>
                </button>
                <button class="main-tab-btn <%= "alert-history".equals(activeTab) ? "active" : "" %>" data-tab="alert-history">
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/>
                        <path d="M13.73 21a2 2 0 0 1-3.46 0"/>
                    </svg>
                    <span>Alert History</span>
                </button>
                <button class="main-tab-btn <%= "room-info".equals(activeTab) ? "active" : "" %>" data-tab="room-info">
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/>
                        <polyline points="14 2 14 8 20 8"/>
                        <line x1="16" y1="13" x2="8" y2="13"/>
                        <line x1="16" y1="17" x2="8" y2="17"/>
                        <polyline points="10 9 9 9 8 9"/>
                    </svg>
                    <span>Room Info</span>
                </button>
            </div>
        </section>

        <!-- 6. TAB CONTENT PANES -->
        <!-- Tab 1: CHARTS (2x2 grid + right column) -->
        <div id="tab-charts" class="tab-pane <%= "charts".equals(activeTab) ? "active" : "" %>">
            <div class="charts-and-side-layout">
                <!-- Left: 2x2 SVG Charts Grid -->
                <div class="charts-grid-2x2">
                    <!-- Chart 1: Temperature (°C) -->
                    <div class="chart-box-card">
                        <div class="chart-box-header">
                            <div class="chart-title-group">
                                <div class="chart-icon-round bg-blue-light">
                                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#2563eb" stroke-width="2.3" stroke-linecap="round" stroke-linejoin="round">
                                        <path d="M14 14.76V3.5a2.5 2.5 0 0 0-5 0v11.26a4.5 4.5 0 1 0 5 0z"/>
                                        <circle cx="11.5" cy="17.5" r="1.5" fill="#2563eb"/>
                                    </svg>
                                </div>
                                <h2 class="chart-header-title">Temperature (°C)</h2>
                            </div>
                            <div class="segmented-control" data-chart="temp">
                                <button class="seg-btn" data-range="1h">1h</button>
                                <button class="seg-btn active" data-range="6h">6h</button>
                                <button class="seg-btn" data-range="24h">24h</button>
                                <button class="seg-btn" data-range="7d">7d</button>
                            </div>
                        </div>

                        <div class="chart-svg-wrapper" id="chartSvgTemp"></div>

                        <div class="chart-bottom-legend">
                            <span class="legend-dot-circle bg-primary-blue"></span>
                            <span class="legend-name">Temperature (°C)</span>
                        </div>
                    </div>

                    <!-- Chart 2: Humidity (%) -->
                    <div class="chart-box-card">
                        <div class="chart-box-header">
                            <div class="chart-title-group">
                                <div class="chart-icon-round bg-teal-light">
                                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#14b8a6" stroke-width="2.3" stroke-linecap="round" stroke-linejoin="round">
                                        <path d="M12 2.69l5.66 5.66a8 8 0 1 1-11.31 0z"/>
                                    </svg>
                                </div>
                                <h2 class="chart-header-title">Humidity (%)</h2>
                            </div>
                            <div class="segmented-control" data-chart="humid">
                                <button class="seg-btn" data-range="1h">1h</button>
                                <button class="seg-btn active" data-range="6h">6h</button>
                                <button class="seg-btn" data-range="24h">24h</button>
                                <button class="seg-btn" data-range="7d">7d</button>
                            </div>
                        </div>

                        <div class="chart-svg-wrapper" id="chartSvgHumid"></div>

                        <div class="chart-bottom-legend">
                            <span class="legend-dot-circle bg-teal"></span>
                            <span class="legend-name">Humidity (%)</span>
                        </div>
                    </div>

                    <!-- Chart 3: CO2 (ppm) -->
                    <div class="chart-box-card">
                        <div class="chart-box-header">
                            <div class="chart-title-group">
                                <div class="chart-icon-round bg-amber-light">
                                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#f59e0b" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                                        <path d="M17.5 19H9a7 7 0 1 1 6.71-9h1.79a4.5 4.5 0 1 1 0 9Z"/>
                                    </svg>
                                </div>
                                <h2 class="chart-header-title">CO₂ (ppm)</h2>
                            </div>
                            <div class="segmented-control" data-chart="co2">
                                <button class="seg-btn" data-range="1h">1h</button>
                                <button class="seg-btn active" data-range="6h">6h</button>
                                <button class="seg-btn" data-range="24h">24h</button>
                                <button class="seg-btn" data-range="7d">7d</button>
                            </div>
                        </div>

                        <div class="chart-svg-wrapper" id="chartSvgCo2"></div>

                        <div class="chart-bottom-legend">
                            <span class="legend-dot-circle bg-amber"></span>
                            <span class="legend-name">CO₂ (ppm)</span>
                        </div>
                    </div>

                    <!-- Chart 4: CO (ppm) -->
                    <div class="chart-box-card">
                        <div class="chart-box-header">
                            <div class="chart-title-group">
                                <div class="chart-icon-round bg-purple-light">
                                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#8b5cf6" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                                        <circle cx="12" cy="12" r="9"/>
                                        <path d="M12 7v10M7 12h10"/>
                                    </svg>
                                </div>
                                <h2 class="chart-header-title">CO (ppm)</h2>
                            </div>
                            <div class="segmented-control" data-chart="co">
                                <button class="seg-btn" data-range="1h">1h</button>
                                <button class="seg-btn active" data-range="6h">6h</button>
                                <button class="seg-btn" data-range="24h">24h</button>
                                <button class="seg-btn" data-range="7d">7d</button>
                            </div>
                        </div>

                        <div class="chart-svg-wrapper" id="chartSvgCo"></div>

                        <div class="chart-bottom-legend">
                            <span class="legend-dot-circle bg-purple"></span>
                            <span class="legend-name">CO (ppm)</span>
                        </div>
                    </div>
                </div>

                <!-- Right Column: Two Vertical Cards -->
                <div class="side-info-column">
                    <!-- Card 1: Room Information -->
                    <div class="side-info-card">
                        <div class="side-card-title-row">
                            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#2563eb" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/>
                                <polyline points="14 2 14 8 20 8"/>
                                <line x1="16" y1="13" x2="8" y2="13"/>
                                <line x1="16" y1="17" x2="8" y2="17"/>
                            </svg>
                            <h3 class="side-card-heading">Room Information</h3>
                        </div>

                        <div class="side-info-rows">
                            <div class="side-info-item">
                                <span class="item-label">
                                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#6b7280" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="3" width="18" height="18" rx="2"/><path d="M9 9h6v6H9z"/></svg>
                                    Room ID
                                </span>
                                <span class="item-value"><%= Web.esc(roomCode) %></span>
                            </div>
                            <div class="side-info-item">
                                <span class="item-label">
                                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#6b7280" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="4" y="2" width="16" height="20" rx="2" ry="2"/><path d="M9 22v-4h6v4"/></svg>
                                    Building
                                </span>
                                <span class="item-value"><%= Web.esc(roomLocation) %></span>
                            </div>
                            <div class="side-info-item">
                                <span class="item-label">
                                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#6b7280" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="12" y1="19" x2="12" y2="5"/><polyline points="5 12 12 5 19 12"/></svg>
                                    Sensor Node
                                </span>
                                <span class="item-value"><%= Web.esc(deviceCode) %></span>
                            </div>
                            <div class="side-info-item">
                                <span class="item-label">
                                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#6b7280" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z"/></svg>
                                    Coordinates
                                </span>
                                <span class="item-value"><%= (item != null && item.getLatitude() != null && item.getLongitude() != null) ? (item.getLatitude() + ", " + item.getLongitude()) : "Not set" %></span>
                            </div>
                            <div class="side-info-item">
                                <span class="item-label">
                                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#6b7280" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/></svg>
                                    Status
                                </span>
                                <span class="item-value"><%= (item != null && item.isActive()) ? "Active" : "Inactive" %></span>
                            </div>
                        </div>

                        <div class="side-card-action-bar" style="gap: 8px;">
                            <% if (roomId > 0 && canManageRoom) { %>
                                <a href="<%= ctx %>/admin/rooms/edit?id=<%= roomId %>" class="btn-side-outline">
                                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                                        <path d="M12 20h9"/>
                                        <path d="M16.5 3.5a2.121 2.121 0 0 1 3 3L7 19l-4 1 1-4L16.5 3.5z"/>
                                    </svg>
                                    <span>Edit</span>
                                </a>
                                <button type="button" class="btn-side-danger" onclick="openDeleteModal()">
                                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                                        <polyline points="3 6 5 6 21 6"/>
                                        <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/>
                                        <line x1="10" y1="11" x2="10" y2="17"/>
                                        <line x1="14" y1="11" x2="14" y2="17"/>
                                    </svg>
                                    <span>Delete</span>
                                </button>
                            <% } %>
                        </div>
                    </div>

                    <!-- Card 2: Alert Thresholds (Settings) -->
                    <div class="side-info-card">
                        <div class="side-card-title-row">
                            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#2563eb" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                <circle cx="12" cy="12" r="3"/>
                                <path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1 0 2.83 2 2 0 0 1-2.83 0l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-2 2 2 2 0 0 1-2-2v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83 0 2 2 0 0 1 0-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1-2-2 2 2 0 0 1 2-2h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 0-2.83 2 2 0 0 1 2.83 0l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 2-2 2 2 0 0 1 2 2v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 0 2 2 0 0 1 0 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 2 2 2 2 0 0 1-2 2h-.09a1.65 1.65 0 0 0-1.51 1z"/>
                            </svg>
                            <h3 class="side-card-heading">Alert Thresholds (Settings)</h3>
                        </div>

                        <div class="side-info-rows">
                            <div class="side-info-item">
                                <span class="item-label">
                                    <div class="tiny-icon-circle bg-red-soft">
                                        <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="#ef4444" stroke-width="2.5"><path d="M14 14.76V3.5a2.5 2.5 0 0 0-5 0v11.26a4.5 4.5 0 1 0 5 0z"/></svg>
                                    </div>
                                    Temperature
                                </span>
                                <span class="item-value">≤ <%= (tempMax % 1 == 0 ? (int)tempMax : String.format(Locale.US, "%.1f", tempMax)) %>°C</span>
                            </div>
                            <div class="side-info-item">
                                <span class="item-label">
                                    <div class="tiny-icon-circle bg-blue-soft">
                                        <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="#2563eb" stroke-width="2.5"><path d="M12 2.69l5.66 5.66a8 8 0 1 1-11.31 0z"/></svg>
                                    </div>
                                    Humidity
                                </span>
                                <span class="item-value">≤ <%= (humidMax % 1 == 0 ? (int)humidMax : String.format(Locale.US, "%.1f", humidMax)) %>%</span>
                            </div>
                            <div class="side-info-item">
                                <span class="item-label">
                                    <div class="tiny-icon-circle bg-green-soft">
                                        <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="#16a34a" stroke-width="2.5"><path d="M17.5 19H9a7 7 0 1 1 6.71-9h1.79a4.5 4.5 0 1 1 0 9Z"/></svg>
                                    </div>
                                    CO₂
                                </span>
                                <span class="item-value">≤ <%= (int)co2Max %> ppm</span>
                            </div>
                            <div class="side-info-item">
                                <span class="item-label">
                                    <div class="tiny-icon-circle bg-purple-soft">
                                        <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="#8b5cf6" stroke-width="2.5"><circle cx="12" cy="12" r="9"/></svg>
                                    </div>
                                    CO
                                </span>
                                <span class="item-value">≤ <%= (int)coMax %> ppm</span>
                            </div>
                        </div>

                        <div class="side-card-action-bar">
                            <button class="btn-side-outline" id="btnConfigThresholds">
                                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1 0 2.83 2 2 0 0 1-2.83 0l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-2 2 2 2 0 0 1-2-2v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83 0 2 2 0 0 1 0 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 2 2 2 2 0 0 1-2 2h-.09a1.65 1.65 0 0 0-1.51 1z"/></svg>
                                <span>Configure thresholds</span>
                            </button>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Tab: MEASURE (Manual Measurement Station) -->
        <div id="tab-measure" class="tab-pane <%= isMeasureTab ? "active" : "" %>" 
             data-ctx="<%= ctx %>" 
             data-room-code="<%= Web.esc(roomCode) %>" 
             data-has-device="<%= hasActiveDevice %>" 
             data-can-start="<%= canStartMeasure %>">

            <!-- 1. Device Info & Start Action Card -->
            <div class="measure-top-card">
                <div class="measure-header-row">
                    <div class="measure-title-group">
                        <h3>
                            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#2563eb" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                                <path d="M13 2L3 14h9l-1 8 10-12h-9l1-8z"/>
                            </svg>
                            Manual Measurement Station
                        </h3>
                        <p>Trigger an on-demand 5-second measurement packet from the assigned IoT sensor node and evaluate against thresholds.</p>
                        
                        <div class="measure-device-meta">
                            <span class="device-meta-pill">
                                Sensor Node: <strong><%= activeDevice != null ? Web.esc(activeDevice.getDeviceCode()) : "None" %></strong>
                            </span>
                            <span class="device-meta-pill">
                                Device Status: 
                                <span class="status-pill <%= hasActiveDevice ? "status-normal" : "status-warning" %>" style="padding: 2px 8px; font-size: 11.5px;">
                                    <span class="status-dot"></span> <%= hasActiveDevice ? "Active" : "Inactive" %>
                                </span>
                            </span>
                            <span class="device-meta-pill">
                                Last Seen: <strong><%= (activeDevice != null && activeDevice.getLastSeen() != null) ? Web.esc(activeDevice.getLastSeen().toString()) : "Never" %></strong>
                            </span>
                        </div>
                    </div>

                    <div class="measure-action-group">
                        <% if (canStartMeasure) { %>
                            <button type="button" id="btnStartMeasure" class="btn-measure-start" <%= !hasActiveDevice ? "disabled" : "" %>>
                                <svg class="btn-icon" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.3">
                                    <polygon points="5 3 19 12 5 21 5 3"/>
                                </svg>
                                <span class="btn-text">Start Measurement</span>
                                <span class="spinner-border" style="display: none;"></span>
                            </button>
                        <% } else { %>
                            <div class="measure-perm-notice">
                                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#6b7280" stroke-width="2">
                                    <rect x="3" y="11" width="18" height="11" rx="2" ry="2"/>
                                    <path d="M7 11V7a5 5 0 0 1 10 0v4"/>
                                </svg>
                                <span>You do not have permission to start a measurement.</span>
                            </div>
                        <% } %>
                    </div>
                </div>

                <% if (!hasActiveDevice) { %>
                    <div class="measure-alert-banner alert-warning">
                        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#b45309" stroke-width="2">
                            <path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/>
                            <line x1="12" y1="9" x2="12" y2="13"/>
                            <line x1="12" y1="17" x2="12.01" y2="17"/>
                        </svg>
                        <span>No active device is assigned to this room.</span>
                    </div>
                <% } %>

                <div id="measureStatusMessage" class="measure-alert-banner alert-danger" style="display: none;"></div>
            </div>

            <!-- 2. Stepper Progress Card -->
            <div class="measure-stepper-card">
                <div class="stepper-header">
                    <span class="stepper-title">Measurement Workflow Status</span>
                    <span id="measureTimerBadge" class="stepper-timer-badge" style="display: none;">
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <circle cx="12" cy="12" r="10"/>
                            <polyline points="12 6 12 12 16 14"/>
                        </svg>
                        Elapsed: <span id="measureTimer">0</span>s
                    </span>
                </div>

                <div class="measure-stepper" aria-live="polite">
                    <div id="stepLine1" class="step-line step-line-1"></div>
                    <div id="stepLine2" class="step-line step-line-2"></div>

                    <!-- Step 1: Pending -->
                    <div id="stepNodePending" class="step-node">
                        <div class="step-circle">1</div>
                        <span class="step-label">Pending</span>
                        <span class="step-sub">Command queued</span>
                    </div>

                    <!-- Step 2: Measuring -->
                    <div id="stepNodeMeasuring" class="step-node">
                        <div class="step-circle">2</div>
                        <span class="step-label">Measuring</span>
                        <span class="step-sub">Device acquiring (5s)</span>
                    </div>

                    <!-- Step 3: Done -->
                    <div id="stepNodeDone" class="step-node">
                        <div class="step-circle">3</div>
                        <span class="step-label">Done</span>
                        <span class="step-sub">Telemetry received</span>
                    </div>
                </div>
            </div>

            <!-- 3. Four Metric Cards -->
            <div class="measure-metrics-grid">
                <!-- Temperature -->
                <div class="measure-metric-card" id="measureCardTemp">
                    <div class="measure-metric-top">
                        <div class="measure-metric-icon bg-blue-light">
                            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#2563eb" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                                <path d="M14 14.76V3.5a2.5 2.5 0 0 0-5 0v11.26a4.5 4.5 0 1 0 5 0z"/>
                                <circle cx="11.5" cy="17.5" r="1.5" fill="#2563eb"/>
                            </svg>
                        </div>
                        <span class="metric-pill status-neutral" id="measureBadgeTemp">Waiting</span>
                    </div>
                    <span class="measure-metric-label">Temperature</span>
                    <span class="measure-metric-val" id="measureValTemp">--</span>
                    <span class="measure-metric-threshold" id="measureThreshTemp" style="display: none;">Threshold: ≤ <%= (tempMax % 1 == 0 ? (int)tempMax : String.format(Locale.US, "%.1f", tempMax)) %>°C</span>
                </div>

                <!-- Humidity -->
                <div class="measure-metric-card" id="measureCardHumid">
                    <div class="measure-metric-top">
                        <div class="measure-metric-icon bg-teal-light">
                            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#14b8a6" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                                <path d="M12 2.69l5.66 5.66a8 8 0 1 1-11.31 0z"/>
                            </svg>
                        </div>
                        <span class="metric-pill status-neutral" id="measureBadgeHumid">Waiting</span>
                    </div>
                    <span class="measure-metric-label">Humidity</span>
                    <span class="measure-metric-val" id="measureValHumid">--</span>
                    <span class="measure-metric-threshold" id="measureThreshHumid" style="display: none;">Threshold: ≤ <%= (humidMax % 1 == 0 ? (int)humidMax : String.format(Locale.US, "%.1f", humidMax)) %>%</span>
                </div>

                <!-- CO2 -->
                <div class="measure-metric-card" id="measureCardCo2">
                    <div class="measure-metric-top">
                        <div class="measure-metric-icon bg-amber-light">
                            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#f59e0b" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                                <path d="M17.5 19H9a7 7 0 1 1 6.71-9h1.79a4.5 4.5 0 1 1 0 9Z"/>
                            </svg>
                        </div>
                        <span class="metric-pill status-neutral" id="measureBadgeCo2">Waiting</span>
                    </div>
                    <span class="measure-metric-label">CO₂ Level</span>
                    <span class="measure-metric-val" id="measureValCo2">--</span>
                    <span class="measure-metric-threshold" id="measureThreshCo2" style="display: none;">Threshold: ≤ <%= (int)co2Max %> ppm</span>
                </div>

                <!-- CO -->
                <div class="measure-metric-card" id="measureCardCo">
                    <div class="measure-metric-top">
                        <div class="measure-metric-icon bg-purple-light">
                            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#8b5cf6" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                                <circle cx="12" cy="12" r="9"/>
                                <path d="M12 7v10M7 12h10"/>
                            </svg>
                        </div>
                        <span class="metric-pill status-neutral" id="measureBadgeCo">Waiting</span>
                    </div>
                    <span class="measure-metric-label">CO Level</span>
                    <span class="measure-metric-val" id="measureValCo">--</span>
                    <span class="measure-metric-threshold" id="measureThreshCo" style="display: none;">Threshold: ≤ <%= (int)coMax %> ppm</span>
                </div>
            </div>

            <!-- 4. Real-time Measurement Alerts Section -->
            <div class="measure-section-card">
                <div class="measure-section-header">
                    <div class="measure-section-title">
                        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#ef4444" stroke-width="2.2">
                            <circle cx="12" cy="12" r="10"/>
                            <line x1="12" y1="8" x2="12" y2="12"/>
                            <line x1="12" y1="16" x2="12.01" y2="16"/>
                        </svg>
                        <span>Measurement Alerts &amp; Threshold Evaluations</span>
                    </div>
                </div>
                <div id="measureAlertsContainer">
                    <div class="measure-empty-state">
                        Measurement not started yet.
                    </div>
                </div>
            </div>

            <!-- 5. Recent Measurements History (Top 10 Sessions) -->
            <div class="measure-section-card">
                <div class="measure-section-header">
                    <div class="measure-section-title">
                        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#2563eb" stroke-width="2">
                            <circle cx="12" cy="12" r="10"/>
                            <polyline points="12 6 12 12 16 14"/>
                        </svg>
                        <span>Recent Measurements History (Last 10 Records)</span>
                    </div>
                </div>
                <div class="table-responsive">
                    <table class="alert-table" id="measureHistoryTable">
                        <thead>
                            <tr>
                                <th>Timestamp</th>
                                <th>Temperature</th>
                                <th>Humidity</th>
                                <th>CO₂ Level</th>
                                <th>CO Level</th>
                                <th>Status</th>
                            </tr>
                        </thead>
                        <tbody id="measureHistoryTbody">
                            <% 
                            int histCount = 0;
                            if (recentSessions != null && !recentSessions.isEmpty()) { 
                                for (AirSession s : recentSessions) { 
                                    if (histCount >= 10) break;
                                    histCount++;
                                    Double sTemp = (s.getTemperature() != null) ? Math.round(s.getTemperature() * 10.0) / 10.0 : (s.getTempC() > 0 ? Math.round(s.getTempC() * 10.0) / 10.0 : null);
                                    Double sHumid = (s.getHumid() != null) ? Math.round(s.getHumid() * 10.0) / 10.0 : (s.getHumidPct() > 0 ? Math.round(s.getHumidPct() * 10.0) / 10.0 : null);
                                    Integer sCo2 = (s.getCo2() != null) ? s.getCo2() : s.getGasARaw();
                                    Double sCo = (s.getCo() != null) ? s.getCo().doubleValue() : (s.getGasBRaw() > 0 ? (double) s.getGasBRaw() : 0.0);
                                    String sTime = (s.getMeasuredAt() != null) ? s.getMeasuredAt().toString() : "–";
                                    boolean isNormal = (sTemp == null || sTemp <= tempMax) && (sHumid == null || sHumid <= humidMax) && (sCo2 == null || sCo2 <= co2Max) && (sCo == null || sCo <= coMax);
                            %>
                            <tr>
                                <td><%= Web.esc(sTime) %></td>
                                <td><%= (sTemp != null ? sTemp + "°C" : "–") %></td>
                                <td><%= (sHumid != null ? (int)sHumid.doubleValue() + "%" : "–") %></td>
                                <td><%= (sCo2 != null ? sCo2 + " ppm" : "–") %></td>
                                <td><%= (sCo != null ? (sCo % 1 == 0 ? (int)sCo.doubleValue() : sCo) + " ppm" : "–") %></td>
                                <td>
                                    <span class="status-pill <%= isNormal ? "status-normal" : "status-warning" %>">
                                        <span class="status-dot"></span> <%= isNormal ? "Normal" : "Warning" %>
                                    </span>
                                </td>
                            </tr>
                            <%  }
                            } else { %>
                            <tr>
                                <td colspan="6" style="text-align: center; padding: 24px 16px; color: #94a3b8; font-weight: 500;">
                                    No measurements recorded for this room yet.
                                </td>
                            </tr>
                            <% } %>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>

        <!-- Tab 2: DATA HISTORY (Telemetry Logs) -->
        <div id="tab-data-history" class="tab-pane <%= "data-history".equals(activeTab) ? "active" : "" %>">
            <div class="simple-card-pane">
                <h3 class="pane-title">Historical Telemetry Logs</h3>
                <p class="pane-subtitle">Recent measurement packets recorded from sensor node <%= Web.esc(deviceCode) %></p>
                <div class="table-responsive">
                    <table class="alert-table">
                        <thead>
                            <tr>
                                <th>Timestamp</th>
                                <th>Temperature</th>
                                <th>Humidity</th>
                                <th>CO₂ Level</th>
                                <th>CO Level</th>
                                <th>Status</th>
                            </tr>
                        </thead>
                        <tbody>
                            <% if (recentSessions != null && !recentSessions.isEmpty()) { %>
                                <% for (AirSession s : recentSessions) { 
                                    Double sTemp = (s.getTemperature() != null) ? Math.round(s.getTemperature() * 10.0) / 10.0 : (s.getTempC() > 0 ? Math.round(s.getTempC() * 10.0) / 10.0 : null);
                                    Double sHumid = (s.getHumid() != null) ? Math.round(s.getHumid() * 10.0) / 10.0 : (s.getHumidPct() > 0 ? Math.round(s.getHumidPct() * 10.0) / 10.0 : null);
                                    Integer sCo2 = (s.getCo2() != null) ? s.getCo2() : s.getGasARaw();
                                    Double sCo = (s.getCo() != null) ? s.getCo().doubleValue() : (s.getGasBRaw() > 0 ? (double) s.getGasBRaw() : 0.0);
                                    String sTime = (s.getMeasuredAt() != null) ? s.getMeasuredAt().toString() : "–";
                                    boolean isNormal = (sTemp == null || sTemp <= tempMax) && (sHumid == null || sHumid <= humidMax) && (sCo2 == null || sCo2 <= co2Max) && (sCo == null || sCo <= coMax);
                                %>
                                <tr>
                                    <td><%= Web.esc(sTime) %></td>
                                    <td><%= (sTemp != null ? sTemp + "°C" : "–") %></td>
                                    <td><%= (sHumid != null ? (int)sHumid.doubleValue() + "%" : "–") %></td>
                                    <td><%= (sCo2 != null ? sCo2 + " ppm" : "–") %></td>
                                    <td><%= (sCo != null ? (sCo % 1 == 0 ? (int)sCo.doubleValue() : sCo) + " ppm" : "–") %></td>
                                    <td>
                                        <span class="status-pill <%= isNormal ? "status-normal" : "status-warning" %>">
                                            <span class="status-dot"></span> <%= isNormal ? "Normal" : "Warning" %>
                                        </span>
                                    </td>
                                </tr>
                                <% } %>
                            <% } else { %>
                                <tr>
                                    <td colspan="6" style="text-align: center; padding: 36px 16px; color: #94a3b8; font-weight: 500;">
                                        No telemetry records found for this room.
                                    </td>
                                </tr>
                            <% } %>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>

        <!-- Tab 3: ALERT HISTORY (Standalone) -->
        <div id="tab-alert-history" class="tab-pane">
            <div class="simple-card-pane">
                <h3 class="pane-title">Complete Alert History for <%= Web.esc(roomName) %></h3>
                <p class="pane-subtitle">Review all historical events, warnings, and resolved incident logs.</p>
                <div class="table-responsive" id="tabAlertTableContainer">
                    <% if (recentAlerts != null && !recentAlerts.isEmpty()) { %>
                        <table class="alert-table">
                            <thead>
                                <tr>
                                    <th style="width: 150px;">Alert Code</th>
                                    <th>Message</th>
                                    <th style="width: 130px;">Status</th>
                                    <th style="width: 170px;">Handled By</th>
                                    <th style="width: 200px;">Note</th>
                                    <th style="width: 170px;">Time</th>
                                </tr>
                            </thead>
                            <tbody>
                                <% for (AirAlert al : recentAlerts) { 
                                    String code = (al.getAlertCode() != null && !al.getAlertCode().isEmpty()) ? al.getAlertCode() : "–";
                                    String msg = (al.getMessage() != null && !al.getMessage().isEmpty()) ? al.getMessage() : "–";
                                    String rawStatus = (al.getStatus() != null) ? al.getStatus().toUpperCase() : "OPENING";
                                    String statusBadgeClass;
                                    String statusText;
                                    if ("APPROVED".equals(rawStatus)) {
                                        statusBadgeClass = "table-status-pill status-resolved";
                                        statusText = "APPROVED";
                                    } else if ("REJECTED".equals(rawStatus)) {
                                        statusBadgeClass = "table-status-pill status-rejected";
                                        statusText = "REJECTED";
                                    } else {
                                        statusBadgeClass = "table-status-pill status-progress";
                                        statusText = "OPENING";
                                    }
                                    String handledByName = (al.getHandledByName() != null && !al.getHandledByName().trim().isEmpty()) 
                                            ? al.getHandledByName() 
                                            : (al.getHandledBy() != null ? ("User #" + al.getHandledBy()) : "–");
                                    String note = (al.getNote() != null && !al.getNote().trim().isEmpty()) ? al.getNote() : "–";
                                    String alTime = (al.getCreatedAt() != null) ? al.getCreatedAt().toString() : "–";
                                %>
                                <tr>
                                    <td>
                                        <span class="alert-code-pill"><%= Web.esc(code) %></span>
                                    </td>
                                    <td>
                                        <div class="alert-message-text"><%= Web.esc(msg) %></div>
                                    </td>
                                    <td>
                                        <span class="<%= statusBadgeClass %>">
                                            <span class="status-dot"></span> <%= statusText %>
                                        </span>
                                    </td>
                                    <td>
                                        <div class="cell-user-wrapper">
                                            <% if (!"–".equals(handledByName)) { %>
                                                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#2563eb" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" style="flex-shrink: 0;">
                                                    <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/>
                                                    <circle cx="12" cy="7" r="4"/>
                                                </svg>
                                            <% } %>
                                            <span class="user-name-text"><%= Web.esc(handledByName) %></span>
                                        </div>
                                    </td>
                                    <td>
                                        <span class="alert-note-text"><%= Web.esc(note) %></span>
                                    </td>
                                    <td>
                                        <div class="cell-time-wrapper">
                                            <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" stroke-width="2">
                                                <circle cx="12" cy="12" r="10"/>
                                                <polyline points="12 6 12 12 16 14"/>
                                            </svg>
                                            <span><%= Web.esc(alTime) %></span>
                                        </div>
                                    </td>
                                </tr>
                                <% } %>
                            </tbody>
                        </table>
                    <% } else { %>
                        <div style="text-align: center; padding: 48px 16px; color: #94a3b8; font-weight: 500;">
                            <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" stroke-width="2" style="margin-bottom: 8px; display: block; margin-left: auto; margin-right: auto;">
                                <circle cx="12" cy="12" r="10"/>
                                <line x1="12" y1="8" x2="12" y2="12"/>
                                <line x1="12" y1="16" x2="12.01" y2="16"/>
                            </svg>
                            No alerts recorded for this classroom.
                        </div>
                    <% } %>
                </div>
            </div>
        </div>

        <!-- Tab 4: ROOM INFO (Extended Details) -->
        <div id="tab-room-info" class="tab-pane">
            <div class="simple-card-pane">
                <h3 class="pane-title">Room Specifications & Hardware Setup</h3>
                <p class="pane-subtitle">Detailed architectural specifications and deployed IoT telemetry hardware.</p>
                <div class="info-data-grid">
                    <div class="info-card-box">
                        <h4>Space Details</h4>
                        <p><strong>Code:</strong> <%= Web.esc(roomCode) %></p>
                        <p><strong>Room Name:</strong> <%= Web.esc(roomName) %></p>
                        <p><strong>Location:</strong> <%= Web.esc(roomLocation) %></p>
                        <p><strong>Coordinates:</strong> <%= (item != null && item.getLatitude() != null && item.getLongitude() != null) ? (item.getLatitude() + ", " + item.getLongitude()) : "Not set" %></p>
                        <p><strong>Note:</strong> <%= (item != null && item.getNote() != null) ? Web.esc(item.getNote()) : "Classroom monitoring station" %></p>
                    </div>
                    <div class="info-card-box">
                        <h4>Equipment Specs</h4>
                        <p><strong>Sensor Node Code:</strong> <%= Web.esc(deviceCode) %></p>
                        <p><strong>Microcontroller:</strong> ESP32-WROOM-32D</p>
                        <p><strong>Sensors:</strong> MQ-7 (CO), MQ-135 (CO₂/Air Quality), DHT22 (Temp & Humid)</p>
                        <p><strong>Drift Calibration:</strong> Max Baseline Shift <%= (item != null ? item.getMaxBaselineDrift() : 5.0f) %></p>
                        <p><strong>Connection:</strong> Wi-Fi 2.4GHz IEEE 802.11 b/g/n</p>
                    </div>
                </div>
            </div>
        </div>
    </main>

    <!-- INJECT DYNAMIC DATA TO JAVASCRIPT OBJECTS -->
    <script>
        window.SERVER_ROOM_DATA = {
            id: <%= roomId %>,
            code: "<%= jRoomCode %>",
            name: "<%= jRoomName %>",
            location: "<%= jRoomLocation %>",
            sensorId: "<%= jDeviceCode %>",
            lastUpdated: "<%= jLastUpdated %>",
            hasData: <%= hasSession %>,
            temp: <%= (currentTemp != null) ? String.format(Locale.US, "%.1f", currentTemp) : "null" %>,
            humid: <%= (currentHumid != null) ? String.format(Locale.US, "%.1f", currentHumid) : "null" %>,
            co2: <%= (currentCo2 != null) ? currentCo2 : "null" %>,
            co: <%= (currentCo != null) ? String.format(Locale.US, "%.1f", currentCo) : "null" %>,
            tempMax: <%= String.format(Locale.US, "%.1f", tempMax) %>,
            humidMax: <%= String.format(Locale.US, "%.1f", humidMax) %>,
            coMax: <%= String.format(Locale.US, "%.1f", coMax) %>,
            co2Max: <%= String.format(Locale.US, "%.1f", co2Max) %>
        };

        window.SERVER_SESSIONS_DATA = [
            <% if (recentSessions != null && !recentSessions.isEmpty()) { 
                for (int sIdx = 0; sIdx < recentSessions.size(); sIdx++) {
                    AirSession s = recentSessions.get(sIdx);
                    String sTime = (s.getMeasuredAt() != null) ? s.getMeasuredAt().toString() : "";
                    double st = (s.getTemperature() != null) ? Math.round(s.getTemperature() * 10.0) / 10.0 : (s.getTempC() > 0 ? Math.round(s.getTempC() * 10.0) / 10.0 : 0.0);
                    double sh = (s.getHumid() != null) ? Math.round(s.getHumid() * 10.0) / 10.0 : (s.getHumidPct() > 0 ? Math.round(s.getHumidPct() * 10.0) / 10.0 : 0.0);
                    int sco2 = (s.getCo2() != null) ? s.getCo2() : s.getGasARaw();
                    double sco = (s.getCo() != null) ? s.getCo().doubleValue() : (s.getGasBRaw() > 0 ? (double) s.getGasBRaw() : 0.0);
                    long epochMs = (s.getMeasuredAt() != null) ? s.getMeasuredAt().getTime() : 0L;
            %>
            {
                time: "<%= sTime %>",
                epochMs: <%= epochMs %>,
                temp: <%= String.format(Locale.US, "%.1f", st) %>,
                humid: <%= String.format(Locale.US, "%.1f", sh) %>,
                co2: <%= sco2 %>,
                co: <%= String.format(Locale.US, "%.1f", sco) %>
            }<%= (sIdx < recentSessions.size() - 1) ? "," : "" %>
            <%  }
               } %>
        ];

        window.SERVER_ALERT_DATA = [
            <% if (recentAlerts != null && !recentAlerts.isEmpty()) { %>
            <% for (int aIdx = 0; aIdx < recentAlerts.size(); aIdx++) { 
                AirAlert al = recentAlerts.get(aIdx);
                String code = (al.getAlertCode() != null && !al.getAlertCode().isEmpty()) ? al.getAlertCode() : "–";
                String msg = (al.getMessage() != null && !al.getMessage().isEmpty()) ? al.getMessage() : "–";
                String rawStatus = (al.getStatus() != null) ? al.getStatus().toUpperCase() : "OPENING";
                String alStatus = "APPROVED".equals(rawStatus) ? "APPROVED" : ("REJECTED".equals(rawStatus) ? "REJECTED" : "OPENING");
                String alStatusClass = "APPROVED".equals(rawStatus) ? "resolved" : ("REJECTED".equals(rawStatus) ? "rejected" : "progress");
                String handledByName = (al.getHandledByName() != null && !al.getHandledByName().trim().isEmpty()) 
                        ? al.getHandledByName() 
                        : (al.getHandledBy() != null ? ("User #" + al.getHandledBy()) : "–");
                String note = (al.getNote() != null && !al.getNote().trim().isEmpty()) ? al.getNote() : "–";
                String alTime = (al.getCreatedAt() != null) ? al.getCreatedAt().toString() : "–";

                code = code.replace("\\", "\\\\").replace("\"", "\\\"").replace("\r", " ").replace("\n", " ");
                msg = msg.replace("\\", "\\\\").replace("\"", "\\\"").replace("\r", " ").replace("\n", " ");
                handledByName = handledByName.replace("\\", "\\\\").replace("\"", "\\\"").replace("\r", " ").replace("\n", " ");
                note = note.replace("\\", "\\\\").replace("\"", "\\\"").replace("\r", " ").replace("\n", " ");
                alTime = alTime.replace("\\", "\\\\").replace("\"", "\\\"").replace("\r", " ").replace("\n", " ");
            %>
            {
                id: <%= al.getAlertId() %>,
                alertCode: "<%= code %>",
                message: "<%= msg %>",
                status: "<%= alStatus %>",
                statusCode: "<%= alStatusClass %>",
                handledByName: "<%= handledByName %>",
                note: "<%= note %>",
                time: "<%= alTime %>"
            }<%= (aIdx < recentAlerts.size() - 1) ? "," : "" %>
            <% } %>
            <% } %>
        ];
    </script>
    <!-- DELETE ROOM CONFIRMATION MODAL -->
    <div id="deleteModal" class="custom-modal-overlay" style="display: none;">
        <div class="custom-modal-box">
            <div class="custom-modal-icon-danger">
                <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="#ef4444" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                    <polyline points="3 6 5 6 21 6"/>
                    <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/>
                    <line x1="10" y1="11" x2="10" y2="17"/>
                    <line x1="14" y1="11" x2="14" y2="17"/>
                </svg>
            </div>
            <h3 class="custom-modal-title">Delete Classroom</h3>
            <p class="custom-modal-desc">
                Are you sure you want to delete classroom <strong><%= Web.esc(roomName) %></strong> (<%= Web.esc(roomCode) %>)?
                This action will permanently delete the room and unassign any connected sensor devices.
            </p>
            <form method="post" action="<%= ctx %>/admin/rooms/delete" id="deleteRoomForm">
                <input type="hidden" name="id" value="<%= roomId %>">
                <div class="custom-modal-actions">
                    <button type="button" class="modal-btn-cancel" onclick="closeDeleteModal()">Cancel</button>
                    <button type="submit" class="modal-btn-delete">Delete Classroom</button>
                </div>
            </form>
        </div>
    </div>

    <script>
        function openDeleteModal() {
            var modal = document.getElementById('deleteModal');
            if (modal) modal.style.display = 'flex';
        }
        function closeDeleteModal() {
            var modal = document.getElementById('deleteModal');
            if (modal) modal.style.display = 'none';
        }
        window.addEventListener('click', function(e) {
            var modal = document.getElementById('deleteModal');
            if (e.target === modal) {
                closeDeleteModal();
            }
        });
    </script>
    <script src="<%= ctx %>/assets/js/room-detail.js?v=<%= System.currentTimeMillis() %>"></script>
    <script src="<%= ctx %>/assets/js/room-measure.js?v=<%= System.currentTimeMillis() %>"></script>
</body>
</html>
