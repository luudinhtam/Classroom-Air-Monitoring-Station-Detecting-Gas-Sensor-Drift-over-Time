/**
 * =========================================================================
 * Classroom Temp – Monitoring System (Room Detail room-detail.js)
 * Pure Javascript handling:
 * - Room telemetry data & threshold evaluation (supports Server Room Data)
 * - Dynamic SVG Chart rendering for 4 metrics (Temp, Humidity, CO2, CO)
 * - Independent time range switching (1h, 6h, 24h, 7d)
 * - Mouseover vertical guide line & dynamic floating tooltips
 * - Main tab navigation switching (Charts, Data History, Alert History, Room Info)
 * - Alert history tables with status badges
 * =========================================================================
 */

// 1. DATA OBJECTS & THRESHOLDS (Strictly from Server Data)
const sData = window.SERVER_ROOM_DATA || {};
const roomTelemetry = {
    hasData: Boolean(sData.hasData),
    name: sData.name || "Room",
    location: sData.location || "–",
    lastUpdated: sData.lastUpdated || "No telemetry recorded",
    sensorId: sData.sensorId || "Not Assigned",
    metrics: {
        temp: {
            value: (sData.temp !== undefined && sData.temp !== null) ? sData.temp : null,
            max: sData.tempMax || 32.0,
            unit: "°C",
            label: "Temperature",
            color: "#2563eb",
            yMin: 15,
            yMax: 35,
            ySteps: [15, 20, 25, 30, 35]
        },
        humid: {
            value: (sData.humid !== undefined && sData.humid !== null) ? sData.humid : null,
            max: sData.humidMax || 80.0,
            unit: "%",
            label: "Humidity",
            color: "#14b8a6",
            yMin: 0,
            yMax: 100,
            ySteps: [0, 20, 40, 60, 80, 100]
        },
        co2: {
            value: (sData.co2 !== undefined && sData.co2 !== null) ? sData.co2 : null,
            max: sData.co2Max || 1000,
            unit: "ppm",
            label: "CO₂",
            color: "#f59e0b",
            yMin: 0,
            yMax: 2000,
            ySteps: [0, 500, 1000, 1500, 2000]
        },
        co: {
            value: (sData.co !== undefined && sData.co !== null) ? sData.co : null,
            max: sData.coMax || 10,
            unit: "ppm",
            label: "CO",
            color: "#8b5cf6",
            yMin: 0,
            yMax: 20,
            ySteps: [0, 5, 10, 15, 20]
        }
    }
};

// Alert history logs (Only database alerts)
const alertHistoryData = Array.isArray(window.SERVER_ALERT_DATA) ? window.SERVER_ALERT_DATA : [];

// Active range for each chart (default: '6h')
const chartRanges = {
    temp: "6h",
    humid: "6h",
    co2: "6h",
    co: "6h"
};

// 2. STATUS EVALUATION LOGIC
function checkMetricStatus(metricKey) {
    const m = roomTelemetry.metrics[metricKey];
    if (m.value === null || m.value === undefined) return null;
    if (m.max !== undefined) {
        return (m.value <= m.max);
    }
    return true;
}

function checkOverallRoomStatus() {
    if (!roomTelemetry.hasData) return null;
    const tempStatus = checkMetricStatus("temp");
    const humidStatus = checkMetricStatus("humid");
    const co2Status = checkMetricStatus("co2");
    const coStatus = checkMetricStatus("co");
    if (tempStatus === null && humidStatus === null && co2Status === null && coStatus === null) return null;
    return (tempStatus !== false && humidStatus !== false && co2Status !== false && coStatus !== false);
}

