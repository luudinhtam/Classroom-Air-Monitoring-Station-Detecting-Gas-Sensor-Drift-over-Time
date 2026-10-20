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
        ? "Calibration History – " + Web.esc(a.getCode()) + " / " + Web.esc(a.getName())
        : "Calibration History – All Stations";
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
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><%= pageTitle %></title>
    <link rel="stylesheet" href="<%= ctx %>/assets/css/app.css">
</head>
<body>
<jsp:include page="/WEB-INF/views/nav.jsp"/>

<div class="wrap">

    <!-- TIÊU ĐỀ -->
    <div class="dashboard-header" style="margin-bottom: 12px;">
        <div>
            <h2><%= pageTitle %></h2>
            <div class="muted">Total Calibration Records: <b><%= total %></b></div>
        </div>
        <div class="actions" style="margin: 0;">
            <a class="btn ghost" href="<%= ctx %>/admin/stations">&larr; Stations List</a>
        </div>
    </div>

    <!-- CẢNH BÁO KHI VÀO KHÔNG CÓ STATION -->
    <% if (a == null) { %>
        <div style="padding: 12px 16px; background: #fef3c7; border: 1px solid #fcd34d; border-radius: 6px;
                    font-size: 13px; color: #92400e; margin-bottom: 14px;">
            ⚠️ No monitoring station selected. Displaying <b>all calibration records</b>.
            To manage by specific station, go to
            <a href="<%= ctx %>/admin/stations" style="color: #b45309; font-weight: 600;">Stations List</a>
            and choose a station.
        </div>
    <% } %>

    <!-- BỘ LỌC -->
    <form class="filter" method="get" action="<%= ctx %>/admin/calibrations" style="margin-bottom: 14px;">
        <% if (stationId > 0) { %>
            <input type="hidden" name="stationId" value="<%= stationId %>">
        <% } %>
        <label style="font-size: 13px; font-weight: 500; color: #475569;">Search:</label>
        <input type="text" name="keyword" placeholder="Name or calibration code..." value="">
        <button type="submit" class="btn">Filter</button>
        <a class="btn ghost" href="<%= baseUrl %>">Reset</a>
    </form>

    <!-- BẢNG DANH SÁCH -->
    <% if (rows == null || rows.isEmpty()) { %>
        <div style="padding: 24px; text-align: center; background: #fff; border: 1px solid #e2e8f0;
                    border-radius: 6px; color: #64748b;">
            No calibration records found<%= a != null ? " for station " + Web.esc(a.getName()) : "" %>.
        </div>
    <% } else { %>
        <div class="table-responsive">
        <table class="grid">
            <thead>
                <tr>
                    <th style="width: 60px;">#</th>
                    <th style="width: 100px;">Code</th>
                    <th>Name</th>
                    <% if (a == null) { %><th style="width: 80px;">Station #</th><% } %>
                    <th class="c" style="width: 110px;">CO Baseline</th>
                    <th class="c" style="width: 110px;">CO2 Baseline</th>
                    <th style="width: 140px;">Performed By</th>
                    <th style="width: 130px;">Calibrated At</th>
                    <th>Note</th>
                    <% if (canManageCalibration) { %>
                        <th class="c" style="width: 130px;">Actions</th>
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
                                Edit
                            </button>

                            <form method="post"
                                  action="<%= ctx %>/admin/calibrations/delete"
                                  onsubmit="return confirm('Delete this calibration record?');" style="display:inline-block;">

                                <input type="hidden" name="calibrationId"
                                       value="<%= c.getCalibrationId() %>">

                                <input type="hidden" name="stationId"
                                       value="<%= c.getStationId() %>">

                                <button type="submit" class="btn-block btn-red">
                                    Delete
                                </button>
                            </form>
                        </td>
                    <% } %>
                </tr>
                <% } %>
            </tbody>
        </table>
        </div>
    <% } %>

</div>
</body>
</html>
