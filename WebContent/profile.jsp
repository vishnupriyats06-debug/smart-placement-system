<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, com.placement.DBUtil, com.placement.StreakUtil" %>
<%
    // Prevent caching on profile page
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    Object userIdObj = session.getAttribute("userId");
    if (userIdObj == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    int userId = (Integer) userIdObj;
    String username = "";
    String email = "";
    String currentAvatar = "avatar11.svg";
    Timestamp joinedAt = null;

    try (Connection conn = DBUtil.getConnection()) {
        String sql = "SELECT username, email, avatar, created_at FROM users WHERE id = ?";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    username = rs.getString("username");
                    email = rs.getString("email");
                    String dbAvatar = rs.getString("avatar");
                    if (dbAvatar != null && !dbAvatar.isEmpty()) {
                        currentAvatar = dbAvatar;
                    }
                    joinedAt = rs.getTimestamp("created_at");
                    // Sync session avatar
                    session.setAttribute("avatar", currentAvatar);
                }
            }
        }
    } catch (SQLException e) {
        e.printStackTrace();
    }

    int avatarNum = 11;
    try {
        avatarNum = Integer.parseInt(currentAvatar.replaceAll("\\D+", ""));
    } catch (Exception ignored) {}
    String avatarPath = (avatarNum <= 10) ? "images/avatars/female/" + currentAvatar : "images/avatars/male/" + currentAvatar;

    StreakUtil.StreakData streak = StreakUtil.getStreak(userId);
    String msg = request.getParameter("msg");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Student Profile - Smart Placement System</title>
    <link rel="stylesheet" href="css/style.css">