// 3. UI POPULATION (HEADER & 4 METRIC CARDS)
function updateRoomHeaderAndCards() {
    const roomTitleEl = document.getElementById("roomTitle");
    if (roomTitleEl) roomTitleEl.innerText = roomTelemetry.name;

    const roomLocationEl = document.getElementById("roomLocation");
    if (roomLocationEl) roomLocationEl.innerText = roomTelemetry.location;

    const lastUpdatedEl = document.getElementById("lastUpdatedHeader");
    if (lastUpdatedEl) lastUpdatedEl.innerText = roomTelemetry.lastUpdated;

    // Overall Room Status Badge
    const overallNormal = checkOverallRoomStatus();
    const overallBadge = document.getElementById("overallRoomStatusBadge");
    const overallText = document.getElementById("overallRoomStatusText");
    if (overallBadge && overallText) {
        if (overallNormal === true) {
            overallBadge.className = "status-pill status-normal";
            overallText.innerText = "Normal";
        } else if (overallNormal === false) {
            overallBadge.className = "status-pill status-warning";
            overallText.innerText = "Warning";
        } else {
            overallBadge.className = "status-pill status-neutral";
            overallText.innerText = "No Data";
        }
    }

    // 4 Metric Cards
    const metricsConfig = [
        { key: "temp", valId: "valTemp", badgeId: "badgeTemp" },
        { key: "humid", valId: "valHumid", badgeId: "badgeHumid" },
        { key: "co2", valId: "valCo2", badgeId: "badgeCo2" },
        { key: "co", valId: "valCo", badgeId: "badgeCo" }
    ];

    metricsConfig.forEach(item => {
        const m = roomTelemetry.metrics[item.key];
        const status = checkMetricStatus(item.key);
        const valEl = document.getElementById(item.valId);
        const badgeEl = document.getElementById(item.badgeId);

        if (valEl) {
            valEl.innerText = (m.value !== null && m.value !== undefined) ? `${m.value} ${m.unit}` : "--";
        }
        if (badgeEl) {
            if (status === true) {
                badgeEl.className = "metric-pill status-normal";
                badgeEl.innerHTML = `<span class="status-dot"></span> Normal`;
            } else if (status === false) {
                badgeEl.className = "metric-pill status-warning";
                badgeEl.innerHTML = `<span class="status-dot"></span> Warning`;
            } else {
                badgeEl.className = "metric-pill status-neutral";
                badgeEl.innerHTML = `<span class="status-dot"></span> No Data`;
            }
        }
    });
}

// 4. CHART DATA FROM DATABASE SESSIONS
function generateChartPoints(type, range) {
    const rawSessions = Array.isArray(window.SERVER_SESSIONS_DATA) ? window.SERVER_SESSIONS_DATA : [];
    if (rawSessions.length === 0) {
        return { points: [], timestamps: [], xLabels: [] };
    }

    // Sessions from DAO search are ordered by measured_at DESC (newest first).
    // Sort chronologically: oldest to newest (left to right).
    const chronological = rawSessions.slice().reverse();

    // Determine cutoff if range filtering is applicable
    const latestEpoch = chronological[chronological.length - 1].epochMs || Date.now();
    let maxMs = 6 * 3600 * 1000;
    if (range === "1h") maxMs = 3600 * 1000;
    else if (range === "6h") maxMs = 6 * 3600 * 1000;
    else if (range === "24h") maxMs = 24 * 3600 * 1000;
    else if (range === "7d") maxMs = 7 * 24 * 3600 * 1000;

    let filtered = chronological.filter(s => {
        if (!s.epochMs) return true;
        return (latestEpoch - s.epochMs) <= maxMs;
    });

    if (filtered.length === 0) {
        filtered = chronological;
    }

    const points = filtered.map(s => {
        const val = s[type];
        return (val !== null && val !== undefined) ? Number(val) : 0;
    });

    const timestamps = filtered.map(s => {
        if (!s.time) return "";
        if (s.time.length >= 16) {
            return s.time.substring(11, 16);
        }
        return s.time;
    });

    // Generate readable X labels (up to 6 evenly distributed)
    const xLabels = [];
    if (filtered.length === 1) {
        xLabels.push(timestamps[0]);
    } else if (filtered.length > 1) {
        const stepCount = Math.min(6, filtered.length);
        for (let i = 0; i < stepCount; i++) {
            const idx = Math.round((i / (stepCount - 1)) * (filtered.length - 1));
            xLabels.push(timestamps[idx]);
        }
    }

    return { points, timestamps, xLabels };
}

