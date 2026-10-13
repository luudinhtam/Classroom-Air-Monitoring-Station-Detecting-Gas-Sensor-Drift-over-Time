
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.util.List"%>
<%@page import="java.time.format.DateTimeFormatter"%>
<%@page import="controller.BaseLineServlet.SensorSample"%>
<%@page import="model.EmptyWindow"%>
<%
    String ctx = request.getContextPath();

    EmptyWindow ew = (EmptyWindow) request.getAttribute("emptyWindow");
    List<SensorSample> samples =
            (List<SensorSample>) request.getAttribute("samples");

    Integer stationId = (Integer) request.getAttribute("stationId");
    Integer sampleCount = (Integer) request.getAttribute("sampleCount");

    Double baselineCO = (Double) request.getAttribute("baselineCO");
    Double baselineCO2 = (Double) request.getAttribute("baselineCO2");

    String errorMessage = (String) request.getAttribute("errorMessage");

    DateTimeFormatter formatter =
            DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm:ss");
%>

<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Tính mức nền - Air Station</title>
    <link rel="stylesheet" href="<%= ctx %>/css/app.css">
</head>
<body style="padding: 40px 100px;">

    <h1>Tính mức nền cảm biến</h1>

    <% if (errorMessage != null) { %>
        <p role="alert"><%= errorMessage %></p>
    <% } %>

    <% if (ew != null && samples != null
            && baselineCO != null && baselineCO2 != null) { %>
            
        <div style="display: flex; justify-content: space-between; align-items: flex-start; flex-wrap: wrap;">

            <!-- Thông tin khoảng phòng trống: bên trái -->
            <div>
                <h2 style="margin-top: 0; margin-bottom: 20px;">
                    Thông tin khoảng phòng trống
                </h2>

                <table border="1" cellpadding="8" cellspacing="0">
                    <tr>
                        <th>Mã khoảng</th>
                        <td><%= ew.getCode() %></td>
                    </tr>
                    <tr>
                        <th>Tên khoảng</th>
                        <td><%= ew.getName() %></td>
                    </tr>
                    <tr>
                        <th>Bắt đầu</th>
                        <td><%= ew.getStartAt().format(formatter) %></td>
                    </tr>
                    <tr>
                        <th>Kết thúc</th>
                        <td><%= ew.getEndAt().format(formatter) %></td>
                    </tr>
                    <tr>
                        <th>Số mẫu</th>
                        <td><%= sampleCount %></td>
                    </tr>
                </table>
            </div>

            <!-- Danh sách mẫu đo: bên phải -->
            <div>
                <h2 style="margin-top: 0; margin-bottom: 20px;">
                    Danh sách mẫu đo
                </h2>

                <div style="max-height: 380px; width: 650px; overflow-y: auto; border: 1px solid #ccc;">
                    <table border="1" cellpadding="8" cellspacing="0"
                           style="width: 100%; border-collapse: separate; border-spacing: 0;">

                        <thead>
                            <tr style="position: sticky; top: 0; background: #f2f2f2; z-index: 2; border: 1px solid #000;">
                                <th >STT</th>
                                <th >Thời gian đo</th>
                                <th >CO</th>
                                <th >CO₂</th>
                            </tr>
                        </thead>

                        <tbody>
                            <% for (int i = 0; i < samples.size(); i++) {
                                SensorSample sample = samples.get(i);
                            %>
                                <tr>
                                    <td style="border: 1px solid #000;">
                                        <%= i + 1 %>
                                    </td>
                                    <td style="border: 1px solid #000;">
                                        <%= sample.getMeasuredAt().format(formatter) %>
                                    </td>
                                    <td style="border: 1px solid #000;">
                                        <%= String.format(java.util.Locale.US, "%.3f",
                                                sample.getCoValue()) %>
                                    </td>
                                    <td style="border: 1px solid #000;">
                                        <%= String.format(java.util.Locale.US, "%.3f",
                                                sample.getCo2Value()) %>
                                    </td>
                                </tr>
                            <% } %>
                        </tbody>

                    </table>
                </div>
            </div>

        </div>

            
        <h2 style="text-align: center; margin-top: 60px">Kết quả baseline dự kiến</h2>

        <table style="width: 50%; margin: 0 auto" border="1" cellpadding="8" cellspacing="0">
            <thead>
                <tr>
                    <th>Thông số</th>
                    <th>Giá trị trung bình</th>
                </tr>
            </thead>
            <tbody>
                <tr>
                    <td>Baseline CO</td>
                    <td><%= String.format(java.util.Locale.US, "%.3f", baselineCO) %></td>
                </tr>
                <tr>
                    <td>Baseline CO₂</td>
                    <td><%= String.format(java.util.Locale.US, "%.3f", baselineCO2) %></td>
                </tr>
            </tbody>
        </table>

        <p>
            <strong>Lưu ý:</strong>
            Đây là dữ liệu cảm biến giả lập phục vụ kiểm thử,
            chưa phải dữ liệu đo từ thiết bị thật.
        </p>

        <h2>Xác nhận</h2>

        <p>
            Chỉ xác nhận nếu bạn đồng ý lưu hai giá trị baseline phía trên
            thành một bản ghi Calibration mới.
        </p>

        <form method="post" action="<%= ctx %>/admin/emptyWindows/baseline">

            <button class="btn" type="submit">
                Xác nhận lưu mức nền mới
            </button>

            <a class="btn ghost" href="<%= ctx %>/admin/emptyWindows?stationId=<%= stationId %>">
                Quay lại
            </a>
        </form>

    <% } else { %>

        <p>Không có kết quả baseline để hiển thị.</p>

        <% if (stationId != null) { %>
            <a href="<%= ctx %>/admin/emptyWindows?stationId=<%= stationId %>">
                Quay lại danh sách khoảng phòng trống
            </a>
        <% } else { %>
            <a href="<%= ctx %>/admin/stations">Quay lại danh sách trạm</a>
        <% } %>

    <% } %>

</body>
</html>
