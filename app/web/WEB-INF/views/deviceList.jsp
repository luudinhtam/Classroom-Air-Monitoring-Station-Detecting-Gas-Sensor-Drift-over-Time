<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.util.*, java.text.SimpleDateFormat, model.Device, model.AppUser, util.Web"%>
<%
    String ctx = request.getContextPath();
    AppUser me = (AppUser) session.getAttribute("user");
    String userName = (me != null && me.getFullName() != null) ? me.getFullName() : "Tai khoan ADMIN";
    String userRole = (me != null && me.getRoleCode() != null) ? me.getRoleCode() : "ADMIN";
    boolean isAdmin = "ADMIN".equals(userRole);

    String flash = (String) session.getAttribute("flash");
    if (flash != null) session.removeAttribute("flash");
    String flashError = (String) session.getAttribute("flashError");
    if (flashError != null) session.removeAttribute("flashError");

    List<Device> allDevices = (List<Device>) request.getAttribute("allDevices");
    if (allDevices == null) {
        allDevices = (List<Device>) request.getAttribute("rows");
    }
    if (allDevices == null) {
        allDevices = new ArrayList<>();
    }

    Integer openAlertObj = (Integer) request.getAttribute("openAlertCount");
    int openAlertCount = (openAlertObj != null && openAlertObj >= 0) ? openAlertObj : 0;

    int totalDev = allDevices.size();
    int activeCount = 0;
    int inactiveCount = 0;
    for (Device d : allDevices) {
        if (d.isIsActive()) activeCount++;
        else inactiveCount++;
    }
    String activePct = totalDev > 0 ? String.format(Locale.US, "%.1f", (activeCount * 100.0 / totalDev)) : "0.0";
    String inactivePct = totalDev > 0 ? String.format(Locale.US, "%.1f", (inactiveCount * 100.0 / totalDev)) : "0.0";

    java.time.ZonedDateTime nowZdt = java.time.ZonedDateTime.now(java.time.ZoneId.of("Asia/Ho_Chi_Minh"));
    String jDateStr = nowZdt.format(java.time.format.DateTimeFormatter.ofPattern("EEEE, d MMMM yyyy", java.util.Locale.ENGLISH));
    String jTimeStr = nowZdt.format(java.time.format.DateTimeFormatter.ofPattern("HH:mm"));
    String jSidebarDateTime = nowZdt.format(java.time.format.DateTimeFormatter.ofPattern("EEEE, dd/MM/yyyy, HH:mm", java.util.Locale.ENGLISH));

    // Serialize allDevices to JSON for client-side reactive rendering
    SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy HH:mm");
    StringBuilder devicesJson = new StringBuilder("[");
    for (int i = 0; i < allDevices.size(); i++) {
        Device d = allDevices.get(i);
        String id = d.getDeviceCode() != null ? d.getDeviceCode() : ("D" + String.format("%03d", d.getDeviceId()));
        String cr = d.getRoomCode() != null ? d.getRoomCode() : "-";
        String status = d.isIsActive() ? "Active" : "Inactive";
        String seenStr = d.getLastSeen() != null ? sdf.format(d.getLastSeen()) : "Never";
        String aKey = d.getApiKey() != null ? d.getApiKey() : "";
        String noteStr = d.getNote() != null ? d.getNote() : "";

        id = id.replace("\\", "\\\\").replace("\"", "\\\"");
        cr = cr.replace("\\", "\\\\").replace("\"", "\\\"");
        aKey = aKey.replace("\\", "\\\\").replace("\"", "\\\"");
        noteStr = noteStr.replace("\\", "\\\\").replace("\"", "\\\"");

        if (i > 0) devicesJson.append(",");
        devicesJson.append("{")
                   .append("\"id\":\"").append(id).append("\",")
                   .append("\"deviceId\":").append(d.getDeviceId()).append(",")
                   .append("\"isActive\":").append(d.isIsActive()).append(",")
                   .append("\"classroom\":\"").append(cr).append("\",")
                   .append("\"roomId\":").append(d.getRoomId() != null ? d.getRoomId() : "null").append(",")
                   .append("\"status\":\"").append(status).append("\",")
                   .append("\"lastSeen\":\"").append(seenStr).append("\",")
                   .append("\"apiKey\":\"").append(aKey).append("\",")
                   .append("\"note\":\"").append(noteStr).append("\"")
                   .append("}");
    }
    devicesJson.append("]");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Devices – Classroom Air Monitoring System</title>
    <link rel="shortcut icon" href="<%= ctx %>/favicon.ico" type="image/x-icon">
    <!-- Google Fonts: Inter -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="<%= ctx %>/assets/css/devices.css?v=<%= System.currentTimeMillis() %>">
    <style>
        .actions-cell {
            display: inline-flex !important;
            flex-direction: row !important;
            align-items: center !important;
            justify-content: flex-end !important;
            gap: 8px !important;
            white-space: nowrap !important;
        }
        .actions-cell form {
            display: inline-block !important;
            margin: 0 !important;
            padding: 0 !important;
        }
        .actions-cell .btn-act {
            width: 70px !important;
            min-width: 70px !important;
            max-width: 70px !important;
            height: 28px !important;
            display: inline-flex !important;
            align-items: center !important;
            justify-content: center !important;
            text-align: center !important;
            padding: 0 !important;
            box-sizing: border-box !important;
            font-size: 11.5px !important;
            font-weight: 600 !important;
            border-radius: 6px !important;
        }
        .btn-act-purple {
            background: #f5f3ff !important;
            color: #7c3aed !important;
            border-color: #ddd6fe !important;
        }
        .btn-act-purple:hover {
            background: #ede9fe !important;
            border-color: #c4b5fd !important;
        }
        .devices-table td.col-actions {
            vertical-align: middle !important;
            text-align: right !important;
            padding-right: 14px !important;
            white-space: nowrap !important;
        }
        .col-actions .th-content {
            justify-content: flex-end !important;
            padding-right: 14px !important;
        }

        /* 3 Stats Cards Hover Effect */
        .stat-card {
            transition: transform 0.22s cubic-bezier(0.4, 0, 0.2, 1), 
                        box-shadow 0.22s cubic-bezier(0.4, 0, 0.2, 1), 
                        border-color 0.22s ease !important;
            cursor: pointer;
            position: relative;
        }

        .stat-card:hover {
            transform: translateY(-4px) !important;
            box-shadow: 0 10px 20px -3px rgba(15, 27, 61, 0.08), 0 4px 6px -2px rgba(15, 27, 61, 0.04) !important;
            border-color: #cbd5e1 !important;
        }

        .stat-card:hover .stat-icon-wrapper {
            transform: scale(1.08);
        }

        .stat-icon-wrapper {
            transition: transform 0.22s ease;
        }

        /* Active stats cards matching active status */
        .stat-card.active {
            transform: translateY(-2px);
        }
        .stat-card.active-blue {
            border: 2px solid #2563eb !important;
            background: #f8fbff !important;
            box-shadow: 0 0 0 3px rgba(37, 99, 235, 0.12) !important;
        }
        .stat-card.active-green {
            border: 2px solid #16a34a !important;
            background: #f6fef9 !important;
            box-shadow: 0 0 0 3px rgba(22, 163, 74, 0.12) !important;
        }
        .stat-card.active-slate {
            border: 2px solid #64748b !important;
            background: #f8fafc !important;
            box-shadow: 0 0 0 3px rgba(100, 116, 139, 0.12) !important;
        }

        /* API Key Modal Popup */
        .device-modal-backdrop {
            position: fixed;
            top: 0; left: 0; right: 0; bottom: 0;
            background: rgba(15, 23, 42, 0.45);
            backdrop-filter: blur(4px);
            z-index: 99999;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 16px;
        }
        .device-modal-card {
            background: #ffffff;
            border-radius: 12px;
            box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.15), 0 10px 10px -5px rgba(0, 0, 0, 0.04);
            width: 100%;
            max-width: 480px;
            overflow: hidden;
            animation: modalFadeIn 0.15s ease-out;
            border: 1px solid #e2e8f0;
        }
        @keyframes modalFadeIn {
            from { opacity: 0; transform: scale(0.96); }
            to { opacity: 1; transform: scale(1); }
        }
        .device-modal-header {
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 16px 20px;
            border-bottom: 1px solid #f1f5f9;
        }
        .device-modal-title-group {
            display: flex;
            align-items: center;
            gap: 12px;
        }
        .modal-icon-box {
            width: 36px;
            height: 36px;
            border-radius: 8px;
            background: #f5f3ff;
            display: flex;
            align-items: center;
            justify-content: center;
            flex-shrink: 0;
        }
        .modal-title {
            margin: 0;
            font-size: 16px;
            font-weight: 700;
            color: #0f172a;
        }
        .modal-subtitle {
            margin: 2px 0 0;
            font-size: 12px;
            color: #64748b;
        }
        .modal-close-btn {
            background: transparent;
            border: none;
            font-size: 22px;
            color: #94a3b8;
            cursor: pointer;
            line-height: 1;
            padding: 4px;
            border-radius: 6px;
            transition: all 0.12s ease;
        }
        .modal-close-btn:hover {
            color: #0f172a;
            background: #f1f5f9;
        }
        .device-modal-body {
            padding: 20px;
        }
        .modal-field-label {
            display: block;
            font-size: 11.5px;
            font-weight: 700;
            color: #475569;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            margin-bottom: 6px;
        }
        .modal-field-value-box {
            background: #f8fafc;
            border: 1px solid #e2e8f0;
            padding: 8px 12px;
            border-radius: 6px;
            font-weight: 600;
            font-size: 13.5px;
            color: #1e293b;
        }
        .key-copy-group {
            display: flex;
            align-items: center;
            gap: 8px;
        }
        .modal-key-input {
            flex: 1;
            height: 38px;
            padding: 0 12px;
            background: #f8fafc;
            border: 1px solid #cbd5e1;
            border-radius: 6px;
            font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
            font-size: 13px;
            color: #0f172a;
            letter-spacing: 0.5px;
            outline: none;
        }
        .modal-key-input:focus {
            border-color: #7c3aed;
            box-shadow: 0 0 0 3px rgba(124, 58, 237, 0.15);
        }
        .btn-copy-key {
            height: 38px;
            padding: 0 14px;
            background: #7c3aed;
            color: #ffffff;
            border: 1px solid #7c3aed;
            border-radius: 6px;
            font-size: 12.5px;
            font-weight: 600;
            cursor: pointer;
            display: inline-flex;
            align-items: center;
            gap: 6px;
            transition: all 0.15s ease;
            white-space: nowrap;
        }
        .btn-copy-key:hover {
            background: #6d28d9;
            border-color: #6d28d9;
        }
        .btn-copy-key.copied {
            background: #16a34a !important;
            border-color: #16a34a !important;
        }
        .modal-hint {
            display: block;
            margin-top: 8px;
            font-size: 11.5px;
            color: #94a3b8;
            line-height: 1.4;
        }
        .modal-hint code {
            background: #f1f5f9;
            padding: 1px 5px;
            border-radius: 4px;
            font-size: 11px;
            color: #334155;
        }
        .device-modal-footer {
            padding: 12px 20px;
            border-top: 1px solid #f1f5f9;
            display: flex;
            justify-content: flex-end;
            background: #fafafa;
        }
        .btn-modal-close {
            height: 34px;
            padding: 0 16px;
            background: #ffffff;
            border: 1px solid #cbd5e1;
            border-radius: 6px;
            font-size: 13px;
            font-weight: 600;
            color: #475569;
            cursor: pointer;
            transition: all 0.12s ease;
        }
        .btn-modal-close:hover {
            background: #f1f5f9;
            color: #1e293b;
        }
        .device-modal-card-lg {
            max-width: 540px !important;
        }
        .modal-form-input {
            width: 100%;
            height: 38px;
            padding: 0 12px;
            background: #ffffff;
            border: 1px solid #cbd5e1;
            border-radius: 6px;
            font-size: 13px;
            color: #0f172a;
            outline: none;
            box-sizing: border-box;
            transition: border-color 0.15s ease, box-shadow 0.15s ease;
        }
        .modal-form-input:focus {
            border-color: #2563eb;
            box-shadow: 0 0 0 3px rgba(37, 99, 235, 0.15);
        }
        .modal-form-select {
            width: 100%;
            height: 38px;
            padding: 0 12px;
            background: #ffffff;
            border: 1px solid #cbd5e1;
            border-radius: 6px;
            font-size: 13px;
            font-weight: 500;
            color: #0f172a;
            outline: none;
            cursor: pointer;
            box-sizing: border-box;
            transition: border-color 0.15s ease;
        }
        .modal-form-select:focus {
            border-color: #2563eb;
            box-shadow: 0 0 0 3px rgba(37, 99, 235, 0.15);
        }
        .btn-modal-save {
            height: 34px;
            padding: 0 20px;
            background: #2563eb;
            border: 1px solid #2563eb;
            border-radius: 6px;
            font-size: 13px;
            font-weight: 600;
            color: #ffffff;
            cursor: pointer;
            transition: all 0.12s ease;
            box-shadow: 0 1px 3px rgba(37, 99, 235, 0.25);
        }
        .btn-modal-save:hover {
            background: #1d4ed8;
            border-color: #1d4ed8;
        }
    </style>