// 5. PURE SVG CHART RENDERER
function renderSvgChart(type) {
    const containerMap = {
        temp: "chartSvgTemp",
        humid: "chartSvgHumid",
        co2: "chartSvgCo2",
        co: "chartSvgCo"
    };

    const wrapperId = containerMap[type];
    const container = document.getElementById(wrapperId);
    if (!container) return;

    const range = chartRanges[type];
    const chartConfig = roomTelemetry.metrics[type];
    const data = generateChartPoints(type, range);

    if (!data.points || data.points.length === 0) {
        container.innerHTML = `
            <div style="display: flex; flex-direction: column; align-items: center; justify-content: center; height: 180px; color: #94a3b8; font-size: 13px; gap: 8px;">
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <polyline points="22 12 18 12 15 21 9 3 6 12 2 12"/>
                </svg>
                <span>No telemetry recorded for this timeframe</span>
            </div>
        `;
        return;
    }

    const width = container.clientWidth || 395;
    const height = 180;
    const padL = 46;
    const padR = 18;
    const padT = 16;
    const padB = 26;

    const plotW = width - padL - padR;
    const plotH = height - padT - padB;

    const yMin = chartConfig.yMin;
    const yMax = chartConfig.yMax;
    const ySteps = chartConfig.ySteps;

    // Y Grid lines & Labels
    let gridSvg = "";
    ySteps.forEach(yVal => {
        const yPos = padT + (1 - (yVal - yMin) / (yMax - yMin)) * plotH;
        gridSvg += `
            <line x1="${padL}" y1="${yPos}" x2="${width - padR}" y2="${yPos}" stroke="#edf2f7" stroke-width="1" />
            <text x="${padL - 8}" y="${yPos + 3.5}" fill="#94a3b8" font-size="10" font-family="'Inter', sans-serif" text-anchor="end">${yVal}</text>
        `;
    });

    // Map point values to (x, y) coordinates
    let coords;
    if (data.points.length === 1) {
        const val = data.points[0];
        const clamped = Math.max(yMin, Math.min(yMax, val));
        const y = padT + (1 - (clamped - yMin) / (yMax - yMin)) * plotH;
        coords = [
            { x: padL, y, val, time: data.timestamps[0] },
            { x: width - padR, y, val, time: data.timestamps[0] }
        ];
    } else {
        coords = data.points.map((val, idx) => {
            const x = padL + (idx / (data.points.length - 1)) * plotW;
            const clamped = Math.max(yMin, Math.min(yMax, val));
            const y = padT + (1 - (clamped - yMin) / (yMax - yMin)) * plotH;
            return { x, y, val, time: data.timestamps[idx] };
        });
    }

    // Generate smooth bezier curve path
    let linePath = `M ${coords[0].x} ${coords[0].y}`;
    for (let i = 0; i < coords.length - 1; i++) {
        const p0 = coords[i];
        const p1 = coords[i + 1];
        const cpX = (p0.x + p1.x) / 2;
        linePath += ` C ${cpX} ${p0.y}, ${cpX} ${p1.y}, ${p1.x} ${p1.y}`;
    }

    const areaPath = `${linePath} L ${coords[coords.length - 1].x} ${padT + plotH} L ${coords[0].x} ${padT + plotH} Z`;
    const gradId = `grad_${type}`;

    // X Axis Labels
    let xLabelsSvg = "";
    if (data.xLabels.length > 0) {
        data.xLabels.forEach((label, idx) => {
            const x = padL + (idx / (data.xLabels.length - 1)) * plotW;
            xLabelsSvg += `
                <text x="${x}" y="${height - 6}" fill="#94a3b8" font-size="10" font-family="'Inter', sans-serif" text-anchor="middle">${label}</text>
            `;
        });
    }

    const lastCoord = coords[coords.length - 1];

    // Assemble complete SVG with hover layers
    container.innerHTML = `
        <div style="position: relative; width: 100%; height: 100%;">
            <svg width="100%" height="100%" viewBox="0 0 ${width} ${height}" preserveAspectRatio="none" style="overflow: visible; display: block;">
                <defs>
                    <linearGradient id="${gradId}" x1="0" y1="0" x2="0" y2="1">
                        <stop offset="0%" stop-color="${chartConfig.color}" stop-opacity="0.22" />
                        <stop offset="100%" stop-color="${chartConfig.color}" stop-opacity="0.0" />
                    </linearGradient>
                </defs>

                <!-- Grid -->
                ${gridSvg}

                <!-- Area Fill -->
                <path d="${areaPath}" fill="url(#${gradId})" />

                <!-- Main Line -->
                <path d="${linePath}" fill="none" stroke="${chartConfig.color}" stroke-width="2.3" stroke-linecap="round" stroke-linejoin="round" />

                <!-- Last Point Indicator Dot -->
                <circle cx="${lastCoord.x}" cy="${lastCoord.y}" r="4" fill="${chartConfig.color}" stroke="#ffffff" stroke-width="2" />

                <!-- X Labels -->
                ${xLabelsSvg}

                <!-- Dynamic Hover Guide Line & Indicator -->
                <line id="guideLine_${type}" x1="0" y1="${padT}" x2="0" y2="${padT + plotH}" stroke="#94a3b8" stroke-width="1.2" stroke-dasharray="3,3" opacity="0" pointer-events="none" />
                <circle id="guideCircle_${type}" cx="0" cy="0" r="5" fill="${chartConfig.color}" stroke="#ffffff" stroke-width="2.2" opacity="0" pointer-events="none" />

                <!-- Transparent Interactive Overlay -->
                <rect class="chart-mouse-overlay" x="${padL}" y="${padT}" width="${plotW}" height="${plotH}" fill="transparent" style="cursor: crosshair;" />
            </svg>

            <!-- Floating Dynamic Tooltip -->
            <div id="chartTooltip_${type}" class="chart-tooltip-box" style="display: none; top: 0; left: 0;">
                <div class="chart-tooltip-time" id="tooltipTime_${type}">--:--</div>
                <div class="chart-tooltip-value" id="tooltipVal_${type}">--</div>
            </div>
        </div>
    `;

    // Attach Mouse Events for Tooltip & Guide line
    const overlay = container.querySelector(".chart-mouse-overlay");
    const guideLine = container.querySelector(`#guideLine_${type}`);
    const guideCircle = container.querySelector(`#guideCircle_${type}`);
    const tooltip = container.querySelector(`#chartTooltip_${type}`);
    const tooltipTime = container.querySelector(`#tooltipTime_${type}`);
    const tooltipVal = container.querySelector(`#tooltipVal_${type}`);

    if (overlay && guideLine && guideCircle && tooltip) {
        overlay.addEventListener("mousemove", (e) => {
            const rect = overlay.getBoundingClientRect();
            const mouseX = e.clientX - rect.left;
            const clampedX = Math.max(0, Math.min(plotW, mouseX));
            const progress = clampedX / plotW;
            const index = Math.round(progress * (coords.length - 1));
            const pt = coords[index];

            if (pt) {
                guideLine.setAttribute("x1", pt.x);
                guideLine.setAttribute("x2", pt.x);
                guideLine.setAttribute("opacity", "1");

                guideCircle.setAttribute("cx", pt.x);
                guideCircle.setAttribute("cy", pt.y);
                guideCircle.setAttribute("opacity", "1");

                tooltipTime.innerText = pt.time;
                tooltipVal.innerText = `${pt.val} ${chartConfig.unit}`;
                tooltipVal.style.color = chartConfig.color;

                tooltip.style.left = `${pt.x}px`;
                tooltip.style.top = `${pt.y}px`;
                tooltip.style.display = "block";
            }
        });

        overlay.addEventListener("mouseleave", () => {
            guideLine.setAttribute("opacity", "0");
            guideCircle.setAttribute("opacity", "0");
            tooltip.style.display = "none";
        });
    }
}

