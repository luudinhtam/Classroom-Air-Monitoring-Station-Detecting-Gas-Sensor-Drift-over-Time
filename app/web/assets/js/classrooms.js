/**
 * =========================================================================
 * Classroom Temp – Monitoring System (Classrooms classrooms.js)
 * Pure Javascript handling:
 * - 24 Initial classroom dataset with environmental telemetry
 * - Seamless integration with Server Data (window.SERVER_CLASSROOMS_DATA)
 * - Dynamic 3-level evaluation (Normal, Warning, Danger) per metric
 * - Dynamic room status classification (Normal, Warning, Overheat)
 * - Automatic calculation of stats cards & alert badges
 * - Multi-criteria filter & search engine
 * - Interactive Refresh with real-time sensor fluctuation
 * - 3x3 Grid rendering & pagination controls
 * - Direct routing to Room Detail (${APP_CTX}/admin/rooms/detail?id=...)
 * =========================================================================
 */

// 1. DATASET MANAGEMENT (Strictly initialized from database via window.SERVER_CLASSROOMS_DATA)
const defaultThumbnail = (window.APP_CTX || "") + "/assets/images/classroom_default.png";

// Active copy of data (Initialised from window.SERVER_CLASSROOMS_DATA)
let classroomsData = [];

function initClassroomsData() {
    if (window.SERVER_CLASSROOMS_DATA && Array.isArray(window.SERVER_CLASSROOMS_DATA)) {
        classroomsData = JSON.parse(JSON.stringify(window.SERVER_CLASSROOMS_DATA));
    } else {
        classroomsData = [];
    }
}

// 2. STATE MANAGEMENT
const state = {
    searchQuery: "",
    status: "ALL",
    currentPage: 1,
    pageSize: 9
};

// 3. THRESHOLD RULES & STATUS EVALUATION
function getMetricLevel(metric, val) {
    if (val === null || val === undefined) return "nodata";
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
        if (val <= 1000) return "warning"; // 801 - 1000
        return "danger"; // > 1000
    }
    if (metric === "co") {
        if (val <= 5.0) return "normal";
        if (val <= 10.0) return "warning"; // > 5.0 - 10.0
        return "danger"; // > 10.0
    }
    return "normal";
}

function getRoomStatus(room) {
    // Normal if no alerts, Warning if room has opening alerts
    if (room && room.openAlerts && room.openAlerts > 0) {
        return "Warning";
    }
    return "Normal";
}

// 4. STATS CARDS CALCULATION
function updateStatsCards() {
    const total = classroomsData.length;
    let normalCount = 0;
    let warningCount = 0;

    classroomsData.forEach(r => {
        const s = getRoomStatus(r);
        if (s === "Normal") normalCount++;
        else if (s === "Warning") warningCount++;
    });

    const statTotalEl = document.getElementById("statTotal");
    const statNormalEl = document.getElementById("statNormal");
    const statNormalPctEl = document.getElementById("statNormalPct");
    const statWarningEl = document.getElementById("statWarning");
    const statWarningPctEl = document.getElementById("statWarningPct");

    if (statTotalEl) statTotalEl.innerText = total;

    if (statNormalEl) {
        statNormalEl.innerText = normalCount;
        const pct = total > 0 ? ((normalCount / total) * 100).toFixed(1) : "0.0";
        if (statNormalPctEl) statNormalPctEl.innerText = `${pct}%`;
    }

    if (statWarningEl) {
        statWarningEl.innerText = warningCount;
        const pct = total > 0 ? ((warningCount / total) * 100).toFixed(1) : "0.0";
        if (statWarningPctEl) statWarningPctEl.innerText = `${pct}%`;
    }

    // Top Bar Notification Badge & Sidebar Badge (Total opening alerts count from DB)
    const alertCount = (typeof window.OPEN_ALERT_COUNT !== "undefined") ? parseInt(window.OPEN_ALERT_COUNT, 10) : warningCount;
    const topBellBadge = document.getElementById("topBellBadge");
    const sidebarAlertBadge = document.getElementById("sidebarAlertBadge");

    if (topBellBadge) {
        topBellBadge.innerText = alertCount;
        topBellBadge.style.display = alertCount > 0 ? "flex" : "none";
    }
    if (sidebarAlertBadge) {
        sidebarAlertBadge.innerText = alertCount;
        sidebarAlertBadge.style.display = alertCount > 0 ? "inline-block" : "none";
    }
}

