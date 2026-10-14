<%@page import="util.Web"%>
<%@page import="model.AirStation"%>
<%@page import="java.util.List"%>
<%@page import="model.AppUser"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    List<AirStation> rows = (List<AirStation>) request.getAttribute("rows");
    String keyword = (String) request.getAttribute("keyword");
    String status = (String) request.getAttribute("status");
    String ctx = request.getContextPath();
    
    // Khởi tạo cờ kiểm tra quyền quản lý trạm (Admin, Station Manager, Operator)
    AppUser me = (AppUser) session.getAttribute("user");
    String myRole = (me != null) ? me.getRoleCode() : "";
    boolean canManageStation = "ADMIN".equals(myRole) || "STATION_MANAGER".equals(myRole) || "OPERATOR".equals(myRole);
%>
<!DOCTYPE html>
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <title>Stations</title>
        <link rel="stylesheet" href="<%= ctx %>/css/app.css?v=2">
    </head>
    
    <body>
        <jsp:include page="/WEB-INF/views/nav.jsp"/>
        <div class="wrap">
            <h2>Stations (<%= request.getAttribute("total") %>)</h2>
            
            <form class="filter" method="get" action="<%= ctx %>/admin/stations">
                <input type="text" name="keyword" placeholder="Station name..."
                       value="<%= Web.esc(keyword) %>">
                <select name="status">
                    <option value="">-- All Statuses --</option>
                    <option value="ACTIVE" <%= "ACTIVE".equals(status) ? "selected" : "" %>>Active</option>
                    <option value="INACTIVE" <%= "INACTIVE".equals(status) ? "selected" : "" %>>Inactive</option>
                </select>
                <button type="submit">Filter</button>
                <a class="btn ghost" href="<%= ctx %>/admin/stations">Reset</a>

                <% if (canManageStation) { %>
                    <a class="btn" href="<%= ctx %>/admin/stations/create">+ Add Station</a>
                <% } %>
            </form>
            
            <table class="grid">
                <tr>
                    <th>#</th>
                    <th>Station Code</th>
                    <th>Station Name</th>
                    <th>Location</th>
                    <th>Note</th>
                    <th class="c">Status</th>
                    <th>Actions</th>
                </tr>
                
                <% for (AirStation a : rows) { %>
                    <tr class="<%= a.isActive() ? "Active" : "Inactive" %>"
                            style="<%= a.isActive() ? "" : "background-color: #fdf3f3;" %>">
                    <td><%= a.getStationId() %></td>
                    <td><%= Web.esc(a.getCode()) %></td>
                    <td><%= Web.esc(a.getName()) %></td>
                    <td><%= Web.esc(a.getLocation()) %></td>
                    <td><%= Web.esc(a.getNote()) %></td>
                    
                    <td class="c"><%= a.isActive() ? "Active" : "Inactive" %></td>
                    
                    <td class="ops ops-group">
                        <% if (canManageStation) { %>
                            <button type="button" class="btn-block btn-blue"
                                    onclick="window.location.href='<%= ctx %>/admin/stations/edit?id=<%= a.getStationId() %>'">
                                Edit
                            </button>

                            <form method="post" action="<%= ctx %>/admin/stations/lock">
                                <input type="hidden" name="id" value="<%= a.getStationId() %>">
                                <button type="submit" class="btn-block <%= a.isActive() ? "btn-orange" : "btn-green" %>">
                                    <%= a.isActive() ? "Deactivate" : "Activate" %>
                                </button>
                            </form>
                        <% } %>

                        <button type="button" class="btn-block btn-gray"
                                onclick="window.location.href='<%= ctx %>/admin/stations/detail?id=<%= a.getStationId() %>'">
                            Details
                        </button>

                        <% if (canManageStation) { %>
                            <form method="post" action="<%= ctx %>/admin/stations/delete"
                                  onsubmit="return confirm('Delete this station?');">
                                <input type="hidden" name="id" value="<%= a.getStationId() %>">
                                <button type="submit" class="btn-block btn-red">Delete</button>
                            </form>
                        <% } %>

                        <button type="button" class="btn-block btn-gray"
                                onclick="window.location.href='<%= ctx %>/admin/calibrations?stationId=<%= a.getStationId() %>'">
                            Calibrations
                        </button>

                        <button type="button" class="btn-block btn-gray"
                                onclick="window.location.href='<%= ctx %>/admin/emptyWindows?stationId=<%= a.getStationId() %>'">
                            Empty Windows
                        </button>
                    </td>
                </tr>
                <% } %>
                
                <% if (rows.isEmpty()) { %>
                    <tr><td colspan="7" class="c">No stations match the filter</td></tr>
                <% } %>
            </table>
            
        </div>
    </body>
</html>