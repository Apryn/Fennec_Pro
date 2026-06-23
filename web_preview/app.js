// Application State Management
let isActivated = false;
let currentTraderId = "";
let profitVal = 16659003;
let baseTradeVal = 14000;
let martingaleTradeVal = 17000;
let nextTradeVal = 14000;
let isBotActive = true;
let isMartingaleActive = false;
let consecutiveLossesCount = 0;

// Risk Management parameters matching Koala S Pro
let isAutoDemo = false;
let martingaleMultiplierPercent = 122; // default 122% (meaning multiplier 2.22)
let maxMartingaleLevels = "always";    // always, 1, 2, 3, etc.
let resetMartingaleLevel = "off";      // off, 1, 2, 3, etc.
let stopLossLimit = 4;                 // off, 1, 2, 3, 4, 5, etc.
let takeProfitLimit = 20000000;        // target profit to halt
let isDemoWallet = false;              // active demo mode state
let platformUrl = "https://olymptrade.com"; // active platform/mirror URL

// Full Automation & Anti-Ban variables
let isAutoTradingActive = false;
let minimumBalanceGuard = 200000;
let currentAccountBalance = 10000000;

// Time Keeping Variables
let clockInterval = null;
let stopwatchInterval = null;
let elapsedSeconds = 0;
let activeTab = "home";

// Mock History Data
const historyData = [];

// DOM Elements
const authScreen = document.getElementById("auth-screen");
const dashboardScreen = document.getElementById("dashboard-screen");
const traderIdInput = document.getElementById("trader-id-input");
const activateBtn = document.getElementById("activate-btn");
const authAlert = document.getElementById("auth-alert");
const alertText = document.getElementById("alert-text");

const profitCounter = document.getElementById("profit-counter");
const nextTradeValue = document.getElementById("next-trade-value");
const liveClock = document.getElementById("live-clock");
const stopwatch = document.getElementById("stopwatch");
const statusBanner = document.getElementById("status-banner");
const statusBannerText = document.getElementById("status-banner-text");
const statusIndicatorIcon = document.querySelector(".status-indicator-icon");

const configBtn = document.getElementById("config-btn");
const stopBotBtn = document.getElementById("stop-bot-btn");
const stopBotText = document.getElementById("stop-bot-text");
const simulateWinBtn = document.getElementById("simulate-win-btn");
const simulateLossBtn = document.getElementById("simulate-loss-btn");

const configModal = document.getElementById("config-modal");
const closeModalX = document.getElementById("close-modal-x");
const cancelConfigBtn = document.getElementById("cancel-config-btn");
const saveConfigBtn = document.getElementById("save-config-btn");
const baseTradeInput = document.getElementById("base-trade-input");
const martingaleTradeInput = document.getElementById("martingale-trade-input");

// New Risk Config DOM elements
const autoDemoToggle = document.getElementById("auto-demo-toggle");
const martingaleMultiplierInput = document.getElementById("martingale-multiplier-input");
const maxMartingaleSelect = document.getElementById("max-martingale-select");
const resetMartingaleSelect = document.getElementById("reset-martingale-select");
const stopLossSelect = document.getElementById("stop-loss-select");
const takeProfitInput = document.getElementById("take-profit-input");

// New Automation DOM elements
const activeBalanceValue = document.getElementById("active-balance-value");
const autoTradeToggle = document.getElementById("auto-trade-toggle");
const minBalanceInput = document.getElementById("min-balance-input");
const platformUrlInput = document.getElementById("platform-url-input");
const chartMockWebAddress = document.querySelector(".chart-mock-web-address");

const profileTraderId = document.getElementById("profile-trader-id");
const logoutBtn = document.getElementById("logout-btn");
const historyRows = document.getElementById("history-rows");

// --- INITIALIZATION ---
window.addEventListener("DOMContentLoaded", () => {
    startClock();
    startStopwatch();
    setupEventListeners();
    updateDashboardUI();
    startAutoSignalGenerator();
});

let autoSignalInterval = null;

