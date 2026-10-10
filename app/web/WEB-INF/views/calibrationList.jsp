

<%@page import="model.AirStation"%>
<%@page import="dao.AirStationDAO"%>
<%@page import="util.Web"%>
<%@page import="model.Calibration"%>
<%@page import="java.util.List"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>

<%
    List<Calibration> rows = (List<Calibration>) request.getAttribute("rows");
    int stationId = (int) request.getAttribute("stationId");
    int total = (int) request.getAttribute("total");
    String ctx = request.getContextPath();
    
    AirStationDAO stations = new AirStationDAO();
    AirStation a = stations.findById(stationId);
%>

<!DOCTYPE html>
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <title>Station Calibrations</title>
        <link rel="stylesheet" href="<%= ctx %>/css/app.css">
    </head>
    <body>
        <jsp:include page="/WEB-INF/views/nav.jsp"/>
        
        <div class="wrap">
            <h2>Lich su hieu chuan tram: <%= a.getCode() %> / <%= a.getName() %>  (<%= request.getAttribute("total") %>)</h2>
            <form class="filter" method="get" action="<%= ctx %>/admin/calibrations?stationId=<%= stationId %>">
                <input type="text" name="keyword" placeholder="Ten hieu chuan"
                       value="">
                
                <button type="submit">Loc</button>
                <a class="btn ghost" href="<%= ctx %>/admin/calibrations?stationId=<%= stationId %>">Bo loc</a>

                <a class="btn" href="<%= ctx %>/admin/calibrations/create?stationId=<%= stationId %>">Them hieu chuan</a>
                
                <a class="btn ghost" href="<%= ctx %>/admin/stations">Tro ve danh sach cac tram</a>
            </form>
            
            
            
            <table class="grid">
                <tr>
                    <th>#</th>
                    <th>Code</th>
                    <th>Name</th>
                    <th>CO Baseline</th>
                    <th>CO2 Baseline</th>
                    <th>Performed by</th>
                    <th>Calibrated at</th>
                    <th>Note</th>
                    <th>Thao tac</th>
                </tr>
                
                <% for (Calibration c : rows) { %>
                <tr>
                    <td><%= c.getCalibrationId()%></td>
                    <td><%= Web.esc(c.getCode()) %></td>
                    <td><%= Web.esc(c.getName()) %></td>
                    <td><%= c.getCoBaseLine() %></td>
                    <td><%= c.getCo2BaseLine() %></td>
                    <td><%= Web.esc(c.getPerformedByUsername()) %></td>
                    <td><%= c.getCalibratedAt() %></td>
                    <td><%= Web.esc(c.getNote()) %></td>
                    
                    <td class="ops">
                        <a href="<%= ctx %>/admin/calibrations/edit?id=<%= c.getCalibrationId() %>&stationId=<%= stationId %>">Sua</a>
                        
                        <form method="post" action="<%= ctx %>/admin/calibrations/delete"
                                onsubmit="return confirm('Xoa tram nay?');">
                            <input type="hidden" name="calibrationId" value="<%= c.getCalibrationId() %>">
                            <input type="hidden" name="stationId" value="<%= stationId %>">
                            <button type="submit" class="link danger">Xoa</button>
                        </form>
                    </td>
                </tr>
                <% } %>
                
                <% if (rows.isEmpty()) { %>
                    <tr><td colspan="9" class="c">Khong co dong nao khop bo loc</td></tr>
                <% } %>
            </table>
            
        </div>
        
        
    </body>
</html>
