<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="util.Web" %>
<% String error = (String) request.getAttribute("error");%>

<!DOCTYPE html>
<html>
    <head>
        <meta charset="UTF-8">
        <title>Airroom – Sign in</title>

        <link rel="stylesheet" href="<%= request.getContextPath() %>/css/login.css">
    </head>

    <body>

        <div class="login-page">

            <form class="login-box"
                  method="post"
                  action="<%= request.getContextPath()%>/login">

                <!-- Logo -->
                <div class="logo">
                    <div class="logo-icon">
                        <div class="blue"></div>
                        <div class="orange"></div>
                        <div class="red"></div>
                    </div>

                    <div class="logo-text">
                        Airroom<span>™</span>
                    </div>
                </div>

                <h1>Login</h1>

                <% if (error != null) {%>
                <div class="error-alert">
                    <div class="error-icon">!</div>
                    <div class="error-text">
                        <%= error.equalsIgnoreCase("Sai ten dang nhap hoac mat khau") ? "Invalid Username or Password" : Web.esc(error)%>
                    </div>
                </div>
                <% }%>

                <label for="username">Username</label>

                <input
                    type="text"
                    id="username"
                    name="username"
                    placeholder="e.g username"
                    autofocus
                    required
                    >

                <div class="password-group">
                    <label for="password">Password</label>

                    <input
                        type="password"
                        id="password"
                        name="password"
                        placeholder="password"
                        required
                        >
                </div>

                <div class="login-footer">
                    <button type="submit">
                        Login
                    </button>
                </div>

            </form>

        </div>

    </body>
</html>