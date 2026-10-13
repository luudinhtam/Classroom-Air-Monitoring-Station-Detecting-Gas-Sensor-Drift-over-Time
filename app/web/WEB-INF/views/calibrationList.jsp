<%@page import="java.time.format.DateTimeFormatter"%>
<%@page import="model.AirStation"%>
<%@page import="dao.AirStationDAO"%>
<%@page import="util.Web"%>
<%@page import="model.Calibration"%>
<%@page import="java.util.List"%>
<%@page import="model.AppUser"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>

<%
    List<Calibration> rows = (List<Calibration>) request.getAttribute("rows");
    int stationId = (int) request.getAttribute("stationId");
    int total = (int) request.getAttribute("total");
    String ctx = request.getContextPath();
    DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    AirStationDAO stations = new AirStationDAO();
    // Chỉ tra cứu trạm nếu stationId hợp lệ — tránh NullPointerException khi vào từ dashboard không có stationId
    AirStation a = stationId > 0 ? stations.findById(stationId) : null;

    String pageTitle = (a != null)
        ? "Lịch sử hiệu chuẩn – " + Web.esc(a.getCode()) + " / " + Web.esc(a.getName())
        : "Lịch sử hiệu chuẩn – Tất cả trạm";
    String baseUrl = ctx + "/admin/calibrations" + (stationId > 0 ? "?stationId=" + stationId : "");

    // Phân quyền hiển thị nút: Admin, Station Manager, Operator được quản lý; Reviewer/Viewer chỉ xem
    AppUser me = (AppUser) session.getAttribute("user");
    String myRole = (me != null) ? me.getRoleCode() : "";
    boolean canManageCalibration = "ADMIN".equals(myRole) || "STATION_MANAGER".equals(myRole) || "OPERATOR".equals(myRole);
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title><%= pageTitle %></title>
    <link rel="stylesheet" href="<%= ctx %>/css/app.css">
</head>
<body>
<jsp:include page="/WEB-INF/views/nav.jsp"/>

<div class="wrap">

    <!-- TIÊU ĐỀ -->
    <div class="dashboard-header" style="margin-bottom: 12px;">
        <div>
            <h2><%= pageTitle %></h2>
            <div class="muted">Tổng số phiếu hiệu chuẩn: <b><%= total %></b></div>
        </div>
        <div class="actions" style="margin: 0;">
            <% if (a != null && canManageCalibration) { %>
                <a class="btn" href="<%= ctx %>/admin/calibrations/create?stationId=<%= stationId %>">+ Thêm hiệu chuẩn</a>
            <% } %>
            <a class="btn ghost" href="<%= ctx %>/admin/stations">&larr; Danh sách trạm</a>
        </div>
    </div>

    <!-- CẢNH BÁO KHI VÀO KHÔNG CÓ STATION -->
    <% if (a == null) { %>
        <div style="padding: 12px 16px; background: #fef3c7; border: 1px solid #fcd34d; border-radius: 6px;
                    font-size: 13px; color: #92400e; margin-bottom: 14px;">
            ⚠️ Chưa chọn trạm giám sát. Đang hiển thị <b>tất cả phiếu hiệu chuẩn</b>.
            Để quản lý theo từng trạm, hãy vào
            <a href="<%= ctx %>/admin/stations" style="color: #b45309; font-weight: 600;">Danh sách trạm</a>
            và chọn trạm cụ thể.
        </div>
    <% } %>

    <!-- BỘ LỌC -->
    <form class="filter" method="get" action="<%= ctx %>/admin/calibrations" style="margin-bottom: 14px;">
        <% if (stationId > 0) { %>
            <input type="hidden" name="stationId" value="<%= stationId %>">
        <% } %>
        <label style="font-size: 13px; font-weight: 500; color: #475569;">Tìm kiếm:</label>
        <input type="text" name="keyword" placeholder="Tên hoặc mã phiếu hiệu chuẩn..." value="">
        <button type="submit" class="btn">Lọc</button>
        <a class="btn ghost" href="<%= baseUrl %>">Đặt lại</a>
    </form>

    <!-- BẢNG DANH SÁCH -->
    <% if (rows == null || rows.isEmpty()) { %>
        <div style="padding: 24px; text-align: center; background: #fff; border: 1px solid #e2e8f0;
                    border-radius: 6px; color: #64748b;">
            Không tìm thấy phiếu hiệu chuẩn nào<%= a != null ? " cho trạm " + Web.esc(a.getName()) : "" %>.
        </div>
    <% } else { %>
        <table class="grid">
            <thead>
                <tr>
                    <th style="width: 60px;">#</th>
                    <th style="width: 100px;">Mã phiếu</th>
                    <th>Tên hiệu chuẩn</th>
                    <% if (a == null) { %><th style="width: 80px;">Trạm #</th><% } %>
                    <th class="c" style="width: 110px;">CO Baseline</th>
                    <th class="c" style="width: 110px;">CO2 Baseline</th>
                    <th style="width: 140px;">Người thực hiện</th>
                    <th style="width: 130px;">Ngày hiệu chuẩn</th>
                    <th>Ghi chú</th>
                    <% if (canManageCalibration) { %>
                        <th class="c" style="width: 130px;">Thao tác</th>
                    <% } %>
                </tr>
            </thead>
            <tbody>
                <% for (Calibration c : rows) { %>
                <tr>
                    <td><b><%= c.getCalibrationId() %></b></td>
                    <td><span class="tag"><%= Web.esc(c.getCode()) %></span></td>
                    <td><%= Web.esc(c.getName()) %></td>
                    <% if (a == null) { %>
                        <td class="c"><%= c.getStationId() %></td>
                    <% } %>
                    <td class="c"><%= c.getCoBaseLine() %></td>
                    <td class="c"><%= c.getCo2BaseLine() %></td>
                    <td><%= Web.esc(c.getPerformedByUsername()) %></td>
                    <td class="muted"><%= c.getCalibratedAt() != null ? c.getCalibratedAt().toLocalDateTime().format(formatter) : "–" %></td>
                    <td class="muted" style="font-size: 12px;"><%= c.getNote() != null ? Web.esc(c.getNote()) : "–" %></td>
                    
                    <% if (canManageCalibration) { %>
                        <td class="ops ops-group c">
                            <button type="button" class="btn-block btn-blue"
                                    onclick="window.location.href='<%= ctx %>/admin/calibrations/edit?id=<%= c.getCalibrationId() %>&stationId=<%= c.getStationId() %>'">
                                Sửa
                            </button>

                            <form method="post"
                                  action="<%= ctx %>/admin/calibrations/delete"
                                  onsubmit="return confirm('Xóa phiếu hiệu chuẩn này?');" style="display:inline-block;">

                                <input type="hidden" name="calibrationId"
                                       value="<%= c.getCalibrationId() %>">

                                <input type="hidden" name="stationId"
                                       value="<%= c.getStationId() %>">

                                <button type="submit" class="btn-block btn-red">
                                    Xóa
                                </button>
                            </form>
                        </td>
                    <% } %>
                </tr>
                <% } %>
            </tbody>
        </table>
    <% } %>

</div>
</body>
</html>