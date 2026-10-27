/**
 * Devices Management Page Script – Classroom Air Monitoring System
 * Handles client-side state, reactive filtering, SVG Donut rendering,
 * interactive table sorting, row selection, pagination, and refresh fluctuation.
 */

// Global state and real current time
let demoNow = new Date();

const badges = {
    bell: 7,
    sidebarAlerts: 3
};

// Devices list populated strictly from server database
let devices = [];

// Recent Activity log entries
const recentActivities = [];

const pageSize = 14;

// Filter, Sort, and Pagination state
const state = {
    keyword: "",
    filterStatus: "ALL",
    filterClassroom: "ALL",
    sortKey: null,
    sortDir: "asc",
    currentPage: 1,
    selectedIds: new Set()
};

/* =============================================================================
   1. DATE & TIME FORMATTING
   ============================================================================= */
function formatDateTime(date) {
    if (!date) date = new Date();
    const days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
    const months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
    
    const dayName = days[date.getDay()];
    const day = date.getDate();
    const monthName = months[date.getMonth()];
    const year = date.getFullYear();
    
    const hours = String(date.getHours()).padStart(2, "0");
    const minutes = String(date.getMinutes()).padStart(2, "0");
    
    return {
        dateString: `${dayName}, ${day} ${monthName} ${year}`,
        timeString: `${hours}:${minutes}`,
        dateOnlySlash: `${String(day).padStart(2, "0")}/${String(date.getMonth() + 1).padStart(2, "0")}/${year} ${hours}:${minutes}`,
        sidebarDateTime: `${dayName}, ${String(day).padStart(2, "0")}/${String(date.getMonth() + 1).padStart(2, "0")}/${year}, ${hours}:${minutes}`
    };
}

function renderHeaderDate() {
    const fmt = formatDateTime(new Date());
    const dateEl = document.getElementById("headerDateText");
    const timeEl = document.getElementById("headerTimeText");
    if (dateEl) dateEl.textContent = fmt.dateString;
    if (timeEl) timeEl.textContent = fmt.timeString;
}

function renderSidebarFooter() {
    const fmt = formatDateTime(new Date());
    const footerTimeEl = document.getElementById("sidebarLastUpdate");
    if (footerTimeEl) {
        footerTimeEl.textContent = fmt.sidebarDateTime;
    }
}

// Keep sidebar time & header time ticking live
setInterval(() => {
    renderHeaderDate();
    renderSidebarFooter();
}, 10000);

function renderBadges() {
    const bellBadge = document.getElementById("topBellBadge");
    const sidebarAlertBadge = document.getElementById("sidebarAlertBadge");
    if (bellBadge) bellBadge.textContent = badges.bell;
    if (sidebarAlertBadge) sidebarAlertBadge.textContent = badges.sidebarAlerts;
}

/* =============================================================================
   2. STAT CARDS CALCULATION & RENDERING
   ============================================================================= */
function renderStatCards() {
    const total = devices.length;
    let activeCount = 0;
    let inactiveCount = 0;

    devices.forEach(d => {
        const isAct = d.isActive !== undefined ? Boolean(d.isActive) : ((d.status || "").toLowerCase() === "active");
        if (isAct) activeCount++;
        else inactiveCount++;
    });

    const activePct = total > 0 ? ((activeCount / total) * 100).toFixed(1) : "0.0";
    const inactivePct = total > 0 ? ((inactiveCount / total) * 100).toFixed(1) : "0.0";

    const totalEl = document.getElementById("statTotalDevices");
    const activeEl = document.getElementById("statOnlineCount");
    const activePctEl = document.getElementById("statOnlinePct");
    const inactiveEl = document.getElementById("statInactiveCount");
    const inactivePctEl = document.getElementById("statInactivePct");

    if (totalEl) totalEl.textContent = total;
    if (activeEl) activeEl.textContent = activeCount;
    if (activePctEl) activePctEl.textContent = `${activePct}%`;
    if (inactiveEl) inactiveEl.textContent = inactiveCount;
    if (inactivePctEl) inactivePctEl.textContent = `${inactivePct}%`;
}

/* =============================================================================
   3. CLASSROOM OPTIONS POPULATION
   ============================================================================= */
