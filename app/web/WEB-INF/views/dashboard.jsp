<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="model.AppUser, util.Web" %>
<%
    AppUser me = (AppUser) session.getAttribute("user");
    String ctx = request.getContextPath();

    // Các thống kê sẽ do DashboardServlet set vào request attribute.
    // Nếu chưa có, hiển thị "–" thay vì báo lỗi null.
    Object totalSessions = request.getAttribute("totalSessions");
    Object totalAlerts   = request.getAttribute("totalAlerts");
    Object totalDrifted  = request.getAttribute("totalDrifted");
    Object totalDevices  = request.getAttribute("totalDevices");
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Airroom – Dashboard</title>
    <link rel="stylesheet" href="<%= ctx %>/css/app.css">
</head>
<body>
<jsp:include page="/WEB-INF/views/nav.jsp"/>
<div class="wrap">
    <h2>Dashboard – Tram theo doi khong khi</h2>

    <div class="cards">
        <div class="card">
            <div class="num"><%= totalSessions != null ? totalSessions : "–" %></div>
            <div class="cap">Tong phien do</div>
        </div>
        <div class="card">
            <div class="num"><%= totalAlerts != null ? totalAlerts : "–" %></div>
            <div class="cap">Canh bao hom nay</div>
        </div>
        <div class="card">
            <div class="num"><%= totalDrifted != null ? totalDrifted : "–" %></div>
            <div class="cap">Phien DRIFTED</div>
        </div>
        <div class="card">
            <div class="num"><%= totalDevices != null ? totalDevices : "–" %></div>
            <div class="cap">Thiet bi ket noi</div>
        </div>
    </div>

    <h3>Bieu do phan bo nhan (7 ngay gan nhat)</h3>
    <canvas id="labelChart" width="720" height="240"></canvas>

    <h3>Tro chuyen nhanh</h3>
    <div class="quick-links">
        <a class="btn" href="<%= ctx %>/sessions">Xem danh sach phien</a>
        <% if ("REVIEWER".equals(me.getRoleCode()) || "ADMIN".equals(me.getRoleCode())) { %>
            <a class="btn ghost" href="<%= ctx %>/sessions?label=DRIFTED">Loc DRIFTED</a>
            <a class="btn ghost" href="<%= ctx %>/sessions?label=HIGH">Loc HIGH</a>
        <% } %>
    </div>

</div>

<script src="<%= ctx %>/js/app.js"></script>
<script>
    // Placeholder – DashboardServlet se set ra JSON cac nhan va so luong
    var labels = <%= request.getAttribute("chartLabels") != null
                   ? request.getAttribute("chartLabels") : "['BASE','RAISED','HIGH','DRIFTED','TEMP_EFFECT','WARMUP']" %>;
    var values = <%= request.getAttribute("chartValues") != null
                   ? request.getAttribute("chartValues") : "[0,0,0,0,0,0]" %>;
    if (typeof drawBars === 'function') {
        drawBars('labelChart', labels, values);
    }
</script>
</body>
</html>
