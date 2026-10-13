/**
 * dashboardCharts.js - Thư viện vẽ biểu đồ phân tán (Scatter Plot),
 * xu hướng mức nền (Trend Chart) và phân bố cảnh báo trực tiếp bằng HTML5 Canvas.
 * Hoạt động 100% offline không phụ thuộc internet/CDN.
 */

// 1. VẼ BIỂU ĐỒ PHÂN TÁN (SCATTER PLOT): TƯƠNG QUAN KHÍ VÀ NHIỆT ĐỘ
function initScatterPlot(canvasId, points) {
    var cv = document.getElementById(canvasId);
    if (!cv || !points || points.length === 0) return;
    var ctx = cv.getContext('2d');
    var w = cv.width, h = cv.height;

    var padL = 60, padB = 45, padT = 30, padR = 25;
    var plotW = w - padL - padR;
    var plotH = h - padT - padB;

    // Tìm min/max nhiệt độ & khí
    var minT = 0, maxT = 45;
    var minG = 400, maxG = 2200;

    for (var i = 0; i < points.length; i++) {
        var p = points[i];
        if (p.tempC < minT) minT = Math.floor(p.tempC);
        if (p.tempC > maxT) maxT = Math.ceil(p.tempC);
        if (p.gasARaw < minG) minG = Math.floor(p.gasARaw / 100) * 100;
        if (p.gasARaw > maxG) maxG = Math.ceil(p.gasARaw / 100) * 100;
    }
    minT = Math.max(0, minT);
    maxT = Math.max(40, maxT);
    minG = Math.max(300, minG);
    maxG = Math.max(2000, maxG);

    function mapX(val) {
        return padL + ((val - minT) / (maxT - minT)) * plotW;
    }
    function mapY(val) {
        return (h - padB) - ((val - minG) / (maxG - minG)) * plotH;
    }

    function render(hoveredIdx) {
        ctx.clearRect(0, 0, w, h);

        // Vùng highlight nhiệt độ cao (> 30°C) - vùng dễ bị nhiễu do nhiệt
        var temp30X = mapX(30);
        if (temp30X < w - padR) {
            ctx.fillStyle = 'rgba(255, 237, 213, 0.45)';
            ctx.fillRect(temp30X, padT, (w - padR) - temp30X, plotH);
            ctx.fillStyle = '#b45309';
            ctx.font = 'italic 11px sans-serif';
            ctx.textAlign = 'right';
            ctx.fillText('Vùng nhiệt độ cao (>30°C): Nguy cơ nhiễu nhiệt (TEMP_EFFECT)', w - padR - 8, padT + 16);
        }

        // Lưới ngang & Ticks trục Y (Nồng độ khí)
        ctx.textAlign = 'right';
        ctx.font = '11px sans-serif';
        var ySteps = 5;
        for (var i = 0; i <= ySteps; i++) {
            var valY = Math.round(minG + (maxG - minG) * (i / ySteps));
            var y = mapY(valY);

            ctx.strokeStyle = '#e2e8f0';
            ctx.lineWidth = 1;
            ctx.beginPath();
            ctx.moveTo(padL, y);
            ctx.lineTo(w - padR, y);
            ctx.stroke();

            ctx.fillStyle = '#64748b';
            ctx.fillText(valY, padL - 8, y + 4);
        }

        // Lưới dọc & Ticks trục X (Nhiệt độ)
        ctx.textAlign = 'center';
        var xSteps = 8;
        for (var j = 0; j <= xSteps; j++) {
            var valX = Math.round(minT + (maxT - minT) * (j / xSteps));
            var x = mapX(valX);

            ctx.strokeStyle = '#f1f5f9';
            ctx.lineWidth = 1;
            ctx.beginPath();
            ctx.moveTo(x, padT);
            ctx.lineTo(x, h - padB);
            ctx.stroke();

            ctx.fillStyle = '#64748b';
            ctx.fillText(valX + '°C', x, h - padB + 16);
        }

        // Trục tọa độ chính
        ctx.strokeStyle = '#94a3b8';
        ctx.lineWidth = 1.5;
        ctx.beginPath();
        ctx.moveTo(padL, padT);
        ctx.lineTo(padL, h - padB);
        ctx.lineTo(w - padR, h - padB);
        ctx.stroke();

        // Nhãn trục
        ctx.fillStyle = '#334155';
        ctx.font = 'bold 12px sans-serif';
        ctx.textAlign = 'center';
        ctx.fillText('Nhiệt độ môi trường (°C)', padL + plotW / 2, h - 8);

        ctx.save();
        ctx.translate(14, padT + plotH / 2);
        ctx.rotate(-Math.PI / 2);
        ctx.textAlign = 'center';
        ctx.fillText('Giá trị khí Gas A Raw (ppm/đơn vị)', 0, 0);
        ctx.restore();

        // Vẽ các điểm Scatter
        for (var k = 0; k < points.length; k++) {
            var pt = points[k];
            var px = mapX(pt.tempC);
            var py = mapY(pt.gasARaw);

            var color = '#3b82f6'; // Mặc định BASE
            if (pt.labelCode === 'HIGH') color = '#ef4444';
            else if (pt.labelCode === 'TEMP_EFFECT') color = '#f97316';
            else if (pt.labelCode === 'DRIFTED') color = '#a855f7';
            else if (pt.labelCode === 'WARMUP') color = '#64748b';
            else if (pt.labelCode === 'RAISED') color = '#06b6d4';

            ctx.beginPath();
            var radius = (k === hoveredIdx) ? 7 : 4;
            ctx.arc(px, py, radius, 0, Math.PI * 2);
            ctx.fillStyle = color;
            ctx.fill();
            ctx.strokeStyle = (k === hoveredIdx) ? '#000' : 'rgba(255,255,255,0.85)';
            ctx.lineWidth = (k === hoveredIdx) ? 2 : 1;
            ctx.stroke();
        }

        // Tooltip nếu đang hover
        if (hoveredIdx >= 0 && hoveredIdx < points.length) {
            var hPt = points[hoveredIdx];
            var hx = mapX(hPt.tempC);
            var hy = mapY(hPt.gasARaw);

            var text1 = 'Nhãn: ' + hPt.labelCode;
            var text2 = 'Nhiệt độ: ' + hPt.tempC + '°C | Khí: ' + hPt.gasARaw;
            var text3 = 'Độ ẩm: ' + hPt.humidPct + '% | Delta: ' + hPt.gasADelta;

            var tipW = 190, tipH = 58;
            var tipX = Math.min(w - tipW - 10, Math.max(padL + 10, hx + 10));
            var tipY = Math.min(h - tipH - 10, Math.max(padT + 10, hy - 40));

            ctx.fillStyle = 'rgba(15, 23, 42, 0.9)';
            ctx.beginPath();
            ctx.rect(tipX, tipY, tipW, tipH);
            ctx.fill();

            ctx.fillStyle = '#fff';
            ctx.font = 'bold 11px sans-serif';
            ctx.textAlign = 'left';
            ctx.fillText(text1, tipX + 8, tipY + 16);
            ctx.font = '10px sans-serif';
            ctx.fillStyle = '#cbd5e1';
            ctx.fillText(text2, tipX + 8, tipY + 32);
            ctx.fillText(text3, tipX + 8, tipY + 48);
        }
    }

    render(-1);

    // Xử lý sự kiện di chuột
    cv.addEventListener('mousemove', function (e) {
        var rect = cv.getBoundingClientRect();
        var mx = e.clientX - rect.left;
        var my = e.clientY - rect.top;

        var closest = -1;
        var minDist = 12; // Bán kính bắt điểm
        for (var i = 0; i < points.length; i++) {
            var px = mapX(points[i].tempC);
            var py = mapY(points[i].gasARaw);
            var dist = Math.hypot(mx - px, my - py);
            if (dist < minDist) {
                minDist = dist;
                closest = i;
            }
        }
        render(closest);
    });

    cv.addEventListener('mouseleave', function () {
        render(-1);
    });
}

