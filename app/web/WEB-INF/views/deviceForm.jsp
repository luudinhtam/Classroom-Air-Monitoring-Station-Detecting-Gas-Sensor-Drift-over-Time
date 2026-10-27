<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="model.Device, model.AppUser, util.Web" %>
<%
    Device item = (Device) request.getAttribute("editDevice");
    String error = (String) request.getAttribute("error");
    String ctx = request.getContextPath();
    boolean isNew = (item == null || item.getDeviceId() == 0);

    AppUser me = (AppUser) session.getAttribute("user");
    String userName = (me != null && me.getFullName() != null) ? me.getFullName() : "Tai khoan ADMIN";
    String userRole = (me != null && me.getRoleCode() != null) ? me.getRoleCode() : "ADMIN";
    boolean isAdmin = "ADMIN".equals(userRole);

    int openAlertCount = 0;
    try {
        openAlertCount = dao.DashboardDAO.getInstance().getDashboardStats().getOpenAlerts();
    } catch (Exception ignored) {}

    String flash = (String) session.getAttribute("flash");
    if (flash != null) session.removeAttribute("flash");
    String flashError = (String) session.getAttribute("flashError");
    if (flashError != null) session.removeAttribute("flashError");

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
    <title><%= isNew ? "Add Device" : "Edit Device" %> – Classroom Air Monitoring System</title>
    <link rel="shortcut icon" href="<%= ctx %>/favicon.ico" type="image/x-icon">
    <!-- Google Fonts: Inter -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="<%= ctx %>/assets/css/devices.css?v=<%= System.currentTimeMillis() %>">
    <style>
        .form-layout-container {
            max-width: 760px;
            margin: 20px 0 40px;
        }

        .device-card-form {
            background: #ffffff;
            border: 1px solid #e2e8f0;
            border-radius: 12px;
            box-shadow: 0 4px 16px -2px rgba(15, 27, 61, 0.05), 0 2px 6px -1px rgba(15, 27, 61, 0.03);
            overflow: hidden;
        }

        .card-header-bar {
            padding: 20px 24px;
            border-bottom: 1px solid #f1f5f9;
            background: #fafbfc;
            display: flex;
            align-items: center;
            justify-content: space-between;
        }

        .card-header-title-group {
            display: flex;
            align-items: center;
            gap: 12px;
        }

        .card-header-icon {
            width: 38px;
            height: 38px;
            border-radius: 9px;
            background: #eff6ff;
            color: #2563eb;
            display: flex;
            align-items: center;
            justify-content: center;
            flex-shrink: 0;
        }

        .card-header-title {
            margin: 0;
            font-size: 16px;
            font-weight: 700;
            color: #0f172a;
        }

        .card-header-sub {
            margin: 2px 0 0;
            font-size: 12.5px;
            color: #64748b;
        }

        .card-body-form {
            padding: 24px;
        }

        .form-group-item {
            margin-bottom: 22px;
        }

        .form-label {
            display: flex;
            align-items: center;
            gap: 6px;
            font-size: 13px;
            font-weight: 600;
            color: #334155;
            margin-bottom: 8px;
        }

        .form-label .req-star {
            color: #ef4444;
            font-size: 13px;
            font-weight: 700;
        }

        .input-icon-wrap {
            position: relative;
            display: flex;
            align-items: center;
        }

        .input-prefix-icon {
            position: absolute;
            left: 14px;
            color: #94a3b8;
            pointer-events: none;
            display: flex;
            align-items: center;
            justify-content: center;
            transition: color 0.15s ease;
        }

        .form-input-control {
            width: 100%;
            height: 44px;
            padding: 0 14px 0 42px;
            background: #ffffff;
            border: 1px solid #cbd5e1;
            border-radius: 8px;
            font-family: inherit;
            font-size: 13.5px;
            color: #0f172a;
            box-sizing: border-box;
            outline: none;
            transition: border-color 0.18s ease, box-shadow 0.18s ease, background-color 0.18s ease;
        }

        .form-input-control:focus {
            border-color: #2563eb;
            box-shadow: 0 0 0 3px rgba(37, 99, 235, 0.12);
        }

        .form-input-control:focus + .input-prefix-icon,
        .input-icon-wrap:focus-within .input-prefix-icon {
            color: #2563eb;
        }

        .form-input-control[readonly] {
            background-color: #f8fafc;
            color: #64748b;
            cursor: not-allowed;
            border-color: #e2e8f0;
        }

        .field-helper-text {
            display: flex;
            align-items: center;
            gap: 5px;
            margin: 6px 0 0;
            font-size: 12px;
            color: #64748b;
            line-height: 1.4;
        }

        .input-with-button {
            display: flex;
            align-items: center;
            gap: 8px;
        }

        .btn-gen-key {
            height: 44px;
            padding: 0 16px;
            background: #eff6ff;
            color: #2563eb;
            border: 1px solid #bfdbfe;
            border-radius: 8px;
            font-size: 13px;
            font-weight: 600;
            cursor: pointer;
            display: inline-flex;
            align-items: center;
            gap: 6px;
            white-space: nowrap;
            transition: all 0.15s ease;
        }

        .btn-gen-key:hover {
            background: #dbeafe;
            border-color: #93c5fd;
        }

        /* Callout Notice */
        .device-info-callout {
            display: flex;
            align-items: flex-start;
            gap: 12px;
            background: #eff6ff;
            border: 1px solid #bfdbfe;
            border-radius: 8px;
            padding: 14px 16px;
            margin-bottom: 24px;
        }

        .callout-icon {
            color: #2563eb;
            flex-shrink: 0;
            margin-top: 1px;
        }

        .callout-content {
            font-size: 12.5px;
            color: #1e40af;
            line-height: 1.5;
        }

        .callout-content strong {
            font-weight: 700;
        }

        .callout-content code {
            background: #dbeafe;
            padding: 2px 6px;
            border-radius: 4px;
            font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
            font-weight: 700;
            color: #1d4ed8;
            border: 1px solid #bfdbfe;
        }

        /* Actions Bar */
        .form-actions-row {
            display: flex;
            align-items: center;
            justify-content: flex-end;
            gap: 12px;
            padding-top: 20px;
            margin-top: 10px;
            border-top: 1px solid #f1f5f9;
        }

        .btn-form-cancel {
            height: 42px;
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
            gap: 8px;
            transition: all 0.16s ease;
            cursor: pointer;
        }

        .btn-form-cancel:hover {
            background: #f8fafc;
            border-color: #94a3b8;
            color: #0f172a;
        }

        .btn-form-save {
            height: 42px;
            padding: 0 24px;
            background: #2563eb;
            border: 1px solid #2563eb;
            border-radius: 8px;
            color: #ffffff;
            font-size: 13.5px;
            font-weight: 600;
            display: inline-flex;
            align-items: center;
            gap: 8px;
            box-shadow: 0 2px 4px rgba(37, 99, 235, 0.2);
            transition: all 0.16s ease;
            cursor: pointer;
        }

        .btn-form-save:hover {
            background: #1d4ed8;
            border-color: #1d4ed8;
            box-shadow: 0 4px 10px rgba(37, 99, 235, 0.3);
        }

        .form-error-banner {
            display: flex;
            align-items: center;
            gap: 10px;
            background: #fef2f2;
            border: 1px solid #fecaca;
            color: #991b1b;
            padding: 12px 16px;
            border-radius: 8px;
            font-size: 13px;
            font-weight: 500;
            margin-bottom: 20px;
        }

        .breadcrumb-link {
            color: #2563eb !important;
            text-decoration: none;
        }
        .breadcrumb-link:hover {
            text-decoration: underline;
        }
    </style>
