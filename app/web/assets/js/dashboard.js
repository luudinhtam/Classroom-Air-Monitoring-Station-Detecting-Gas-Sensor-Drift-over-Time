/**
 * =========================================================================
 * Classroom Air – Monitoring System (Dashboard script.js)
 * Pure Javascript handling:
 * - 24 Classrooms dataset & 8 Alerts dataset
 * - Dynamic calculations for averages, threshold levels, and room statuses
 * - Real-time date/time formatting from demoNow
 * - Metric comparisons vs. previous hour
 * - Pure SVG Trend Chart with 3 smooth lines, dynamic axes, and tooltips
 * - Pure SVG Donut Chart with interactive arc highlighting
 * - Classroom overview cards & Recent alerts table
 * - Responsive sidebar hamburger toggle
 * =========================================================================
 */

// 1. DATASETS & CONFIGURATIONS

// System reference time: from server or default 21/10/2025 13:45
const demoNow = (window.DASHBOARD_DATA && window.DASHBOARD_DATA.now)
    ? new Date(window.DASHBOARD_DATA.now)
    : new Date("2025-10-21T13:45:00");

// Actual rooms used (from backend database)
const rooms = (window.DASHBOARD_DATA && Array.isArray(window.DASHBOARD_DATA.rooms))
    ? window.DASHBOARD_DATA.rooms
    : [];

// Sensor health status dataset
const sensors = (window.DASHBOARD_DATA && window.DASHBOARD_DATA.sensors)
    ? window.DASHBOARD_DATA.sensors
    : { working: 0, warning: 0, error: 0 };

// Actual alerts used (from backend database)
const alerts = (window.DASHBOARD_DATA && Array.isArray(window.DASHBOARD_DATA.alerts))
    ? window.DASHBOARD_DATA.alerts
    : [];

// Actual session history used for trend charts (from backend database)
const history = (window.DASHBOARD_DATA && Array.isArray(window.DASHBOARD_DATA.history))
    ? window.DASHBOARD_DATA.history
    : [];

// Metric chart specifications
const METRICS_CONFIG = {
    co2: {
        name: "CO₂",
        unit: "ppm",
        yTitle: "CO₂ (ppm)",
        yMin: 0,
        yMax: 2000,
        ySteps: [0, 500, 1000, 1500, 2000],
        allowedText: "Allowed: ≤ 1000 ppm",
        color: "#16a34a",
        softBg: "#dcfce7",
        iconSvg: `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#16a34a" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M17.5 19H9a7 7 0 1 1 6.71-9h1.79a4.5 4.5 0 1 1 0 9Z"/></svg>`,
        bounds: { avg: [650, 720], min: [590, 620], max: [850, 990] }
    },
    co: {
        name: "CO",
        unit: "ppm",
        yTitle: "CO (ppm)",
        yMin: 0,
        yMax: 10,
        ySteps: [0, 2, 4, 6, 8, 10],
        allowedText: "Allowed: ≤ 10 ppm",
        color: "#8b5cf6",
        softBg: "#ede9fe",
        iconSvg: `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#8b5cf6" stroke-width="2.3" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="9"/><path d="M12 7v10M7 12h10"/></svg>`,
        bounds: { avg: [0.9, 1.3], min: [0.6, 0.8], max: [1.8, 2.1] }
    },
    temp: {
        name: "Temperature",
        unit: "°C",
        yTitle: "Temperature (°C)",
        yMin: 15,
        yMax: 35,
        ySteps: [15, 20, 25, 30, 35],
        allowedText: "Allowed: 20 – 28°C",
        color: "#2563eb",
        softBg: "#eff6ff",
        iconSvg: `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#2563eb" stroke-width="2.3" stroke-linecap="round" stroke-linejoin="round"><path d="M14 14.76V3.5a2.5 2.5 0 0 0-5 0v11.26a4.5 4.5 0 1 0 5 0z"/><circle cx="11.5" cy="17.5" r="1.5" fill="#2563eb"/></svg>`,
        bounds: { avg: [25.0, 26.5], min: [23.5, 24.2], max: [29.0, 33.1] }
    },
    humidity: {
        name: "Humidity",
        unit: "%",
        yTitle: "Humidity (%)",
        yMin: 0,
        yMax: 100,
        ySteps: [0, 20, 40, 60, 80, 100],
        allowedText: "Allowed: 40 – 70%",
        color: "#2563eb",
        softBg: "#eff6ff",
        iconSvg: `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#2563eb" stroke-width="2.3" stroke-linecap="round" stroke-linejoin="round"><path d="M12 2.69l5.66 5.66a8 8 0 1 1-11.31 0z"/></svg>`,
        bounds: { avg: [56, 60], min: [52, 55], max: [64, 68] }
    }
};

