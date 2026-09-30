<%-- 
    Document   : stationList
    Created on : Sep 30, 2026, 10:09:48 AM
    Author     : Welcome
--%>

<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    String lockState = (String) request.getAttribute("lockState");
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
        <div class="wrap">
            <h2>Stations (<%= request.getAttribute("total") %>)</h2>
            
            <form class="filter" method="get" action="<%= ctx %>/admin/users">
                <input type="text" name="keyword" placeholder="Ten tram"
                       value="">
                <select name="lockState">
                    <option value="">-- Moi trang thai --</option>
                    <option value="ACTIVE" <%= "ACTIVE".equals(lockState) ? "selected" : "" %>>Active</option>
                    <option value="INACTIVE" <%= "LOCKED".equals(lockState) ? "selected" : "" %>>Inactive</option>
                </select>
                <button type="submit">Loc</button>
                <a class="btn ghost" href="<%= ctx %>/admin/stations">Bo loc</a>

                <a class="btn" href="<%= ctx %>/admin/stations/create">Them tram</a>
            </form>
            
            <table class="grid">
                <tr>
                    <th>ID</th><th>Code</th><th>Name</th>
                    <th>Note</th><th class="c">Status</th><th>Created at</th><th>Thao tac</th>
                </tr>
                <tr><td colspan="6" class="c">Khong co dong nao khop bo loc</td></tr>
            </table>
            
        </div>
    </body>
</html>
