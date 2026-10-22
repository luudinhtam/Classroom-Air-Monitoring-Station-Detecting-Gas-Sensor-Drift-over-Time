<%@page import="util.Web"%>
<%@page import="model.Room"%>
<%@page import="java.util.List"%>
<%@page import="model.AppUser"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    List<Room> rows = (List<Room>) request.getAttribute("rows");
    String keyword = (String) request.getAttribute("keyword");
    String status = (String) request.getAttribute("status");
    String ctx = request.getContextPath();
    
    // Khởi tạo cờ kiểm tra quyền quản lý phòng (Admin, Station Manager, Operator)
    AppUser me = (AppUser) session.getAttribute("user");
    String myRole = (me != null) ? me.getRoleCode() : "";
    boolean canManageRoom = "ADMIN".equals(myRole) || "STATION_MANAGER".equals(myRole) || "OPERATOR".equals(myRole);
%>
<!DOCTYPE html>
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Rooms</title>
        <link rel="stylesheet" href="<%= ctx %>/assets/css/app.css?v=2">
    </head>
    
    <body>
        <jsp:include page="/WEB-INF/views/nav.jsp"/>
        <div class="wrap">
            <h2>Rooms (<%= request.getAttribute("total") %>)</h2>
            
            <form class="filter" method="get" action="<%= ctx %>/admin/rooms">
                <input type="text" name="keyword" placeholder="Room name..."
                       value="<%= Web.esc(keyword) %>">
                <select name="status">
                    <option value="">-- All Statuses --</option>
                    <option value="ACTIVE" <%= "ACTIVE".equals(status) ? "selected" : "" %>>Active</option>
                    <option value="INACTIVE" <%= "INACTIVE".equals(status) ? "selected" : "" %>>Inactive</option>
                </select>
                <button type="submit">Filter</button>
                <a class="btn ghost" href="<%= ctx %>/admin/rooms">Reset</a>

                <% if (canManageRoom) { %>
                    <a class="btn" href="<%= ctx %>/admin/rooms/create">+ Add Room</a>
                <% } %>
            </form>
            
            <div class="table-responsive">
            <table class="grid">
                <tr>
                    <th>#</th>
                    <th>Room Code</th>
                    <th>Room Name</th>
                    <th>Location</th>
                    <th>Note</th>
                    <th class="c">Status</th>
                    <th>Actions</th>
                </tr>
                
                <% for (Room r : rows) { %>
                    <tr class="<%= r.isActive() ? "Active" : "Inactive" %>"
                            style="<%= r.isActive() ? "" : "background-color: #fdf3f3;" %>">
                    <td><%= r.getRoomId() %></td>
                    <td><%= Web.esc(r.getCode()) %></td>
                    <td><%= Web.esc(r.getName()) %></td>
                    <td><%= Web.esc(r.getLocation()) %></td>
                    <td><%= Web.esc(r.getNote()) %></td>
                    
                    <td class="c"><%= r.isActive() ? "Active" : "Inactive" %></td>
                    
                    <td class="ops ops-group">
                        <% if (canManageRoom) { %>
                            <button type="button" class="btn-block btn-blue"
                                    onclick="window.location.href='<%= ctx %>/admin/rooms/edit?id=<%= r.getRoomId() %>'">
                                Edit
                            </button>

                            <form method="post" action="<%= ctx %>/admin/rooms/lock">
                                <input type="hidden" name="id" value="<%= r.getRoomId() %>">
                                <button type="submit" class="btn-block <%= r.isActive() ? "btn-orange" : "btn-green" %>">
                                    <%= r.isActive() ? "Deactivate" : "Activate" %>
                                </button>
                            </form>
                        <% } %>

                        <button type="button" class="btn-block btn-gray"
                                onclick="window.location.href='<%= ctx %>/admin/rooms/detail?id=<%= r.getRoomId() %>'">
                            Details
                        </button>

                        <% if (canManageRoom) { %>
                            <form method="post" action="<%= ctx %>/admin/rooms/delete"
                                  onsubmit="return confirm('Delete this room?');">
                                <input type="hidden" name="id" value="<%= r.getRoomId() %>">
                                <button type="submit" class="btn-block btn-red">Delete</button>
                            </form>
                        <% } %>

                        <button type="button" class="btn-block btn-gray"
                                onclick="window.location.href='<%= ctx %>/admin/calibrations?roomId=<%= r.getRoomId() %>'">
                            Calibrations
                        </button>

                        <button type="button" class="btn-block btn-gray"
                                onclick="window.location.href='<%= ctx %>/admin/emptyWindows?roomId=<%= r.getRoomId() %>'">
                            Empty Windows
                        </button>
                    </td>
                </tr>
                <% } %>
                
                <% if (rows.isEmpty()) { %>
                    <tr><td colspan="7" class="c">No rooms match the filter</td></tr>
                <% } %>
            </table>
            </div>
            
        </div>
    </body>
</html>