// Render all 4 SVG charts
function renderAllSvgCharts() {
    renderSvgChart("temp");
    renderSvgChart("humid");
    renderSvgChart("co2");
    renderSvgChart("co");
}

// 6. SETUP SEGMENTED TIME RANGE CONTROLS
function setupSegmentedControls() {
    const controls = document.querySelectorAll(".segmented-control");
    controls.forEach(control => {
        const chartType = control.dataset.chart;
        const buttons = control.querySelectorAll(".seg-btn");

        buttons.forEach(btn => {
            btn.addEventListener("click", () => {
                buttons.forEach(b => b.classList.remove("active"));
                btn.classList.add("active");
                const newRange = btn.dataset.range;
                chartRanges[chartType] = newRange;
                renderSvgChart(chartType);
            });
        });
    });
}

// 7. SETUP MAIN NAVIGATION TABS
function setupMainTabs() {
    const tabBtns = document.querySelectorAll(".main-tab-btn");
    const tabPanes = document.querySelectorAll(".tab-pane");

    tabBtns.forEach(btn => {
        btn.addEventListener("click", () => {
            const targetTab = btn.dataset.tab;

            tabBtns.forEach(b => b.classList.remove("active"));
            tabPanes.forEach(p => p.classList.remove("active"));

            btn.classList.add("active");
            const targetPane = document.getElementById(`tab-${targetTab}`);
            if (targetPane) {
                targetPane.classList.add("active");
            }

            // Sync URL query param without full reload
            try {
                const u = new URL(window.location.href);
                u.searchParams.set("tab", targetTab);
                window.history.replaceState({}, "", u.toString());
            } catch (ignored) {}

            if (targetTab === "charts") {
                renderAllSvgCharts();
            }
        });
    });

    // Check URL query param ?tab=...
    try {
        const urlParams = new URLSearchParams(window.location.search);
        const activeTabParam = urlParams.get("tab");
        if (activeTabParam) {
            const targetBtn = document.querySelector(`.main-tab-btn[data-tab="${activeTabParam}"]`);
            if (targetBtn) {
                targetBtn.click();
            }
        }
    } catch (ignored) {}
}