// Interactive state
let currentTrendMetric = "co2";
let currentTrendRange = "24h";

// 2. THRESHOLD RULES & EVALUATION
function getMetricLevel(metric, val) {
    if (metric === "temp") {
        if (val >= 20.0 && val <= 28.0) return "normal";
        if ((val > 28.0 && val <= 30.0) || val < 20.0) return "warning";
        return "danger"; // > 30.0
    }
    if (metric === "humidity") {
        if (val >= 40 && val <= 70) return "normal";
        return "warning"; // out of 40-70%
    }
    if (metric === "co2") {
        if (val <= 800) return "normal";
        if (val <= 1000) return "warning";
        return "danger";
    }
    if (metric === "co") {
        if (val <= 5.0) return "normal";
        if (val <= 10.0) return "warning";
        return "danger";
    }
    return "normal";
}

function getRoomStatus(room) {
    const tempLvl = getMetricLevel("temp", room.temp);
    if (tempLvl === "danger") return "Overheat";

    const humidLvl = getMetricLevel("humidity", room.humidity);
    const co2Lvl = getMetricLevel("co2", room.co2);
    const coLvl = getMetricLevel("co", room.co);

    if (
        tempLvl === "warning" ||
        humidLvl === "warning" ||
        co2Lvl === "warning" || co2Lvl === "danger" ||
        coLvl === "warning" || coLvl === "danger"
    ) {
        return "Warning";
    }

    return "Normal";
}

// 3. COMPUTATIONS
function computeAverages() {
    const withData = rooms.filter(r => r.hasData !== false && r.temp !== null && !isNaN(r.temp));
    if (withData.length === 0) {
        return { co2: null, co: null, temp: null, humidity: null };
    }
    const total = withData.length;
    let sumCo2 = 0, sumCo = 0, sumTemp = 0, sumHumid = 0;
    let co2Count = 0, coCount = 0;

    withData.forEach(r => {
        if (r.co2 !== null && !isNaN(r.co2)) {
            sumCo2 += r.co2;
            co2Count++;
        }
        if (r.co !== null && !isNaN(r.co)) {
            sumCo += r.co;
            coCount++;
        }
        sumTemp += r.temp;
        sumHumid += r.humidity;
    });

    return {
        co2: co2Count > 0 ? Math.round(sumCo2 / co2Count) : null,
        co: coCount > 0 ? Math.round((sumCo / coCount) * 10) / 10 : null,
        temp: Math.round((sumTemp / total) * 10) / 10,
        humidity: Math.round(sumHumid / total)
    };
}

function computeRoomCounts() {
    let normal = 0, warning = 0, overheat = 0, noData = 0;
    rooms.forEach(r => {
        if (r.hasData === false) {
            noData++;
            return;
        }
        const s = getRoomStatus(r);
        if (s === "Normal") normal++;
        else if (s === "Warning") warning++;
        else if (s === "Overheat") overheat++;
        else normal++;
    });
    return { total: rooms.length, normal, warning, overheat, noData };
}

// 4. RENDER DATE & TIME (Dynamically calculated day of week)
function renderHeaderDate() {
    const dayNames = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
    const monthNames = [
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"
    ];

    const dayOfWeek = dayNames[demoNow.getDay()];
    const day = demoNow.getDate();
    const month = monthNames[demoNow.getMonth()];
    const year = demoNow.getFullYear();

    const hours = String(demoNow.getHours()).padStart(2, "0");
    const minutes = String(demoNow.getMinutes()).padStart(2, "0");

    const dateTextEl = document.getElementById("currentDateText");
    const timeTextEl = document.getElementById("currentTimeText");

    if (dateTextEl) dateTextEl.innerText = `${dayOfWeek}, ${day} ${month} ${year}`;
    if (timeTextEl) timeTextEl.innerText = `${hours}:${minutes}`;

    const sidebarUpdateEl = document.getElementById("sidebarLastUpdate");
    if (sidebarUpdateEl) {
        const dd = String(day).padStart(2, "0");
        const mm = String(demoNow.getMonth() + 1).padStart(2, "0");
        sidebarUpdateEl.innerText = `${dayOfWeek}, ${dd}/${mm}/${year}, ${hours}:${minutes}`;
    }
}

