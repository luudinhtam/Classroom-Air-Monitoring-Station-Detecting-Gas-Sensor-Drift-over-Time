<%@page import="model.AirStation"%>
<%@page import="dao.AirStationDAO"%>
<%@page import="util.Web"%>
<%@page import="model.EmptyWindow"%>
<%@page import="java.util.List"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>

<%
    List<EmptyWindow> rows = (List<EmptyWindow>) request.getAttribute("rows");
    int stationId = (int) request.getAttribute("stationId");
    int total = (int) request.getAttribute("total");
    String ctx = request.getContextPath();

    AirStationDAO stations = new AirStationDAO();
    AirStation a = stations.findById(stationId);
%>

<!DOCTYPE html>
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <title>Station Empty Windows</title>
        <link rel="stylesheet" href="<%= ctx %>/css/app.css">
    </head>

    <body>
        <jsp:include page="/WEB-INF/views/nav.jsp"/>
        <div class="wrap">
            <h2>
                Khoang phong trong tram:
                <%= a.getCode() %> / <%= a.getName() %>
                (<%= total %>)
            </h2>

            <form class="filter" method="get" action="<%= ctx %>/admin/emptyWindows">
                
                <input type="hidden" name="stationId" value="<%= stationId %>">

                <input type="text" name="keyword" placeholder="Ten khoang phong trong"
                       value="<%= request.getParameter("keyword") != null
                                ? Web.esc(request.getParameter("keyword"))
                                : "" %>">

                <button type="submit">Loc</button>

                <a class="btn ghost" href="<%= ctx %>/admin/emptyWindows?stationId=<%= stationId %>">
                    Bo loc
                </a>

                <a class="btn" href="<%= ctx %>/admin/emptyWindows/create?stationId=<%= stationId %>">
                    Them khoang phong trong
                </a>

                <a class="btn ghost" href="<%= ctx %>/admin/stations" style="background-color: pink;">
                    Click to go back
                </a>
            </form>

            <table class="grid">
                <tr>
                    <th>#</th>
                    <th>Code</th>
                    <th>Name</th>
                    <th>Start at</th>
                    <th>End at</th>
                    <th>Marked by</th>
                    <th>Created at</th>
                    <th>Note</th>
                    <th>Thao tac</th>
                </tr>

                <% for (EmptyWindow ew : rows) { %>
                <tr>
                    <td><%= ew.getEmptyWindowId() %></td>

                    <td><%= Web.esc(ew.getCode()) %></td>

                    <td><%= Web.esc(ew.getName()) %></td>

                    <td><%= ew.getStartAt() %></td>

                    <td><%= ew.getEndAt() %></td>

                    <td><%= Web.esc(ew.getMarkedByUsername()) %></td>

                    <td><%= ew.getCreatedAt() %></td>

                    <td><%= Web.esc(ew.getNote()) %></td>

                    <td class="ops">

                        <button type="button" class="btn ghost"
                                onclick="window.location.href='<%= ctx %>/admin/emptyWindows/edit?id=<%= ew.getEmptyWindowId() %>&stationId=<%= stationId %>'">
                            Sua
                        </button>

                        <form method="post"
                              action="<%= ctx %>/admin/emptyWindows/delete"
                              onsubmit="return confirm('Xoa khoang phong trong nay?');">

                            <input type="hidden" name="emptyWindowId"
                                   value="<%= ew.getEmptyWindowId() %>">

                            <input type="hidden" name="stationId"
                                   value="<%= stationId %>">

                            <button type="submit" class="btn danger" style="background-color: red; color: white">
                                Xoa
                            </button>
                        </form>

                        <button type="button" class="btn"
                                onclick="window.location.href='<%= ctx %>/admin/emptyWindows/baseline?emptyWindowId=<%= ew.getEmptyWindowId() %>&stationId=<%= stationId %>'">
                            Tinh muc nen
                        </button>

                    </td>
                </tr>
                <% } %>
                <% if (rows.isEmpty()) { %>
                <tr>
                    <td colspan="9" class="c">
                        Khong co khoang phong trong nao
                    </td>
                </tr>
                <% } %>

            </table>

        </div>

    </body>
</html>