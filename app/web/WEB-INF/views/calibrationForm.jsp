<%@page import="java.util.List"%>
<%@page import="model.AppUser"%>
<%@page import="util.Web"%>
<%@page import="model.Calibration"%>
<%@page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>

<%
    Calibration item = (Calibration) request.getAttribute("editCalibration");
    String error = (String) request.getAttribute("error");
    Integer rIdObj = (Integer) request.getAttribute("roomId");
    int roomId = (rIdObj != null) ? rIdObj : (request.getAttribute("stationId") != null ? (Integer) request.getAttribute("stationId") : 0);
    String ctx = request.getContextPath();
    boolean isNew = (item == null || item.getCalibrationId() == 0);
%>

<!DOCTYPE html>
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title><%= isNew ? "Add Calibration" : "Edit Calibration" %></title>
        <link rel="stylesheet" href="<%= ctx %>/assets/css/app.css">
    </head>
    <body>
        <jsp:include page="/WEB-INF/views/nav.jsp"/>
        
        <div class="wrap">
            <h2><%= isNew ? "Add Calibration" : "Edit Calibration" %> for Room ID: <%= roomId %></h2>
            
            <% if (error != null) { %><div class="error"><%= Web.esc(error) %></div><% } %>
            
            <form class="form" method="post" action="<%= ctx %>/admin/calibrations/save?roomId=<%= roomId %>">
                <input type="hidden" name="calibrationId" value="<%= isNew ? 0 : item.getCalibrationId() %>">

                <label>Code</label>
                <input type="text" name="code" required minlength="3"
                        <%= !isNew ? "readonly style=\"opacity:.55;cursor:not-allowed;\"" : "" %>
                        value="<%= item == null ? "" : Web.esc(item.getCode()) %>">
                    <% if (!isNew) { %>
                    <small style="color:#888">Calibration code cannot be changed once created.</small>
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
                    <option value="">-- Select Performer --</option>
                    <%
                        List<AppUser> calibrationUsers = (List<AppUser>) request.getAttribute("calibrationUsers");

                        int performedBy = item == null ? 0 : item.getPerformedBy();

                        if (calibrationUsers != null) {
                            for (AppUser u : calibrationUsers) {
                    %>
                        <option value="<%= u.getUserId() %>"
                                <%= u.getUserId() == performedBy ? "selected" : "" %>>
                            <%= Web.esc(u.getUsername()) %>
                        </option>
                    <%      }
                        } %>
                </select>
                
                <label>Note</label>
                <input type="text" name="note"
                       value="<%= item == null ? "" : Web.esc(item.getNote()) %>">

                <div class="actions">
                    <button type="submit" class="primary">Save</button>
                    <a href="<%= ctx %>/admin/calibrations?roomId=<%= roomId %>" class="btn ghost">Cancel</a>
                </div>
            </form>
        </div>
        
    </body>
</html>
