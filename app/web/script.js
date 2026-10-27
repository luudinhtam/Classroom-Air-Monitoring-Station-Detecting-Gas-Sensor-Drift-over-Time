/**
 * =========================================================================
 * Classroom Temp – Monitoring System (script.js)
 * Xử lý logic thuần Javascript:
 * - Dữ liệu mẫu 17 phòng học
 * - Quy tắc tính trạng thái động (Bình thường / Cảnh báo / Quá nhiệt)
 * - Tự động vẽ biểu đồ Sparkline bằng SVG path + gradient
 * - Tìm kiếm, lọc theo tòa nhà, lọc theo trạng thái
 * - Phân trang động & chuyển đổi Grid/List view
 * - Modal xem chi tiết
 * =========================================================================
 */

// 1. DỮ LIỆU CÁC PHÒNG HỌC (Ưu tiên lấy từ Server SQL Server, fallback sang mảng mẫu)
const DEFAULT_CLASSROOM_IMG = "assets/images/classroom_default.png";

const fallbackRoomsData = [
    // --- 12 phòng thuộc Trang 1 theo đúng yêu cầu ---
    { id: 101, name: "Phòng 101", building: "Tòa A", floor: 1, location: "Tòa A - Tầng 1", temp: 24.5, humid: 58, image: DEFAULT_CLASSROOM_IMG },
    { id: 102, name: "Phòng 102", building: "Tòa A", floor: 1, location: "Tòa A - Tầng 1", temp: 25.1, humid: 55, image: DEFAULT_CLASSROOM_IMG },
    { id: 103, name: "Phòng 103", building: "Tòa A", floor: 1, location: "Tòa A - Tầng 1", temp: 28.7, humid: 62, image: DEFAULT_CLASSROOM_IMG },
    { id: 104, name: "Phòng 104", building: "Tòa A", floor: 1, location: "Tòa A - Tầng 1", temp: 23.8, humid: 56, image: DEFAULT_CLASSROOM_IMG },
    { id: 201, name: "Phòng 201", building: "Tòa B", floor: 2, location: "Tòa B - Tầng 2", temp: 24.2, humid: 57, image: DEFAULT_CLASSROOM_IMG },
    { id: 202, name: "Phòng 202", building: "Tòa B", floor: 2, location: "Tòa B - Tầng 2", temp: 29.3, humid: 65, image: DEFAULT_CLASSROOM_IMG },
    { id: 203, name: "Phòng 203", building: "Tòa B", floor: 2, location: "Tòa B - Tầng 2", temp: 32.6, humid: 68, image: DEFAULT_CLASSROOM_IMG },
    { id: 204, name: "Phòng 204", building: "Tòa B", floor: 2, location: "Tòa B - Tầng 2", temp: 24.0, humid: 54, image: DEFAULT_CLASSROOM_IMG },
    { id: 301, name: "Phòng 301", building: "Tòa C", floor: 3, location: "Tòa C - Tầng 3", temp: 25.3, humid: 59, image: DEFAULT_CLASSROOM_IMG },
    { id: 302, name: "Phòng 302", building: "Tòa C", floor: 3, location: "Tòa C - Tầng 3", temp: 24.7, humid: 57, image: DEFAULT_CLASSROOM_IMG },
    { id: 303, name: "Phòng 303", building: "Tòa C", floor: 3, location: "Tòa C - Tầng 3", temp: 28.9, humid: 63, image: DEFAULT_CLASSROOM_IMG },
    { id: 304, name: "Phòng 304", building: "Tòa C", floor: 3, location: "Tòa C - Tầng 3", temp: 25.0, humid: 56, image: DEFAULT_CLASSROOM_IMG },

    // --- 5 phòng bổ sung để tạo trang 2 ---
    { id: 105, name: "Phòng 105", building: "Tòa A", floor: 2, location: "Tòa A - Tầng 2", temp: 26.2, humid: 58, image: DEFAULT_CLASSROOM_IMG },
    { id: 106, name: "Phòng 106", building: "Tòa A", floor: 2, location: "Tòa A - Tầng 2", temp: 31.4, humid: 70, image: DEFAULT_CLASSROOM_IMG },
    { id: 205, name: "Phòng 205", building: "Tòa B", floor: 3, location: "Tòa B - Tầng 3", temp: 27.5, humid: 60, image: DEFAULT_CLASSROOM_IMG },
    { id: 305, name: "Phòng 305", building: "Tòa C", floor: 1, location: "Tòa C - Tầng 1", temp: 23.5, humid: 53, image: DEFAULT_CLASSROOM_IMG },
    { id: 306, name: "Phòng 306", building: "Tòa C", floor: 2, location: "Tòa C - Tầng 2", temp: 29.8, humid: 66, image: DEFAULT_CLASSROOM_IMG }
];