function startAutoSignalGenerator() {
    if (autoSignalInterval) clearInterval(autoSignalInterval);
    autoSignalInterval = setInterval(() => {
        if (isBotActive && isAutoTradingActive) {
            // Generate a random signal direction
            const direction = Math.random() > 0.5 ? "UP" : "DOWN";
            statusBannerText.textContent = `Status: Sinyal ${direction} terdeteksi! Memulai eksekusi otomatis...`;
            statusBanner.className = "status-banner active";
            statusIndicatorIcon.className = "status-indicator-icon animate-pulse-glow-green";

            // Anti-ban random delay (1.5s to 3.5s) simulating human click delay
            const delay = Math.floor(Math.random() * 2000) + 1500;
            setTimeout(() => {
                if (!isBotActive || !isAutoTradingActive) return;

                // Deduct trade amount from active balance
                currentAccountBalance -= nextTradeVal;
                
                // Check Balance Guard Proteksi Saldo Minimum
                if (currentAccountBalance < minimumBalanceGuard) {
                    isBotActive = false;
                    isAutoTradingActive = false;
                    statusBannerText.textContent = `Status: FORCE STOP! Saldo (Rp ${formatCurrency(currentAccountBalance)}) di bawah batas proteksi (Rp ${formatCurrency(minimumBalanceGuard)}).`;
                    statusBanner.className = "status-banner";
                    statusIndicatorIcon.className = "status-indicator-icon animate-pulse-glow-red";
                    
                    // Add Guard stop to logs
                    const now = new Date();
                    const timeStr = `${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}:${String(now.getSeconds()).padStart(2, '0')}`;
                    historyData.unshift({
                        time: timeStr,
                        asset: "FORCE STOP (Saldo Guard)",
                        tradeSize: 0,
                        result: "GUARD",
                        profitChange: 0
                    });
                    
                    updateDashboardUI();
                    return;
                }

                // Random WIN/LOSS simulation
                const isWin = Math.random() > 0.40; // 60% win rate
                if (isWin) {
                    const profitEarned = Math.round(nextTradeVal * 0.82);
                    currentAccountBalance += nextTradeVal + profitEarned;
                    profitVal += profitEarned;
                    
                    addHistoryRecord(nextTradeVal, "WIN", profitEarned);

                    if (isDemoWallet) {
                        isDemoWallet = false;
                    }

                    isMartingaleActive = false;
                    consecutiveLossesCount = 0;
                    nextTradeVal = baseTradeVal;

                    if (profitVal >= takeProfitLimit) {
                        isBotActive = false;
                        isAutoTradingActive = false;
                        statusBannerText.textContent = "Status: Target Profit tercapai! Bot dihentikan.";
                    } else {
                        statusBannerText.textContent = `Status: Eksekusi ${direction} WIN! (+Rp ${formatCurrency(profitEarned)})`;
                    }
                } else {
                    profitVal -= nextTradeVal;
                    addHistoryRecord(nextTradeVal, "LOSS", -nextTradeVal);
                    consecutiveLossesCount++;
                    isMartingaleActive = true;

                    // Check Stop Loss
                    if (stopLossLimit !== "off" && consecutiveLossesCount >= stopLossLimit) {
                        if (isAutoDemo) {
                            isDemoWallet = true;
                            statusBannerText.textContent = "Status: Stop Loss tercapai! Beralih ke akun DEMO.";
                        } else {
                            isBotActive = false;
                            isAutoTradingActive = false;
                            statusBannerText.textContent = "Status: Stop Loss tercapai! Bot dihentikan.";
                        }
                        
                        nextTradeVal = baseTradeVal;
                        consecutiveLossesCount = 0;
                        isMartingaleActive = false;
                    } else {
                        // Apply multiplier
                        const multiplierFactor = 1.0 + (martingaleMultiplierPercent / 100.0);
                        nextTradeVal = Math.round(nextTradeVal * multiplierFactor);
                        statusBannerText.textContent = `Status: Eksekusi ${direction} LOSS. Mencoba Martingale langkah ${consecutiveLossesCount}...`;
                    }
                }
                updateDashboardUI();
            }, delay);
        }
    }, 15000); // Check/execute signal every 15 seconds for responsive simulation testing
}

