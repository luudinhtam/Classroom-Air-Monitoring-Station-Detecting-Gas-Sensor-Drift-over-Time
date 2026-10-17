

<%@page import="java.time.format.DateTimeFormatter"%>
<%@page import="util.Web"%>
<%@page import="model.AirStation"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>

<%
    AirStation item = (AirStation) request.getAttribute("detail");
    String error = (String) request.getAttribute("error");
    String ctx = request.getContextPath();
    DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
%>

<!DOCTYPE html>
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Air Station Details</title>
        <link rel="stylesheet" href="<%= ctx %>/css/app.css">
    </head>
    <body>
        <jsp:include page="/WEB-INF/views/nav.jsp"/>
        <div class="wrap">
            <h2>Air Station Details</h2>

            <% if (item == null) { %>

                <p>Air station not found.</p>

        <% } else { %>

            <div>
                <p>
                    <strong>Station ID:</strong>
                    <%= item.getStationId() %>
                </p>

                <p>
                    <strong>Code:</strong>
                    <%= Web.esc(item.getCode()) %>
                </p>

                <p>
                    <strong>Name:</strong>
                    <%= Web.esc(item.getName()) %>
                </p>

                <p>
                    <strong>Location:</strong>
                    <%= Web.esc(item.getLocation()) %>
                </p>

                <p>
                    <strong>CO Warning Threshold:</strong>
                    <%= item.getCoWarningThreshold() %>
                </p>

                <p>
                    <strong>CO2 Warning Threshold:</strong>
                    <%= item.getCo2WarningThreshold() %>
                </p>

                <p>
                    <strong>Maximum Baseline Drift:</strong>
                    <%= item.getMaxBaselineDrift() %>
                </p>

                <p>
                    <strong>Device Code:</strong>
                    <%= Web.esc(item.getDeviceCode()) %>
                </p>

                <p>
                    <strong>Note:</strong>
                    <%= item.getNote() == null ? "" : Web.esc(item.getNote()) %>
                </p>

                <p>
                    <strong>Status:</strong>
                    <%= item.isActive() ? "Active" : "Inactive" %>
                </p>

                <p>
                    <strong>Created At:</strong>
                    <%= item.getCreatedAt().toLocalDateTime().format(formatter) %>
                </p>
            </div>

        <% } %>

        <p style="margin-top: 20px;">
            <a class="btn ghost" href="${pageContext.request.contextPath}/admin/stations">
                &larr; Back to Stations
            </a>
        </p>
        </div>
    </body>
</html>
