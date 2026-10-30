<%@page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@page import="java.util.List, java.util.Locale, model.Room, model.Device, model.AppUser, util.Web"%>
<%
    Room item = (Room) request.getAttribute("editRoom");
    if (item == null) {
        item = (Room) request.getAttribute("editStation"); // Alias compatibility
    }
    String error = (String) request.getAttribute("error");
    String ctx = request.getContextPath();
    boolean isNew = (item == null);
    List<Device> deviceList = (List<Device>) request.getAttribute("deviceList");
    String selectedDeviceCode = (item != null && item.getDeviceCode() != null) ? item.getDeviceCode().trim() : "";

    AppUser me = (AppUser) session.getAttribute("user");
    String userName = (me != null && me.getFullName() != null) ? me.getFullName() : "Admin User";
    String userRole = (me != null && me.getRoleCode() != null) ? me.getRoleCode() : "ADMIN";
    boolean isAdmin = "ADMIN".equals(userRole);

    int openAlertCount = dao.AlertDAO.getOpeningAlertCount();

    java.time.ZonedDateTime nowZdt = java.time.ZonedDateTime.now(java.time.ZoneId.of("Asia/Ho_Chi_Minh"));
    String jDateStr = nowZdt.format(java.time.format.DateTimeFormatter.ofPattern("EEEE, d MMMM yyyy", java.util.Locale.ENGLISH));
    String jTimeStr = nowZdt.format(java.time.format.DateTimeFormatter.ofPattern("HH:mm"));
    String jSidebarDateTime = nowZdt.format(java.time.format.DateTimeFormatter.ofPattern("EEEE, dd/MM/yyyy, HH:mm", java.util.Locale.ENGLISH));
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><%= isNew ? "Add Room" : "Edit Room" %> – Classroom Temp Monitoring System</title>
    <link rel="shortcut icon" href="<%= ctx %>/favicon.ico" type="image/x-icon">
    <!-- Google Fonts: Inter -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="<%= ctx %>/assets/css/classrooms.css?v=<%= System.currentTimeMillis() %>">
    <style>
        .breadcrumb-link {
            color: #2563eb !important;
            text-decoration: none !important;
            font-weight: 500;
        }

        .breadcrumb-link:hover {
            color: #1d4ed8 !important;
            text-decoration: none !important;
        }

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

        .form-content-wrap {
            max-width: 860px;
            width: 100%;
            margin: 4px 0 36px;
        }

        .form-top-actions {
            display: flex;
            align-items: center;
            justify-content: flex-start;
            margin-bottom: 16px;
        }

        .btn-back-link {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            padding: 8px 16px;
            background: #ffffff;
            border: 1px solid #cbd5e1;
            border-radius: 8px;
            color: #475569;
            font-size: 13px;
            font-weight: 600;
            text-decoration: none;
            transition: all 0.15s ease;
            box-shadow: 0 1px 2px rgba(0, 0, 0, 0.03);
        }

        .btn-back-link:hover {
            background: #f8fafc;
            border-color: #94a3b8;
            color: #0f172a;
        }

        .room-form-card {
            background: #ffffff;
            border: 1px solid #e2e8f0;
            border-radius: 14px;
            box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.04), 0 2px 4px -1px rgba(0, 0, 0, 0.02);
            padding: 30px 36px;
        }

        .form-grid {
            display: grid;
            grid-template-columns: 1fr;
            gap: 18px;
        }

        .grid-col-2 {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 18px;
        }

        .grid-col-3 {
            display: grid;
            grid-template-columns: 1fr 1fr 1fr;
            gap: 16px;
        }

        .form-group {
            display: flex;
            flex-direction: column;
            gap: 6px;
        }

        .form-group label {
            font-size: 13px;
            font-weight: 600;
            color: #334155;
            display: flex;
            align-items: center;
            gap: 4px;
        }

        .form-group label .req {
            color: #ef4444;
        }

        .form-group input[type="text"],
        .form-group input[type="number"],
        .form-group select,
        .form-group textarea {
            width: 100%;
            height: 42px;
            padding: 0 12px;
            border: 1px solid #cbd5e1;
            border-radius: 8px;
            font-family: inherit;
            font-size: 13.5px;
            color: #0f172a;
            background: #ffffff;
            box-sizing: border-box;
            transition: all 0.15s ease;
            outline: none;
        }

        .form-group textarea {
            height: auto;
            padding: 10px 12px;
            resize: vertical;
            min-height: 85px;
        }

        .form-group input:focus,
        .form-group select:focus,
        .form-group textarea:focus {
            border-color: #2563eb;
            box-shadow: 0 0 0 3px rgba(37, 99, 235, 0.12);
        }

        .form-group input[readonly] {
            background-color: #f1f5f9;
            color: #64748b;
            cursor: not-allowed;
            border-color: #e2e8f0;
        }

        .input-hint {
            font-size: 11.5px;
            color: #64748b;
            line-height: 1.4;
            margin: 2px 0 0;
        }

        .divider-line {
            height: 1px;
            background: #f1f5f9;
            margin: 8px 0;
        }

        .form-actions-bar {
            display: flex;
            align-items: center;
            justify-content: flex-end;
            gap: 12px;
            margin-top: 26px;
            padding-top: 20px;
            border-top: 1px solid #f1f5f9;
        }

        .btn-cancel {
            height: 40px;
            padding: 0 20px;
            background: #ffffff;
            border: 1px solid #cbd5e1;
            border-radius: 8px;
            color: #475569;
            font-size: 13.5px;
            font-weight: 600;
            text-decoration: none;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            transition: all 0.15s ease;
            cursor: pointer;
        }

        .btn-cancel:hover {
            background: #f8fafc;
            color: #0f172a;
            border-color: #94a3b8;
        }

        .btn-submit {
            height: 40px;
            padding: 0 24px;
            background: #2563eb;
            border: 1px solid #2563eb;
            border-radius: 8px;
            color: #ffffff;
            font-size: 13.5px;
            font-weight: 600;
            display: inline-flex;
            align-items: center;
            gap: 6px;
            box-shadow: 0 1px 2px rgba(37, 99, 235, 0.2);
            transition: all 0.15s ease;
            cursor: pointer;
        }

        .btn-submit:hover {
            background: #1d4ed8;
            border-color: #1d4ed8;
            box-shadow: 0 4px 8px rgba(37, 99, 235, 0.25);
        }

        .error-alert-box {
            padding: 12px 16px;
            background: #fee2e2;
            border: 1px solid #fca5a5;
            border-radius: 8px;
            color: #b91c1c;
            font-size: 13px;
            font-weight: 500;
            margin-bottom: 20px;
            display: flex;
            align-items: center;
            gap: 8px;
        }

        @media (max-width: 640px) {
            .grid-col-2, .grid-col-3 {
                grid-template-columns: 1fr;
            }
            .room-form-card {
                padding: 20px;
            }
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
                    <%= openAlertCount %>
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
                    <a href="<%= ctx %>/dashboard" class="breadcrumb-item breadcrumb-home" title="Home">
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
                    <a href="<%= ctx %>/admin/rooms" class="breadcrumb-item breadcrumb-link">Classrooms</a>
                    <span class="breadcrumb-separator">
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none"
                            stroke="currentColor" stroke-width="2" stroke-linecap="round"
                            stroke-linejoin="round">
                            <polyline points="9 18 15 12 9 6" />
                        </svg>
                    </span>
                    <span class="breadcrumb-item breadcrumb-current"><%= isNew ? "Add Room" : "Edit Room" %></span>
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
                        <%= openAlertCount %>
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
                    <h1 class="page-main-heading"><%= isNew ? "Add Room" : "Edit Room" %></h1>
                    <p class="page-subheading"><%= isNew ? "Register a new room and bind an available sensor device." : "Update room environmental thresholds and device binding." %></p>
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

        <!-- 4. FORM CONTENT AREA -->
        <div class="form-content-wrap">
            <div class="form-top-actions">
                <a href="<%= ctx %>/admin/rooms" class="btn-back-link">
                    <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.3" stroke-linecap="round" stroke-linejoin="round">
                        <line x1="19" y1="12" x2="5" y2="12"></line>
                        <polyline points="12 19 5 12 12 5"></polyline>
                    </svg>
                    <span>Back to Classrooms</span>
                </a>
            </div>

            <!-- Error Notification -->
            <% if (error != null && !error.trim().isEmpty()) { %>
            <div class="error-alert-box">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                    <circle cx="12" cy="12" r="10"></circle>
                    <line x1="12" y1="8" x2="12" y2="12"></line>
                    <line x1="12" y1="16" x2="12.01" y2="16"></line>
                </svg>
                <span><%= Web.esc(error) %></span>
            </div>
            <% } %>

            <!-- Main Room Form Card -->
            <div class="room-form-card">
                <form method="post" action="<%= ctx %>/admin/rooms/save">
                    <input type="hidden" name="isEdit" value="<%= isNew ? "0" : "1" %>">
                    <input type="hidden" name="roomId" value="<%= isNew ? -1 : item.getRoomId() %>">
                    <input type="hidden" name="latitude" value="<%= (item == null || item.getLatitude() == null) ? "10.841129" : item.getLatitude() %>">
                    <input type="hidden" name="longitude" value="<%= (item == null || item.getLongitude() == null) ? "106.809883" : item.getLongitude() %>">

                    <div class="form-grid">
                        <!-- Row 1: Code & Name -->
                        <div class="grid-col-2">
                            <div class="form-group">
                                <label for="code">Room Code <span class="req">*</span></label>
                                <input type="text" id="code" name="code" required minlength="2" maxlength="32"
                                       placeholder="e.g. A101"
                                       value="<%= item == null ? "" : Web.esc(item.getCode()) %>"
                                       <%= !isNew ? "readonly" : "" %>>
                                <% if (!isNew) { %>
                                    <span class="input-hint">Room code is unique and cannot be modified after creation.</span>
                                <% } else { %>
                                    <span class="input-hint">Unique room identifier (e.g. A101, B202).</span>
                                <% } %>
                            </div>

                            <div class="form-group">
                                <label for="name">Room Name <span class="req">*</span></label>
                                <input type="text" id="name" name="name" required maxlength="100"
                                       placeholder="e.g. Classroom A101"
                                       value="<%= item == null ? "" : Web.esc(item.getName()) %>">
                                <span class="input-hint">Display name shown in classroom lists and reports.</span>
                            </div>
                        </div>

                        <!-- Row 2: Location -->
                        <div class="form-group">
                            <label for="location">Location <span class="req">*</span></label>
                            <input type="text" id="location" name="location" required maxlength="150"
                                   placeholder="e.g. Building A · Floor 1"
                                   value="<%= item == null ? "" : Web.esc(item.getLocation()) %>">
                            <span class="input-hint">Specific area or building description inside campus.</span>
                        </div>

                        <div class="divider-line"></div>

                        <!-- Row 3: Environmental Warning Thresholds (Temperature, Humidity, CO2, CO) -->
                        <div class="grid-col-2">
                            <div class="form-group">
                                <label for="tempThreshold">Temperature Warning Threshold (°C)</label>
                                <input type="number" step="0.1" min="0" max="100" id="tempThreshold" name="tempThreshold"
                                       placeholder="32.0"
                                       value="<%= (item != null && item.getTempWarningThreshold() > 0) ? String.format(Locale.US, "%.1f", item.getTempWarningThreshold()) : "32.0" %>">
                                <span class="input-hint">Default 32.0 °C.</span>
                            </div>

                            <div class="form-group">
                                <label for="humidThreshold">Humidity Warning Threshold (%)</label>
                                <input type="number" step="0.1" min="0" max="100" id="humidThreshold" name="humidThreshold"
                                       placeholder="80.0"
                                       value="<%= (item != null && item.getHumidWarningThreshold() > 0) ? String.format(Locale.US, "%.1f", item.getHumidWarningThreshold()) : "80.0" %>">
                                <span class="input-hint">Default 80.0 %.</span>
                            </div>

                            <div class="form-group">
                                <label for="co2Threshold">CO2 Warning Threshold (ppm)</label>
                                <input type="number" step="1" min="0" max="5000" id="co2Threshold" name="co2Threshold"
                                       placeholder="1000"
                                       value="<%= (item != null && item.getCo2WarningThreshold() > 0) ? String.format(Locale.US, "%.0f", item.getCo2WarningThreshold()) : "1000" %>">
                                <span class="input-hint">Default 1000 ppm.</span>
                            </div>

                            <div class="form-group">
                                <label for="coThreshold">CO Warning Threshold (ppm)</label>
                                <input type="number" step="0.1" min="0" max="1000" id="coThreshold" name="coThreshold"
                                       placeholder="9.0"
                                       value="<%= (item != null && item.getCoWarningThreshold() > 0) ? String.format(Locale.US, "%.1f", item.getCoWarningThreshold()) : "9.0" %>">
                                <span class="input-hint">Default 9.0 ppm.</span>
                            </div>
                        </div>

                        <div class="divider-line"></div>

                        <!-- Row 4: Device Code Dropdown (Unassigned Devices, Optional) -->
                        <div class="form-group">
                            <label for="deviceCode">Device Code</label>
                            <select name="deviceCode" id="deviceCode">
                                <option value="">-- None (No device assigned) --</option>
                                <%
                                    boolean hasAvailableDevices = false;
                                    if (deviceList != null && !deviceList.isEmpty()) {
                                        for (Device dev : deviceList) {
                                            String dCode = dev.getDeviceCode();
                                            if (dCode == null || dCode.trim().isEmpty()) continue;
                                            hasAvailableDevices = true;
                                            boolean isSelected = dCode.trim().equalsIgnoreCase(selectedDeviceCode);
                                %>
                                    <option value="<%= Web.esc(dCode) %>" <%= isSelected ? "selected" : "" %>>
                                        <%= Web.esc(dCode) %> <%= dev.isIsActive() ? "(Active)" : "(Inactive)" %>
                                    </option>
                                <%
                                        }
                                    }
                                    if (!hasAvailableDevices) {
                                %>
                                    <option value="" disabled>No available unassigned devices</option>
                                <%  } %>
                            </select>
                            <span class="input-hint">Optional. Select an available unassigned device, or leave empty to assign later.</span>
                        </div>

                        <!-- Row 5: Note -->
                        <div class="form-group">
                            <label for="note">Note</label>
                            <textarea id="note" name="note" rows="3"
                                      placeholder="Optional notes or details about the classroom..."><%= item == null || item.getNote() == null ? "" : Web.esc(item.getNote()) %></textarea>
                            <span class="input-hint">Optional remarks regarding sensor placement, room capacity, or usage hours.</span>
                        </div>
                    </div>

                    <!-- Form Action Buttons -->
                    <div class="form-actions-bar">
                        <a href="<%= ctx %>/admin/rooms" class="btn-cancel">Cancel</a>
                        <button type="submit" class="btn-submit">
                            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.3" stroke-linecap="round" stroke-linejoin="round">
                                <path d="M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2z"></path>
                                <polyline points="17 21 17 13 7 13 7 21"></polyline>
                                <polyline points="7 3 7 8 15 8"></polyline>
                            </svg>
                            <span><%= isNew ? "Add Room" : "Save Changes" %></span>
                        </button>
                    </div>
                </form>
            </div>
        </div>
    </main>

    <!-- Interactive Scripts: Sidebar toggle, user profile dropdown, and live clock -->
    <script>
        (function() {
            // Sidebar Toggle
            const btnToggle = document.getElementById("btnSidebarToggle");
            if (btnToggle) {
                btnToggle.addEventListener("click", function() {
                    document.body.classList.toggle("sidebar-collapsed");
                });
            }

            // User Profile Menu Toggle
            const userToggle = document.getElementById("userMenuToggle");
            const userMenu = document.getElementById("userDropdownMenu");
            if (userToggle && userMenu) {
                userToggle.addEventListener("click", function(e) {
                    e.stopPropagation();
                    userMenu.classList.toggle("show");
                });
                document.addEventListener("click", function(e) {
                    if (!userMenu.contains(e.target)) {
                        userMenu.classList.remove("show");
                    }
                });
            }

            // Live ticking clock for Date & Time Card
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
</body>
</html>