const sourceRooms = (window.DASHBOARD_ROOMS_DATA && window.DASHBOARD_ROOMS_DATA.length > 0)
    ? window.DASHBOARD_ROOMS_DATA
    : fallbackRoomsData;

// Sinh mảng 20 điểm nhiệt độ lịch sử cho mỗi phòng (nếu server chưa có sẵn)
const rooms = sourceRooms.map(room => {
    if (room.history && room.history.length === 20) {
        return room;
    }
    const history = [];
    for (let i = 0; i < 20; i++) {
        const delta = (Math.sin(i * 0.7 + room.id) * 0.9) + ((Math.random() - 0.5) * 0.6);
        history.push(parseFloat((room.temp + delta).toFixed(1)));
    }
    history[history.length - 1] = room.temp;
    return { ...room, history };
});

// 2. QUẢN LÝ TRẠNG THÁI ỨNG DỤNG (APPLICATION STATE)
const state = {
    searchQuery: "",
    statusFilter: "ALL",       // ALL | NORMAL | WARNING | DANGER
    buildingFilter: "ALL",     // ALL | Tòa A | Tòa B | Tòa C
    viewMode: "grid",          // grid | list
    currentPage: 1,
    pageSize: 12
};

// 3. QUY TẮC PHÂN LOẠI TRẠNG THÁI THEO NHIỆT ĐỘ
// < 28°C: Bình thường | 28°C - 30°C: Cảnh báo | > 30°C: Quá nhiệt
function getStatus(temp) {
    if (temp < 28.0) {
        return {
            code: "NORMAL",
            label: "Bình thường",
            colorClass: "normal",
            strokeColor: "#16a34a",
            fillStart: "rgba(22, 163, 74, 0.25)",
            fillEnd: "rgba(22, 163, 74, 0.0)"
        };
    } else if (temp <= 30.0) {
        return {
            code: "WARNING",
            label: "Cảnh báo",
            colorClass: "warning",
            strokeColor: "#f59e0b",
            fillStart: "rgba(245, 158, 11, 0.25)",
            fillEnd: "rgba(245, 158, 11, 0.0)"
        };
    } else {
        return {
            code: "DANGER",
            label: "Quá nhiệt",
            colorClass: "danger",
            strokeColor: "#ef4444",
            fillStart: "rgba(239, 68, 68, 0.25)",
            fillEnd: "rgba(239, 68, 68, 0.0)"
        };
    }
}

// 4. TÍNH TOÁN VÀ HIỂN THỊ 4 THẺ THỐNG KÊ (STATS CARDS)
function renderStats() {
    let total = rooms.length;
    let normal = 0;
    let warning = 0;
    let danger = 0;

    rooms.forEach(r => {
        const s = getStatus(r.temp);
        if (s.code === "NORMAL") normal++;
        else if (s.code === "WARNING") warning++;
        else if (s.code === "DANGER") danger++;
    });

    // Cập nhật lên 4 card
    document.getElementById("statTotalRooms").innerText = total;
    document.getElementById("statNormalRooms").innerText = normal;
    document.getElementById("statWarningRooms").innerText = warning;
    document.getElementById("statDangerRooms").innerText = danger;

    // Cập nhật badge số cảnh báo (Cảnh báo + Quá nhiệt) ở sidebar và chuông
    const alertTotal = warning + danger;
    const sidebarBadge = document.getElementById("sidebarAlertBadge");
    const headerBellBadge = document.getElementById("headerBellBadge");

    if (sidebarBadge) sidebarBadge.innerText = alertTotal;
    if (headerBellBadge) headerBellBadge.innerText = alertTotal;
}