// --- TIMER LOGIC ---
function startClock() {
    function updateClock() {
        const now = new Date();
        const hrs = String(now.getHours()).padStart(2, '0');
        const mins = String(now.getMinutes()).padStart(2, '0');
        const secs = String(now.getSeconds()).padStart(2, '0');
        liveClock.textContent = `${hrs}:${mins}:${secs}`;
    }
    updateClock();
    clockInterval = setInterval(updateClock, 1000);
}

function startStopwatch() {
    if (stopwatchInterval) clearInterval(stopwatchInterval);
    
    stopwatchInterval = setInterval(() => {
        if (isBotActive) {
            elapsedSeconds++;
            const hrs = String(Math.floor(elapsedSeconds / 3600)).padStart(2, '0');
            const mins = String(Math.floor((elapsedSeconds % 3600) / 60)).padStart(2, '0');
            const secs = String(elapsedSeconds % 60).padStart(2, '0');
            stopwatch.textContent = `${hrs}:${mins}:${secs}`;
        }
    }, 1000);
}

// --- EVENT LISTENERS ---
function setupEventListeners() {
    // Lock Screen Submit
    activateBtn.addEventListener("click", handleActivation);
    traderIdInput.addEventListener("keypress", (e) => {
        if (e.key === "Enter") handleActivation();
    });

    // Tab Navigation
    const navItems = document.querySelectorAll(".bottom-nav .nav-item");
    navItems.forEach(item => {
        item.addEventListener("click", () => {
            const tabName = item.getAttribute("data-tab");
            switchTab(tabName);
        });
    });

    // Modal Actions
    configBtn.addEventListener("click", openConfigModal);
    closeModalX.addEventListener("click", closeConfigModal);
    cancelConfigBtn.addEventListener("click", closeConfigModal);
    saveConfigBtn.addEventListener("click", saveConfig);

    // Simulation controls
    stopBotBtn.addEventListener("click", toggleBotStatus);
    simulateWinBtn.addEventListener("click", runSimulateWin);
    simulateLossBtn.addEventListener("click", runSimulateLoss);

    // Logout
    logoutBtn.addEventListener("click", handleLogout);

    // Theme Engine adjustments
    const themeChoices = document.querySelectorAll(".theme-choice");
    themeChoices.forEach(choice => {
        choice.addEventListener("click", () => {
            themeChoices.forEach(c => c.classList.remove("active"));
            choice.classList.add("active");
            
            const theme = choice.getAttribute("data-theme");
            setThemeAccent(theme);
        });
    });

    const glowSlider = document.getElementById("glow-slider");
    glowSlider.addEventListener("input", (e) => {
        const val = e.target.value;
        document.documentElement.style.setProperty("--theme-glow-size", `${val}px`);
    });

    const contrastToggle = document.getElementById("contrast-toggle");
    contrastToggle.addEventListener("change", (e) => {
        if (e.target.checked) {
            document.body.classList.add("high-contrast-mode");
        } else {
            document.body.classList.remove("high-contrast-mode");
        }
    });

    // Animated Chart updates
    animateMockChart();

    // Auto format inputs on blur to match screenshot style
    baseTradeInput.addEventListener("blur", () => {
        const val = parseFormattedInt(baseTradeInput.value);
        baseTradeInput.value = formatDottedInt(val);
    });
    martingaleTradeInput.addEventListener("blur", () => {
        const val = parseFormattedInt(martingaleTradeInput.value);
        martingaleTradeInput.value = formatDottedInt(val);
    });
    martingaleMultiplierInput.addEventListener("blur", () => {
        let val = parseFormattedInt(martingaleMultiplierInput.value);
        if (val < 10) val = 10;
        if (val > 500) val = 500;
        martingaleMultiplierInput.value = val + "%";
    });
    takeProfitInput.addEventListener("blur", () => {
        const val = parseFormattedInt(takeProfitInput.value);
        takeProfitInput.value = formatDottedInt(val);
    });
    minBalanceInput.addEventListener("blur", () => {
        const val = parseFormattedInt(minBalanceInput.value);
        minBalanceInput.value = formatDottedInt(val);
    });
}

