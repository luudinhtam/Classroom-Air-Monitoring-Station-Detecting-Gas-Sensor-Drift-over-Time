<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.util.*, java.time.format.DateTimeFormatter, model.*, util.Web"%>
<%
    Room item = (Room) request.getAttribute("detail");
    AirSession latestSession = (AirSession) request.getAttribute("latestSession");
    List<AirSession> recentSessions = (List<AirSession>) request.getAttribute("recentSessions");
    List<AirAlert> recentAlerts = (List<AirAlert>) request.getAttribute("recentAlerts");
    AppUser me = (AppUser) session.getAttribute("user");
    String ctx = request.getContextPath();

    String userName = (me != null && me.getFullName() != null) ? me.getFullName() : "Admin User";
    String userRole = (me != null && me.getRoleCode() != null) ? me.getRoleCode() : "ADMIN";

    String roomName = (item != null && item.getName() != null) ? item.getName() : "Room A101";
    String roomCode = (item != null && item.getCode() != null) ? item.getCode() : "A101";
    String roomLocation = (item != null && item.getLocation() != null) ? item.getLocation() : "Building A · Floor 1";
    String deviceCode = (item != null && item.getDeviceCode() != null && !item.getDeviceCode().trim().isEmpty()) 
                        ? item.getDeviceCode() : "TH-A101-001";
    int roomId = (item != null) ? item.getRoomId() : 0;
    float coMax = (item != null && item.getCoWarningThreshold() > 0) ? item.getCoWarningThreshold() : 10.0f;
    float co2Max = (item != null && item.getCo2WarningThreshold() > 0) ? item.getCo2WarningThreshold() : 1000.0f;
    
    double currentTemp = (latestSession != null && latestSession.getTempC() != null) 
                         ? Math.round(latestSession.getTempC() * 10.0) / 10.0 : 24.8;
    double currentHumid = (latestSession != null && latestSession.getHumidPct() != null) 
                          ? Math.round(latestSession.getHumidPct() * 10.0) / 10.0 : 56.0;
    double currentCo2 = 652.0;
    double currentCo = 1.2;

    String lastUpdated = (latestSession != null && latestSession.getMeasuredAt() != null)
                         ? latestSession.getMeasuredAt().toString() : "21/10/2025 13:45:20";
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

            <a href="<%= ctx %>/admin/rooms" class="menu-item active" title="Room List">
                <svg class="menu-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <rect x="4" y="2" width="16" height="20" rx="2" ry="2"/>
                    <path d="M9 22v-4h6v4"/>
                    <path d="M8 6h.01M16 6h.01M8 10h.01M16 10h.01M8 14h.01M16 14h.01"/>
                </svg>
                <span>Room List</span>
            </a>

            <a href="<%= ctx %>/sessions" class="menu-item" title="Charts & History">
                <svg class="menu-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <polyline points="22 12 18 12 15 21 9 3 6 12 2 12"/>
                </svg>
                <span>Charts & History</span>
            </a>

            <a href="<%= ctx %>/alerts" class="menu-item" title="Alerts">
                <svg class="menu-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/>
                    <path d="M13.73 21a2 2 0 0 1-3.46 0"/>
                </svg>
                <span>Alerts</span>
                <span class="sidebar-badge">2</span>
            </a>

            <a href="<%= ctx %>/admin/devices" class="menu-item" title="Settings & Devices">
                <svg class="menu-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <circle cx="12" cy="12" r="3"/>
                    <path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1 0 2.83 2 2 0 0 1-2.83 0l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-2 2 2 2 0 0 1-2-2v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83 0 2 2 0 0 1 0-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1-2-2 2 2 0 0 1 2-2h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 0-2.83 2 2 0 0 1 2.83 0l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 2-2 2 2 0 0 1 2 2v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 0 2 2 0 0 1 0 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 2 2 2 2 0 0 1-2 2h-.09a1.65 1.65 0 0 0-1.51 1z"/>
                </svg>
                <span>Settings</span>
            </a>
        </nav>

        <!-- Sidebar Footer Status -->
        <div class="sidebar-footer">
            <div class="status-live">
                <span class="live-dot"></span>
                <span class="live-text">System is running</span>
            </div>
            <div class="status-time">Updated: <%= Web.esc(lastUpdated) %></div>
        </div>
    </aside>

    <!-- 2. MAIN CONTENT AREA -->
    <main class="main-content">
        <!-- TOP BAR -->
        <header class="top-bar">
            <!-- Left: Breadcrumb Navigation -->
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
                <a href="<%= ctx %>/admin/rooms" class="breadcrumb-item breadcrumb-link">Room List</a>
                <span class="breadcrumb-separator">
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <polyline points="9 18 15 12 9 6"/>
                    </svg>
                </span>
                <span class="breadcrumb-item breadcrumb-current"><%= Web.esc(roomName) %> Detail</span>
            </nav>

            <!-- Right: Notifications & User Profile -->
            <div class="top-bar-right">
                <button class="icon-btn-round" title="Notifications">
                    <svg width="19" height="19" viewBox="0 0 24 24" fill="none" stroke="#4b5563" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/>
                        <path d="M13.73 21a2 2 0 0 1-3.46 0"/>
                    </svg>
                    <span class="notif-badge-dot"></span>
                </button>

                <div class="user-profile-badge">
                    <div class="user-avatar-circle">
                        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#2563eb" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                            <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/>
                            <circle cx="12" cy="7" r="4"/>
                        </svg>
                    </div>
                    <div class="user-profile-text">
                        <span class="user-name"><%= Web.esc(userName) %></span>
                        <span class="user-role"><%= Web.esc(userRole) %></span>
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
                        <span class="status-pill status-normal" id="overallRoomStatusBadge">
                            <span class="status-dot"></span>
                            <span id="overallRoomStatusText">Normal</span>
                        </span>
                    </div>
                </div>
            </div>

            <!-- Middle Block: Classroom Photo Thumbnail -->
            <div class="header-photo-block">
                <img src="<%= ctx %>/assets/images/classroom_default.png" 
                     alt="Classroom Photo" 
                     class="room-photo" 
                     onerror="this.src='https://images.unsplash.com/photo-1580582932707-520aed937b7b?auto=format&fit=crop&w=600&q=80'">
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
                    <!-- Wifi Icon Green -->
                    <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#16a34a" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M5 12.55a11 11 0 0 1 14.08 0"/>
                        <path d="M1.42 9a16 16 0 0 1 21.16 0"/>
                        <path d="M8.53 16.11a6 6 0 0 1 6.95 0"/>
                        <line x1="12" y1="20" x2="12.01" y2="20"/>
                    </svg>
                </div>

                <div class="sensor-card-body">
                    <div class="sensor-pill-status">
                        <span class="status-pill status-normal">
                            <span class="status-dot"></span> <%= (item != null && item.isActive()) ? "Active" : "Active" %>
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
                    <span class="metric-pill" id="badgeTemp">
                        <span class="status-dot"></span> Normal
                    </span>
                </div>
                <div class="metric-data-body">
                    <span class="metric-label">Temperature</span>
                    <span class="metric-big-val" id="valTemp"><%= currentTemp %>°C</span>
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
                    <span class="metric-pill" id="badgeHumid">
                        <span class="status-dot"></span> Normal
                    </span>
                </div>
                <div class="metric-data-body">
                    <span class="metric-label">Humidity</span>
                    <span class="metric-big-val" id="valHumid"><%= (int)currentHumid %>%</span>
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
                    <span class="metric-pill" id="badgeCo2">
                        <span class="status-dot"></span> Normal
                    </span>
                </div>
                <div class="metric-data-body">
                    <span class="metric-label">CO₂</span>
                    <span class="metric-big-val" id="valCo2"><%= (int)currentCo2 %> ppm</span>
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
                    <span class="metric-pill" id="badgeCo">
                        <span class="status-dot"></span> Normal
                    </span>
                </div>
                <div class="metric-data-body">
                    <span class="metric-label">CO</span>
                    <span class="metric-big-val" id="valCo"><%= currentCo %> ppm</span>
                    <span class="metric-allowed-range">(≤ <%= (int)coMax %> ppm)</span>
                </div>
            </div>
        </section>

        <!-- 5. TABS BAR -->
        <section class="main-tabs-card">
            <div class="tabs-nav-bar">
                <button class="main-tab-btn active" data-tab="charts">
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <polyline points="22 12 18 12 15 21 9 3 6 12 2 12"/>
                    </svg>
                    <span>Charts</span>
                </button>
                <button class="main-tab-btn" data-tab="data-history">
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <rect x="3" y="4" width="18" height="18" rx="2" ry="2"/>
                        <line x1="16" y1="2" x2="16" y2="6"/>
                        <line x1="8" y1="2" x2="8" y2="6"/>
                        <line x1="3" y1="10" x2="21" y2="10"/>
                    </svg>
                    <span>Data History</span>
                </button>
                <button class="main-tab-btn" data-tab="alert-history">
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/>
                        <path d="M13.73 21a2 2 0 0 1-3.46 0"/>
                    </svg>
                    <span>Alert History</span>
                </button>
                <button class="main-tab-btn" data-tab="room-info">
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
        <div id="tab-charts" class="tab-pane active">
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
                                <span class="item-value"><%= (item != null && item.getLatitude() != null) ? item.getLatitude() + ", " + item.getLongitude() : "10.03, 105.78" %></span>
                            </div>
                            <div class="side-info-item">
                                <span class="item-label">
                                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#6b7280" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/></svg>
                                    Status
                                </span>
                                <span class="item-value"><%= (item != null && item.isActive()) ? "Active" : "Active" %></span>
                            </div>
                        </div>

                        <div class="side-card-action-bar">
                            <% if (roomId > 0) { %>
                                <a href="<%= ctx %>/admin/rooms/edit?id=<%= roomId %>" class="btn-side-outline">
                                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                                        <path d="M12 20h9"/>
                                        <path d="M16.5 3.5a2.121 2.121 0 0 1 3 3L7 19l-4 1 1-4L16.5 3.5z"/>
                                    </svg>
                                    <span>Edit</span>
                                </a>
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
                                <span class="item-value">20 – 28°C</span>
                            </div>
                            <div class="side-info-item">
                                <span class="item-label">
                                    <div class="tiny-icon-circle bg-blue-soft">
                                        <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="#2563eb" stroke-width="2.5"><path d="M12 2.69l5.66 5.66a8 8 0 1 1-11.31 0z"/></svg>
                                    </div>
                                    Humidity
                                </span>
                                <span class="item-value">40 – 70%</span>
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

        <!-- Tab 2: DATA HISTORY (Telemetry Logs) -->
        <div id="tab-data-history" class="tab-pane">
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
                                    double sTemp = s.getTempC() != null ? Math.round(s.getTempC() * 10.0)/10.0 : 24.8;
                                    double sHumid = s.getHumidPct() != null ? Math.round(s.getHumidPct() * 10.0)/10.0 : 56.0;
                                    String sTime = s.getMeasuredAt() != null ? s.getMeasuredAt().toString() : "21/10/2025 13:45";
                                %>
                                <tr>
                                    <td><%= Web.esc(sTime) %></td>
                                    <td><%= sTemp %>°C</td>
                                    <td><%= (int)sHumid %>%</td>
                                    <td>652 ppm</td>
                                    <td>1.2 ppm</td>
                                    <td><span class="status-pill status-normal"><span class="status-dot"></span> Normal</span></td>
                                </tr>
                                <% } %>
                            <% } else { %>
                                <tr><td>21/10/2025 13:45:20</td><td>24.8°C</td><td>56%</td><td>652 ppm</td><td>1.2 ppm</td><td><span class="status-pill status-normal"><span class="status-dot"></span> Normal</span></td></tr>
                                <tr><td>21/10/2025 13:30:00</td><td>24.6°C</td><td>55%</td><td>648 ppm</td><td>1.1 ppm</td><td><span class="status-pill status-normal"><span class="status-dot"></span> Normal</span></td></tr>
                                <tr><td>21/10/2025 13:15:00</td><td>24.5°C</td><td>57%</td><td>660 ppm</td><td>1.3 ppm</td><td><span class="status-pill status-normal"><span class="status-dot"></span> Normal</span></td></tr>
                                <tr><td>21/10/2025 13:00:00</td><td>24.3°C</td><td>58%</td><td>675 ppm</td><td>1.4 ppm</td><td><span class="status-pill status-normal"><span class="status-dot"></span> Normal</span></td></tr>
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
                    <!-- Populated dynamically via JS -->
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
                        <p><strong>Coordinates:</strong> <%= (item != null && item.getLatitude() != null) ? item.getLatitude() + ", " + item.getLongitude() : "10.03, 105.78" %></p>
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

        <!-- 7. RECENT ALERT HISTORY TABLE (FULL WIDTH BOTTOM) -->
        <section class="alert-history-card">
            <div class="alert-history-header">
                <div class="alert-header-left">
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#2563eb" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/>
                        <path d="M13.73 21a2 2 0 0 1-3.46 0"/>
                    </svg>
                    <h2 class="card-title-main">Recent Alert History</h2>
                </div>
            </div>

            <div class="table-responsive">
                <table class="alert-table">
                    <thead>
                        <tr>
                            <th style="width: 190px;">Time</th>
                            <th style="width: 190px;">Alert Type</th>
                            <th style="width: 140px;">Metric</th>
                            <th style="width: 150px;">Measured Value</th>
                            <th style="width: 160px;">Allowed Threshold</th>
                            <th style="width: 140px;">Status</th>
                            <th>Notes</th>
                        </tr>
                    </thead>
                    <tbody id="recentAlertTableBody">
                        <!-- Populated by JS -->
                    </tbody>
                </table>
            </div>
        </section>
    </main>

    <!-- INJECT DYNAMIC DATA TO JAVASCRIPT OBJECTS -->
    <script>
        window.SERVER_ROOM_DATA = {
            id: <%= roomId %>,
            code: "<%= Web.esc(roomCode) %>",
            name: "<%= Web.esc(roomName) %>",
            location: "<%= Web.esc(roomLocation) %>",
            sensorId: "<%= Web.esc(deviceCode) %>",
            lastUpdated: "<%= Web.esc(lastUpdated) %>",
            temp: <%= currentTemp %>,
            humid: <%= currentHumid %>,
            co2: <%= currentCo2 %>,
            co: <%= currentCo %>,
            coMax: <%= coMax %>,
            co2Max: <%= co2Max %>
        };

        <% if (recentAlerts != null && !recentAlerts.isEmpty()) { %>
        window.SERVER_ALERT_DATA = [
            <% for (int aIdx = 0; aIdx < recentAlerts.size(); aIdx++) { 
                AirAlert al = recentAlerts.get(aIdx);
                String alTime = (al.getCreatedAt() != null) ? al.getCreatedAt().toString() : "21/10/2025 09:12";
                String alType = (al.getMessage() != null) ? al.getMessage() : "Sensor alert";
                String alStatus = "RESOLVED".equalsIgnoreCase(al.getStatus()) ? "Resolved" : "In progress";
                String alStatusClass = "RESOLVED".equalsIgnoreCase(al.getStatus()) ? "resolved" : "progress";
            %>
            {
                id: <%= al.getAlertId() %>,
                time: "<%= Web.esc(alTime) %>",
                type: "<%= Web.esc(alType) %>",
                category: "<%= (al.getRuleCode() != null && al.getRuleCode().toLowerCase().contains("temp")) ? "temp" : (al.getRuleCode() != null && al.getRuleCode().toLowerCase().contains("humid")) ? "humid" : "sensor" %>",
                metric: "<%= (al.getRuleCode() != null && al.getRuleCode().toLowerCase().contains("temp")) ? "Temperature" : "Sensor" %>",
                measuredValue: "29.4°C",
                allowedThreshold: "≤ 28°C",
                status: "<%= alStatus %>",
                statusCode: "<%= alStatusClass %>",
                notes: "<%= (al.getHandledNote() != null) ? Web.esc(al.getHandledNote()) : "Logged by monitoring system" %>"
            }<%= (aIdx < recentAlerts.size() - 1) ? "," : "" %>
            <% } %>
        ];
        <% } %>
    </script>
    <script src="<%= ctx %>/assets/js/room-detail.js"></script>
</body>
</html>
