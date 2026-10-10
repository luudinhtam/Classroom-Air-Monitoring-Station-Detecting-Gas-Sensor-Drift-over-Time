<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="model.AppUser, util.Web" %>
<%
    AppUser me = (AppUser) session.getAttribute("user");
    String ctx = request.getContextPath();
    String flash = (String) session.getAttribute("flash");
    if (flash != null) session.removeAttribute("flash");
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
    <% if ("ADMIN".equals(me.getRoleCode())) { %>
        <a href="<%= ctx %>/admin/users">Users</a>
        <a href="<%= ctx %>/admin/stations">Stations</a>
    <% } %>
</div>
<% if (flash != null) { %>
    <div class="flash"><%= Web.esc(flash) %></div>
<% } %>