// 5. RENDER ALERT BADGES
function renderAlertBadge() {
    const activeCount = alerts.filter(a => a.status === "Active").length;
    const topBellBadge = document.getElementById("topBellBadge");
    const sidebarAlertBadge = document.getElementById("sidebarAlertBadge");

    if (topBellBadge) {
        topBellBadge.innerText = activeCount;
        topBellBadge.style.display = activeCount > 0 ? "flex" : "none";
    }
    if (sidebarAlertBadge) {
        sidebarAlertBadge.innerText = activeCount;
        sidebarAlertBadge.style.display = activeCount > 0 ? "inline-block" : "none";
    }
}

// 6. RENDER 4 STATS CARDS
function renderStatCards() {
    const serverStats = (window.DASHBOARD_DATA && window.DASHBOARD_DATA.stats) ? window.DASHBOARD_DATA.stats : {};
    const total = (serverStats.totalRooms !== undefined) ? serverStats.totalRooms : rooms.length;
    const openingAlerts = (serverStats.openAlerts !== undefined) ? serverStats.openAlerts : alerts.length;
    const activeDev = (serverStats.activeDevices !== undefined) ? serverStats.activeDevices : 0;
    const inactiveDev = (serverStats.inactiveDevices !== undefined) ? serverStats.inactiveDevices : 0;

    const statTotalEl = document.getElementById("statTotal");
    if (statTotalEl) statTotalEl.innerText = total;

    const statOpeningEl = document.getElementById("statOpeningAlerts");
    if (statOpeningEl) statOpeningEl.innerText = openingAlerts;

    const statActiveEl = document.getElementById("statActiveDevices");
    if (statActiveEl) statActiveEl.innerText = activeDev;

    const statInactiveEl = document.getElementById("statInactiveDevices");
    if (statInactiveEl) statInactiveEl.innerText = inactiveDev;

    const totalUsers = (serverStats.totalUsers !== undefined) ? serverStats.totalUsers : 0;
    const statUsersEl = document.getElementById("statTotalUsers");
    if (statUsersEl) statUsersEl.innerText = totalUsers;
}

function renderDiffRow(elementId, diff, type) {
    const el = document.getElementById(elementId);
    if (!el) return;

    if (diff === 0) {
        el.className = "stat-diff-row diff-no-change";
        el.innerHTML = `<span>—</span><span>No change vs. last hour</span>`;
        return;
    }

    const isPositive = diff > 0;
    const sign = isPositive ? "+" : "";
    const text = `${sign}${diff} vs. last hour`;

    // Arrow SVG
    const arrowUp = `<svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><line x1="12" y1="19" x2="12" y2="5"/><polyline points="5 12 12 5 19 12"/></svg>`;
    const arrowDown = `<svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><line x1="12" y1="5" x2="12" y2="19"/><polyline points="19 12 12 19 5 12"/></svg>`;
    const icon = isPositive ? arrowUp : arrowDown;

    let colorClass = "";
    if (type === "normal") {
        colorClass = isPositive ? "diff-positive-green" : "diff-negative-red";
    } else if (type === "warning") {
        colorClass = "diff-amber";
    } else if (type === "overheat") {
        colorClass = "diff-red";
    }

    el.className = `stat-diff-row ${colorClass}`;
    el.innerHTML = `${icon}<span>${text}</span>`;
}

