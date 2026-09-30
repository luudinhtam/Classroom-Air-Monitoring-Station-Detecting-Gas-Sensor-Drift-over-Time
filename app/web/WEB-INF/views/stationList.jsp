<%-- 
    Document   : stationList
    Created on : Sep 30, 2026, 10:09:48 AM
    Author     : Welcome
--%>

<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    String ctx = request.getContextPath();
%>
<!DOCTYPE html>
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <title>Stations</title>
        <link rel="stylesheet" href="<%= ctx %>/css/app.css">
    </head>
    
    <body>
        <jsp:include page="/WEB-INF/views/nav.jsp"/>
        <h1>Hello World!</h1>
        
    </body>
</html>