// 8. RENDER ALERT HISTORY TABLE
function getAlertIconSvg(category) {
    if (category === "temp") {
        return `
            <div class="small-round-icon bg-red-soft">
                <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="#ef4444" stroke-width="2.3" stroke-linecap="round" stroke-linejoin="round">
                    <path d="M14 14.76V3.5a2.5 2.5 0 0 0-5 0v11.26a4.5 4.5 0 1 0 5 0z"/>
                    <circle cx="11.5" cy="17.5" r="1.5" fill="#ef4444"/>
                </svg>
            </div>
        `;
    }
    if (category === "humid") {
        return `
            <div class="small-round-icon bg-blue-soft">
                <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="#2563eb" stroke-width="2.3" stroke-linecap="round" stroke-linejoin="round">
                    <path d="M12 2.69l5.66 5.66a8 8 0 1 1-11.31 0z"/>
                </svg>
            </div>
        `;
    }
    return `
        <div class="small-round-icon bg-amber-soft">
            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="#f59e0b" stroke-width="2.3" stroke-linecap="round" stroke-linejoin="round">
                <rect x="4" y="4" width="16" height="16" rx="2"/>
                <rect x="9" y="9" width="6" height="6"/>
                <path d="M9 1v3M15 1v3M9 20v3M15 20v3M20 9h3M20 14h3M1 9h3M1 14h3"/>
            </svg>
        </div>
    `;
}

