<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="util.Web" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Khong du quyen</title>
    <link rel="stylesheet" href="<%= request.getContextPath() %>/css/app.css">
</head>
<body>
<jsp:include page="/WEB-INF/views/nav.jsp"/>
<div class="wrap">
    <h2>Khong du quyen</h2>
    <p>
        Vai tro cua ban khong co quyen
        <b><%= Web.esc((String) request.getAttribute("neededPerm")) %></b>
        nen khong mo duoc trang nay.
    </p>
    <p>
        Viec chan nay do bo loc phia may chu thuc hien, khong phai do an nut tren giao dien,
        nen dan thang duong dan vao trinh duyet cung se bi tu choi y het.
    </p>
    <p><a class="btn" href="<%= request.getContextPath() %>/dashboard">Ve trang chinh</a></p>
</div>
</body>
</html>