// 7. RENDER AIR QUALITY OVERVIEW
function renderAirQuality() {
    let avg = computeAverages();
    if (avg.temp === null && history.length > 0) {
        const validH = history.filter(h => h.temp !== null && !isNaN(h.temp));
        if (validH.length > 0) {
            let sumCo2 = 0, sumCo = 0, sumTemp = 0, sumHumid = 0;
            let co2C = 0, coC = 0, tempC = 0, humC = 0;
            validH.forEach(h => {
                if (h.co2 !== null && !isNaN(h.co2)) { sumCo2 += h.co2; co2C++; }
                if (h.co !== null && !isNaN(h.co)) { sumCo += h.co; coC++; }
                if (h.temp !== null && !isNaN(h.temp)) { sumTemp += h.temp; tempC++; }
                if (h.humidity !== null && !isNaN(h.humidity)) { sumHumid += h.humidity; humC++; }
            });
            avg = {
                co2: co2C > 0 ? Math.round(sumCo2 / co2C) : null,
                co: coC > 0 ? Math.round((sumCo / coC) * 10) / 10 : null,
                temp: tempC > 0 ? Math.round((sumTemp / tempC) * 10) / 10 : null,
                humidity: humC > 0 ? Math.round(sumHumid / humC) : null
            };
        }
    }

    const co2El = document.getElementById("avgCo2Val");
    if (co2El) co2El.innerText = avg.co2 !== null ? avg.co2 : "--";

    const coEl = document.getElementById("avgCoVal");
    if (coEl) coEl.innerText = avg.co !== null ? avg.co.toFixed(1) : "--";

    const tempEl = document.getElementById("avgTempVal");
    if (tempEl) tempEl.innerText = avg.temp !== null ? avg.temp.toFixed(1) : "--";

    const humidEl = document.getElementById("avgHumidVal");
    if (humidEl) humidEl.innerText = avg.humidity !== null ? avg.humidity : "--";

    // Apply color to range based on status of average value if data exists
    if (avg.co2 !== null) applyRangeColor("avgCo2Range", getMetricLevel("co2", avg.co2));
    if (avg.co !== null) applyRangeColor("avgCoRange", getMetricLevel("co", avg.co));
    if (avg.temp !== null) applyRangeColor("avgTempRange", getMetricLevel("temp", avg.temp));
    if (avg.humidity !== null) applyRangeColor("avgHumidRange", getMetricLevel("humidity", avg.humidity));
}

function applyRangeColor(elementId, level) {
    const el = document.getElementById(elementId);
    if (!el) return;
    el.className = `air-metric-range range-${level}`;
}

// 8. GENERATE TREND CHART DATA & RENDERING
// Deterministic pseudo-random generator with fixed seed
function seededRandom(seed) {
    const x = Math.sin(seed) * 10000;
    return x - Math.floor(x);
}

function generateTrendData(metricKey, rangeKey) {
    const cfg = METRICS_CONFIG[metricKey];

    // Priority 1: Use actual database historical measurements from Air_Session
    if (history && history.length > 0) {
        const validPoints = history.filter(h => h[metricKey] !== null && !isNaN(h[metricKey]));
        if (validPoints.length > 0) {
            const allVals = validPoints.map(p => p[metricKey]);
            const actualMin = Math.min(...allVals);
            const actualMax = Math.max(...allVals);

            return validPoints.map(p => {
                const val = p[metricKey];
                return {
                    avg: val,
                    min: actualMin,
                    max: actualMax,
                    time: p.time
                };
            });
        }
    }

    // Priority 2: Use room temp / sensor measurements
    const avgVal = computeAverages()[metricKey];
    if (avgVal === null || rooms.length === 0) {
        return [];
    }

    const validRooms = rooms.filter(r => r.hasData !== false && r[metricKey] !== null && !isNaN(r[metricKey]));
    if (validRooms.length === 0) {
        return [];
    }

    const allVals = validRooms.map(r => r[metricKey]);
    const actualMin = Math.min(...allVals);
    const actualMax = Math.max(...allVals);

    return validRooms.map(r => ({
        avg: r[metricKey],
        min: actualMin,
        max: actualMax,
        time: r.id
    }));
}