// 5. FILTER & SEARCH LOGIC
function updateStatCardsActiveUI() {
    const statCards = document.querySelectorAll(".stats-cards-grid .stat-card");
    statCards.forEach(card => {
        const cardStatus = card.getAttribute("data-status");
        if (cardStatus === state.status) {
            card.classList.add("active");
        } else {
            card.classList.remove("active");
        }
    });
}

function setStatCardFilter(newStatus) {
    if (state.status === newStatus && newStatus !== "ALL") {
        state.status = "ALL";
    } else {
        state.status = newStatus;
    }
    state.currentPage = 1;
    updateStatCardsActiveUI();
    renderClassrooms();
}

function getFilteredClassrooms() {
    return classroomsData.filter(room => {
        // Quick filter by status from stat-card
        if (state.status === "NORMAL" && getRoomStatus(room) !== "Normal") {
            return false;
        }
        if (state.status === "WARNING" && getRoomStatus(room) !== "Warning") {
            return false;
        }

        // Search query
        if (state.searchQuery.trim() !== "") {
            const q = state.searchQuery.toLowerCase().trim();
            const idMatch = (room.id || "").toLowerCase().includes(q);
            const nameMatch = (room.name || "").toLowerCase().includes(q);
            const locMatch = (room.location || "").toLowerCase().includes(q);
            if (!idMatch && !nameMatch && !locMatch) {
                return false;
            }
        }

        return true;
    });
}