// 5. TẠO BIỂU ĐỒ SPARKLINE DẠNG SVG (PATH + GRADIENT)
function renderSparkline(history, statusInfo, uniqueId) {
    const width = 125;
    const height = 30;
    const padding = 3;

    const min = Math.min(...history) - 0.5;
    const max = Math.max(...history) + 0.5;
    const range = (max - min) === 0 ? 1 : (max - min);

    // Tính tọa độ các điểm
    const points = history.map((val, index) => {
        const x = padding + (index / (history.length - 1)) * (width - padding * 2);
        const y = height - padding - ((val - min) / range) * (height - padding * 2);
        return { x, y };
    });

    // Tạo đường cong mượt (smooth curve qua bezier)
    let pathD = `M ${points[0].x} ${points[0].y}`;
    for (let i = 0; i < points.length - 1; i++) {
        const p0 = points[i];
        const p1 = points[i + 1];
        const cpX = (p0.x + p1.x) / 2;
        pathD += ` C ${cpX} ${p0.y}, ${cpX} ${p1.y}, ${p1.x} ${p1.y}`;
    }

    // Tạo vùng gradient khép kín
    const areaD = `${pathD} L ${points[points.length - 1].x} ${height} L ${points[0].x} ${height} Z`;
    const gradId = `sparkGrad_${uniqueId}`;

    return `
        <svg class="sparkline-svg" viewBox="0 0 ${width} ${height}">
            <defs>
                <linearGradient id="${gradId}" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="0%" stop-color="${statusInfo.fillStart}" />
                    <stop offset="100%" stop-color="${statusInfo.fillEnd}" />
                </linearGradient>
            </defs>
            <path d="${areaD}" fill="url(#${gradId})" />
            <path d="${pathD}" fill="none" stroke="${statusInfo.strokeColor}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" />
        </svg>
    `;
}

// 6. LỌC DANH SÁCH PHÒNG THEO STATE HIỆN TẠI
function getFilteredRooms() {
    return rooms.filter(room => {
        // Lọc theo tên phòng
        const matchesSearch = room.name.toLowerCase().includes(state.searchQuery.toLowerCase().trim());

        // Lọc theo trạng thái
        const status = getStatus(room.temp);
        const matchesStatus = (state.statusFilter === "ALL") || (status.code === state.statusFilter);

        // Lọc theo tòa nhà
        const matchesBuilding = (state.buildingFilter === "ALL") || (room.building === state.buildingFilter);

        return matchesSearch && matchesStatus && matchesBuilding;
    });
}

