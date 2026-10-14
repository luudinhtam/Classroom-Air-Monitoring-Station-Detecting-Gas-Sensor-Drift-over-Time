
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
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Baseline Calculation - Air Station</title>
    <link rel="stylesheet" href="<%= ctx %>/css/app.css">
</head>
<body style="padding: 40px 100px;">

    <h1>Sensor Baseline Calculation</h1>

    <% if (errorMessage != null) { %>
        <p role="alert"><%= errorMessage %></p>
    <% } %>

    <% if (ew != null && samples != null
            && baselineCO != null && baselineCO2 != null) { %>
            
        <div style="display: flex; justify-content: space-between; align-items: flex-start; flex-wrap: wrap;">

            <!-- Empty window info: left -->
            <div>
                <h2 style="margin-top: 0; margin-bottom: 20px;">
                    Empty Window Information
                </h2>

                <table border="1" cellpadding="8" cellspacing="0">
                    <tr>
                        <th>Window Code</th>
                        <td><%= ew.getCode() %></td>
                    </tr>
                    <tr>
                        <th>Window Name</th>
                        <td><%= ew.getName() %></td>
                    </tr>
                    <tr>
                        <th>Start At</th>
                        <td><%= ew.getStartAt().format(formatter) %></td>
                    </tr>
                    <tr>
                        <th>End At</th>
                        <td><%= ew.getEndAt().format(formatter) %></td>
                    </tr>
                    <tr>
                        <th>Sample Count</th>
                        <td><%= sampleCount %></td>
                    </tr>
                </table>
            </div>

            <!-- Samples list: right -->
            <div>
                <h2 style="margin-top: 0; margin-bottom: 20px;">
                    Measurement Samples
                </h2>

                <div style="max-height: 380px; width: 650px; overflow-y: auto; border: 1px solid #ccc;">
                    <table border="1" cellpadding="8" cellspacing="0"
                           style="width: 100%; border-collapse: separate; border-spacing: 0;">

                        <thead>
                            <tr style="position: sticky; top: 0; background: #f2f2f2; z-index: 2; border: 1px solid #000;">
                                <th>#</th>
                                <th>Measured At</th>
                                <th>CO</th>
                                <th>CO₂</th>
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

            
        <h2 style="text-align: center; margin-top: 60px">Estimated Baseline Result</h2>

        <table style="width: 50%; margin: 0 auto" border="1" cellpadding="8" cellspacing="0">
            <thead>
                <tr>
                    <th>Metric</th>
                    <th>Average Value</th>
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
            <strong>Note:</strong>
            This is simulated sensor data for testing, not real measurements from a physical device.
        </p>

        <h2>Confirmation</h2>

        <p>
            Confirm only if you agree to save these two baseline values as a new Calibration record.
        </p>

        <form method="post" action="<%= ctx %>/admin/emptyWindows/baseline">

            <button class="btn" type="submit">
                Confirm & Save New Baseline
            </button>

            <a class="btn ghost" href="<%= ctx %>/admin/emptyWindows?stationId=<%= stationId %>">
                Back
            </a>
        </form>

    <% } else { %>

        <p>No baseline results to display.</p>

        <% if (stationId != null) { %>
            <a href="<%= ctx %>/admin/emptyWindows?stationId=<%= stationId %>">
                Back to Empty Windows List
            </a>
        <% } else { %>
            <a href="<%= ctx %>/admin/stations">Back to Stations List</a>
        <% } %>

    <% } %>

</body>
</html>
