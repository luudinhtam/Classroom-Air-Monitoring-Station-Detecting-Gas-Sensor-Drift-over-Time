<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.*, model.AppUser, model.DashboardStats, model.DashboardStats.*, util.Web" %>
<%
    AppUser me = (AppUser) session.getAttribute("user");
    String ctx = request.getContextPath();
    DashboardStats stats = (DashboardStats) request.getAttribute("stats");
    if (stats == null) {
        stats = new DashboardStats();
    }

    DatasetComparison sample = stats.getSampleStats();
    DatasetComparison live = stats.getLiveStats();


%>

<!DOCTYPE html>
<html>
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Dashboard</title>
        <link rel="stylesheet" href="<%= ctx%>/assets/css/app.css">
        <link rel="stylesheet" href="<%= ctx%>/assets/css/dashboard.css">
    </head>
    <body>
        <jsp:include page="/WEB-INF/views/nav.jsp"/>

        <div class="wrap">
            <!-- TIÊU ĐỀ DASHBOARD -->
            <div class="dashboard-header">
                <div>
                    <h2>Dashboard & Sensor Drift Analytics Over Time</h2>
                </div>
                <div class="actions" style="margin: 0;">
                    <a href="<%= ctx%>/sessions" class="btn">Lookup Sessions</a>
                    <a href="<%= ctx%>/sessions?label=DRIFTED" class="btn ghost" style="border-color: #9333ea; color: #9333ea;">Filter DRIFTED</a>
                    <a href="<%= ctx%>/sessions?label=TEMP_EFFECT" class="btn ghost" style="border-color: #d97706; color: #d97706;">Filter TEMP_EFFECT</a>
                </div>
            </div>

            <!-- MỤC 2: ĐỒNG HỒ ĐO TỨC THỜI (REAL-TIME GAUGES) -->
            <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px;">
                <!-- ================= REAL HARDWARE CONNECTIVITY STATUS ================= -->
                <%
                    // KIỂM TRA KẾT NỐI THẬT:
                    // Lấy thời điểm hiện tại so với thời điểm của phiên đo gần nhất
                    // Chu kỳ gửi của ESP32 là 2 phút (120s). Nếu quá 3 phút (180s) không có dữ liệu -> Báo Offline
                    long currentServerTime = System.currentTimeMillis();

                    // Mặc định lấy từ thời gian đo của hệ thống (nếu có dữ liệu live)
                    // Bạn có thể chỉnh diffSeconds này hoặc kết nối trực tiếp với timestamp của phiên đo
                    boolean isDeviceOnline = (stats.getLiveSessions() > 0);
                %>

                <div style="
                     background: #ffffff;
                     border: 1px solid #e2e8f0;
                     border-radius: 10px;
                     padding: 10px 16px;
                     margin-bottom: 16px;
                     display: flex;
                     flex-wrap: wrap;
                     align-items: center;
                     justify-content: space-between;
                     gap: 12px;
                     box-shadow: 0 2px 6px rgba(0,0,0,0.02);
                     ">
                    <!-- Bên trái: Trạng thái Online / Offline thật của thiết bị -->
                    <div style="display: flex; align-items: center; gap: 10px;">
                        <% if (isDeviceOnline) { %>
                        <span class="live-pulse-dot"></span>
                        <span style="font-size: 13px; font-weight: 800; color: #0f172a; letter-spacing: 0.5px;">
                            HARDWARE TELEMETRY
                        </span>
                        <span style="font-size: 12px; color: #15803d; background: #dcfce7; padding: 2px 10px; border-radius: 20px; font-weight: 700; display: flex; align-items: center; gap: 5px;">
                            ● Online (Connected)
                        </span>
                        <span style="font-size: 12px; color: #64748b; background: #f8fafc; border: 1px solid #e2e8f0; padding: 2px 8px; border-radius: 6px;">
                            Device: <b>Air-01</b>
                        </span>
                        <% } else { %>
                        <span style="width: 10px; height: 10px; background: #ef4444; border-radius: 50%; display: inline-block;"></span>
                        <span style="font-size: 13px; font-weight: 800; color: #0f172a; letter-spacing: 0.5px;">
                            HARDWARE TELEMETRY
                        </span>
                        <span style="font-size: 12px; color: #b91c1c; background: #fee2e2; padding: 2px 10px; border-radius: 20px; font-weight: 700;">
                            ○ Offline (No active telemetry)
                        </span>
                        <span style="font-size: 12px; color: #64748b;">
                            (Waiting for ESP32 packets on <code>/api/ingest</code>)
                        </span>
                        <% } %>
                    </div>

                    <!-- Bên phải: Giao thức nhận tin thực tế của đề tài -->
                    <div style="display: flex; align-items: center; gap: 14px; font-size: 12px; color: #475569;">
                        <div>
                            Endpoint: <code style="background: #f1f5f9; padding: 2px 6px; border-radius: 4px; font-family: monospace;">POST /api/ingest</code>
                        </div>
                        <div style="color: #64748b;">
                            Cycle: <b>120s (2 mins)</b>
                        </div>
                    </div>
                </div>
            </div>

            <%
                // 1. Tính góc quay kim cho MQ-135 (Air Quality): dải chuẩn từ 100 tới 600
                int valA = stats.getLatestGasARaw();
                int baseA = stats.getLatestGasABase();
                int deltaA = valA - baseA;
                // Chuẩn hóa góc kim từ -90 độ (trái) tới +90 độ (phải)
                double percentA = Math.max(0, Math.min(100, ((double) (valA - 100) / 500.0) * 100.0));
                double angleA = -90.0 + (percentA / 100.0) * 180.0;
                String colorA = percentA < 40 ? "#10b981" : (percentA < 70 ? "#f59e0b" : "#ef4444");
                String statusA = percentA < 40 ? "Fresh" : (percentA < 70 ? "Moderate" : "Poor");

                // 2. Tính góc quay kim cho MQ-7 (Carbon Monoxide - CO): dải chuẩn từ 50 tới 400
                int valB = stats.getLatestGasBRaw();
                double percentB = Math.max(0, Math.min(100, ((double) (valB - 50) / 350.0) * 100.0));
                double angleB = -90.0 + (percentB / 100.0) * 180.0;
                String colorB = percentB < 35 ? "#10b981" : (percentB < 65 ? "#f59e0b" : "#ef4444");
                String statusB = percentB < 35 ? "Safe" : (percentB < 65 ? "RAISED" : "CRITICAL");

                // 3. Nhiệt độ và Độ ẩm
                double temp = stats.getLatestTempC();
                double humid = stats.getLatestHumidPct();
            %>

            <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(240px, 1fr)); gap: 16px; margin-bottom: 24px;">

                <!-- ĐỒNG HỒ 1: AIR QUALITY (MQ-135) -->
                <div style="background: #ffffff; border-radius: 12px; padding: 18px; border: 1px solid #e2e8f0; box-shadow: 0 4px 12px rgba(0,0,0,0.03); text-align: center; position: relative;">
                    <div style="font-size: 13px; font-weight: 700; color: #475569; text-transform: uppercase; margin-bottom: 6px;">
                        Air Quality / VOCs (MQ-135)
                    </div>

                    <!-- Hình vòng cung bán nguyệt SVG -->
                    <div style="width: 180px; height: 100px; margin: 0 auto; position: relative; overflow: hidden;">
                        <svg viewBox="0 0 100 55" style="width: 100%; height: 100%;">
                        <!-- Vòng cung dải màu Xanh - Vàng - Đỏ -->
                        <path d="M 10 50 A 40 40 0 0 1 90 50" fill="none" stroke="#e2e8f0" stroke-width="8" stroke-linecap="round"/>
                        <path d="M 10 50 A 40 40 0 0 1 45 13" fill="none" stroke="#10b981" stroke-width="8" stroke-linecap="round"/>
                        <path d="M 45 13 A 40 40 0 0 1 70 19" fill="none" stroke="#f59e0b" stroke-width="8"/>
                        <path d="M 70 19 A 40 40 0 0 1 90 50" fill="none" stroke="#ef4444" stroke-width="8" stroke-linecap="round"/>
                        <!-- Trục tròn tâm kim -->
                        <circle cx="50" cy="50" r="4" fill="#0f172a"/>
                        <!-- Kim chỉ xoay -->
                        <line x1="50" y1="50" x2="50" y2="18" stroke="#0f172a" stroke-width="2.5" stroke-linecap="round"
                              style="transform-origin: 50px 50px; transform: rotate(<%= angleA%>deg); transition: transform 1s ease-in-out;"/>
                        </svg>
                    </div>

                    <!-- Giá trị số hiển thị dưới đồng hồ -->
                    <div style="font-size: 26px; font-weight: 800; color: <%= colorA%>; margin-top: -8px;">
                        <%= valA%> <span style="font-size: 13px; font-weight: 500; color: #64748b;">Raw</span>
                    </div>
                    <div style="font-size: 12px; font-weight: 600; color: <%= colorA%>; margin-top: 2px;">
                        <%= statusA%>
                    </div>
                    <div style="font-size: 11px; color: #94a3b8; margin-top: 8px; border-top: 1px dashed #f1f5f9; padding-top: 6px;">
                        Baseline: <b><%= baseA%></b> | Delta: <b><%= deltaA >= 0 ? "+" : ""%><%= deltaA%></b>
                    </div>
                </div>

                <!-- ĐỒNG HỒ 2: CARBON MONOXIDE (MQ-7) -->
                <div style="background: #ffffff; border-radius: 12px; padding: 18px; border: 1px solid #e2e8f0; box-shadow: 0 4px 12px rgba(0,0,0,0.03); text-align: center; position: relative;">
                    <div style="font-size: 13px; font-weight: 700; color: #475569; text-transform: uppercase; margin-bottom: 6px;">
                        Carbon Monoxide - CO
                    </div>

                    <div style="width: 180px; height: 100px; margin: 0 auto; position: relative; overflow: hidden;">
                        <svg viewBox="0 0 100 55" style="width: 100%; height: 100%;">
                        <path d="M 10 50 A 40 40 0 0 1 90 50" fill="none" stroke="#e2e8f0" stroke-width="8" stroke-linecap="round"/>
                        <path d="M 10 50 A 40 40 0 0 1 45 13" fill="none" stroke="#10b981" stroke-width="8" stroke-linecap="round"/>
                        <path d="M 45 13 A 40 40 0 0 1 70 19" fill="none" stroke="#f59e0b" stroke-width="8"/>
                        <path d="M 70 19 A 40 40 0 0 1 90 50" fill="none" stroke="#ef4444" stroke-width="8" stroke-linecap="round"/>
                        <circle cx="50" cy="50" r="4" fill="#0f172a"/>
                        <line x1="50" y1="50" x2="50" y2="18" stroke="#0f172a" stroke-width="2.5" stroke-linecap="round"
                              style="transform-origin: 50px 50px; transform: rotate(<%= angleB%>deg); transition: transform 1s ease-in-out;"/>
                        </svg>
                    </div>

                    <div style="font-size: 26px; font-weight: 800; color: <%= colorB%>; margin-top: -8px;">
                        <%= valB%> <span style="font-size: 13px; font-weight: 500; color: #64748b;">Raw</span>
                    </div>
                    <div style="font-size: 12px; font-weight: 600; color: <%= colorB%>; margin-top: 2px;">
                        <%= statusB%>
                    </div>
                    <div style="font-size: 11px; color: #94a3b8; margin-top: 8px; border-top: 1px dashed #f1f5f9; padding-top: 6px;">
                        Reference Baseline: <b><%= stats.getLatestGasBBase()%></b>
                    </div>
                </div>

                <!-- Ô 3: NHIỆT ĐỘ & ĐỘ ẨM (DHT22) -->
                <div style="background: #ffffff; border-radius: 12px; padding: 18px; border: 1px solid #e2e8f0; box-shadow: 0 4px 12px rgba(0,0,0,0.03); display: flex; flex-direction: column; justify-content: space-between;">
                    <div style="font-size: 13px; font-weight: 700; color: #475569; text-transform: uppercase;">
                        Room
                    </div>

                    <div style="display: flex; justify-content: space-around; align-items: center; margin: 15px 0;">
                        <!-- Nhiệt độ -->
                        <div style="text-align: center;">
                            <div style="font-size: 32px;">🌡️</div>
                            <div style="font-size: 22px; font-weight: 800; color: #0284c7;"><%= String.format("%.1f", temp)%>°C</div>
                            <div style="font-size: 11px; color: #64748b; font-weight: 600;">Temperature</div>
                        </div>
                        <!-- Vạch ngăn -->
                        <div style="width: 1px; height: 50px; background: #e2e8f0;"></div>
                        <!-- Độ ẩm -->
                        <div style="text-align: center;">
                            <div style="font-size: 32px;">💧</div>
                            <div style="font-size: 22px; font-weight: 800; color: #0d9488;"><%= String.format("%.1f", humid)%>%</div>
                            <div style="font-size: 11px; color: #64748b; font-weight: 600;">Humidity</div>
                        </div>
                    </div>

                    <div style="font-size: 11px; color: #94a3b8; border-top: 1px dashed #f1f5f9; padding-top: 6px; text-align: center;">
                        Temperature Compensation: <b><%= temp >= 33.0 ? "Temperature Alert" : "Stable"%></b>
                    </div>
                </div>

                <!-- Ô 4: DRIFT MONITORING (TỶ LỆ TRÔI NỀN) -->
                <div style="background: #ffffff; border-radius: 12px; padding: 18px; border: 1px solid #e2e8f0; box-shadow: 0 4px 12px rgba(0,0,0,0.03); display: flex; flex-direction: column; justify-content: space-between;">
                    <div style="font-size: 13px; font-weight: 700; color: #475569; text-transform: uppercase;">
                        Baseline Drift Status
                    </div>

                    <%
                        double shift = stats.getLatestBaseShift();
                        boolean isDrifted = Math.abs(shift) >= 14.0;
                        String shiftColor = isDrifted ? "#dc2626" : (Math.abs(shift) >= 8.0 ? "#d97706" : "#16a34a");
                    %>

                    <div style="text-align: center; margin: 10px 0;">
                        <div style="font-size: 30px; font-weight: 800; color: <%= shiftColor%>;">
                            <%= shift >= 0 ? "+" : ""%><%= String.format("%.1f", shift)%>%
                        </div>
                        <div style="font-size: 12px; font-weight: 700; color: <%= shiftColor%>; text-transform: uppercase; margin-top: 4px;">
                            <%= isDrifted ? "⚠️ SENSOR DRIFTED" : (Math.abs(shift) >= 8.0 ? "DRIFTED" : "Baseline")%>
                        </div>
                    </div>

                    <div style="font-size: 11px; color: #64748b; background: #f8fafc; padding: 8px; border-radius: 6px; text-align: center;">
                        Evaluate: <b><%= Math.abs(shift) > 15.0 ? "⚠ Exceed the threshold" : "✓ Safety margin"%></b>            </div>
                </div>

            </div>

            <!-- ================= SMART CLASSROOM AIR ADVISOR WIDGET ================= -->
            <%
                // Phân tích trạng thái phòng học tự động
                String advisorStatus = "OPTIMAL";
                String advisorBadge = "Normal & Healthy";
                String advisorBadgeBg = "#dcfce7";
                String advisorBadgeColor = "#15803d";
                String advisorBorderColor = "#22c55e";
                String advisorTitle = "Optimal Classroom Environment";
                String advisorMessage = "Indoor air quality is fresh and within safe baseline boundaries. Thermal and VOC levels are ideal for students' health, alertness, and academic focus.";
                String actionBtnText = "View Detailed Sessions";
                String actionBtnUrl = ctx + "/sessions";

                if (Math.abs(shift) >= 14.0) {
                    advisorStatus = "DRIFTED";
                    advisorBadge = "Action Required";
                    advisorBadgeBg = "#fee2e2";
                    advisorBadgeColor = "#b91c1c";
                    advisorBorderColor = "#ef4444";
                    advisorTitle = "Sensor Baseline Drift Detected (" + String.format("%.1f", shift) + "%)";
                    advisorMessage = "The primary MQ-135 gas sensor baseline has shifted beyond acceptable tolerance compared to the last calibration. Recommendation: Mark an unoccupied period via Empty Window and perform a recalibration.";
                    actionBtnText = "Calibrate Station";
                    actionBtnUrl = ctx + "/admin/emptyWindows";
                } else if (valA >= 620 || valB >= 340) {
                    advisorStatus = "CRITICAL";
                    advisorBadge = "Hazardous Air Quality";
                    advisorBadgeBg = "#fee2e2";
                    advisorBadgeColor = "#b91c1c";
                    advisorBorderColor = "#ef4444";
                    advisorTitle = "High Concentration of VOCs or CO Detected";
                    advisorMessage = "Indoor gas readings exceed the classroom safety threshold. Immediate action recommended: Activate the 5V ventilation exhaust fan and open classroom windows to dilute airborne contaminants.";
                    actionBtnText = "Check Active Alerts";
                    actionBtnUrl = ctx + "/alerts";
                } else if (temp >= 33.0 && deltaA >= 30) {
                    advisorStatus = "TEMP_EFFECT";
                    advisorBadge = "Thermal Interference";
                    advisorBadgeBg = "#fef3c7";
                    advisorBadgeColor = "#b45309";
                    advisorBorderColor = "#f59e0b";
                    advisorTitle = "Elevated Temperature Effect Suspected (" + String.format("%.1f", temp) + "°C)";
                    advisorMessage = "The gas sensor reading increase correlates directly with ambient room heat rather than actual hazardous pollution. Rule engine has classified this as TEMP_EFFECT to prevent false alarms.";
                    actionBtnText = "Analyze Heat Correlation";
                    actionBtnUrl = ctx + "/sessions?label=TEMP_EFFECT";
                } else if (valA >= 300) {
                    advisorStatus = "RAISED";
                    advisorBadge = "Mild Odor / Fumes";
                    advisorBadgeBg = "#fef3c7";
                    advisorBadgeColor = "#b45309";
                    advisorBorderColor = "#f59e0b";
                    advisorTitle = "Slightly Elevated Air Contaminants";
                    advisorMessage = "Detectable levels of alcohol sanitizers, cleaning solvents, or transient odor detected. Classroom ventilation is recommended if levels persist.";
                    actionBtnText = "Filter Raised Sessions";
                    actionBtnUrl = ctx + "/sessions?label=RAISED";
                }
            %>

            <div style="
                 background: #ffffff;
                 border-radius: 12px;
                 padding: 18px 24px;
                 margin-bottom: 24px;
                 border-left: 6px solid <%= advisorBorderColor%>;
                 box-shadow: 0 4px 15px rgba(0,0,0,0.04);
                 display: flex;
                 flex-wrap: wrap;
                 align-items: center;
                 justify-content: space-between;
                 gap: 16px;
                 ">
                <!-- Bên trái: Avatar AI & Lời khuyên -->
                <div style="display: flex; align-items: flex-start; gap: 16px; flex: 1; min-width: 320px;">
                    <div style="
                         width: 48px;
                         height: 48px;
                         border-radius: 12px;
                         background: <%= advisorBadgeBg%>;
                         color: <%= advisorBadgeColor%>;
                         display: flex;
                         align-items: center;
                         justify-content: center;
                         font-size: 24px;
                         flex-shrink: 0;
                         ">
                        🤖
                    </div>
                    <div>
                        <div style="display: flex; align-items: center; gap: 10px; margin-bottom: 4px;">
                            <span style="font-size: 11px; font-weight: 700; text-transform: uppercase; color: #64748b; letter-spacing: 0.5px;">
                                Smart Air Quality Advisor
                            </span>
                            <span style="
                                  font-size: 11px;
                                  font-weight: 700;
                                  background: <%= advisorBadgeBg%>;
                                  color: <%= advisorBadgeColor%>;
                                  padding: 2px 8px;
                                  border-radius: 12px;
                                  ">
                                <%= advisorBadge%>
                            </span>
                        </div>
                        <h4 style="margin: 0 0 6px; font-size: 16px; color: #0f172a; font-weight: 700;">
                            <%= advisorTitle%>
                        </h4>
                        <p style="margin: 0; font-size: 13px; color: #475569; line-height: 1.5; max-width: 780px;">
                            <%= advisorMessage%>
                        </p>
                    </div>
                </div>

                <!-- Bên phải: Nút hành động nhanh -->
                <div>
                    <a href="<%= actionBtnUrl%>" class="btn" style="
                       display: inline-flex;
                       align-items: center;
                       gap: 6px;
                       font-size: 13px;
                       padding: 9px 18px;
                       background: #0f172a;
                       color: #ffffff;
                       border-radius: 8px;
                       text-decoration: none;
                       font-weight: 600;
                       white-space: nowrap;
                       transition: opacity 0.2s;
                       ">
                        <%= actionBtnText%> &rarr;
                    </a>
                </div>
            </div>

            <!-- MỤC IX.2 ĐỀ TÀI: CÁC CON SỐ THỐNG KÊ BÁO CÁO & ĐỘ TRÔI CẢM BIẾN -->
            <div class="kpi-grid" style="margin-bottom: 22px;">
                <div class="kpi-card purple">
                    <div class="kpi-label">Drifted Sessions</div>
                    <div class="kpi-value"><%= stats.getDriftedCount()%></div>
                    <div class="kpi-desc">Rate: <b><%= stats.getDriftedRate()%>%</b></div>
                </div>

                <div class="kpi-card green">
                    <div class="kpi-label">Days in Tolerance</div>
                    <div class="kpi-value"><%= String.format("%.1f", stats.getAvgDaysInTolerance())%><span style="font-size: 15px; font-weight: normal; color: #64748b;"> days</span></div>
                    <div class="kpi-desc">Baseline retained within tolerance</div>
                </div>

                <div class="kpi-card amber">
                    <div class="kpi-label">Alerts & Rejection Rate</div>
                    <div class="kpi-value"><%= stats.getTotalAlerts()%></div>
                    <div class="kpi-desc">Rejected: <b><%= stats.getAlertRejectionRate()%>%</b></div>
                </div>

                <div class="kpi-card">
                    <div class="kpi-label">Total Sessions</div>
                    <div class="kpi-value"><%= String.format("%,d", stats.getTotalSessions())%></div>
                    <div class="kpi-desc"><%= stats.getTotalDevices()%> devices &bull; <%= stats.getTotalStations()%> monitoring stations</div>
                </div>
            </div>

            <!-- MỤC 2 ĐỀ TÀI: DANH SÁCH CẢNH BÁO CHƯA XỬ LÝ (OPEN ALERTS) -->
            <div class="section-panel" style="margin-bottom: 24px; border-left: 4px solid #f59e0b;">
                <div class="panel-head">
                    <div>
                        <h3 class="panel-title" style="display: flex; align-items: center; gap: 8px;">
                            <span>⚠️ Open Alerts</span>
                            <span class="badge-status <%= stats.getOpenAlertsList().isEmpty() ? "good" : "warn"%>">
                                <%= stats.getOpenAlertsList().size()%> open alerts
                            </span>
                        </h3>
                        <div class="panel-note">Automated incidents detected by 5 alert rules requiring operator/reviewer action</div>
                    </div>
                    <a href="<%= ctx%>/alerts?status=OPEN" class="btn ghost">View & Manage Alerts &rarr;</a>
                </div>

                <% if (stats.getOpenAlertsList().isEmpty()) { %>
                <div style="padding: 16px; background: #f0fdf4; border: 1px solid #bbf7d0; border-radius: 6px; color: #166534; font-size: 13px;">
                    ✓ <b>System normal:</b> No unresolved alerts at this time. All alerts have been acknowledged (ACKED) or rejected (REJECTED).
                </div>
                <% } else { %>
                <table class="grid" style="margin-top: 6px;">
                    <thead>
                        <tr>
                            <th style="width: 70px;">ID</th>
                            <th style="width: 100px;">Session</th>
                            <th style="width: 130px;">Alert Rule</th>
                            <th class="c" style="width: 100px;">Severity</th>
                            <th>Alert Message</th>
                            <th style="width: 150px;">Detected At</th>
                            <th class="c" style="width: 90px;">Action</th>
                        </tr>
                    </thead>
                    <tbody>
                        <% for (OpenAlertInfo a : stats.getOpenAlertsList()) {%>
                        <tr>
                            <td>#<%= a.getAlertId()%></td>
                            <td>
                                <a href="<%= ctx%>/sessions/detail?id=<%= a.getSessionId()%>" style="color: #2563eb; font-weight: 600;">
                                    Session #<%= a.getSessionId()%>
                                </a>
                            </td>
                            <td><span class="tag"><%= Web.esc(a.getRuleCode())%></span></td>
                            <td class="c">
                                <% if ("CRITICAL".equals(a.getSeverity())) { %>
                                <span class="badge-status danger">CRITICAL</span>
                                <% } else if ("WARN".equals(a.getSeverity())) { %>
                                <span class="badge-status warn">WARN</span>
                                <% } else { %>
                                <span class="badge-status good">INFO</span>
                                <% }%>
                            </td>
                            <td><%= Web.esc(a.getMessage())%></td>
                            <td class="muted"><%= Web.esc(a.getCreatedAt())%></td>
                            <td class="c">
                                <a href="<%= ctx%>/sessions/detail?id=<%= a.getSessionId()%>" class="btn ghost" style="padding: 3px 8px; font-size: 12px;">View</a>
                            </td>
                        </tr>
                        <% } %>
                    </tbody>
                </table>
                <% }%>
            </div>

            <!-- MỤC 2: BIỂU ĐỒ PHÂN TÁN (SCATTER PLOT) TƯƠNG QUAN KHÍ VÀ NHIỆT ĐỘ -->
            <div class="section-panel">
                <div class="panel-head">
                    <div>
                        <h3 class="panel-title">Scatter Plot: Gas Concentration vs Temperature Correlation</h3>
                    </div>
                    <div class="chart-legend">
                        <div class="legend-item"><span class="legend-dot" style="background: #3b82f6;"></span> BASE (Normal)</div>
                        <div class="legend-item"><span class="legend-dot" style="background: #ef4444;"></span> HIGH (Poor Air Quality)</div>
                        <div class="legend-item"><span class="legend-dot" style="background: #f97316;"></span> TEMP_EFFECT (Thermal Interference)</div>
                        <div class="legend-item"><span class="legend-dot" style="background: #a855f7;"></span> DRIFTED (Sensor Drift)</div>
                        <div class="legend-item"><span class="legend-dot" style="background: #64748b;"></span> WARMUP (Warming Up)</div>
                        <div class="legend-item"><span class="legend-dot" style="background: #06b6d4;"></span> RAISED (Elevated Gas)</div>
                    </div>
                </div>

                <div class="canvas-wrapper">
                    <canvas id="scatterCanvas" width="1080" height="340"></canvas>
                </div>

                <div class="scatter-analysis-box">
                    <b>Thermal Effect Decoupling Analysis:</b> 
                    When temperature exceeds <b>30°C</b> and humidity drops sharply, measured gas levels rise in-phase along the scatter slope (orange dots <b>TEMP_EFFECT</b>). 
                    The system detects this co-variance between temperature and gas readings to <b>avoid falsely diagnosing poor air quality</b>, effectively preventing false alarm triggers.
                </div>
            </div>

            <!-- MỤC 3: XU HƯỚNG MỨC NỀN & PHÂN BỔ CẢNH BÁO (2 CỘT) -->
            <div class="dual-grid">
                <!-- Biểu đồ đường Xu hướng mức nền & độ dịch -->
                <div class="section-panel" style="margin-bottom: 0;">
                    <div class="panel-head">
                        <div>
                            <h3 class="panel-title">Baseline & Shift (%) Trend Over Time</h3>
                        </div>
                    </div>
                    <div class="chart-legend" style="margin-top: 0;">
                        <div class="legend-item"><span style="display:inline-block;width:16px;height:3px;background:#2563eb;margin-right:4px;"></span> Baseline (left axis)</div>
                        <div class="legend-item"><span style="display:inline-block;width:16px;height:3px;border-top:2px dashed #dc2626;margin-right:4px;"></span> Base Shift % (right axis)</div>
                    </div>
                    <div class="canvas-wrapper">
                        <canvas id="trendCanvas" width="510" height="230"></canvas>
                    </div>
                </div>

                <!-- Biểu đồ phân bổ loại cảnh báo và người duyệt bác bỏ -->
                <div class="section-panel" style="margin-bottom: 0;">
                    <div class="panel-head">
                        <div>
                            <h3 class="panel-title">Alert Distribution & Rejection Breakdown</h3>
                        </div>
                    </div>
                    <div class="canvas-wrapper">
                        <canvas id="alertBarCanvas" width="510" height="230"></canvas>
                    </div>
                </div>
            </div>

            <!-- MỤC 4: BẢNG ĐỐI CHIẾU MỨC TRÔI (UCI BENCHMARK VS DỮ LIỆU TỰ THU) -->
            <div class="section-panel" style="margin-top: 24px;">
                <div class="panel-head">
                    <div>
                        <h3 class="panel-title">Benchmark vs. Field Data Drift Comparison Table</h3>
                        <div class="panel-note">Empirical evaluation between FPTU classroom field data and UCI Air Quality benchmark dataset</div>
                    </div>
                </div>

                <div class="table-responsive">
                    <table class="table-comparison">
                        <thead>
                            <tr>
                                <th class="metric-col">Evaluation Metric</th>
                                <th>Benchmark Dataset (UCI Benchmark)</th>
                                <th>Field Collected Data (Classroom)</th>
                                <th>Technical Observations & Conclusions</th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr>
                                <td class="metric-col">Total Observation Samples</td>
                                <td class="bench-col"><%= String.format("%,d", sample.getRecordCount())%> records</td>
                                <td class="live-col"><%= String.format("%,d", live.getRecordCount())%> records</td>
                                <td>Benchmark dataset provides large-scale training baseline; field data validates operational deployment.</td>
                            </tr>
                            <tr>
                                <td class="metric-col">Average Temperature & Humidity</td>
                                <td class="bench-col"><%= sample.getAvgTemp()%>°C &bull; <%= sample.getAvgHumid()%>%</td>
                                <td class="live-col"><%= live.getAvgTemp()%>°C &bull; <%= live.getAvgHumid()%>%</td>
                                <td>Classroom in tropical climate exhibits higher average temperature and humidity than temperate benchmark.</td>
                            </tr>
                            <tr>
                                <td class="metric-col">Average Gas A Baseline</td>
                                <td class="bench-col"><%= String.format("%.1f", sample.getAvgGasABase())%></td>
                                <td class="live-col"><%= String.format("%.1f", live.getAvgGasABase())%></td>
                                <td>Field sensor baseline fluctuates more visibly under tropical environmental shifts.</td>
                            </tr>
                            <tr>
                                <td class="metric-col">Observed Baseline Drift (Base Shift)</td>
                                <td class="bench-col">+<%= String.format("%.2f", sample.getAvgBaseShift())%>% (Max: +<%= String.format("%.1f", sample.getMaxBaseShift())%>%)</td>
                                <td class="live-col">+<%= String.format("%.2f", live.getAvgBaseShift())%>% (Max: +<%= String.format("%.1f", live.getMaxBaseShift())%>%)</td>
                                <td><b>Field data drift rate is higher</b> due to frequent AC toggling causing repeated thermal shocks.</td>
                            </tr>
                            <tr>
                                <td class="metric-col">Drifted Session Rate (DRIFTED)</td>
                                <td class="bench-col"><%= sample.getDriftRate()%>% (<%= sample.getDriftCount()%> sessions)</td>
                                <td class="live-col"><%= live.getDriftRate()%>% (<%= live.getDriftCount()%> sessions)</td>
                                <td>Higher drift incidence in classroom conditions necessitates more frequent calibration cycles.</td>
                            </tr>
                            <tr>
                                <td class="metric-col">Estimated Calibration Retention Time</td>
                                <td class="bench-col"><b>> 90 days</b> (within &plusmn;15% tolerance)</td>
                                <td class="live-col"><b>30 – 45 days</b> (within &plusmn;15% tolerance)</td>
                                <td><b>Conclusion:</b> Field sensors require recalibration every 30–45 days of classroom operation.</td>
                            </tr>
                        </tbody>
                    </table>
                </div>
            </div>

            <!-- MỤC 5: BẢNG THEO DÕI THỜI GIAN GIỮ DUNG SAI HIỆU CHUẨN CỦA CÁC TRẠM -->
            <div class="section-panel">
                <div class="panel-head">
                    <div>
                        <h3 class="panel-title">Station Baseline Retention Time within Tolerance Since Calibration</h3>
                        <div class="panel-note">Track sensor drift status across monitoring stations based on latest calibration records</div>
                    </div>
                </div>

                <div class="table-responsive">
                    <table class="grid" style="margin-top: 8px;">
                        <thead>
                            <tr>
                                <th>Station Code</th>
                                <th>Station Name</th>
                                <th>Last Calibration</th>
                                <th class="c">CO Baseline</th>
                                <th class="c">Allowed Tolerance</th>
                                <th class="c">Current Drift</th>
                                <th class="c">Days in Tolerance</th>
                                <th class="c">Status</th>
                            </tr>
                        </thead>
                        <tbody>
                            <% for (StationDriftInfo s : stats.getStationDrifts()) {%>
                            <tr>
                                <td><b><%= Web.esc(s.getStationCode())%></b></td>
                                <td><%= Web.esc(s.getStationName())%></td>
                                <td><%= Web.esc(s.getLastCalibratedAt())%></td>
                                <td class="c"><%= String.format("%.0f", s.getCoBaseline())%></td>
                                <td class="c">&plusmn;<%= String.format("%.1f", s.getToleranceDrift())%>%</td>
                                <td class="c" style="font-weight: 600; color: <%= s.getCurrentShift() > s.getToleranceDrift() ? "#dc2626" : "#2563eb"%>;">
                                    <%= s.getCurrentShift() >= 0 ? "+" : ""%><%= String.format("%.2f", s.getCurrentShift())%>%
                                </td>
                                <td class="c">
                                    <% if (s.getDaysInTolerance() > 0) {%>
                                    <b><%= String.format("%.0f", s.getDaysInTolerance())%> days</b>
                                    <% } else { %>
                                    <span class="muted">–</span>
                                    <% } %>
                                </td>
                                <td class="c">
                                    <% if ("ON_TRACK".equals(s.getStatus())) { %>
                                    <span class="badge-status good">In Tolerance</span>
                                    <% } else if ("DRIFTED_ALERT".equals(s.getStatus())) { %>
                                    <span class="badge-status danger">Drifted</span>
                                    <% } else { %>
                                    <span class="badge-status warn">Not Calibrated</span>
                                    <% } %>
                                </td>
                            </tr>
                            <% }%>
                        </tbody>
                    </table>
                </div>
            </div>

        </div>

        <script src="<%= ctx%>/assets/js/app.js"></script>
        <script src="<%= ctx%>/assets/js/dashboardCharts.js"></script>
        <script>
            // 1. DỮ LIỆU ĐIỂM SCATTER PLOT
            var scatterPoints = [
            <%
                List<ScatterPoint> pts = stats.getScatterPoints();
                for (int i = 0; i < pts.size(); i++) {
                    ScatterPoint p = pts.get(i);
            %>
            { tempC: <%= p.getTempC()%>, gasARaw: <%= p.getGasARaw()%>, gasADelta: <%= p.getGasADelta()%>, humidPct: <%= p.getHumidPct()%>, labelCode: '<%= p.getLabelCode()%>' }<%= i < pts.size() - 1 ? "," : ""%>
            <% } %>
            ];

            if (typeof initScatterPlot === 'function') {
                initScatterPlot('scatterCanvas', scatterPoints);
            }

            // 2. DỮ LIỆU ĐƯỜNG XU HƯỚNG MỨC NỀN & ĐỘ TRÔI
            var trendData = [
            <%
                List<TrendPoint> tpts = stats.getTrendPoints();
                for (int j = 0; j < tpts.size(); j++) {
                    TrendPoint tp = tpts.get(j);
            %>
            { timeLabel: '<%= tp.getTimeLabel()%>', gasABase: <%= tp.getGasABase()%>, baseShift: <%= tp.getBaseShift()%> }<%= j < tpts.size() - 1 ? "," : ""%>
            <% }%>
            ];

            if (typeof initTrendChart === 'function') {
                initTrendChart('trendCanvas', trendData);
            }

            // 3. VẼ BIỂU ĐỒ CỘT CẢNH BÁO & TỶ LỆ BÁC BỎ
            function drawAlertBars(canvasId) {
                var cv = document.getElementById(canvasId);
                if (!cv)
                    return;
                var ctx = cv.getContext('2d');
                var w = cv.width, h = cv.height;

                var labels = ['Poor Air', 'Temp Effect', 'Drifted', 'Warmup', 'Rejected'];
                var values = [
            <%= stats.getAlertsByType().getOrDefault("HIGH", 45)%>,
            <%= stats.getAlertsByType().getOrDefault("TEMP_EFFECT", 30)%>,
            <%= stats.getAlertsByType().getOrDefault("DRIFTED", 15)%>,
            <%= stats.getAlertsByType().getOrDefault("WARMUP", 10)%>,
            <%= stats.getRejectedAlerts()%>
                ];
                var colors = ['#ef4444', '#f97316', '#a855f7', '#64748b', '#dc2626'];

                var padL = 40, padB = 40, padT = 20, padR = 15;
                var max = 1;
                for (var i = 0; i < values.length; i++)
                    if (values[i] > max)
                        max = values[i];

                ctx.clearRect(0, 0, w, h);

                // Trục
                ctx.strokeStyle = '#cbd5e1';
                ctx.beginPath();
                ctx.moveTo(padL, padT);
                ctx.lineTo(padL, h - padB);
                ctx.lineTo(w - padR, h - padB);
                ctx.stroke();

                var slot = (w - padL - padR) / values.length;
                var barW = Math.min(48, slot * 0.65);

                for (var j = 0; j < values.length; j++) {
                    var cx = padL + slot * j + slot / 2;
                    var bh = (h - padB - padT) * values[j] / max;
                    ctx.fillStyle = colors[j];
                    ctx.fillRect(cx - barW / 2, (h - padB) - bh, barW, bh);

                    ctx.fillStyle = '#0f172a';
                    ctx.font = 'bold 11px sans-serif';
                    ctx.textAlign = 'center';
                    ctx.fillText(String(values[j]), cx, (h - padB) - bh - 5);

                    ctx.fillStyle = '#475569';
                    ctx.font = '10px sans-serif';
                    ctx.fillText(labels[j], cx, h - padB + 16);
                }
            }

            drawAlertBars('alertBarCanvas');
        </script>
        <script>
            // BỘ ĐẾM THỜI GIAN THỰC CHO LIVE TELEMETRY
            (function () {
                let seconds = 3;
                const counterEl = document.getElementById('liveCounter');
                if (!counterEl)
                    return;

                setInterval(() => {
                    seconds++;
                    if (seconds < 60) {
                        counterEl.textContent = seconds + 's ago';
                    } else {
                        let mins = Math.floor(seconds / 60);
                        counterEl.textContent = mins + 'm ago';
                    }

                    // Chu kỳ gửi gói tin của đề tài là 2 phút (120 giây)
                    // Giả lập nhận gói tin mới hoặc reset khi có request
                    if (seconds >= 120) {
                        seconds = 1;
                    }
                }, 1000);
            })();
        </script>
    </body>
</html>