// 6. RENDER INDIVIDUAL CLASSROOM CARD
function renderRoomCard(room) {
    // Metric levels
    const tempLvl = getMetricLevel("temp", room.temp);
    const humidLvl = getMetricLevel("humidity", room.humidity);
    const co2Lvl = getMetricLevel("co2", room.co2);
    const coLvl = getMetricLevel("co", room.co);

    // SVG icon colors based on levels
    const tempStroke = (tempLvl === "danger") ? "#ef4444" : (tempLvl === "warning") ? "#f59e0b" : (tempLvl === "nodata") ? "#94a3b8" : "#2563eb";
    const humidStroke = (humidLvl === "warning") ? "#f59e0b" : (humidLvl === "nodata") ? "#94a3b8" : "#2563eb";
    const co2Stroke = (co2Lvl === "danger") ? "#ef4444" : (co2Lvl === "warning") ? "#f59e0b" : (co2Lvl === "nodata") ? "#94a3b8" : "#2563eb";
    const coStroke = (coLvl === "danger") ? "#ef4444" : (coLvl === "warning") ? "#f59e0b" : (coLvl === "nodata") ? "#94a3b8" : "#8b5cf6";

    // Build URL to Room Detail
    const ctx = window.APP_CTX || "";
    const detailParam = room.dbId ? room.dbId : encodeURIComponent(room.id);
    const detailUrl = `${ctx}/admin/rooms/detail?id=${detailParam}`;

    // Thumbnail
    const defaultThumbnail = `${ctx}/assets/images/classroom_default.png`;
    const roomImg = room.image || defaultThumbnail;
    const roomDisplayName = room.name || room.location || `Room ${room.id}`;

    // Status badge: Warning if room has opening alerts, otherwise Normal
    const hasOpeningAlert = Boolean(room && room.openAlerts && room.openAlerts > 0);
    const statusText = hasOpeningAlert ? "Warning" : "Normal";
    const statusClass = hasOpeningAlert ? "status-warning" : "status-normal";

    return `
        <div class="classroom-card">
            <!-- Card Top Row -->
            <div class="card-top-row">
                <div class="card-thumbnail-box">
                    <img src="${roomImg}" 
                         alt="Room ${room.id}" 
                         class="card-thumbnail" 
                         onerror="this.src='${defaultThumbnail}'">
                </div>
                <div class="card-title-group">
                    <div class="card-code-status-row">
                        <span class="card-room-code">${room.id}</span>
                        <span class="status-pill ${statusClass}">
                            <span class="status-dot"></span>
                            <span>${statusText}</span>
                        </span>
                    </div>
                    <div class="card-location-row">
                        <!-- Location Pin Icon -->
                        <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="#6b7280" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                            <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"/>
                            <circle cx="12" cy="10" r="3"/>
                        </svg>
                        <span>${roomDisplayName}</span>
                    </div>
                </div>
            </div>

            <!-- Card Metrics: 2 Rows x 2 Cols (Row 1 starts with Temp, Row 2 starts with Humidity) -->
            <div class="card-metrics-grid">
                <!-- Row 1, Col 1: Temperature (Head of Row 1) -->
                <div class="metric-col level-${tempLvl}">
                    <div class="metric-mini-circle">
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="${tempStroke}" stroke-width="2.3" stroke-linecap="round" stroke-linejoin="round">
                            <path d="M14 14.76V3.5a2.5 2.5 0 0 0-5 0v11.26a4.5 4.5 0 1 0 5 0z"/>
                            <circle cx="11.5" cy="17.5" r="1.5" fill="${tempStroke}"/>
                        </svg>
                    </div>
                    <div class="metric-col-data">
                        <span class="metric-val">${room.temp != null ? room.temp + '\u00B0C' : '--'}</span>
                        <span class="metric-name">Temp</span>
                    </div>
                </div>

                <!-- Row 1, Col 2: CO2 -->
                <div class="metric-col level-${co2Lvl}">
                    <div class="metric-mini-circle">
                        <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="${co2Stroke}" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                            <path d="M17.5 19H9a7 7 0 1 1 6.71-9h1.79a4.5 4.5 0 1 1 0 9Z"/>
                        </svg>
                    </div>
                    <div class="metric-col-data">
                        <span class="metric-val">${room.co2 != null ? room.co2 + ' ppm' : '--'}</span>
                        <span class="metric-name">CO₂</span>
                    </div>
                </div>

                <!-- Row 2, Col 1: Humidity (Head of Row 2) -->
                <div class="metric-col level-${humidLvl}">
                    <div class="metric-mini-circle">
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="${humidStroke}" stroke-width="2.3" stroke-linecap="round" stroke-linejoin="round">
                            <path d="M12 2.69l5.66 5.66a8 8 0 1 1-11.31 0z"/>
                        </svg>
                    </div>
                    <div class="metric-col-data">
                        <span class="metric-val">${room.humidity != null ? room.humidity + '%' : '--'}</span>
                        <span class="metric-name">Humidity</span>
                    </div>
                </div>

                <!-- Row 2, Col 2: CO -->
                <div class="metric-col level-${coLvl}">
                    <div class="metric-mini-circle">
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="${coStroke}" stroke-width="2.3" stroke-linecap="round" stroke-linejoin="round">
                            <circle cx="12" cy="12" r="9"/>
                            <path d="M12 7v10M7 12h10"/>
                        </svg>
                    </div>
                    <div class="metric-col-data">
                        <span class="metric-val">${room.co != null ? room.co + ' ppm' : '--'}</span>
                        <span class="metric-name">CO</span>
                    </div>
                </div>
            </div>

            <!-- Card Bottom Row -->
            <div class="card-bottom-row">
                <div class="sensor-status-group">
                    <div class="sensor-online-text ${room.sensorOnline ? '' : 'sensor-offline'}">
                        <span class="sensor-online-dot ${room.sensorOnline ? '' : 'sensor-offline-dot'}"></span>
                        <span>${room.sensorOnline ? 'Sensor Online' : 'Sensor Offline'}</span>
                    </div>
                    <span class="sensor-update-time">Updated: ${room.updatedAt || 'No data'}</span>
                </div>
                <a href="${detailUrl}" class="btn-view-details">
                    <span>View Details</span>
                    <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                        <polyline points="9 18 15 12 9 6"/>
                    </svg>
                </a>
            </div>
        </div>
    `;
}

// 7. RENDER CLASSROOMS GRID & PAGINATION
function renderClassrooms() {
    const filtered = getFilteredClassrooms();
    const gridEl = document.getElementById("classroomsGrid");
    const noResultsEl = document.getElementById("noResultsBox");
    const footerCountEl = document.getElementById("footerCountText");
    const paginationEl = document.getElementById("paginationControls");

    if (!gridEl) return;

    if (filtered.length === 0) {
        gridEl.innerHTML = "";
        gridEl.style.display = "none";
        if (noResultsEl) noResultsEl.style.display = "block";
        if (footerCountEl) footerCountEl.innerText = `Showing 0 of ${classroomsData.length} classrooms`;
        if (paginationEl) paginationEl.innerHTML = "";
        return;
    }

    gridEl.style.display = "grid";
    if (noResultsEl) noResultsEl.style.display = "none";

    const totalPages = Math.ceil(filtered.length / state.pageSize) || 1;
    if (state.currentPage > totalPages) {
        state.currentPage = 1;
    }

    const startIndex = (state.currentPage - 1) * state.pageSize;
    const paginated = filtered.slice(startIndex, startIndex + state.pageSize);

    // Render 3x3 cards
    gridEl.innerHTML = paginated.map(renderRoomCard).join("");

    // Update footer count text
    if (footerCountEl) {
        footerCountEl.innerText = `Showing ${paginated.length} of ${filtered.length} classroom${filtered.length > 1 ? 's' : ''}`;
    }

    // Render pagination buttons
    renderPagination(totalPages);
}