function renderTrendChart() {
    const cfg = METRICS_CONFIG[currentTrendMetric];
    const trendData = generateTrendData(currentTrendMetric, currentTrendRange);
    const svg = document.getElementById("trendSvg");
    if (!svg) return;

    // Update Y Title
    document.getElementById("chartYTitle").innerText = cfg.yTitle;

    const W = 510;
    const H = 240;
    const padL = 42;
    const padR = 14;
    const padT = 16;
    const padB = 34;

    const plotW = W - padL - padR;
    const plotH = H - padT - padB;

    let svgHtml = "";

    // 1. Horizontal faint grid lines & Y labels
    const steps = cfg.ySteps;
    steps.forEach(val => {
        const normY = (val - cfg.yMin) / (cfg.yMax - cfg.yMin);
        const yPos = padT + plotH - normY * plotH;

        // Grid line
        svgHtml += `<line x1="${padL}" y1="${yPos}" x2="${W - padR}" y2="${yPos}" stroke="#f1f5f9" stroke-width="1"/>`;
        // Label
        svgHtml += `<text x="${padL - 8}" y="${yPos + 3.5}" font-size="10" fill="#94a3b8" text-anchor="end" font-weight="600">${val.toLocaleString()}</text>`;
    });

    if (trendData.length === 0) {
        svgHtml += `<text x="${W / 2}" y="${H / 2}" font-size="13" fill="#94a3b8" text-anchor="middle" font-weight="500">No sensor data available</text>`;
        svg.innerHTML = svgHtml;
        return;
    }

    // 2. X Axis ticks & Labels from real data timestamps
    const numTicks = trendData.length;
    trendData.forEach((d, idx) => {
        if (numTicks > 8 && idx % 2 !== 0 && idx !== numTicks - 1) return;
        const xPos = padL + (idx / Math.max(1, numTicks - 1)) * plotW;
        const lbl = d.time || `T${idx+1}`;
        svgHtml += `<text x="${xPos}" y="${H - 12}" font-size="10" fill="#94a3b8" text-anchor="middle" font-weight="500">${lbl}</text>`;
    });

    // Coordinate mapping helper
    const getX = (idx) => padL + (idx / Math.max(1, trendData.length - 1)) * plotW;
    const getY = (val) => {
        const norm = (val - cfg.yMin) / (cfg.yMax - cfg.yMin);
        return padT + plotH - Math.max(0, Math.min(1, norm)) * plotH;
    };

    // 3. Build single path for Average of all classrooms (Blue) with subtle area fill
    const pathAvg = buildSmoothCurve(trendData.map((d, i) => ({ x: getX(i), y: getY(d.avg) })));

    if (trendData.length > 1) {
        const firstX = getX(0);
        const lastX = getX(trendData.length - 1);
        const bottomY = padT + plotH;
        svgHtml += `
            <defs>
                <linearGradient id="trendAreaGradient" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="0%" stop-color="#2563eb" stop-opacity="0.18"/>
                    <stop offset="100%" stop-color="#2563eb" stop-opacity="0.0"/>
                </linearGradient>
            </defs>
            <path d="${pathAvg} L ${lastX} ${bottomY} L ${firstX} ${bottomY} Z" fill="url(#trendAreaGradient)"/>
        `;
    }

    svgHtml += `<path d="${pathAvg}" fill="none" stroke="#2563eb" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/>`;

    // Dots at points for average
    trendData.forEach((d, i) => {
        svgHtml += `<circle cx="${getX(i)}" cy="${getY(d.avg)}" r="3.5" fill="#2563eb" stroke="#ffffff" stroke-width="1.5"/>`;
    });

    svg.innerHTML = svgHtml;

    // Attach interactive hover
    setupChartHover(trendData, padL, plotW, getX, getY, cfg);
}

function getXAxisLabels(rangeKey) {
    if (rangeKey === "24h") {
        return ["14:00", "17:00", "20:00", "23:00", "02:00", "05:00", "08:00", "11:00"];
    }
    if (rangeKey === "6h") {
        return ["08:00", "09:00", "10:00", "11:00", "12:00", "13:00"];
    }
    if (rangeKey === "7d") {
        const shortDays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
        const labels = [];
        for (let i = 6; i >= 0; i--) {
            const d = new Date(demoNow);
            d.setDate(d.getDate() - i);
            labels.push(shortDays[d.getDay()]);
        }
        return labels;
    }
    return [];
}

// Catmull-Rom or cubic bezier smooth curve builder
function buildSmoothCurve(points) {
    if (points.length === 0) return "";
    let d = `M ${points[0].x.toFixed(1)} ${points[0].y.toFixed(1)}`;
    for (let i = 0; i < points.length - 1; i++) {
        const p0 = points[i === 0 ? i : i - 1];
        const p1 = points[i];
        const p2 = points[i + 1];
        const p3 = points[i + 2] || p2;

        const cp1x = p1.x + (p2.x - p0.x) / 6;
        const cp1y = p1.y + (p2.y - p0.y) / 6;
        const cp2x = p2.x - (p3.x - p1.x) / 6;
        const cp2y = p2.y - (p3.y - p1.y) / 6;

        d += ` C ${cp1x.toFixed(1)} ${cp1y.toFixed(1)}, ${cp2x.toFixed(1)} ${cp2y.toFixed(1)}, ${p2.x.toFixed(1)} ${p2.y.toFixed(1)}`;
    }
    return d;
}

