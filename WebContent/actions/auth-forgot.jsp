<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, com.placement.DBUtil, com.placement.PasswordUtil" %>
<%
    String username = request.getParameter("username");
    String newPassword = request.getParameter("new_password");
    String confirmPassword = request.getParameter("confirm_password");

    if (username == null || newPassword == null || confirmPassword == null ||
        username.trim().isEmpty() || newPassword.trim().isEmpty() || confirmPassword.trim().isEmpty()) {
        response.sendRedirect("../forgot-password.jsp?error=missing");
        return;
    }

    username = username.trim();

    if (!newPassword.equals(confirmPassword)) {
        response.sendRedirect("../forgot-password.jsp?error=mismatch");
        return;
    }

    if (newPassword.length() < 6) {
        response.sendRedirect("../forgot-password.jsp?error=short_pwd");
        return;
    }

    String checkUserSql = "SELECT id FROM users WHERE username = ?";
    String updatePwdSql = "UPDATE users SET password_hash = ? WHERE username = ?";

    try (Connection conn = DBUtil.getConnection()) {
        // 1. Verify username exists
        boolean userFound = false;
        try (PreparedStatement ps = conn.prepareStatement(checkUserSql)) {
            ps.setString(1, username);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    userFound = true;
                }
            }
        }

        if (!userFound) {
            response.sendRedirect("../forgot-password.jsp?error=not_found");
            return;
        }

        // 2. Hash and update password
        String hashedNewPassword = PasswordUtil.hashPassword(newPassword);
        try (PreparedStatement ps = conn.prepareStatement(updatePwdSql)) {
            ps.setString(1, hashedNewPassword);
            ps.setString(2, username);
            int rows = ps.executeUpdate();
            if (rows > 0) {
                response.sendRedirect("../login.jsp?msg=reset_success");
                return;
            }
        }

    } catch (SQLException e) {
        e.printStackTrace();
        response.sendRedirect("../forgot-password.jsp?error=db");
        return;
    }

    response.sendRedirect("../forgot-password.jsp?error=unknown");
%>
