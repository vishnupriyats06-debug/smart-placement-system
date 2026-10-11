<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, java.util.*, com.placement.DBUtil, com.placement.StreakUtil" %>
<%
    // Prevent caching on results page
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    Object userIdObj = session.getAttribute("userId");
    if (userIdObj == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    int userId = (Integer) userIdObj;
    String attemptIdParam = request.getParameter("attempt_id");
    if (attemptIdParam == null || attemptIdParam.trim().isEmpty()) {
        response.sendRedirect("dashboard.jsp");
        return;
    }

    int attemptId = Integer.parseInt(attemptIdParam.trim());

    String section = "";
    int score = 0;
    int attempted = 0;
    int correct = 0;
    int incorrect = 0;
    double accuracy = 0.0;
    int totalTime = 0;
    double avgTime = 0.0;
    Timestamp submittedAt = null;

    List<Map<String, Object>> reviewList = new ArrayList<>();

    try (Connection conn = DBUtil.getConnection()) {
        // 1. Fetch attempt summary
        String getAttemptSql = "SELECT section, score, attempted_count, correct_count, incorrect_count, " +
                               "       accuracy, total_time_seconds, avg_response_time, submitted_at " +
                               "FROM quiz_attempts WHERE id = ? AND user_id = ?";
        try (PreparedStatement ps = conn.prepareStatement(getAttemptSql)) {
            ps.setInt(1, attemptId);
            ps.setInt(2, userId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    section = rs.getString("section");
                    score = rs.getInt("score");
                    attempted = rs.getInt("attempted_count");
                    correct = rs.getInt("correct_count");
                    incorrect = rs.getInt("incorrect_count");
                    accuracy = rs.getDouble("accuracy");
                    totalTime = rs.getInt("total_time_seconds");
                    avgTime = rs.getDouble("avg_response_time");
                    submittedAt = rs.getTimestamp("submitted_at");
                } else {
                    response.sendRedirect("dashboard.jsp");
                    return;
                }
            }
        }

        // 2. Fetch question-by-question review data
        String getReviewSql = "SELECT q.question_text, q.topic, q.difficulty, " +
                              "       q.option_a, q.option_b, q.option_c, q.option_d, q.correct_option, " +
                              "       qr.selected_option, qr.is_correct, qr.response_time_seconds, qr.question_order " +
                              "FROM quiz_responses qr " +
                              "JOIN questions q ON qr.question_id = q.id " +
                              "WHERE qr.attempt_id = ? " +
                              "ORDER BY qr.question_order ASC";

        try (PreparedStatement ps = conn.prepareStatement(getReviewSql)) {
            ps.setInt(1, attemptId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> r = new HashMap<>();
                    r.put("order", rs.getInt("question_order"));
                    r.put("question", rs.getString("question_text"));
                    r.put("topic", rs.getString("topic"));
                    r.put("difficulty", rs.getString("difficulty"));
                    r.put("optionA", rs.getString("option_a"));
                    r.put("optionB", rs.getString("option_b"));
                    r.put("optionC", rs.getString("option_c"));
                    r.put("optionD", rs.getString("option_d"));
                    r.put("correctOption", rs.getString("correct_option"));
                    r.put("selectedOption", rs.getString("selected_option"));
                    r.put("isCorrect", rs.getBoolean("is_correct"));
                    r.put("time", rs.getInt("response_time_seconds"));
                    reviewList.add(r);
                }
            }
        }
    } catch (SQLException e) {
        e.printStackTrace();
    }

    int unattempted = 15 - attempted;
    int mins = totalTime / 60;
    int secs = totalTime % 60;
    StreakUtil.StreakData streak = StreakUtil.getStreak(userId);
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Assessment Results - Smart Placement System</title>
    <link rel="stylesheet" href="css/style.css">
    <link rel="stylesheet" href="css/quiz.css">
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
                    <li><a href="dashboard.jsp" class="nav-link">Dashboard</a></li>
                    <li><a href="progress.jsp" class="nav-link">Progress Tracking</a></li>
                    <li><a href="profile.jsp" class="nav-link">Profile</a></li>
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

    <main class="container">
        <!-- Hero Score Banner -->
        <section class="result-hero">
            <div style="margin-bottom: 1rem;">
                <span class="tag tag-<%= section %>" style="font-size: 0.95rem; padding: 0.35rem 1rem;">
                    <%= Character.toUpperCase(section.charAt(0)) + section.substring(1) %> Aptitude
                </span>
            </div>

            <div class="score-badge-circle">
                <div class="score-num"><%= score %></div>
                <div class="score-total">out of 15</div>
            </div>

            <h1 style="font-size: 2rem; margin-bottom: 0.5rem;">
                <% if (score >= 12) { %>
                    Outstanding Performance! 🌟
                <% } else if (score >= 8) { %>
                    Great Effort! Keep Practicing! 💪
                <% } else { %>
                    Good Attempt! Room for Improvement! 🚀
                <% } %>
            </h1>
            <p style="color: var(--text-secondary); max-width: 600px; margin: 0 auto 2rem;">
                Completed on <%= submittedAt != null ? submittedAt.toString().substring(0, 16) : "Just now" %>. 
                Your daily streak has been refreshed!
            </p>

            <div style="display: flex; gap: 1rem; justify-content: center; flex-wrap: wrap;">
                <a href="dashboard.jsp" class="btn btn-primary">
                    Return to Dashboard
                </a>
                <a href="actions/quiz-start.jsp?section=<%= section %>" class="btn btn-secondary">
                    Retake <%= Character.toUpperCase(section.charAt(0)) + section.substring(1) %> Quiz
                </a>
                <a href="progress.jsp" class="btn btn-secondary">
                    View Progress Analytics &rarr;
                </a>
            </div>
        </section>

        <!-- Stats Grid for this Attempt -->
        <section class="stats-grid" style="margin-bottom: 3rem;">
            <div class="stat-card">
                <div class="stat-icon" style="background: rgba(16, 185, 129, 0.15); color: #10b981;">
                    ✓
                </div>
                <div class="stat-info">
                    <div class="stat-value" style="color: #10b981;"><%= correct %></div>
                    <div class="stat-label">Correct Answers</div>
                </div>
            </div>

            <div class="stat-card">
                <div class="stat-icon" style="background: rgba(239, 68, 68, 0.15); color: #ef4444;">
                    ✗
                </div>
                <div class="stat-info">
                    <div class="stat-value" style="color: #ef4444;"><%= incorrect %></div>
                    <div class="stat-label">Incorrect Answers</div>
                </div>
            </div>

            <div class="stat-card">
                <div class="stat-icon" style="background: rgba(245, 158, 11, 0.15); color: #f59e0b;">
                    ⏸
                </div>
                <div class="stat-info">
                    <div class="stat-value" style="color: #f59e0b;"><%= unattempted %></div>
                    <div class="stat-label">Skipped / Unattempted</div>
                </div>
            </div>

            <div class="stat-card">
                <div class="stat-icon" style="background: rgba(6, 182, 212, 0.15); color: #06b6d4;">
                    ⏱
                </div>
                <div class="stat-info">
                    <div class="stat-value"><%= mins %>m <%= secs %>s</div>
                    <div class="stat-label">Total Time (<%= String.format("%.1f", avgTime) %>s avg)</div>
                </div>
            </div>
        </section>

        <!-- Question by Question Review -->
        <section style="margin-bottom: 3rem;">
            <div class="section-heading">
                <h2 class="section-title">
                    <span>🔍</span> Detailed Solution & Answer Review
                </h2>
                <span style="color: var(--text-secondary); font-size: 0.9rem;">
                    Accuracy on attempted: <%= String.format("%.1f", accuracy) %>%
                </span>
            </div>

            <% for (Map<String, Object> r : reviewList) {
                int ord = (Integer) r.get("order");
                String qText = (String) r.get("question");
                String topic = (String) r.get("topic");
                String diff = (String) r.get("difficulty");
                String optA = (String) r.get("optionA");
                String optB = (String) r.get("optionB");
                String optC = (String) r.get("optionC");
                String optD = (String) r.get("optionD");
                String correctOpt = (String) r.get("correctOption");
                String userOpt = (String) r.get("selectedOption");
                boolean isCor = (Boolean) r.get("isCorrect");
                int timeTaken = (Integer) r.get("time");

                String statusClass = (userOpt == null || userOpt.isEmpty()) ? "skipped" : (isCor ? "correct" : "incorrect");
            %>
                <div class="review-item <%= statusClass %>">
                    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 0.75rem;">
                        <div style="display: flex; align-items: center; gap: 0.6rem;">
                            <span style="font-weight: 700; color: var(--accent-secondary);">Q<%= ord %>.</span>
                            <span class="tag" style="background: rgba(255, 255, 255, 0.08);"><%= topic %></span>
                            <span class="tag" style="background: rgba(255, 255, 255, 0.08);"><%= diff %></span>
                        </div>
                        <div>
                            <% if (userOpt == null || userOpt.isEmpty()) { %>
                                <span class="tag" style="background: rgba(245, 158, 11, 0.15); color: #fbbf24;">Skipped</span>
                            <% } else if (isCor) { %>
                                <span class="tag" style="background: rgba(16, 185, 129, 0.15); color: #34d399;">Correct (+1)</span>
                            <% } else { %>
                                <span class="tag" style="background: rgba(239, 68, 68, 0.15); color: #f87171;">Incorrect (0)</span>
                            <% } %>
                        </div>
                    </div>

                    <p style="font-size: 1.05rem; font-weight: 500; margin-bottom: 1rem; color: #ffffff;">
                        <%= qText %>
                    </p>

                    <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(260px, 1fr)); gap: 0.6rem; margin-bottom: 1rem;">
                        <div style="padding: 0.6rem 0.9rem; border-radius: var(--radius-sm); border: 1px solid var(--border-color); background: <%= "A".equals(correctOpt) ? "rgba(16, 185, 129, 0.15)" : ("A".equals(userOpt) ? "rgba(239, 68, 68, 0.15)" : "rgba(255, 255, 255, 0.02)") %>;">
                            <strong>A.</strong> <%= optA %>
                            <% if ("A".equals(correctOpt)) { %> <span style="color: #10b981; font-weight: 700; float: right;">✓ Correct</span> <% } %>
                            <% if ("A".equals(userOpt) && !isCor) { %> <span style="color: #ef4444; font-weight: 700; float: right;">✗ Your Choice</span> <% } %>
                        </div>

                        <div style="padding: 0.6rem 0.9rem; border-radius: var(--radius-sm); border: 1px solid var(--border-color); background: <%= "B".equals(correctOpt) ? "rgba(16, 185, 129, 0.15)" : ("B".equals(userOpt) ? "rgba(239, 68, 68, 0.15)" : "rgba(255, 255, 255, 0.02)") %>;">
                            <strong>B.</strong> <%= optB %>
                            <% if ("B".equals(correctOpt)) { %> <span style="color: #10b981; font-weight: 700; float: right;">✓ Correct</span> <% } %>
                            <% if ("B".equals(userOpt) && !isCor) { %> <span style="color: #ef4444; font-weight: 700; float: right;">✗ Your Choice</span> <% } %>
                        </div>

                        <div style="padding: 0.6rem 0.9rem; border-radius: var(--radius-sm); border: 1px solid var(--border-color); background: <%= "C".equals(correctOpt) ? "rgba(16, 185, 129, 0.15)" : ("C".equals(userOpt) ? "rgba(239, 68, 68, 0.15)" : "rgba(255, 255, 255, 0.02)") %>;">
                            <strong>C.</strong> <%= optC %>
                            <% if ("C".equals(correctOpt)) { %> <span style="color: #10b981; font-weight: 700; float: right;">✓ Correct</span> <% } %>
                            <% if ("C".equals(userOpt) && !isCor) { %> <span style="color: #ef4444; font-weight: 700; float: right;">✗ Your Choice</span> <% } %>
                        </div>

                        <div style="padding: 0.6rem 0.9rem; border-radius: var(--radius-sm); border: 1px solid var(--border-color); background: <%= "D".equals(correctOpt) ? "rgba(16, 185, 129, 0.15)" : ("D".equals(userOpt) ? "rgba(239, 68, 68, 0.15)" : "rgba(255, 255, 255, 0.02)") %>;">
                            <strong>D.</strong> <%= optD %>
                            <% if ("D".equals(correctOpt)) { %> <span style="color: #10b981; font-weight: 700; float: right;">✓ Correct</span> <% } %>
                            <% if ("D".equals(userOpt) && !isCor) { %> <span style="color: #ef4444; font-weight: 700; float: right;">✗ Your Choice</span> <% } %>
                        </div>
                    </div>
                </div>
            <% } %>
        </section>
    </main>

    <footer class="footer">
        <p>Smart Placement System &copy; 2026. Empowering Students for Campus Placement Success.</p>
    </footer>

    <script src="js/main.js"></script>
</body>
</html>
