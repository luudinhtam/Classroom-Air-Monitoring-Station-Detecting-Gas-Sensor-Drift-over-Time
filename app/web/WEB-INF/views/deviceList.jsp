<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
    <%@ page import="java.util.List, java.util.Map, java.util.HashMap, model.Device, model.Room, dao.RoomDAO, model.AppUser, util.Web" %>
        <% List<Device> rows = (List<Device>) request.getAttribute("rows");
                AppUser me = (AppUser) session.getAttribute("user");
                String ctx = request.getContextPath();

                String keyword = (String) request.getAttribute("keyword");
                String activeState = (String) request.getAttribute("activeState");
                Integer currentPage = (Integer) request.getAttribute("page");
                Integer totalPages = (Integer) request.getAttribute("pages");
                if (currentPage == null) currentPage = 1;
                if (totalPages == null) totalPages = 1;

                String qs = "keyword=" + Web.esc(keyword)
                + "&activeState=" + Web.esc(activeState);

                Map<Integer, String> roomCodeMap = new HashMap<>();
                try {
                    for (Room r : RoomDAO.getInstance().findAllActive()) {
                        roomCodeMap.put(r.getRoomId(), r.getCode());
                    }
                } catch (Exception ignored) {}
                %>
                <!DOCTYPE html>
                <html>

                <head>
                    <meta charset="UTF-8">
                    <meta name="viewport" content="width=device-width, initial-scale=1.0">
                    <title>Devices</title>
                    <link rel="stylesheet" href="<%= ctx %>/assets/css/app.css?v=2">
                </head>

                <body>
                    <jsp:include page="/WEB-INF/views/nav.jsp" />
                    <div class="wrap">
                        <h2>Devices (<%= request.getAttribute("total") %>)</h2>

                        <form class="filter" method="get" action="<%= ctx %>/admin/devices">
                            <input type="text" name="keyword" placeholder="Device code, location..."
                                value="<%= Web.esc(keyword) %>">
                            <select name="activeState">
                                <option value="">-- All Statuses --</option>
                                <option value="ACTIVE" <%="ACTIVE" .equals(activeState) ? "selected" : "" %>>Active
                                </option>
                                <option value="INACTIVE" <%="INACTIVE" .equals(activeState) ? "selected" : "" %>
                                    >Inactive</option>
                            </select>
                            <button type="submit">Filter</button>
                            <a class="btn ghost" href="<%= ctx %>/admin/devices">Reset</a>

                            <a class="btn" href="<%= ctx %>/admin/devices/create">+ Add Device</a>
                        </form>

                        <div class="table-responsive">
                            <table class="grid">
                                <tr>
                                    <th>ID</th>
                                    <th>Device Code</th>
                                    <th>API Key</th>
                                    <th>Location</th>
                                    <th>Room Code</th>
                                    <th>Last Seen</th>
                                    <th class="c">Status</th>
                                    <th>Actions</th>
                                </tr>
                                <% for (Device d : rows) { %>
                                    <tr class="<%= !d.isIsActive() ? " locked" : "" %>">
                                        <td>
                                            <%= d.getDeviceId() %>
                                        </td>
                                        <td><strong>
                                                <%= Web.esc(d.getDeviceCode()) %>
                                            </strong></td>
                                        <td><code><%= Web.esc(d.getApiKey()) %></code></td>
                                        <td>
                                            <%= Web.esc(d.getLocation() !=null ? d.getLocation() : "-" ) %>
                                        </td>
                                        <td>
                                            <% String rCode = (d.getRoomId() != null) ? roomCodeMap.get(d.getRoomId()) : null; %>
                                            <%= rCode != null ? "<span class=\"tag\">" + Web.esc(rCode) + "</span>" : "<span style='color:#94a3b8'>–</span>" %>
                                        </td>
                                        <td>
                                            <%= d.getLastSeen() !=null ? d.getLastSeen().toString() : "Never" %>
                                        </td>
                                        <td class="c">
                                            <span class="tag <%= d.isIsActive() ? "" : " danger" %>">
                                                <%= d.isIsActive() ? "Active" : "Inactive" %>
                                            </span>
                                        </td>
                                        <td class="ops ops-group">
                                            <button type="button" class="btn-block btn-blue"
                                                onclick="window.location.href='<%= ctx %>/admin/devices/edit?id=<%= d.getDeviceId() %>'">
                                                Edit
                                            </button>

                                            <form method="post" action="<%= ctx %>/admin/devices/toggle">
                                                <input type="hidden" name="id" value="<%= d.getDeviceId() %>">
                                                <button type="submit" class="btn-block <%= d.isIsActive() ? "btn-orange" : "btn-green" %>">
                                                    <%= d.isIsActive() ? "Lock" : "Unlock" %>
                                                </button>
                                            </form>

                                            <form method="post" action="<%= ctx %>/admin/devices/delete"
                                                onsubmit="return confirm('Delete this device?');">
                                                <input type="hidden" name="id" value="<%= d.getDeviceId() %>">
                                                <button type="submit" class="btn-block btn-red">Delete</button>
                                            </form>
                                        </td>
                                    </tr>
                                    <% } %>
                                        <% if (rows==null || rows.isEmpty()) { %>
                                            <tr>
                                                <td colspan="8" class="c">No devices match the filter</td>
                                            </tr>
                                            <% } %>
                            </table>
                        </div>

                        <div class="pager">
                            <% for (int p=1; p <=totalPages; p++) { %>
                                <% if (p==currentPage) { %><b>
                                        <%= p %>
                                    </b>
                                    <% } else { %><a href="?<%= qs %>&page=<%= p %>">
                                            <%= p %>
                                        </a>
                                        <% } %>
                                            <% } %>
                        </div>
                    </div>
                </body>

                </html>