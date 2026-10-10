<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="model.Device, util.Web" %>
<%
    Device item = (Device) request.getAttribute("editDevice");
    String error = (String) request.getAttribute("error");
    String ctx = request.getContextPath();
    boolean isNew = (item == null || item.getDeviceId() == 0);
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title><%= isNew ? "Them thiet bi" : "Sua thiet bi" %></title>
    <link rel="stylesheet" href="<%= ctx %>/css/app.css">
</head>
<body>
<jsp:include page="/WEB-INF/views/nav.jsp"/>
<div class="wrap">
    <h2><%= isNew ? "Them thiet bi" : "Sua thiet bi" %></h2>

    <% if (error != null) { %><div class="error"><%= Web.esc(error) %></div><% } %>

    <form class="form" method="post" action="<%= ctx %>/admin/devices/save">
        <input type="hidden" name="deviceId" value="<%= isNew ? 0 : item.getDeviceId() %>">

        <label>Ma thiet bi (Device Code)</label>
        <input type="text" name="deviceCode" required minlength="3" maxlength="32"
                <%= !isNew ? "readonly style=\"opacity:.55;cursor:not-allowed;\"" : "" %>
                value="<%= item == null ? "" : Web.esc(item.getDeviceCode()) %>">
            <% if (!isNew) { %>
            <small style="color:#888">Ma thiet bi khong the thay doi sau khi tao.</small>
            <% } %>

        <label>API Key (Header X-API-Key thiet bi gui ve)</label>
        <input type="text" name="apiKey" required maxlength="64"
               value="<%= item == null ? "" : Web.esc(item.getApiKey()) %>">

        <label>Vi tri dat thiet bi (Location)</label>
        <input type="text" name="location" maxlength="150" placeholder="Vi du: Ban thuc hanh so 1"
               value="<%= item == null || item.getLocation() == null ? "" : Web.esc(item.getLocation()) %>">

        <label>Trang thai</label>
        <select name="isActive">
            <option value="true" <%= (item == null || item.isIsActive()) ? "selected" : "" %>>Hoat dong</option>
            <option value="false" <%= (item != null && !item.isIsActive()) ? "selected" : "" %>>Tam ngung</option>
        </select>

        <div class="actions">
            <button type="submit" class="primary">Luu thong tin</button>
            <a href="<%= ctx %>/admin/devices" class="btn ghost">Huy bo</a>
        </div>
    </form>
</div>
</body>
</html>
