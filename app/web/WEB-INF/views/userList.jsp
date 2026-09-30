<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.List, model.AppUser, model.AppRole, util.Web" %>
<%
    List<AppUser> rows = (List<AppUser>) request.getAttribute("rows");
    List<AppRole> roles = (List<AppRole>) request.getAttribute("roles");
    AppUser me = (AppUser) session.getAttribute("user");
    String ctx = request.getContextPath();

    String keyword = (String) request.getAttribute("keyword");
    Integer roleId = (Integer) request.getAttribute("roleId");
    String lockState = (String) request.getAttribute("lockState");
    Integer currentPage = (Integer) request.getAttribute("page");
    Integer totalPages  = (Integer) request.getAttribute("pages");
    if (currentPage == null) currentPage = 1;
    if (totalPages  == null) totalPages  = 1;

    String qs = "keyword=" + Web.esc(keyword)
              + "&roleId=" + (roleId == null ? "" : roleId.toString())
              + "&lockState=" + Web.esc(lockState);
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Users</title>
    <link rel="stylesheet" href="<%= ctx %>/css/app.css">
</head>
<body>
<jsp:include page="/WEB-INF/views/nav.jsp"/>
<div class="wrap">
    <h2>Nguoi dung (<%= request.getAttribute("total") %>)</h2>

    <form class="filter" method="get" action="<%= ctx %>/admin/users">
        <input type="text" name="keyword" placeholder="Ten dang nhap, ho ten"
               value="<%= Web.esc(keyword) %>">
        <select name="roleId">
            <option value="">-- Moi vai tro --</option>
            <% for (AppRole r : roles) { %>
            <option value="<%= r.getRoleId() %>"
                <%= (roleId != null && roleId.intValue() == r.getRoleId()) ? "selected" : "" %>>
                <%= Web.esc(r.getRoleCode()) %></option>
            <% } %>
        </select>
        <select name="lockState">
            <option value="">-- Moi trang thai --</option>
            <option value="ACTIVE" <%= "ACTIVE".equals(lockState) ? "selected" : "" %>>Dang dung</option>
            <option value="LOCKED" <%= "LOCKED".equals(lockState) ? "selected" : "" %>>Da khoa</option>
        </select>
        <button type="submit">Loc</button>
        <a class="btn ghost" href="<%= ctx %>/admin/users">Bo loc</a>
        
        <a class="btn" href="<%= ctx %>/admin/users/create">Them nguoi dung</a>
    </form>

    <table class="grid">
        <tr>
            <th>ID</th><th>Ten dang nhap</th><th>Ho ten</th>
            <th>Vai tro</th><th class="c">Trang thai</th><th>Thao tac</th>
        </tr>
        <% for (AppUser u : rows) { %>
        <tr class="<%= u.isLocked() ? "locked" : "" %>">
            <td><%= u.getUserId() %></td>
            <td><%= Web.esc(u.getUsername()) %></td>
            <td><%= Web.esc(u.getFullName()) %></td>
            <td><span class="tag"><%= Web.esc(u.getRoleCode()) %></span></td>
            <td class="c"><%= u.isLocked() ? "Da khoa" : "Dang dung" %></td>
            <td class="ops">
                <a href="<%= ctx %>/admin/users/edit?id=<%= u.getUserId() %>">Sua</a>
                
                <% if (me.getUserId() != u.getUserId()) { %>
                    <form method="post" action="<%= ctx %>/admin/users/lock">
                        <input type="hidden" name="id" value="<%= u.getUserId() %>">
                        <button type="submit" class="link"><%= u.isLocked() ? "Mo khoa" : "Khoa" %></button>
                    </form>
                <% } %>
                
                <form method="post" action="<%= ctx %>/admin/users/reset"
                      onsubmit="return confirm('Dat lai mat khau ve 123456?');">
                    <input type="hidden" name="id" value="<%= u.getUserId() %>">
                    <button type="submit" class="link">Dat lai mat khau</button>
                </form>
                
                <% if (me.getUserId() != u.getUserId()) { %>
                    <form method="post" action="<%= ctx %>/admin/users/delete"
                          onsubmit="return confirm('Xoa tai khoan nay?');">
                        <input type="hidden" name="id" value="<%= u.getUserId() %>">
                        <button type="submit" class="link danger">Xoa</button>
                    </form>
                <% } %>
            </td>
        </tr>
        <% } %>
        <% if (rows.isEmpty()) { %>
        <tr><td colspan="6" class="c">Khong co dong nao khop bo loc</td></tr>
        <% } %>
    </table>

    <div class="pager">
        <% for (int p = 1; p <= totalPages; p++) { %>
            <% if (p == currentPage) { %><b><%= p %></b>
            <% } else { %><a href="?<%= qs %>&page=<%= p %>"><%= p %></a><% } %>
        <% } %>
    </div>
</div>
</body>
</html>
