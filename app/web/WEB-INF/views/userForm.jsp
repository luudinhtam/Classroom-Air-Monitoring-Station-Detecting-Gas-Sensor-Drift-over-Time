<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.List, model.AppUser, model.AppRole, util.Web" %>
<%
    AppUser item = (AppUser) request.getAttribute("editUser");
    List<AppRole> roles = (List<AppRole>) request.getAttribute("roles");
    String error = (String) request.getAttribute("error");
    String ctx = request.getContextPath();
    boolean isNew = (item == null || item.getUserId() == 0);

    AppUser me = (AppUser) session.getAttribute("user");
    String userName = (me != null && me.getFullName() != null) ? me.getFullName() : "Tai khoan ADMIN";
    String userRole = (me != null && me.getRoleCode() != null) ? me.getRoleCode() : "ADMIN";
    boolean isAdmin = "ADMIN".equals(userRole);

    int openAlertCount = 6;
    try {
        openAlertCount = dao.DashboardDAO.getInstance().getDashboardStats().getOpenAlerts();
        if (openAlertCount <= 0) openAlertCount = 6;
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
    <title><%= isNew ? "Add User" : "User Details" %> – Classroom Air Monitoring System</title>
    <link rel="shortcut icon" href="<%= ctx %>/favicon.ico" type="image/x-icon">
    <!-- Google Fonts: Inter -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="<%= ctx %>/assets/css/users.css?v=<%= System.currentTimeMillis() %>">
    <style>
        .form-layout-container {
            max-width: 760px;
            margin: 20px 0 40px;
        }

        .user-card-form {
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

        .form-select-control {
            width: 100%;
            height: 44px;
            padding: 0 36px 0 42px;
            background: #ffffff;
            border: 1px solid #cbd5e1;
            border-radius: 8px;
            font-family: inherit;
            font-size: 13.5px;
            color: #0f172a;
            box-sizing: border-box;
            outline: none;
            cursor: pointer;
            appearance: none;
            -webkit-appearance: none;
            transition: border-color 0.18s ease, box-shadow 0.18s ease;
        }

        .form-select-control:focus {
            border-color: #2563eb;
            box-shadow: 0 0 0 3px rgba(37, 99, 235, 0.12);
        }

        .select-chevron-icon {
            position: absolute;
            right: 14px;
            color: #94a3b8;
            pointer-events: none;
            display: flex;
            align-items: center;
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

        /* Notice Box for new account */
        .default-password-callout {
            display: flex;
            align-items: flex-start;
            gap: 12px;
            background: #f0fdf4;
            border: 1px solid #bbf7d0;
            border-radius: 8px;
            padding: 14px 16px;
            margin-bottom: 24px;
        }

        .callout-icon {
            color: #16a34a;
            flex-shrink: 0;
            margin-top: 1px;
        }

        .callout-content {
            font-size: 12.5px;
            color: #166534;
            line-height: 1.5;
        }

        .callout-content strong {
            font-weight: 700;
        }

        .callout-content code {
            background: #dcfce7;
            padding: 2px 6px;
            border-radius: 4px;
            font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
            font-weight: 700;
            color: #15803d;
            border: 1px solid #bbf7d0;
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

        /* Flash / Error Banner */
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
                <span class="sidebar-badge"><%= openAlertCount %></span>
            </a>

            <a href="<%= ctx %>/admin/devices" class="menu-item" title="Devices">
                <svg class="menu-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <rect x="4" y="4" width="16" height="16" rx="2"/>
                    <rect x="9" y="9" width="6" height="6"/>
                    <path d="M9 1v3M15 1v3M9 20v3M15 20v3M20 9h3M20 14h3M1 9h3M1 14h3"/>
                </svg>
                <span>Devices</span>
            </a>

            <% if (isAdmin) { %>
            <a href="<%= ctx %>/admin/users" class="menu-item active" title="Users">
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
                    <a href="<%= ctx %>/admin/users" class="breadcrumb-item breadcrumb-link">Users</a>
                    <span class="breadcrumb-separator">
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                            <polyline points="9 18 15 12 9 6"/>
                        </svg>
                    </span>
                    <span class="breadcrumb-item breadcrumb-current"><%= isNew ? "Add User" : "Edit User" %></span>
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

        <!-- 3. PAGE TITLE SECTION -->
        <section class="page-title-section">
            <div class="title-left">
                <div class="title-icon-box">
                    <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#ffffff" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M16 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/>
                        <circle cx="8.5" cy="7" r="4"/>
                        <line x1="20" y1="8" x2="20" y2="14"/>
                        <line x1="23" y1="11" x2="17" y2="11"/>
                    </svg>
                </div>
                <div class="title-text-group">
                    <h1 class="page-title"><%= isNew ? "Add New User" : "User Details" %></h1>
                    <p class="page-subtitle"><%= isNew ? "Create a user account with login handle, full name, and assigned system role." : "View and update profile details and role permissions." %></p>
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

        <!-- 4. MAIN FORM CONTAINER -->
        <div class="form-layout-container">
            <% if (error != null && !error.isEmpty()) { %>
            <div class="form-error-banner">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                    <circle cx="12" cy="12" r="10"/>
                    <line x1="12" y1="8" x2="12" y2="12"/>
                    <line x1="12" y1="16" x2="12.01" y2="16"/>
                </svg>
                <span><%= Web.esc(error) %></span>
            </div>
            <% } %>

            <% if (flash != null && !flash.isEmpty()) { %>
            <div class="flash-banner success" style="margin-bottom: 20px;">
                <span><%= Web.esc(flash) %></span>
            </div>
            <% } %>

            <div class="user-card-form">
                <!-- Card Header -->
                <div class="card-header-bar">
                    <div class="card-header-title-group">
                        <div class="card-header-icon">
                            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                                <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/>
                                <circle cx="12" cy="7" r="4"/>
                            </svg>
                        </div>
                        <div>
                            <h3 class="card-header-title">Account Information</h3>
                            <p class="card-header-sub">Provide valid user credentials and assign role permissions.</p>
                        </div>
                    </div>
                </div>

                <!-- Form Body -->
                <form class="card-body-form" method="post" action="<%= ctx %>/admin/users/save">
                    <input type="hidden" name="userId" value="<%= isNew ? 0 : item.getUserId() %>">

                    <!-- Default Password Notice (New User only) -->
                    <% if (isNew) { %>
                    <div class="default-password-callout">
                        <svg class="callout-icon" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                            <rect x="3" y="11" width="18" height="11" rx="2" ry="2"/>
                            <path d="M7 11V7a5 5 0 0 1 10 0v4"/>
                        </svg>
                        <div class="callout-content">
                            <strong>Default Password Notice:</strong> The temporary login password for newly created accounts is <code>123456</code>. Users can change their password after signing in.
                        </div>
                    </div>
                    <% } %>

                    <!-- 1. Username Input -->
                    <div class="form-group-item">
                        <label class="form-label" for="username">
                            <span>Username</span>
                            <span class="req-star">*</span>
                        </label>
                        <div class="input-icon-wrap">
                            <svg class="input-prefix-icon" width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                <circle cx="12" cy="12" r="4"/>
                                <path d="M16 8v5a3 3 0 0 0 6 0v-1a10 10 0 1 0-3.92 7.94"/>
                            </svg>
                            <input type="text" 
                                   class="form-input-control" 
                                   id="username" 
                                   name="username" 
                                   required 
                                   minlength="3" 
                                   maxlength="50"
                                   placeholder="e.g. johndoe" 
                                   autocomplete="off"
                                   value="<%= item == null ? "" : Web.esc(item.getUsername()) %>"
                                   <%= !isNew ? "readonly" : "" %>>
                        </div>
                        <p class="field-helper-text">
                            <% if (!isNew) { %>
                                <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                    <rect x="3" y="11" width="18" height="11" rx="2" ry="2"/>
                                    <path d="M7 11V7a5 5 0 0 1 10 0v4"/>
                                </svg>
                                <span>Username cannot be modified once the account is created.</span>
                            <% } else { %>
                                <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                    <circle cx="12" cy="12" r="10"/>
                                    <line x1="12" y1="16" x2="12" y2="12"/>
                                    <line x1="12" y1="8" x2="12.01" y2="8"/>
                                </svg>
                                <span>Minimum 3 characters. Unique identifier for system authentication.</span>
                            <% } %>
                        </p>
                    </div>

                    <!-- Password field with toggle for details view -->
                    <% if (!isNew) { %>
                    <div class="form-group-item">
                        <label class="form-label" for="userFormPassword">
                            <span>Password</span>
                        </label>
                        <div class="input-icon-wrap" style="position: relative;">
                            <svg class="input-prefix-icon" width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                <rect x="3" y="11" width="18" height="11" rx="2" ry="2"/>
                                <path d="M7 11V7a5 5 0 0 1 10 0v4"/>
                            </svg>
                            <input type="password" 
                                   class="form-input-control" 
                                   id="userFormPassword" 
                                   value="123456" 
                                   readonly 
                                   style="padding-right: 85px; letter-spacing: 1px; background: #f8fafc; font-family: inherit;">
                            <button type="button" 
                                    id="btnToggleFormPass"
                                    onclick="toggleUserFormPassword()" 
                                    style="position: absolute; right: 8px; top: 50%; transform: translateY(-50%); height: 28px; padding: 0 10px; border-radius: 6px; background: #f1f5f9; border: 1px solid #e2e8f0; color: #475569; font-size: 12px; font-weight: 600; cursor: pointer; display: inline-flex; align-items: center; gap: 4px; transition: all 0.15s ease;">
                                <span id="toggleFormPassIcon" style="display: inline-flex; align-items: center;">
                                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                                        <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/>
                                        <circle cx="12" cy="12" r="3"/>
                                    </svg>
                                </span>
                                <span id="toggleFormPassText">Show</span>
                            </button>
                        </div>
                    </div>
                    <% } %>

                    <!-- 2. Full Name Input -->
                    <div class="form-group-item">
                        <label class="form-label" for="fullName">
                            <span>Full Name</span>
                            <span class="req-star">*</span>
                        </label>
                        <div class="input-icon-wrap">
                            <svg class="input-prefix-icon" width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/>
                                <circle cx="12" cy="7" r="4"/>
                            </svg>
                            <input type="text" 
                                   class="form-input-control" 
                                   id="fullName" 
                                   name="fullName" 
                                   required 
                                   maxlength="100"
                                   placeholder="e.g. Johnathan Doe" 
                                   autocomplete="name"
                                   value="<%= item == null ? "" : Web.esc(item.getFullName()) %>">
                        </div>
                        <p class="field-helper-text">
                            <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                <circle cx="12" cy="12" r="10"/>
                                <line x1="12" y1="16" x2="12" y2="12"/>
                                <line x1="12" y1="8" x2="12.01" y2="8"/>
                            </svg>
                            <span>Official display name shown on dashboards, audit logs, and alert assignments.</span>
                        </p>
                    </div>

                    <!-- 3. Role Select Dropdown -->
                    <div class="form-group-item">
                        <label class="form-label" for="roleId">
                            <span>Role</span>
                            <span class="req-star">*</span>
                        </label>
                        <div class="input-icon-wrap">
                            <svg class="input-prefix-icon" width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/>
                            </svg>
                            <select name="roleId" id="roleId" class="form-select-control" required>
                                <option value="" disabled <%= isNew ? "selected" : "" %>>-- Select User Role --</option>
                                <% if (roles != null) { 
                                    for (AppRole r : roles) { 
                                        boolean isSelected = (item != null && item.getRoleId() == r.getRoleId());
                                %>
                                <option value="<%= r.getRoleId() %>" <%= isSelected ? "selected" : "" %>>
                                    <%= Web.esc(r.getRoleCode()) %> &mdash; <%= Web.esc(r.getRoleName()) %>
                                </option>
                                <%  } 
                                   } %>
                            </select>
                            <svg class="select-chevron-icon" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                                <polyline points="6 9 12 15 18 9"/>
                            </svg>
                        </div>
                        <p class="field-helper-text">
                            <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                <circle cx="12" cy="12" r="10"/>
                                <line x1="12" y1="16" x2="12" y2="12"/>
                                <line x1="12" y1="8" x2="12.01" y2="8"/>
                            </svg>
                            <span>Select authorization tier (ADMIN, STATION_MANAGER, OPERATOR, REVIEWER, or VIEWER).</span>
                        </p>
                    </div>

                    <!-- 4. Save and Cancel Buttons -->
                    <div class="form-actions-row">
                        <a href="<%= ctx %>/admin/users" class="btn-form-cancel" title="Cancel and return to users list">
                            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                                <line x1="18" y1="6" x2="6" y2="18"/>
                                <line x1="6" y1="6" x2="18" y2="18"/>
                            </svg>
                            <span>Cancel</span>
                        </a>
                        <button type="submit" class="btn-form-save" title="Save user">
                            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.3" stroke-linecap="round" stroke-linejoin="round">
                                <path d="M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2z"/>
                                <polyline points="17 21 17 13 7 13 7 21"/>
                                <polyline points="7 3 7 8 15 8"/>
                            </svg>
                            <span><%= isNew ? "Save" : "Save Changes" %></span>
                        </button>
                    </div>
                </form>
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

        // Toggle Password Visibility in User Form
        function toggleUserFormPassword() {
            const passInput = document.getElementById("userFormPassword");
            const btnText = document.getElementById("toggleFormPassText");
            const btnIcon = document.getElementById("toggleFormPassIcon");
            if (!passInput) return;

            if (passInput.type === "password") {
                passInput.type = "text";
                if (btnText) btnText.textContent = "Hide";
                if (btnIcon) {
                    btnIcon.innerHTML = '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24"/><line x1="1" y1="1" x2="23" y2="23"/></svg>';
                }
            } else {
                passInput.type = "password";
                if (btnText) btnText.textContent = "Show";
                if (btnIcon) {
                    btnIcon.innerHTML = '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>';
                }
            }
        }
    </script>
</body>
</html>