</head>
<body>

    <!-- 1. FIXED LEFT SIDEBAR (235px) -->
    <aside class="sidebar">
        <!-- Logo Header -->
        <div class="sidebar-logo">
            <div class="logo-box">
                <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#2563eb" stroke-width="2.3" stroke-linecap="round" stroke-linejoin="round">
                    <path d="M14 14.76V3.5a2.5 2.5 0 0 0-5 0v11.26a4.5 4.5 0 1 0 5 0z"/>
                    <circle cx="11.5" cy="17.5" r="1.5" fill="#2563eb"/>
                </svg>
            </div>
            <div class="logo-text">
                <span class="brand-title">Classroom Air</span>
                <span class="brand-sub">Monitoring System</span>
            </div>
        </div>

        <!-- Vertical Menu Navigation -->
        <nav class="sidebar-menu">
            <a href="<%= ctx %>/dashboard" class="menu-item" title="Dashboard">
                <svg class="menu-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <rect x="3" y="3" width="7" height="9" rx="1.5"/>
                    <rect x="14" y="3" width="7" height="5" rx="1.5"/>
                    <rect x="14" y="12" width="7" height="9" rx="1.5"/>
                    <rect x="3" y="16" width="7" height="5" rx="1.5"/>
                </svg>
                <span>Dashboard</span>
            </a>

            <a href="<%= ctx %>/admin/rooms" class="menu-item" title="Classrooms">
                <svg class="menu-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/>
                    <polyline points="9 22 9 12 15 12 15 22"/>
                </svg>
                <span>Classrooms</span>
            </a>

            <a href="<%= ctx %>/alerts" class="menu-item" title="Alerts">
                <svg class="menu-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/>
                    <path d="M13.73 21a2 2 0 0 1-3.46 0"/>
                </svg>
                <span>Alerts</span>
                <% if (openAlertCount > 0) { %>
                    <span class="sidebar-badge"><%= openAlertCount %></span>
                <% } %>
            </a>

            <a href="<%= ctx %>/admin/devices" class="menu-item active" title="Devices">
                <svg class="menu-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <rect x="4" y="4" width="16" height="16" rx="2"/>
                    <rect x="9" y="9" width="6" height="6"/>
                    <path d="M9 1v3M15 1v3M9 20v3M15 20v3M20 9h3M20 14h3M1 9h3M1 14h3"/>
                </svg>
                <span>Devices</span>
            </a>

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
                    <a href="<%= ctx %>/admin/devices" class="breadcrumb-item breadcrumb-link">Devices</a>
                    <span class="breadcrumb-separator">
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                            <polyline points="9 18 15 12 9 6"/>
                        </svg>
                    </span>
                    <span class="breadcrumb-item breadcrumb-current"><%= isNew ? "Add Device" : "Edit Device" %></span>
                </nav>
            </div>

            <!-- Right: Notifications & User Profile -->
            <div class="top-bar-right">
                <a href="<%= ctx %>/alerts" class="icon-btn-round" title="Notifications">
                    <svg width="19" height="19" viewBox="0 0 24 24" fill="none" stroke="#4b5563" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/>
                        <path d="M13.73 21a2 2 0 0 1-3.46 0"/>
                    </svg>
                    <% if (openAlertCount > 0) { %>
                        <span class="notif-badge" id="topBellBadge"><%= openAlertCount %></span>
                    <% } %>
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
            <div class="title-left">
                <div class="title-icon-box">
                    <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#ffffff" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                        <rect x="4" y="4" width="16" height="16" rx="2"/>
                        <rect x="9" y="9" width="6" height="6"/>
                        <path d="M9 1v3M15 1v3M9 20v3M15 20v3M20 9h3M20 14h3M1 9h3M1 14h3"/>
                    </svg>
                </div>
                <div class="title-text-group">
                    <h1 class="page-title"><%= isNew ? "Add New Device" : "Edit Device" %></h1>
                    <p class="page-subtitle"><%= isNew ? "Register a new hardware monitoring station or sensor node into the system." : "Update device authentication credentials and hardware notes." %></p>
                </div>
            </div>

            <!-- Date & Time Card -->
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

        <!-- 4. FORM CARD CONTAINER -->
        <div class="form-layout-container">
            <% if (error != null && !error.trim().isEmpty()) { %>
                <div class="form-error-banner">
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <circle cx="12" cy="12" r="10"/>
                        <line x1="12" y1="8" x2="12" y2="12"/>
                        <line x1="12" y1="16" x2="12.01" y2="16"/>
                    </svg>
                    <span><%= Web.esc(error) %></span>
                </div>
            <% } %>

            <div class="device-card-form">
                <div class="card-header-bar">
                    <div class="card-header-title-group">
                        <div class="card-header-icon">
                            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                                <path d="M12 2v4M12 18v4M4.93 4.93l2.83 2.83M16.24 16.24l2.83 2.83M2 12h4M18 12h4M4.93 19.07l2.83-2.83M16.24 7.76l2.83-2.83"/>
                            </svg>
                        </div>
                        <div>
                            <h3 class="card-header-title">Device Credentials & Configuration</h3>
                            <p class="card-header-sub">Provide the device code, API ingestion token, and installation note</p>
                        </div>
                    </div>
                </div>

                <div class="card-body-form">
                    <!-- Helper Notice -->
                    <div class="device-info-callout">
                        <svg class="callout-icon" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                            <circle cx="12" cy="12" r="10"/>
                            <line x1="12" y1="16" x2="12" y2="12"/>
                            <line x1="12" y1="8" x2="12.01" y2="8"/>
                        </svg>
                        <div class="callout-content">
                            <strong>Hardware Ingestion Note:</strong> The device board authenticates via HTTP header <code>X-API-Key</code> matching the API Key below. Packets with invalid keys will be recorded in <code>RejectedPacket</code>.
                        </div>
                    </div>

                    <form method="post" action="<%= ctx %>/admin/devices/save">
                        <input type="hidden" name="deviceId" value="<%= isNew ? 0 : item.getDeviceId() %>">
                        <input type="hidden" name="isActive" value="<%= item == null || item.isIsActive() ? "true" : "false" %>">
                        <input type="hidden" name="roomId" value="<%= (item != null && item.getRoomId() != null) ? item.getRoomId() : "" %>">

                        <!-- 1. Device Code Input -->
                        <div class="form-group-item">
                            <label class="form-label" for="deviceCode">
                                <span>Device code</span>
                                <span class="req-star">*</span>
                            </label>
                            <div class="input-icon-wrap">
                                <svg class="input-prefix-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                    <rect x="4" y="4" width="16" height="16" rx="2"/>
                                    <rect x="9" y="9" width="6" height="6"/>
                                    <path d="M9 1v3M15 1v3M9 20v3M15 20v3M20 9h3M20 14h3M1 9h3M1 14h3"/>
                                </svg>
                                <input type="text" 
                                       class="form-input-control" 
                                       id="deviceCode" 
                                       name="deviceCode" 
                                       required 
                                       minlength="3" 
                                       maxlength="32"
                                       placeholder="e.g. D001, AIR-DEV-01" 
                                       autocomplete="off"
                                       <%= !isNew ? "readonly" : "" %>
                                       value="<%= item == null ? "" : Web.esc(item.getDeviceCode()) %>">
                            </div>
                            <p class="field-helper-text">
                                <% if (!isNew) { %>
                                    <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                        <rect x="3" y="11" width="18" height="11" rx="2" ry="2"/>
                                        <path d="M7 11V7a5 5 0 0 1 10 0v4"/>
                                    </svg>
                                    <span>Device code cannot be changed once created.</span>
                                <% } else { %>
                                    <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                        <circle cx="12" cy="12" r="10"/>
                                        <line x1="12" y1="16" x2="12" y2="12"/>
                                        <line x1="12" y1="8" x2="12.01" y2="8"/>
                                    </svg>
                                    <span>Unique identifier for the hardware device (e.g. D001, D002).</span>
                                <% } %>
                            </p>
                        </div>

                        <!-- 2. API Key Input -->
                        <div class="form-group-item">
                            <label class="form-label" for="apiKey">
                                <span>API Key</span>
                                <span class="req-star">*</span>
                            </label>
                            <div class="input-with-button">
                                <div class="input-icon-wrap" style="flex: 1;">
                                    <svg class="input-prefix-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                        <path d="M21 2l-2 2m-1.5 1.5L14 9l-1.5-1.5L11 9l-1.5-1.5L8 9"/>
                                        <circle cx="7.5" cy="16.5" r="5.5"/>
                                        <path d="m3.5 14.5 4 4"/>
                                    </svg>
                                    <input type="text" 
                                           class="form-input-control" 
                                           id="apiKey" 
                                           name="apiKey" 
                                           required 
                                           maxlength="64"
                                           placeholder="e.g. demo-key-d001" 
                                           autocomplete="off"
                                           value="<%= item == null ? "" : Web.esc(item.getApiKey()) %>">
                                </div>
                                <button type="button" class="btn-gen-key" id="btnGenKey" title="Generate random secure key">
                                    <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                                        <polyline points="23 4 23 10 17 10"/>
                                        <path d="M20.49 15a9 9 0 1 1-2.12-9.36L23 10"/>
                                    </svg>
                                    <span>Generate</span>
                                </button>
                            </div>
                            <p class="field-helper-text">
                                <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                    <circle cx="12" cy="12" r="10"/>
                                    <line x1="12" y1="16" x2="12" y2="12"/>
                                    <line x1="12" y1="8" x2="12.01" y2="8"/>
                                </svg>
                                <span>Used by the microcontroller board in the HTTP request header <code>X-API-Key</code>.</span>
                            </p>
                        </div>

                        <!-- 3. Note Input -->
                        <div class="form-group-item">
                            <label class="form-label" for="note">
                                <span>Note</span>
                            </label>
                            <div class="input-icon-wrap">
                                <svg class="input-prefix-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                    <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/>
                                    <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/>
                                </svg>
                                <input type="text" 
                                       class="form-input-control" 
                                       id="note" 
                                       name="note" 
                                       maxlength="150"
                                       placeholder="e.g. Phòng P001, Gắn tường cửa ra vào" 
                                       value="<%= item == null || item.getNote() == null ? "" : Web.esc(item.getNote()) %>">
                            </div>
                            <p class="field-helper-text">
                                <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                    <circle cx="12" cy="12" r="10"/>
                                    <line x1="12" y1="16" x2="12" y2="12"/>
                                    <line x1="12" y1="8" x2="12.01" y2="8"/>
                                </svg>
                                <span>Optional installation notes, designated classroom, or hardware location.</span>
                            </p>
                        </div>

                        <!-- 4. Add and Cancel Buttons -->
                        <div class="form-actions-row">
                            <a href="<%= ctx %>/admin/devices" class="btn-form-cancel" title="Cancel and return to devices list">
                                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                                    <line x1="18" y1="6" x2="6" y2="18"/>
                                    <line x1="6" y1="6" x2="18" y2="18"/>
                                </svg>
                                <span>Cancel</span>
                            </a>
                            <button type="submit" class="btn-form-save" title="<%= isNew ? "Add device" : "Save changes" %>">
                                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.3" stroke-linecap="round" stroke-linejoin="round">
                                    <% if (isNew) { %>
                                        <line x1="12" y1="5" x2="12" y2="19"/>
                                        <line x1="5" y1="12" x2="19" y2="12"/>
                                    <% } else { %>
                                        <path d="M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2z"/>
                                        <polyline points="17 21 17 13 7 13 7 21"/>
                                        <polyline points="7 3 7 8 15 8"/>
                                    <% } %>
                                </svg>
                                <span><%= isNew ? "Add" : "Save Changes" %></span>
                            </button>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </main>

    <!-- Page Scripts -->
    <script>
        // Sidebar Toggle
        const btnSidebarToggle = document.getElementById("btnSidebarToggle");
        if (btnSidebarToggle) {
            btnSidebarToggle.addEventListener("click", () => {
                document.body.classList.toggle("sidebar-collapsed");
            });
        }

        // User Profile Dropdown
        const userMenuToggle = document.getElementById("userMenuToggle");
        const userDropdownMenu = document.getElementById("userDropdownMenu");
        if (userMenuToggle && userDropdownMenu) {
            userMenuToggle.addEventListener("click", (e) => {
                e.stopPropagation();
                userDropdownMenu.classList.toggle("show");
            });

            document.addEventListener("click", (e) => {
                if (!userDropdownMenu.contains(e.target)) {
                    userDropdownMenu.classList.remove("show");
                }
            });
        }

        // Generate Random API Key
        const btnGenKey = document.getElementById("btnGenKey");
        const apiKeyInput = document.getElementById("apiKey");
        const devCodeInput = document.getElementById("deviceCode");

        if (btnGenKey && apiKeyInput) {
            btnGenKey.addEventListener("click", () => {
                const prefix = (devCodeInput && devCodeInput.value.trim()) 
                    ? "key-" + devCodeInput.value.trim().toLowerCase().replace(/[^a-z0-9]/g, "") + "-"
                    : "dev-key-";
                const chars = "abcdefghijklmnopqrstuvwxyz0123456789";
                let randomStr = "";
                for (let i = 0; i < 16; i++) {
                    randomStr += chars.charAt(Math.floor(Math.random() * chars.length));
                }
                apiKeyInput.value = prefix + randomStr;
                apiKeyInput.focus();
            });
        }
    </script>
</body>
</html>