function populateClassroomOptions() {
    const classroomSet = new Set();
    devices.forEach(d => {
        if (d.classroom && d.classroom !== "-") {
            classroomSet.add(d.classroom);
        }
    });

    const sortedClassrooms = Array.from(classroomSet).sort((a, b) => a.localeCompare(b));
    const container = document.getElementById("classroomOptionsList");
    if (!container) return;

    container.innerHTML = `<div class="option-item ${state.filterClassroom === 'ALL' ? 'selected' : ''}" data-val="ALL">All Classrooms</div>`;
    sortedClassrooms.forEach(cr => {
        const item = document.createElement("div");
        item.className = `option-item ${state.filterClassroom === cr ? 'selected' : ''}`;
        item.setAttribute("data-val", cr);
        item.textContent = cr;
        container.appendChild(item);
    });
}

/* =============================================================================
   4. FILTERING & SORTING LOGIC
   ============================================================================= */
function applyFilters() {
    const kw = state.keyword.trim().toLowerCase();

    return devices.filter(d => {
        // Keyword search across id, classroom
        if (kw) {
            const idMatch = (d.id || "").toLowerCase().includes(kw);
            const classMatch = (d.classroom || "").toLowerCase().includes(kw);
            if (!idMatch && !classMatch) return false;
        }

        // Status filter (Active / Inactive)
        if (state.filterStatus !== "ALL") {
            const isAct = d.isActive !== undefined ? Boolean(d.isActive) : ((d.status || "").toLowerCase() === "active");
            const filterAct = state.filterStatus.toLowerCase() === "active";
            if (isAct !== filterAct) {
                return false;
            }
        }

        // Classroom filter
        if (state.filterClassroom !== "ALL") {
            if ((d.classroom || "").toLowerCase() !== state.filterClassroom.toLowerCase()) {
                return false;
            }
        }

        return true;
    });
}

function parseLastSeen(str) {
    if (!str) return 0;
    // Format: "23/10/2026 13:42" or ISO
    const parts = str.split(" ");
    if (parts.length === 2) {
        const dparts = parts[0].split("/");
        const tparts = parts[1].split(":");
        if (dparts.length === 3 && tparts.length === 2) {
            return new Date(dparts[2], dparts[1] - 1, dparts[0], tparts[0], tparts[1]).getTime();
        }
    }
    const parsed = Date.parse(str);
    return isNaN(parsed) ? 0 : parsed;
}

function sortDevices(filteredList) {
    if (!state.sortKey) return filteredList;

    return [...filteredList].sort((a, b) => {
        let valA = a[state.sortKey];
        let valB = b[state.sortKey];

        if (state.sortKey === "lastSeen") {
            valA = parseLastSeen(valA);
            valB = parseLastSeen(valB);
            return state.sortDir === "asc" ? valA - valB : valB - valA;
        }

        valA = (valA || "").toString().toLowerCase();
        valB = (valB || "").toString().toLowerCase();

        const cmp = valA.localeCompare(valB);
        return state.sortDir === "asc" ? cmp : -cmp;
    });
}

/* =============================================================================
   5. TABLE & PAGINATION RENDERING
   ============================================================================= */
