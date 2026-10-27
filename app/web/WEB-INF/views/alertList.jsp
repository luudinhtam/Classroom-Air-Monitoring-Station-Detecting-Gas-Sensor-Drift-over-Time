<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.List, model.AirAlert, model.AppUser, util.Web" %>
<%
    AppUser me = (AppUser) session.getAttribute("user");
    String ctx = request.getContextPath();

    String userName = (me != null && me.getFullName() != null) ? me.getFullName() : "Tai khoan ADMIN";
    String userRole = (me != null && me.getRoleCode() != null) ? me.getRoleCode() : "ADMIN";
    boolean isAdmin = "ADMIN".equals(userRole);
    boolean canHandle = me != null && !"VIEWER".equals(userRole);

    List<AirAlert> alerts = (List<AirAlert>) request.getAttribute("alerts");

    Integer pageNoObj = (Integer) request.getAttribute("page");
    int pageNo = (pageNoObj != null) ? pageNoObj : 1;

    Integer totalPagesObj = (Integer) request.getAttribute("totalPages");
    int totalPages = (totalPagesObj != null) ? totalPagesObj : 1;

    Integer totalObj = (Integer) request.getAttribute("total");
    int total = (totalObj != null) ? totalObj : (alerts != null ? alerts.size() : 0);

    Integer sizeObj = (Integer) request.getAttribute("size");
    int size = (sizeObj != null) ? sizeObj : 5;

    String currentStatus = (String) request.getAttribute("currentStatus");
    String currentRuleCode = (String) request.getAttribute("currentRuleCode");
    String currentSeverity = (String) request.getAttribute("currentSeverity");
    Integer currentRoomId = (Integer) request.getAttribute("currentRoomId");
    @SuppressWarnings("unchecked")
    List<model.Room> roomList = (List<model.Room>) request.getAttribute("roomList");

    Integer openCountObj = (Integer) request.getAttribute("openCount");
    int openCount = (openCountObj != null) ? openCountObj : 0;

    Integer ackedCountObj = (Integer) request.getAttribute("ackedCount");
    int ackedCount = (ackedCountObj != null) ? ackedCountObj : 0;

    Integer rejectedCountObj = (Integer) request.getAttribute("rejectedCount");
    int rejectedCount = (rejectedCountObj != null) ? rejectedCountObj : 0;

    Integer allCountObj = (Integer) request.getAttribute("allCount");
    int allCount = (allCountObj != null) ? allCountObj : total;

    String flash = (String) session.getAttribute("flash");
    if (flash != null) session.removeAttribute("flash");

    String flashError = (String) session.getAttribute("flashError");
    if (flashError != null) session.removeAttribute("flashError");

    java.time.ZonedDateTime nowZdt = java.time.ZonedDateTime.now(java.time.ZoneId.of("Asia/Ho_Chi_Minh"));
    String jDateStr = nowZdt.format(java.time.format.DateTimeFormatter.ofPattern("EEEE, d MMMM yyyy", java.util.Locale.ENGLISH));
    String jTimeStr = nowZdt.format(java.time.format.DateTimeFormatter.ofPattern("HH:mm"));
    String jSidebarDateTime = nowZdt.format(java.time.format.DateTimeFormatter.ofPattern("EEEE, dd/MM/yyyy, HH:mm", java.util.Locale.ENGLISH));

    int startRecord = total > 0 ? ((pageNo - 1) * size + 1) : 0;
    int endRecord = Math.min(pageNo * size, total);

    String filterParams = (currentStatus != null ? "&status=" + Web.esc(currentStatus) : "")
                        + (currentRuleCode != null ? "&ruleCode=" + Web.esc(currentRuleCode) : "")
                        + (currentSeverity != null ? "&severity=" + Web.esc(currentSeverity) : "")
                        + (currentRoomId != null ? "&roomId=" + currentRoomId : "");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Alerts – Classroom Temp Monitoring System</title>
    <link rel="shortcut icon" href="<%= ctx %>/favicon.ico" type="image/x-icon">
    <!-- Google Fonts: Inter -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="<%= ctx %>/assets/css/users.css">
    <link rel="stylesheet" href="<%= ctx %>/assets/css/alertList.css?v=<%= System.currentTimeMillis() %>">

    <!-- Embedded Scoped Alert Styles (100% immune to browser cache delays) -->
    <style>
        /* 1. Quick Status Filter Tabs */
        .status-tabs {
            display: flex;
            gap: 8px;
            border-bottom: 2px solid #e3eaf5;
            padding-bottom: 0;
            overflow-x: auto;
            overflow-y: hidden;
            white-space: nowrap;
            margin-bottom: 2px;
            width: 100%;
            scrollbar-width: none;
            -ms-overflow-style: none;
        }

        .status-tabs::-webkit-scrollbar {
            display: none;
            width: 0;
            height: 0;
        }

        .status-tab-btn {
            padding: 9px 16px;
            font-size: 13px;
            font-weight: 600;
            color: #64748b;
            text-decoration: none;
            border-radius: 8px 8px 0 0;
            border-bottom: 2px solid transparent;
            display: inline-flex;
            align-items: center;
            gap: 8px;
            transition: all 0.15s ease;
            margin-bottom: -2px;
            flex-shrink: 0;
        }

        .status-tab-btn:hover {
            color: #2563eb;
            background: #ffffff;
        }

        .status-tab-btn.active {
            color: #2563eb;
            border-bottom: 2px solid #2563eb;
            background: #ffffff;
        }

        .status-tab-btn .tab-count {
            font-size: 11px;
            padding: 2px 7px;
            border-radius: 12px;
            background: #e2e8f0;
            color: #475569;
            font-weight: 700;
        }

        .status-tab-btn.active .tab-count {
            background: #dbeafe;
            color: #2563eb;
        }

        .status-tab-btn.tab-open .tab-count {
            background: #fef3c7;
            color: #92400e;
        }

        .status-tab-btn.tab-acked .tab-count {
            background: #dcfce7;
            color: #166534;
        }

        .status-tab-btn.tab-rejected .tab-count {
            background: #fee2e2;
            color: #991b1b;
        }

        /* 2. Stats Cards: Always 1 row (4 columns) & Hover Effects */
        .stats-cards-grid {
            display: grid !important;
            grid-template-columns: repeat(4, minmax(0, 1fr)) !important;
            gap: 16px !important;
            width: 100% !important;
            box-sizing: border-box !important;
        }

        .stat-card {
            min-width: 0 !important;
            padding: 16px 18px !important;
            gap: 12px !important;
            transition: transform 0.22s cubic-bezier(0.4, 0, 0.2, 1), 
                        box-shadow 0.22s cubic-bezier(0.4, 0, 0.2, 1), 
                        border-color 0.22s ease !important;
            cursor: pointer;
            position: relative;
        }

        .stat-card .stat-info {
            min-width: 0;
            overflow: hidden;
        }

        .stat-card .stat-label,
        .stat-card .stat-subtext {
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        }

        .stat-card:hover {
            transform: translateY(-4px) !important;
            box-shadow: 0 10px 20px -3px rgba(15, 27, 61, 0.08), 0 4px 6px -2px rgba(15, 27, 61, 0.04) !important;
            border-color: #cbd5e1 !important;
        }

        .stat-card:hover .stat-icon-wrapper {
            transform: scale(1.08);
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
        .stat-card.active-amber {
            border: 2px solid #d97706 !important;
            background: #fffdf5 !important;
            box-shadow: 0 0 0 3px rgba(217, 119, 6, 0.12) !important;
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

        .stat-icon-wrapper {
            transition: transform 0.22s ease;
        }

        .stat-icon-wrapper.amber {
            background: #fffbeb !important;
            color: #d97706 !important;
        }

        /* Instant quick search clear button */
        .btn-clear-quick-search {
            position: absolute;
            right: 10px;
            top: 50%;
            transform: translateY(-50%);
            background: #e2e8f0;
            border: none;
            color: #64748b;
            width: 20px;
            height: 20px;
            border-radius: 50%;
            cursor: pointer;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            font-size: 14px;
            line-height: 1;
            padding: 0;
            transition: all 0.15s ease;
        }
        .btn-clear-quick-search:hover {
            background: #cbd5e1;
            color: #0f172a;
        }

        /* 3. Table Card & Alerts Table */
        .table-card {
            background: #ffffff;
            border: 1px solid #e3eaf5;
            border-radius: 10px;
            box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.03);
            overflow: hidden;
            display: flex;
            flex-direction: column;
            width: 100%;
        }

        .table-responsive {
            width: 100%;
            overflow-x: auto;
        }

        .alerts-table {
            width: 100%;
            border-collapse: collapse;
            text-align: left;
        }

        .alerts-table thead tr {
            height: 44px;
            background: #f8fafc;
            border-bottom: 1px solid #e3eaf5;
        }

        .alerts-table th {
            padding: 0 16px;
            font-size: 12.5px;
            font-weight: 600;
            color: #475569;
            white-space: nowrap;
        }

        .alerts-table td {
            padding: 13px 16px;
            border-bottom: 1px solid #f1f5f9;
            font-size: 13px;
            color: #0f1b3d;
            vertical-align: middle;
        }

        .alerts-table tbody tr {
            transition: background 0.12s ease;
        }

        .alerts-table tbody tr:hover {
            background: #f8fbff;
        }

        .alerts-table tbody tr.row-rejected {
            opacity: 0.75;
            background: #fafbfc;
        }

        .alert-id-tag {
            font-weight: 700;
            color: #2563eb;
            font-size: 13px;
        }

        .stt-badge {
            font-weight: 700;
            color: #64748b;
            font-size: 13px;
        }

        .alert-code-pill {
            display: inline-block;
            padding: 3px 9px;
            font-size: 11px;
            font-weight: 700;
            border-radius: 6px;
            background: #eff6ff;
            color: #1d4ed8;
            border: 1px solid #bfdbfe;
            letter-spacing: 0.3px;
            white-space: nowrap;
        }

        .alert-type-badge {
            display: inline-flex;
            align-items: center;
            gap: 5px;
            padding: 3px 9px;
            font-size: 11.5px;
            font-weight: 700;
            border-radius: 6px;
            letter-spacing: 0.3px;
            white-space: nowrap;
            border: 1px solid #e2e8f0;
            background: #f8fafc;
            color: #334155;
        }
        .alert-type-badge.type-temp {
            background: #fff7ed;
            color: #c2410c;
            border-color: #fed7aa;
        }
        .alert-type-badge.type-humid {
            background: #ecfeff;
            color: #0e7490;
            border-color: #a5f3fc;
        }
        .alert-type-badge.type-co2 {
            background: #f5f3ff;
            color: #6d28d9;
            border-color: #ddd6fe;
        }
        .alert-type-badge.type-co {
            background: #fff1f2;
            color: #be123c;
            border-color: #fecdd3;
        }

        .room-code-tag {
            display: inline-flex;
            align-items: center;
            gap: 5px;
            padding: 3px 8px;
            background: #f8fafc;
            border: 1px solid #cbd5e1;
            border-radius: 6px;
            font-size: 12px;
            font-weight: 600;
            color: #1e293b;
            text-decoration: none;
            white-space: nowrap;
            transition: all 0.15s ease;
        }
        .room-code-tag:hover {
            background: #eff6ff;
            border-color: #93c5fd;
            color: #2563eb;
        }

        .cell-user-wrapper {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            font-size: 13px;
            font-weight: 600;
            color: #0f1b3d;
        }

        .cell-time-wrapper {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            font-size: 12.5px;
            color: #64748b;
            white-space: nowrap;
        }

        .alert-note-text {
            font-size: 12.5px;
            color: #64748b;
            line-height: 1.4;
            display: inline-block;
            max-width: 220px;
            word-break: break-word;
        }

        /* 4. Severity Pills */
        .severity-pill {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            padding: 3px 10px;
            border-radius: 20px;
            font-size: 11.5px;
            font-weight: 700;
            letter-spacing: 0.3px;
            white-space: nowrap;
        }

        .severity-pill .dot {
            width: 6px;
            height: 6px;
            border-radius: 50%;
        }

        .severity-pill.critical {
            background: #fee2e2;
            color: #b91c1c;
        }
        .severity-pill.critical .dot {
            background: #ef4444;
        }

        .severity-pill.warn {
            background: #fef3c7;
            color: #b45309;
        }
        .severity-pill.warn .dot {
            background: #f59e0b;
        }

        .severity-pill.info {
            background: #dbeafe;
            color: #1d4ed8;
        }
        .severity-pill.info .dot {
            background: #3b82f6;
        }

        /* 5. Rule Tags */
        .rule-tag {
            display: inline-block;
            padding: 3px 8px;
            border-radius: 6px;
            font-size: 11.5px;
            font-weight: 600;
            font-family: monospace;
        }

        .rule-tag.rule-high { background: #fee2e2; color: #991b1b; }
        .rule-tag.rule-temp { background: #ffedd5; color: #c2410c; }
        .rule-tag.rule-drift { background: #f3e8ff; color: #7e22ce; }
        .rule-tag.rule-warmup { background: #e0f2fe; color: #0369a1; }

        /* 6. Device Badge & Session Link */
        .device-badge {
            display: inline-flex;
            align-items: center;
            gap: 5px;
            padding: 3px 8px;
            background: #f1f5f9;
            border: 1px solid #e2e8f0;
            border-radius: 6px;
            font-family: monospace;
            font-size: 12px;
            font-weight: 600;
            color: #334155;
            white-space: nowrap;
        }

        .session-link {
            display: inline-flex;
            align-items: center;
            gap: 3px;
            margin-top: 3px;
            font-size: 11.5px;
            color: #2563eb;
            text-decoration: none;
            font-weight: 600;
            white-space: nowrap;
        }
        .session-link:hover {
            text-decoration: underline;
        }

        .alert-message-text {
            font-size: 13px;
            font-weight: 500;
            color: #0f1b3d;
            line-height: 1.45;
            max-width: 280px;
            word-break: break-word;
            display: inline-block;
        }

        /* 7. Status Pill */
        .alert-status-pill {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            padding: 3px 10px;
            border-radius: 20px;
            font-size: 11.5px;
            font-weight: 600;
            white-space: nowrap;
        }

        .alert-status-pill .status-dot {
            width: 6px;
            height: 6px;
            border-radius: 50%;
        }

        .alert-status-pill.open { background: #fef3c7; color: #92400e; }
        .alert-status-pill.open .status-dot { background: #d97706; }

        .alert-status-pill.acked { background: #dcfce7; color: #166534; }
        .alert-status-pill.acked .status-dot { background: #16a34a; }

        .alert-status-pill.rejected { background: #fee2e2; color: #991b1b; }
        .alert-status-pill.rejected .status-dot { background: #dc2626; }

        .handler-box {
            display: flex;
            flex-direction: column;
            gap: 2px;
        }

        .handler-name {
            font-size: 12px;
            font-weight: 600;
            color: #0f1b3d;
            white-space: nowrap;
        }

        .handler-note {
            font-size: 11px;
            color: #64748b;
            font-style: italic;
            max-width: 170px;
            word-break: break-word;
        }

        /* 8. Action Buttons */
        .action-buttons-group {
            display: flex;
            align-items: center;
            gap: 6px;
            white-space: nowrap;
        }

        .btn-approve {
            background: #16a34a;
            color: #ffffff;
            border: 1px solid #16a34a;
            border-radius: 6px;
            padding: 5px 10px;
            font-size: 12px;
            font-weight: 600;
            cursor: pointer;
            display: inline-flex;
            align-items: center;
            gap: 4px;
            transition: all 0.15s ease;
        }
        .btn-approve:hover { background: #15803d; }

        .btn-reject {
            background: #ffffff;
            color: #dc2626;
            border: 1px solid #fecaca;
            border-radius: 6px;
            padding: 5px 10px;
            font-size: 12px;
            font-weight: 600;
            cursor: pointer;
            display: inline-flex;
            align-items: center;
            gap: 4px;
            transition: all 0.15s ease;
        }
        .btn-reject:hover { background: #fee2e2; border-color: #fca5a5; }

        .btn-detail {
            background: #eff6ff;
            color: #2563eb;
            border: 1px solid #bfdbfe;
            border-radius: 6px;
            padding: 5px 12px;
            font-size: 12px;
            font-weight: 600;
            cursor: pointer;
            display: inline-flex;
            align-items: center;
            gap: 5px;
            transition: all 0.15s ease;
            white-space: nowrap;
        }
        .btn-detail:hover {
            background: #2563eb;
            color: #ffffff;
            border-color: #2563eb;
            box-shadow: 0 2px 4px rgba(37, 99, 235, 0.2);
        }

        /* 9. Modal Overlay & Dialog */
        .modal-overlay {
            position: fixed !important;
            top: 0 !important;
            left: 0 !important;
            width: 100vw !important;
            height: 100vh !important;
            background: rgba(15, 27, 61, 0.5) !important;
            backdrop-filter: blur(4px) !important;
            align-items: center !important;
            justify-content: center !important;
            z-index: 9999 !important;
        }

        .modal-dialog {
            background: #ffffff !important;
            width: 460px !important;
            max-width: 90vw !important;
            border-radius: 14px !important;
            box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.15) !important;
            overflow: hidden !important;
        }

        .modal-dialog-detail {
            width: 580px !important;
            max-width: 95vw !important;
            max-height: 90vh !important;
            display: flex;
            flex-direction: column;
        }

        .modal-dialog-detail form {
            display: flex;
            flex-direction: column;
            overflow: hidden;
            flex: 1;
            margin: 0;
        }

        .detail-modal-body {
            overflow-y: auto;
            max-height: calc(90vh - 140px);
            padding: 18px 22px;
            display: flex;
            flex-direction: column;
            gap: 14px;
        }

        /* Detail Grid */
        .detail-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 10px 14px;
            background: #f8fafc;
            border: 1px solid #e2e8f0;
            border-radius: 10px;
            padding: 12px 16px;
        }

        .detail-item {
            display: flex;
            flex-direction: column;
            gap: 4px;
        }

        .detail-item.span-2 {
            grid-column: span 2;
        }

        .detail-item-label {
            font-size: 11px;
            font-weight: 700;
            color: #64748b;
            text-transform: uppercase;
            letter-spacing: 0.3px;
        }

        .detail-item-val {
            font-size: 13.5px;
            color: #0f1b3d;
        }

        .modal-message-box {
            background: #ffffff;
            border: 1px solid #e2e8f0;
            border-radius: 6px;
            padding: 9px 12px;
            font-size: 13px;
            color: #0f1b3d;
            line-height: 1.45;
            word-break: break-word;
        }

        .modal-handler-box {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            background: #ffffff;
            border: 1px solid #cbd5e1;
            border-radius: 6px;
            padding: 7px 12px;
            font-size: 13px;
            color: #0f1b3d;
            font-weight: 600;
        }

        .handler-user-badge {
            font-size: 11px;
            background: #dbeafe;
            color: #1d4ed8;
            padding: 2px 8px;
            border-radius: 12px;
            font-weight: 600;
        }

        /* Modal Action Status Options */
        .modal-section-title {
            font-size: 11.5px;
            font-weight: 700;
            color: #475569;
            text-transform: uppercase;
            letter-spacing: 0.4px;
            margin-top: 2px;
        }

        .status-choice-group {
            display: flex;
            gap: 12px;
        }

        .status-choice-card {
            flex: 1;
            border: 2px solid #e2e8f0;
            border-radius: 10px;
            padding: 10px 14px;
            cursor: pointer;
            transition: all 0.15s ease;
            background: #ffffff;
            display: flex;
            align-items: center;
            position: relative;
        }

        .status-choice-card input[type="radio"] {
            position: absolute;
            opacity: 0;
            pointer-events: none;
        }

        .status-choice-card.selected.approve-card {
            border-color: #16a34a;
            background: #f0fdf4;
            box-shadow: 0 0 0 1px #16a34a;
        }

        .status-choice-card.selected.reject-card {
            border-color: #dc2626;
            background: #fef2f2;
            box-shadow: 0 0 0 1px #dc2626;
        }

        .choice-content {
            display: flex;
            align-items: center;
            gap: 10px;
            width: 100%;
        }

        .choice-icon-wrap {
            width: 28px;
            height: 28px;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            flex-shrink: 0;
        }

        .choice-icon-wrap.approve-icon {
            background: #dcfce7;
            color: #15803d;
        }

        .choice-icon-wrap.reject-icon {
            background: #fee2e2;
            color: #b91c1c;
        }

        .choice-label {
            font-size: 13px;
            font-weight: 700;
            color: #0f1b3d;
        }

        .choice-hint {
            font-size: 11px;
            color: #64748b;
        }

        .btn-modal-save {
            background: #2563eb;
            color: #ffffff;
            border: none;
            border-radius: 6px;
            padding: 8px 18px;
            font-size: 13px;
            font-weight: 600;
            cursor: pointer;
            display: inline-flex;
            align-items: center;
            gap: 6px;
            transition: background 0.15s ease;
        }
        .btn-modal-save:hover {
            background: #1d4ed8;
        }

        .modal-header {
            padding: 16px 20px;
            border-bottom: 1px solid #f1f5f9;
            display: flex;
            align-items: center;
            justify-content: space-between;
        }

        .modal-title-group {
            display: flex;
            align-items: center;
            gap: 10px;
        }

        .modal-icon-badge {
            width: 32px;
            height: 32px;
            border-radius: 8px;
            background: #fee2e2;
            color: #dc2626;
            display: flex;
            align-items: center;
            justify-content: center;
        }

        .modal-icon-badge.blue {
            background: #eff6ff;
            color: #2563eb;
        }

        .modal-title {
            font-size: 15px;
            font-weight: 700;
            color: #0f1b3d;
        }

        .modal-close-btn {
            background: transparent;
            border: none;
            color: #64748b;
            cursor: pointer;
            padding: 4px;
            border-radius: 6px;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .modal-close-btn:hover { background: #f1f5f9; color: #0f1b3d; }

        .modal-body {
            padding: 18px 20px;
            display: flex;
            flex-direction: column;
            gap: 14px;
        }

        .modal-body label {
            font-size: 13px;
            font-weight: 600;
            color: #475569;
        }

        .quick-reason-pills {
            display: flex;
            flex-wrap: wrap;
            gap: 6px;
        }

        .reason-chip {
            padding: 5px 11px;
            border-radius: 20px;
            border: 1px solid #e2e8f0;
            background: #f8fafc;
            font-size: 12px;
            color: #475569;
            cursor: pointer;
            transition: all 0.15s ease;
        }
        .reason-chip:hover {
            background: #eff6ff;
            color: #2563eb;
            border-color: #bfdbfe;
        }

        .modal-textarea {
            width: 100%;
            min-height: 85px;
            padding: 10px 12px;
            border: 1px solid #cbd5e1;
            border-radius: 8px;
            font-family: inherit;
            font-size: 13px;
            color: #0f1b3d;
            resize: vertical;
            outline: none;
            box-sizing: border-box;
        }
        .modal-textarea:focus { border-color: #2563eb; }

        .modal-footer {
            padding: 14px 20px;
            background: #f8fafc;
            border-top: 1px solid #f1f5f9;
            display: flex;
            align-items: center;
            justify-content: flex-end;
            gap: 8px;
        }

        .btn-modal-cancel {
            padding: 7px 14px;
            border: 1px solid #cbd5e1;
            background: #ffffff;
            border-radius: 6px;
            font-size: 13px;
            font-weight: 500;
            cursor: pointer;
        }
        .btn-modal-cancel:hover { background: #e2e8f0; }

        .btn-modal-confirm {
            padding: 7px 16px;
            border: none;
            background: #dc2626;
            color: #ffffff;
            border-radius: 6px;
            font-size: 13px;
            font-weight: 600;
            cursor: pointer;
            display: inline-flex;
            align-items: center;
            gap: 6px;
        }
        .btn-modal-confirm:hover { background: #b91c1c; }

        .page-jump-input {
            width: 48px;
            height: 30px;
            padding: 0 6px;
            border: 1px solid #cbd5e1;
            border-radius: 6px;
            font-size: 12px;
            text-align: center;
            outline: none;
        }
        .page-jump-input:focus { border-color: #2563eb; }

        .page-jump-btn {
            height: 30px;
            padding: 0 10px;
            border: 1px solid #cbd5e1;
            background: #f8fafc;
            border-radius: 6px;
            font-size: 12px;
            font-weight: 600;
            cursor: pointer;
        }
        .page-jump-btn:hover { background: #e2e8f0; }
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

            <!-- ACTIVE ITEM: Alerts -->
            <a href="<%= ctx %>/alerts" class="menu-item active" title="Alerts">
                <svg class="menu-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/>
                    <path d="M13.73 21a2 2 0 0 1-3.46 0"/>
                </svg>
                <span>Alerts</span>
                <span class="sidebar-badge" id="sidebarAlertBadge"><%= openCount %></span>
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
                    <span class="breadcrumb-item breadcrumb-current">Alerts</span>
                </nav>
            </div>

            <!-- Right: Notifications & User Profile -->
            <div class="top-bar-right">
                <a href="<%= ctx %>/alerts" class="icon-btn-round" title="Notifications">
                    <svg width="19" height="19" viewBox="0 0 24 24" fill="none" stroke="#4b5563" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/>
                        <path d="M13.73 21a2 2 0 0 1-3.46 0"/>
                    </svg>
                    <% if (openCount > 0) { %>
                    <span class="notif-badge" id="topBellBadge"><%= openCount %></span>
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
                        <div class="user-dropdown-header">Role: <%= Web.esc(userRole) %></div>
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

        <!-- Flash Alert Messages -->
        <% if (flash != null && !flash.isEmpty()) { %>
        <div class="flash-message success">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path><polyline points="22 4 12 14.01 9 11.01"></polyline></svg>
            <span><%= Web.esc(flash) %></span>
        </div>
        <% } %>

        <% if (flashError != null && !flashError.isEmpty()) { %>
        <div class="flash-message error">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"></circle><line x1="12" y1="8" x2="12" y2="12"></line><line x1="12" y1="16" x2="12.01" y2="16"></line></svg>
            <span><%= Web.esc(flashError) %></span>
        </div>
        <% } %>

        <!-- 3. PAGE TITLE SECTION -->
        <section class="page-title-section">
            <div class="title-left-group">
                <div class="title-icon-box" style="background: #f59e0b;">
                    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#ffffff" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/>
                        <path d="M13.73 21a2 2 0 0 1-3.46 0"/>
                    </svg>
                </div>
                <div class="title-text-group">
                    <h1 class="page-main-heading">Alerts</h1>
                    <p class="page-subheading">Classroom Air Monitoring System &ndash; Real-time anomaly & drift logs</p>
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

        <!-- 4. FOUR STATS CARDS (Always on 1 row) -->
        <section class="stats-cards-grid" style="grid-template-columns: repeat(4, minmax(0, 1fr)) !important;">
            <!-- 1. Total Alerts -->
            <div class="stat-card <%= (currentStatus == null || currentStatus.isEmpty()) ? "active active-blue" : "" %>" onclick="filterByStatus('')" title="Lọc tất cả cảnh báo">
                <div class="stat-icon-wrapper blue">
                    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M22 12h-4l-3 9L9 3l-3 9H2"/>
                    </svg>
                </div>
                <div class="stat-info">
                    <span class="stat-label">Total Alerts</span>
                    <div class="stat-value-row">
                        <span class="stat-value"><%= allCount %></span>
                    </div>
                    <span class="stat-subtext">Logged incident records</span>
                </div>
            </div>

            <!-- 2. Open Pending Alerts -->
            <div class="stat-card <%= "OPENING".equals(currentStatus) ? "active active-amber" : "" %>" onclick="filterByStatus('OPENING')" title="Lọc cảnh báo đang mở (Pending)">
                <div class="stat-icon-wrapper amber">
                    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/>
                        <line x1="12" y1="9" x2="12" y2="13"/>
                        <line x1="12" y1="17" x2="12.01" y2="17"/>
                    </svg>
                </div>
                <div class="stat-info">
                    <span class="stat-label">Open Pending</span>
                    <div class="stat-value-row">
                        <span class="stat-value" style="color: #d97706;"><%= openCount %></span>
                    </div>
                    <span class="stat-subtext">Awaiting operator review</span>
                </div>
            </div>

            <!-- 3. Approved Alerts -->
            <div class="stat-card <%= "APPROVED".equals(currentStatus) ? "active active-green" : "" %>" onclick="filterByStatus('APPROVED')" title="Lọc cảnh báo đã Approved">
                <div class="stat-icon-wrapper green">
                    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/>
                        <polyline points="22 4 12 14.01 9 11.01"/>
                    </svg>
                </div>
                <div class="stat-info">
                    <span class="stat-label">Approved (Acked)</span>
                    <div class="stat-value-row">
                        <span class="stat-value" style="color: #16a34a;"><%= ackedCount %></span>
                    </div>
                    <span class="stat-subtext">Confirmed real incidents</span>
                </div>
            </div>

            <!-- 4. Rejected Alerts -->
            <div class="stat-card <%= "REJECTED".equals(currentStatus) ? "active active-red" : "" %>" onclick="filterByStatus('REJECTED')" title="Lọc cảnh báo đã Rejected">
                <div class="stat-icon-wrapper red">
                    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                        <circle cx="12" cy="12" r="10"/>
                        <line x1="15" y1="9" x2="9" y2="15"/>
                        <line x1="9" y1="9" x2="15" y2="15"/>
                    </svg>
                </div>
                <div class="stat-info">
                    <span class="stat-label">Rejected</span>
                    <div class="stat-value-row">
                        <span class="stat-value" style="color: #ef4444;"><%= rejectedCount %></span>
                    </div>
                    <span class="stat-subtext">Filtered false alarms</span>
                </div>
            </div>
        </section>

        <!-- 5. STATUS TABS & FILTER BAR -->
        <%
            String filterPreservedParams = "";
            if (currentRoomId != null && currentRoomId > 0) filterPreservedParams += "&roomId=" + currentRoomId;
            if (currentRuleCode != null && !currentRuleCode.isEmpty()) filterPreservedParams += "&ruleCode=" + Web.esc(currentRuleCode);
        %>
        <div class="status-tabs">
            <a href="<%= ctx %>/alerts<%= filterPreservedParams.startsWith("&") ? "?" + filterPreservedParams.substring(1) : filterPreservedParams %>" onclick="filterByStatus(''); return false;" class="status-tab-btn <%= (currentStatus == null || currentStatus.isEmpty()) ? "active" : "" %>">
                <span>All Alerts</span>
                <span class="tab-count"><%= allCount %></span>
            </a>
            <a href="<%= ctx %>/alerts?status=OPENING<%= filterPreservedParams %>" onclick="filterByStatus('OPENING'); return false;" class="status-tab-btn tab-open <%= "OPENING".equals(currentStatus) ? "active" : "" %>">
                <span>Opening</span>
                <span class="tab-count"><%= openCount %></span>
            </a>
            <a href="<%= ctx %>/alerts?status=APPROVED<%= filterPreservedParams %>" onclick="filterByStatus('APPROVED'); return false;" class="status-tab-btn tab-acked <%= "APPROVED".equals(currentStatus) ? "active" : "" %>">
                <span>Approved</span>
                <span class="tab-count"><%= ackedCount %></span>
            </a>
            <a href="<%= ctx %>/alerts?status=REJECTED<%= filterPreservedParams %>" onclick="filterByStatus('REJECTED'); return false;" class="status-tab-btn tab-rejected <%= "REJECTED".equals(currentStatus) ? "active" : "" %>">
                <span>Rejected</span>
                <span class="tab-count"><%= rejectedCount %></span>
            </a>
        </div>

        <section class="filter-card">
            <form id="alertsFilterForm" class="filter-form" method="get" action="<%= ctx %>/alerts">
                <input type="hidden" name="status" id="filterStatusInput" value="<%= currentStatus != null ? Web.esc(currentStatus) : "" %>">

                <!-- Instant Real-Time Quick Search Input -->
                <div class="search-input-group" style="position: relative; flex: 1; min-width: 240px; max-width: 380px;">
                    <svg class="search-icon" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                        <circle cx="11" cy="11" r="8"/>
                        <line x1="21" y1="21" x2="16.65" y2="16.65"/>
                    </svg>
                    <input type="text" id="tableQuickSearch" class="search-field" placeholder="Lọc nhanh mã, phòng, nội dung, thời gian..." autocomplete="off">
                    <button type="button" id="clearQuickSearch" class="btn-clear-quick-search" title="Xóa tìm kiếm" style="display:none;">&times;</button>
                </div>

                <!-- Classroom Filter (Auto-submits immediately on change) -->
                <select class="filter-select" name="roomId" id="selectRoomFilter" onchange="this.form.submit()" title="Chọn phòng để lọc ngay lập tức">
                    <option value="">-- All Classrooms --</option>
                    <% if (roomList != null) {
                        for (model.Room r : roomList) { %>
                            <option value="<%= r.getRoomId() %>" <%= (currentRoomId != null && currentRoomId == r.getRoomId()) ? "selected" : "" %>>
                                <%= Web.esc(r.getCode()) %> - <%= Web.esc(r.getName()) %>
                            </option>
                    <%  }
                    } %>
                </select>

                <!-- Alert Code Filter (Auto-submits immediately on change) -->
                <select class="filter-select" name="ruleCode" id="selectRuleFilter" onchange="this.form.submit()" title="Chọn mã cảnh báo để lọc ngay lập tức">
                    <option value="">-- All Types --</option>
                    <option value="TEMPERATURE" <%= "TEMPERATURE".equals(currentRuleCode) ? "selected" : "" %>>TEMPERATURE (Nhiệt độ)</option>
                    <option value="HUMID" <%= "HUMID".equals(currentRuleCode) ? "selected" : "" %>>HUMID (Độ ẩm)</option>
                    <option value="CO2" <%= "CO2".equals(currentRuleCode) ? "selected" : "" %>>CO2 (Khí CO₂)</option>
                    <option value="CO" <%= "CO".equals(currentRuleCode) ? "selected" : "" %>>CO (Khí CO)</option>
                </select>

                <button type="submit" class="btn-filter">Filter</button>
                <a class="btn-reset" href="<%= ctx %>/alerts">Reset All</a>
            </form>
        </section>

        <!-- 6. ALERTS TABLE CARD -->
        <section class="table-card">
            <div class="table-responsive">
                <table class="alerts-table">
                    <thead>
                        <tr>
                            <th style="width: 60px; text-align: center;">STT</th>
                            <th style="width: 120px;">Alert Code</th>
                            <th style="width: 130px;">Type</th>
                            <th style="width: 120px;">Room Code</th>
                            <th>Message</th>
                            <th style="width: 120px;">Status</th>
                            <th style="width: 165px;">Thời gian</th>
                            <th style="width: 110px; text-align: center;">Detail</th>
                        </tr>
                    </thead>
                    <tbody>
                        <% if (alerts != null && !alerts.isEmpty()) {
                            int idx = 0;
                            for (AirAlert a : alerts) {
                                int stt = (pageNo - 1) * size + (++idx);
                                String code = a.getAlertCode() != null ? a.getAlertCode() : "–";
                                String alertType = a.getAlertType() != null ? a.getAlertType() : "–";
                                String typeBadgeClass = "type-default";
                                String typeUpper = alertType.toUpperCase();
                                if (typeUpper.contains("TEMP")) typeBadgeClass = "type-temp";
                                else if (typeUpper.contains("HUMID")) typeBadgeClass = "type-humid";
                                else if (typeUpper.contains("CO2")) typeBadgeClass = "type-co2";
                                else if (typeUpper.equals("CO")) typeBadgeClass = "type-co";
                                String roomCode = a.getRoomCode();
                                Integer roomId = a.getRoomId();
                                String msg = a.getMessage() != null ? a.getMessage() : "–";
                                String st = a.getStatus() != null ? a.getStatus().toUpperCase() : "OPENING";
                                boolean isRowRejected = "REJECTED".equals(st);
                                String statusPillClass = "open";
                                String statusLabel = "OPENING";
                                if ("APPROVED".equals(st) || "ACKED".equals(st)) {
                                    statusPillClass = "acked";
                                    statusLabel = "APPROVED";
                                } else if ("REJECTED".equals(st)) {
                                    statusPillClass = "rejected";
                                    statusLabel = "REJECTED";
                                }
                                String handledByName = (a.getHandledByName() != null && !a.getHandledByName().trim().isEmpty())
                                        ? a.getHandledByName()
                                        : (a.getHandledBy() != null ? ("User #" + a.getHandledBy()) : "–");
                                String note = (a.getNote() != null && !a.getNote().trim().isEmpty()) ? a.getNote() : "";
                                String alTime = a.getCreatedAt() != null ? a.getCreatedAt().toString() : "–";
                        %>
                        <tr class="<%= isRowRejected ? "row-rejected" : "" %>" data-status="<%= statusLabel %>">
                            <td style="text-align: center;">
                                <span class="stt-badge"><%= stt %></span>
                            </td>
                            <td>
                                <span class="alert-code-pill"><%= Web.esc(code) %></span>
                            </td>
                            <td>
                                <span class="alert-type-badge <%= typeBadgeClass %>">
                                    <%= Web.esc(alertType) %>
                                </span>
                            </td>
                            <td>
                                <% if (roomCode != null && !roomCode.trim().isEmpty()) { %>
                                    <a href="<%= ctx %>/admin/rooms/detail?id=<%= roomId != null ? roomId : "" %>" class="room-code-tag" title="View Room Detail">
                                        <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"></path></svg>
                                        <span><%= Web.esc(roomCode) %></span>
                                    </a>
                                <% } else { %>
                                    <span style="color: #94a3b8;">–</span>
                                <% } %>
                            </td>
                            <td>
                                <span class="alert-message-text"><%= Web.esc(msg) %></span>
                            </td>
                            <td>
                                <span class="alert-status-pill <%= statusPillClass %>">
                                    <span class="status-dot"></span>
                                    <%= statusLabel %>
                                </span>
                            </td>
                            <td style="color: #64748b; font-size: 12.5px; white-space: nowrap;">
                                <div class="cell-time-wrapper">
                                    <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" stroke-width="2">
                                        <circle cx="12" cy="12" r="10"/>
                                        <polyline points="12 6 12 12 16 14"/>
                                    </svg>
                                    <span><%= Web.esc(alTime) %></span>
                                </div>
                            </td>
                            <td style="text-align: center;">
                                <button type="button" class="btn-detail"
                                        data-stt="<%= stt %>"
                                        data-alert-id="<%= a.getAlertId() %>"
                                        data-alert-code="<%= Web.esc(code) %>"
                                        data-type="<%= Web.esc(alertType) %>"
                                        data-room-code="<%= Web.esc(roomCode != null ? roomCode : "–") %>"
                                        data-message="<%= Web.esc(msg) %>"
                                        data-status="<%= statusLabel %>"
                                        data-handled-by="<%= Web.esc(handledByName) %>"
                                        data-note="<%= Web.esc(note) %>"
                                        data-time="<%= Web.esc(alTime) %>"
                                        onclick="openDetailModal(this)"
                                        title="View alert details">
                                    <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2">
                                        <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"></path>
                                        <circle cx="12" cy="12" r="3"></circle>
                                    </svg>
                                    <span>Detail</span>
                                </button>
                            </td>
                        </tr>
                        <%  }
                           } else { %>
                        <tr>
                            <td colspan="8" style="padding: 36px 16px; text-align: center; color: #64748b;">
                                No alerts match the current filter criteria.
                            </td>
                        </tr>
                        <% } %>
                    </tbody>
                </table>
            </div>

            <!-- Table Footer & Pagination -->
            <div class="table-footer">
                <span class="footer-text">
                    <span id="defaultFooterCount">Showing <b><%= startRecord %></b> to <b><%= endRecord %></b> of <b><%= total %></b> alerts</span>
                    <span id="quickSearchFooterCount" style="display:none; color: #2563eb; font-weight: 600;"></span>
                </span>
                <div class="pager-links">
                    <% if (pageNo > 1) { %>
                        <a class="page-num" href="?page=1<%= filterParams %>" title="First">&laquo;</a>
                        <a class="page-num" href="?page=<%= pageNo - 1 %><%= filterParams %>" title="Previous">&lsaquo;</a>
                    <% } %>

                    <%
                        int startP = Math.max(1, pageNo - 2);
                        int endP = Math.min(totalPages, pageNo + 2);
                        for (int p = startP; p <= endP; p++) {
                            if (p == pageNo) {
                    %>
                        <span class="page-num current"><%= p %></span>
                    <%      } else { %>
                        <a class="page-num" href="?page=<%= p %><%= filterParams %>"><%= p %></a>
                    <%      }
                        }
                    %>

                    <% if (pageNo < totalPages) { %>
                        <a class="page-num" href="?page=<%= pageNo + 1 %><%= filterParams %>" title="Next">&rsaquo;</a>
                        <a class="page-num" href="?page=<%= totalPages %><%= filterParams %>" title="Last">&raquo;</a>
                    <% } %>

                    <!-- Direct Page Jump -->
                    <form method="get" action="<%= ctx %>/alerts" style="display: inline-flex; align-items: center; gap: 4px; margin-left: 10px;">
                        <% if (currentStatus != null) { %><input type="hidden" name="status" value="<%= Web.esc(currentStatus) %>"><% } %>
                        <% if (currentRuleCode != null) { %><input type="hidden" name="ruleCode" value="<%= Web.esc(currentRuleCode) %>"><% } %>
                        <% if (currentSeverity != null) { %><input type="hidden" name="severity" value="<%= Web.esc(currentSeverity) %>"><% } %>
                        <% if (currentRoomId != null) { %><input type="hidden" name="roomId" value="<%= currentRoomId %>"><% } %>
                        <input type="number" name="page" min="1" max="<%= totalPages %>" placeholder="#" class="page-jump-input" required>
                        <button type="submit" class="page-jump-btn">Go</button>
                    </form>
                </div>
            </div>
        </section>
    </main>

    <!-- 7. ALERT DETAILS MODAL -->
    <div class="modal-overlay" id="detailModalOverlay" style="display: none;">
        <div class="modal-dialog modal-dialog-detail">
            <div class="modal-header">
                <div class="modal-title-group">
                    <div class="modal-icon-badge blue">
                        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2">
                            <circle cx="12" cy="12" r="10"></circle>
                            <line x1="12" y1="8" x2="12" y2="12"></line>
                            <line x1="12" y1="16" x2="12.01" y2="16"></line>
                        </svg>
                    </div>
                    <div>
                        <span class="modal-title">Alert Details <span id="modalAlertIdTitle" style="color: #2563eb;">#</span></span>
                        <div style="font-size: 11.5px; color: #64748b; margin-top: 2px;">Xem thông tin đầy đủ và cập nhật xử lý cảnh báo</div>
                    </div>
                </div>
                <button type="button" class="modal-close-btn" onclick="closeDetailModal()" title="Close dialog">
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="18" y1="6" x2="6" y2="18"></line><line x1="6" y1="6" x2="18" y2="18"></line></svg>
                </button>
            </div>

            <form method="post" action="<%= ctx %>/alerts" id="detailAlertForm">
                <input type="hidden" name="alertId" id="modalAlertIdInput">
                <input type="hidden" name="action" value="save">
                <input type="hidden" name="backStatus" value="<%= currentStatus != null ? Web.esc(currentStatus) : "" %>">
                <input type="hidden" name="backRoomId" value="<%= currentRoomId != null ? currentRoomId : "" %>">

                <div class="modal-body detail-modal-body">
                    <!-- Thông tin chi tiết cảnh báo -->
                    <div class="detail-grid">
                        <div class="detail-item">
                            <span class="detail-item-label">Số thứ tự:</span>
                            <span class="detail-item-val font-semibold" id="modalStt">–</span>
                        </div>
                        <div class="detail-item">
                            <span class="detail-item-label">Alert Code:</span>
                            <div><span id="modalAlertCodeBadge" class="alert-code-pill">–</span></div>
                        </div>
                        <div class="detail-item">
                            <span class="detail-item-label">Type:</span>
                            <div><span id="modalTypeBadge" class="alert-type-badge">–</span></div>
                        </div>
                        <div class="detail-item">
                            <span class="detail-item-label">Room Code:</span>
                            <div><span id="modalRoomCodeBadge" class="room-code-tag">–</span></div>
                        </div>
                        <div class="detail-item span-2">
                            <span class="detail-item-label">Trạng thái hiện tại:</span>
                            <div><span id="modalStatusBadge" class="alert-status-pill open">–</span></div>
                        </div>
                        <div class="detail-item span-2">
                            <span class="detail-item-label">Thời gian:</span>
                            <div class="cell-time-wrapper">
                                <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="#64748b" stroke-width="2"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>
                                <span id="modalTime" style="font-size: 13px; color: #1e293b; font-weight: 500;">–</span>
                            </div>
                        </div>
                        <div class="detail-item span-2">
                            <span class="detail-item-label">Nội dung cảnh báo (Message):</span>
                            <div class="modal-message-box" id="modalMessage">–</div>
                        </div>
                        <div class="detail-item span-2">
                            <span class="detail-item-label">Xử lý bởi (Handled By):</span>
                            <div class="modal-handler-box">
                                <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="#2563eb" stroke-width="2.2"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>
                                <span class="handler-name"><%= Web.esc(userName) %></span>
                                <span class="handler-user-badge">Người dùng hiện tại</span>
                            </div>
                        </div>
                    </div>

                    <!-- Chọn Approve hoặc Reject -->
                    <div class="modal-section-title">Chọn trạng thái xử lý:</div>
                    <div class="status-choice-group">
                        <label class="status-choice-card approve-card" id="approveCard" onclick="selectChoice('APPROVED')">
                            <input type="radio" name="status" value="APPROVED" id="modalOptApprove" <%= canHandle ? "" : "disabled" %>>
                            <div class="choice-content">
                                <div class="choice-icon-wrap approve-icon">
                                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3"><polyline points="20 6 9 17 4 12"></polyline></svg>
                                </div>
                                <div class="choice-text">
                                    <div class="choice-label">Approve</div>
                                    <div class="choice-hint">Xác nhận sự cố & duyệt cảnh báo</div>
                                </div>
                            </div>
                        </label>
                        <label class="status-choice-card reject-card" id="rejectCard" onclick="selectChoice('REJECTED')">
                            <input type="radio" name="status" value="REJECTED" id="modalOptReject" <%= canHandle ? "" : "disabled" %>>
                            <div class="choice-content">
                                <div class="choice-icon-wrap reject-icon">
                                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3"><line x1="18" y1="6" x2="6" y2="18"></line><line x1="6" y1="6" x2="18" y2="18"></line></svg>
                                </div>
                                <div class="choice-text">
                                    <div class="choice-label">Reject</div>
                                    <div class="choice-hint">Từ chối cảnh báo giả / nhiễu cảm biến</div>
                                </div>
                            </div>
                        </label>
                    </div>

                    <!-- Ô để ghi chú (Note) -->
                    <div class="modal-note-section">
                        <label for="modalNoteText" class="detail-item-label" style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 6px;">
                            <span>Ghi chú xử lý (Note):</span>
                            <span style="font-weight: normal; color: #94a3b8; font-size: 11.5px;">Tùy chọn</span>
                        </label>
                        <% if (canHandle) { %>
                            <div class="quick-reason-pills" style="margin-bottom: 6px;">
                                <button type="button" class="reason-chip" onclick="setDetailNote('Đã kiểm tra phòng học và xử lý thông gió.')">Đã thông gió</button>
                                <button type="button" class="reason-chip" onclick="setDetailNote('Cảnh báo giả / Nhiễu môi trường.')">Cảnh báo giả</button>
                                <button type="button" class="reason-chip" onclick="setDetailNote('Nước rửa tay / cồn bay hơi tạm thời.')">Cồn sát khuẩn</button>
                                <button type="button" class="reason-chip" onclick="setDetailNote('Nhiệt độ đã ổn định trở lại.')">Nhiệt độ ổn định</button>
                            </div>
                        <% } %>
                        <textarea id="modalNoteText" name="handledNote" class="modal-textarea" placeholder="Nhập lý do hoặc hướng xử lý cảnh báo..." rows="3" <%= canHandle ? "" : "readonly" %>></textarea>
                    </div>
                </div>

                <div class="modal-footer">
                    <button type="button" class="btn-modal-cancel" onclick="closeDetailModal()">Đóng</button>
                    <% if (canHandle) { %>
                        <button type="submit" class="btn-modal-save">
                            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="20 6 9 17 4 12"></polyline></svg>
                            <span>Save</span>
                        </button>
                    <% } %>
                </div>
            </form>
        </div>
    </div>

    <!-- Page Scripts -->
    <script>
        // 1. Sidebar Toggle
        const btnSidebarToggle = document.getElementById("btnSidebarToggle");
        if (btnSidebarToggle) {
            btnSidebarToggle.addEventListener("click", () => {
                document.body.classList.toggle("sidebar-collapsed");
            });
        }

        // 2. User Profile Dropdown
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

        // 3. Dynamic Live Clock
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

        // 4. Detail Modal Handling
        const detailModalOverlay = document.getElementById('detailModalOverlay');
        const modalAlertIdTitle = document.getElementById('modalAlertIdTitle');
        const modalAlertIdInput = document.getElementById('modalAlertIdInput');
        const modalStt = document.getElementById('modalStt');
        const modalAlertCodeBadge = document.getElementById('modalAlertCodeBadge');
        const modalTypeBadge = document.getElementById('modalTypeBadge');
        const modalRoomCodeBadge = document.getElementById('modalRoomCodeBadge');
        const modalStatusBadge = document.getElementById('modalStatusBadge');
        const modalTime = document.getElementById('modalTime');
        const modalMessage = document.getElementById('modalMessage');
        const modalNoteText = document.getElementById('modalNoteText');
        const modalOptApprove = document.getElementById('modalOptApprove');
        const modalOptReject = document.getElementById('modalOptReject');
        const approveCard = document.getElementById('approveCard');
        const rejectCard = document.getElementById('rejectCard');

        function openDetailModal(btn) {
            const ds = btn.dataset;
            modalAlertIdTitle.textContent = '#' + ds.alertId;
            modalAlertIdInput.value = ds.alertId;
            modalStt.textContent = '#' + ds.stt;
            modalAlertCodeBadge.textContent = ds.alertCode;
            if (modalTypeBadge) {
                const tVal = ds.type || '–';
                modalTypeBadge.textContent = tVal;
                let tClass = 'type-default';
                const tu = tVal.toUpperCase();
                if (tu.includes('TEMP')) tClass = 'type-temp';
                else if (tu.includes('HUMID')) tClass = 'type-humid';
                else if (tu.includes('CO2')) tClass = 'type-co2';
                else if (tu === 'CO') tClass = 'type-co';
                modalTypeBadge.className = 'alert-type-badge ' + tClass;
            }
            modalRoomCodeBadge.textContent = ds.roomCode;

            // Status badge
            const st = (ds.status || 'OPENING').toUpperCase();
            modalStatusBadge.textContent = st;
            let pillClass = 'open';
            if (st === 'APPROVED' || st === 'ACKED') pillClass = 'acked';
            else if (st === 'REJECTED') pillClass = 'rejected';
            modalStatusBadge.className = 'alert-status-pill ' + pillClass;

            modalTime.textContent = ds.time || '–';
            modalMessage.textContent = ds.message || '–';
            modalNoteText.value = (ds.note && ds.note !== '–') ? ds.note : '';

            // Select Approve or Reject
            if (st === 'REJECTED') {
                selectChoice('REJECTED');
            } else {
                selectChoice('APPROVED');
            }

            detailModalOverlay.style.display = 'flex';
        }

        function selectChoice(type) {
            if (!approveCard || !rejectCard) return;
            if (type === 'REJECTED') {
                if (modalOptReject) modalOptReject.checked = true;
                rejectCard.classList.add('selected');
                approveCard.classList.remove('selected');
            } else {
                if (modalOptApprove) modalOptApprove.checked = true;
                approveCard.classList.add('selected');
                rejectCard.classList.remove('selected');
            }
        }

        function closeDetailModal() {
            detailModalOverlay.style.display = 'none';
        }

        function setDetailNote(note) {
            modalNoteText.value = note;
            modalNoteText.focus();
        }

        // Close on Escape or click outside dialog
        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape' && detailModalOverlay.style.display === 'flex') {
                closeDetailModal();
            }
        });

        detailModalOverlay.addEventListener('click', (e) => {
            if (e.target === detailModalOverlay) {
                closeDetailModal();
            }
        });

        // 5. Instant Zero-Reload Filtering for Stat Cards & Status Tabs
        let currentActiveStatus = '<%= currentStatus != null ? currentStatus : "" %>';

        function filterByStatus(status) {
            // If clicking the same active status card (other than all), toggle back to all
            if (status && currentActiveStatus === status) {
                status = '';
            }
            currentActiveStatus = status || '';

            // 1. Update hidden form input for sync
            const statusInput = document.getElementById('filterStatusInput');
            if (statusInput) statusInput.value = currentActiveStatus;

            // 2. Update active states on the 4 stats cards
            const cards = document.querySelectorAll('.stats-cards-grid .stat-card');
            cards.forEach(card => {
                card.classList.remove('active', 'active-blue', 'active-amber', 'active-green', 'active-red');
            });

            if (!currentActiveStatus) {
                if (cards[0]) cards[0].classList.add('active', 'active-blue');
            } else if (currentActiveStatus === 'OPENING') {
                if (cards[1]) cards[1].classList.add('active', 'active-amber');
            } else if (currentActiveStatus === 'APPROVED' || currentActiveStatus === 'ACKED') {
                if (cards[2]) cards[2].classList.add('active', 'active-green');
            } else if (currentActiveStatus === 'REJECTED') {
                if (cards[3]) cards[3].classList.add('active', 'active-red');
            }

            // 3. Update active states on status tabs
            const tabs = document.querySelectorAll('.status-tabs .status-tab-btn');
            tabs.forEach(tab => tab.classList.remove('active'));
            if (!currentActiveStatus && tabs[0]) tabs[0].classList.add('active');
            else if (currentActiveStatus === 'OPENING' && tabs[1]) tabs[1].classList.add('active');
            else if ((currentActiveStatus === 'APPROVED' || currentActiveStatus === 'ACKED') && tabs[2]) tabs[2].classList.add('active');
            else if (currentActiveStatus === 'REJECTED' && tabs[3]) tabs[3].classList.add('active');

            // 4. Check if rows exist in DOM for instant filtering
            const rows = Array.from(document.querySelectorAll('.alerts-table tbody tr:not(.quick-search-empty)'));
            const hasStatusRows = currentActiveStatus === '' || rows.some(r => {
                const rs = (r.dataset.status || '').toUpperCase();
                return currentActiveStatus === 'APPROVED' ? (rs === 'APPROVED' || rs === 'ACKED') : (rs === currentActiveStatus);
            });

            // If rows can be filtered in DOM, filter IMMEDIATELY with zero reload!
            if (hasStatusRows || rows.length === 0) {
                try {
                    const url = new URL(window.location.href);
                    if (currentActiveStatus) {
                        url.searchParams.set('status', currentActiveStatus);
                    } else {
                        url.searchParams.delete('status');
                    }
                    window.history.replaceState({}, '', url.toString());
                } catch (e) {}

                applyTableFilters();
            } else {
                // If records are only on other pages from server, submit form
                const form = document.getElementById('alertsFilterForm');
                if (form) form.submit();
            }
        }

        // 6. Real-time Multi-Criteria Table Filtering (Status + Keystroke Query)
        function applyTableFilters() {
            const tableBody = document.querySelector('.alerts-table tbody');
            if (!tableBody) return;

            const searchInput = document.getElementById('tableQuickSearch');
            const query = searchInput ? searchInput.value.trim().toLowerCase() : '';
            const clearBtn = document.getElementById('clearQuickSearch');
            if (clearBtn) {
                clearBtn.style.display = query.length > 0 ? 'inline-flex' : 'none';
            }

            const defaultCountEl = document.getElementById('defaultFooterCount');
            const searchCountEl = document.getElementById('quickSearchFooterCount');

            let emptyRow = tableBody.querySelector('.quick-search-empty');
            if (!emptyRow) {
                emptyRow = document.createElement('tr');
                emptyRow.className = 'quick-search-empty';
                emptyRow.style.display = 'none';
                emptyRow.innerHTML = `
                    <td colspan="8" style="padding: 32px 16px; text-align: center; color: #64748b;">
                        <div style="display: flex; flex-direction: column; align-items: center; gap: 8px;">
                            <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
                                <circle cx="11" cy="11" r="8"></circle>
                                <line x1="21" y1="21" x2="16.65" y2="16.65"></line>
                            </svg>
                            <span style="font-weight: 600; color: #334155; font-size: 14px;">Không tìm thấy cảnh báo phù hợp với bộ lọc</span>
                            <span style="font-size: 12.5px; color: #94a3b8;">Nhấn thẻ Total Alerts hoặc nút '✕' để hiển thị lại tất cả</span>
                        </div>
                    </td>
                `;
                tableBody.appendChild(emptyRow);
            }

            const rows = Array.from(tableBody.querySelectorAll('tr:not(.quick-search-empty)'));
            let matched = 0;
            let totalRows = rows.length;

            rows.forEach(r => {
                const rowStatus = (r.dataset.status || '').toUpperCase();
                let statusMatch = true;
                if (currentActiveStatus) {
                    const stNorm = currentActiveStatus.toUpperCase();
                    if (stNorm === 'APPROVED' || stNorm === 'ACKED') {
                        statusMatch = (rowStatus === 'APPROVED' || rowStatus === 'ACKED');
                    } else {
                        statusMatch = (rowStatus === stNorm);
                    }
                }

                const text = r.textContent.toLowerCase();
                let queryMatch = (!query || text.includes(query));

                if (statusMatch && queryMatch) {
                    r.style.display = '';
                    matched++;
                } else {
                    r.style.display = 'none';
                }
            });

            if (matched === 0 && (query.length > 0 || currentActiveStatus)) {
                emptyRow.style.display = '';
            } else {
                emptyRow.style.display = 'none';
            }

            if (searchCountEl && defaultCountEl) {
                if (query.length > 0 || currentActiveStatus) {
                    defaultCountEl.style.display = 'none';
                    searchCountEl.style.display = 'inline';
                    let statusLabel = currentActiveStatus ? (' • Trạng thái: ' + currentActiveStatus) : '';
                    searchCountEl.textContent = 'Lọc tức thì: Hiển thị ' + matched + '/' + totalRows + ' cảnh báo' + statusLabel;
                } else {
                    defaultCountEl.style.display = 'inline';
                    searchCountEl.style.display = 'none';
                }
            }
        }

        function initQuickSearch() {
            const searchInput = document.getElementById('tableQuickSearch');
            const clearBtn = document.getElementById('clearQuickSearch');
            if (searchInput) {
                searchInput.addEventListener('input', applyTableFilters);
                searchInput.addEventListener('keydown', (e) => {
                    if (e.key === 'Escape') {
                        searchInput.value = '';
                        applyTableFilters();
                    }
                });
            }
            if (clearBtn) {
                clearBtn.addEventListener('click', () => {
                    if (searchInput) {
                        searchInput.value = '';
                        searchInput.focus();
                    }
                    applyTableFilters();
                });
            }
        }

        initQuickSearch();
    </script>
</body>
</html>
