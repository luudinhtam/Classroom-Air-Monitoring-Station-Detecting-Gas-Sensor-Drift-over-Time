<%@page import="java.util.List"%>
<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="model.AirSession, model.AppUser, util.Web" %>
<%
    AirSession item = (AirSession) request.getAttribute("editSession");
    String error = (String) request.getAttribute("error");
    String ctx = request.getContextPath();
    
    boolean isNew = (item == null || item.getSessionId() == 0);
    String currentLabel = (item != null && item.getLabelCode() != null) ? item.getLabelCode().trim() : "";

    AppUser me = (AppUser) session.getAttribute("user");
    String myRole = (me != null) ? me.getRoleCode() : "";
    
    // Chỉ có ADMIN mới được quyền đổi nhãn. STATION_MANAGER và OPERATOR chỉ sửa được thông số khác, không được đổi nhãn.
    boolean canEditLabel = "ADMIN".equals(myRole);
    // REVIEWER thì ngược lại: chỉ được đổi nhãn, không được sửa thông số thô
    boolean isReviewerOnly = "REVIEWER".equals(myRole);
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title><%= isNew ? "New Measurement Session" : "Update Session #" + item.getSessionId() %></title>
    <link rel="stylesheet" href="<%= ctx %>/css/app.css">
    <script>
    var originalLabel = "<%= (item != null && item.getLabelCode() != null) ? item.getLabelCode().trim() : "" %>";

    function handleLabelChange() {
        var isNewRecord = <%= isNew %>;
        if (isNewRecord || !<%= canEditLabel %>) return;

        var selectElement = document.getElementById("labelCodeSelect");
        var reasonContainer = document.getElementById("reasonContainer");
        var reasonTextarea = document.getElementById("editReasonField");
        
        if (!selectElement || !reasonContainer) return;

        var currentSelected = selectElement.value.trim();

        if (currentSelected !== originalLabel) {
            reasonContainer.style.display = "block";
            if (reasonTextarea) reasonTextarea.required = true;
        } else {
            reasonContainer.style.display = "none";
            if (reasonTextarea) {
                reasonTextarea.required = false;
                reasonTextarea.value = "";
            }
        }
    }
    
    window.addEventListener("DOMContentLoaded", function() {
        handleLabelChange();
    });
    </script>
</head>
<body>
<jsp:include page="/WEB-INF/views/nav.jsp"/>