// --- AFFILIATE AUTH LOGIC ---
function handleActivation() {
    const inputVal = traderIdInput.value.trim();
    hideAlert();

    if (!inputVal) {
        showAlert("INVALID: Trader ID tidak boleh kosong.", "error");
        return;
    }

    // Allow any numeric ID of 5-15 digits as success, except specific test IDs.
    if (inputVal === "77777") {
        showAlert("WRONG_AFFILIATE: ID terdaftar di tim pusat, tetapi bukan melalui link khusus live ini. Silakan daftar ulang melalui link di bio TikTok kami!", "error");
    } 
    else if (/^\d{5,15}$/.test(inputVal)) {
        // Success
        currentTraderId = inputVal;
        isActivated = true;
        profileTraderId.textContent = currentTraderId;
        
        // Transition screen
        authScreen.classList.remove("active");
        dashboardScreen.classList.add("active");
        
        // Reset stopwatch
        elapsedSeconds = 0;
        isBotActive = true;
        updateDashboardUI();
    }
    else {
        showAlert("INVALID: ID tidak ditemukan atau format tidak sesuai. Pastikan Anda sudah mendaftar via link di bio TikTok dan memasukkan 5-15 digit angka.", "error");
    }
}

function handleLogout() {
    isActivated = false;
    currentTraderId = "";
    traderIdInput.value = "";
    
    dashboardScreen.classList.remove("active");
    authScreen.classList.add("active");
    switchTab("home");
}

function showAlert(message, type) {
    alertText.textContent = message;
    authAlert.className = `alert-message ${type}`;
    authAlert.classList.remove("hidden");
}

function hideAlert() {
    authAlert.classList.add("hidden");
}

// --- TAB ROUTING ---
function switchTab(tabName) {
    activeTab = tabName;
    
    // Update subpages visibility
    const subpages = document.querySelectorAll(".subpage");
    subpages.forEach(page => {
        page.classList.remove("active");
    });
    document.getElementById(`${tabName}-subpage`).classList.add("active");

    // Update bottom nav items state
    const navItems = document.querySelectorAll(".bottom-nav .nav-item");
    navItems.forEach(item => {
        item.classList.remove("active");
        if (item.getAttribute("data-tab") === tabName) {
            item.classList.add("active");
        }
    });

    if (tabName === "history") {
        renderHistory();
    }
}

// Helper formatting functions
function formatDottedInt(val) {
    return val.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ".");
}

function parseFormattedInt(valStr) {
    const clean = valStr.toString().replace(/[^0-9]/g, '');
    return parseInt(clean) || 0;
}

// --- CONFIGURATION MODAL ---
function openConfigModal() {
    baseTradeInput.value = formatDottedInt(baseTradeVal);
    martingaleTradeInput.value = formatDottedInt(martingaleTradeVal);
    autoDemoToggle.checked = isAutoDemo;
    autoTradeToggle.checked = isAutoTradingActive;
    martingaleMultiplierInput.value = martingaleMultiplierPercent + "%";
    maxMartingaleSelect.value = maxMartingaleLevels;
    resetMartingaleSelect.value = resetMartingaleLevel;
    stopLossSelect.value = stopLossLimit;
    takeProfitInput.value = formatDottedInt(takeProfitLimit);
    minBalanceInput.value = formatDottedInt(minimumBalanceGuard);
    platformUrlInput.value = platformUrl;
    configModal.classList.remove("hidden");
}

function closeConfigModal() {
    configModal.classList.add("hidden");
}