function renderTable() {
    const tbody = document.getElementById("devicesTableBody");
    if (!tbody) return;

    const filtered = applyFilters();
    const sorted = sortDevices(filtered);

    const totalCount = sorted.length;
    const totalPages = Math.ceil(totalCount / pageSize) || 1;

    // Boundary check for current page
    if (state.currentPage > totalPages) {
        state.currentPage = totalPages;
    }
    if (state.currentPage < 1) {
        state.currentPage = 1;
    }

    const startIndex = (state.currentPage - 1) * pageSize;
    const pageItems = sorted.slice(startIndex, startIndex + pageSize);

    tbody.innerHTML = "";

    if (pageItems.length === 0) {
        const tr = document.createElement("tr");
        tr.innerHTML = `<td colspan="6" class="empty-table-state">No devices found</td>`;
        tbody.appendChild(tr);
    } else {
        pageItems.forEach(d => {
            const tr = document.createElement("tr");
            const isSelected = state.selectedIds.has(d.id);
            if (isSelected) tr.classList.add("row-selected");

            // Status badge and icon (Active / Inactive)
            const isDeviceActive = (d.isActive !== undefined) ? Boolean(d.isActive) : ((d.status || "").toLowerCase() === "active");
            const statusLabel = isDeviceActive ? "Active" : "Inactive";
            const statusClass = isDeviceActive ? "online" : "inactive";
            const statusIcon = isDeviceActive 
                ? `<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                     <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/>
                   </svg>`
                : `<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                     <circle cx="12" cy="12" r="10"/><line x1="4.93" y1="4.93" x2="19.07" y2="19.07"/>
                   </svg>`;

            const devNum = d.deviceId || d.id;
            const appCtx = window.APP_CTX || '';

            tr.innerHTML = `
                <td class="col-check">
                    <div class="custom-checkbox ${isSelected ? 'checked' : ''}" data-device-id="${d.id}">
                        <svg class="check-tick" width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="#ffffff" stroke-width="3" stroke-linecap="round" stroke-linejoin="round">
                            <polyline points="20 6 9 17 4 12"/>
                        </svg>
                    </div>
                </td>
                <td class="col-id"><span class="dev-id-text">${d.id}</span></td>
                <td class="col-classroom"><span class="classroom-text">${d.classroom || '-'}</span></td>
                <td class="col-status">
                    <span class="status-pill ${statusClass}">
                        ${statusIcon}
                        <span>${statusLabel}</span>
                    </span>
                </td>
                <td class="col-seen">${d.lastSeen || 'Never'}</td>
                <td class="col-actions">
                    <div class="actions-cell">
                        <button type="button" class="btn-act btn-act-purple" title="View API Key"
                                onclick="openApiKeyModal('${d.id}', '${(d.apiKey || '').replace(/'/g, "\\'")}')">
                            API Key
                        </button>
                        <button type="button" class="btn-act btn-act-blue" title="View device details"
                                onclick="openDeviceDetailModal('${d.id}')">
                            Detail
                        </button>
                        <form method="post" action="${appCtx}/admin/devices/delete"
                              onsubmit="return confirm('Are you sure you want to delete device ${d.id}?');">
                            <input type="hidden" name="id" value="${devNum}">
                            <button type="submit" class="btn-act btn-act-red" title="Delete device">
                                Delete
                            </button>
                        </form>
                    </div>
                </td>
            `;
            tbody.appendChild(tr);
        });
    }

    renderFooterCount(startIndex, pageItems.length, totalCount);
    renderPagination(totalPages);
    updateSelectAllCheckbox(pageItems);
}

function renderFooterCount(start, currentCount, total) {
    const el = document.getElementById("footerCountText");
    if (!el) return;

    if (total === 0) {
        el.textContent = "Showing 0 of 0 devices";
    } else {
        const from = start + 1;
        const to = start + currentCount;
        el.textContent = `Showing ${from}–${to} of ${total} devices`;
    }
}

function renderPagination(totalPages) {
    const container = document.getElementById("paginationControls");
    if (!container) return;

    container.innerHTML = "";

    // Prev Button «
    const prevBtn = document.createElement("button");
    prevBtn.className = "page-btn";
    prevBtn.innerHTML = "&laquo;";
    prevBtn.disabled = state.currentPage <= 1;
    prevBtn.onclick = () => {
        if (state.currentPage > 1) {
            state.currentPage--;
            renderTable();
        }
    };
    container.appendChild(prevBtn);

    // Page Numbers
    for (let p = 1; p <= totalPages; p++) {
        const pBtn = document.createElement("button");
        pBtn.className = `page-btn ${p === state.currentPage ? 'active' : ''}`;
        pBtn.textContent = p;
        pBtn.onclick = () => {
            state.currentPage = p;
            renderTable();
        };
        container.appendChild(pBtn);
    }

    // Next Button »
    const nextBtn = document.createElement("button");
    nextBtn.className = "page-btn";
    nextBtn.innerHTML = "&raquo;";
    nextBtn.disabled = state.currentPage >= totalPages;
    nextBtn.onclick = () => {
        if (state.currentPage < totalPages) {
            state.currentPage++;
            renderTable();
        }
    };
    container.appendChild(nextBtn);
}

