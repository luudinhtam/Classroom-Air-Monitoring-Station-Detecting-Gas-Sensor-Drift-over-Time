<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.util.List, java.text.SimpleDateFormat, model.AppUser, model.AppRole, util.Web"%>
<%
    List<AppUser> rows = (List<AppUser>) request.getAttribute("rows");
    List<AppRole> roles = (List<AppRole>) request.getAttribute("roles");
    AppUser me = (AppUser) session.getAttribute("user");
    String ctx = request.getContextPath();

    String userName = (me != null && me.getFullName() != null) ? me.getFullName() : "Tai khoan ADMIN";
    String userRole = (me != null && me.getRoleCode() != null) ? me.getRoleCode() : "ADMIN";
    boolean isAdmin = "ADMIN".equals(userRole);

    String keyword = (String) request.getAttribute("keyword");
    Integer roleId = (Integer) request.getAttribute("roleId");
    String lockState = (String) request.getAttribute("lockState");
    Integer currentPage = (Integer) request.getAttribute("page");
    Integer totalPages  = (Integer) request.getAttribute("pages");
    if (currentPage == null) currentPage = 1;
    if (totalPages  == null) totalPages  = 1;

    Integer totalObj = (Integer) request.getAttribute("total");
    int total = (totalObj != null) ? totalObj : (rows != null ? rows.size() : 0);

    Integer totalUsersObj = (Integer) request.getAttribute("totalUsers");
    int totalUsers = (totalUsersObj != null) ? totalUsersObj : total;

    Integer activeUsersObj = (Integer) request.getAttribute("activeUsers");
    int activeUsers = (activeUsersObj != null) ? activeUsersObj : total;

    Integer lockedUsersObj = (Integer) request.getAttribute("lockedUsers");
    int lockedUsers = (lockedUsersObj != null) ? lockedUsersObj : 0;

    Integer adminCountObj = (Integer) request.getAttribute("adminCount");
    int adminCount = (adminCountObj != null) ? adminCountObj : 1;

    Integer openAlertObj = (Integer) request.getAttribute("openAlertCount");
    int openAlertCount = (openAlertObj != null && openAlertObj > 0) ? openAlertObj : 6;

    String qs = "keyword=" + Web.esc(keyword)
              + "&roleId=" + (roleId == null ? "" : roleId.toString())
              + "&lockState=" + Web.esc(lockState);

    java.time.ZonedDateTime nowZdt = java.time.ZonedDateTime.now(java.time.ZoneId.of("Asia/Ho_Chi_Minh"));
    String jDateStr = nowZdt.format(java.time.format.DateTimeFormatter.ofPattern("EEEE, d MMMM yyyy", java.util.Locale.ENGLISH));
    String jTimeStr = nowZdt.format(java.time.format.DateTimeFormatter.ofPattern("HH:mm"));
    String jSidebarDateTime = nowZdt.format(java.time.format.DateTimeFormatter.ofPattern("EEEE, dd/MM/yyyy, HH:mm", java.util.Locale.ENGLISH));

    double activePct = totalUsers > 0 ? ((double) activeUsers / totalUsers * 100) : 0;
    double lockedPct = totalUsers > 0 ? ((double) lockedUsers / totalUsers * 100) : 0;
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Users – Classroom Temp Monitoring System</title>
    <link rel="shortcut icon" href="<%= ctx %>/favicon.ico" type="image/x-icon">
    <!-- Google Fonts: Inter -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="<%= ctx %>/assets/css/users.css">
    <style>
        /* User Detail Modal Styling */
        .user-modal-backdrop {
            position: fixed;
            top: 0;
            left: 0;
            width: 100vw;
            height: 100vh;
            background: rgba(15, 23, 42, 0.45);
            backdrop-filter: blur(4px);
            z-index: 1050;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 16px;
            box-sizing: border-box;
        }

        .user-modal-card {
            background: #ffffff;
            border-radius: 14px;
            box-shadow: 0 20px 25px -5px rgba(15, 23, 42, 0.2), 0 8px 10px -6px rgba(15, 23, 42, 0.1);
            width: 100%;
            max-width: 540px;
            border: 1px solid #e2e8f0;
            animation: userModalPop 0.2s cubic-bezier(0.16, 1, 0.3, 1);
            overflow: hidden;
        }

        @keyframes userModalPop {
            from { opacity: 0; transform: scale(0.96) translateY(-8px); }
            to { opacity: 1; transform: scale(1) translateY(0); }
        }

        .user-modal-header {
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 18px 22px;
            border-bottom: 1px solid #f1f5f9;
            background: #ffffff;
        }

        .user-modal-title-group {
            display: flex;
            align-items: center;
            gap: 12px;
        }

        .modal-icon-badge {
            width: 38px;
            height: 38px;
            border-radius: 10px;
            background: #eff6ff;
            color: #2563eb;
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
            font-size: 24px;
            color: #94a3b8;
            cursor: pointer;
            line-height: 1;
            padding: 4px;
            border-radius: 6px;
            transition: all 0.15s ease;
        }
        .modal-close-btn:hover {
            color: #0f172a;
            background: #f1f5f9;
        }

        .user-modal-body {
            padding: 22px;
            display: flex;
            flex-direction: column;
            gap: 15px;
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

        .modal-form-input, .modal-form-select {
            width: 100%;
            height: 38px;
            border: 1px solid #cbd5e1;
            border-radius: 8px;
            padding: 0 12px;
            font-size: 13.5px;
            color: #0f172a;
            background: #ffffff;
            box-sizing: border-box;
            outline: none;
            transition: all 0.15s ease;
        }
        .modal-form-input:focus, .modal-form-select:focus {
            border-color: #2563eb;
            box-shadow: 0 0 0 3px rgba(37, 99, 235, 0.12);
        }

        .password-input-group {
            display: flex;
            align-items: center;
            position: relative;
        }

        .password-input-group .modal-form-input {
            padding-right: 78px;
            letter-spacing: 0.5px;
        }

        .btn-toggle-password {
            position: absolute;
            right: 6px;
            height: 28px;
            padding: 0 8px;
            border-radius: 6px;
            background: #f1f5f9;
            border: 1px solid #e2e8f0;
            color: #475569;
            font-size: 11.5px;
            font-weight: 600;
            cursor: pointer;
            display: inline-flex;
            align-items: center;
            gap: 4px;
            transition: all 0.15s ease;
        }
        .btn-toggle-password:hover {
            background: #e2e8f0;
            color: #0f172a;
        }

        .user-modal-footer {
            display: flex;
            align-items: center;
            justify-content: flex-end;
            gap: 10px;
            padding: 16px 22px;
            border-top: 1px solid #f1f5f9;
            background: #f8fafc;
        }

        .btn-modal-cancel {
            height: 38px;
            padding: 0 16px;
            border-radius: 8px;
            background: #ffffff;
            border: 1px solid #cbd5e1;
            color: #475569;
            font-size: 13px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.15s ease;
        }
        .btn-modal-cancel:hover {
            background: #f1f5f9;
            color: #0f172a;
        }

        .btn-modal-save {
            height: 38px;
            padding: 0 20px;
            border-radius: 8px;
            background: #2563eb;
            border: 1px solid transparent;
            color: #ffffff;
            font-size: 13px;
            font-weight: 600;
            cursor: pointer;
            box-shadow: 0 1px 2px rgba(0, 0, 0, 0.05);
            transition: all 0.15s ease;
        }
        .btn-modal-save:hover {
            background: #1d4ed8;
        }
        /* 3 Stats Cards Interactive Styling */
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
        .stat-card.active-red {
            border: 2px solid #ef4444 !important;
            background: #fef8f8 !important;
            box-shadow: 0 0 0 3px rgba(239, 68, 68, 0.12) !important;
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

            <!-- ACTIVE ITEM: Users -->
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
                    <span class="breadcrumb-item breadcrumb-current">Users</span>
                </nav>
            </div>

            <!-- Right: Notifications & User Profile -->
            <div class="top-bar-right">
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

        <!-- 3. PAGE TITLE SECTION -->
        <section class="page-title-section">
            <div class="title-left-group">
                <div class="title-icon-box">
                    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#ffffff" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/>
                        <circle cx="9" cy="7" r="4"/>
                        <path d="M23 21v-2a4 4 0 0 0-3-3.87"/>
                        <path d="M16 3.13a4 4 0 0 1 0 7.75"/>
                    </svg>
                </div>
                <div class="title-text-group">
                    <h1 class="page-main-heading">Users</h1>
                    <p class="page-subheading">Manage system accounts, user roles, and access credentials.</p>
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

        <!-- 4. THREE STATS CARDS -->
        <section class="stats-cards-grid" style="grid-template-columns: repeat(3, 1fr);">
            <!-- 1. Total Users -->
            <div class="stat-card <%= (lockState == null || lockState.isEmpty()) ? "active active-blue" : "" %>" 
                 data-status="ALL" onclick="filterByUserStatus('ALL')" title="Show all users">
                <div class="stat-icon-wrapper blue">
                    <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/>
                        <circle cx="9" cy="7" r="4"/>
                        <path d="M23 21v-2a4 4 0 0 0-3-3.87"/>
                        <path d="M16 3.13a4 4 0 0 1 0 7.75"/>
                    </svg>
                </div>
                <div class="stat-info">
                    <span class="stat-label">Total Users</span>
                    <div class="stat-value-row">
                        <span class="stat-value"><%= totalUsers %></span>
                    </div>
                    <span class="stat-subtext">Registered accounts</span>
                </div>
            </div>

            <!-- 2. Active Accounts -->
            <div class="stat-card <%= "ACTIVE".equalsIgnoreCase(lockState) ? "active active-green" : "" %>" 
                 data-status="ACTIVE" onclick="filterByUserStatus('ACTIVE')" title="Filter Active users">
                <div class="stat-icon-wrapper green">
                    <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/>
                        <polyline points="22 4 12 14.01 9 11.01"/>
                    </svg>
                </div>
                <div class="stat-info">
                    <span class="stat-label">Active</span>
                    <div class="stat-value-row">
                        <span class="stat-value"><%= activeUsers %></span>
                    </div>
                    <span class="stat-subtext"><%= String.format(java.util.Locale.US, "%.1f", activePct) %>% of total</span>
                </div>
            </div>

            <!-- 3. Locked Accounts -->
            <div class="stat-card <%= "LOCKED".equalsIgnoreCase(lockState) ? "active active-red" : "" %>" 
                 data-status="LOCKED" onclick="filterByUserStatus('LOCKED')" title="Filter Locked users">
                <div class="stat-icon-wrapper red">
                    <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                        <rect x="3" y="11" width="18" height="11" rx="2" ry="2"/>
                        <path d="M7 11V7a5 5 0 0 1 10 0v4"/>
                    </svg>
                </div>
                <div class="stat-info">
                    <span class="stat-label">Locked</span>
                    <div class="stat-value-row">
                        <span class="stat-value"><%= lockedUsers %></span>
                    </div>
                    <span class="stat-subtext"><%= String.format(java.util.Locale.US, "%.1f", lockedPct) %>% of total</span>
                </div>
            </div>
        </section>

        <!-- 5. FILTER BAR CARD -->
        <section class="filter-card">
            <form class="filter-form" method="get" action="<%= ctx %>/admin/users" id="usersFilterForm">
                <!-- Search Box -->
                <div class="search-input-group">
                    <svg class="search-icon" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                        <circle cx="11" cy="11" r="8"/>
                        <line x1="21" y1="21" x2="16.65" y2="16.65"/>
                    </svg>
                    <input type="text" class="search-field" name="keyword" id="userSearchInput" placeholder="Search by username, full name..." value="<%= Web.esc(keyword) %>" autocomplete="off">
                </div>

                <!-- Role Filter -->
                <select class="filter-select" name="roleId" id="userRoleSelect">
                    <option value="">-- All Roles --</option>
                    <% if (roles != null) { for (AppRole r : roles) { %>
                    <option value="<%= r.getRoleId() %>" <%= (roleId != null && roleId.intValue() == r.getRoleId()) ? "selected" : "" %>>
                        <%= Web.esc(r.getRoleCode()) %>
                    </option>
                    <% } } %>
                </select>

                <!-- Status Filter -->
                <select class="filter-select" name="lockState" id="userStatusSelect">
                    <option value="">-- All Statuses --</option>
                    <option value="ACTIVE" <%= "ACTIVE".equals(lockState) ? "selected" : "" %>>Active</option>
                    <option value="LOCKED" <%= "LOCKED".equals(lockState) ? "selected" : "" %>>Locked</option>
                </select>

                <button type="submit" class="btn-filter">Filter</button>
                <a class="btn-reset" href="<%= ctx %>/admin/users">Reset</a>

                <!-- Add User Button -->
                <a class="btn-add-user" href="<%= ctx %>/admin/users/create">
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round">
                        <line x1="12" y1="5" x2="12" y2="19"/>
                        <line x1="5" y1="12" x2="19" y2="12"/>
                    </svg>
                    <span>Add User</span>
                </a>
            </form>
        </section>

        <!-- 6. USERS TABLE CARD -->
        <section class="table-card">
            <div class="table-responsive">
                <table class="users-table">
                    <thead>
                        <tr>
                            <th style="width: 70px;">ID</th>
                            <th>User</th>
                            <th style="width: 170px;">Role</th>
                            <th style="width: 130px;">Status</th>
                            <th style="width: 170px; text-align: right; padding-right: 20px;">Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        <% if (rows != null && !rows.isEmpty()) {
                            SimpleDateFormat sdfDt = new SimpleDateFormat("dd/MM/yyyy HH:mm");
                            for (AppUser u : rows) {
                                String rCode = u.getRoleCode() != null ? u.getRoleCode() : "VIEWER";
                                String rName = (u.getRoleName() != null && !u.getRoleName().trim().isEmpty()) ? u.getRoleName() : rCode;
                                String createdStr = (u.getCreatedAt() != null) ? sdfDt.format(u.getCreatedAt()) : "-";
                                String roleBadgeClass = "role-viewer";
                                if ("ADMIN".equalsIgnoreCase(rCode)) roleBadgeClass = "role-admin";
                                else if ("STATION_MANAGER".equalsIgnoreCase(rCode)) roleBadgeClass = "role-manager";
                                else if ("OPERATOR".equalsIgnoreCase(rCode)) roleBadgeClass = "role-operator";
                                else if ("REVIEWER".equalsIgnoreCase(rCode)) roleBadgeClass = "role-reviewer";

                                String initial = (u.getFullName() != null && !u.getFullName().isEmpty()) 
                                    ? u.getFullName().substring(0, 1).toUpperCase() 
                                    : (u.getUsername() != null && !u.getUsername().isEmpty() ? u.getUsername().substring(0, 1).toUpperCase() : "U");
                        %>
                        <tr class="<%= u.isLocked() ? "row-locked" : "" %>" data-status="<%= u.isLocked() ? "LOCKED" : "ACTIVE" %>" data-role="<%= u.getRoleId() %>">
                            <td><strong>#<%= u.getUserId() %></strong></td>
                            <td>
                                <div class="user-cell">
                                    <div class="user-avatar"><%= initial %></div>
                                    <div class="user-info-text">
                                        <span class="user-fullname"><%= Web.esc(u.getFullName()) %></span>
                                        <span class="user-loginname">@<%= Web.esc(u.getUsername()) %></span>
                                    </div>
                                </div>
                            </td>
                            <td>
                                <span class="role-badge <%= roleBadgeClass %>"><%= Web.esc(rCode) %></span>
                            </td>
                            <td>
                                <span class="status-pill <%= u.isLocked() ? "locked" : "active" %>">
                                    <span class="status-dot-small"></span>
                                    <span><%= u.isLocked() ? "Locked" : "Active" %></span>
                                </span>
                            </td>
                            <td>
                                <div class="actions-group" style="justify-content: flex-end; padding-right: 4px;">
                                    <button type="button" class="btn-act btn-act-blue"
                                            data-user-id="<%= u.getUserId() %>"
                                            data-username="<%= Web.esc(u.getUsername()) %>"
                                            data-fullname="<%= Web.esc(u.getFullName() != null ? u.getFullName() : "") %>"
                                            data-password="123456"
                                            data-role-id="<%= u.getRoleId() %>"
                                            data-role-name="<%= Web.esc(rName) %>"
                                            data-role-code="<%= Web.esc(rCode) %>"
                                            data-locked="<%= u.isLocked() %>"
                                            data-created-at="<%= createdStr %>"
                                            onclick="openUserDetailModal(this)">
                                        Detail
                                    </button>

                                    <% if (me != null && me.getUserId() != u.getUserId()) { %>
                                        <form method="post" action="<%= ctx %>/admin/users/delete" style="display:inline; margin:0;"
                                              onsubmit="return confirm('Delete user @<%= Web.esc(u.getUsername()) %> permanently?');">
                                            <input type="hidden" name="id" value="<%= u.getUserId() %>">
                                            <button type="submit" class="btn-act btn-act-red">Delete</button>
                                        </form>
                                    <% } else { %>
                                        <button type="button" class="btn-act btn-act-red" disabled style="opacity: 0.45; cursor: not-allowed;" title="Cannot delete current logged-in user">Delete</button>
                                    <% } %>
                                </div>
                            </td>
                        </tr>
                        <%  }
                           } else { %>
                        <tr>
                            <td colspan="5" class="empty-state">No users match the search filter</td>
                        </tr>
                        <% } %>
                    </tbody>
                </table>
            </div>

            <!-- Table Footer & Pagination -->
            <div class="table-footer">
                <span class="footer-text" id="userFooterCount" data-total="<%= total %>">Showing <%= rows != null ? rows.size() : 0 %> of <%= total %> users</span>
                <div class="pager-links">
                    <% for (int p = 1; p <= totalPages; p++) { %>
                        <% if (p == currentPage) { %>
                            <span class="page-num current"><%= p %></span>
                        <% } else { %>
                            <a class="page-num" href="?<%= qs %>&page=<%= p %>"><%= p %></a>
                        <% } %>
                    <% } %>
                </div>
            </div>
        </section>
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

        // Dynamic Clock Updater
        (function() {
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

        // =====================================================================
        // INSTANT REACTIVE FILTERING & STAT CARDS INTERACTION
        // =====================================================================
        let currentActiveStatus = '<%= (lockState != null) ? Web.esc(lockState) : "" %>';

        function filterByUserStatus(status) {
            const norm = (status || 'ALL').toUpperCase();

            // Toggle off back to ALL if clicking the already active status card
            if (currentActiveStatus.toUpperCase() === norm && norm !== 'ALL') {
                currentActiveStatus = '';
            } else if (norm === 'ALL') {
                currentActiveStatus = '';
            } else {
                currentActiveStatus = norm;
            }

            // 1. Synchronize dropdown
            const statusSelect = document.getElementById('userStatusSelect');
            if (statusSelect) {
                statusSelect.value = currentActiveStatus;
            }

            // 2. Update active highlight on stat cards
            updateStatCardsActive(currentActiveStatus);

            // 3. Check if rows exist in DOM for instant filtering
            const rows = Array.from(document.querySelectorAll('.users-table tbody tr:not(.empty-state-row)'));
            const hasStatusRows = currentActiveStatus === '' || rows.some(r => {
                const rs = (r.dataset.status || '').toUpperCase();
                return (rs === currentActiveStatus);
            });

            // If rows can be filtered in DOM or empty table, filter immediately with zero reload
            if (hasStatusRows || rows.length === 0) {
                try {
                    const url = new URL(window.location.href);
                    if (currentActiveStatus) {
                        url.searchParams.set('lockState', currentActiveStatus);
                    } else {
                        url.searchParams.delete('lockState');
                    }
                    window.history.replaceState({}, '', url.toString());
                } catch (e) {}

                applyTableFilters();
            } else {
                // If records are on other pages from server, submit form
                const form = document.getElementById('usersFilterForm');
                if (form) form.submit();
            }
        }

        function updateStatCardsActive(status) {
            const norm = (status || '').toUpperCase();
            const cards = document.querySelectorAll('.stats-cards-grid .stat-card');
            cards.forEach(c => c.classList.remove('active', 'active-blue', 'active-green', 'active-red'));

            if (!norm && cards[0]) {
                cards[0].classList.add('active', 'active-blue');
            } else if (norm === 'ACTIVE' && cards[1]) {
                cards[1].classList.add('active', 'active-green');
            } else if (norm === 'LOCKED' && cards[2]) {
                cards[2].classList.add('active', 'active-red');
            }
        }

        function applyTableFilters() {
            const tableBody = document.querySelector('.users-table tbody');
            if (!tableBody) return;

            const searchInput = document.getElementById('userSearchInput');
            const query = searchInput ? searchInput.value.trim().toLowerCase() : '';

            const roleSelect = document.getElementById('userRoleSelect');
            const selectedRole = roleSelect ? roleSelect.value : '';

            let emptyRow = tableBody.querySelector('.empty-state-row');
            if (!emptyRow) {
                emptyRow = document.createElement('tr');
                emptyRow.className = 'empty-state-row';
                emptyRow.style.display = 'none';
                emptyRow.innerHTML = `<td colspan="5" class="empty-state">No users match the current filter</td>`;
                tableBody.appendChild(emptyRow);
            }

            const rows = Array.from(tableBody.querySelectorAll('tr:not(.empty-state-row)'));
            let matched = 0;
            const totalRows = rows.length;

            rows.forEach(r => {
                const rowStatus = (r.dataset.status || '').toUpperCase();
                let statusMatch = true;
                if (currentActiveStatus) {
                    statusMatch = (rowStatus === currentActiveStatus);
                }

                const rowRole = r.dataset.role || '';
                let roleMatch = true;
                if (selectedRole) {
                    roleMatch = (rowRole === selectedRole);
                }

                const text = r.textContent.toLowerCase();
                let queryMatch = (!query || text.includes(query));

                if (statusMatch && roleMatch && queryMatch) {
                    r.style.display = '';
                    matched++;
                } else {
                    r.style.display = 'none';
                }
            });

            if (matched === 0 && (query.length > 0 || currentActiveStatus || selectedRole)) {
                emptyRow.style.display = '';
            } else {
                emptyRow.style.display = 'none';
            }

            const footerCount = document.getElementById('userFooterCount');
            if (footerCount) {
                const totalInDb = footerCount.getAttribute('data-total') || totalRows;
                if (currentActiveStatus || query.length > 0 || selectedRole) {
                    let statusLabel = currentActiveStatus ? (' • Filter: ' + currentActiveStatus) : '';
                    footerCount.textContent = 'Showing ' + matched + ' of ' + totalInDb + ' users' + statusLabel;
                } else {
                    footerCount.textContent = 'Showing ' + totalRows + ' of ' + totalInDb + ' users';
                }
            }
        }

        // Initialize listeners
        const userStatusSelect = document.getElementById('userStatusSelect');
        if (userStatusSelect) {
            userStatusSelect.addEventListener('change', () => {
                currentActiveStatus = userStatusSelect.value;
                updateStatCardsActive(currentActiveStatus);
                applyTableFilters();
                try {
                    const url = new URL(window.location.href);
                    if (currentActiveStatus) {
                        url.searchParams.set('lockState', currentActiveStatus);
                    } else {
                        url.searchParams.delete('lockState');
                    }
                    window.history.replaceState({}, '', url.toString());
                } catch (e) {}
            });
        }

        const userSearchInput = document.getElementById('userSearchInput');
        if (userSearchInput) {
            userSearchInput.addEventListener('input', applyTableFilters);
        }

        const userRoleSelect = document.getElementById('userRoleSelect');
        if (userRoleSelect) {
            userRoleSelect.addEventListener('change', applyTableFilters);
        }

        // =====================================================================
        // USER DETAIL MODAL HANDLERS
        // =====================================================================
        window.openUserDetailModal = function(btn) {
            if (!btn || !btn.dataset) return;
            const ds = btn.dataset;

            const modal = document.getElementById("userDetailModal");
            if (!modal) return;

            const userIdEl = document.getElementById("modalDetailUserId");
            const createdEl = document.getElementById("modalDetailCreatedAt");
            const usernameEl = document.getElementById("modalDetailUsername");
            const passEl = document.getElementById("modalDetailPassword");
            const fullNameEl = document.getElementById("modalDetailFullName");
            const roleIdEl = document.getElementById("modalDetailRoleId");
            const lockedSelect = document.getElementById("modalDetailLockedSelect");

            if (userIdEl) userIdEl.value = ds.userId || "0";
            if (createdEl) createdEl.value = ds.createdAt || "-";
            if (usernameEl) usernameEl.value = ds.username || "";
            if (passEl) {
                passEl.value = ds.password || "123456";
                passEl.type = "password";
            }

            const btnText = document.getElementById("togglePasswordText");
            const btnIcon = document.getElementById("togglePasswordIcon");
            if (btnText) btnText.textContent = "Show";
            if (btnIcon) {
                btnIcon.innerHTML = '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>';
            }

            if (fullNameEl) fullNameEl.value = ds.fullname || "";
            if (roleIdEl) roleIdEl.value = ds.roleId || "";

            const isLocked = String(ds.locked) === "true";
            if (lockedSelect) lockedSelect.value = isLocked ? "true" : "false";
            updateModalStatusPill(isLocked ? "true" : "false");

            modal.style.display = "flex";
        };

        window.closeUserDetailModal = function() {
            const modal = document.getElementById("userDetailModal");
            if (modal) modal.style.display = "none";
        };

        window.togglePasswordVisibility = function() {
            const passEl = document.getElementById("modalDetailPassword");
            const btnText = document.getElementById("togglePasswordText");
            const btnIcon = document.getElementById("togglePasswordIcon");
            if (!passEl) return;

            if (passEl.type === "password") {
                passEl.type = "text";
                if (btnText) btnText.textContent = "Hide";
                if (btnIcon) {
                    btnIcon.innerHTML = '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24"/><line x1="1" y1="1" x2="23" y2="23"/></svg>';
                }
            } else {
                passEl.type = "password";
                if (btnText) btnText.textContent = "Show";
                if (btnIcon) {
                    btnIcon.innerHTML = '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>';
                }
            }
        };

        window.updateModalStatusPill = function(val) {
            const pill = document.getElementById("modalDetailStatusPill");
            const text = document.getElementById("modalDetailStatusText");
            const isLocked = String(val) === "true";
            if (pill && text) {
                if (isLocked) {
                    pill.className = "status-pill locked";
                    text.textContent = "Locked";
                } else {
                    pill.className = "status-pill active";
                    text.textContent = "Active";
                }
            }
        };

        document.addEventListener("keydown", function(e) {
            if (e.key === "Escape") {
                closeUserDetailModal();
            }
        });
    </script>

    <!-- USER DETAIL MODAL POPUP -->
    <div id="userDetailModal" class="user-modal-backdrop" style="display: none;" onclick="if(event.target===this) closeUserDetailModal();">
        <div class="user-modal-card">
            <div class="user-modal-header">
                <div class="user-modal-title-group">
                    <div class="modal-icon-badge">
                        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                            <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/>
                            <circle cx="12" cy="7" r="4"/>
                        </svg>
                    </div>
                    <div>
                        <h3 class="modal-title">User Details</h3>
                        <p class="modal-subtitle">View account credentials, role permissions, and access status</p>
                    </div>
                </div>
                <button type="button" class="modal-close-btn" onclick="closeUserDetailModal()" title="Close">&times;</button>
            </div>

            <form method="post" action="<%= ctx %>/admin/users/save">
                <input type="hidden" name="userId" id="modalDetailUserId" value="">

                <div class="user-modal-body">
                    <!-- Row 1: Created At & Username -->
                    <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 14px;">
                        <div>
                            <label class="modal-field-label">Created At (Thời gian tạo)</label>
                            <input type="text" id="modalDetailCreatedAt" class="modal-form-input" readonly 
                                   style="background: #f8fafc; color: #475569; font-weight: 600; cursor: not-allowed;">
                        </div>
                        <div>
                            <label class="modal-field-label">Username</label>
                            <input type="text" name="username" id="modalDetailUsername" class="modal-form-input" readonly 
                                   style="background: #f8fafc; color: #0f172a; font-weight: 700; cursor: not-allowed;">
                        </div>
                    </div>

                    <!-- Row 2: Password with dots and show/hide button -->
                    <div>
                        <label class="modal-field-label">Password</label>
                        <div class="password-input-group">
                            <input type="password" id="modalDetailPassword" class="modal-form-input" readonly value="123456" 
                                   style="background: #f8fafc; color: #0f172a; font-size: 13.5px; font-weight: 500;">
                            <button type="button" id="btnTogglePassword" class="btn-toggle-password" onclick="togglePasswordVisibility()" title="Show/Hide password">
                                <span id="togglePasswordIcon" style="display: inline-flex; align-items: center;">
                                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                                        <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/>
                                        <circle cx="12" cy="12" r="3"/>
                                    </svg>
                                </span>
                                <span id="togglePasswordText">Show</span>
                            </button>
                        </div>
                    </div>

                    <!-- Row 3: Full Name & Role Name -->
                    <div style="display: grid; grid-template-columns: 1.1fr 0.9fr; gap: 14px;">
                        <div>
                            <label class="modal-field-label">Full Name</label>
                            <input type="text" name="fullName" id="modalDetailFullName" class="modal-form-input" required maxlength="100">
                        </div>
                        <div>
                            <label class="modal-field-label">Role Name</label>
                            <select name="roleId" id="modalDetailRoleId" class="modal-form-select">
                                <% if (roles != null) {
                                    for (AppRole r : roles) { %>
                                        <option value="<%= r.getRoleId() %>"><%= Web.esc(r.getRoleName()) %> (<%= Web.esc(r.getRoleCode()) %>)</option>
                                <%  }
                                   } %>
                            </select>
                        </div>
                    </div>

                    <!-- Row 4: Status & Option Lock/Unlock -->
                    <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 14px;">
                        <div>
                            <label class="modal-field-label">Current Status (Trạng thái)</label>
                            <div style="height: 38px; display: flex; align-items: center;">
                                <span class="status-pill active" id="modalDetailStatusPill">
                                    <span class="status-dot-small"></span>
                                    <span id="modalDetailStatusText">Active</span>
                                </span>
                            </div>
                        </div>
                        <div>
                            <label class="modal-field-label">Option Lock / Unlock</label>
                            <select name="locked" id="modalDetailLockedSelect" class="modal-form-select" onchange="updateModalStatusPill(this.value)">
                                <option value="false">Active (Unlocked)</option>
                                <option value="true">Locked</option>
                            </select>
                        </div>
                    </div>
                </div>

                <div class="user-modal-footer">
                    <button type="button" class="btn-modal-cancel" onclick="closeUserDetailModal()">Cancel</button>
                    <button type="submit" class="btn-modal-save">Save</button>
                </div>
            </form>
        </div>
    </div>
</body>
</html>
