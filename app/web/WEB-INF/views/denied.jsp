<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="util.Web" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Access Denied</title>
    <link rel="stylesheet" href="<%= request.getContextPath() %>/assets/css/app.css">
</head>
<body>
<jsp:include page="/WEB-INF/views/nav.jsp"/>
<div class="wrap">
    <h2>Access Denied</h2>
    <p>
        Your role does not have permission
        <b><%= Web.esc((String) request.getAttribute("neededPerm")) %></b>
        to access this page.
    </p>
    <p>
        This restriction is enforced by the server-side filter and cannot be bypassed.
    </p>
    <p><a class="btn" href="<%= request.getContextPath() %>/dashboard">Back to Dashboard</a></p>
</div>
</body>
</html>

