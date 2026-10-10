

<%@page import="util.Web"%>
<%@page import="model.AirStation"%>
<%@page import="java.util.List"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    List<AirStation> rows = (List<AirStation>) request.getAttribute("rows");
    String keyword = (String) request.getAttribute("keyword");
    String status = (String) request.getAttribute("status");
    String ctx = request.getContextPath();
%>
<!DOCTYPE html>
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <title>Stations</title>
        <link rel="stylesheet" href="<%= ctx %>/css/app.css">
    </head>
    
    <body>
        <jsp:include page="/WEB-INF/views/nav.jsp"/>
        <div class="wrap">
            <h2>Stations (<%= request.getAttribute("total") %>)</h2>
            
            <form class="filter" method="get" action="<%= ctx %>/admin/stations">
                <input type="text" name="keyword" placeholder="Ten tram"
                       value="<%= Web.esc(keyword) %>">
                <select name="status">
                    <option value="">-- Moi trang thai --</option>
                    <option value="ACTIVE" <%= "ACTIVE".equals(status) ? "selected" : "" %>>Active</option>
                    <option value="INACTIVE" <%= "INACTIVE".equals(status) ? "selected" : "" %>>Inactive</option>
                </select>
                <button type="submit">Loc</button>
                <a class="btn ghost" href="<%= ctx %>/admin/stations">Bo loc</a>

                <a class="btn" href="<%= ctx %>/admin/stations/create">Them tram</a>
            </form>
            
            <table class="grid">
                <tr>
                    <th>#</th>
                    <th>Ma tram</th>
                    <th>Ten tram</th>
                    <th>Dia chi</th>
                    <th>Ghi chu</th>
                    <th class="c">Trang thai</th>
                    <th>Thao tac</th>
                </tr>
                
                <% for (AirStation a : rows) { %>
                <tr class="<%= a.isActive() ? "Active" : "Inactive" %>">
                    <td><%= a.getStationId() %></td>
                    <td><%= Web.esc(a.getCode()) %></td>
                    <td><%= Web.esc(a.getName()) %></td>
                    <td><%= Web.esc(a.getLocation()) %></td>
                    <td><%= Web.esc(a.getNote()) %></td>
                    
                    <td class="c"><%= a.isActive() ? "Active" : "Inactive" %></td>
                    <td class="ops">
                        <a href="<%= ctx %>/admin/stations/edit?id=<%= a.getStationId() %>">Sua</a>

                        
                        <form method="post" action="<%= ctx %>/admin/stations/lock">
                            <input type="hidden" name="id" value="<%= a.getStationId() %>">
                            <button type="submit" class="link"><%= a.isActive() ? "Tat" : "Mo" %></button>
                        </form>

                        <a href="<%= ctx %>/admin/stations/detail?id=<%= a.getStationId() %>">Chi tiet</a>
                        
                        <form method="post" action="<%= ctx %>/admin/stations/delete"
                                onsubmit="return confirm('Xoa tram nay?');">
                            <input type="hidden" name="id" value="<%= a.getStationId() %>">
                            <button type="submit" class="link danger">Xoa</button>
                        </form>
                            
                        <a href="<%= ctx %>/admin/calibrations?stationId=<%= a.getStationId() %>">Hieu chuan</a>
                        <a href="<%= ctx %>/admin/emptyWindows?stationId=<%= a.getStationId() %>">Khoang trong</a>
                        
                    </td>
                </tr>
                <% } %>
                
                <% if (rows.isEmpty()) { %>
                    <tr><td colspan="7" class="c">Khong co dong nao khop bo loc</td></tr>
                <% } %>
            </table>
            
        </div>
    </body>
</html>
