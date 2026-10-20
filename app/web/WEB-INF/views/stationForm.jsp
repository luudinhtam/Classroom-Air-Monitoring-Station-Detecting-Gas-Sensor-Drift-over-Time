<%@page import="java.util.List"%>
<%@page import="model.Device"%>
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
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title><%= isNew ? "Add Station" : "Edit Station" %></title>
        <link rel="stylesheet" href="<%= ctx %>/assets/css/app.css">
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

                <div style="display: flex; gap: 12px;">
                    <div style="flex: 1;">
                        <label>Latitude (Vĩ độ)</label>
                        <input type="number" step="any" name="latitude" 
                               value="<%= (item == null || item.getLatitude() == null) ? 10.841129 : item.getLatitude() %>">
                    </div>
                    <div style="flex: 1;">
                        <label>Longitude (Kinh độ)</label>
                        <input type="number" step="any" name="longitude" 
                               value="<%= (item == null || item.getLongitude() == null) ? 106.809883 : item.getLongitude() %>">
                    </div>
                </div>
                <small style="color: #64748b; margin-top: -6px; margin-bottom: 12px; display: block;">Mặc định là khuôn viên ĐH FPT TP.HCM. Bạn cũng có thể kéo thả trực tiếp trên trang <b>Bản đồ (Map)</b>.</small>

                <label>CO Warning Threshold</label>
                <input type="number" name="coThreshold" 
                       value="<%= item == null ? "" : item.getCoWarningThreshold() %>">
                
                <label>CO2 Warning Threshold</label>
                <input type="number" name="co2Threshold" 
                       value="<%= item == null ? "" : item.getCo2WarningThreshold() %>">
                
                <label>Max Baseline Drift (%)</label>
                <input type="number" name="maxBaselineDrift" 
                       value="<%= isNew ? 15 : item.getMaxBaselineDrift() %>">
                <small style="color: #64748b; display: block; margin-top: 4px;">Mặc định 15% (dung sai trôi mức nền chuẩn kỹ thuật của đề tài, có thể tùy chỉnh).</small>
                
                <label for="deviceCode">Device Code</label>
                <select name="deviceCode" id="deviceCode" required>
                    <option value="">-- Select Device --</option>

                    <%
                        List<Device> deviceList = (List<Device>) request.getAttribute("deviceList");

                        String selectedDeviceCode = item == null
                                ? ""
                                : item.getDeviceCode();

                        if (deviceList != null) {
                            for (Device device : deviceList) {
                                String deviceCode = device.getDeviceCode();
                    %>
                        <option value="<%= Web.esc(deviceCode) %>" 
                            <%= deviceCode.equals(selectedDeviceCode) ? "selected" : "" %>>
                            <%= Web.esc(deviceCode) %>
                        </option>
                    <%
                            }
                        }
                    %>
                </select>
                
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
