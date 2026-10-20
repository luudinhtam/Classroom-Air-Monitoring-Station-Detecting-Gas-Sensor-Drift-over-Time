// Draws a bar chart straight onto a canvas. No charting library is fetched from
// the internet, so the page still works on a machine with no network.
function drawBars(canvasId, labels, values) {
    var cv = document.getElementById(canvasId);
    if (!cv || !values || values.length === 0) return;
    var ctx = cv.getContext('2d');
    var w = cv.width, h = cv.height;
    var padL = 42, padB = 34, padT = 18, padR = 14;

    var max = 0;
    for (var i = 0; i < values.length; i++) if (values[i] > max) max = values[i];
    if (max === 0) max = 1;

    ctx.clearRect(0, 0, w, h);

    // axes
    ctx.strokeStyle = '#aab';
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.moveTo(padL, padT);
    ctx.lineTo(padL, h - padB);
    ctx.lineTo(w - padR, h - padB);
    ctx.stroke();

    // horizontal guides and their labels
    ctx.fillStyle = '#667';
    ctx.font = '11px sans-serif';
    ctx.textAlign = 'right';
    for (var g = 0; g <= 4; g++) {
        var val = Math.round(max * g / 4);
        var y = (h - padB) - (h - padB - padT) * g / 4;
        ctx.fillText(String(val), padL - 6, y + 4);
        if (g > 0) {
            ctx.strokeStyle = '#eef0f3';
            ctx.beginPath();
            ctx.moveTo(padL + 1, y);
            ctx.lineTo(w - padR, y);
            ctx.stroke();
        }
    }

    var slot = (w - padL - padR) / values.length;
    var barW = Math.min(64, slot * 0.6);

    for (var j = 0; j < values.length; j++) {
        var cx = padL + slot * j + slot / 2;
        var bh = (h - padB - padT) * values[j] / max;
        ctx.fillStyle = '#4a6fa5';
        ctx.fillRect(cx - barW / 2, (h - padB) - bh, barW, bh);

        ctx.fillStyle = '#222';
        ctx.font = 'bold 12px sans-serif';
        ctx.textAlign = 'center';
        ctx.fillText(String(values[j]), cx, (h - padB) - bh - 6);

        ctx.fillStyle = '#556';
        ctx.font = '11px sans-serif';
        ctx.fillText(labels[j], cx, h - padB + 15);
    }
}