</head>
<body>
    <header class="navbar">
        <div class="navbar-container">
            <div class="brand-logo">
                <div class="brand-icon-box">
                    <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                        <path d="M22 10v6M2 10l10-5 10 5-10 5z"/>
                        <path d="M6 12v5c3 3 9 3 12 0v-5"/>
                    </svg>
                </div>
                <span>Smart<span class="brand-name-highlight">Placement</span></span>
            </div>

            <nav>
                <ul class="nav-links">
                    <li><a href="dashboard.jsp" class="nav-link">Dashboard</a></li>
                    <li><a href="progress.jsp" class="nav-link">Progress Tracking</a></li>
                    <li><a href="profile.jsp" class="nav-link active">Profile</a></li>
                </ul>
            </nav>

            <div class="nav-user">
                <div class="streak-pill">
                    <span class="streak-icon">🔥</span>
                    <span><%= streak.currentStreak %> Day Streak</span>
                </div>
                <a href="logout.jsp" class="btn btn-danger btn-sm">Logout</a>
            </div>
        </div>
    </header>

    <main class="container" style="max-width: 1040px;">
        <% if ("saved".equals(msg)) { %>
            <div class="alert alert-success" style="margin-bottom: 2rem;">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/>
                </svg>
                <span>Avatar updated successfully and saved in MySQL database!</span>
            </div>
        <% } %>

        <!-- User Information Card -->
        <section class="glass-panel" style="padding: 2.5rem; margin-bottom: 2.5rem; display: flex; align-items: center; gap: 2.5rem; flex-wrap: wrap;">
            <div style="position: relative;">
                <img src="<%= avatarPath %>" alt="Current Avatar" style="width: 110px; height: 110px; border-radius: 50%; border: 3px solid var(--accent-primary); box-shadow: 0 0 25px rgba(99, 102, 241, 0.4); object-fit: cover;">
                <span style="position: absolute; bottom: 0; right: 0; background: #10b981; border: 2px solid var(--bg-surface); width: 22px; height: 22px; border-radius: 50%;" title="Active"></span>
            </div>

            <div style="flex: 1; min-width: 250px;">
                <div style="display: flex; align-items: center; gap: 1rem; flex-wrap: wrap; margin-bottom: 0.35rem;">
                    <h1 style="font-size: 1.85rem; margin-bottom: 0;"><%= username %></h1>
                    <button type="button" id="toggleAvatarBtn" class="btn btn-secondary btn-sm" onclick="toggleAvatarPicker()" style="display: inline-flex; align-items: center; gap: 0.45rem;">
                        <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                            <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"></path>
                            <circle cx="12" cy="7" r="4"></circle>
                        </svg>
                        <span id="toggleAvatarBtnText">Change Avatar</span>
                    </button>
                </div>
                <p style="color: var(--text-secondary); margin-bottom: 0.85rem;"><%= email %></p>
                <div style="display: flex; gap: 1.5rem; font-size: 0.85rem; color: var(--text-muted); flex-wrap: wrap;">
                    <span>Joined: <strong><%= joinedAt != null ? joinedAt.toString().substring(0, 10) : "2026" %></strong></span>
                    <span>Current Streak: <strong style="color: #fbbf24;">🔥 <%= streak.currentStreak %> Days</strong></span>
                    <span>Longest Streak: <strong style="color: #60a5fa;">🏆 <%= streak.longestStreak %> Days</strong></span>
                </div>
            </div>
        </section>

        <!-- Avatar Selection Grid (Hidden by default, shown when user clicks Change Avatar) -->
        <section id="avatarSection" class="glass-panel" style="padding: 2.5rem; display: none; margin-bottom: 2.5rem; animation: fadeInDown 0.3s ease;">
            <div class="section-heading">
                <div>
                    <h2 class="section-title">
                        <span>🎭</span> Choose Your Avatar
                    </h2>
                    <p style="color: var(--text-secondary); font-size: 0.95rem; margin-top: 0.35rem;">
                        Select from 20 predefined avatars (10 male & 10 female). Your chosen avatar updates immediately across your dashboard.
                    </p>
                </div>
            </div>

            <form id="avatarForm" action="actions/update-avatar.jsp" method="POST">
                <input type="hidden" id="selectedAvatarInput" name="avatar" value="<%= currentAvatar %>">

                <!-- Female Avatars Group (1-10) -->
                <h3 style="font-size: 1.15rem; color: #f472b6; margin: 1.5rem 0 0.75rem; display: flex; align-items: center; gap: 0.5rem;">
                    👩 Female Avatars (1 to 10)
                </h3>
                <div class="avatar-selection-grid">
                    <% for (int i = 1; i <= 10; i++) {
                        String fName = String.format("avatar%02d.svg", i);
                        boolean isSelected = fName.equals(currentAvatar);
                    %>
                        <div class="avatar-item <%= isSelected ? "selected" : "" %>" id="card_<%= fName %>" onclick="chooseAvatar('<%= fName %>')">
                            <img src="images/avatars/female/<%= fName %>" alt="Female Avatar <%= i %>">
                            <span>Avatar <%= i %></span>
                        </div>
                    <% } %>
                </div>

                <!-- Male Avatars Group (11-20) -->
                <h3 style="font-size: 1.15rem; color: #60a5fa; margin: 2rem 0 0.75rem; display: flex; align-items: center; gap: 0.5rem;">
                    👨 Male Avatars (11 to 20)
                </h3>
                <div class="avatar-selection-grid">
                    <% for (int i = 11; i <= 20; i++) {
                        String mName = String.format("avatar%02d.svg", i);
                        boolean isSelected = mName.equals(currentAvatar);
                    %>
                        <div class="avatar-item <%= isSelected ? "selected" : "" %>" id="card_<%= mName %>" onclick="chooseAvatar('<%= mName %>')">
                            <img src="images/avatars/male/<%= mName %>" alt="Male Avatar <%= i - 10 %>">
                            <span>Avatar <%= i %></span>
                        </div>
                    <% } %>
                </div>

                <div style="margin-top: 2rem; display: flex; justify-content: flex-end; gap: 1rem;">
                    <button type="button" class="btn btn-secondary" onclick="toggleAvatarPicker()">Cancel</button>
                    <button type="submit" class="btn btn-primary">
                        Save Selected Avatar
                    </button>
                </div>
            </form>
        </section>
    </main>

    <footer class="footer">
        <p>Smart Placement System &copy; 2026. Student Profiles.</p>
    </footer>

    <script src="js/main.js"></script>
    <script>
        function toggleAvatarPicker() {
            const section = document.getElementById('avatarSection');
            const btnText = document.getElementById('toggleAvatarBtnText');
            if (!section) return;

            const isHidden = window.getComputedStyle(section).display === 'none';
            if (isHidden) {
                section.style.display = 'block';
                if (btnText) btnText.textContent = 'Hide Avatar Options';
                section.scrollIntoView({ behavior: 'smooth', block: 'start' });
            } else {
                section.style.display = 'none';
                if (btnText) btnText.textContent = 'Change Avatar';
            }
        }

        function chooseAvatar(avatarFilename) {
            document.getElementById('selectedAvatarInput').value = avatarFilename;

            // Remove selected class from all items
            const items = document.querySelectorAll('.avatar-item');
            items.forEach(el => el.classList.remove('selected'));

            // Add selected class to chosen item
            const chosen = document.getElementById('card_' + avatarFilename);
            if (chosen) {
                chosen.classList.add('selected');
            }
        }
    </script>
</body>
</html>
