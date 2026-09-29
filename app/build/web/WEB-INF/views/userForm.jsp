<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.List, model.AppUser, model.AppRole, util.Web" %>
<%
    AppUser item = (AppUser) request.getAttribute("editUser");
    List<AppRole> roles = (List<AppRole>) request.getAttribute("roles");
    String error = (String) request.getAttribute("error");
    String ctx = request.getContextPath();
    boolean isNew = (item == null || item.getUserId() == 0);
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title><%= isNew ? "Them nguoi dung" : "Sua nguoi dung" %></title>
    <link rel="stylesheet" href="<%= ctx %>/css/app.css">
</head>
<body>
<jsp:include page="/WEB-INF/views/nav.jsp"/>
<div class="wrap">
    <h2><%= isNew ? "Them nguoi dung" : "Sua nguoi dung" %></h2>

    <% if (error != null) { %><div class="error"><%= Web.esc(error) %></div><% } %>

    <form class="form" method="post" action="<%= ctx %>/admin/users/save">
        <input type="hidden" name="userId" value="<%= isNew ? 0 : item.getUserId() %>">

        <label>Ten dang nhap</label>
        <input type="text" name="username" required minlength="3"
               value="<%= item == null ? "" : Web.esc(item.getUsername()) %>">

        <label>Ho ten</label>
        <input type="text" name="fullName" required
               value="<%= item == null ? "" : Web.esc(item.getFullName()) %>">

        <label>Vai tro</label>
        <select name="roleId" required>
            <% for (AppRole r : roles) { %>
            <option value="<%= r.getRoleId() %>"
                <%= (item != null && item.getRoleId() == r.getRoleId()) ? "selected" : "" %>>
                <%= Web.esc(r.getRoleCode()) %> &mdash; <%= Web.esc(r.getRoleName()) %></option>
            <% } %>
        </select>

        <div class="actions">
            <button type="submit" class="primary">Luu thong tin</button>
            <a href="<%= ctx %>/admin/users" class="btn ghost">Huy bo</a>
        </div>
    </form>
</div>
</body>
</html>
