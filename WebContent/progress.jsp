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
    if (avatar == null || avatar.isEmpty()) avatar = "avatar11.svg";

    int avatarNum = 11;
    try {
        avatarNum = Integer.parseInt(avatar.replaceAll("\\D+", ""));
    } catch (Exception ignored) {}
    String avatarPath = (avatarNum <= 10) ? "images/avatars/female/" + avatar : "images/avatars/male/" + avatar;

    int totalQuizzes = 0;
    int totalAttempted = 0;
    int totalCorrect = 0;
    int totalIncorrect = 0;
    int totalTimeSeconds = 0;
    double overallAccuracy = 0.0;
    double avgResponseTime = 0.0;

    // Section metrics: [attempted, correct, totalQuizzes, totalTime]
    Map<String, int[]> secData = new HashMap<>();
    secData.put("quantitative", new int[]{0, 0, 0, 0});
    secData.put("logical", new int[]{0, 0, 0, 0});
    secData.put("verbal", new int[]{0, 0, 0, 0});

    List<Map<String, Object>> allAttempts = new ArrayList<>();

    try (Connection conn = DBUtil.getConnection()) {
        String sql = "SELECT id, section, attempted_count, correct_count, incorrect_count, score, accuracy, " +
                     "       total_time_seconds, avg_response_time, submitted_at " +
                     "FROM quiz_attempts WHERE user_id = ? AND is_submitted = 1 ORDER BY submitted_at DESC";

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    totalQuizzes++;
                    String sec = rs.getString("section").toLowerCase();
                    int att = rs.getInt("attempted_count");
                    int cor = rs.getInt("correct_count");
                    int incor = rs.getInt("incorrect_count");
                    int timeSec = rs.getInt("total_time_seconds");

                    totalAttempted += att;
                    totalCorrect += cor;
                    totalIncorrect += incor;
                    totalTimeSeconds += timeSec;

                    if (secData.containsKey(sec)) {
                        int[] arr = secData.get(sec);
                        arr[0] += att;
                        arr[1] += cor;
                        arr[2] += 1;
                        arr[3] += timeSec;
                    }

                    Map<String, Object> row = new HashMap<>();
                    row.put("id", rs.getInt("id"));
                    row.put("section", sec);
                    row.put("score", rs.getInt("score"));
                    row.put("accuracy", rs.getDouble("accuracy"));
                    row.put("time", timeSec);
                    row.put("avgTime", rs.getDouble("avg_response_time"));
                    row.put("date", rs.getTimestamp("submitted_at"));
                    allAttempts.add(row);
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

    StreakUtil.StreakData streak = StreakUtil.getStreak(userId);

    // Calculate Trend (compare last attempt accuracy vs previous attempts)
    String trendText = "Consistent";
    String trendClass = "tag-quant";
    if (allAttempts.size() >= 2) {
        double latestAcc = (Double) allAttempts.get(0).get("accuracy");
        double prevAcc = (Double) allAttempts.get(1).get("accuracy");
        if (latestAcc > prevAcc) {
            trendText = "Improving (+" + String.format("%.1f", (latestAcc - prevAcc)) + "%) 📈";
            trendClass = "tag-quant";
        } else if (latestAcc < prevAcc) {
            trendText = "Declined (" + String.format("%.1f", (latestAcc - prevAcc)) + "%) 📉";
            trendClass = "tag-verbal";
        }
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Progress Tracking - Smart Placement System</title>
    <link rel="stylesheet" href="css/style.css">
    <link rel="stylesheet" href="css/quiz.css">
    <style>
        .progress-bar-bg {
            width: 100%;
            height: 10px;
            background: rgba(255, 255, 255, 0.08);
            border-radius: var(--radius-full);
            overflow: hidden;
            margin-top: 0.6rem;
        }
        .progress-fill-bar {
            height: 100%;
            border-radius: var(--radius-full);
            transition: width 1s cubic-bezier(0.16, 1, 0.3, 1);
        }
    </style>
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
                    <li><a href="progress.jsp" class="nav-link active">Progress Tracking</a></li>
                    <li><a href="profile.jsp" class="nav-link">Profile</a></li>
                </ul>
            </nav>

            <div class="nav-user">
                <div class="streak-pill">
                    <span class="streak-icon">🔥</span>
                    <span><%= streak.currentStreak %> Day Streak</span>
                </div>
                <a href="profile.jsp" class="nav-avatar-box">
                    <img src="<%= avatarPath %>" alt="Avatar" class="nav-avatar-img">
                </a>
                <a href="logout.jsp" class="btn btn-danger btn-sm">Logout</a>
            </div>
        </div>
    </header>

    <main class="container">
        <!-- Overview Header -->
        <div style="margin-bottom: 2.5rem; display: flex; justify-content: space-between; align-items: flex-end; flex-wrap: wrap; gap: 1rem;">
            <div>
                <h1 style="font-size: 2.2rem; margin-bottom: 0.4rem;">Performance & Analytics</h1>
                <p style="color: var(--text-secondary);">
                    Comprehensive assessment insights calculated strictly from verified database attempts.
                </p>
            </div>
            <div>
                <span class="tag <%= trendClass %>" style="font-size: 0.95rem; padding: 0.45rem 1rem;">
                    Recent Trend: <%= trendText %>
                </span>
            </div>
        </div>

        <!-- Metric Cards -->
        <section class="stats-grid">
            <div class="stat-card">
                <div class="stat-icon" style="background: rgba(99, 102, 241, 0.15); color: #818cf8;">
                    📑
                </div>
                <div class="stat-info">
                    <div class="stat-value"><%= totalQuizzes %></div>
                    <div class="stat-label">Total Quizzes Completed</div>
                </div>
            </div>

            <div class="stat-card">
                <div class="stat-icon" style="background: rgba(16, 185, 129, 0.15); color: #34d399;">
                    ✓
                </div>
                <div class="stat-info">
                    <div class="stat-value" style="color: #34d399;"><%= totalCorrect %></div>
                    <div class="stat-label">Total Correct Answers</div>
                </div>
            </div>

            <div class="stat-card">
                <div class="stat-icon" style="background: rgba(239, 68, 68, 0.15); color: #f87171;">
                    ✗
                </div>
                <div class="stat-info">
                    <div class="stat-value" style="color: #f87171;"><%= totalIncorrect %></div>
                    <div class="stat-label">Total Incorrect Answers</div>
                </div>
            </div>

            <div class="stat-card">
                <div class="stat-icon" style="background: rgba(6, 182, 212, 0.15); color: #22d3ee;">
                    🎯
                </div>
                <div class="stat-info">
                    <div class="stat-value"><%= String.format("%.1f", overallAccuracy) %>%</div>
                    <div class="stat-label">Cumulative Accuracy</div>
                </div>
            </div>
        </section>

        <!-- Section-Wise Mastery Breakdown -->
        <section style="margin-bottom: 3.5rem;">
            <div class="section-heading">
                <h2 class="section-title">
                    <span>📊</span> Section-Wise Domain Mastery
                </h2>
            </div>

            <div class="practice-grid">
                <!-- Quantitative Aptitude -->
                <%
                    int[] qArr = secData.get("quantitative");
                    double qAcc = qArr[0] > 0 ? ((double) qArr[1] / qArr[0]) * 100.0 : 0.0;
                    double qAvgTime = qArr[0] > 0 ? (double) qArr[3] / qArr[0] : 0.0;
                %>
                <div class="glass-panel" style="padding: 2rem;">
                    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 1rem;">
                        <h3 style="font-size: 1.3rem;">Quantitative Aptitude</h3>
                        <span class="tag tag-quantitative"><%= qArr[2] %> Quizzes</span>
                    </div>

                    <div style="margin-bottom: 1.25rem;">
                        <div style="display: flex; justify-content: space-between; font-size: 0.9rem; color: var(--text-secondary);">
                            <span>Accuracy Rate</span>
                            <strong><%= String.format("%.1f", qAcc) %>%</strong>
                        </div>
                        <div class="progress-bar-bg">
                            <div class="progress-fill-bar" data-width="<%= String.format("%.1f", qAcc) %>%;" style="width: <%= String.format("%.1f", qAcc) %>%; background: linear-gradient(90deg, #6366f1, #818cf8);"></div>
                        </div>
                    </div>

                    <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 0.75rem; font-size: 0.85rem; color: var(--text-secondary); padding-top: 1rem; border-top: 1px solid var(--border-color);">
                        <div>Attempted: <strong style="color: #fff;"><%= qArr[0] %></strong></div>
                        <div>Correct: <strong style="color: #10b981;"><%= qArr[1] %></strong></div>
                        <div>Avg Speed: <strong style="color: #fff;"><%= String.format("%.1f", qAvgTime) %>s</strong></div>
                        <div>Status: <strong style="color: <%= qAcc >= 70 ? "#10b981" : "#f59e0b" %>;"><%= qAcc >= 70 ? "Proficient" : "Practicing" %></strong></div>
                    </div>
                </div>

                <!-- Logical Reasoning -->
                <%
                    int[] lArr = secData.get("logical");
                    double lAcc = lArr[0] > 0 ? ((double) lArr[1] / lArr[0]) * 100.0 : 0.0;
                    double lAvgTime = lArr[0] > 0 ? (double) lArr[3] / lArr[0] : 0.0;
                %>
                <div class="glass-panel" style="padding: 2rem;">
                    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 1rem;">
                        <h3 style="font-size: 1.3rem;">Logical Reasoning</h3>
                        <span class="tag tag-logical"><%= lArr[2] %> Quizzes</span>
                    </div>

                    <div style="margin-bottom: 1.25rem;">
                        <div style="display: flex; justify-content: space-between; font-size: 0.9rem; color: var(--text-secondary);">
                            <span>Accuracy Rate</span>
                            <strong><%= String.format("%.1f", lAcc) %>%</strong>
                        </div>
                        <div class="progress-bar-bg">
                            <div class="progress-fill-bar" data-width="<%= String.format("%.1f", lAcc) %>%;" style="width: <%= String.format("%.1f", lAcc) %>%; background: linear-gradient(90deg, #06b6d4, #38bdf8);"></div>
                        </div>
                    </div>

                    <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 0.75rem; font-size: 0.85rem; color: var(--text-secondary); padding-top: 1rem; border-top: 1px solid var(--border-color);">
                        <div>Attempted: <strong style="color: #fff;"><%= lArr[0] %></strong></div>
                        <div>Correct: <strong style="color: #10b981;"><%= lArr[1] %></strong></div>
                        <div>Avg Speed: <strong style="color: #fff;"><%= String.format("%.1f", lAvgTime) %>s</strong></div>
                        <div>Status: <strong style="color: <%= lAcc >= 70 ? "#10b981" : "#f59e0b" %>;"><%= lAcc >= 70 ? "Proficient" : "Practicing" %></strong></div>
                    </div>
                </div>

                <!-- Verbal Ability -->
                <%
                    int[] vArr = secData.get("verbal");
                    double vAcc = vArr[0] > 0 ? ((double) vArr[1] / vArr[0]) * 100.0 : 0.0;
                    double vAvgTime = vArr[0] > 0 ? (double) vArr[3] / vArr[0] : 0.0;
                %>
                <div class="glass-panel" style="padding: 2rem;">
                    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 1rem;">
                        <h3 style="font-size: 1.3rem;">Verbal Ability</h3>
                        <span class="tag tag-verbal"><%= vArr[2] %> Quizzes</span>
                    </div>

                    <div style="margin-bottom: 1.25rem;">
                        <div style="display: flex; justify-content: space-between; font-size: 0.9rem; color: var(--text-secondary);">
                            <span>Accuracy Rate</span>
                            <strong><%= String.format("%.1f", vAcc) %>%</strong>
                        </div>
                        <div class="progress-bar-bg">
                            <div class="progress-fill-bar" data-width="<%= String.format("%.1f", vAcc) %>%;" style="width: <%= String.format("%.1f", vAcc) %>%; background: linear-gradient(90deg, #ec4899, #f472b6);"></div>
                        </div>
                    </div>

                    <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 0.75rem; font-size: 0.85rem; color: var(--text-secondary); padding-top: 1rem; border-top: 1px solid var(--border-color);">
                        <div>Attempted: <strong style="color: #fff;"><%= vArr[0] %></strong></div>
                        <div>Correct: <strong style="color: #10b981;"><%= vArr[1] %></strong></div>
                        <div>Avg Speed: <strong style="color: #fff;"><%= String.format("%.1f", vAvgTime) %>s</strong></div>
                        <div>Status: <strong style="color: <%= vAcc >= 70 ? "#10b981" : "#f59e0b" %>;"><%= vAcc >= 70 ? "Proficient" : "Practicing" %></strong></div>
                    </div>
                </div>
            </div>
        </section>

        <!-- Complete Assessment History Table -->
        <section>
            <div class="section-heading">
                <h2 class="section-title">
                    <span>📜</span> Complete Assessment Log
                </h2>
                <span style="color: var(--text-secondary); font-size: 0.9rem;">
                    All <%= allAttempts.size() %> attempts recorded
                </span>
            </div>

            <div class="table-responsive">
                <table class="data-table">
                    <thead>
                        <tr>
                            <th>Attempt ID</th>
                            <th>Timestamp</th>
                            <th>Section</th>
                            <th>Score (15)</th>
                            <th>Accuracy</th>
                            <th>Duration</th>
                            <th>Avg / Question</th>
                            <th>Review</th>
                        </tr>
                    </thead>
                    <tbody>
                        <% if (allAttempts.isEmpty()) { %>
                            <tr>
                                <td colspan="8" style="text-align: center; padding: 2.5rem; color: var(--text-muted);">
                                    No completed quiz attempts found. Start a practice test from the dashboard!
                                </td>
                            </tr>
                        <% } else {
                            for (Map<String, Object> a : allAttempts) {
                                int attId = (Integer) a.get("id");
                                String sName = (String) a.get("section");
                                int score = (Integer) a.get("score");
                                double acc = (Double) a.get("accuracy");
                                int timeS = (Integer) a.get("time");
                                double avgQ = (Double) a.get("avgTime");
                                Timestamp date = (Timestamp) a.get("date");
                                int m = timeS / 60;
                                int s = timeS % 60;
                        %>
                            <tr>
                                <td>#<%= attId %></td>
                                <td><%= date != null ? date.toString().substring(0, 16) : "N/A" %></td>
                                <td><span class="tag tag-<%= sName %>"><%= sName %></span></td>
                                <td><strong><%= score %> / 15</strong></td>
                                <td>
                                    <span style="color: <%= acc >= 70 ? "#10b981" : (acc >= 40 ? "#f59e0b" : "#ef4444") %>; font-weight: 600;">
                                        <%= String.format("%.1f", acc) %>%
                                    </span>
                                </td>
                                <td><%= m %>m <%= s %>s</td>
                                <td><%= String.format("%.1f", avgQ) %>s</td>
                                <td>
                                    <a href="quiz-result.jsp?attempt_id=<%= attId %>" class="btn btn-secondary btn-sm">
                                        View Solutions
                                    </a>
                                </td>
                            </tr>
                        <%  }
                        } %>
                    </tbody>
                </table>
            </div>
        </section>
    </main>

    <footer class="footer">
        <p>Smart Placement System &copy; 2026. Real-Time Performance Analytics & Streaks Engine.</p>
    </footer>

    <script src="js/main.js"></script>
    <script src="js/progress.js"></script>
</body>
</html>
