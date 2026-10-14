<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="model.AppUser, util.Web" %>
<%
    AppUser me = (AppUser) session.getAttribute("user");
    String ctx = request.getContextPath();
    String flash = (String) session.getAttribute("flash");
    if (flash != null) session.removeAttribute("flash");
    String flashError = (String) session.getAttribute("flashError");
    if (flashError != null) session.removeAttribute("flashError");
    
    // Khởi tạo cờ phân quyền
    String myRole = (me != null) ? me.getRoleCode() : "";
    boolean isAdmin = "ADMIN".equals(myRole);
%>
<div class="topbar">
    <div class="brand">Airroom <span class="sem">FALL2026</span></div>
    <div class="who">
        <%= Web.esc(me.getFullName()) %>
        <span class="tag" style="color: black"><%= Web.esc(myRole) %></span>
        <a class="out" href="<%= ctx %>/logout">Logout</a>
    </div>
</div>
<div class="menu">
    <a href="<%= ctx %>/dashboard">Dashboard</a>
    <a href="<%= ctx %>/sessions">Sessions</a>
    <a href="<%= ctx %>/alerts">Alerts</a>
    
    <!-- Mọi vai trò đều có quyền Xem (R) Trạm nên không ẩn menu này -->
    <a href="<%= ctx %>/admin/stations">Stations</a>
    
    <!-- Chỉ ADMIN mới được xem menu Quản lý Users và Devices -->
    <% if (isAdmin) { %>
        <a href="<%= ctx %>/admin/users">Users</a>
        <a href="<%= ctx %>/admin/devices">Devices</a>
    <% } %>
</div>
<% if (flash != null) { %><div class="flash"><%= Web.esc(flash) %></div><% } %>
<% if (flashError != null) { %><div class="error" style="max-width: 1120px; margin: 12px auto 0;"><%= Web.esc(flashError) %></div><% } %>