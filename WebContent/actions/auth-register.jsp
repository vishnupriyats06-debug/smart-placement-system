<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, com.placement.DBUtil, com.placement.PasswordUtil" %>
<%
    String username = request.getParameter("username");
    String email = request.getParameter("email");
    String password = request.getParameter("password");

    if (username == null || email == null || password == null ||
        username.trim().isEmpty() || email.trim().isEmpty() || password.trim().isEmpty()) {
        response.sendRedirect("../register.jsp?error=missing");
        return;
    }

    username = username.trim();
    email = email.trim();

    if (password.length() < 6) {
        response.sendRedirect("../register.jsp?error=short_pwd");
        return;
    }

    String checkUserSql = "SELECT id FROM users WHERE username = ?";
    String checkEmailSql = "SELECT id FROM users WHERE email = ?";
    String insertSql = "INSERT INTO users (username, email, password_hash, avatar) VALUES (?, ?, ?, ?)";

    try (Connection conn = DBUtil.getConnection()) {
        // 1. Check unique username
        try (PreparedStatement ps = conn.prepareStatement(checkUserSql)) {
            ps.setString(1, username);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    response.sendRedirect("../register.jsp?error=exists_user");
                    return;
                }
            }
        }

        // 2. Check unique email
        try (PreparedStatement ps = conn.prepareStatement(checkEmailSql)) {
            ps.setString(1, email);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    response.sendRedirect("../register.jsp?error=exists_email");
                    return;
                }
            }
        }

        // 3. Hash password and insert
        String hashedPassword = PasswordUtil.hashPassword(password);
        try (PreparedStatement ps = conn.prepareStatement(insertSql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setString(1, username);
            ps.setString(2, email);
            ps.setString(3, hashedPassword);
            ps.setString(4, "avatar11.svg"); // Default initial avatar
            ps.executeUpdate();
            
            try (ResultSet rs = ps.getGeneratedKeys()) {
                if (rs.next()) {
                    int newUserId = rs.getInt(1);
                    // Initialize streak record
                    try (PreparedStatement psStreak = conn.prepareStatement("INSERT IGNORE INTO user_streaks (user_id, current_streak, longest_streak) VALUES (?, 0, 0)")) {
                        psStreak.setInt(1, newUserId);
                        psStreak.executeUpdate();
                    }
                }
            }
        }

        response.sendRedirect("../login.jsp?msg=registered");
        return;

    } catch (SQLException e) {
        e.printStackTrace();
        response.sendRedirect("../register.jsp?error=" + java.net.URLEncoder.encode(e.getMessage(), "UTF-8"));
    }
%>