</head>
<body>    <!-- 1. FIXED LEFT SIDEBAR (235px) -->
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

        <!-- Vertical Menu Navigation (5 items) -->
        <nav class="sidebar-menu">
            <a href="<%= ctx %>/dashboard" class="menu-item" title="Dashboard">
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

            <!-- ACTIVE ITEM: Devices -->
            <a href="<%= ctx %>/admin/devices" class="menu-item active" title="Devices">
                <svg class="menu-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <rect x="4" y="4" width="16" height="16" rx="2"/>
                    <rect x="9" y="9" width="6" height="6"/>
                    <path d="M9 1v3M15 1v3M9 20v3M15 20v3M20 9h3M20 14h3M1 9h3M1 14h3"/>
                </svg>
                <span>Devices</span>
            </a>

            <!-- Users -->
            <% if (isAdmin) { %>
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
                    <span class="breadcrumb-item breadcrumb-current">Devices</span>
                </nav>
            </div>

            <!-- Right: Notifications & User Profile -->
            <div class="top-bar-right">
                <a href="<%= ctx %>/alerts" class="icon-btn-round" title="Notifications">
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

        <% if (flash != null && !flash.isEmpty()) { %>
        <div class="flash-banner success">
            <span><%= Web.esc(flash) %></span>
        </div>
        <% } %>
        <% if (flashError != null && !flashError.isEmpty()) { %>
        <div class="flash-banner error">
            <span><%= Web.esc(flashError) %></span>
        </div>
        <% } %>

        <!-- 3. PAGE TITLE SECTION (y ~70–115) -->
        <section class="page-title-section">
            <div class="title-left">
                <div class="title-icon-box">
                    <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#ffffff" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                        <rect x="3" y="3" width="7" height="7" rx="1.5"/>
                        <rect x="14" y="3" width="7" height="7" rx="1.5"/>
                        <rect x="14" y="14" width="7" height="7" rx="1.5"/>
                        <rect x="3" y="14" width="7" height="7" rx="1.5"/>
                    </svg>
                </div>
                <div class="title-text-group">
                    <h1 class="page-title">Devices</h1>
                    <p class="page-subtitle">Manage and monitor all sensors in the system.</p>
                </div>
            </div>

            <!-- Date & Time Card (x 1215–1514, y 73–110) -->
            <div class="datetime-card">
                <div class="datetime-item">
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#64748b" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <rect x="3" y="4" width="18" height="18" rx="2" ry="2"/>
                        <line x1="16" y1="2" x2="16" y2="6"/>
                        <line x1="8" y1="2" x2="8" y2="6"/>
                        <line x1="3" y1="10" x2="21" y2="10"/>
                    </svg>
                    <span class="datetime-date" id="currentDateText"><%= jDateStr %></span>
                </div>
                <div class="datetime-divider"></div>
                <div class="datetime-item">
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#2563eb" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                        <circle cx="12" cy="12" r="10"/>
                        <polyline points="12 6 12 12 16 14"/>
                    </svg>
                    <span class="datetime-time" id="currentTimeText"><%= jTimeStr %></span>
                </div>
            </div>
        </section>

        <!-- 4. STATS CARDS (Active / Inactive) -->
        <section class="stats-cards-grid" style="grid-template-columns: repeat(3, 1fr);">
            <!-- 1. Total Devices -->
            <div class="stat-card active active-blue" onclick="filterByDeviceStatus('ALL')" title="Show all devices">
                <div class="stat-icon-wrapper blue">
                    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <rect x="4" y="4" width="16" height="16" rx="2"/>
                        <rect x="9" y="9" width="6" height="6"/>
                        <path d="M9 1v3M15 1v3M9 20v3M15 20v3M20 9h3M20 14h3M1 9h3M1 14h3"/>
                    </svg>
                </div>
                <div class="stat-info">
                    <span class="stat-label">Total Devices</span>
                    <div class="stat-value-row">
                        <span class="stat-value" id="statTotalDevices"><%= totalDev %></span>
                    </div>
                    <div class="stat-subtext">
                        <span class="stat-sub-dot"></span>
                        <span>Connected devices</span>
                    </div>
                </div>
            </div>

            <!-- 2. Active -->
            <div class="stat-card" onclick="filterByDeviceStatus('Active')" title="Filter Active devices">
                <div class="stat-icon-wrapper green">
                    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/>
                        <polyline points="22 4 12 14.01 9 11.01"/>
                    </svg>
                </div>
                <div class="stat-info">
                    <span class="stat-label">Active</span>
                    <div class="stat-value-row">
                        <span class="stat-value" id="statOnlineCount"><%= activeCount %></span>
                        <span class="stat-percent" id="statOnlinePct"><%= activePct %>%</span>
                    </div>
                    <div class="stat-subtext">
                        <span class="stat-sub-dot" style="background: #16a34a;"></span>
                        <span>Operating normally</span>
                    </div>
                </div>
            </div>

            <!-- 3. Inactive -->
            <div class="stat-card" onclick="filterByDeviceStatus('Inactive')" title="Filter Inactive devices">
                <div class="stat-icon-wrapper red" style="background: #f1f5f9; color: #64748b;">
                    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                        <rect x="3" y="11" width="18" height="11" rx="2" ry="2"/>
                        <path d="M7 11V7a5 5 0 0 1 10 0v4"/>
                    </svg>
                </div>
                <div class="stat-info">
                    <span class="stat-label">Inactive</span>
                    <div class="stat-value-row">
                        <span class="stat-value" id="statInactiveCount"><%= inactiveCount %></span>
                        <span class="stat-percent" id="statInactivePct"><%= inactivePct %>%</span>
                    </div>
                    <div class="stat-subtext">
                        <span class="stat-sub-dot" style="background: #94a3b8;"></span>
                        <span>Disabled / Locked</span>
                    </div>
                </div>
            </div>
        </section>

        <!-- 5. FILTER BAR (x 236–1514, y 255–314) -->
        <section class="filter-card">
            <!-- Search Input -->
            <div class="search-wrapper">
                <svg class="search-icon" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                    <circle cx="11" cy="11" r="8"/>
                    <line x1="21" y1="21" x2="16.65" y2="16.65"/>
                </svg>
                <input type="text" class="search-input" id="searchInput" placeholder="Search by device code or classroom..." autocomplete="off">
            </div>

            <!-- 3 Custom Selects -->
            <div class="filter-select-group">
                <!-- Status Select -->
                <div class="custom-select-box status-select" id="statusSelectBox">
                    <div class="select-label-row">
                        <span>Status</span>
                        <svg class="sort-icon" width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="m7 15 5 5 5-5"/><path d="m7 9 5-5 5 5"/></svg>
                    </div>
                    <div class="select-val-row">All Statuses</div>
                    <svg class="select-chevron" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><polyline points="6 9 12 15 18 9"/></svg>
                    <div class="select-options-popup">
                        <div class="option-item selected" data-val="ALL">All Statuses</div>
                        <div class="option-item" data-val="Active">Active</div>
                        <div class="option-item" data-val="Inactive">Inactive</div>
                    </div>
                </div>

                <!-- Classroom Select -->
                <div class="custom-select-box classroom-select" id="classroomSelectBox">
                    <div class="select-label-row">
                        <span>Classroom</span>
                        <svg class="sort-icon" width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="m7 15 5 5 5-5"/><path d="m7 9 5-5 5 5"/></svg>
                    </div>
                    <div class="select-val-row">All Classrooms</div>
                    <svg class="select-chevron" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><polyline points="6 9 12 15 18 9"/></svg>
                    <div class="select-options-popup" id="classroomOptionsList">
                        <div class="option-item selected" data-val="ALL">All Classrooms</div>
                    </div>
                </div>
            </div>

            <!-- Refresh Button -->
            <button type="button" class="btn-refresh" id="btnRefresh" title="Refresh data">
                <svg class="refresh-icon" id="refreshIcon" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.3" stroke-linecap="round" stroke-linejoin="round">
                    <polyline points="23 4 23 10 17 10"/>
                    <path d="M20.49 15a9 9 0 1 1-2.12-9.36L23 10"/>
                </svg>
                <span>Refresh</span>
            </button>

            <!-- Add Device Button -->
            <a class="btn-add-device" href="<%= ctx %>/admin/devices/create" title="Add new device">
                <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round">
                    <line x1="12" y1="5" x2="12" y2="19"/>
                    <line x1="5" y1="12" x2="19" y2="12"/>
                </svg>
                <span>Add Device</span>
            </a>
        </section>

        <!-- 6. MAIN 2-COLUMN SECTION (y 328–982) -->
        <section class="content-grid">
            <!-- LEFT COLUMN: DEVICES TABLE CARD (934px wide) -->
            <div class="table-card">
                <div class="table-container">
                    <table class="devices-table">
                        <thead>
                            <tr>
                                <th class="col-check">
                                    <div class="custom-checkbox" id="selectAllCheckbox" title="Select all on this page">
                                        <svg class="check-tick" width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="#ffffff" stroke-width="3" stroke-linecap="round" stroke-linejoin="round">
                                            <polyline points="20 6 9 17 4 12"/>
                                        </svg>
                                        <svg class="check-minus" width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="#ffffff" stroke-width="3" stroke-linecap="round" stroke-linejoin="round">
                                            <line x1="5" y1="12" x2="19" y2="12"/>
                                        </svg>
                                    </div>
                                </th>
                                <th class="col-id" data-sort="id">
                                    <span class="th-content">
                                        <span>Device Code</span>
                                        <svg class="sort-icon" width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor"><path d="m7 15 5 5 5-5"/><path d="m7 9 5-5 5 5"/></svg>
                                    </span>
                                </th>
                                <th class="col-classroom" data-sort="classroom">
                                    <span class="th-content">
                                        <span>Classroom</span>
                                        <svg class="sort-icon" width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor"><path d="m7 15 5 5 5-5"/><path d="m7 9 5-5 5 5"/></svg>
                                    </span>
                                </th>
                                <th class="col-status" data-sort="status">
                                    <span class="th-content">
                                        <span>Status</span>
                                        <svg class="sort-icon" width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor"><path d="m7 15 5 5 5-5"/><path d="m7 9 5-5 5 5"/></svg>
                                    </span>
                                </th>
                                <th class="col-seen" data-sort="lastSeen">
                                    <span class="th-content">
                                        <span>Last Seen</span>
                                        <svg class="sort-icon" width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor"><path d="m7 15 5 5 5-5"/><path d="m7 9 5-5 5 5"/></svg>
                                    </span>
                                </th>
                                <th class="col-actions">
                                    <span class="th-content no-sort" style="justify-content: flex-end; padding-right: 8px;">
                                        <span>Actions</span>
                                    </span>
                                </th>
                            </tr>
                        </thead>
                        <tbody id="devicesTableBody">
                            <% if (allDevices.isEmpty()) { %>
                            <tr><td colspan="6" class="empty-table-state">No devices found</td></tr>
                            <% } else {
                                int limit = Math.min(allDevices.size(), 14);
                                for (int idx = 0; idx < limit; idx++) {
                                    Device d = allDevices.get(idx);
                                    String dCode = d.getDeviceCode() != null ? d.getDeviceCode() : ("D" + String.format("%03d", d.getDeviceId()));
                                    String rCode = d.getRoomCode() != null ? d.getRoomCode() : "-";
                                    boolean isAct = d.isIsActive();
                                    String st = isAct ? "Active" : "Inactive";
                                    String seen = d.getLastSeen() != null ? sdf.format(d.getLastSeen()) : "Never";
                                    String stClass = isAct ? "online" : "inactive";
                                    int devId = d.getDeviceId();
                            %>
                            <tr data-device-id="<%= dCode %>">
                                <td class="col-check">
                                    <div class="custom-checkbox" data-device-id="<%= dCode %>">
                                        <svg class="check-tick" width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="#ffffff" stroke-width="3" stroke-linecap="round" stroke-linejoin="round">
                                            <polyline points="20 6 9 17 4 12"/>
                                        </svg>
                                    </div>
                                </td>
                                <td class="col-id"><span class="dev-id-text"><%= Web.esc(dCode) %></span></td>
                                <td class="col-classroom"><span class="classroom-text"><%= Web.esc(rCode) %></span></td>
                                <td class="col-status">
                                    <span class="status-pill <%= stClass %>">
                                        <span class="status-dot"></span>
                                        <span><%= Web.esc(st) %></span>
                                    </span>
                                </td>
                                <td class="col-seen"><%= Web.esc(seen) %></td>
                                <td class="col-actions">
                                    <div class="actions-cell">
                                        <button type="button" class="btn-act btn-act-purple" title="View API Key"
                                                onclick="openApiKeyModal('<%= Web.esc(dCode) %>', '<%= Web.esc(d.getApiKey() != null ? d.getApiKey() : "") %>')">
                                            API Key
                                        </button>
                                        <button type="button" class="btn-act btn-act-blue" title="View device details"
                                                onclick="openDeviceDetailModal('<%= Web.esc(dCode) %>')">
                                            Detail
                                        </button>
                                        <form method="post" action="<%= ctx %>/admin/devices/delete"
                                              onsubmit="return confirm('Are you sure you want to delete device <%= Web.esc(dCode) %>?');">
                                            <input type="hidden" name="id" value="<%= devId %>">
                                            <button type="submit" class="btn-act btn-act-red" title="Delete device">
                                                Delete
                                            </button>
                                        </form>
                                    </div>
                                </td>
                            </tr>
                            <%  } } %>
                        </tbody>
                    </table>
                </div>

                <!-- Table Footer (Pagination & Count) -->
                <div class="table-footer">
                    <span class="footer-count-text" id="footerCountText">Showing <%= allDevices.isEmpty() ? "0 of 0" : ("1–" + Math.min(allDevices.size(), 14) + " of " + allDevices.size()) %> devices</span>
                    <div class="pagination-controls" id="paginationControls">
                        <!-- Populated by devices.js -->
                    </div>
                </div>
            </div>
        </section>
    </main>

    <!-- API KEY MODAL POPUP -->
    <div id="apiKeyModal" class="device-modal-backdrop" style="display: none;" onclick="if(event.target===this) closeApiKeyModal();">
        <div class="device-modal-card">
            <div class="device-modal-header">
                <div class="device-modal-title-group">
                    <div class="modal-icon-box">
                        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#7c3aed" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                            <path d="M21 2l-2 2m-7.61 7.61a5.5 5.5 0 1 1-7.778 7.778 5.5 5.5 0 0 1 7.777-7.777zm0 0L15.5 7.5m0 0l3 3L22 7l-3-3m-3.5 3.5L19 4"/>
                        </svg>
                    </div>
                    <div>
                        <h3 class="modal-title">Device API Key</h3>
                        <p class="modal-subtitle">Authentication credential for telemetry stream</p>
                    </div>
                </div>
                <button type="button" class="modal-close-btn" onclick="closeApiKeyModal()" title="Close">&times;</button>
            </div>
            
            <div class="device-modal-body">
                <div class="modal-field-group">
                    <label class="modal-field-label">Device Code</label>
                    <div class="modal-field-value-box" id="modalDeviceCode">-</div>
                </div>
                <div class="modal-field-group" style="margin-top: 14px;">
                    <label class="modal-field-label">API Key</label>
                    <div class="key-copy-group">
                        <input type="text" id="modalApiKeyInput" class="modal-key-input" readonly value="">
                        <button type="button" id="btnCopyKey" class="btn-copy-key" onclick="copyApiKey()" title="Copy to clipboard">
                            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                                <rect x="9" y="9" width="13" height="13" rx="2" ry="2"/>
                                <path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"/>
                            </svg>
                            <span id="copyBtnText">Copy</span>
                        </button>
                    </div>
                    <span class="modal-hint">Use this key in the <code>X-Device-Key</code> header to authenticate device data packets.</span>
                </div>
            </div>
            
            <div class="device-modal-footer">
                <button type="button" class="btn-modal-close" onclick="closeApiKeyModal()">Close</button>
            </div>
        </div>
    </div>

    <!-- DEVICE DETAIL MODAL POPUP -->
    <div id="deviceDetailModal" class="device-modal-backdrop" style="display: none;" onclick="if(event.target===this) closeDeviceDetailModal();">
        <div class="device-modal-card device-modal-card-lg">
            <div class="device-modal-header">
                <div class="device-modal-title-group">
                    <div class="modal-icon-box" style="background: #eff6ff; color: #2563eb;">
                        <svg width="19" height="19" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                            <rect x="4" y="4" width="16" height="16" rx="2"/>
                            <rect x="9" y="9" width="6" height="6"/>
                            <path d="M9 1v3M15 1v3M9 20v3M15 20v3M20 9h3M20 14h3M1 9h3M1 14h3"/>
                        </svg>
                    </div>
                    <div>
                        <h3 class="modal-title">Device Details</h3>
                        <p class="modal-subtitle">View device telemetry credentials and manage authorization</p>
                    </div>
                </div>
                <button type="button" class="modal-close-btn" onclick="closeDeviceDetailModal()" title="Close">&times;</button>
            </div>
            
            <form method="post" action="<%= ctx %>/admin/devices/save">
                <input type="hidden" name="deviceId" id="modalDetailDeviceId" value="">
                <input type="hidden" name="roomId" id="modalDetailRoomId" value="">

                <div class="device-modal-body" style="display: flex; flex-direction: column; gap: 14px;">
                    <!-- Row 1: Device code & Room code -->
                    <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 14px;">
                        <div>
                            <label class="modal-field-label">Device Code</label>
                            <input type="text" name="deviceCode" id="modalDetailDeviceCode" class="modal-form-input" readonly 
                                   style="background: #f8fafc; color: #334155; font-weight: 700; cursor: not-allowed;">
                        </div>
                        <div>
                            <label class="modal-field-label">Room Code</label>
                            <div class="modal-field-value-box" id="modalDetailRoomCode" style="height: 38px; display: flex; align-items: center;">-</div>
                        </div>
                    </div>

                    <!-- Row 2: API Key -->
                    <div>
                        <label class="modal-field-label">API Key</label>
                        <div class="key-copy-group">
                            <input type="text" name="apiKey" id="modalDetailApiKey" class="modal-key-input" required maxlength="64">
                            <button type="button" id="btnCopyDetailKey" class="btn-copy-key" onclick="copyDetailApiKey()" title="Copy to clipboard">
                                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                                    <rect x="9" y="9" width="13" height="13" rx="2" ry="2"/>
                                    <path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"/>
                                </svg>
                                <span id="copyDetailBtnText">Copy</span>
                            </button>
                        </div>
                    </div>

                    <!-- Row 3: Note -->
                    <div>
                        <label class="modal-field-label">Note</label>
                        <input type="text" name="note" id="modalDetailNote" class="modal-form-input" maxlength="150" placeholder="e.g. Phòng P001, Gắn tường">
                    </div>

                    <!-- Row 4: Last seen & Status -->
                    <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 14px;">
                        <div>
                            <label class="modal-field-label">Last Seen</label>
                            <div class="modal-field-value-box" id="modalDetailLastSeen" style="height: 38px; display: flex; align-items: center; font-size: 12.5px; color: #64748b;">-</div>
                        </div>
                        <div>
                            <label class="modal-field-label">Status</label>
                            <div id="modalDetailStatusDisplay" style="height: 38px; display: flex; align-items: center;">
                                <span class="status-pill online" id="modalDetailStatusPill">
                                    <span class="status-dot"></span>
                                    <span id="modalDetailStatusText">Active</span>
                                </span>
                            </div>
                        </div>
                    </div>

                    <!-- Row 5: Option chọn unlock hoặc lock -->
                    <div>
                        <label class="modal-field-label">Authorization (Lock / Unlock)</label>
                        <select name="isActive" id="modalDetailIsActive" class="modal-form-select">
                            <option value="true">Unlock (Active - Allow telemetry)</option>
                            <option value="false">Lock (Inactive - Reject packets)</option>
                        </select>
                        <span class="modal-hint">Choose <b>Lock</b> to temporarily suspend packets from this device, or <b>Unlock</b> to resume active monitoring.</span>
                    </div>
                </div>
                
                <div class="device-modal-footer" style="gap: 10px;">
                    <button type="button" class="btn-modal-close" onclick="closeDeviceDetailModal()">Cancel</button>
                    <button type="submit" class="btn-modal-save">Save</button>
                </div>
            </form>
        </div>
    </div>

    <!-- Inject live Database device records into client script -->
    <script>
        window.APP_CTX = '<%= ctx %>';
        window.SERVER_DEVICES = <%= devicesJson.toString() %>;
        window.SERVER_BADGES = {
            bell: <%= openAlertCount %>,
            sidebarAlerts: <%= openAlertCount %>
        };

        window.openApiKeyModal = function(code, key) {
            var modal = document.getElementById("apiKeyModal");
            var codeEl = document.getElementById("modalDeviceCode");
            var keyInput = document.getElementById("modalApiKeyInput");
            var btnCopy = document.getElementById("btnCopyKey");
            var copyText = document.getElementById("copyBtnText");
            if (!modal) return;
            if (codeEl) codeEl.textContent = code || "-";
            if (keyInput) keyInput.value = key || "No API Key assigned";
            if (btnCopy) btnCopy.classList.remove("copied");
            if (copyText) copyText.textContent = "Copy";
            modal.style.display = "flex";
        };

        window.closeApiKeyModal = function() {
            var modal = document.getElementById("apiKeyModal");
            if (modal) modal.style.display = "none";
        };

        window.openDeviceDetailModal = function(idOrCode) {
            var dev = null;
            var list = window.SERVER_DEVICES || (typeof devices !== 'undefined' ? devices : []) || [];
            for (var i = 0; i < list.length; i++) {
                var item = list[i];
                if (item.id === idOrCode || String(item.deviceId) === String(idOrCode)) {
                    dev = item;
                    break;
                }
            }
            if (!dev) return;

            var modal = document.getElementById("deviceDetailModal");
            if (!modal) return;

            var devIdEl = document.getElementById("modalDetailDeviceId");
            var devCodeEl = document.getElementById("modalDetailDeviceCode");
            var roomIdEl = document.getElementById("modalDetailRoomId");
            var roomCodeEl = document.getElementById("modalDetailRoomCode");
            var apiKeyEl = document.getElementById("modalDetailApiKey");
            var noteEl = document.getElementById("modalDetailNote");
            var lastSeenEl = document.getElementById("modalDetailLastSeen");
            var activeSelect = document.getElementById("modalDetailIsActive");
            var statusPill = document.getElementById("modalDetailStatusPill");
            var statusText = document.getElementById("modalDetailStatusText");

            if (devIdEl) devIdEl.value = dev.deviceId || 0;
            if (devCodeEl) devCodeEl.value = dev.id || "";
            if (roomIdEl) roomIdEl.value = (dev.roomId !== undefined && dev.roomId !== null) ? dev.roomId : "";
            if (roomCodeEl) roomCodeEl.textContent = dev.classroom || "-";
            if (apiKeyEl) apiKeyEl.value = dev.apiKey || "";
            if (noteEl) noteEl.value = dev.note || "";
            if (lastSeenEl) lastSeenEl.textContent = dev.lastSeen || "Never";

            var isAct = dev.isActive !== undefined ? Boolean(dev.isActive) : ((dev.status || "").toLowerCase() === "active");
            if (activeSelect) {
                activeSelect.value = isAct ? "true" : "false";
            }
            if (statusPill && statusText) {
                if (isAct) {
                    statusPill.className = "status-pill online";
                    statusText.textContent = "Active";
                } else {
                    statusPill.className = "status-pill inactive";
                    statusText.textContent = "Inactive";
                }
            }

            var btnCopy = document.getElementById("btnCopyDetailKey");
            var copyText = document.getElementById("copyDetailBtnText");
            if (btnCopy) btnCopy.classList.remove("copied");
            if (copyText) copyText.textContent = "Copy";

            modal.style.display = "flex";
        };

        window.closeDeviceDetailModal = function() {
            var modal = document.getElementById("deviceDetailModal");
            if (modal) modal.style.display = "none";
        };

        window.copyApiKey = function() {
            var keyInput = document.getElementById("modalApiKeyInput");
            var btnCopy = document.getElementById("btnCopyKey");
            var copyText = document.getElementById("copyBtnText");
            if (!keyInput) return;
            var keyVal = keyInput.value;
            if (!keyVal || keyVal === "No API Key assigned") return;
            
            if (navigator.clipboard && navigator.clipboard.writeText) {
                navigator.clipboard.writeText(keyVal).then(function() {
                    if (btnCopy) btnCopy.classList.add("copied");
                    if (copyText) copyText.textContent = "Copied!";
                    setTimeout(function() {
                        if (btnCopy) btnCopy.classList.remove("copied");
                        if (copyText) copyText.textContent = "Copy";
                    }, 2000);
                }).catch(function() {
                    fallbackCopy(keyInput, btnCopy, copyText);
                });
            } else {
                fallbackCopy(keyInput, btnCopy, copyText);
            }
        };

        window.copyDetailApiKey = function() {
            var keyInput = document.getElementById("modalDetailApiKey");
            var btnCopy = document.getElementById("btnCopyDetailKey");
            var copyText = document.getElementById("copyDetailBtnText");
            if (!keyInput) return;
            var keyVal = keyInput.value;
            if (!keyVal) return;
            
            if (navigator.clipboard && navigator.clipboard.writeText) {
                navigator.clipboard.writeText(keyVal).then(function() {
                    if (btnCopy) btnCopy.classList.add("copied");
                    if (copyText) copyText.textContent = "Copied!";
                    setTimeout(function() {
                        if (btnCopy) btnCopy.classList.remove("copied");
                        if (copyText) copyText.textContent = "Copy";
                    }, 2000);
                }).catch(function() {
                    fallbackCopy(keyInput, btnCopy, copyText);
                });
            } else {
                fallbackCopy(keyInput, btnCopy, copyText);
            }
        };

        function fallbackCopy(input, btn, text) {
            input.select();
            input.setSelectionRange(0, 99999);
            try {
                document.execCommand("copy");
                if (btn) btn.classList.add("copied");
                if (text) text.textContent = "Copied!";
                setTimeout(function() {
                    if (btn) btn.classList.remove("copied");
                    if (text) text.textContent = "Copy";
                }, 2000);
            } catch(e) {}
        }

        window.filterByDeviceStatus = function(val) {
            if (window.setDeviceStatusFilter) {
                var current = (window.state && window.state.filterStatus) ? window.state.filterStatus : 'ALL';
                var next = (current.toUpperCase() === (val || '').toUpperCase() && (val || '').toUpperCase() !== 'ALL') ? 'ALL' : val;
                window.setDeviceStatusFilter(next);
            } else {
                var box = document.getElementById("statusSelectBox");
                if (!box) return;
                var popup = box.querySelector(".select-options-popup");
                if (!popup) return;
                var target = popup.querySelector('.option-item[data-val="' + val + '"]');
                if (target) target.click();
            }
        };

        document.addEventListener("keydown", function(e) {
            if (e.key === "Escape") {
                window.closeApiKeyModal();
                window.closeDeviceDetailModal();
            }
        });
    </script>
    <script src="<%= ctx %>/assets/js/devices.js?v=<%= System.currentTimeMillis() %>"></script>
    <script>
        if (window.SERVER_DEVICES && typeof renderAll === 'function') {
            devices = window.SERVER_DEVICES;
            renderAll();
        }
    </script>
</body>
</html>