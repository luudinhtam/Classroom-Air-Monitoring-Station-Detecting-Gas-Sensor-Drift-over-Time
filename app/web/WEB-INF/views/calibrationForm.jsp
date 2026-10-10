

<%@page import="java.util.List"%>
<%@page import="model.AppUser"%>
<%@page import="util.Web"%>
<%@page import="model.Calibration"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>

<%
    Calibration item = (Calibration) request.getAttribute("editCalibration");
    String error = (String) request.getAttribute("error");
    Integer stationId = (Integer) request.getAttribute("stationId");
    String ctx = request.getContextPath();
    boolean isNew = (item == null || item.getCalibrationId()== 0);
%>

<!DOCTYPE html>
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <title><%= isNew ? "Them hieu chuan" : "Sua hieu chuan" %></title>
        <link rel="stylesheet" href="<%= ctx %>/css/app.css">
    </head>
    <body>
        <jsp:include page="/WEB-INF/views/nav.jsp"/>
        
        <div class="wrap">
            <h2><%= isNew ? "Them hieu chuan" : "Sua hieu chuan" %> cho stationId: <%= stationId %></h2>
            
            <% if (error != null) { %><div class="error"><%= Web.esc(error) %></div><% } %>
            
            <form class="form" method="post" action="<%= ctx %>/admin/calibrations/save?stationId=<%= stationId %>">
                <input type="hidden" name="calibrationId" value="<%= isNew ? 0 : item.getCalibrationId() %>">

                <label>Code</label>
                <input type="text" name="code" required minlength="3"
                        <%= !isNew ? "readonly style=\"opacity:.55;cursor:not-allowed;\"" : "" %>
                        value="<%= item == null ? "" : Web.esc(item.getCode()) %>">
                    <% if (!isNew) { %>
                    <small style="color:#888">Code hieu chuan khong the thay doi sau khi tao.</small>
                    <% } %>

                <label>Name</label>
                <input type="text" name="name" required
                       value="<%= item == null ? "" : Web.esc(item.getName()) %>">

                <label>CO Baseline</label>
                <input type="number" name="coBaseline"
                       value="<%= item == null ? "" : item.getCoBaseLine() %>">
                
                <label>CO2 Baseline</label>
                <input type="number" name="co2Baseline"
                       value="<%= item == null ? "" : item.getCo2BaseLine() %>">
                
                
                <label>Performed by</label>
                <select name="userId" required>
                    <option value="">-- Chọn người thực hiện --</option>
                    <%
                        List<AppUser> calibrationUsers = (List<AppUser>) request.getAttribute("calibrationUsers");

                        int performedBy = item == null ? 0 : item.getPerformedBy();

                        for (AppUser u : calibrationUsers) {
                    %>
                        <option value="<%= u.getUserId() %>"
                                <%= u.getUserId() == performedBy ? "selected" : "" %>>
                            <%= Web.esc(u.getUsername()) %>
                        </option>
                    <%}%>
                </select>
                
                <label>Note</label>
                <input type="text" name="note"
                       value="<%= item == null ? "" : Web.esc(item.getNote()) %>">

                <div class="actions">
                    <button type="submit" class="primary">Luu thong tin</button>
                    <a href="<%= ctx %>/admin/calibrations?stationId=<%= stationId %>" class="btn ghost">Huy bo</a>
                </div>
            </form>
        </div>
        
    </body>
</html>
