<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="model.AppUser, util.Web" %>
<%
    AppUser me = (AppUser) session.getAttribute("user");
    String ctx = request.getContextPath();
    String flash = (String) session.getAttribute("flash");
    if (flash != null) session.removeAttribute("flash");
    String flashError = (String) session.getAttribute("flashError");
    if (flashError != null) session.removeAttribute("flashError");
%>
<div class="topbar">
    <div class="brand">Airroom <span class="sem">FALL2026</span></div>
    <div class="who">
        <%= Web.esc(me.getFullName()) %>
        <span class="tag" style="color: black"><%= Web.esc(me.getRoleCode()) %></span>
        <a class="out" href="<%= ctx %>/logout">Logout</a>
    </div>
</div>
<div class="menu">
    <a href="<%= ctx %>/dashboard">Dashboard</a>
    <a href="<%= ctx %>/sessions">Sessions</a>
    <a href="<%= ctx %>/alerts">Alert</a>
    <% if ("ADMIN".equals(me.getRoleCode())) { %>
        <a href="<%= ctx %>/admin/users">Users</a>
        <a href="<%= ctx %>/admin/devices">Devices</a>
        <a href="<%= ctx %>/admin/stations">Stations</a>
    <% } %>
</div>
<% if (flash != null) { %>
    <div class="flash"><%= Web.esc(flash) %></div>
<% } %>
<% if (flashError != null) { %>
    <div class="error" style="max-width: 1120px; margin: 12px auto 0;"><%= Web.esc(flashError) %></div>
<% } %>
