<%@page import="java.time.format.DateTimeFormatter"%>
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
    
    DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
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

                <a class="btn ghost" href="<%= ctx %>/admin/stations">&larr; Danh sách trạm</a>
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

                    <td><%= ew.getStartAt().format(formatter) %></td>

                    <td><%= ew.getEndAt().format(formatter) %></td>

                    <td><%= Web.esc(ew.getMarkedByUsername()) %></td>

                    <td><%= ew.getCreatedAt().format(formatter) %></td>

                    <td><%= Web.esc(ew.getNote()) %></td>

                    <td class="ops ops-group">

                        <button type="button" class="btn-block btn-blue"
                                onclick="window.location.href='<%= ctx %>/admin/emptyWindows/edit?id=<%= ew.getEmptyWindowId() %>&stationId=<%= stationId %>'">
                            Sửa
                        </button>

                        <form method="post"
                              action="<%= ctx %>/admin/emptyWindows/delete"
                              onsubmit="return confirm('Xóa khoảng phòng trống này?');">

                            <input type="hidden" name="emptyWindowId"
                                   value="<%= ew.getEmptyWindowId() %>">

                            <input type="hidden" name="stationId"
                                   value="<%= stationId %>">

                            <button type="submit" class="btn-block btn-red">
                                Xóa
                            </button>
                        </form>

                        <button type="button" class="btn-block btn-gray"
                                onclick="window.location.href='<%= ctx %>/admin/emptyWindows/baseline?emptyWindowId=<%= ew.getEmptyWindowId() %>&stationId=<%= stationId %>'">
                            Tính mức nền
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