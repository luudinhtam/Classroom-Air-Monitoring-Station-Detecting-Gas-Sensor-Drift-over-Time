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
        </tr>
        <% } } %>
        <% if (rows == null || rows.isEmpty()) { %>
        <tr><td colspan="10" class="c">Khong co phien nao khop bo loc</td></tr>
        <% } %>
    </table>

    <div class="pager">
        <% for (int p = 1; p <= totalPages; p++) { %>
            <% if (p == currentPage) { %><b><%= p %></b>
            <% } else { %><a href="?label=<%= Web.esc(labelFilter) %>&page=<%= p %>"><%= p %></a><% } %>
        <% } %>
    </div>
</div>
</body>
</html>