/* =============================================================================
   7. CHECKBOX SELECTION MANAGEMENT
   ============================================================================= */
function updateSelectAllCheckbox(pageItems) {
    const selectAllBox = document.getElementById("selectAllCheckbox");
    if (!selectAllBox || pageItems.length === 0) {
        if (selectAllBox) {
            selectAllBox.classList.remove("checked", "indeterminate");
        }
        return;
    }

    const selectedOnPage = pageItems.filter(item => state.selectedIds.has(item.id));
    
    if (selectedOnPage.length === 0) {
        selectAllBox.classList.remove("checked", "indeterminate");
    } else if (selectedOnPage.length === pageItems.length) {
        selectAllBox.classList.add("checked");
        selectAllBox.classList.remove("indeterminate");
    } else {
        selectAllBox.classList.remove("checked");
        selectAllBox.classList.add("indeterminate");
    }
}

function setupSelectAll() {
    const selectAllBox = document.getElementById("selectAllCheckbox");
    if (!selectAllBox) return;

    selectAllBox.addEventListener("click", () => {
        const filtered = applyFilters();
        const sorted = sortDevices(filtered);
        const startIndex = (state.currentPage - 1) * pageSize;
        const pageItems = sorted.slice(startIndex, startIndex + pageSize);

        const allSelected = pageItems.every(item => state.selectedIds.has(item.id));

        if (allSelected) {
            // Uncheck all on current page
            pageItems.forEach(item => state.selectedIds.delete(item.id));
        } else {
            // Check all on current page
            pageItems.forEach(item => state.selectedIds.add(item.id));
        }

        renderTable();
    });

    // Row checkbox delegated event
    const tbody = document.getElementById("devicesTableBody");
    if (tbody) {
        tbody.addEventListener("click", e => {
            const cb = e.target.closest(".custom-checkbox");
            if (cb && cb.id !== "selectAllCheckbox") {
                const devId = cb.getAttribute("data-device-id");
                if (devId) {
                    if (state.selectedIds.has(devId)) {
                        state.selectedIds.delete(devId);
                    } else {
                        state.selectedIds.add(devId);
                    }
                    renderTable();
                }
            }
        });
    }
}

/* =============================================================================
   8. ROW ACTION MENU
   ============================================================================= */
window.handleMenuAction = function(action, deviceId) {
    if (action === "view") {
        alert(`View details: ${deviceId}`);
    } else if (action === "restart") {
        alert(`Restarting device ${deviceId}...`);
    } else if (action === "remove") {
        alert(`Removing device ${deviceId}...`);
    }
    closeAllMenus();
};

function closeAllMenus() {
    document.querySelectorAll(".row-action-menu.active").forEach(m => m.classList.remove("active"));
}

function setupRowMenu() {
    document.addEventListener("click", e => {
        const menuBtn = e.target.closest(".btn-row-menu");
        if (menuBtn) {
            e.stopPropagation();
            const devId = menuBtn.getAttribute("data-menu-id");
            const targetMenu = document.getElementById(`menu-${devId}`);
            const wasActive = targetMenu && targetMenu.classList.contains("active");
            closeAllMenus();
            if (targetMenu && !wasActive) {
                targetMenu.classList.add("active");
            }
        } else if (!e.target.closest(".row-action-menu")) {
            closeAllMenus();
        }
    });
}

/* =============================================================================
   9. RIGHT COLUMN CARDS: DONUT CHART, TYPES & RECENT ACTIVITY
   ============================================================================= */
