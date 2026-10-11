<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, java.util.*, com.placement.DBUtil, com.placement.StreakUtil" %>
<%
    Object userIdObj = session.getAttribute("userId");
    if (userIdObj == null) {
        response.sendRedirect("../login.jsp");
        return;
    }

    int userId = (Integer) userIdObj;
    String attemptIdParam = request.getParameter("attempt_id");
    if (attemptIdParam == null || attemptIdParam.trim().isEmpty()) {
        response.sendRedirect("../dashboard.jsp");
        return;
    }

    int attemptId = Integer.parseInt(attemptIdParam.trim());

    try (Connection conn = DBUtil.getConnection()) {
        conn.setAutoCommit(false); // Begin transaction for data integrity

        // 1. Verify attempt ownership and ensure it hasn't been submitted already (prevent duplicate submissions)
        String checkAttemptSql = "SELECT id, section, started_at, is_submitted FROM quiz_attempts WHERE id = ? AND user_id = ?";
        Timestamp startedAt = null;
        boolean isAlreadySubmitted = false;

        try (PreparedStatement ps = conn.prepareStatement(checkAttemptSql)) {
            ps.setInt(1, attemptId);
            ps.setInt(2, userId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    startedAt = rs.getTimestamp("started_at");
                    isAlreadySubmitted = rs.getBoolean("is_submitted");
                } else {
                    // Attempt not found or doesn't belong to this user
                    conn.rollback();
                    response.sendRedirect("../dashboard.jsp");
                    return;
                }
            }
        }

        if (isAlreadySubmitted) {
            // Already submitted, directly redirect to result page without re-evaluating
            session.removeAttribute("active_attempt_id");
            conn.rollback();
            response.sendRedirect("../quiz-result.jsp?attempt_id=" + attemptId);
            return;
        }

        // 2. Load the correct answers and questions for this attempt from MySQL
        Map<Integer, String> correctAnswers = new HashMap<>();
        String loadQuestionsSql = "SELECT qr.question_id, q.correct_option " +
                                 "FROM quiz_responses qr " +
                                 "JOIN questions q ON qr.question_id = q.id " +
                                 "WHERE qr.attempt_id = ?";

        try (PreparedStatement ps = conn.prepareStatement(loadQuestionsSql)) {
            ps.setInt(1, attemptId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    correctAnswers.put(rs.getInt("question_id"), rs.getString("correct_option").toUpperCase().trim());
                }
            }
        }

        int totalQuestions = correctAnswers.size();
        int attemptedCount = 0;
        int correctCount = 0;
        int incorrectCount = 0;
        int totalResponseTime = 0;

        // 3. Process each question's submitted response
        String updateResponseSql = "UPDATE quiz_responses SET selected_option = ?, is_correct = ?, response_time_seconds = ? " +
                                   "WHERE attempt_id = ? AND question_id = ?";

        try (PreparedStatement psResp = conn.prepareStatement(updateResponseSql)) {
            for (int i = 0; i < totalQuestions; i++) {
                String qIdParam = request.getParameter("q_id_" + i);
                String selectedOpt = request.getParameter("selected_answer_" + i);
                String respTimeParam = request.getParameter("response_time_" + i);

                if (qIdParam != null && !qIdParam.trim().isEmpty()) {
                    int qId = Integer.parseInt(qIdParam.trim());
                    String correctOpt = correctAnswers.get(qId);
                    
                    int respTime = 0;
                    if (respTimeParam != null && !respTimeParam.trim().isEmpty()) {
                        try {
                            respTime = Math.max(0, Integer.parseInt(respTimeParam.trim()));
                        } catch (NumberFormatException ignored) {}
                    }
                    totalResponseTime += respTime;

                    boolean isCorrect = false;
                    String finalSelected = null;

                    if (selectedOpt != null && !selectedOpt.trim().isEmpty()) {
                        finalSelected = selectedOpt.trim().toUpperCase();
                        attemptedCount++;
                        if (finalSelected.equals(correctOpt)) {
                            isCorrect = true;
                            correctCount++;
                        } else {
                            incorrectCount++;
                        }
                    }

                    // Update response record in database
                    if (finalSelected != null) {
                        psResp.setString(1, finalSelected);
                    } else {
                        psResp.setNull(1, Types.CHAR);
                    }
                    psResp.setBoolean(2, isCorrect);
                    psResp.setInt(3, respTime);
                    psResp.setInt(4, attemptId);
                    psResp.setInt(5, qId);
                    psResp.addBatch();
                }
            }
            psResp.executeBatch();
        }

        // 4. Calculate total time, accuracy, and average response time
        long startMs = (startedAt != null) ? startedAt.getTime() : new java.util.Date().getTime();
        long nowMs = new java.util.Date().getTime();
        int totalQuizDurationSeconds = Math.max(1, (int) ((nowMs - startMs) / 1000));

        double accuracy = 0.0;
        if (attemptedCount > 0) {
            accuracy = ((double) correctCount / attemptedCount) * 100.0;
        }

        double avgResponseTime = 0.0;
        if (attemptedCount > 0) {
            avgResponseTime = (double) totalResponseTime / attemptedCount;
        } else {
            avgResponseTime = (double) totalQuizDurationSeconds / totalQuestions;
        }

        int score = correctCount; // Score = number of correct answers out of 15

        // 5. Update the quiz_attempt record as completed
        String updateAttemptSql = "UPDATE quiz_attempts SET " +
                                  "attempted_count = ?, " +
                                  "correct_count = ?, " +
                                  "incorrect_count = ?, " +
                                  "score = ?, " +
                                  "accuracy = ?, " +
                                  "total_time_seconds = ?, " +
                                  "avg_response_time = ?, " +
                                  "is_submitted = 1, " +
                                  "submitted_at = NOW() " +
                                  "WHERE id = ?";

        try (PreparedStatement psUpdate = conn.prepareStatement(updateAttemptSql)) {
            psUpdate.setInt(1, attemptedCount);
            psUpdate.setInt(2, correctCount);
            psUpdate.setInt(3, incorrectCount);
            psUpdate.setInt(4, score);
            psUpdate.setDouble(5, accuracy);
            psUpdate.setInt(6, totalQuizDurationSeconds);
            psUpdate.setDouble(7, avgResponseTime);
            psUpdate.setInt(8, attemptId);
            psUpdate.executeUpdate();
        }

        // Commit transaction
        conn.commit();

        // 6. Update user daily streak
        StreakUtil.updateStreakOnQuizCompletion(userId);

        // Remove active attempt from session
        session.removeAttribute("active_attempt_id");

        // Redirect to result screen
        response.sendRedirect("../quiz-result.jsp?attempt_id=" + attemptId);

    } catch (Exception e) {
        e.printStackTrace();
        response.sendRedirect("../dashboard.jsp?error=submit_failed");
    }
%>
