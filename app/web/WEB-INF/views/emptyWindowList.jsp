<%@page import="java.time.format.DateTimeFormatter"%>
<%@page import="model.Room"%>
<%@page import="dao.RoomDAO"%>
<%@page import="util.Web"%>
<%@page import="model.EmptyWindow"%>
<%@page import="java.util.List"%>
<%@page import="model.AppUser"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>

<%
    List<EmptyWindow> rows = (List<EmptyWindow>) request.getAttribute("rows");
    Integer rIdObj = (Integer) request.getAttribute("roomId");
    int roomId = (rIdObj != null) ? rIdObj : (request.getAttribute("stationId") != null ? (Integer) request.getAttribute("stationId") : 0);
    int total = (int) request.getAttribute("total");
    String ctx = request.getContextPath();
    DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    RoomDAO rooms = new RoomDAO();
    Room r = rooms.findById(roomId);

    // Phân quyền hiển thị nút: Admin, Station Manager, Operator được quản lý; Reviewer/Viewer chỉ xem
    AppUser me = (AppUser) session.getAttribute("user");
    String myRole = (me != null) ? me.getRoleCode() : "";
    boolean canManageEmptyWindow = "ADMIN".equals(myRole) || "STATION_MANAGER".equals(myRole) || "OPERATOR".equals(myRole);
%>

<!DOCTYPE html>
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Room Empty Windows</title>
        <link rel="stylesheet" href="<%= ctx %>/assets/css/app.css">
    </head>

    <body>
        <jsp:include page="/WEB-INF/views/nav.jsp"/>
        <div class="wrap">
            <h2>
                Empty Windows for Room:
                <%= r != null ? (Web.esc(r.getCode()) + " / " + Web.esc(r.getName())) : ("ID: " + roomId) %>
                (<%= total %>)
            </h2>

            <form class="filter" method="get" action="<%= ctx %>/admin/emptyWindows">
                
                <input type="hidden" name="roomId" value="<%= roomId %>">

                <input type="text" name="keyword" placeholder="Empty window name..."
                       value="<%= request.getParameter("keyword") != null
                                     ? Web.esc(request.getParameter("keyword"))
                                     : "" %>">

                <button type="submit">Filter</button>

                <a class="btn ghost" href="<%= ctx %>/admin/emptyWindows?roomId=<%= roomId %>">
                    Reset
                </a>

                <% if (canManageEmptyWindow) { %>
                    <a class="btn" href="<%= ctx %>/admin/emptyWindows/create?roomId=<%= roomId %>">
                        + Add Empty Window
                    </a>
                <% } %>

                <a class="btn ghost" href="<%= ctx %>/admin/rooms">&larr; Rooms List</a>
            </form>

            <div class="table-responsive">
            <table class="grid">
                <tr>
                    <th>#</th>
                    <th>Code</th>
                    <th>Name</th>
                    <th>Start at</th>
                    <th>End at</th>
                    <th>Marked by</th>
                    <th>Created at</th>
                    <th>Note</th>
                    <% if (canManageEmptyWindow) { %>
                        <th>Actions</th>
                    <% } %>
                </tr>

                <% for (EmptyWindow ew : rows) { %>
                <tr>
                    <td><%= ew.getEmptyWindowId() %></td>

                    <td><%= Web.esc(ew.getCode()) %></td>

                    <td><%= Web.esc(ew.getName()) %></td>

                    <td><%= ew.getStartAt().format(formatter) %></td>

                    <td><%= ew.getEndAt().format(formatter) %></td>

                    <td><%= Web.esc(ew.getMarkedByUsername()) %></td>

                    <td><%= ew.getCreatedAt().format(formatter) %></td>

                    <td><%= Web.esc(ew.getNote()) %></td>

                    <% if (canManageEmptyWindow) { %>
                        <td class="ops ops-group">

                            <button type="button" class="btn-block btn-blue"
                                    onclick="window.location.href='<%= ctx %>/admin/emptyWindows/edit?id=<%= ew.getEmptyWindowId() %>&roomId=<%= roomId %>'">
                                Edit
                            </button>

                            <form method="post"
                                  action="<%= ctx %>/admin/emptyWindows/delete"
                                  onsubmit="return confirm('Delete this empty window?');" style="display:inline-block;">

                                <input type="hidden" name="emptyWindowId"
                                       value="<%= ew.getEmptyWindowId() %>">

                                <input type="hidden" name="roomId"
                                       value="<%= roomId %>">

                                <button type="submit" class="btn-block btn-red">
                                    Delete
                                </button>
                            </form>

                            <button type="button" class="btn-block btn-gray"
                                    onclick="window.location.href='<%= ctx %>/admin/emptyWindows/baseline?emptyWindowId=<%= ew.getEmptyWindowId() %>&roomId=<%= roomId %>'">
                                Calculate Baseline
                            </button>

                        </td>
                    <% } %>
                </tr>
                <% } %>
                <% if (rows.isEmpty()) { %>
                <tr>
                    <td colspan="<%= canManageEmptyWindow ? 9 : 8 %>" class="c">
                        No empty windows found
                    </td>
                </tr>
                <% } %>

            </table>
            </div>

        </div>

    </body>
</html>