function renderDeviceStatusDonut() {
    const total = devices.length;
    let activeCount = 0;
    let inactiveCount = 0;

    devices.forEach(d => {
        const isAct = d.isActive !== undefined ? Boolean(d.isActive) : ((d.status || "").toLowerCase() === "active");
        if (isAct) activeCount++;
        else inactiveCount++;
    });

    const activePct = total > 0 ? ((activeCount / total) * 100).toFixed(1) : "0.0";
    const inactivePct = total > 0 ? ((inactiveCount / total) * 100).toFixed(1) : "0.0";

    const lTotal = document.getElementById("donutCenterTotal");
    const lOnline = document.getElementById("legendOnlineCount");
    const lOnlinePct = document.getElementById("legendOnlinePct");
    const lWarn = document.getElementById("legendWarningCount");
    const lWarnPct = document.getElementById("legendWarningPct");
    const lErr = document.getElementById("legendErrorCount");
    const lErrPct = document.getElementById("legendErrorPct");

    if (lTotal) lTotal.textContent = total;
    if (lOnline) lOnline.textContent = activeCount;
    if (lOnlinePct) lOnlinePct.textContent = `${activePct}%`;
    if (lWarn) lWarn.textContent = inactiveCount;
    if (lWarnPct) lWarnPct.textContent = `${inactivePct}%`;
    if (lErr) lErr.textContent = 0;
    if (lErrPct) lErrPct.textContent = `0.0%`;

    const svg = document.getElementById("deviceStatusDonutSvg");
    if (!svg) return;

    const r = 48;
    const c = 2 * Math.PI * r;
    const gap = total > 1 && inactiveCount > 0 && activeCount > 0 ? 3 : 0;

    const onLen = total > 0 ? Math.max(0, (activeCount / total) * c - gap) : 0;
    const inactLen = total > 0 ? Math.max(0, (inactiveCount / total) * c - gap) : 0;

    svg.innerHTML = `
        <circle cx="59" cy="59" r="${r}" fill="none" stroke="#f1f5f9" stroke-width="13" />
        <!-- Inactive Segment (Slate/Gray) -->
        <circle id="donutSegWarn" class="donut-segment" cx="59" cy="59" r="${r}" fill="none" stroke="#94a3b8" 
            stroke-width="13" stroke-dasharray="${inactLen} ${c - inactLen}" stroke-dashoffset="0"
            transform="rotate(-90 59 59)" />
        <!-- Active Segment (Green) -->
        <circle id="donutSegOn" class="donut-segment" cx="59" cy="59" r="${r}" fill="none" stroke="#16a34a" 
            stroke-width="13" stroke-dasharray="${onLen} ${c - onLen}" stroke-dashoffset="${-(inactLen + gap)}"
            transform="rotate(-90 59 59)" />
    `;

    setupDonutHighlight("legendRowOnline", "donutSegOn");
    setupDonutHighlight("legendRowWarning", "donutSegWarn");
}

function setupDonutHighlight(rowId, arcId) {
    const row = document.getElementById(rowId);
    if (!row) return;

    row.addEventListener("mouseenter", () => {
        const arc = document.getElementById(arcId);
        if (arc) arc.classList.add("highlight");
    });
    row.addEventListener("mouseleave", () => {
        const arc = document.getElementById(arcId);
        if (arc) arc.classList.remove("highlight");
    });
}

function renderRecentActivity() {
    const container = document.getElementById("recentActivityFeed");
    if (!container) return;

    container.innerHTML = "";

    recentActivities.forEach(item => {
        let dotClass = "ok";
        let idClass = "navy-id";
        let msgClass = "ok-msg";

        if (item.type === "warning") {
            dotClass = "warn";
            idClass = "red-id";
            msgClass = "warn-msg";
        } else if (item.type === "error") {
            dotClass = "err";
            idClass = "red-id";
            msgClass = "err-msg";
        }

        const div = document.createElement("div");
        div.className = "activity-item";
        div.innerHTML = `
            <div class="activity-dot-col">
                <span class="activity-dot ${dotClass}"></span>
            </div>
            <div class="activity-content">
                <div class="activity-line-top">
                    <span class="act-id ${idClass}">${item.device}</span>
                    <span class="act-msg ${msgClass}">${item.content}</span>
                </div>
                <div class="activity-line-time">${item.time}</div>
            </div>
        `;
        container.appendChild(div);
    });
}

/* =============================================================================
   10. REFRESH HANDLER (TIME ADVANCE & SUBTLE JIGGLE)
   ============================================================================= */