function setupChartHover(trendData, padL, plotW, getX, getY, cfg) {
    const container = document.getElementById("chartContainer");
    const guideLine = document.getElementById("chartGuideLine");
    const tooltip = document.getElementById("chartTooltip");
    if (!container || !guideLine || !tooltip) return;

    container.onmousemove = (e) => {
        const rect = container.getBoundingClientRect();
        const mouseX = e.clientX - rect.left;

        if (mouseX < padL || mouseX > padL + plotW) {
            guideLine.style.display = "none";
            tooltip.style.display = "none";
            return;
        }

        const frac = (mouseX - padL) / plotW;
        const idx = Math.max(0, Math.min(trendData.length - 1, Math.round(frac * (trendData.length - 1))));
        const dataPoint = trendData[idx];

        const xPos = getX(idx);
        guideLine.style.left = `${xPos}px`;
        guideLine.style.display = "block";

        const pointLabel = dataPoint.time ? `${dataPoint.time}` : `Point #${idx + 1}`;
        tooltip.innerHTML = `
            <div style="font-weight:700; color:#0f1b3d; margin-bottom:4px;">${pointLabel}</div>
            <div style="color:#2563eb; font-weight:700; font-size:13px;">Average: ${dataPoint.avg} ${cfg.unit}</div>
        `;

        const tooltipX = Math.min(rect.width - 130, Math.max(10, xPos - 55));
        tooltip.style.left = `${tooltipX}px`;
        tooltip.style.top = `40px`;
        tooltip.style.display = "block";
    };

    container.onmouseleave = () => {
        guideLine.style.display = "none";
        tooltip.style.display = "none";
    };
}

// 9. RENDER TREND SUMMARY CARD
function renderTrendSummary() {
    const cfg = METRICS_CONFIG[currentTrendMetric];
    let avgVal = computeAverages()[currentTrendMetric];
    if ((avgVal === null || isNaN(avgVal)) && history.length > 0) {
        const validH = history.filter(h => h[currentTrendMetric] !== null && !isNaN(h[currentTrendMetric]));
        if (validH.length > 0) {
            const sum = validH.reduce((acc, h) => acc + h[currentTrendMetric], 0);
            avgVal = (currentTrendMetric === "co2" || currentTrendMetric === "humidity")
                ? Math.round(sum / validH.length)
                : Math.round((sum / validH.length) * 10) / 10;
        }
    }

    const iconBox = document.getElementById("summaryIconBox");
    if (iconBox) {
        iconBox.innerHTML = cfg.iconSvg;
        iconBox.style.background = cfg.softBg;
    }

    document.getElementById("summaryMetricName").innerText = cfg.name;
    let dispVal = "--";
    if (avgVal !== null && !isNaN(avgVal)) {
        dispVal = (currentTrendMetric === "co" || currentTrendMetric === "temp") ? avgVal.toFixed(1) : avgVal;
    }
    document.getElementById("summaryMetricVal").innerText = dispVal;
    document.getElementById("summaryMetricUnit").innerText = cfg.unit;
    document.getElementById("summaryRangeText").innerText = cfg.allowedText;

    // Render Sparkline SVG (Smooth area fill + line)
    const sparkSvg = document.getElementById("sparklineSvg");
    if (!sparkSvg) return;

    const sparkData = generateTrendData(currentTrendMetric, "24h");
    if (sparkData.length === 0) {
        sparkSvg.innerHTML = "";
        return;
    }

    const W = 200, H = 50;
    const vals = sparkData.map(d => d.avg);
    const minV = Math.min(...vals);
    const maxV = Math.max(...vals);
    const span = (maxV - minV) || 1;

    const getSx = (i) => (i / (vals.length - 1)) * W;
    const getSy = (v) => H - 6 - ((v - minV) / span) * (H - 12);

    let linePath = `M ${getSx(0)} ${getSy(vals[0])}`;
    for (let i = 1; i < vals.length; i++) {
        linePath += ` L ${getSx(i).toFixed(1)} ${getSy(vals[i]).toFixed(1)}`;
    }
    const areaPath = `${linePath} L ${W} ${H} L 0 ${H} Z`;

    sparkSvg.innerHTML = `
        <defs>
            <linearGradient id="sparkGrad" x1="0" y1="0" x2="0" y2="1">
                <stop offset="0%" stop-color="${cfg.color}" stop-opacity="0.25"/>
                <stop offset="100%" stop-color="${cfg.color}" stop-opacity="0.0"/>
            </linearGradient>
        </defs>
        <path d="${areaPath}" fill="url(#sparkGrad)"/>
        <path d="${linePath}" fill="none" stroke="${cfg.color}" stroke-width="2" stroke-linecap="round"/>
    `;
}