function saveConfig() {
    const baseVal = parseFormattedInt(baseTradeInput.value);
    const martVal = parseFormattedInt(martingaleTradeInput.value);
    const multiplierVal = parseFormattedInt(martingaleMultiplierInput.value);
    const takeProfitVal = parseFormattedInt(takeProfitInput.value);
    const minBalanceVal = parseFormattedInt(minBalanceInput.value);
    const urlVal = platformUrlInput.value.trim();

    if (baseVal <= 0 || martVal <= 0 || multiplierVal <= 0 || takeProfitVal <= 0 || minBalanceVal < 0 || !urlVal) {
        alert("Semua nominal input harus valid, dan URL platform tidak boleh kosong.");
        return;
    }

    baseTradeVal = baseVal;
    martingaleTradeVal = martVal;
    isAutoDemo = autoDemoToggle.checked;
    isAutoTradingActive = autoTradeToggle.checked;
    martingaleMultiplierPercent = multiplierVal;
    maxMartingaleLevels = maxMartingaleSelect.value;
    resetMartingaleLevel = resetMartingaleSelect.value;
    stopLossLimit = stopLossSelect.value === "off" ? "off" : parseInt(stopLossSelect.value);
    takeProfitLimit = takeProfitVal;
    minimumBalanceGuard = minBalanceVal;
    platformUrl = urlVal;

    // Update the mock web address bar at the bottom of the chart
    if (chartMockWebAddress) {
        chartMockWebAddress.innerHTML = `<span class="lock-icon">🔒</span> ${platformUrl}/platform`;
    }

    // Recalculate next trade based on current state
    if (isMartingaleActive) {
        nextTradeVal = martingaleTradeVal;
    } else {
        nextTradeVal = baseTradeVal;
    }

    updateDashboardUI();
    closeConfigModal();
}

// --- BOT STATUS CONTROLS ---
function toggleBotStatus() {
    isBotActive = !isBotActive;
    updateDashboardUI();
}

// --- SIMULATION CALCULATIONS (WIN/LOSS) ---
function runSimulateWin() {
    if (!isBotActive) return;

    // Win payout is typically 82% of trade amount
    const profitEarned = Math.round(nextTradeVal * 0.82);
    profitVal += profitEarned;

    // Record history
    addHistoryRecord(nextTradeVal, "WIN", profitEarned);

    // If auto demo was triggered, switch back to real wallet on win
    if (isDemoWallet) {
        isDemoWallet = false;
        statusBannerText.textContent = "Status: Profit! Beralih kembali ke akun REAL.";
    }

    // Reset Martingale
    isMartingaleActive = false;
    consecutiveLossesCount = 0;
    nextTradeVal = baseTradeVal;

    // Check Take Profit Limit
    if (profitVal >= takeProfitLimit) {
        isBotActive = false;
        statusBannerText.textContent = "Status: Target Profit tercapai! Bot dihentikan.";
    }

    // Highlight metrics card green briefly
    pulseCardBorder("green");
    updateDashboardUI();
}

function runSimulateLoss() {
    if (!isBotActive) return;

    // Loss subtracts the entire trade amount
    profitVal -= nextTradeVal;

    // Record history
    addHistoryRecord(nextTradeVal, "LOSS", -nextTradeVal);

    consecutiveLossesCount++;
    isMartingaleActive = true;

    // 1. Check Stop Loss Limit
    if (stopLossLimit !== "off" && consecutiveLossesCount >= stopLossLimit) {
        if (isAutoDemo) {
            isDemoWallet = true;
            statusBannerText.textContent = "Status: Stop Loss tercapai! Beralih ke akun DEMO.";
        } else {
            isBotActive = false;
            statusBannerText.textContent = "Status: Stop Loss tercapai! Bot dihentikan.";
        }
        
        nextTradeVal = baseTradeVal;
        consecutiveLossesCount = 0;
        isMartingaleActive = false;

        pulseCardBorder("red");
        updateDashboardUI();
        return;
    }

    // 2. Check Martingale Capping / Resets
    let reachedMaxMart = false;
    if (maxMartingaleLevels !== "always") {
        const maxLevel = parseInt(maxMartingaleLevels);
        if (consecutiveLossesCount > maxLevel) {
            reachedMaxMart = true;
        }
    }

    let reachedResetMart = false;
    if (resetMartingaleLevel !== "off") {
        const resetLevel = parseInt(resetMartingaleLevel);
        if (consecutiveLossesCount > resetLevel) {
            reachedResetMart = true;
        }
    }

    if (reachedMaxMart || reachedResetMart) {
        nextTradeVal = baseTradeVal;
        consecutiveLossesCount = 0;
        isMartingaleActive = false;
    } else {
        if (consecutiveLossesCount === 1) {
            nextTradeVal = martingaleTradeVal;
        } else {
            // Apply Martingale percentage (e.g. 122% means multiply previous by 2.22)
            const multiplierFactor = 1.0 + (martingaleMultiplierPercent / 100.0);
            nextTradeVal = Math.round(nextTradeVal * multiplierFactor);
        }
    }

    // Highlight metrics card red briefly
    pulseCardBorder("red");
    updateDashboardUI();
}

