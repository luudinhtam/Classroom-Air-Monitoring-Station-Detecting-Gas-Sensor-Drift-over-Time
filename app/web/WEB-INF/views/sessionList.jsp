<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.List, model.AirSession, util.Web" %>
<%
    List<AirSession> rows = (List<AirSession>) request.getAttribute("rows");
    String labelFilter = (String) request.getAttribute("label");
    String ctx = request.getContextPath();
    Integer currentPage = (Integer) request.getAttribute("page");
    Integer totalPages  = (Integer) request.getAttribute("pages");
    if (currentPage == null) currentPage = 1;
    if (totalPages  == null) totalPages  = 1;
    if (labelFilter == null) labelFilter = "";
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Airroom – Sessions</title>
    <link rel="stylesheet" href="<%= ctx %>/css/app.css">
</head>
<body>
<jsp:include page="/WEB-INF/views/nav.jsp"/>
<div class="wrap">
    <h2>Danh sach phien do (<%= request.getAttribute("total") %>)</h2>

    <form class="filter" method="get" action="<%= ctx %>/sessions">
        <select name="label">
            <option value="">-- Tat ca nhan --</option>
            <option value="BASE"        <%= "BASE".equals(labelFilter)        ? "selected" : "" %>>BASE</option>
            <option value="RAISED"      <%= "RAISED".equals(labelFilter)      ? "selected" : "" %>>RAISED</option>
            <option value="HIGH"        <%= "HIGH".equals(labelFilter)        ? "selected" : "" %>>HIGH</option>
            <option value="DRIFTED"     <%= "DRIFTED".equals(labelFilter)     ? "selected" : "" %>>DRIFTED</option>
            <option value="TEMP_EFFECT" <%= "TEMP_EFFECT".equals(labelFilter) ? "selected" : "" %>>TEMP_EFFECT</option>
            <option value="WARMUP"      <%= "WARMUP".equals(labelFilter)      ? "selected" : "" %>>WARMUP</option>
        </select>
        <button type="submit">Loc</button>
        <a class="btn ghost" href="<%= ctx %>/sessions">Bo loc</a>
        <a class="btn" href="<%= ctx %>/sessions/create">+ Them phien do</a>
    </form>

    <table class="grid">
        <tr>
            <th>#</th>
            <th>Thoi gian do</th>
            <th>Gas A (raw)</th>
            <th>Gas B (raw)</th>
            <th>Gas A (base)</th>
            <th>Delta</th>
            <th>Temp (°C)</th>
            <th>Humid (%)</th>
            <th>Base Shift</th>
            <th>Nhan</th>
            <th>Ma thiet bi</th>
            <th>Thao tac</th>
        </tr>
        <% if (rows != null) {
            for (AirSession r : rows) {
                String lbl = r.getLabelCode();
                if (lbl == null) lbl = "";
        %>
        <tr class="lb-<%= lbl %>">
            <td><%= r.getSessionId() %></td>
            <td><%= r.getMeasuredAt() %></td>
            <td><%= r.getGasARaw() %></td>
            <td><%= r.getGasBRaw() %></td>
            <td><%= r.getGasABase() %></td>
            <td><%= r.getGasADelta() %></td>
            <td><%= r.getTempC() %></td>
            <td><%= r.getHumidPct() %></td>
            <td><%= r.getBaseShift() %></td>
            <td><span class="tag"><%= Web.esc(lbl) %></span></td>
            <td><%= r.getDeviceId() %></td>
            <td class="ops">
                <a href="<%= ctx %>/sessions/detail?id=<%= r.getSessionId() %>">Chi tiết</a>
                <a href="<%= ctx %>/sessions/edit?id=<%= r.getSessionId() %>">Sửa</a>
                
                <form method="post" action="<%= ctx %>/sessions/delete"
                      onsubmit="return confirm('Xoa phien do nay?');">
                    <input type="hidden" name="id" value="<%= r.getSessionId() %>">
                    <button type="submit" class="link danger">Xoa</button>
                </form>
            </td>
        </tr>
        <% } } %>
        <% if (rows == null || rows.isEmpty()) { %>
        <tr><td colspan="12" class="c">Khong co phien nao khop bo loc</td></tr>
        <% } %>
    </table>

    <div class="pager">
        <% if (currentPage > 1) { %>
            <a href="?label=<%= Web.esc(labelFilter) %>&page=1">&laquo; Đầu</a>
            <a href="?label=<%= Web.esc(labelFilter) %>&page=<%= currentPage - 1 %>">&lsaquo; Trước</a>
        <% } %>

        <%
            int startPage = currentPage - 1;
            int endPage = currentPage + 1;

            if (currentPage == 1) endPage = 3;
            else if (currentPage == totalPages) startPage = totalPages - 2;
            
            if (startPage < 1) startPage = 1;
            if (endPage > totalPages) endPage = totalPages;
        %>

        <% if (startPage > 1) { %>
            <a href="?label=<%= Web.esc(labelFilter) %>&page=1">1</a>
            <% if (startPage > 2) { %>
                <span>...</span>
            <% } %>
        <% } %>

        <% for (int p = startPage; p <= endPage; p++) { %>
            <% if (p == currentPage) { %>
                <b><%= p %></b>
            <% } else { %>
                <a href="?label=<%= Web.esc(labelFilter) %>&page=<%= p %>"><%= p %></a>
            <% } %>
        <% } %>

        <% if (endPage < totalPages) { %>
            <% if (endPage < totalPages - 1) { %>
                <span>...</span>
            <% } %>
            <a href="?label=<%= Web.esc(labelFilter) %>&page=<%= totalPages %>"><%= totalPages %></a>
        <% } %>

        <% if (currentPage < totalPages) { %>
            <a href="?label=<%= Web.esc(labelFilter) %>&page=<%= currentPage + 1 %>">Sau &rsaquo;</a>
            <a href="?label=<%= Web.esc(labelFilter) %>&page=<%= totalPages %>">Cuối &raquo;</a>
        <% } %>

        <form method="get" action="<%= ctx %>/sessions" style="display: inline-block; margin-left: 15px;">
            <input type="hidden" name="label" value="<%= Web.esc(labelFilter) %>">
            <input type="number" name="page" min="1" max="<%= totalPages %>" placeholder="Trang..." required style="width: 70px; padding: 4px; border: 1px solid #ccc; border-radius: 3px;">
            <button type="submit" style="padding: 4px 8px; cursor: pointer; border-radius: 3px; border: 1px solid #ccc; background: #eee; color: black;">Đi</button>
        </form>
    </div>
</div>
</body>
</html>