// 7. RENDER DANH SÁCH PHÒNG HỌC (GRID HOẶC LIST)
function renderRooms() {
    const container = document.getElementById("roomsContainer");
    const filtered = getFilteredRooms();

    // Áp dụng class chế độ xem
    container.className = `rooms-container ${state.viewMode}-mode`;

    // Trường hợp không tìm thấy kết quả
    if (filtered.length === 0) {
        container.innerHTML = `
            <div class="empty-state">
                <svg class="empty-state-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <circle cx="11" cy="11" r="8"></circle>
                    <line x1="21" y1="21" x2="16.65" y2="16.65"></line>
                </svg>
                <div class="empty-state-title">Không tìm thấy phòng học phù hợp</div>
                <p>Vui lòng thử thay đổi từ khóa tìm kiếm hoặc bỏ bớt các tiêu chí lọc.</p>
            </div>
        `;
        renderPagination(0);
        return;
    }

    // Tính toán phân trang
    const totalPages = Math.ceil(filtered.length / state.pageSize);
    if (state.currentPage > totalPages) state.currentPage = totalPages;
    if (state.currentPage < 1) state.currentPage = 1;

    const startIndex = (state.currentPage - 1) * state.pageSize;
    const pageItems = filtered.slice(startIndex, startIndex + state.pageSize);

    // Render từng thẻ phòng
    container.innerHTML = pageItems.map(room => {
        const st = getStatus(room.temp);
        const sparklineSvg = renderSparkline(room.history, st, room.id);

        // Icon trạng thái
        let badgeIconHtml = `<span class="status-badge-dot"></span>`;
        if (st.code === "WARNING") {
            badgeIconHtml = `
                <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
                    <path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/>
                    <line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/>
                </svg>
            `;
        }

        return `
            <div class="room-card" data-id="${room.id}">
                <!-- Hàng trên: Ảnh, Tên phòng, Badge -->
                <div class="card-header-row">
                    <div class="room-info-group">
                        <img src="${room.image}" alt="${room.name}" class="room-thumbnail" onerror="this.src='https://images.unsplash.com/photo-1580582932707-520aed937b7b?auto=format&fit=crop&w=200&q=80'">
                        <div class="room-title-block">
                            <span class="room-name">${room.name}</span>
                            <span class="room-location">
                                <!-- SVG Ghim vị trí -->
                                <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="#6b7280" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                    <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"/>
                                    <circle cx="12" cy="10" r="3"/>
                                </svg>
                                ${room.location}
                            </span>
                        </div>
                    </div>
                    <div class="status-badge ${st.colorClass}">
                        ${badgeIconHtml}
                        <span>${st.label}</span>
                    </div>
                </div>

                <!-- Hàng giữa: Nhiệt độ & Độ ẩm -->
                <div class="card-metrics-row">
                    <div class="metric-item">
                        <div class="metric-circle-icon">
                            <!-- SVG Nhiệt kế xanh -->
                            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#2563eb" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                <path d="M14 14.76V3.5a2.5 2.5 0 0 0-5 0v11.26a4.5 4.5 0 1 0 5 0z"/>
                                <circle cx="11.5" cy="17.5" r="1.5" fill="#2563eb"/>
                            </svg>
                        </div>
                        <div class="metric-text">
                            <span class="metric-value">${room.temp}°C</span>
                            <span class="metric-label">Nhiệt độ</span>
                        </div>
                    </div>

                    <div class="metric-item">
                        <div class="metric-circle-icon">
                            <!-- SVG Giọt nước xanh -->
                            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#0284c7" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                <path d="M12 2.69l5.66 5.66a8 8 0 1 1-11.31 0z"/>
                            </svg>
                        </div>
                        <div class="metric-text">
                            <span class="metric-value">${room.humid}%</span>
                            <span class="metric-label">Độ ẩm</span>
                        </div>
                    </div>
                </div>

                <!-- Hàng dưới: Sparkline & Nút xem chi tiết -->
                <div class="card-footer-row">
                    <div class="sparkline-wrapper">
                        ${sparklineSvg}
                    </div>
                    <button class="btn-detail" onclick="openRoomModal(${room.id})">
                        <span>Xem chi tiết</span>
                        <!-- SVG Mũi tên > -->
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                            <polyline points="9 18 15 12 9 6"/>
                        </svg>
                    </button>
                </div>
            </div>
        `;
    }).join("");

    renderPagination(totalPages);
}

// 8. RENDER PHÂN TRANG ĐỘNG
function renderPagination(totalPages) {
    const container = document.getElementById("paginationContainer");
    if (totalPages <= 1) {
        container.innerHTML = "";
        return;
    }

    let html = `
        <button class="page-btn" ${state.currentPage === 1 ? "disabled" : ""} onclick="changePage(${state.currentPage - 1})">
            <!-- Mũi tên < -->
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <polyline points="15 18 9 12 15 6"/>
            </svg>
        </button>
    `;

    for (let p = 1; p <= totalPages; p++) {
        html += `
            <button class="page-btn ${p === state.currentPage ? "active" : ""}" onclick="changePage(${p})">
                ${p}
            </button>
        `;
    }

    html += `
        <button class="page-btn" ${state.currentPage === totalPages ? "disabled" : ""} onclick="changePage(${state.currentPage + 1})">
            <!-- Mũi tên > -->
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <polyline points="9 18 15 12 9 6"/>
            </svg>
        </button>
    `;

    container.innerHTML = html;
}

function changePage(page) {
    state.currentPage = page;
    renderRooms();
    window.scrollTo({ top: 0, behavior: 'smooth' });
}

// 9. BỘ LỌC VÀ SỰ KIỆN TÌM KIẾM
function applyFilters() {
    state.currentPage = 1; // Luôn quay về trang 1 khi lọc
    renderRooms();
}