// 8. RENDER PAGINATION BUTTONS
function renderPagination(totalPages) {
    const paginationEl = document.getElementById("paginationControls");
    if (!paginationEl) return;

    if (totalPages <= 1) {
        paginationEl.innerHTML = "";
        return;
    }

    let html = "";

    // Prev Button
    const prevDisabled = state.currentPage === 1 ? "disabled" : "";
    html += `
        <button class="page-btn page-arrow-btn" id="btnPagePrev" ${prevDisabled} title="Previous Page">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                <polyline points="15 18 9 12 15 6"/>
            </svg>
        </button>
    `;

    // Page Numbers
    for (let p = 1; p <= totalPages; p++) {
        const activeClass = (p === state.currentPage) ? "active" : "";
        html += `<button class="page-btn ${activeClass}" data-page="${p}">${p}</button>`;
    }

    // Next Button
    const nextDisabled = state.currentPage === totalPages ? "disabled" : "";
    html += `
        <button class="page-btn page-arrow-btn" id="btnPageNext" ${nextDisabled} title="Next Page">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                <polyline points="9 18 15 12 9 6"/>
            </svg>
        </button>
    `;

    paginationEl.innerHTML = html;

    // Attach listeners
    const prevBtn = document.getElementById("btnPagePrev");
    if (prevBtn && state.currentPage > 1) {
        prevBtn.addEventListener("click", () => {
            state.currentPage--;
            renderClassrooms();
            window.scrollTo({ top: 0, behavior: "smooth" });
        });
    }

    const nextBtn = document.getElementById("btnPageNext");
    if (nextBtn && state.currentPage < totalPages) {
        nextBtn.addEventListener("click", () => {
            state.currentPage++;
            renderClassrooms();
            window.scrollTo({ top: 0, behavior: "smooth" });
        });
    }

    paginationEl.querySelectorAll("button[data-page]").forEach(btn => {
        btn.addEventListener("click", (e) => {
            const page = parseInt(e.currentTarget.getAttribute("data-page"), 10);
            if (page && page !== state.currentPage) {
                state.currentPage = page;
                renderClassrooms();
                window.scrollTo({ top: 0, behavior: "smooth" });
            }
        });
    });
}

// 9. REFRESH HANDLER (Animates icon feedback only, preserves genuine database data)
function handleRefresh() {
    const refreshSvg = document.getElementById("refreshSvg");
    if (refreshSvg) {
        refreshSvg.classList.add("spinning");
        setTimeout(() => {
            refreshSvg.classList.remove("spinning");
        }, 800);
    }
}

// 10. ATTACH ALL EVENT LISTENERS
function setupEventListeners() {
    // Quick filter stat cards
    const statCards = document.querySelectorAll(".stats-cards-grid .stat-card");
    statCards.forEach(card => {
        card.addEventListener("click", () => {
            const cardStatus = card.getAttribute("data-status");
            if (cardStatus) {
                setStatCardFilter(cardStatus);
            }
        });
    });

    // Search input
    const searchInput = document.getElementById("searchInput");
    if (searchInput) {
        searchInput.addEventListener("input", (e) => {
            state.searchQuery = e.target.value;
            state.currentPage = 1;
            renderClassrooms();
        });
    }

    // Refresh button
    const btnRefresh = document.getElementById("btnRefresh");
    if (btnRefresh) {
        btnRefresh.addEventListener("click", handleRefresh);
    }

    // Hamburger Sidebar Toggle
    const btnToggle = document.getElementById("btnSidebarToggle");
    if (btnToggle) {
        btnToggle.addEventListener("click", () => {
            document.body.classList.toggle("sidebar-collapsed");
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

// 11. INITIALIZATION ON DOM READY
document.addEventListener("DOMContentLoaded", () => {
    initClassroomsData();
    setupEventListeners();
    updateStatsCards();
    updateStatCardsActiveUI();
    renderClassrooms();
});
