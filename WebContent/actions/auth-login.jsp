<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, com.placement.DBUtil, com.placement.PasswordUtil" %>
<%
    String username = request.getParameter("username");
    String password = request.getParameter("password");

    if (username == null || password == null || username.trim().isEmpty() || password.trim().isEmpty()) {
        response.sendRedirect("../login.jsp?error=missing");
        return;
    }

    username = username.trim();

    String sql = "SELECT id, username, email, password_hash, avatar FROM users WHERE username = ?";
    try (Connection conn = DBUtil.getConnection();
         PreparedStatement ps = conn.prepareStatement(sql)) {
        
        ps.setString(1, username);
        try (ResultSet rs = ps.executeQuery()) {
            if (rs.next()) {
                String storedHash = rs.getString("password_hash");
                if (PasswordUtil.verifyPassword(password, storedHash)) {
                    // Successful authentication - initialize session
                    session.setAttribute("userId", rs.getInt("id"));
                    session.setAttribute("username", rs.getString("username"));
                    session.setAttribute("email", rs.getString("email"));
                    session.setAttribute("avatar", rs.getString("avatar"));
                    
                    response.sendRedirect("../dashboard.jsp");
                    return;
                }
            }
        }
    } catch (Exception e) {
        e.printStackTrace();
        response.sendRedirect("../login.jsp?error=db");
        return;
    }

    response.sendRedirect("../login.jsp?error=invalid");
%>
