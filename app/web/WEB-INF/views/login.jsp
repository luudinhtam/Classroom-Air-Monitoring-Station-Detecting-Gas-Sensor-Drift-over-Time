<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="util.Web" %>
<%
    String error = (String) request.getAttribute("error");
    String ctx = request.getContextPath();
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Sign In – Classroom Temp Monitoring System</title>
    <link rel="shortcut icon" href="<%= ctx %>/favicon.ico" type="image/x-icon">
    <!-- Google Fonts: Be Vietnam Pro -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Be+Vietnam+Pro:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="<%= ctx %>/assets/css/login_new.css">
    <style>
        /* Đảm bảo đường dẫn hình nền chính xác theo contextPath của ứng dụng */
        .intro-backdrop {
            background-image: url('<%= ctx %>/assets/images/classroom_default.png'), 
                              url('https://images.unsplash.com/photo-1580582932707-520aed937b7b?auto=format&fit=crop&w=1600&q=80') !important;
        }
    </style>
</head>
<body>

    <div class="login-wrapper">
        <!-- =========================================================================
             1. LEFT SIDE (~58%) – BRAND INTRO & SHOWCASE PANE
             ========================================================================= -->
        <section class="intro-pane">
            <div class="intro-backdrop"></div>
            <div class="intro-overlay"></div>

            <div class="intro-content">
                <!-- Logo & Brand Header -->
                <div class="brand-header">
                    <div class="brand-logo-box">
                        <!-- Thermometer White Icon -->
                        <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="#ffffff" stroke-width="2.3" stroke-linecap="round" stroke-linejoin="round">
                            <path d="M14 14.76V3.5a2.5 2.5 0 0 0-5 0v11.26a4.5 4.5 0 1 0 5 0z"/>
                            <circle cx="11.5" cy="17.5" r="1.5" fill="#ffffff"/>
                        </svg>
                    </div>
                    <div class="brand-text">
                        <span class="brand-title">Classroom Temp</span>
                        <span class="brand-subtitle">Monitoring System</span>
                    </div>
                </div>

                <!-- Headline & Intro Description -->
                <div class="intro-hero">
                    <h1 class="hero-title">
                        Classroom Temperature Monitoring<br>
                        for an Ideal Learning Environment
                    </h1>
                    <p class="hero-desc">
                        An IoT-powered platform to track temperature, humidity, and classroom conditions in real time,
                        supporting efficient facility management and ensuring student well-being.
                    </p>
                </div>

                <!-- 4 Feature Highlights -->
                <div class="features-row">
                    <div class="feature-item">
                        <div class="feature-icon bg-green-light">
                            <!-- Thermometer Green -->
                            <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#16a34a" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                                <path d="M14 14.76V3.5a2.5 2.5 0 0 0-5 0v11.26a4.5 4.5 0 1 0 5 0z"/>
                                <circle cx="11.5" cy="17.5" r="1.5" fill="#16a34a"/>
                            </svg>
                        </div>
                        <span class="feature-label">Temperature<br>Tracking</span>
                    </div>

                    <div class="feature-item">
                        <div class="feature-icon bg-blue-light">
                            <!-- Waterdrop Blue -->
                            <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#1d63ed" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                                <path d="M12 2.69l5.66 5.66a8 8 0 1 1-11.31 0z"/>
                            </svg>
                        </div>
                        <span class="feature-label">Humidity<br>Monitoring</span>
                    </div>

                    <div class="feature-item">
                        <div class="feature-icon bg-purple-light">
                            <!-- Wifi / Alert Purple -->
                            <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#8b5cf6" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                                <path d="M5 12.55a11 11 0 0 1 14.08 0"/>
                                <path d="M1.42 9a16 16 0 0 1 21.16 0"/>
                                <path d="M8.53 16.11a6 6 0 0 1 6.95 0"/>
                                <line x1="12" y1="20" x2="12.01" y2="20"/>
                            </svg>
                        </div>
                        <span class="feature-label">Automated<br>Alerts</span>
                    </div>

                    <div class="feature-item">
                        <div class="feature-icon bg-blue-light">
                            <!-- Visual Analytics Blue -->
                            <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#1d63ed" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                                <line x1="18" y1="20" x2="18" y2="10"/>
                                <line x1="12" y1="20" x2="12" y2="4"/>
                                <line x1="6" y1="20" x2="6" y2="14"/>
                            </svg>
                        </div>
                        <span class="feature-label">Visual<br>Analytics</span>
                    </div>
                </div>

                <!-- Glassmorphism Preview Card -->
                <div class="preview-glass-card">
                    <div class="glass-header">
                        <div class="glass-temp-group">
                            <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#1d63ed" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                                <path d="M14 14.76V3.5a2.5 2.5 0 0 0-5 0v11.26a4.5 4.5 0 1 0 5 0z"/>
                                <circle cx="11.5" cy="17.5" r="1.5" fill="#1d63ed"/>
                            </svg>
                            <span class="glass-temp-val">24.5°C</span>
                        </div>
                        <span class="glass-badge-status">
                            <span class="status-dot"></span> Normal
                        </span>
                    </div>

                    <!-- Emerald Smooth Sparkline SVG -->
                    <div class="glass-sparkline">
                        <svg viewBox="0 0 200 45" class="glass-spark-svg">
                            <defs>
                                <linearGradient id="glassSparkGrad" x1="0" y1="0" x2="0" y2="1">
                                    <stop offset="0%" stop-color="rgba(20, 184, 166, 0.35)"/>
                                    <stop offset="100%" stop-color="rgba(20, 184, 166, 0.0)"/>
                                </linearGradient>
                            </defs>
                            <path d="M 0 32 Q 35 15, 65 26 T 130 18 T 170 28 T 200 12 L 200 45 L 0 45 Z" fill="url(#glassSparkGrad)"/>
                            <path d="M 0 32 Q 35 15, 65 26 T 130 18 T 170 28 T 200 12" fill="none" stroke="#0d9488" stroke-width="2.5" stroke-linecap="round"/>
                        </svg>
                    </div>

                    <div class="glass-footer">
                        <div class="glass-metric">
                            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#1d63ed" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                <path d="M12 2.69l5.66 5.66a8 8 0 1 1-11.31 0z"/>
                            </svg>
                            <div class="metric-text">
                                <span class="val">58%</span>
                                <span class="lbl">Humidity</span>
                            </div>
                        </div>
                        <div class="glass-metric">
                            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#16a34a" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                <path d="M5 12.55a11 11 0 0 1 14.08 0"/>
                                <path d="M1.42 9a16 16 0 0 1 21.16 0"/>
                                <circle cx="12" cy="20" r="1" fill="#16a34a"/>
                            </svg>
                            <div class="metric-text">
                                <span class="val">Sensor</span>
                                <span class="lbl">Active</span>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Bottom Wave SVG & Slogan -->
            <div class="intro-bottom-wave">
                <svg class="wave-svg" viewBox="0 0 1200 120" preserveAspectRatio="none">
                    <defs>
                        <linearGradient id="waveGrad" x1="0" y1="0" x2="1" y2="0">
                            <stop offset="0%" stop-color="#2563eb"/>
                            <stop offset="100%" stop-color="#4f8ff0"/>
                        </linearGradient>
                    </defs>
                    <path d="M0,45 C220,95 440,15 700,55 C920,85 1060,30 1200,60 L1200,120 L0,120 Z" fill="url(#waveGrad)"></path>
                </svg>
                <div class="wave-content">
                    <!-- Leaf Icon -->
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="rgba(255,255,255,0.85)" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M11 20A7 7 0 0 1 4 13a17 17 0 0 1 17-9 7 7 0 0 1-7 16h-3z"/>
                        <path d="M2 21c0-3 1.85-5.36 5.08-6"/>
                    </svg>
                    <span>Connected Technology &nbsp;·&nbsp; Safe &nbsp;·&nbsp; Efficient</span>
                </div>
            </div>
        </section>

        <!-- =========================================================================
             2. RIGHT SIDE (~42%) – SIGN IN FORM (CLEAN WHITE)
             ========================================================================= -->
        <section class="form-pane">
            <div class="form-card">
                <!-- Graduation Cap Blue Icon -->
                <div class="grad-cap-wrapper">
                    <svg width="80" height="80" viewBox="0 0 24 24" fill="none" stroke="#1d63ed" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M22 10v6M2 10l10-5 10 5-10 5z"/>
                        <path d="M6 12v5c0 2 3 3 6 3s6-1 6-3v-5"/>
                    </svg>
                </div>

                <h2 class="form-title">Sign In</h2>
                <p class="form-desc">Please sign in to continue using the classroom temperature monitoring system.</p>

                <!-- Server Error Alert Box -->
                <div id="generalError" class="alert-error-box" style="<%= (error != null) ? "display: flex;" : "display: none;" %>">
                    <!-- Alert Triangle Icon -->
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#ef4444" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <circle cx="12" cy="12" r="10"/>
                        <line x1="12" y1="8" x2="12" y2="12"/>
                        <line x1="12" y1="16" x2="12.01" y2="16"/>
                    </svg>
                    <span id="generalErrorText">
                        <% if (error != null) { %>
                            <%= error.equalsIgnoreCase("Sai ten dang nhap hoac mat khau") ? "Invalid username or password" : Web.esc(error) %>
                        <% } else { %>
                            Invalid username or password
                        <% } %>
                    </span>
                </div>

                <!-- Login Form kết nối POST về /login của Servlet -->
                <form id="loginForm" class="login-form-inner" method="post" action="<%= ctx %>/login" novalidate>
                    <!-- Username Field -->
                    <div class="input-field-group">
                        <div class="input-container" id="usernameContainer">
                            <!-- User Icon -->
                            <svg class="field-icon" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/>
                                <circle cx="12" cy="7" r="4"/>
                            </svg>
                            <input type="text" id="usernameInput" name="username" placeholder="Username" autocomplete="username" autofocus required>
                        </div>
                        <span class="field-error-msg" id="usernameError"></span>
                    </div>

                    <!-- Password Field -->
                    <div class="input-field-group">
                        <div class="input-container" id="passwordContainer">
                            <!-- Lock Icon -->
                            <svg class="field-icon" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                <rect x="3" y="11" width="18" height="11" rx="2" ry="2"/>
                                <path d="M7 11V7a5 5 0 0 1 10 0v4"/>
                            </svg>
                            <input type="password" id="passwordInput" name="password" placeholder="Password" autocomplete="current-password" required>
                            <!-- Password Toggle Eye Button -->
                            <button type="button" class="eye-toggle-btn" id="togglePasswordBtn" aria-label="Toggle password visibility">
                                <!-- Eye Off Icon (default) -->
                                <svg id="eyeOffIcon" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                    <path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24"/>
                                    <line x1="1" y1="1" x2="23" y2="23"/>
                                </svg>
                                <!-- Eye On Icon (when visible) -->
                                <svg id="eyeOnIcon" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="display: none;">
                                    <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/>
                                    <circle cx="12" cy="12" r="3"/>
                                </svg>
                            </button>
                        </div>
                        <span class="field-error-msg" id="passwordError"></span>
                    </div>

                    <!-- Options: Remember me + Forgot password -->
                    <div class="form-options-row">
                        <label class="custom-checkbox-label">
                            <input type="checkbox" id="rememberMeCheckbox" name="rememberMe">
                            <span class="checkbox-box">
                                <svg class="check-mark" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="#ffffff" stroke-width="3.5" stroke-linecap="round" stroke-linejoin="round">
                                    <polyline points="20 6 9 17 4 12"/>
                                </svg>
                            </span>
                            <span class="checkbox-text">Remember me</span>
                        </label>
                        <a href="#" class="forgot-link" id="forgotPasswordLink">Forgot password?</a>
                    </div>

                    <!-- Sign In Submit Button -->
                    <button type="submit" class="btn-submit" id="submitBtn">
                        <span class="btn-text">Sign In</span>
                        <!-- Right Arrow SVG -->
                        <svg class="btn-arrow-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#ffffff" stroke-width="2.3" stroke-linecap="round" stroke-linejoin="round">
                            <line x1="5" y1="12" x2="19" y2="12"/>
                            <polyline points="12 5 19 12 12 19"/>
                        </svg>
                        <span class="btn-spinner" id="btnSpinner" style="display: none;"></span>
                    </button>
                </form>



                <!-- Footer Copyright -->
                <footer class="form-footer">
                    <div>Classroom Temperature Monitoring System</div>
                    <div>&copy; 2025. All rights reserved.</div>
                </footer>
            </div>
        </section>
    </div>

    <script>
        // DOM Elements
        const loginForm = document.getElementById("loginForm");
        const usernameInput = document.getElementById("usernameInput");
        const passwordInput = document.getElementById("passwordInput");
        const usernameContainer = document.getElementById("usernameContainer");
        const passwordContainer = document.getElementById("passwordContainer");
        const usernameError = document.getElementById("usernameError");
        const passwordError = document.getElementById("passwordError");
        const generalError = document.getElementById("generalError");
        const togglePasswordBtn = document.getElementById("togglePasswordBtn");
        const eyeOffIcon = document.getElementById("eyeOffIcon");
        const eyeOnIcon = document.getElementById("eyeOnIcon");
        const rememberMeCheckbox = document.getElementById("rememberMeCheckbox");
        const forgotPasswordLink = document.getElementById("forgotPasswordLink");
        const submitBtn = document.getElementById("submitBtn");
        const btnSpinner = document.getElementById("btnSpinner");
        const btnText = submitBtn.querySelector(".btn-text");
        const btnArrow = submitBtn.querySelector(".btn-arrow-icon");

        // Toggle Password Visibility
        togglePasswordBtn.addEventListener("click", () => {
            const isPassword = passwordInput.getAttribute("type") === "password";
            if (isPassword) {
                passwordInput.setAttribute("type", "text");
                eyeOffIcon.style.display = "none";
                eyeOnIcon.style.display = "block";
            } else {
                passwordInput.setAttribute("type", "password");
                eyeOffIcon.style.display = "block";
                eyeOnIcon.style.display = "none";
            }
            passwordInput.focus();
        });

        // Clear error highlights on input
        function clearFieldError(container, errorEl) {
            container.classList.remove("error");
            errorEl.innerText = "";
            if (generalError) generalError.style.display = "none";
        }

        usernameInput.addEventListener("input", () => clearFieldError(usernameContainer, usernameError));
        passwordInput.addEventListener("input", () => clearFieldError(passwordContainer, passwordError));

        // Forgot password notice
        forgotPasswordLink.addEventListener("click", (e) => {
            e.preventDefault();
            alert("Please contact the administrator to reset your password.");
        });

        // Form submit validation & Remember me
        loginForm.addEventListener("submit", function(e) {
            let isValid = true;
            const u = usernameInput.value.trim();
            const p = passwordInput.value;

            if (!u) {
                usernameContainer.classList.add("error");
                usernameError.innerText = "Please enter your username";
                isValid = false;
            }
            if (!p) {
                passwordContainer.classList.add("error");
                passwordError.innerText = "Please enter your password";
                isValid = false;
            }

            if (!isValid) {
                e.preventDefault();
                return;
            }

            // Save Remember Me
            if (rememberMeCheckbox.checked) {
                localStorage.setItem("airroom_saved_username", u);
            } else {
                localStorage.removeItem("airroom_saved_username");
            }

            // Button loading spinner
            submitBtn.disabled = true;
            btnText.innerText = "Signing in...";
            btnArrow.style.display = "none";
            btnSpinner.style.display = "inline-block";
        });

        // Load saved username if present
        document.addEventListener("DOMContentLoaded", () => {
            const saved = localStorage.getItem("airroom_saved_username");
            if (saved && !usernameInput.value) {
                usernameInput.value = saved;
                rememberMeCheckbox.checked = true;
                passwordInput.focus();
            }
        });
    </script>
</body>
</html>
