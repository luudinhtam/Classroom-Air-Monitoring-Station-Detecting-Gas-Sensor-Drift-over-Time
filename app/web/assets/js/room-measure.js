/**
 * =========================================================================
 * Classroom Air – Manual Measurement Tab (room-measure.js)
 * Pure JavaScript (fetch, async/await) managing:
 * - Start Measurement POST request with double-click locking
 * - Continuous 1-second interval status polling with transient error retries
 * - Stepper progress state visualization (Pending -> Measuring -> Done)
 * - Elapsed measuring timer
 * - Metric card rendering with threshold highlighting
 * - Real-time alerts listing (XSS safe via textContent)
 * - SessionStorage state persistence and recovery across page refreshes
 * - Tab switching / URL param synchronization
 * =========================================================================
 */

(function () {
    'use strict';

    // Timeout & retry configuration matching MeasureService
    const CLIENT_MAX_TIMEOUT_SECONDS = 50; // 15s pending + 30s sent + 5s buffer
    const MAX_TRANSIENT_RETRIES = 3;

    let pollingTimerId = null;
    let elapsedTimerId = null;
    let measureStartTime = null;
    let currentCommandId = null;
    let transientRetries = 0;
    let isMeasuringInProgress = false;

    // DOM Elements
    let pane, ctx, roomCode, canStart, btnStart, btnText, btnSpinner;
    let statusMsgBox, timerBadge, timerVal;
    let stepperCard, step1Node, step2Node, step3Node, line1, line2;
    let cardTemp, valTemp, badgeTemp, threshTemp;
    let cardHumid, valHumid, badgeHumid, threshHumid;
    let cardCo, valCo, badgeCo, threshCo;
    let cardCo2, valCo2, badgeCo2, threshCo2;
    let alertsContainer, historyTbody;

    // Auto Mode Elements
    let btnModeManual, btnModeAuto, manualControlGroup, autoControlGroup, measureModeDesc, measureStationTitle;
    let autoIntervalInput, chipIntervals, btnStartAuto;
    let autoStatusBanner, autoPulseDot, autoStatusBadge, autoStatusText, autoCountdownWrap, autoCountdownVal, autoSessionCountEl;

    // Auto Mode State
    let currentMode = "manual"; // "manual" | "auto"
    let isAutoRunning = false;
    let autoIntervalSec = 30;
    let autoCountdownTimerId = null;
    let autoCountdownRemaining = 0;
    let autoSessionCount = 0;

    function initMeasureTab() {
        pane = document.getElementById("tab-measure");
        if (!pane) return;

        ctx = pane.dataset.ctx || "";
        roomCode = pane.dataset.roomCode || "";
        canStart = pane.dataset.canStart === "true";

        btnStart = document.getElementById("btnStartMeasure");
        btnText = btnStart ? btnStart.querySelector(".btn-text") : null;
        btnSpinner = btnStart ? btnStart.querySelector(".spinner-border") : null;
        statusMsgBox = document.getElementById("measureStatusMessage");
        timerBadge = document.getElementById("measureTimerBadge");
        timerVal = document.getElementById("measureTimer");

        // Stepper Nodes
        stepperCard = document.getElementById("measureStepperCard");
        step1Node = document.getElementById("stepNodePending");
        step2Node = document.getElementById("stepNodeMeasuring");
        step3Node = document.getElementById("stepNodeDone");
        line1 = document.getElementById("stepLine1");
        line2 = document.getElementById("stepLine2");

        // 4 Metric Card Elements
        cardTemp = document.getElementById("measureCardTemp");
        valTemp = document.getElementById("measureValTemp");
        badgeTemp = document.getElementById("measureBadgeTemp");
        threshTemp = document.getElementById("measureThreshTemp");

        cardHumid = document.getElementById("measureCardHumid");
        valHumid = document.getElementById("measureValHumid");
        badgeHumid = document.getElementById("measureBadgeHumid");
        threshHumid = document.getElementById("measureThreshHumid");

        cardCo = document.getElementById("measureCardCo");
        valCo = document.getElementById("measureValCo");
        badgeCo = document.getElementById("measureBadgeCo");
        threshCo = document.getElementById("measureThreshCo");

        cardCo2 = document.getElementById("measureCardCo2");
        valCo2 = document.getElementById("measureValCo2");
        badgeCo2 = document.getElementById("measureBadgeCo2");
        threshCo2 = document.getElementById("measureThreshCo2");

        alertsContainer = document.getElementById("measureAlertsContainer");
        historyTbody = document.getElementById("measureHistoryTbody");

        // Auto Mode DOM Queries
        btnModeManual = document.getElementById("btnModeManual");
        btnModeAuto = document.getElementById("btnModeAuto");
        manualControlGroup = document.getElementById("manualControlGroup");
        autoControlGroup = document.getElementById("autoControlGroup");
        measureModeDesc = document.getElementById("measureModeDesc");
        measureStationTitle = document.getElementById("measureStationTitle");

        autoIntervalInput = document.getElementById("autoIntervalInput");
        chipIntervals = document.querySelectorAll(".chip-interval");
        btnStartAuto = document.getElementById("btnStartAuto");

        autoStatusBanner = document.getElementById("autoStatusBanner");
        autoPulseDot = document.getElementById("autoPulseDot");
        autoStatusBadge = document.getElementById("autoStatusBadge");
        autoStatusText = document.getElementById("autoStatusText");
        autoCountdownWrap = document.getElementById("autoCountdownWrap");
        autoCountdownVal = document.getElementById("autoCountdownVal");
        autoSessionCountEl = document.getElementById("autoSessionCount");

        // Bind Mode Switch buttons
        if (btnModeManual) btnModeManual.addEventListener("click", () => switchMode("manual"));
        if (btnModeAuto) btnModeAuto.addEventListener("click", () => switchMode("auto"));

        // Bind Interval Chips
        if (chipIntervals && chipIntervals.length > 0) {
            chipIntervals.forEach(chip => {
                chip.addEventListener("click", () => {
                    const sec = parseInt(chip.dataset.sec, 10);
                    if (!isNaN(sec) && sec >= 10) {
                        autoIntervalSec = sec;
                        if (autoIntervalInput) autoIntervalInput.value = sec;
                        chipIntervals.forEach(c => c.classList.remove("active"));
                        chip.classList.add("active");
                    }
                });
            });
        }

        // Bind Interval Input
        if (autoIntervalInput) {
            autoIntervalInput.addEventListener("change", () => {
                let sec = parseInt(autoIntervalInput.value, 10);
                if (isNaN(sec) || sec < 10) sec = 10;
                if (sec > 3600) sec = 3600;
                autoIntervalInput.value = sec;
                autoIntervalSec = sec;

                if (chipIntervals) {
                    chipIntervals.forEach(c => {
                        if (parseInt(c.dataset.sec, 10) === sec) c.classList.add("active");
                        else c.classList.remove("active");
                    });
                }
            });
        }

        // Bind Auto Toggle Button (Start Auto / Stop Auto)
        if (btnStartAuto && canStart) {
            btnStartAuto.addEventListener("click", handleToggleAuto);
        }

        // Bind Manual Start button
        if (btnStart && canStart) {
            btnStart.addEventListener("click", handleStartClick);
        }

        // Window cleanup on navigation
        window.addEventListener("beforeunload", () => {
            stopPolling();
            stopElapsedTimer();
            stopAutoCountdown();
        });

        // Check if there is an in-flight command saved in sessionStorage
        recoverPendingSession();
    }

    function getStorageKey() {
        return "airroom_measure_cmd_" + (roomCode || "default");
    }

    // 1. RECOVERY ON PAGE LOAD / REFRESH
    async function recoverPendingSession() {
        const savedCmdIdStr = sessionStorage.getItem(getStorageKey());
        if (savedCmdIdStr === null || savedCmdIdStr === undefined || savedCmdIdStr === "") {
            return;
        }

        const savedCmdId = parseInt(savedCmdIdStr, 10);
        if (isNaN(savedCmdId) || savedCmdId < 0) {
            sessionStorage.removeItem(getStorageKey());
            return;
        }

        // Call status once to verify current state
        try {
            setButtonState(true, "Checking previous session...");
            const data = await fetchStatus(savedCmdId);
            if (!data) return;

            if (data.status === "PENDING" || data.status === "SENT") {
                // Resume ongoing measurement
                currentCommandId = savedCmdId;
                isMeasuringInProgress = true;
                startElapsedTimer();
                updateStepperState(data.status);
                scheduleNextPoll();
            } else if (data.status === "DONE") {
                // Completed session
                currentCommandId = savedCmdId;
                updateStepperState("DONE");
                renderResults(data.result);
                sessionStorage.removeItem(getStorageKey());
                setButtonState(false, "Start Measurement");
            } else {
                // TIMEOUT or other final state
                sessionStorage.removeItem(getStorageKey());
                resetToIdle();
            }
        } catch (e) {
            sessionStorage.removeItem(getStorageKey());
            resetToIdle();
        }
    }

    // 2. START MEASUREMENT HANDLER
    async function handleStartClick(e) {
        if (e) e.preventDefault();
        if (isMeasuringInProgress) return;

        hideMessage();
        resetMetricCards();
        resetAlertsSection();
        setButtonState(true, "Requesting...");

        try {
            const formData = new URLSearchParams();
            formData.append("id", roomCode);

            const resp = await fetch(`${ctx}/admin/rooms/measure/start`, {
                method: "POST",
                headers: {
                    "Content-Type": "application/x-www-form-urlencoded;charset=UTF-8",
                    "X-Requested-With": "XMLHttpRequest",
                    "Accept": "application/json"
                },
                body: formData.toString()
            });

            const json = await resp.json().catch(() => null);

            if (!resp.ok) {
                handleHttpError(resp.status, json);
                setButtonState(false, "Start Measurement");
                onMeasurementCycleFinished(false);
                return;
            }

            if (json && json.commandId !== null && json.commandId !== undefined) {
                currentCommandId = json.commandId;
                sessionStorage.setItem(getStorageKey(), currentCommandId);
                isMeasuringInProgress = true;
                transientRetries = 0;
                measureStartTime = Date.now();

                startElapsedTimer();
                updateStepperState("PENDING");
                setButtonState(true, "Measuring...");

                // Begin status polling
                scheduleNextPoll();
            } else {
                showError("Invalid response received from server.");
                setButtonState(false, "Start Measurement");
                onMeasurementCycleFinished(false);
            }
        } catch (err) {
            showError("Network error: Unable to contact server. Please try again.");
            setButtonState(false, "Start Measurement");
            onMeasurementCycleFinished(false);
        }
    }

    // 3. STATUS POLLING
    function scheduleNextPoll() {
        stopPolling();

        // Check if exceeded max client timeout (50s)
        if (measureStartTime && (Date.now() - measureStartTime > CLIENT_MAX_TIMEOUT_SECONDS * 1000)) {
            handleTimeout("Measurement timed out on client. Device did not respond in time.");
            return;
        }

        pollingTimerId = setTimeout(async () => {
            if (!isMeasuringInProgress || currentCommandId === null) return;
            await doPoll();
        }, 1000);
    }

    async function doPoll() {
        try {
            const data = await fetchStatus(currentCommandId);
            if (!data) return;

            transientRetries = 0; // Reset retry count on successful response
            const status = data.status;

            if (status === "PENDING" || status === "SENT") {
                updateStepperState(status);
                scheduleNextPoll();
            } else if (status === "DONE") {
                completeMeasurement(data);
            } else if (status === "TIMEOUT") {
                handleTimeout("Measurement timed out. Device took too long to complete data acquisition.");
            } else {
                handleTimeout("Measurement ended with status: " + status);
            }
        } catch (networkErr) {
            transientRetries++;
            if (transientRetries <= MAX_TRANSIENT_RETRIES) {
                // Transient glitch, retry
                scheduleNextPoll();
            } else {
                handleTimeout("Lost connection to server after 3 retries. Please check your network.");
            }
        }
    }

    async function fetchStatus(cmdId) {
        const url = `${ctx}/admin/rooms/measure/status?id=${encodeURIComponent(roomCode)}&commandId=${encodeURIComponent(cmdId)}`;
        const resp = await fetch(url, {
            method: "GET",
            headers: {
                "X-Requested-With": "XMLHttpRequest",
                "Accept": "application/json"
            }
        });

        const json = await resp.json().catch(() => null);

        if (!resp.ok) {
            handleHttpError(resp.status, json);
            stopMeasurementProcess();
            return null;
        }

        return json;
    }

    // 4. COMPLETION & TIMEOUT
    function completeMeasurement(data) {
        stopMeasurementProcess();
        sessionStorage.removeItem(getStorageKey());
        updateStepperState("DONE");
        renderResults(data.result);
        setButtonState(false, "Start Measurement");
        showSuccess("Measurement completed successfully.");

        // Prepend new record to History Table
        if (data.result) {
            prependHistoryRecord(data.result);
        }

        // Notify auto runner
        onMeasurementCycleFinished(true);
    }

    function handleTimeout(msg) {
        stopMeasurementProcess();
        sessionStorage.removeItem(getStorageKey());
        setStepperError(msg || "Measurement timed out.");
        showError(msg || "Measurement timed out. Device did not respond.");
        setButtonState(false, "Start Measurement");

        // Notify auto runner
        onMeasurementCycleFinished(false);
    }

    // =========================================================================
    // AUTO MODE CONTROLLER (Periodic Measurement Loop)
    // =========================================================================

    function switchMode(mode) {
        if (currentMode === mode) return;
        currentMode = mode;

        if (mode === "manual") {
            if (isAutoRunning) {
                handleToggleAuto();
            }
            if (btnModeManual) btnModeManual.classList.add("active");
            if (btnModeAuto) btnModeAuto.classList.remove("active");
            if (manualControlGroup) manualControlGroup.style.display = "flex";
            if (autoControlGroup) autoControlGroup.style.display = "none";
            if (autoStatusBanner) autoStatusBanner.style.display = "none";
            if (stepperCard) stepperCard.style.display = "";
            if (measureModeDesc) {
                measureModeDesc.textContent = "Trigger an on-demand 10-second measurement packet from the assigned IoT sensor node and evaluate against thresholds.";
            }
        } else {
            if (btnModeAuto) btnModeAuto.classList.add("active");
            if (btnModeManual) btnModeManual.classList.remove("active");
            if (manualControlGroup) manualControlGroup.style.display = "none";
            if (autoControlGroup) autoControlGroup.style.display = "flex";
            if (autoStatusBanner) autoStatusBanner.style.display = "flex";
            if (stepperCard) stepperCard.style.display = "none";
            if (measureModeDesc) {
                measureModeDesc.textContent = "Continuously acquire periodic telemetry from the sensor node after every configured interval.";
            }
        }
    }

    function setAutoButtonState(running) {
        if (!btnStartAuto) return;
        if (running) {
            btnStartAuto.className = "btn-auto-action btn-auto-stop";
            btnStartAuto.innerHTML = `
                <svg class="btn-icon" width="16" height="16" viewBox="0 0 24 24" fill="currentColor">
                    <rect x="5" y="5" width="14" height="14" rx="2"/>
                </svg>
                <span class="btn-text">Stop Auto</span>
            `;
        } else {
            btnStartAuto.className = "btn-auto-action btn-auto-start";
            btnStartAuto.innerHTML = `
                <svg class="btn-icon" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.3">
                    <polygon points="5 3 19 12 5 21 5 3"/>
                </svg>
                <span class="btn-text">Start Auto</span>
            `;
        }
    }

    async function handleToggleAuto() {
        if (!canStart) return;

        if (!isAutoRunning) {
            // --- 1. START AUTO ---
            isAutoRunning = true;
            setAutoButtonState(true);
            updateAutoBanner("running", "Auto Running", "Active - periodic measurement running");

            // If not measuring currently, trigger first cycle immediately
            if (!isMeasuringInProgress) {
                triggerAutoCycle();
            }
        } else {
            // --- 2. STOP AUTO ---
            isAutoRunning = false;
            setAutoButtonState(false);
            stopAutoCountdown();
            if (autoCountdownWrap) autoCountdownWrap.style.display = "none";
            updateAutoBanner("idle", "Auto Stopped", "Auto measurement stopped. Click Start Auto to begin.");

            // Stop in-flight measurement on client
            const cmdIdToStop = currentCommandId;
            stopMeasurementProcess();
            sessionStorage.removeItem(getStorageKey());
            setButtonState(false, "Start Measurement");

            // Request server to update active command status to DONE
            try {
                const formData = new URLSearchParams();
                formData.append("id", roomCode);
                if (cmdIdToStop !== null && cmdIdToStop !== undefined) {
                    formData.append("commandId", cmdIdToStop);
                }

                await fetch(`${ctx}/admin/rooms/measure/stop`, {
                    method: "POST",
                    headers: {
                        "Content-Type": "application/x-www-form-urlencoded;charset=UTF-8",
                        "X-Requested-With": "XMLHttpRequest",
                        "Accept": "application/json"
                    },
                    body: formData.toString()
                });
            } catch (e) {
                console.warn("Failed to notify stop to server:", e);
            }
        }
    }

    function triggerAutoCycle() {
        if (!isAutoRunning) return;
        if (isMeasuringInProgress) return;

        updateAutoBanner("measuring", "Measuring...", "Acquiring telemetry from sensor node (10s)...");
        if (autoCountdownWrap) autoCountdownWrap.style.display = "none";

        handleStartClick();
    }

    function startAutoCountdown() {
        stopAutoCountdown();
        if (!isAutoRunning) return;

        autoCountdownRemaining = autoIntervalSec;
        if (autoCountdownWrap) autoCountdownWrap.style.display = "inline-flex";
        if (autoCountdownVal) autoCountdownVal.textContent = autoCountdownRemaining;

        updateAutoBanner("running", "Auto Running", "Cycle complete. Waiting for next measurement...");

        autoCountdownTimerId = setInterval(() => {
            if (!isAutoRunning) {
                stopAutoCountdown();
                return;
            }

            autoCountdownRemaining--;
            if (autoCountdownVal) autoCountdownVal.textContent = autoCountdownRemaining;

            if (autoCountdownRemaining <= 0) {
                stopAutoCountdown();
                if (autoCountdownWrap) autoCountdownWrap.style.display = "none";
                triggerAutoCycle();
            }
        }, 1000);
    }

    function stopAutoCountdown() {
        if (autoCountdownTimerId) {
            clearInterval(autoCountdownTimerId);
            autoCountdownTimerId = null;
        }
    }

    function updateAutoBanner(state, badgeText, statusText) {
        if (autoPulseDot) autoPulseDot.className = "auto-pulse-dot " + state;
        if (autoStatusBadge) {
            autoStatusBadge.className = "auto-status-badge badge-" + state;
            autoStatusBadge.textContent = badgeText;
        }
        if (autoStatusText) autoStatusText.textContent = statusText;
    }

    function onMeasurementCycleFinished(success) {
        if (success) {
            autoSessionCount++;
            if (autoSessionCountEl) autoSessionCountEl.textContent = autoSessionCount;
        }

        if (isAutoRunning) {
            startAutoCountdown();
        }
    }

    function stopMeasurementProcess() {
        isMeasuringInProgress = false;
        stopPolling();
        stopElapsedTimer();
    }

    function stopPolling() {
        if (pollingTimerId) {
            clearTimeout(pollingTimerId);
            pollingTimerId = null;
        }
    }

    function startElapsedTimer() {
        stopElapsedTimer();
        if (!measureStartTime) measureStartTime = Date.now();
        if (timerBadge) timerBadge.style.display = "inline-flex";

        elapsedTimerId = setInterval(() => {
            if (!measureStartTime) return;
            const sec = Math.floor((Date.now() - measureStartTime) / 1000);
            if (timerVal) timerVal.textContent = sec;
        }, 500);
    }

    function stopElapsedTimer() {
        if (elapsedTimerId) {
            clearInterval(elapsedTimerId);
            elapsedTimerId = null;
        }
    }

    // 5. STEPPER VISUALIZATION
    function updateStepperState(status) {
        if (!step1Node || !step2Node || !step3Node) return;

        // Reset error classes
        step1Node.classList.remove("error");
        step2Node.classList.remove("error");
        step3Node.classList.remove("error");

        if (status === "PENDING") {
            step1Node.className = "step-node active";
            step2Node.className = "step-node";
            step3Node.className = "step-node";
            if (line1) line1.className = "step-line active";
            if (line2) line2.className = "step-line";
        } else if (status === "SENT") {
            step1Node.className = "step-node completed";
            step2Node.className = "step-node active";
            step3Node.className = "step-node";
            if (line1) line1.className = "step-line completed";
            if (line2) line2.className = "step-line active";
        } else if (status === "DONE") {
            step1Node.className = "step-node completed";
            step2Node.className = "step-node completed";
            step3Node.className = "step-node completed";
            if (line1) line1.className = "step-line completed";
            if (line2) line2.className = "step-line completed";
        }
    }

    function setStepperError(message) {
        if (!step1Node || !step2Node || !step3Node) return;
        step1Node.className = "step-node";
        step2Node.className = "step-node error";
        step3Node.className = "step-node";
        if (line1) line1.className = "step-line";
        if (line2) line2.className = "step-line";

        const sub = step2Node.querySelector(".step-sub");
        if (sub) sub.textContent = message || "Error";
    }

    function resetToIdle() {
        if (step1Node) step1Node.className = "step-node";
        if (step2Node) step2Node.className = "step-node";
        if (step3Node) step3Node.className = "step-node";
        if (line1) line1.className = "step-line";
        if (line2) line2.className = "step-line";
        if (timerBadge) timerBadge.style.display = "none";
        if (timerVal) timerVal.textContent = "0";
        setButtonState(false, "Start Measurement");
    }

    // 6. RENDER RESULTS & METRIC CARDS
    function renderResults(result) {
        if (!result) return;

        const th = result.thresholds || {};

        // Temperature
        renderMetricCard(
            cardTemp, valTemp, badgeTemp, threshTemp,
            result.temp, th.temp, "\u00B0C", "Temperature"
        );

        // Humidity
        renderMetricCard(
            cardHumid, valHumid, badgeHumid, threshHumid,
            result.humid, th.humid, "%", "Humidity"
        );

        // CO
        renderMetricCard(
            cardCo, valCo, badgeCo, threshCo,
            result.co, th.co, " ppm", "CO"
        );

        // CO2
        renderMetricCard(
            cardCo2, valCo2, badgeCo2, threshCo2,
            result.co2, th.co2, " ppm", "CO₂"
        );

        // Alerts List
        renderAlertsList(result.alerts);
    }

    function renderMetricCard(cardEl, valEl, badgeEl, threshEl, value, threshold, unit, label) {
        if (!cardEl || !valEl) return;

        if (value === null || value === undefined) {
            valEl.textContent = "--";
            if (badgeEl) {
                badgeEl.textContent = "No Data";
                badgeEl.className = "metric-pill status-neutral";
            }
            if (threshEl) threshEl.style.display = "none";
            return;
        }

        valEl.textContent = value + unit;

        const hasThresh = (threshold !== null && threshold !== undefined);
        const isExceeded = hasThresh && (Number(value) > Number(threshold));

        if (threshEl) {
            if (hasThresh) {
                threshEl.textContent = `Threshold: ≤ ${threshold}${unit}`;
                threshEl.style.display = "block";
            } else {
                threshEl.style.display = "none";
            }
        }

        if (isExceeded) {
            cardEl.classList.add("card-exceeded");
            if (badgeEl) {
                badgeEl.className = "metric-pill status-warning";
                badgeEl.textContent = "Exceeded";
            }
        } else {
            cardEl.classList.remove("card-exceeded");
            if (badgeEl) {
                badgeEl.className = "metric-pill status-normal";
                badgeEl.textContent = "Normal";
            }
        }
    }

    function resetMetricCards() {
        const cards = [
            { card: cardTemp, val: valTemp, badge: badgeTemp, thresh: threshTemp },
            { card: cardHumid, val: valHumid, badge: badgeHumid, thresh: threshHumid },
            { card: cardCo, val: valCo, badge: badgeCo, thresh: threshCo },
            { card: cardCo2, val: valCo2, badge: badgeCo2, thresh: threshCo2 }
        ];

        cards.forEach(c => {
            if (c.card) c.card.classList.remove("card-exceeded");
            if (c.val) c.val.textContent = "--";
            if (c.badge) {
                c.badge.className = "metric-pill status-neutral";
                c.badge.textContent = "Waiting";
            }
            if (c.thresh) c.thresh.style.display = "none";
        });
    }

    // 7. RENDER ALERTS LIST (XSS Safe)
    function renderAlertsList(alerts) {
        if (!alertsContainer) return;
        alertsContainer.textContent = ""; // Clear existing

        if (!alerts || alerts.length === 0) {
            const cleanBox = document.createElement("div");
            cleanBox.className = "measure-clean-state";

            // Check icon SVG
            cleanBox.innerHTML = `
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#16a34a" stroke-width="2.3" stroke-linecap="round" stroke-linejoin="round">
                    <polyline points="20 6 9 17 4 12"/>
                </svg>
            `;
            const textSpan = document.createElement("span");
            textSpan.textContent = "All readings are within thresholds.";
            cleanBox.appendChild(textSpan);
            alertsContainer.appendChild(cleanBox);
            return;
        }

        // Table for alerts
        const tableWrap = document.createElement("div");
        tableWrap.className = "table-responsive";

        const table = document.createElement("table");
        table.className = "alert-table";

        const thead = document.createElement("thead");
        thead.innerHTML = `
            <tr>
                <th style="width: 130px;">Alert Code</th>
                <th style="width: 140px;">Type</th>
                <th>Message</th>
                <th style="width: 120px;">Status</th>
            </tr>
        `;
        table.appendChild(thead);

        const tbody = document.createElement("tbody");

        alerts.forEach(al => {
            const tr = document.createElement("tr");

            // Code
            const tdCode = document.createElement("td");
            const spanCode = document.createElement("span");
            spanCode.className = "alert-code-pill";
            spanCode.textContent = al.alertCode || "–";
            tdCode.appendChild(spanCode);
            tr.appendChild(tdCode);

            // Type
            const tdType = document.createElement("td");
            const spanType = document.createElement("span");
            spanType.className = "status-pill status-warning";
            spanType.textContent = al.type || "–";
            tdType.appendChild(spanType);
            tr.appendChild(tdType);

            // Message
            const tdMsg = document.createElement("td");
            const divMsg = document.createElement("div");
            divMsg.className = "alert-message-text";
            divMsg.textContent = al.message || "–";
            tdMsg.appendChild(divMsg);
            tr.appendChild(tdMsg);

            // Status
            const tdStatus = document.createElement("td");
            const spanStatus = document.createElement("span");
            spanStatus.className = "table-status-pill status-progress";
            spanStatus.textContent = al.status || "OPENING";
            tdStatus.appendChild(spanStatus);
            tr.appendChild(tdStatus);

            tbody.appendChild(tr);
        });

        table.appendChild(tbody);
        tableWrap.appendChild(table);
        alertsContainer.appendChild(tableWrap);
    }

    function resetAlertsSection() {
        if (!alertsContainer) return;
        alertsContainer.textContent = "";
        const emptyBox = document.createElement("div");
        emptyBox.className = "measure-empty-state";
        emptyBox.textContent = "Measurement not started yet.";
        alertsContainer.appendChild(emptyBox);
    }

    // 8. PREPEND TO HISTORY TABLE
    function prependHistoryRecord(result) {
        if (!historyTbody) return;

        // Remove placeholder if present
        const emptyTr = historyTbody.querySelector("tr td[colspan]");
        if (emptyTr) {
            emptyTr.parentElement.remove();
        }

        const tr = document.createElement("tr");
        tr.style.background = "#f0fdf4"; // Subtle highlight for the newly measured row

        // Timestamp
        const tdTime = document.createElement("td");
        tdTime.textContent = result.measuredAt || new Date().toLocaleString();
        tr.appendChild(tdTime);

        // Temp
        const tdTemp = document.createElement("td");
        tdTemp.textContent = (result.temp !== null && result.temp !== undefined) ? (result.temp + "\u00B0C") : "–";
        tr.appendChild(tdTemp);

        // Humid
        const tdHumid = document.createElement("td");
        tdHumid.textContent = (result.humid !== null && result.humid !== undefined) ? (result.humid + "%") : "–";
        tr.appendChild(tdHumid);

        // CO2
        const tdCo2 = document.createElement("td");
        tdCo2.textContent = (result.co2 !== null && result.co2 !== undefined) ? (result.co2 + " ppm") : "–";
        tr.appendChild(tdCo2);

        // CO
        const tdCo = document.createElement("td");
        tdCo.textContent = (result.co !== null && result.co !== undefined) ? (result.co + " ppm") : "–";
        tr.appendChild(tdCo);

        // Status
        const tdStatus = document.createElement("td");
        const isAlert = result.alerts && result.alerts.length > 0;
        const spanStatus = document.createElement("span");
        spanStatus.className = "status-pill " + (isAlert ? "status-warning" : "status-normal");
        spanStatus.textContent = isAlert ? "Warning" : "Normal";
        tdStatus.appendChild(spanStatus);
        tr.appendChild(tdStatus);

        historyTbody.insertBefore(tr, historyTbody.firstChild);
    }

    // 9. ERROR HANDLING
    function handleHttpError(statusCode, json) {
        const errCode = (json && json.error) ? json.error : "";
        const errMsg = (json && json.message) ? json.message : "";

        if (statusCode === 401) {
            showAuthError();
        } else if (statusCode === 403) {
            showError("You do not have permission to perform this action.");
        } else if (statusCode === 409) {
            if (errCode === "NO_DEVICE") {
                showError("No active device is assigned to this room.");
            } else if (errCode === "DEVICE_BUSY") {
                showError("A measurement is already in progress for this room.");
            } else {
                showError(errMsg || "Conflict: Device or measurement error occurred.");
            }
        } else if (statusCode === 404) {
            showError("Room or measurement command not found.");
        } else if (statusCode === 400) {
            showError(errMsg || "Invalid measurement request data.");
        } else {
            showError(errMsg || "Something went wrong. Please try again.");
        }
    }

    function showAuthError() {
        if (!statusMsgBox) return;
        statusMsgBox.textContent = "";
        statusMsgBox.className = "measure-alert-banner alert-danger";

        const textSpan = document.createElement("span");
        textSpan.textContent = "Your session has expired. Please sign in again. ";

        const loginLink = document.createElement("a");
        loginLink.href = `${ctx}/login`;
        loginLink.textContent = "Sign in";
        loginLink.style.color = "#b91c1c";
        loginLink.style.fontWeight = "700";
        loginLink.style.textDecoration = "underline";

        statusMsgBox.appendChild(textSpan);
        statusMsgBox.appendChild(loginLink);
        statusMsgBox.style.display = "flex";
    }

    function showError(msg) {
        if (!statusMsgBox) return;
        statusMsgBox.textContent = msg;
        statusMsgBox.className = "measure-alert-banner alert-danger";
        statusMsgBox.style.display = "flex";
    }

    function showSuccess(msg) {
        if (!statusMsgBox) return;
        statusMsgBox.textContent = msg;
        statusMsgBox.className = "measure-alert-banner alert-info";
        statusMsgBox.style.display = "flex";
    }

    function hideMessage() {
        if (statusMsgBox) {
            statusMsgBox.style.display = "none";
            statusMsgBox.textContent = "";
        }
    }

    function setButtonState(disabled, label) {
        if (!btnStart) return;
        btnStart.disabled = disabled;
        if (btnText && label) btnText.textContent = label;
        if (btnSpinner) btnSpinner.style.display = disabled ? "inline-block" : "none";
    }

    // Initialize when DOM is ready
    if (document.readyState === "loading") {
        document.addEventListener("DOMContentLoaded", initMeasureTab);
    } else {
        initMeasureTab();
    }
})();