// 2. VẼ BIỂU ĐỒ XU HƯỚNG MỨC NỀN & ĐỘ DỊCH (TREND CHART)
function initTrendChart(canvasId, trendData) {
    var cv = document.getElementById(canvasId);
    if (!cv || !trendData || trendData.length === 0) return;
    var ctx = cv.getContext('2d');
    var w = cv.width, h = cv.height;

    var padL = 55, padB = 35, padT = 25, padR = 55;
    var plotW = w - padL - padR;
    var plotH = h - padT - padB;

    var minBase = 9999, maxBase = 0;
    var minShift = 9999, maxShift = -9999;

    for (var i = 0; i < trendData.length; i++) {
        var d = trendData[i];
        if (d.gasABase < minBase) minBase = d.gasABase;
        if (d.gasABase > maxBase) maxBase = d.gasABase;
        if (d.baseShift < minShift) minShift = d.baseShift;
        if (d.baseShift > maxShift) maxShift = d.baseShift;
    }
    minBase = Math.floor(minBase * 0.95);
    maxBase = Math.ceil(maxBase * 1.05);
    minShift = Math.min(0, Math.floor(minShift));
    maxShift = Math.max(15, Math.ceil(maxShift));

    ctx.clearRect(0, 0, w, h);

    // Trục Y trái: Mức nền (gas_a_base)
    ctx.textAlign = 'right';
    ctx.font = '10px sans-serif';
    ctx.fillStyle = '#2563eb';
    for (var g = 0; g <= 4; g++) {
        var vBase = Math.round(minBase + (maxBase - minBase) * (g / 4));
        var y = (h - padB) - plotH * (g / 4);
        ctx.fillText(String(vBase), padL - 8, y + 4);

        ctx.strokeStyle = '#f1f5f9';
        ctx.beginPath();
        ctx.moveTo(padL, y);
        ctx.lineTo(w - padR, y);
        ctx.stroke();
    }

    // Trục Y phải: Độ dịch % (base_shift)
    ctx.textAlign = 'left';
    ctx.fillStyle = '#dc2626';
    for (var s = 0; s <= 4; s++) {
        var vShift = (minShift + (maxShift - minShift) * (s / 4)).toFixed(1);
        var y = (h - padB) - plotH * (s / 4);
        ctx.fillText(vShift + '%', w - padR + 8, y + 4);
    }

    // Trục X nhãn thời gian
    var slot = plotW / Math.max(1, (trendData.length - 1));
    ctx.textAlign = 'center';
    ctx.fillStyle = '#64748b';
    for (var t = 0; t < trendData.length; t++) {
        var x = padL + slot * t;
        ctx.fillText(trendData[t].timeLabel, x, h - padB + 16);
    }

    // Vẽ đường Mức nền Base (Màu xanh dương)
    ctx.strokeStyle = '#2563eb';
    ctx.lineWidth = 2.5;
    ctx.beginPath();
    for (var i = 0; i < trendData.length; i++) {
        var x = padL + slot * i;
        var y = (h - padB) - ((trendData[i].gasABase - minBase) / (maxBase - minBase)) * plotH;
        if (i === 0) ctx.moveTo(x, y);
        else ctx.lineTo(x, y);
    }
    ctx.stroke();

    // Điểm nút Base
    for (var i = 0; i < trendData.length; i++) {
        var x = padL + slot * i;
        var y = (h - padB) - ((trendData[i].gasABase - minBase) / (maxBase - minBase)) * plotH;
        ctx.beginPath();
        ctx.arc(x, y, 4, 0, Math.PI * 2);
        ctx.fillStyle = '#2563eb';
        ctx.fill();
        ctx.strokeStyle = '#fff';
        ctx.lineWidth = 2;
        ctx.stroke();
    }

    // Vẽ đường Độ dịch Shift % (Màu đỏ/cam)
    ctx.strokeStyle = '#dc2626';
    ctx.lineWidth = 2;
    ctx.setLineDash([4, 4]);
    ctx.beginPath();
    for (var j = 0; j < trendData.length; j++) {
        var x = padL + slot * j;
        var y = (h - padB) - ((trendData[j].baseShift - minShift) / (maxShift - minShift)) * plotH;
        if (j === 0) ctx.moveTo(x, y);
        else ctx.lineTo(x, y);
    }
    ctx.stroke();
    ctx.setLineDash([]);

    // Điểm nút Shift
    for (var j = 0; j < trendData.length; j++) {
        var x = padL + slot * j;
        var y = (h - padB) - ((trendData[j].baseShift - minShift) / (maxShift - minShift)) * plotH;
        ctx.beginPath();
        ctx.arc(x, y, 4, 0, Math.PI * 2);
        ctx.fillStyle = '#dc2626';
        ctx.fill();
        ctx.strokeStyle = '#fff';
        ctx.lineWidth = 2;
        ctx.stroke();
    }
}