function renderAlertHistoryTable() {
    const tabContainer = document.getElementById("tabAlertTableContainer");
    // If Tab 3 is already rendered by JSP, keep the server-side rendered table intact
    if (tabContainer && tabContainer.children.length > 0) {
        return;
    }

    const tbody = document.getElementById("recentAlertTableBody");

    if (!alertHistoryData || alertHistoryData.length === 0) {
        if (tbody) {
            tbody.innerHTML = `
                <tr>
                    <td colspan="7" style="text-align: center; padding: 36px 16px; color: #94a3b8; font-weight: 500;">
                        No alerts recorded for this classroom.
                    </td>
                </tr>
            `;
        }
        if (tabContainer) {
            tabContainer.innerHTML = `
                <div style="text-align: center; padding: 48px 16px; color: #94a3b8; font-weight: 500;">
                    <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" stroke-width="2" style="margin-bottom: 8px; display: block; margin-left: auto; margin-right: auto;">
                        <circle cx="12" cy="12" r="10"/>
                        <line x1="12" y1="8" x2="12" y2="12"/>
                        <line x1="12" y1="16" x2="12.01" y2="16"/>
                    </svg>
                    No alerts recorded for this classroom.
                </div>
            `;
        }
        return;
    }

    let rowsHtml = "";
    alertHistoryData.forEach(row => {
        const isResolved = (row.statusCode === "resolved" || row.status === "Approved" || row.status === "APPROVED");
        const isRejected = (row.statusCode === "rejected" || row.status === "Rejected" || row.status === "REJECTED");
        const statusBadgeClass = isResolved ? "table-status-pill status-resolved" : (isRejected ? "table-status-pill status-rejected" : "table-status-pill status-progress");
        const dotHtml = `<span class="status-dot"></span>`;
        const userDisplay = row.handledByName || "–";
        const hasUser = userDisplay !== "–";

        rowsHtml += `
            <tr>
                <td>
                    <span class="alert-code-pill">${row.alertCode || "–"}</span>
                </td>
                <td>
                    <div class="alert-message-text">${row.message || "–"}</div>
                </td>
                <td>
                    <span class="${statusBadgeClass}">
                        ${dotHtml} ${row.status || "OPENING"}
                    </span>
                </td>
                <td>
                    <div class="cell-user-wrapper">
                        ${hasUser ? `<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#2563eb" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" style="flex-shrink: 0;"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>` : ''}
                        <span class="user-name-text">${userDisplay}</span>
                    </div>
                </td>
                <td>
                    <span class="alert-note-text">${row.note || "–"}</span>
                </td>
                <td>
                    <div class="cell-time-wrapper">
                        <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" stroke-width="2">
                            <circle cx="12" cy="12" r="10"/>
                            <polyline points="12 6 12 12 16 14"/>
                        </svg>
                        <span>${row.time || "–"}</span>
                    </div>
                </td>
            </tr>
        `;
    });

    if (tbody) {
        tbody.innerHTML = rowsHtml;
    }

    // Populate Tab 3 Alert Table Container
    if (tabContainer) {
        tabContainer.innerHTML = `
            <table class="alert-table">
                <thead>
                    <tr>
                        <th style="width: 150px;">Alert Code</th>
                        <th>Message</th>
                        <th style="width: 130px;">Status</th>
                        <th style="width: 170px;">Handled By</th>
                        <th style="width: 200px;">Note</th>
                        <th style="width: 170px;">Time</th>
                    </tr>
                </thead>
                <tbody>
                    ${rowsHtml}
                </tbody>
            </table>
        `;
    }
}

// 9. SETUP ACTION BUTTONS
function setupActionButtons() {
    const btnConfig = document.getElementById("btnConfigThresholds");
    if (btnConfig) {
        btnConfig.addEventListener("click", () => {
            alert("Configure Safety Alert Thresholds:\n- Temperature Limit: ≤ " + roomTelemetry.metrics.temp.max + "°C\n- Humidity Limit: ≤ " + roomTelemetry.metrics.humid.max + "%\n- CO₂ Warning Limit: ≤ " + roomTelemetry.metrics.co2.max + " ppm\n- CO Warning Limit: ≤ " + roomTelemetry.metrics.co.max + " ppm\n\n(Threshold configuration settings dialog)");
        });
    }
}

// 10. SETUP HEADER CONTROLS (Sidebar Toggle & User Dropdown)
function setupHeaderControls() {
    // Hamburger Sidebar Toggle
    const btnToggle = document.getElementById("btnSidebarToggle");
    if (btnToggle) {
        btnToggle.addEventListener("click", () => {
            document.body.classList.toggle("sidebar-collapsed");
            setTimeout(renderAllSvgCharts, 260);
        });
    }

    // User Profile Dropdown Toggle
    const userBadge = document.getElementById("userMenuToggle");
    const userMenu = document.getElementById("userDropdownMenu");
    if (userBadge && userMenu) {
        userBadge.addEventListener("click", (e) => {
            e.stopPropagation();
            userMenu.classList.toggle("show");
        });
        document.addEventListener("click", (e) => {
            if (!userMenu.contains(e.target)) {
                userMenu.classList.remove("show");
            }
        });
    }
}

// 11. INITIALIZATION
document.addEventListener("DOMContentLoaded", () => {
    updateRoomHeaderAndCards();
    setupMainTabs();
    setupSegmentedControls();
    setupActionButtons();
    setupHeaderControls();
    renderAlertHistoryTable();
    renderAllSvgCharts();

    window.addEventListener("resize", () => {
        renderAllSvgCharts();
    });
});