// 10. RENDER CLASSROOM OVERVIEW (4 First Rooms)
function renderClassroomOverview() {
    const grid = document.getElementById("classroomOverviewGrid");
    if (!grid) return;

    if (rooms.length === 0) {
        grid.innerHTML = `<div style="grid-column: 1/-1; padding: 24px; text-align: center; color: #94a3b8; font-weight: 500;">No classrooms found in database.</div>`;
        return;
    }

    const displayRooms = rooms.slice(0, 6);
    let html = "";

    displayRooms.forEach(room => {
        let statusBadge = "";
        let tempVal = "--";
        let humidVal = "--";
        let co2Val = "--";
        let coVal = "--";
        let tempLvl = "normal", humidLvl = "normal", co2Lvl = "normal", coLvl = "normal";

        if (room.hasData === false) {
            statusBadge = `<span class="status-pill" style="background:#f1f5f9; color:#64748b;"><span class="status-dot-sm" style="background:#94a3b8;"></span>No Data</span>`;
        } else {
            const status = getRoomStatus(room);
            if (status === "Normal") {
                statusBadge = `<span class="status-pill status-normal"><span class="status-dot-sm"></span>Normal</span>`;
            } else if (status === "Warning") {
                statusBadge = `<span class="status-pill status-warning">
                    <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="#f59e0b" stroke-width="2.5"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/></svg>Warning</span>`;
            } else {
                statusBadge = `<span class="status-pill status-overheat"><span class="status-dot-sm"></span>Overheat</span>`;
            }

            tempVal = room.temp !== null ? `${room.temp}°C` : "--";
            humidVal = room.humidity !== null ? `${room.humidity}%` : "--";
            co2Val = room.co2 !== null ? `${room.co2} ppm` : "--";
            coVal = room.co !== null ? `${room.co} ppm` : "--";

            tempLvl = room.temp !== null ? getMetricLevel("temp", room.temp) : "normal";
            humidLvl = room.humidity !== null ? getMetricLevel("humidity", room.humidity) : "normal";
            co2Lvl = room.co2 !== null ? getMetricLevel("co2", room.co2) : "normal";
            coLvl = room.co !== null ? getMetricLevel("co", room.co) : "normal";
        }

        const defaultImg = (window.DASHBOARD_DATA && window.DASHBOARD_DATA.defaultImage)
            ? window.DASHBOARD_DATA.defaultImage
            : 'classroom_default.png';
        
        let roomHref = "#";
        if (window.DASHBOARD_DATA && window.DASHBOARD_DATA.roomDetailUrl) {
            const separator = window.DASHBOARD_DATA.roomDetailUrl.includes("?") ? "&" : "?";
            roomHref = `${window.DASHBOARD_DATA.roomDetailUrl}${separator}id=${encodeURIComponent(room.dbId || room.id)}`;
        }

        html += `
            <a href="${roomHref}" class="overview-room-card" title="View details of ${room.id}">
                <!-- Top Row: Thumb, ID & Status -->
                <div class="room-card-top">
                    <img src="${defaultImg}" alt="${room.id}" class="room-thumb-img" onerror="this.src='${defaultImg}'">
                    <div class="room-code-badge">
                        <span class="room-id-bold">${room.id}</span>
                        ${statusBadge}
                    </div>
                </div>

                <!-- 2x2 Metrics Grid: Row 1 Temp & Humid, Row 2 CO2 & CO -->
                <div class="room-card-metrics-2x2">
                    <!-- Row 1: Temp -->
                    <div class="room-mini-metric ${tempLvl === 'warning' ? 'val-warning' : tempLvl === 'danger' ? 'val-danger' : ''}">
                        <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.3"><path d="M14 14.76V3.5a2.5 2.5 0 0 0-5 0v11.26a4.5 4.5 0 1 0 5 0z"/></svg>
                        <span>${tempVal}</span>
                    </div>

                    <!-- Row 1: Humid -->
                    <div class="room-mini-metric ${humidLvl === 'warning' ? 'val-warning' : ''}">
                        <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.3"><path d="M12 2.69l5.66 5.66a8 8 0 1 1-11.31 0z"/></svg>
                        <span>${humidVal}</span>
                    </div>

                    <!-- Row 2: CO2 -->
                    <div class="room-mini-metric ${co2Lvl === 'warning' ? 'val-warning' : co2Lvl === 'danger' ? 'val-danger' : ''}">
                        <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><path d="M17.5 19H9a7 7 0 1 1 6.71-9h1.79a4.5 4.5 0 1 1 0 9Z"/></svg>
                        <span>${co2Val}</span>
                    </div>

                    <!-- Row 2: CO -->
                    <div class="room-mini-metric ${coLvl === 'warning' ? 'val-warning' : coLvl === 'danger' ? 'val-danger' : ''}">
                        <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.3"><circle cx="12" cy="12" r="9"/></svg>
                        <span>${coVal}</span>
                    </div>
                </div>

                <!-- Right Chevron -->
                <div class="room-card-chevron">
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="9 18 15 12 9 6"/></svg>
                </div>
            </a>
        `;
    });

    grid.innerHTML = html;
}

