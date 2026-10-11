<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    // Invalidate session cleanly
    if (session != null) {
        session.invalidate();
    }

    // Set cache disable headers
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    response.sendRedirect("login.jsp?msg=logged_out");
%>
