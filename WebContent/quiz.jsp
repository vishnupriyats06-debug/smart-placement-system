<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, java.util.*, com.placement.DBUtil, com.placement.Question" %>
<%
    // Prevent caching on quiz page
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    Object userIdObj = session.getAttribute("userId");
    if (userIdObj == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    int userId = (Integer) userIdObj;
    Object attemptIdObj = session.getAttribute("active_attempt_id");
    int attemptId = (attemptIdObj != null) ? (Integer) attemptIdObj : -1;

    String section = "quantitative";
    Timestamp startedAt = null;
    boolean isSubmitted = false;

    // Load active attempt details
    try (Connection conn = DBUtil.getConnection()) {
        if (attemptId <= 0) {
            // Check if there is an active unsubmitted attempt in database
            String findActiveSql = "SELECT id, section, started_at, is_submitted FROM quiz_attempts WHERE user_id = ? AND is_submitted = 0 ORDER BY id DESC LIMIT 1";
            try (PreparedStatement ps = conn.prepareStatement(findActiveSql)) {
                ps.setInt(1, userId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        attemptId = rs.getInt("id");
                        section = rs.getString("section");
                        startedAt = rs.getTimestamp("started_at");
                        isSubmitted = rs.getBoolean("is_submitted");
                        session.setAttribute("active_attempt_id", attemptId);
                    }
                }
            }
        } else {
            String getAttemptSql = "SELECT section, started_at, is_submitted FROM quiz_attempts WHERE id = ? AND user_id = ?";
            try (PreparedStatement ps = conn.prepareStatement(getAttemptSql)) {
                ps.setInt(1, attemptId);
                ps.setInt(2, userId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        section = rs.getString("section");
                        startedAt = rs.getTimestamp("started_at");
                        isSubmitted = rs.getBoolean("is_submitted");
                    }
                }
            }
        }
    } catch (SQLException e) {
        e.printStackTrace();
    }

    if (attemptId <= 0 || isSubmitted) {
        // No active attempt or already submitted
        session.removeAttribute("active_attempt_id");
        response.sendRedirect("dashboard.jsp");
        return;
    }

    // Load the 15 questions assigned to this attempt in the exact order saved
    List<Question> questions = new ArrayList<>();
    Map<Integer, String> existingAnswers = new HashMap<>(); // questionId -> selectedOption

    try (Connection conn = DBUtil.getConnection()) {
        String loadQSql = "SELECT q.id, q.section, q.topic, q.difficulty, q.question_text, " +
                          "       q.option_a, q.option_b, q.option_c, q.option_d, q.correct_option, " +
                          "       qr.selected_option " +
                          "FROM quiz_responses qr " +
                          "JOIN questions q ON qr.question_id = q.id " +
                          "WHERE qr.attempt_id = ? " +
                          "ORDER BY qr.question_order ASC";

        try (PreparedStatement ps = conn.prepareStatement(loadQSql)) {
            ps.setInt(1, attemptId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Question q = new Question();
                    q.setId(rs.getInt("id"));
                    q.setSection(rs.getString("section"));
                    q.setTopic(rs.getString("topic"));
                    q.setDifficulty(rs.getString("difficulty"));
                    q.setQuestionText(rs.getString("question_text"));
                    q.setOptionA(rs.getString("option_a"));
                    q.setOptionB(rs.getString("option_b"));
                    q.setOptionC(rs.getString("option_c"));
                    q.setOptionD(rs.getString("option_d"));
                    // Note: correctOption is kept server-side only, not sent to JS!
                    questions.add(q);

                    String sel = rs.getString("selected_option");
                    if (sel != null && !sel.isEmpty()) {
                        existingAnswers.put(q.getId(), sel);
                    }
                }
            }
        }
    } catch (SQLException e) {
        e.printStackTrace();
    }

    if (questions.isEmpty()) {
        response.sendRedirect("dashboard.jsp");
        return;
    }

    long startedAtMs = (startedAt != null) ? startedAt.getTime() : new java.util.Date().getTime();
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Active Quiz: <%= Character.toUpperCase(section.charAt(0)) + section.substring(1) %> - Smart Placement System</title>
    <link rel="stylesheet" href="css/style.css">
    <link rel="stylesheet" href="css/quiz.css">
