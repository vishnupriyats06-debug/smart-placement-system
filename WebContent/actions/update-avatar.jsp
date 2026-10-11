<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, com.placement.DBUtil" %>
<%
    Object userIdObj = session.getAttribute("userId");
    if (userIdObj == null) {
        response.sendRedirect("../login.jsp");
        return;
    }

    int userId = (Integer) userIdObj;
    String avatar = request.getParameter("avatar");

    if (avatar != null && !avatar.trim().isEmpty()) {
        avatar = avatar.trim();
        // Basic sanitizer to allow only avatar01.svg .. avatar20.svg
        if (avatar.matches("avatar(0[1-9]|1[0-9]|20)\\.svg")) {
            String sql = "UPDATE users SET avatar = ? WHERE id = ?";
            try (Connection conn = DBUtil.getConnection();
                 PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setString(1, avatar);
                ps.setInt(2, userId);
                ps.executeUpdate();
                
                session.setAttribute("avatar", avatar);
            } catch (SQLException e) {
                e.printStackTrace();
            }
        }
    }

    response.sendRedirect("../profile.jsp?msg=saved");
%>