function handleRefresh() {
    const refreshBtn = document.getElementById("btnRefresh");
    const icon = document.getElementById("refreshIcon");

    if (icon) {
        icon.classList.add("spinning");
        setTimeout(() => {
            icon.classList.remove("spinning");
        }, 800);
    }

    // Advance demoNow by 1 minute
    demoNow = new Date(demoNow.getTime() + 60 * 1000);
    renderHeaderDate();
    renderSidebarFooter();

    // Jiggle temp +/- 0.3 and humidity +/- 2 for devices with readings
    devices.forEach(d => {
        if (d.temp !== null && d.temp !== undefined) {
            const deltaT = (Math.random() * 0.6 - 0.3);
            d.temp = Number((d.temp + deltaT).toFixed(1));
        }
        if (d.humidity !== null && d.humidity !== undefined) {
            const deltaH = Math.round(Math.random() * 4 - 2);
            d.humidity = Math.max(10, Math.min(99, d.humidity + deltaH));
        }
    });

    // Re-render table and stat views
    renderTable();
}

/* =============================================================================
   10B. STAT CARDS INSTANT FILTERING & SYNC
   ============================================================================= */
function updateStatusSelectBoxUI(status) {
    const box = document.getElementById("statusSelectBox");
    if (!box) return;
    const popup = box.querySelector(".select-options-popup");
    if (!popup) return;

    const norm = (status || "ALL").toUpperCase();
    let selectedLabel = "All Statuses";

    popup.querySelectorAll(".option-item").forEach(opt => {
        const optVal = (opt.getAttribute("data-val") || "ALL").toUpperCase();
        const isMatch = optVal === norm;
        opt.classList.toggle("selected", isMatch);
        if (isMatch) {
            selectedLabel = opt.textContent;
        }
    });

    const valEl = box.querySelector(".select-val-row");
    if (valEl) valEl.textContent = selectedLabel;
}

function updateStatCardsActive(status) {
    const norm = (status || "ALL").toUpperCase();
    const cards = document.querySelectorAll(".stats-cards-grid .stat-card");
    if (!cards || cards.length === 0) return;

    cards.forEach(c => {
        c.classList.remove("active", "active-blue", "active-green", "active-slate");
    });

    if (norm === "ALL" && cards[0]) {
        cards[0].classList.add("active", "active-blue");
    } else if (norm === "ACTIVE" && cards[1]) {
        cards[1].classList.add("active", "active-green");
    } else if (norm === "INACTIVE" && cards[2]) {
        cards[2].classList.add("active", "active-slate");
    }
}

function setDeviceStatusFilter(status) {
    const norm = (status || "ALL").toUpperCase();
    state.filterStatus = (norm === "ACTIVE") ? "Active" : ((norm === "INACTIVE") ? "Inactive" : "ALL");
    state.currentPage = 1;

    updateStatusSelectBoxUI(state.filterStatus);
    updateStatCardsActive(state.filterStatus);

    try {
        const url = new URL(window.location.href);
        if (state.filterStatus !== "ALL") {
            url.searchParams.set("status", state.filterStatus);
        } else {
            url.searchParams.delete("status");
        }
        window.history.replaceState({}, "", url.toString());
    } catch (e) {}

    renderTable();
}

function filterByDeviceStatus(val) {
    const current = (state.filterStatus || "ALL").toUpperCase();
    const target = (val || "ALL").toUpperCase();
    const next = (current === target && target !== "ALL") ? "ALL" : val;
    setDeviceStatusFilter(next);
}

window.state = state;
window.setDeviceStatusFilter = setDeviceStatusFilter;
window.filterByDeviceStatus = filterByDeviceStatus;

/* =============================================================================
   11. EVENT LISTENERS SETUP
   ============================================================================= */
