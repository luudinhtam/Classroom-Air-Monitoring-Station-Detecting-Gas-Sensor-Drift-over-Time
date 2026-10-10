<%@page import="java.time.format.DateTimeFormatter"%>
<%@page import="java.util.List"%>
<%@page import="model.AppUser"%>
<%@page import="util.Web"%>
<%@page import="model.EmptyWindow"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>

<%
    EmptyWindow item = (EmptyWindow) request.getAttribute("editEmptyWindow");
    String error = (String) request.getAttribute("error");
    Integer stationId = (Integer) request.getAttribute("stationId");
    String ctx = request.getContextPath();

    boolean isNew = (item == null || item.getEmptyWindowId() == 0);

    DateTimeFormatter dateTimeFormatter = DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm");

    String startAt = "";
    String endAt = "";

    if (item != null) {
        if (item.getStartAt() != null) {
            startAt = item.getStartAt().format(dateTimeFormatter);
        }

        if (item.getEndAt() != null) {
            endAt = item.getEndAt().format(dateTimeFormatter);
        }
    }
%>

<!DOCTYPE html>
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <title><%= isNew ? "Them khoang phong trong" : "Sua khoang phong trong" %></title>
        <link rel="stylesheet" href="<%= ctx %>/css/app.css">
    </head>

    <body>
        <jsp:include page="/WEB-INF/views/nav.jsp"/>
        <div class="wrap">
            <h2><%= isNew ? "Them khoang phong trong" : "Sua khoang phong trong" %> cho stationId: <%= stationId %></h2>

            <% if (error != null) { %>
                <div class="error"><%= Web.esc(error) %></div>
            <% } %>

            <form class="form" method="post" 
                  action="<%= ctx %>/admin/emptyWindows/save?stationId=<%= stationId %>">

                <input type="hidden" name="emptyWindowId" value="<%= isNew ? 0 : item.getEmptyWindowId() %>">

                <label>Code</label>
                <input type="text" name="code" required minlength="3"
                       <%= !isNew ? "readonly style=\"opacity:.55;cursor:not-allowed;\"" : "" %>
                       value="<%= item == null ? "" : Web.esc(item.getCode()) %>">
                <% if (!isNew) { %>
                    <small style="color:#888">Code khoang phong trong khong the thay doi sau khi tao.</small>
                <% } %>

                <label>Name</label>
                <input type="text" name="name" required value="<%= item == null ? "" : Web.esc(item.getName()) %>">

                <label>Start at</label>
                <input type="datetime-local" name="startAt" required value="<%= startAt %>">

                <label>End at</label>
                <input type="datetime-local" name="endAt" required value="<%= endAt %>">
                <small style="color:#888"> Thoi gian ket thuc phai sau thoi gian bat dau.</small>

                <label>Marked by</label>
                <select name="userId" required>
                    <option value="">
                        -- Chọn người đánh dấu --
                    </option>

                    <%
                        List<AppUser> emptyWindowUsers = (List<AppUser>) request.getAttribute("emptyWindowUsers");

                        int markedBy = item == null ? 0 : item.getMarkedBy();
                        if (emptyWindowUsers != null) {
                            for (AppUser u : emptyWindowUsers) {
                    %>
                        <option value="<%= u.getUserId() %>"
                                <%= u.getUserId() == markedBy ? "selected" : "" %>>
                            <%= Web.esc(u.getUsername()) %>
                        </option>
                    <%
                            }
                        }
                    %>
                </select>

                <label>Note</label>
                <input type="text" name="note" value="<%= item == null ? "" : Web.esc(item.getNote()) %>">

                <div class="actions">
                    <button type="submit" class="primary">
                        Luu thong tin
                    </button>

                    <a href="<%= ctx %>/admin/emptyWindows?stationId=<%= stationId %>" class="btn ghost">
                        Huy bo
                    </a>
                </div>
            </form>
        </div>
    </body>
</html>