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
<link rel="shortcut icon" href="<%= ctx %>/favicon.ico" type="image/x-icon">
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
          <a href="https://www.tinkercad.com/things/4THaogXGuYY/edit?returnTo=%2Fdashboard&export=drive&sharecode=aflFzA5etyZjCrmYvCcFj38-V-5jQ3_pAHfEKWGcoOU" target="_blank" rel="noopener noreferrer" style="
            display: inline-flex;
            align-items: center;
            gap: 6px;
            background: #ffffff;
            color: #059669;
            font-weight: 600;
            padding: 5px 14px;
            border-radius: 20px;
            border: 1.5px solid #059669;
            text-decoration: none;
            transition: all 0.2s;
        " title="View 3D Model">
            📦 3D Model
        </a>
        
         <a href="<%= ctx %>/map" class="nav-map-btn" style="
        display: inline-flex;
        align-items: center;
        gap: 6px;
        background: #ffffff;
        color: #2563eb;
        font-weight: 600;
        padding: 5px 14px;
        border-radius: 20px;
        border: 1.5px solid #2563eb;
        text-decoration: none;
        transition: all 0.2s;
    ">
        🗺️ Map
    </a>
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
    
    (function() {
    let link = document.querySelector("link[rel*='icon']") || document.createElement('link');
    link.type = 'image/x-icon';
    link.rel = 'shortcut icon';
    link.href = '<%= request.getContextPath() %>/favicon.ico?v=2';
    document.getElementsByTagName('head')[0].appendChild(link);
})();
</script>