// --- UI UPDATERS ---
function updateDashboardUI() {
    // Format profit counter string: 16.659.003
    profitCounter.textContent = formatCurrency(profitVal);

    // Update wallet label type
    const walletTypeLabel = document.querySelector(".metrics-card .card-label");
    if (walletTypeLabel) {
        walletTypeLabel.textContent = isDemoWallet 
            ? "PROFIT HARI INI (DEMO WALLET)" 
            : "PROFIT HARI INI (REAL WALLET)";
        
        if (isDemoWallet) {
            walletTypeLabel.style.color = "var(--neon-yellow)";
        } else {
            walletTypeLabel.style.color = "var(--color-text-muted)";
        }
    }

    // Next Trade banner indicators
    nextTradeValue.textContent = `Rp ${formatCurrency(nextTradeVal)}`;
    if (isMartingaleActive) {
        nextTradeValue.className = "next-trade-value-style yellow";
    } else {
        nextTradeValue.className = "next-trade-value-style green";
    }

    // Active Balance indicator
    if (activeBalanceValue) {
        activeBalanceValue.textContent = `Rp ${formatCurrency(currentAccountBalance)}`;
    }

    // Bot Active states
    if (isBotActive) {
        statusBanner.className = "status-banner active";
        statusBannerText.textContent = "Status: Fennec sedang bekerja...";
        statusIndicatorIcon.className = "status-indicator-icon animate-pulse-glow-green";
        
        stopBotText.textContent = "STOP BOT";
        stopBotBtn.className = "btn-alert-red ripple";
    } else {
        statusBanner.className = "status-banner";
        statusBannerText.textContent = "Status: Fennec dihentikan.";
        statusIndicatorIcon.className = "status-indicator-icon animate-pulse-glow-red";
        
        stopBotText.textContent = "START BOT";
        stopBotBtn.className = "btn-alert-red stopped ripple";
    }
}

function formatCurrency(val) {
    const absolute = Math.abs(val);
    const formatted = absolute.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ".");
    return val < 0 ? `-${formatted}` : formatted;
}

function pulseCardBorder(result) {
    const card = document.querySelector(".metrics-card");
    card.classList.remove("card-glow-green", "card-glow-red");
    
    if (result === "green") {
        card.classList.add("card-glow-green");
    } else {
        card.classList.add("card-glow-red");
    }
}

// --- HISTORY TAB POPULATOR ---
function addHistoryRecord(amount, outcome, diff) {
    const now = new Date();
    const timeStr = `${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}:${String(now.getSeconds()).padStart(2, '0')}`;
    
    const assets = ["BTC/USD (Crypto)", "EUR/USD", "GBP/USD", "AUD/USD", "USD/JPY"];
    const randomAsset = assets[Math.floor(Math.random() * assets.length)];

    historyData.unshift({
        time: timeStr,
        asset: randomAsset,
        tradeSize: amount,
        result: outcome,
        profitChange: diff
    });

    // Keep history length reasonable
    if (historyData.length > 20) {
        historyData.pop();
    }
}

