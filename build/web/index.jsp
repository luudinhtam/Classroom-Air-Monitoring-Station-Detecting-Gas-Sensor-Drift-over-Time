<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%-- The filter sends an anonymous visitor to the login page and a signed in
     one to the dashboard, so this file only needs to hand over control. --%>
<% response.sendRedirect(request.getContextPath() + "/dashboard"); %>