<div class="wrap">
    <h2><%= isNew ? "New Measurement Session" : "Update Session #" + item.getSessionId() %></h2>

    <% if (error != null) { %>
        <div class="error" style="color: #d9534f; margin-bottom: 15px; font-weight: bold;"><%= Web.esc(error) %></div>
    <% } %>

    <div style="display: flex; gap: 30px; align-items: flex-start; flex-wrap: wrap;">
        
        <div style="flex: 2; min-width: 400px;">
            <form class="form" method="post" action="<%= ctx %>/sessions/save">
                <input type="hidden" name="sessionId" value="<%= isNew ? 0 : item.getSessionId() %>">

                <% if (!isNew) { %>
                    <label>Session ID</label>
                    <input type="text" value="<%= item.getSessionId() %>" readonly style="background: #f0f0f0; color: #555; border: 1px solid #ccc; cursor: not-allowed; padding: 8px; border-radius: 4px;">
                    
                    <label>Measured At</label>
                    <input type="text" value="<%= item.getMeasuredAt() %>" readonly style="background: #f0f0f0; color: #555; border: 1px solid #ccc; cursor: not-allowed; padding: 8px; border-radius: 4px;">
                <% } %>

                <label>Gas A (raw)</label>
                <input type="number" name="gasARaw" required value="<%= item == null ? "" : item.getGasARaw() %>" <%= isReviewerOnly ? "readonly style='background: #f0f0f0; cursor: not-allowed;'" : "" %>>

                <label>Gas B (raw)</label>
                <input type="number" name="gasBRaw" required value="<%= item == null ? "" : item.getGasBRaw() %>" <%= isReviewerOnly ? "readonly style='background: #f0f0f0; cursor: not-allowed;'" : "" %>>

                <label>Gas A (base)</label>
                <input type="number" name="gasABase" required value="<%= item == null ? "" : item.getGasABase() %>" <%= isReviewerOnly ? "readonly style='background: #f0f0f0; cursor: not-allowed;'" : "" %>>

                <label>Temp (°C)</label>
                <input type="text" name="tempC" required value="<%= item == null ? "" : item.getTempC() %>" <%= isReviewerOnly ? "readonly style='background: #f0f0f0; cursor: not-allowed;'" : "" %>>

                <label>Humid (%)</label>
                <input type="text" name="humidPct" required value="<%= item == null ? "" : item.getHumidPct() %>" <%= isReviewerOnly ? "readonly style='background: #f0f0f0; cursor: not-allowed;'" : "" %>>

                <label>Label <%= !canEditLabel && !isNew ? "(Only Admin can change label)" : "" %></label>
                <select name="labelCode" id="labelCodeSelect" required onchange="handleLabelChange()" <%= (!canEditLabel && !isNew) ? "disabled style='background: #f0f0f0; cursor: not-allowed;'" : "" %>>
                    <% 
                        String[] labels = {"BASE", "RAISED", "HIGH", "DRIFTED", "TEMP_EFFECT", "WARMUP"};
                        for (String lbl : labels) {
                    %>
                        <option value="<%= lbl %>" <%= lbl.equals(currentLabel) ? "selected" : "" %>><%= lbl %></option>
                    <% } %>
                </select>
                <% if (!canEditLabel && !isNew) { %>
                    <!-- Truyền hidden để giữ nguyên nhãn cũ khi submit form nếu bị disable -->
                    <input type="hidden" name="labelCode" value="<%= currentLabel %>">
                <% } %>
                
                <label>Device Code</label>
                <select name="deviceId" required <%= isReviewerOnly ? "disabled style='background: #f0f0f0; cursor: not-allowed;'" : "" %>>
                    <option value="">-- Select Measurement Device --</option>
                    <% 
                        List<model.Device> devices = (List<model.Device>) request.getAttribute("devices");
                        int currentDeviceId = (item != null) ? item.getDeviceId() : 0;
                        
                        if (devices != null) {
                            for (model.Device d : devices) {
                    %>
                                <option value="<%= d.getDeviceId() %>" <%= (d.getDeviceId() == currentDeviceId) ? "selected" : "" %>>
                                    <%= Web.esc(d.getDeviceCode()) %> (<%= Web.esc(d.getLocation()) %>)
                                </option>
                    <% 
                            }
                        } 
                    %>
                </select>
                <% if (isReviewerOnly) { %>
                    <input type="hidden" name="deviceId" value="<%= currentDeviceId %>">
                <% } %>

                <div id="reasonContainer" style="display: none;">
                    <label style="margin-top: 15px; color: #d9534f; font-weight: bold;">Reason for edit / label change (* Required)</label>
                    <textarea name="editReason" id="editReasonField" rows="3" 
                              placeholder="Please provide a clear reason (at least 5 characters)..." 
                              minlength="5"
                              style="width: 100%; padding: 8px; border: 1px solid #ccc; border-radius: 4px; background: #fff; color: #333; font-family: inherit;"
                    ><%= request.getParameter("editReason") != null ? Web.esc(request.getParameter("editReason")) : "" %></textarea>
                </div>

                <div class="actions" style="margin-top: 20px;">
                    <button type="submit" class="primary">Save</button>
                    <a href="<%= ctx %>/sessions" class="btn ghost">Cancel</a>
                </div>
            </form>
        </div>

        <% if (!isNew) { %>
        <div style="flex: 1; min-width: 300px; background: #fff; border: 1px solid #ddd; border-radius: 8px; padding: 20px; box-shadow: 0 2px 4px rgba(0,0,0,0.05);">
            <h3 style="margin-top: 0; color: #333; border-bottom: 1px solid #eee; padding-bottom: 10px; font-size: 16px;">
                📜 Label Change History
            </h3>
            
            <div style="color: #555; font-size: 14px; line-height: 1.6; max-height: 500px; overflow-y: auto; margin-top: 10px;">
                <% if (item.getNote() != null && !item.getNote().trim().isEmpty()) { %>
                    <div style="white-space: pre-wrap;"><%= Web.esc(item.getNote()) %></div>
                <% } else { %>
                    <em style="color: #999;">No label change history for this session.</em>
                <% } %>
            </div>
        </div>
        <% } %>

    </div>
</div>
</body>
</html>