</head>
<body>
    <div class="quiz-container">
        <!-- Sticky Quiz Header -->
        <div class="quiz-header-bar">
            <div class="quiz-meta-info">
                <div>
                    <span class="tag tag-<%= section %>"><%= section %></span>
                    <h2 style="font-size: 1.25rem; margin-top: 0.2rem;">Assessment in Progress</h2>
                </div>
            </div>

            <!-- Timer display -->
            <div id="quizTimerBox" class="quiz-timer-box">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/>
                </svg>
                <span id="quizTimerDisplay">15:00</span>
            </div>

            <button type="button" class="btn btn-danger btn-sm" onclick="openSubmitModal()">
                Submit Quiz
            </button>
        </div>

        <!-- Quiz Progress Bar -->
        <div style="margin-bottom: 1.5rem;">
            <div style="display: flex; justify-content: space-between; font-size: 0.85rem; color: var(--text-secondary); margin-bottom: 0.35rem;">
                <span>Progress</span>
                <span id="quizProgressLabel">0 of <%= questions.size() %> Answered</span>
            </div>
            <div class="quiz-progress-track">
                <div id="quizProgressFill" class="quiz-progress-fill" style="width: 0%;"></div>
            </div>
        </div>

        <!-- Main Quiz Workspace -->
        <form id="quizSubmissionForm" action="actions/quiz-submit.jsp" method="POST">
            <input type="hidden" name="attempt_id" value="<%= attemptId %>">

            <div class="quiz-layout">
                <!-- Left: Active Question Card -->
                <div class="question-card">
                    <div class="question-header">
                        <div class="question-num">
                            Question <span id="currentQuestionLabel">1</span> of <%= questions.size() %>
                        </div>
                        <div class="question-badges">
                            <span class="tag" style="background: rgba(255, 255, 255, 0.08); color: var(--text-secondary);">
                                1 Mark
                            </span>
                        </div>
                    </div>

                    <!-- Question Panels -->
                    <% for (int i = 0; i < questions.size(); i++) {
                        Question q = questions.get(i);
                        String savedAns = existingAnswers.getOrDefault(q.getId(), "");
                    %>
                        <div class="question-item-card" id="q_card_<%= i %>" style="display: <%= (i == 0) ? "flex" : "none" %>; flex-direction: column; flex: 1;">
                            <!-- Hidden inputs for submission -->
                            <input type="hidden" name="q_id_<%= i %>" value="<%= q.getId() %>">
                            <input type="hidden" id="selected_answer_<%= i %>" name="selected_answer_<%= i %>" value="<%= savedAns %>">
                            <input type="hidden" id="response_time_<%= i %>" name="response_time_<%= i %>" value="0">

                            <div style="margin-bottom: 0.75rem;">
                                <span class="tag" style="background: rgba(99, 102, 241, 0.15); color: #a5b4fc; margin-right: 0.5rem;">
                                    <%= q.getTopic() %>
                                </span>
                                <span class="tag" style="background: rgba(16, 185, 129, 0.15); color: #6ee7b7;">
                                    <%= q.getDifficulty() %>
                                </span>
                            </div>

                            <div class="question-body">
                                <%= q.getQuestionText() %>
                            </div>

                            <div class="options-list" id="options_group_<%= i %>">
                                <div class="option-item <%= "A".equals(savedAns) ? "selected" : "" %>" data-option="A" onclick="selectOption(<%= i %>, 'A')">
                                    <div class="option-letter">A</div>
                                    <div class="option-text"><%= q.getOptionA() %></div>
                                </div>

                                <div class="option-item <%= "B".equals(savedAns) ? "selected" : "" %>" data-option="B" onclick="selectOption(<%= i %>, 'B')">
                                    <div class="option-letter">B</div>
                                    <div class="option-text"><%= q.getOptionB() %></div>
                                </div>

                                <div class="option-item <%= "C".equals(savedAns) ? "selected" : "" %>" data-option="C" onclick="selectOption(<%= i %>, 'C')">
                                    <div class="option-letter">C</div>
                                    <div class="option-text"><%= q.getOptionC() %></div>
                                </div>

                                <div class="option-item <%= "D".equals(savedAns) ? "selected" : "" %>" data-option="D" onclick="selectOption(<%= i %>, 'D')">
                                    <div class="option-letter">D</div>
                                    <div class="option-text"><%= q.getOptionD() %></div>
                                </div>
                            </div>
                        </div>
                    <% } %>

                    <!-- Quiz Navigation Controls -->
                    <div class="quiz-controls">
                        <button type="button" id="prevQuestionBtn" class="btn btn-secondary" onclick="prevQuestion()">
                            &larr; Previous
                        </button>
                        <button type="button" class="btn btn-secondary btn-sm" onclick="clearCurrentSelection()">
                            Clear Choice
                        </button>
                        <button type="button" id="nextQuestionBtn" class="btn btn-primary" onclick="nextQuestion()">
                            Next Question &rarr;
                        </button>
                    </div>
                </div>

                <!-- Right: Question Palette Sidebar -->
                <aside class="palette-sidebar">
                    <h3 class="palette-title">Question Palette</h3>

                    <div class="palette-grid">
                        <% for (int i = 0; i < questions.size(); i++) {
                            Question q = questions.get(i);
                            String savedAns = existingAnswers.getOrDefault(q.getId(), "");
                            boolean hasAns = !savedAns.isEmpty();
                        %>
                            <button type="button" class="palette-btn <%= hasAns ? "answered" : "" %>" id="pal_btn_<%= i %>" onclick="jumpToQuestion(<%= i %>)">
                                <%= i + 1 %>
                            </button>
                        <% } %>
                    </div>

                    <div class="palette-legend">
                        <div class="legend-item">
                            <span class="legend-dot dot-answered"></span>
                            <span>Answered</span>
                        </div>
                        <div class="legend-item">
                            <span class="legend-dot dot-unanswered"></span>
                            <span>Visited / Unanswered</span>
                        </div>
                        <div class="legend-item">
                            <span class="legend-dot dot-notvisited"></span>
                            <span>Not Visited</span>
                        </div>
                    </div>
                </aside>
            </div>
        </form>
    </div>

    <!-- Submit Confirmation Modal -->
    <div id="submitConfirmModal" class="modal-overlay">
        <div class="modal-content">
            <div style="font-size: 2.5rem; margin-bottom: 1rem;">🏁</div>
            <h3 style="font-size: 1.4rem; margin-bottom: 0.5rem;">Submit Assessment?</h3>
            <p style="color: var(--text-secondary); margin-bottom: 1.5rem; font-size: 0.95rem;">
                You have answered <strong id="modalAnsweredCount" style="color: #10b981;">0</strong> questions.
                <br>Unanswered questions: <strong id="modalUnansweredCount" style="color: #ef4444;">15</strong>.
            </p>

            <div style="display: flex; gap: 1rem; justify-content: center;">
                <button type="button" class="btn btn-secondary" onclick="closeSubmitModal()">
                    Review Questions
                </button>
                <button type="button" class="btn btn-primary" onclick="submitQuiz()">
                    Confirm & Submit
                </button>
            </div>
        </div>
    </div>

    <script src="js/main.js"></script>
    <script src="js/quiz.js"></script>
    <script>
        // Initialize state on page load
        document.addEventListener('DOMContentLoaded', () => {
            initQuiz({
                attemptId: <%= attemptId %>,
                serverStartTime: <%= startedAtMs %>,
                durationSeconds: 900,
                questions: [
                    <% for (int i = 0; i < questions.size(); i++) { %>
                        { id: <%= questions.get(i).getId() %> }<%= (i < questions.size() - 1) ? "," : "" %>
                    <% } %>
                ]
            });
        });
    </script>
</body>
</html>
