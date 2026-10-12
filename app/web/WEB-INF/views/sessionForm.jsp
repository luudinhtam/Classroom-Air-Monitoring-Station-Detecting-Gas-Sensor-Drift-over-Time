<%@page import="java.util.List"%>
<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="model.AirSession, util.Web" %>
<%
    AirSession item = (AirSession) request.getAttribute("editSession");
    String error = (String) request.getAttribute("error");
    String ctx = request.getContextPath();
    
    boolean isNew = (item == null || item.getSessionId() == 0);
    String currentLabel = (item != null && item.getLabelCode() != null) ? item.getLabelCode().trim() : "";
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title><%= isNew ? "Thêm phiên đo mới" : "Cập nhật nhãn phiên đo #" + item.getSessionId() %></title>
    <link rel="stylesheet" href="<%= ctx %>/css/app.css">
    <script>
    // Lấy nhãn ban đầu của phiên đo
    var originalLabel = "<%= (item != null && item.getLabelCode() != null) ? item.getLabelCode().trim() : "" %>";

    function handleLabelChange() {
        var isNewRecord = <%= isNew %>;
        if (isNewRecord) return; // Nếu là Thêm mới thì bỏ qua hoàn toàn

        var selectElement = document.getElementById("labelCodeSelect");
        var reasonContainer = document.getElementById("reasonContainer");
        var reasonTextarea = document.getElementById("editReasonField");
        
        if (!selectElement || !reasonContainer) return;

        var currentSelected = selectElement.value.trim();

        // LOGIC CHÍNH: Nếu nhãn mới KHÁC nhãn cũ -> Hiện ô lý do
        if (currentSelected !== originalLabel) {
            reasonContainer.style.display = "block";
            if (reasonTextarea) reasonTextarea.required = true;
        } else {
            // Nếu đổi lại giống nhãn cũ -> Ẩn ô lý do đi
            reasonContainer.style.display = "none";
            if (reasonTextarea) {
                reasonTextarea.required = false;
                reasonTextarea.value = ""; // Xóa chữ gõ thừa đi cho sạch
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
    <h2><%= isNew ? "Thêm phiên đo mới" : "Cập nhật nhãn phiên đo #" + item.getSessionId() %></h2>

    <% if (error != null) { %>
        <div class="error" style="color: #d9534f; margin-bottom: 15px; font-weight: bold;"><%= Web.esc(error) %></div>
    <% } %>

    <!-- BẮT ĐẦU CHIA 2 CỘT BẰNG FLEXBOX -->
    <div style="display: flex; gap: 30px; align-items: flex-start; flex-wrap: wrap;">
        
        <!-- CỘT TRÁI: FORM NHẬP LIỆU -->
        <div style="flex: 2; min-width: 400px;">
            <form class="form" method="post" action="<%= ctx %>/sessions/save">
                <input type="hidden" name="sessionId" value="<%= isNew ? 0 : item.getSessionId() %>">

                <% if (!isNew) { %>
                    <label>Ma phien do</label>
                    <input type="text" value="<%= item.getSessionId() %>" readonly style="background: #f0f0f0; color: #555; border: 1px solid #ccc; cursor: not-allowed; padding: 8px; border-radius: 4px;">
                    
                    <label>Thoi gian do</label>
                    <input type="text" value="<%= item.getMeasuredAt() %>" readonly style="background: #f0f0f0; color: #555; border: 1px solid #ccc; cursor: not-allowed; padding: 8px; border-radius: 4px;">
                <% } %>

                <label>Gas A (raw)</label>
                <input type="number" name="gasARaw" required value="<%= item == null ? "" : item.getGasARaw() %>">

                <label>Gas B (raw)</label>
                <input type="number" name="gasBRaw" required value="<%= item == null ? "" : item.getGasBRaw() %>">

                <label>Gas A (base)</label>
                <input type="number" name="gasABase" required value="<%= item == null ? "" : item.getGasABase() %>">

                <label>Temp (°C)</label>
                <input type="text" name="tempC" required value="<%= item == null ? "" : item.getTempC() %>">

                <label>Humid (%)</label>
                <input type="text" name="humidPct" required value="<%= item == null ? "" : item.getHumidPct() %>">

                <label>Nhan</label>
                <select name="labelCode" id="labelCodeSelect" required onchange="handleLabelChange()">
                    <% 
                        String[] labels = {"BASE", "RAISED", "HIGH", "DRIFTED", "TEMP_EFFECT", "WARMUP"};
                        for (String lbl : labels) {
                    %>
                        <option value="<%= lbl %>" <%= lbl.equals(currentLabel) ? "selected" : "" %>><%= lbl %></option>
                    <% } %>
                </select>
                
                <label>Mã thiết bị</label>
                <select name="deviceId" required>
                    <option value="">-- Chọn thiết bị đo --</option>
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

                <!-- Khung nhập lý do (Mặc định ẩn, sẽ do JS ở trên điều khiển) -->
                <div id="reasonContainer" style="display: none;">
                    <label style="margin-top: 15px; color: #d9534f; font-weight: bold;">Lý do chỉnh sửa / thay đổi nhãn (* Bắt buộc)</label>
                    <textarea name="editReason" id="editReasonField" rows="3" 
                              placeholder="Vui lòng giải thích rõ lý do (tối thiểu 5 ký tự)..." 
                              minlength="5"
                              style="width: 100%; padding: 8px; border: 1px solid #ccc; border-radius: 4px; background: #fff; color: #333; font-family: inherit;"
                    ><%= request.getParameter("editReason") != null ? Web.esc(request.getParameter("editReason")) : "" %></textarea>
                </div>

                <div class="actions" style="margin-top: 20px;">
                    <button type="submit" class="primary">Lưu thông tin</button>
                    <a href="<%= ctx %>/sessions" class="btn ghost">Hủy bỏ</a>
                </div>
            </form>
        </div>

        <!-- CỘT PHẢI: LỊCH SỬ THAY ĐỔI -->
        <% if (!isNew) { %>
        <div style="flex: 1; min-width: 300px; background: #fff; border: 1px solid #ddd; border-radius: 8px; padding: 20px; box-shadow: 0 2px 4px rgba(0,0,0,0.05);">
            <h3 style="margin-top: 0; color: #333; border-bottom: 1px solid #eee; padding-bottom: 10px; font-size: 16px;">
                📜 Lịch sử thay đổi nhãn
            </h3>
            
            <div style="color: #555; font-size: 14px; line-height: 1.6; max-height: 500px; overflow-y: auto; margin-top: 10px;">
                <% if (item.getNote() != null && !item.getNote().trim().isEmpty()) { %>
                    <div style="white-space: pre-wrap;"><%= Web.esc(item.getNote()) %></div>
                <% } else { %>
                    <em style="color: #999;">Chưa có lịch sử thay đổi nhãn nào cho phiên đo này.</em>
                <% } %>
            </div>
        </div>
        <% } %>

    </div>
</div>
</body>
</html>