<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.List, model.AirAlert, model.AppUser, util.Web" %>
<%
    AppUser me = (AppUser) session.getAttribute("user");
    String ctx = request.getContextPath();

    List<AirAlert> alerts = (List<AirAlert>) request.getAttribute("alerts");
    int pageNo = (Integer) request.getAttribute("page");
    int totalPages = (Integer) request.getAttribute("totalPages");
    int total = (Integer) request.getAttribute("total");

    String currentStatus = (String) request.getAttribute("currentStatus");
    String currentRuleCode = (String) request.getAttribute("currentRuleCode");
    String currentSeverity = (String) request.getAttribute("currentSeverity");

    int openCount = (Integer) request.getAttribute("openCount");
    int ackedCount = (Integer) request.getAttribute("ackedCount");
    int rejectedCount = (Integer) request.getAttribute("rejectedCount");
    int allCount = (Integer) request.getAttribute("allCount");

    boolean canHandle = me != null && !"VIEWER".equals(me.getRoleCode());
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Quản lý cảnh báo</title>
    <link rel="stylesheet" href="<%= ctx %>/css/app.css">
    <link rel="stylesheet" href="<%= ctx %>/css/alertList.css">
</head>
<body>
<jsp:include page="/WEB-INF/views/nav.jsp"/>

