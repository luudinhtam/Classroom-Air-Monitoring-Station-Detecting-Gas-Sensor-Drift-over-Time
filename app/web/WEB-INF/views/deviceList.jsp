<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.List, model.Device, model.AppUser, util.Web" %>
<%
    List<Device> rows = (List<Device>) request.getAttribute("rows");
    AppUser me = (AppUser) session.getAttribute("user");
    String ctx = request.getContextPath();

    String keyword = (String) request.getAttribute("keyword");
    String activeState = (String) request.getAttribute("activeState");
    Integer currentPage = (Integer) request.getAttribute("page");
    Integer totalPages  = (Integer) request.getAttribute("pages");
    if (currentPage == null) currentPage = 1;
    if (totalPages  == null) totalPages  = 1;

    String qs = "keyword=" + Web.esc(keyword)
              + "&activeState=" + Web.esc(activeState);
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Devices</title>
    <link rel="stylesheet" href="<%= ctx %>/css/app.css">
</head>
<body>
<jsp:include page="/WEB-INF/views/nav.jsp"/>
<div class="wrap">
    <h2>Thiet bi (<%= request.getAttribute("total") %>)</h2>

    <form class="filter" method="get" action="<%= ctx %>/admin/devices">
        <input type="text" name="keyword" placeholder="Ma thiet bi, vi tri"
               value="<%= Web.esc(keyword) %>">
        <select name="activeState">
            <option value="">-- Moi trang thai --</option>
            <option value="ACTIVE" <%= "ACTIVE".equals(activeState) ? "selected" : "" %>>Hoat dong</option>
            <option value="INACTIVE" <%= "INACTIVE".equals(activeState) ? "selected" : "" %>>Tam ngung</option>
        </select>
        <button type="submit">Loc</button>
        <a class="btn ghost" href="<%= ctx %>/admin/devices">Bo loc</a>
        
        <a class="btn" href="<%= ctx %>/admin/devices/create">Them thiet bi</a>
    </form>

    <table class="grid">
        <tr>
            <th>ID</th>
            <th>Ma thiet bi</th>
            <th>API Key</th>
            <th>Vi tri</th>
            <th>Lan cuoi hoat dong</th>
            <th class="c">Trang thai</th>
            <th>Thao tac</th>
        </tr>
        <% for (Device d : rows) { %>
        <tr class="<%= !d.isIsActive() ? "locked" : "" %>">
            <td><%= d.getDeviceId() %></td>
            <td><strong><%= Web.esc(d.getDeviceCode()) %></strong></td>
            <td><code><%= Web.esc(d.getApiKey()) %></code></td>
            <td><%= Web.esc(d.getLocation() != null ? d.getLocation() : "-") %></td>
            <td><%= d.getLastSeen() != null ? d.getLastSeen().toString() : "Chua tung" %></td>
            <td class="c">
                <span class="tag <%= d.isIsActive() ? "" : "danger" %>">
                    <%= d.isIsActive() ? "Hoat dong" : "Tam ngung" %>
                </span>
            </td>
            <td class="ops">
                <a href="<%= ctx %>/admin/devices/edit?id=<%= d.getDeviceId() %>">Sua</a>
                
                <form method="post" action="<%= ctx %>/admin/devices/toggle">
                    <input type="hidden" name="id" value="<%= d.getDeviceId() %>">
                    <button type="submit" class="link"><%= d.isIsActive() ? "Khoa" : "Mo khoa" %></button>
                </form>
                
                <form method="post" action="<%= ctx %>/admin/devices/delete"
                      onsubmit="return confirm('Xoa thiet bi nay?');">
                    <input type="hidden" name="id" value="<%= d.getDeviceId() %>">
                    <button type="submit" class="link danger">Xoa</button>
                </form>
            </td>
        </tr>
        <% } %>
        <% if (rows == null || rows.isEmpty()) { %>
        <tr><td colspan="7" class="c">Khong co thiet bi nao khop bo loc</td></tr>
        <% } %>
    </table>

    <div class="pager">
        <% for (int p = 1; p <= totalPages; p++) { %>
            <% if (p == currentPage) { %><b><%= p %></b>
            <% } else { %><a href="?<%= qs %>&page=<%= p %>"><%= p %></a><% } %>
        <% } %>
    </div>
</div>
</body>
</html>
