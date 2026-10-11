<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    // Prevent caching
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    if (session.getAttribute("userId") != null) {
        response.sendRedirect("dashboard.jsp");
        return;
    }

    String error = request.getParameter("error");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Register - Smart Placement System</title>
    <meta name="description" content="Create your Smart Placement System account to start comprehensive placement test preparations.">
    <link rel="stylesheet" href="css/style.css">
</head>
<body>
    <div class="auth-wrapper">
        <div class="auth-card">
            <div class="auth-header">
                <div class="brand-logo" style="justify-content: center; margin-bottom: 1.25rem;">
                    <div class="brand-icon-box">
                        <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
                            <path d="M22 10v6M2 10l10-5 10 5-10 5z"/>
                            <path d="M6 12v5c3 3 9 3 12 0v-5"/>
                        </svg>
                    </div>
                    <span>Smart<span class="brand-name-highlight">Placement</span></span>
                </div>
                <h1 class="auth-title">Create Account</h1>
                <p class="auth-subtitle">Join thousands of students cracking placements</p>
            </div>

            <% if (error != null) { %>
                <div class="alert alert-error">
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/>
                    </svg>
                    <span>
                        <% if ("exists_user".equals(error)) { %>
                            This username is already taken. Please choose another.
                        <% } else if ("exists_email".equals(error)) { %>
                            This email address is already registered. Please sign in.
                        <% } else if ("missing".equals(error)) { %>
                            All fields are required. Please fill in all details.
                        <% } else if ("short_pwd".equals(error)) { %>
                            Password must be at least 6 characters long.
                        <% } else { %>
                            Registration failed: <%= error %>
                        <% } %>
                    </span>
                </div>
            <% } %>

            <form action="actions/auth-register.jsp" method="POST" autocomplete="off" onsubmit="return validateForm()">
                <div class="form-group">
                    <label class="form-label" for="username">Username</label>
                    <input type="text" id="username" name="username" class="form-input" placeholder="Choose a unique username" minlength="3" maxlength="30" required autofocus>
                </div>

                <div class="form-group">
                    <label class="form-label" for="email">Email Address</label>
                    <input type="email" id="email" name="email" class="form-input" placeholder="student@university.edu" required>
                </div>

                <div class="form-group">
                    <label class="form-label" for="password">Password</label>
                    <div class="password-input-wrapper">
                        <input type="password" id="password" name="password" class="form-input" placeholder="Minimum 6 characters" minlength="6" required>
                        <button type="button" class="password-toggle-btn" onclick="togglePasswordVisibility('password', this)" aria-label="Show password" title="Show password" tabindex="-1">
                            <svg class="eye-closed" width="19" height="19" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                <path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24"></path>
                                <line x1="1" y1="1" x2="23" y2="23"></line>
                            </svg>
                            <svg class="eye-open" width="19" height="19" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="display: none;">
                                <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"></path>
                                <circle cx="12" cy="12" r="3"></circle>
                            </svg>
                        </button>
                    </div>
                </div>

                <button type="submit" class="btn btn-primary" style="width: 100%; margin-top: 1rem;">
                    Complete Registration
                </button>
            </form>

            <div class="auth-footer">
                Already have an account? <a href="login.jsp" style="font-weight: 600;">Sign in here</a>
            </div>
        </div>
    </div>

    <script src="js/main.js"></script>
    <script>
        function validateForm() {
            const pwd = document.getElementById('password').value;
            if (pwd.length < 6) {
                alert("Password must be at least 6 characters long.");
                return false;
            }
            return true;
        }
    </script>
</body>
</html>
