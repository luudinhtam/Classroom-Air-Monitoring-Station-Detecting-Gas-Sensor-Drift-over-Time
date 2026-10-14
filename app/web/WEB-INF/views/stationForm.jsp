

<%@page import="util.Web"%>
<%@page import="model.AirStation"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>

<%
    AirStation item = (AirStation) request.getAttribute("editStation");
    String error = (String) request.getAttribute("error");
    String ctx = request.getContextPath();
    boolean isNew = (item == null || item.getStationId()== 0);
%>
<!DOCTYPE html>
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <title><%= isNew ? "Add Station" : "Edit Station" %></title>
        <link rel="stylesheet" href="<%= ctx %>/css/app.css">
    </head>
    <body>
        <jsp:include page="/WEB-INF/views/nav.jsp"/>
        <div class="wrap">
            <h2><%= isNew ? "Add Station" : "Edit Station" %></h2>
            
            <% if (error != null) { %><div class="error"><%= Web.esc(error) %></div><% } %>
            
            <form class="form" method="post" action="<%= ctx %>/admin/stations/save">
                <input type="hidden" name="stationId" value="<%= isNew ? 0 : item.getStationId() %>">

                <label>Code</label>
                <input type="text" name="code" required minlength="3"
                        <%= !isNew ? "readonly style=\"opacity:.55;cursor:not-allowed;\"" : "" %>
                        value="<%= item == null ? "" : Web.esc(item.getCode()) %>">
                    <% if (!isNew) { %>
                    <small style="color:#888">Station code cannot be changed once created.</small>
                    <% } %>

                <label>Name</label>
                <input type="text" name="name" required
                       value="<%= item == null ? "" : Web.esc(item.getName()) %>">
                
                <label>Location</label>
                <input type="text" name="location" required
                       value="<%= item == null ? "" : Web.esc(item.getLocation()) %>">

                <label>CO Warning Threshold</label>
                <input type="number" name="coThreshold" 
                       value="<%= item == null ? "" : item.getCoWarningThreshold() %>">
                
                <label>CO2 Warning Threshold</label>
                <input type="number" name="co2Threshold" 
                       value="<%= item == null ? "" : item.getCo2WarningThreshold() %>">
                
                <label>Max Baseline Drift</label>
                <input type="number" name="maxBaselineDrift" 
                       value="<%= item == null ? "" : item.getMaxBaselineDrift() %>">
                
                <label>Device Code</label>
                <input type="text" name="deviceKey" 
                       value="<%= item == null ? "" : Web.esc(item.getDeviceKey()) %>">
                
                <label>Note</label>
                <input type="text" name="note"
                       value="<%= item == null ? "" : Web.esc(item.getNote()) %>">

                <div class="actions">
                    <button type="submit" class="primary">Save</button>
                    <a href="<%= ctx %>/admin/stations" class="btn ghost">Cancel</a>
                </div>
            </form>
        </div>
    </body>
</html>