// 11. SENSOR STATUS (Card removed as requested)
function renderSensorStatus() {
    // Sensor status card removed
}

// 12. RECENT ALERTS (Section removed as requested)
function renderRecentAlerts() {
    // Recent alerts section removed
}

// 13. CONTROLS & EVENT LISTENERS SETUP
function setupControls() {
    // Hamburger Sidebar Toggle
    const btnToggle = document.getElementById("btnSidebarToggle");
    if (btnToggle) {
        btnToggle.addEventListener("click", () => {
            document.body.classList.toggle("sidebar-collapsed");
        });
    }

    // Trend Metric Pills
    const metricPills = document.querySelectorAll("#metricPills .metric-pill");
    metricPills.forEach(pill => {
        pill.addEventListener("click", () => {
            metricPills.forEach(p => p.classList.remove("active"));
            pill.classList.add("active");
            currentTrendMetric = pill.getAttribute("data-metric");
            renderTrendChart();
            renderTrendSummary();
        });
    });

    // Trend Time Range Dropdown
    const rangeSelect = document.getElementById("rangeSelect");
    if (rangeSelect) {
        rangeSelect.addEventListener("change", (e) => {
            currentTrendRange = e.target.value;
            const subtitleEl = document.getElementById("trendSubtitle");
            if (subtitleEl) {
                const label = e.target.options[e.target.selectedIndex].text;
                subtitleEl.innerText = `(${label})`;
            }
            renderTrendChart();
            renderTrendSummary();
        });
    }

    // View All Sensors link
    const btnViewSensors = document.getElementById("btnViewAllSensors");
    if (btnViewSensors) {
        btnViewSensors.addEventListener("click", (e) => {
            if (window.DASHBOARD_DATA && window.DASHBOARD_DATA.devicesUrl) {
                window.location.href = window.DASHBOARD_DATA.devicesUrl;
            } else {
                e.preventDefault();
                alert("Opening sensor list...");
            }
        });
    }

    // View All Alerts link
    const btnViewAlerts = document.getElementById("btnViewAllAlerts");
    if (btnViewAlerts) {
        btnViewAlerts.addEventListener("click", (e) => {
            if (window.DASHBOARD_DATA && window.DASHBOARD_DATA.alertsUrl) {
                window.location.href = window.DASHBOARD_DATA.alertsUrl;
            } else {
                e.preventDefault();
                alert("Opening all alerts...");
            }
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

// 14. MASTER INITIALIZATION FUNCTION
function renderAll() {
    try { renderHeaderDate(); } catch (e) { console.error("Error in renderHeaderDate:", e); }
    try { renderAlertBadge(); } catch (e) { console.error("Error in renderAlertBadge:", e); }
    try { renderStatCards(); } catch (e) { console.error("Error in renderStatCards:", e); }
    try { renderAirQuality(); } catch (e) { console.error("Error in renderAirQuality:", e); }
    try { renderTrendChart(); } catch (e) { console.error("Error in renderTrendChart:", e); }
    try { renderTrendSummary(); } catch (e) { console.error("Error in renderTrendSummary:", e); }
    try { renderClassroomOverview(); } catch (e) { console.error("Error in renderClassroomOverview:", e); }
    try { renderRecentAlerts(); } catch (e) { console.error("Error in renderRecentAlerts:", e); }
    try { setupControls(); } catch (e) { console.error("Error in setupControls:", e); }
}

document.addEventListener("DOMContentLoaded", renderAll);
