<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, java.util.*, com.placement.DBUtil" %>
<%
    Object userIdObj = session.getAttribute("userId");
    if (userIdObj == null) {
        response.sendRedirect("../login.jsp");
        return;
    }

    int userId = (Integer) userIdObj;
    String section = request.getParameter("section");
    if (section == null || section.trim().isEmpty()) {
        section = "quantitative";
    }
    section = section.toLowerCase().trim();
    if (!section.equals("quantitative") && !section.equals("logical") && !section.equals("verbal")) {
        section = "quantitative";
    }

    try (Connection conn = DBUtil.getConnection()) {
        // 1. Check if user already has an active unsubmitted attempt for this section
        String checkActiveSql = "SELECT id FROM quiz_attempts WHERE user_id = ? AND section = ? AND is_submitted = 0 ORDER BY id DESC LIMIT 1";
        try (PreparedStatement psActive = conn.prepareStatement(checkActiveSql)) {
            psActive.setInt(1, userId);
            psActive.setString(2, section);
            try (ResultSet rsActive = psActive.executeQuery()) {
                if (rsActive.next()) {
                    int existingAttemptId = rsActive.getInt("id");
                    session.setAttribute("active_attempt_id", existingAttemptId);
                    response.sendRedirect("../quiz.jsp");
                    return;
                }
            }
        }

        // 2. Fetch 15 questions using fair rotation (prioritizing unseen questions)
        List<Integer> questionIds = new ArrayList<>();
        String unseenSql = "SELECT id FROM questions WHERE section = ? AND id NOT IN (" +
                           "    SELECT question_id FROM user_question_history WHERE user_id = ? AND section = ?" +
                           ") ORDER BY RAND() LIMIT 15";

        try (PreparedStatement psUnseen = conn.prepareStatement(unseenSql)) {
            psUnseen.setString(1, section);
            psUnseen.setInt(2, userId);
            psUnseen.setString(3, section);
            try (ResultSet rs = psUnseen.executeQuery()) {
                while (rs.next()) {
                    questionIds.add(rs.getInt("id"));
                }
            }
        }

        // If fewer than 15 unseen questions remain, recycle the question pool by resetting history for this section
        if (questionIds.size() < 15) {
            String resetHistorySql = "DELETE FROM user_question_history WHERE user_id = ? AND section = ?";
            try (PreparedStatement psReset = conn.prepareStatement(resetHistorySql)) {
                psReset.setInt(1, userId);
                psReset.setString(2, section);
                psReset.executeUpdate();
            }

            // Refetch 15 random questions
            questionIds.clear();
            String freshSql = "SELECT id FROM questions WHERE section = ? ORDER BY RAND() LIMIT 15";
            try (PreparedStatement psFresh = conn.prepareStatement(freshSql)) {
                psFresh.setString(1, section);
                try (ResultSet rs = psFresh.executeQuery()) {
                    while (rs.next()) {
                        questionIds.add(rs.getInt("id"));
                    }
                }
            }
        }

        if (questionIds.isEmpty()) {
            response.sendRedirect("../dashboard.jsp?error=no_questions");
            return;
        }

        // 3. Create the new attempt in quiz_attempts
        int newAttemptId = -1;
        String insertAttemptSql = "INSERT INTO quiz_attempts (user_id, section, total_questions, is_submitted, started_at) " +
                                  "VALUES (?, ?, 15, 0, NOW())";
        try (PreparedStatement psIns = conn.prepareStatement(insertAttemptSql, Statement.RETURN_GENERATED_KEYS)) {
            psIns.setInt(1, userId);
            psIns.setString(2, section);
            psIns.executeUpdate();
            try (ResultSet rsKey = psIns.getGeneratedKeys()) {
                if (rsKey.next()) {
                    newAttemptId = rsKey.getInt(1);
                }
            }
        }

        // 4. Save question list in quiz_responses and log in user_question_history
        String insertRespSql = "INSERT INTO quiz_responses (attempt_id, question_id, question_order) VALUES (?, ?, ?)";
        String logHistSql = "INSERT INTO user_question_history (user_id, question_id, section, served_at) VALUES (?, ?, ?, NOW())";

        try (PreparedStatement psResp = conn.prepareStatement(insertRespSql);
             PreparedStatement psHist = conn.prepareStatement(logHistSql)) {

            for (int i = 0; i < questionIds.size(); i++) {
                int qId = questionIds.get(i);
                
                psResp.setInt(1, newAttemptId);
                psResp.setInt(2, qId);
                psResp.setInt(3, i + 1);
                psResp.addBatch();

                psHist.setInt(1, userId);
                psHist.setInt(2, qId);
                psHist.setString(3, section);
                psHist.addBatch();
            }

            psResp.executeBatch();
            psHist.executeBatch();
        }

        session.setAttribute("active_attempt_id", newAttemptId);
        response.sendRedirect("../quiz.jsp");

    } catch (SQLException e) {
        e.printStackTrace();
        response.sendRedirect("../dashboard.jsp?error=" + java.net.URLEncoder.encode(e.getMessage(), "UTF-8"));
    }
%>