<div class="wrap">
    <!-- TIÊU ĐỀ -->
    <div class="dashboard-header" style="margin-bottom: 12px;">
        <div>
            <h2>Quản lý cảnh báo</h2>
        </div>
    </div>

    <!-- TABS PHÂN LOẠI TRẠNG THÁI -->
    <div class="tabs-status">
        <a href="<%= ctx %>/alerts" class="tab-btn <%= currentStatus == null ? "active" : "" %>">
            Tất cả cảnh báo <span class="tab-badge"><%= allCount %></span>
        </a>
        <a href="<%= ctx %>/alerts?status=OPEN" class="tab-btn <%= "OPEN".equals(currentStatus) ? "active" : "" %>">
            Chưa xử lý (OPEN) <span class="tab-badge" style="background: #fef3c7; color: #92400e;"><%= openCount %></span>
        </a>
        <a href="<%= ctx %>/alerts?status=ACKED" class="tab-btn <%= "ACKED".equals(currentStatus) ? "active" : "" %>">
            Đã xác nhận (ACKED) <span class="tab-badge" style="background: #dcfce7; color: #166534;"><%= ackedCount %></span>
        </a>
        <a href="<%= ctx %>/alerts?status=REJECTED" class="tab-btn <%= "REJECTED".equals(currentStatus) ? "active" : "" %>">
            Bị bác bỏ (REJECTED) <span class="tab-badge" style="background: #fee2e2; color: #991b1b;"><%= rejectedCount %></span>
        </a>
    </div>

    <!-- BỘ LỌC TÙY CHỌN -->
    <form class="filter" method="get" action="<%= ctx %>/alerts" style="margin-bottom: 14px;">
        <% if (currentStatus != null) { %>
            <input type="hidden" name="status" value="<%= Web.esc(currentStatus) %>">
        <% } %>

        <label style="font-size: 13px; font-weight: 500; color: #475569;">Luật cảnh báo:</label>
        <select name="ruleCode">
            <option value="">-- Tất cả luật --</option>
            <option value="HIGH" <%= "HIGH".equals(currentRuleCode) ? "selected" : "" %>>HIGH (Không khí kém)</option>
            <option value="TEMP_EFFECT" <%= "TEMP_EFFECT".equals(currentRuleCode) ? "selected" : "" %>>TEMP_EFFECT (Ảnh hưởng của nhiệt)</option>
            <option value="DRIFTED" <%= "DRIFTED".equals(currentRuleCode) ? "selected" : "" %>>DRIFTED (Cảm biến đã trôi)</option>
            <option value="WARMUP" <%= "WARMUP".equals(currentRuleCode) ? "selected" : "" %>>WARMUP (Chưa làm nóng xong)</option>
        </select>

        <label style="font-size: 13px; font-weight: 500; color: #475569; margin-left: 8px;">Mức độ:</label>
        <select name="severity">
            <option value="">-- Tất cả mức độ --</option>
            <option value="CRITICAL" <%= "CRITICAL".equals(currentSeverity) ? "selected" : "" %>>CRITICAL (Đỏ - Nghiêm trọng)</option>
            <option value="WARN" <%= "WARN".equals(currentSeverity) ? "selected" : "" %>>WARN (Vàng - Cảnh báo)</option>
            <option value="INFO" <%= "INFO".equals(currentSeverity) ? "selected" : "" %>>INFO (Thông tin)</option>
        </select>

        <button type="submit" class="btn">Lọc</button>
        <a href="<%= ctx %>/alerts<%= currentStatus != null ? "?status=" + currentStatus : "" %>" class="btn ghost">Đặt lại</a>
    </form>

    <!-- BẢNG DANH SÁCH CẢNH BÁO -->
    <% if (alerts == null || alerts.isEmpty()) { %>
        <div style="padding: 24px; text-align: center; background: #fff; border: 1px solid #e2e8f0; border-radius: 6px; color: #64748b;">
            Không tìm thấy cảnh báo nào phù hợp với bộ lọc hiện tại.
        </div>
    <% } else { %>
        <table class="grid">
            <thead>
                <tr>
                    <th style="width: 60px;">Mã</th>
                    <th style="width: 90px;">Phiên đo</th>
                    <th style="width: 140px;">Luật cảnh báo</th>
                    <th class="c" style="width: 90px;">Mức độ</th>
                    <th>Thông điệp cảnh báo</th>
                    <th class="c" style="width: 110px;">Trạng thái</th>
                    <th style="width: 140px;">Thời điểm tạo</th>
                    <th style="width: 170px;">Người xử lý & Ghi chú</th>
                    <th class="c" style="width: 140px;">Thao tác</th>
                </tr>
            </thead>
            <tbody>
                <% for (AirAlert a : alerts) { %>
                    <tr class="<%= "REJECTED".equals(a.getStatus()) ? "locked" : "" %>">
                        <td><b>#<%= a.getAlertId() %></b></td>
                        <td>
                            <% if (a.getSessionId() != null && a.getSessionId() > 0) { %>
                                <a href="<%= ctx %>/sessions/detail?id=<%= a.getSessionId() %>" style="color: #2563eb; font-weight: 600;">
                                    Phiên #<%= a.getSessionId() %>
                                </a>
                            <% } else { %>
                                <span class="muted">–</span>
                            <% } %>
                        </td>
                        <td>
                            <span class="tag"><%= Web.esc(a.getRuleCode()) %></span>
                        </td>
                        <td class="c">
                            <% if ("CRITICAL".equals(a.getSeverity())) { %>
                                <span class="badge-status danger">CRITICAL</span>
                            <% } else if ("WARN".equals(a.getSeverity())) { %>
                                <span class="badge-status warn">WARN</span>
                            <% } else { %>
                                <span class="badge-status good">INFO</span>
                            <% } %>
                        </td>
                        <td><%= Web.esc(a.getMessage()) %></td>
                        <td class="c">
                            <% if ("OPEN".equals(a.getStatus())) { %>
                                <span class="badge-status warn">Chưa xử lý</span>
                            <% } else if ("ACKED".equals(a.getStatus())) { %>
                                <span class="badge-status good">Đã xác nhận</span>
                            <% } else { %>
                                <span class="badge-status danger">Đã bác bỏ</span>
                            <% } %>
                        </td>
                        <td class="muted"><%= a.getCreatedAt() != null ? a.getCreatedAt().toString().substring(0, 16) : "–" %></td>
                        <td>
                            <% if (a.getHandledByName() != null) { %>
                                <div style="font-weight: 600; font-size: 12px;"><%= Web.esc(a.getHandledByName()) %></div>
                                <div class="muted" style="font-size: 11px;"><%= a.getHandledNote() != null ? Web.esc(a.getHandledNote()) : "" %></div>
                            <% } else { %>
                                <span class="muted">Chưa xử lý</span>
                            <% } %>
                        </td>
                        <td class="c">
                            <% if ("OPEN".equals(a.getStatus()) && canHandle) { %>
                                <div style="display: flex; gap: 4px; justify-content: center;">
                                    <!-- Nút xác nhận -->
                                    <form method="post" action="<%= ctx %>/alerts" style="display: inline; margin: 0;">
                                        <input type="hidden" name="alertId" value="<%= a.getAlertId() %>">
                                        <input type="hidden" name="action" value="ack">
                                        <input type="hidden" name="backStatus" value="<%= currentStatus != null ? Web.esc(currentStatus) : "" %>">
                                        <button type="submit" class="btn-action-ack" title="Xác nhận sự cố có thật">✓ Duyệt</button>
                                    </form>

                                    <!-- Nút bác bỏ -->
                                    <button type="button" class="btn-action-rej" title="Bác bỏ báo động giả" onclick="rejectAlert(<%= a.getAlertId() %>)">✕ Bác bỏ</button>
                                </div>
                            <% } else { %>
                                <% if (a.getSessionId() != null && a.getSessionId() > 0) { %>
                                    <a href="<%= ctx %>/sessions/detail?id=<%= a.getSessionId() %>" class="btn ghost" style="padding: 2px 7px; font-size: 11px;">Chi tiết</a>
                                <% } else { %>
                                    <span class="muted">–</span>
                                <% } %>
                            <% } %>
                        </td>
                    </tr>
                <% } %>
            </tbody>
        </table>

        <!-- PHÂN TRANG -->
        <div class="pager">
            <%
                String filterParams = (currentStatus != null ? "&status=" + Web.esc(currentStatus) : "")
                                    + (currentRuleCode != null ? "&ruleCode=" + Web.esc(currentRuleCode) : "")
                                    + (currentSeverity != null ? "&severity=" + Web.esc(currentSeverity) : "");
            %>
            <% if (pageNo > 1) { %>
                <a href="?page=1<%= filterParams %>">&laquo; Đầu</a>
                <a href="?page=<%= pageNo - 1 %><%= filterParams %>">&lsaquo; Trước</a>
            <% } %>

            <%
                int startPage = pageNo - 1;
                int endPage = pageNo + 1;

                if (pageNo == 1) endPage = 3;
                else if (pageNo == totalPages) startPage = totalPages - 2;
                
                if (startPage < 1) startPage = 1;
                if (endPage > totalPages) endPage = totalPages;
            %>

            <% if (startPage > 1) { %>
                <a href="?page=1<%= filterParams %>">1</a>
                <% if (startPage > 2) { %>
                    <span>...</span>
                <% } %>
            <% } %>

            <% for (int p = startPage; p <= endPage; p++) { %>
                <% if (p == pageNo) { %>
                    <b><%= p %></b>
                <% } else { %>
                    <a href="?page=<%= p %><%= filterParams %>"><%= p %></a>
                <% } %>
            <% } %>

            <% if (endPage < totalPages) { %>
                <% if (endPage < totalPages - 1) { %>
                    <span>...</span>
                <% } %>
                <a href="?page=<%= totalPages %><%= filterParams %>"><%= totalPages %></a>
            <% } %>

            <% if (pageNo < totalPages) { %>
                <a href="?page=<%= pageNo + 1 %><%= filterParams %>">Sau &rsaquo;</a>
                <a href="?page=<%= totalPages %><%= filterParams %>">Cuối &raquo;</a>
            <% } %>

            <form method="get" action="<%= ctx %>/alerts" style="display: inline-block; margin-left: 15px;">
                <% if (currentStatus != null) { %>
                    <input type="hidden" name="status" value="<%= Web.esc(currentStatus) %>">
                <% } %>
                <% if (currentRuleCode != null) { %>
                    <input type="hidden" name="ruleCode" value="<%= Web.esc(currentRuleCode) %>">
                <% } %>
                <% if (currentSeverity != null) { %>
                    <input type="hidden" name="severity" value="<%= Web.esc(currentSeverity) %>">
                <% } %>
                <input type="number" name="page" min="1" max="<%= totalPages %>" placeholder="Trang..." required style="width: 70px; padding: 4px; border: 1px solid #ccc; border-radius: 3px;">
                <button type="submit" style="padding: 4px 8px; cursor: pointer; border-radius: 3px; border: 1px solid #ccc; background: #eee; color: black;">Đi</button>
            </form>
        </div>
    <% } %>

</div>

<!-- FORM ẨN XỬ LÝ BÁC BỎ ALERT -->
<form id="rejectForm" method="post" action="<%= ctx %>/alerts" style="display: none;">
    <input type="hidden" name="alertId" id="rejectAlertId">
    <input type="hidden" name="action" value="reject">
    <input type="hidden" name="handledNote" id="rejectHandledNote">
    <input type="hidden" name="backStatus" value="<%= currentStatus != null ? Web.esc(currentStatus) : "" %>">
</form>

<script>
    function rejectAlert(id) {
        var reason = prompt("Nhập lý do bác bỏ cảnh báo #" + id + " (ví dụ: cồn bốc hơi tức thời, nắng chiếu gây nhiễu nhiệt, cảm biến warmup...):", "Báo động giả / Nhiễu môi trường");
        if (reason !== null && reason.trim() !== "") {
            document.getElementById('rejectAlertId').value = id;
            document.getElementById('rejectHandledNote').value = reason.trim();
            document.getElementById('rejectForm').submit();
        }
    }
</script>
</body>
</html>