function setupEventListeners() {
    // Search input
    const searchInput = document.getElementById("searchInput");
    if (searchInput) {
        searchInput.addEventListener("input", e => {
            state.keyword = e.target.value;
            state.currentPage = 1;
            renderTable();
        });
    }

    // Custom Select Dropdowns
    setupCustomSelect("statusSelectBox", val => {
        setDeviceStatusFilter(val);
    });

    setupCustomSelect("classroomSelectBox", val => {
        state.filterClassroom = val;
        state.currentPage = 1;
        renderTable();
    });

    // Refresh Button
    const refreshBtn = document.getElementById("btnRefresh");
    if (refreshBtn) {
        refreshBtn.addEventListener("click", handleRefresh);
    }

    // Sorting headers
    document.querySelectorAll(".devices-table th[data-sort]").forEach(th => {
        th.addEventListener("click", () => {
            const key = th.getAttribute("data-sort");
            if (state.sortKey === key) {
                state.sortDir = state.sortDir === "asc" ? "desc" : "asc";
            } else {
                state.sortKey = key;
                state.sortDir = "asc";
            }
            renderTable();
        });
    });

    // Sidebar Hamburger Toggle
    setupSidebarToggle();

    // User Profile Dropdown
    setupUserDropdown();
}

function setupCustomSelect(selectId, onSelectCallback) {
    const box = document.getElementById(selectId);
    if (!box) return;

    box.addEventListener("click", e => {
        e.stopPropagation();
        const wasOpen = box.classList.contains("open");
        // Close other dropdowns
        document.querySelectorAll(".custom-select-box.open").forEach(b => b.classList.remove("open"));
        if (!wasOpen) {
            box.classList.add("open");
        }
    });

    const popup = box.querySelector(".select-options-popup");
    if (popup) {
        popup.addEventListener("click", e => {
            const item = e.target.closest(".option-item");
            if (item) {
                const val = item.getAttribute("data-val");
                const label = item.textContent;

                const valEl = box.querySelector(".select-val-row");
                if (valEl) valEl.textContent = label;

                popup.querySelectorAll(".option-item").forEach(opt => opt.classList.remove("selected"));
                item.classList.add("selected");

                box.classList.remove("open");
                onSelectCallback(val);
            }
        });
    }

    document.addEventListener("click", () => {
        box.classList.remove("open");
    });
}

function setupSidebarToggle() {
    const toggleBtn = document.getElementById("btnSidebarToggle");
    if (toggleBtn) {
        toggleBtn.addEventListener("click", () => {
            document.body.classList.toggle("sidebar-collapsed");
        });
    }
}

function setupUserDropdown() {
    const userBadge = document.getElementById("userMenuToggle");
    if (userBadge) {
        userBadge.addEventListener("click", e => {
            e.stopPropagation();
            userBadge.classList.toggle("open");
        });

        document.addEventListener("click", () => {
            userBadge.classList.remove("open");
        });
    }
}

/* =============================================================================
   12. MAIN RENDER ALL ENTRYPOINT
   ============================================================================= */
function renderAll() {
    // Render static and calculated components
    renderHeaderDate();
    renderSidebarFooter();
    renderBadges();
    renderStatCards();
    populateClassroomOptions();
    renderDeviceStatusDonut();
    renderRecentActivity();
    renderTable();
}

// Initial bootstrap on DOMContentLoaded
document.addEventListener("DOMContentLoaded", () => {
    // Always use window.SERVER_DEVICES from database (even if empty)
    if (window.SERVER_DEVICES && Array.isArray(window.SERVER_DEVICES)) {
        devices = window.SERVER_DEVICES;
    } else {
        devices = [];
    }

    if (window.SERVER_BADGES) {
        if (window.SERVER_BADGES.bell !== undefined) badges.bell = window.SERVER_BADGES.bell;
        if (window.SERVER_BADGES.sidebarAlerts !== undefined) badges.sidebarAlerts = window.SERVER_BADGES.sidebarAlerts;
    }

    // Check URL parameters for initial status filter
    try {
        const urlParams = new URLSearchParams(window.location.search);
        const urlStatus = urlParams.get("status") || urlParams.get("activeState");
        if (urlStatus) {
            const stUpper = urlStatus.toUpperCase();
            if (stUpper === "ACTIVE") state.filterStatus = "Active";
            else if (stUpper === "INACTIVE") state.filterStatus = "Inactive";
            else state.filterStatus = "ALL";
        }
    } catch (e) {}

    setupSelectAll();
    setupRowMenu();
    setupEventListeners();
    updateStatusSelectBoxUI(state.filterStatus);
    updateStatCardsActive(state.filterStatus);
    renderAll();
});
