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
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><%= isNew ? "Add Device" : "Edit Device" %></title>
    <link rel="stylesheet" href="<%= ctx %>/css/app.css">
</head>
<body>
<jsp:include page="/WEB-INF/views/nav.jsp"/>
<div class="wrap">
    <h2><%= isNew ? "Add Device" : "Edit Device" %></h2>

    <% if (error != null) { %><div class="error"><%= Web.esc(error) %></div><% } %>

    <form class="form" method="post" action="<%= ctx %>/admin/devices/save">
        <input type="hidden" name="deviceId" value="<%= isNew ? 0 : item.getDeviceId() %>">

        <label>Device Code</label>
        <input type="text" name="deviceCode" required minlength="3" maxlength="32"
                <%= !isNew ? "readonly style=\"opacity:.55;cursor:not-allowed;\"" : "" %>
                value="<%= item == null ? "" : Web.esc(item.getDeviceCode()) %>">
            <% if (!isNew) { %>
            <% } %>

        <label>API Key</label>
        <input type="text" name="apiKey" required maxlength="64"
               value="<%= item == null ? "" : Web.esc(item.getApiKey()) %>">

        <label>Location</label>
        <input type="text" name="location" maxlength="150" placeholder="e.g. Lab Bench #1"
               value="<%= item == null || item.getLocation() == null ? "" : Web.esc(item.getLocation()) %>">

        <label>Status</label>
        <select name="isActive">
            <option value="true" <%= (item == null || item.isIsActive()) ? "selected" : "" %>>Active</option>
            <option value="false" <%= (item != null && !item.isIsActive()) ? "selected" : "" %>>Inactive</option>
        </select>

        <div class="actions">
            <button type="submit" class="primary">Save</button>
            <a href="<%= ctx %>/admin/devices" class="btn ghost">Cancel</a>
        </div>
    </form>
</div>
</body>
</html>
