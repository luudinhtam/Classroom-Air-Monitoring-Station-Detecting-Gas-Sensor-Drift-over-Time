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

    <!-- Menu nằm đối xứng ở chính giữa thanh navbar -->
    <div class="menu" id="navMenu" style="background: transparent;">
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

    <div class="topbar-right">
        <div class="who">
            <%= Web.esc(me.getFullName()) %>
            <span class="tag" style="color: black"><%= Web.esc(myRole) %></span>
            <a class="out" href="<%= ctx %>/logout">Logout</a>
        </div>
        <button type="button" class="nav-toggle" id="navToggle" aria-label="Toggle navigation">
            <span></span>
            <span></span>
            <span></span>
        </button>
    </div>
</div>
<% if (flash != null) { %><div class="flash"><%= Web.esc(flash) %></div><% } %>
<% if (flashError != null) { %><div class="error" style="max-width: 1120px; margin: 12px auto 0;"><%= Web.esc(flashError) %></div><% } %>

<script>
    (function() {
        var toggle = document.getElementById('navToggle');
        var menu = document.getElementById('navMenu');
        if (toggle && menu) {
            toggle.addEventListener('click', function(e) {
                e.stopPropagation();
                menu.classList.toggle('open');
                toggle.classList.toggle('active');
            });
            // Tự động đóng menu khi bấm ra ngoài
            document.addEventListener('click', function(e) {
                if (!menu.contains(e.target) && !toggle.contains(e.target)) {
                    menu.classList.remove('open');
                    toggle.classList.remove('active');
                }
            });
        }
    })();
</script>