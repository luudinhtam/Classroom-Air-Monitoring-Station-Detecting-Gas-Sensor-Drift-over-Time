

<%@page import="util.Web"%>
<%@page import="model.AirStation"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>

<%
    AirStation item = (AirStation) request.getAttribute("detail");
    String error = (String) request.getAttribute("error");
    String ctx = request.getContextPath();
%>

<!DOCTYPE html>
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <title>Air Station Detail</title>
    </head>
    <body>
        <h1>Air Station Detail</h1>

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
                    <strong>Device Key:</strong>
                    <%= Web.esc(item.getDeviceKey()) %>
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
                    <%= item.getCreatedAt() %>
                </p>
            </div>

        <% } %>

        <p>
            <a href="${pageContext.request.contextPath}/admin/stations">
                Back to Stations
            </a>
        </p>
    </body>
</html>