function setupEventListeners() {
    // Tìm kiếm
    const searchInput = document.getElementById("searchInput");
    searchInput.addEventListener("input", (e) => {
        state.searchQuery = e.target.value;
        applyFilters();
    });

    // Lọc theo trạng thái
    const statusFilter = document.getElementById("statusFilter");
    statusFilter.addEventListener("change", (e) => {
        state.statusFilter = e.target.value;
        applyFilters();
    });

    // Lọc theo tòa nhà
    const buildingFilter = document.getElementById("buildingFilter");
    buildingFilter.addEventListener("change", (e) => {
        state.buildingFilter = e.target.value;
        applyFilters();
    });

    // Chuyển đổi Grid / List view
    const btnGrid = document.getElementById("btnGridView");
    const btnList = document.getElementById("btnListView");

    btnGrid.addEventListener("click", () => {
        state.viewMode = "grid";
        btnGrid.classList.add("active");
        btnList.classList.remove("active");
        renderRooms();
    });

    btnList.addEventListener("click", () => {
        state.viewMode = "list";
        btnList.classList.add("active");
        btnGrid.classList.remove("active");
        renderRooms();
    });

    // Sự kiện đóng modal
    document.getElementById("modalCloseBtn").addEventListener("click", closeRoomModal);
    document.getElementById("modalActionBtn").addEventListener("click", closeRoomModal);
    document.getElementById("roomDetailModal").addEventListener("click", (e) => {
        if (e.target.id === "roomDetailModal") closeRoomModal();
    });
}

// 10. MODAL XEM CHI TIẾT PHÒNG HỌC
function openRoomModal(roomId) {
    const room = rooms.find(r => r.id === roomId);
    if (!room) return;

    const st = getStatus(room.temp);
    document.getElementById("modalRoomTitle").innerText = `Thông tin chi tiết: ${room.name}`;

    document.getElementById("modalRoomBody").innerHTML = `
        <div style="text-align: center; margin-bottom: 16px;">
            <img src="${room.image}" style="width: 100%; height: 160px; object-fit: cover; border-radius: 8px;">
        </div>
        <div class="modal-detail-row">
            <span class="modal-detail-label">Tên phòng:</span>
            <span class="modal-detail-val">${room.name}</span>
        </div>
        <div class="modal-detail-row">
            <span class="modal-detail-label">Vị trí:</span>
            <span class="modal-detail-val">${room.location}</span>
        </div>
        <div class="modal-detail-row">
            <span class="modal-detail-label">Nhiệt độ hiện tại:</span>
            <span class="modal-detail-val" style="color: ${st.strokeColor}; font-size: 16px;">${room.temp}°C</span>
        </div>
        <div class="modal-detail-row">
            <span class="modal-detail-label">Độ ẩm:</span>
            <span class="modal-detail-val">${room.humid}%</span>
        </div>
        <div class="modal-detail-row">
            <span class="modal-detail-label">Trạng thái:</span>
            <span class="status-badge ${st.colorClass}" style="margin: 0;">${st.label}</span>
        </div>
        <div class="modal-detail-row">
            <span class="modal-detail-label">Thời gian cập nhật:</span>
            <span class="modal-detail-val">21/10/2025 13:42:00</span>
        </div>
        <div style="margin-top: 18px; text-align: right;">
            <a href="admin/rooms/detail?id=${room.id}" style="display: inline-flex; align-items: center; gap: 6px; text-decoration: none; padding: 8px 16px; background: #2563eb; color: #ffffff; border-radius: 6px; font-weight: 600; font-size: 13px; box-shadow: 0 2px 4px rgba(37,99,235,0.25);">
                <span>Xem đầy đủ biểu đồ & chi tiết &rarr;</span>
            </a>
        </div>
    `;

    document.getElementById("roomDetailModal").classList.add("open");
}

function closeRoomModal() {
    document.getElementById("roomDetailModal").classList.remove("open");
}

// 11. KHỞI CHẠY KHI TẢI TRANG
document.addEventListener("DOMContentLoaded", () => {
    renderStats();
    setupEventListeners();
    renderRooms();
});
