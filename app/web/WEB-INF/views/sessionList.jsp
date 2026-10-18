<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.List, model.AirSession, model.AppUser, util.Web" %>
<%
    List<AirSession> rows = (List<AirSession>) request.getAttribute("rows");
    String labelFilter = (String) request.getAttribute("label");
    String ctx = request.getContextPath();
    Integer currentPage = (Integer) request.getAttribute("page");
    Integer totalPages  = (Integer) request.getAttribute("pages");
    if (currentPage == null) currentPage = 1;
    if (totalPages  == null) totalPages  = 1;
    if (labelFilter == null) labelFilter = "";

    AppUser me = (AppUser) session.getAttribute("user");
    String myRole = (me != null) ? me.getRoleCode() : "";
    boolean isAdmin = "ADMIN".equals(myRole);
    boolean canEdit = isAdmin || "STATION_MANAGER".equals(myRole) || "OPERATOR".equals(myRole) || "REVIEWER".equals(myRole);
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Sessions</title>
    <link rel="stylesheet" href="<%= ctx %>/css/app.css?v=2">
</head>
<body>
<jsp:include page="/WEB-INF/views/nav.jsp"/>
<div class="wrap">
    <h2>Measurement Sessions (<%= request.getAttribute("total") %>)</h2>

    <form class="filter" method="get" action="<%= ctx %>/sessions">
        <select name="label">
            <option value="">-- All Labels --</option>
            <option value="BASE"        <%= "BASE".equals(labelFilter)        ? "selected" : "" %>>BASE</option>
            <option value="RAISED"      <%= "RAISED".equals(labelFilter)      ? "selected" : "" %>>RAISED</option>
            <option value="HIGH"        <%= "HIGH".equals(labelFilter)        ? "selected" : "" %>>HIGH</option>
            <option value="DRIFTED"     <%= "DRIFTED".equals(labelFilter)     ? "selected" : "" %>>DRIFTED</option>
            <option value="TEMP_EFFECT" <%= "TEMP_EFFECT".equals(labelFilter) ? "selected" : "" %>>TEMP_EFFECT</option>
            <option value="WARMUP"      <%= "WARMUP".equals(labelFilter)      ? "selected" : "" %>>WARMUP</option>
        </select>
        <button type="submit">Filter</button>
        <a class="btn ghost" href="<%= ctx %>/sessions">Reset</a>
        
        <% if (isAdmin) { %>
            <a class="btn" href="<%= ctx %>/sessions/create">+ Add Session</a>
        <% } %>

        <a class="btn btn-export" href="<%= ctx %>/sessions/export?label=<%= Web.esc(labelFilter) %>">
            Export CSV
        </a>
    </form>

    <div class="table-responsive">
    <table class="grid">
        <tr>
            <th>#</th>
            <th>Measured At</th>
            <th>Air Quality</th>
            <th>CO</th>
            <th>Air Quality (base)</th>
            <th>Delta</th>
            <th>Temp (°C)</th>
            <th>Humid (%)</th>
            <th>Base Shift</th>
            <th>Label</th>
            <th>Device Code</th>
            <th>Actions</th>
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
            <td><%= r.getDeviceCode() != null ? r.getDeviceCode() : "" %></td>
            
            <td class="ops ops-group">
                <button type="button" class="btn-block btn-gray"
                        onclick="window.location.href='<%= ctx %>/sessions/detail?id=<%= r.getSessionId() %>'">
                    Details
                </button>
                
                <% if (canEdit) { %>
                    <button type="button" class="btn-block btn-blue"
                            onclick="window.location.href='<%= ctx %>/sessions/edit?id=<%= r.getSessionId() %>'">
                        Edit
                    </button>
                <% } %>
                
                <% if (isAdmin) { %>
                    <form method="post" action="<%= ctx %>/sessions/delete"
                          onsubmit="return confirm('Are you sure you want to delete this session?');" style="display:inline-block;">
                        <input type="hidden" name="id" value="<%= r.getSessionId() %>">
                        <button type="submit" class="btn-block btn-red">Delete</button>
                    </form>
                <% } %>
            </td>
        </tr>
        <% } } %>
        <% if (rows == null || rows.isEmpty()) { %>
        <tr><td colspan="12" class="c">No sessions match the filter</td></tr>
        <% } %>
    </table>
    </div>

    <div class="pager">
        <% if (currentPage > 1) { %>
            <a href="?label=<%= Web.esc(labelFilter) %>&page=1">&laquo; First</a>
            <a href="?label=<%= Web.esc(labelFilter) %>&page=<%= currentPage - 1 %>">&lsaquo; Prev</a>
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
            <a href="?label=<%= Web.esc(labelFilter) %>&page=<%= currentPage + 1 %>">Next &rsaquo;</a>
            <a href="?label=<%= Web.esc(labelFilter) %>&page=<%= totalPages %>">Last &raquo;</a>
        <% } %>

        <form method="get" action="<%= ctx %>/sessions" style="display: inline-block; margin-left: 15px;">
            <input type="hidden" name="label" value="<%= Web.esc(labelFilter) %>">
            <input type="number" name="page" min="1" max="<%= totalPages %>" placeholder="Page..." required style="width: 70px; padding: 4px; border: 1px solid #ccc; border-radius: 3px;">
            <button type="submit" style="padding: 4px 8px; cursor: pointer; border-radius: 3px; border: 1px solid #ccc; background: #eee; color: black;">Go</button>
        </form>
    </div>
</div>
</body>
</html>