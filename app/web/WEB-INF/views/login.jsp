<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="util.Web" %>
<% String error = (String) request.getAttribute("error"); %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Airroom – Sign in</title>
    <link rel="stylesheet" href="<%= request.getContextPath() %>/css/app.css">
</head>
<body class="login-page">
<form class="login-box" method="post" action="<%= request.getContextPath() %>/login">
    <h1>Airroom</h1>
    <p class="sub">Tram theo doi khong khi phong hoc</p>

    <% if (error != null) { %>
        <div class="error"><%= Web.esc(error) %></div>
    <% } %>

    <label>Username</label>
    <input type="text" name="username" autofocus required>

    <label>Password</label>
    <input type="password" name="password" required>

    <button type="submit">Sign in</button>

    <p class="hint">
        Tai khoan mau: admin, station_manager, operator, reviewer, viewer <br>
        Mat khau deu la 123456
    </p>
</form>
</body>
</html>