function renderHistory() {
    if (historyData.length === 0) {
        historyRows.innerHTML = `
            <tr class="empty-row">
                <td colspan="4">Belum ada transaksi simulasi</td>
            </tr>
        `;
        return;
    }

    let rowsHTML = "";
    historyData.forEach(item => {
        const outcomeClass = item.result === "WIN" ? "win-row" : "loss-row";
        const sign = item.profitChange > 0 ? "+" : "";
        const formattedDiff = formatCurrency(item.profitChange);
        
        rowsHTML += `
            <tr class="${outcomeClass}">
                <td>${item.time}</td>
                <td>${item.asset}</td>
                <td>Rp ${formatCurrency(item.tradeSize)}</td>
                <td class="result-cell">${item.result} (${sign}Rp ${formattedDiff})</td>
            </tr>
        `;
    });
    historyRows.innerHTML = rowsHTML;
}

// --- THEME ENGINE SETTERS ---
function setThemeAccent(themeName) {
    const root = document.documentElement;
    let accentHex = "#00c853";
    let glowColor = "rgba(0, 200, 83, 0.35)";

    switch (themeName) {
        case "neon-green":
            accentHex = "#00c853";
            glowColor = "rgba(0, 200, 83, 0.35)";
            break;
        case "electric-blue":
            accentHex = "#00d2ff";
            glowColor = "rgba(0, 210, 255, 0.4)";
            break;
        case "hot-pink":
            accentHex = "#ff007f";
            glowColor = "rgba(255, 0, 127, 0.45)";
            break;
        case "toxic-purple":
            accentHex = "#9d00ff";
            glowColor = "rgba(157, 0, 255, 0.4)";
            break;
    }

    root.style.setProperty("--theme-accent", accentHex);
    root.style.setProperty("--theme-glow-color", glowColor);
}

// --- ACTIVE CHART DRAWING ANIMATION ---
function animateMockChart() {
    const chartLine = document.getElementById("live-chart-line");
    const pulsingDot = document.querySelector(".pulsing-chart-dot");
    const chartPrice = document.querySelector(".chart-price");
    
    let chartPoints = [130, 110, 120, 70, 90, 50, 40];
    let priceMultiplier = 1.054402100;
    
    setInterval(() => {
        // Shift points
        chartPoints.shift();
        
        // Random new point between 30 and 130
        const lastPoint = chartPoints[chartPoints.length - 1];
        let change = (Math.random() - 0.5) * 40;
        let newPoint = Math.min(Math.max(lastPoint + change, 25), 140);
        chartPoints.push(newPoint);
        
        // Generate SVG Q curve path
        let pathStr = `M 0 ${chartPoints[0]}`;
        let step = 300 / 6;
        for (let i = 1; i < chartPoints.length; i++) {
            let prevX = (i - 1) * step;
            let currentX = i * step;
            let midX = (prevX + currentX) / 2;
            pathStr += ` Q ${midX} ${chartPoints[i-1]} ${currentX} ${chartPoints[i]}`;
        }
        
        chartLine.setAttribute("d", pathStr);
        pulsingDot.setAttribute("cx", "300");
        pulsingDot.setAttribute("cy", String(newPoint));
        
        // Modify gradient fill
        const chartArea = document.querySelector("path[fill^='url']");
        if (chartArea) {
            chartArea.setAttribute("d", `${pathStr} L 300 150 L 0 150 Z`);
        }

        // Simulate price updates
        let pct = (Math.random() - 0.49) * 0.15; // slightly positive drift
        priceMultiplier = priceMultiplier * (1 + pct/100);
        const rawPrice = Math.round(priceMultiplier * 1000000000);
        const changePct = ((priceMultiplier - 1.054402100) / 1.054402100 * 100).toFixed(2);
        
        chartPrice.textContent = `Rp ${formatCurrency(rawPrice)} (${changePct >= 0 ? '+' : ''}${changePct}%)`;
        if (changePct >= 0) {
            chartPrice.className = "chart-price positive";
            chartPrice.style.color = "var(--theme-accent)";
        } else {
            chartPrice.className = "chart-price negative";
            chartPrice.style.color = "var(--neon-red)";
        }
    }, 1500);
}
