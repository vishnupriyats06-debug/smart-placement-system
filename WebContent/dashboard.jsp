<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, java.util.*, com.placement.DBUtil, com.placement.StreakUtil" %>
<%
    // Prevent caching on authenticated pages
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    Object userIdObj = session.getAttribute("userId");
    if (userIdObj == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    int userId = (Integer) userIdObj;
    String username = (String) session.getAttribute("username");
    String avatar = (String) session.getAttribute("avatar");
    if (avatar == null || avatar.isEmpty()) {
        avatar = "avatar11.svg";
    }

    // Determine avatar subfolder (avatar01..10 female, 11..20 male)
    int avatarNum = 11;
    try {
        avatarNum = Integer.parseInt(avatar.replaceAll("\\D+", ""));
    } catch (Exception ignored) {}
    String avatarPath = (avatarNum <= 10) ? "images/avatars/female/" + avatar : "images/avatars/male/" + avatar;

    // Fetch live user statistics from MySQL
    int totalQuizzes = 0;
    int totalAttempted = 0;
    int totalCorrect = 0;
    int totalIncorrect = 0;
    int totalTimeSeconds = 0;
    double overallAccuracy = 0.0;
    double avgResponseTime = 0.0;

    // Section specific metrics: [totalAttempted, totalCorrect]
    Map<String, int[]> sectionStats = new HashMap<>();
    sectionStats.put("quantitative", new int[]{0, 0});
    sectionStats.put("logical", new int[]{0, 0});
    sectionStats.put("verbal", new int[]{0, 0});

    // Recent activity list
    List<Map<String, Object>> recentQuizzes = new ArrayList<>();

    // Streaks
    StreakUtil.StreakData streak = StreakUtil.getStreak(userId);

    try (Connection conn = DBUtil.getConnection()) {
        // Query completed quiz attempts
        String statsSql = "SELECT section, attempted_count, correct_count, incorrect_count, total_time_seconds, score, accuracy, submitted_at " +
                          "FROM quiz_attempts WHERE user_id = ? AND is_submitted = 1 ORDER BY submitted_at DESC";
        try (PreparedStatement ps = conn.prepareStatement(statsSql)) {
            ps.setInt(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    totalQuizzes++;
                    String sec = rs.getString("section").toLowerCase();
                    int att = rs.getInt("attempted_count");
                    int cor = rs.getInt("correct_count");
                    int incor = rs.getInt("incorrect_count");
                    int tSec = rs.getInt("total_time_seconds");

                    totalAttempted += att;
                    totalCorrect += cor;
                    totalIncorrect += incor;
                    totalTimeSeconds += tSec;

                    if (sectionStats.containsKey(sec)) {
                        int[] cur = sectionStats.get(sec);
                        cur[0] += att;
                        cur[1] += cor;
                    }

                    if (recentQuizzes.size() < 5) {
                        Map<String, Object> item = new HashMap<>();
                        item.put("section", sec);
                        item.put("score", rs.getInt("score"));
                        item.put("accuracy", rs.getDouble("accuracy"));
                        item.put("time", tSec);
                        item.put("date", rs.getTimestamp("submitted_at"));
                        recentQuizzes.add(item);
                    }
                }
            }
        }

        if (totalAttempted > 0) {
            overallAccuracy = ((double) totalCorrect / totalAttempted) * 100.0;
            avgResponseTime = (double) totalTimeSeconds / totalAttempted;
        }

    } catch (SQLException e) {
        e.printStackTrace();
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Student Dashboard - Smart Placement System</title>
    <meta name="description" content="Track your placement preparation, practice Quantitative, Logical, and Verbal aptitude tests.">
    <link rel="stylesheet" href="css/style.css">
</head>
<body>
    <!-- Navbar -->
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
                    <li><a href="dashboard.jsp" class="nav-link active">Dashboard</a></li>
                    <li><a href="progress.jsp" class="nav-link">Progress Tracking</a></li>
                    <li><a href="profile.jsp" class="nav-link">Profile</a></li>
                </ul>
            </nav>

            <div class="nav-user">
                <div class="streak-pill" title="Current Daily Practice Streak">
                    <span class="streak-icon">🔥</span>
                    <span><%= streak.currentStreak %> Day Streak</span>
                </div>

                <a href="profile.jsp" class="nav-avatar-box" title="View Profile">
                    <img src="<%= avatarPath %>" alt="User Avatar" class="nav-avatar-img">
                </a>

                <a href="logout.jsp" class="btn btn-danger btn-sm" title="Log Out Safely">
                    Logout
                </a>
            </div>
        </div>
    </header>

    <!-- Main Content -->
    <main class="container">
        <!-- Hero Banner -->
        <section class="dashboard-hero">
            <div class="dashboard-greeting">
                <h1>Hello, <%= username %>! 👋</h1>
                <p>Welcome to your personal placement preparation headquarters. Sharpen your skills and aim for 100% placement readiness.</p>
            </div>
            <div>
                <a href="#practice-sections" class="btn btn-primary btn-lg">
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <polygon points="5 3 19 12 5 21 5 3"/>
                    </svg>
                    Start Daily Practice
                </a>
            </div>
        </section>

        <!-- Stats Overview Grid -->
        <section class="stats-grid">
            <div class="stat-card">
                <div class="stat-icon" style="background: rgba(99, 102, 241, 0.15); color: #818cf8;">
                    📝
                </div>
                <div class="stat-info">
                    <div class="stat-value"><%= totalAttempted %></div>
                    <div class="stat-label">Questions Attempted</div>
                </div>
            </div>

            <div class="stat-card">
                <div class="stat-icon" style="background: rgba(16, 185, 129, 0.15); color: #34d399;">
                    🎯
                </div>
                <div class="stat-info">
                    <div class="stat-value"><%= String.format("%.1f", overallAccuracy) %>%</div>
                    <div class="stat-label">Overall Accuracy</div>
                </div>
            </div>

            <div class="stat-card">
                <div class="stat-icon" style="background: rgba(6, 182, 212, 0.15); color: #22d3ee;">
                    ⚡
                </div>
                <div class="stat-info">
                    <div class="stat-value"><%= String.format("%.1f", avgResponseTime) %>s</div>
                    <div class="stat-label">Avg. Response Time</div>
                </div>
            </div>

            <div class="stat-card">
                <div class="stat-icon" style="background: rgba(245, 158, 11, 0.15); color: #fbbf24;">
                    🏆
                </div>
                <div class="stat-info">
                    <div class="stat-value"><%= streak.longestStreak %> Days</div>
                    <div class="stat-label">Longest Streak</div>
                </div>
            </div>
        </section>

        <!-- Practice Sections -->
        <section id="practice-sections" style="margin-bottom: 3.5rem;">
            <div class="section-heading">
                <h2 class="section-title">
                    <span>📚</span> Practice Question Banks
                </h2>
                <span style="color: var(--text-secondary); font-size: 0.95rem;">15 randomized questions per attempt from 100+ MCQ bank</span>
            </div>

            <div class="practice-grid">
                <!-- Quantitative Aptitude -->
                <div class="practice-card">
                    <span class="practice-card-badge">100+ Questions</span>
                    <div class="practice-card-icon" style="background: rgba(99, 102, 241, 0.15); color: #818cf8;">
                        📐
                    </div>
                    <h3>Quantitative Aptitude</h3>
                    <p>Master Percentages, Profit & Loss, Ratios, Time & Work, Speed-Distance, Interest, Permutations, Probability & Number Systems.</p>

                    <div class="practice-meta">
                        <%
                            int[] qStat = sectionStats.get("quantitative");
                            double qAcc = qStat[0] > 0 ? ((double) qStat[1] / qStat[0]) * 100.0 : 0.0;
                        %>
                        <span>Attempted: <strong><%= qStat[0] %></strong></span>
                        <span>Accuracy: <strong><%= String.format("%.0f", qAcc) %>%</strong></span>
                    </div>

                    <a href="actions/quiz-start.jsp?section=quantitative" class="btn btn-primary" style="width: 100%;">
                        Start 15-Question Quiz &rarr;
                    </a>
                </div>

                <!-- Logical Reasoning -->
                <div class="practice-card">
                    <span class="practice-card-badge">100+ Questions</span>
                    <div class="practice-card-icon" style="background: rgba(6, 182, 212, 0.15); color: #22d3ee;">
                        🧩
                    </div>
                    <h3>Logical Reasoning</h3>
                    <p>Sharpen series patterns, coding-decoding, blood relations, direction sense, syllogisms, seating arrangements, and classification.</p>

                    <div class="practice-meta">
                        <%
                            int[] lStat = sectionStats.get("logical");
                            double lAcc = lStat[0] > 0 ? ((double) lStat[1] / lStat[0]) * 100.0 : 0.0;
                        %>
                        <span>Attempted: <strong><%= lStat[0] %></strong></span>
                        <span>Accuracy: <strong><%= String.format("%.0f", lAcc) %>%</strong></span>
                    </div>

                    <a href="actions/quiz-start.jsp?section=logical" class="btn btn-primary" style="width: 100%;">
                        Start 15-Question Quiz &rarr;
                    </a>
                </div>

                <!-- Verbal Ability -->
                <div class="practice-card">
                    <span class="practice-card-badge">100+ Questions</span>
                    <div class="practice-card-icon" style="background: rgba(236, 72, 153, 0.15); color: #f472b6;">
                        📖
                    </div>
                    <h3>Verbal Ability</h3>
                    <p>Excel in Synonyms & Antonyms, Grammar, Sentence Correction, Fill in Blanks, Comprehension, Para Jumbles & Idioms.</p>

                    <div class="practice-meta">
                        <%
                            int[] vStat = sectionStats.get("verbal");
                            double vAcc = vStat[0] > 0 ? ((double) vStat[1] / vStat[0]) * 100.0 : 0.0;
                        %>
                        <span>Attempted: <strong><%= vStat[0] %></strong></span>
                        <span>Accuracy: <strong><%= String.format("%.0f", vAcc) %>%</strong></span>
                    </div>

                    <a href="actions/quiz-start.jsp?section=verbal" class="btn btn-primary" style="width: 100%;">
                        Start 15-Question Quiz &rarr;
                    </a>
                </div>
            </div>
        </section>

        <!-- Previous Practice Activity -->
        <section style="margin-bottom: 2.5rem;">
            <div class="section-heading">
                <h2 class="section-title">
                    <span>⏱️</span> Recent Practice History
                </h2>
                <a href="progress.jsp" class="btn btn-secondary btn-sm">View Full Progress &rarr;</a>
            </div>

            <div class="table-responsive">
                <table class="data-table">
                    <thead>
                        <tr>
                            <th>Date & Time</th>
                            <th>Section</th>
                            <th>Score (Out of 15)</th>
                            <th>Accuracy</th>
                            <th>Time Spent</th>
                            <th>Action</th>
                        </tr>
                    </thead>
                    <tbody>
                        <% if (recentQuizzes.isEmpty()) { %>
                            <tr>
                                <td colspan="6" style="text-align: center; padding: 2.5rem; color: var(--text-muted);">
                                    No completed quizzes yet. Choose a section above to begin your first practice session!
                                </td>
                            </tr>
                        <% } else {
                            for (Map<String, Object> q : recentQuizzes) {
                                String sName = (String) q.get("section");
                                int score = (Integer) q.get("score");
                                double acc = (Double) q.get("accuracy");
                                int timeS = (Integer) q.get("time");
                                Timestamp date = (Timestamp) q.get("date");
                                int mins = timeS / 60;
                                int secs = timeS % 60;
                        %>
                            <tr>
                                <td><%= date != null ? date.toString().substring(0, 16) : "N/A" %></td>
                                <td>
                                    <span class="tag tag-<%= sName %>"><%= sName %></span>
                                </td>
                                <td><strong><%= score %> / 15</strong></td>
                                <td>
                                    <span style="color: <%= acc >= 70 ? "#10b981" : (acc >= 40 ? "#f59e0b" : "#ef4444") %>; font-weight: 600;">
                                        <%= String.format("%.1f", acc) %>%
                                    </span>
                                </td>
                                <td><%= mins %>m <%= secs %>s</td>
                                <td>
                                    <a href="actions/quiz-start.jsp?section=<%= sName %>" class="btn btn-secondary btn-sm">Retake</a>
                                </td>
                            </tr>
                        <%  }
                        } %>
                    </tbody>
                </table>
            </div>
        </section>
    </main>

    <!-- Footer -->
    <footer class="footer">
        <p>Smart Placement System &copy; 2026. Empowering Engineering & Management Graduates for Top Recruiters.</p>
    </footer>

    <script src="js/main.js"></script>
</body>
</html>
