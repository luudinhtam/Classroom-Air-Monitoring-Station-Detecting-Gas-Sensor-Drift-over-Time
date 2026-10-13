package controller;
import java.io.IOException;
import java.util.List;
import javax.servlet.*;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import dao.AirSessionDAO;
import java.sql.Timestamp;
import java.time.LocalDateTime;
import model.AirSession;
import util.Web;

/**
 * One controller for the session list. It never writes HTML: it reads the
 * query string, calls the DAO and forwards to the JSP. This is the MVC2 shape
 * the subject asks for.
 */
@WebServlet(urlPatterns = { "/sessions", 
                            "/sessions/create", 
                            "/sessions/edit", 
                            "/sessions/save",
                            "/sessions/delete",
                            "/sessions/detail",
                            "/session/detail",
                            "/sessions/export" })


public class AirSessionListServlet extends HttpServlet {

    private static final int PAGE_SIZE = 20;
    private final AirSessionDAO dao = new AirSessionDAO();
    private final dao.DeviceDAO deviceDAO = new dao.DeviceDAO();
    private final dao.LabelDAO labelDAO = new dao.LabelDAO();
    
    private String action(HttpServletRequest req) {
        String path = req.getRequestURI().substring(req.getContextPath().length());
        if (path.startsWith("/sessions")) {
            return path.substring("/sessions".length());
        }
        if (path.startsWith("/session")) {
            return path.substring("/session".length());
        }
        return path;
    }
    
    private void showForm(HttpServletRequest req, HttpServletResponse resp, AirSession session)
        throws ServletException, IOException {
    req.setAttribute("editSession", session);
    req.setAttribute("devices", dao.listDevices());
    req.getRequestDispatcher("/WEB-INF/views/sessionForm.jsp").forward(req, resp);
    }
    
     private void showDetail(HttpServletRequest req, HttpServletResponse resp, AirSession session)
        throws ServletException, IOException {
    req.setAttribute("detail", session);
    req.setAttribute("device", deviceDAO.findById(session.getDeviceId()));
    req.setAttribute("timeline", dao.findTimeline(session.getDeviceId(), 15));
    req.setAttribute("labelHistory", labelDAO.findBySessionId(session.getSessionId()));
    req.getRequestDispatcher("/WEB-INF/views/sessionDetail.jsp").forward(req, resp);
    }
    
    private void showList(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String label = Web.trimmed(req, "label");
        Integer deviceId = Web.optionalInt(req, "device");
        
        int page = Web.intParam(req, "page", 1);
        if (page < 1) page = 1;

        List<AirSession> rows = dao.search(label, deviceId, page, PAGE_SIZE);
        int total = dao.count(label, deviceId);
        int pages = (total + PAGE_SIZE - 1) / PAGE_SIZE;

        req.setAttribute("rows", rows);
        req.setAttribute("page", Integer.valueOf(page));
        req.setAttribute("pages", Integer.valueOf(pages));
        req.setAttribute("total", Integer.valueOf(total));
        req.setAttribute("label", label);
        
        req.getRequestDispatcher("/WEB-INF/views/sessionList.jsp").forward(req, resp);
    }
    
    

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        
        String action = action(req);
        
        if("/create".equals(action)){
            showForm(req, resp, null);
            return;
        }
        
        
        if("/edit".equals(action)){
            int id =  Web.intParam(req, "id", 0);
            AirSession session = dao.findById(id);
            if (session == null){
                resp.sendRedirect(req.getContextPath() + "/sessions");
                return;
            }
            showForm(req, resp, session);
            return;
        }
        if("/detail".equals(action)){
            int id = Web.intParam(req, "id", 0);
            AirSession session = dao.findById(id);
            if (session == null){
                Web.flash(req, "Khong tim thay phien do #" + id);
                resp.sendRedirect(req.getContextPath() + "/sessions");
                return;
            }
            showDetail(req, resp, session);
            return;
        }

        if ("/export".equals(action)) {
            exportCsv(req, resp);
            return;
        }
        showList(req, resp);
        
    }   
    
    
    @Override
protected void doPost(HttpServletRequest req, HttpServletResponse resp)
        throws ServletException, IOException {
    req.setCharacterEncoding("UTF-8");
    String action = action(req);

    try {
        if ("/save".equals(action)) {
            int sessionId = Web.intParam(req, "sessionId", 0);
            int gasARaw = Web.intParam(req, "gasARaw", 0);
            int gasBRaw = Web.intParam(req, "gasBRaw", 0);
            int gasABase = Web.intParam(req, "gasABase", 0);
            
            // Lấy đúng deviceId do người dùng chọn từ form (<select name="deviceId">)
            int deviceId = Web.intParam(req, "deviceId", 1);

            double tempC = 0.0;
            double humidPct = 0.0;
            try { tempC = Double.parseDouble(req.getParameter("tempC")); } catch (Exception ignored) {}
            try { humidPct = Double.parseDouble(req.getParameter("humidPct")); } catch (Exception ignored) {}
            
            String labelCode = Web.trimmed(req, "labelCode");

            AirSession session = new AirSession();
            session.setSessionId(sessionId);
            session.setGasARaw(gasARaw);
            session.setGasBRaw(gasBRaw);
            session.setGasABase(gasABase);
            
            session.setGasADelta((double)(gasARaw - gasABase));
            session.setTempC(tempC);
            session.setHumidPct(humidPct);
            
            double baseShift = gasABase > 0 ? ((double)(gasARaw - gasABase) / gasABase) * 100 : 0.0;
            session.setBaseShift(baseShift);
            session.setWarm(false);
            session.setDeviceId(deviceId); // Truyền deviceId chính xác
            session.setLabelCode(labelCode);

            if (sessionId == 0) {
                // --- THAO TÁC THÊM MỚI ---
                // Sử dụng timestamp làm device_seq để không bị trùng lặp khóa độc lập (tránh lỗi xung đột)
                int uniqueSeq = (int) (System.currentTimeMillis() % Integer.MAX_VALUE);
                session.setDeviceSeq(uniqueSeq);
                
                session.setMeasuredAt(Timestamp.valueOf(LocalDateTime.now())); 
                session.setSample(true);
                
                int result = dao.insert(session);
                if (result == -1) {
                    req.setAttribute("error", "Lỗi: Không thể thêm mới phiên đo do xung đột dữ liệu.");
                    showForm(req, resp, null);
                    return;
                }
            } else {
                // --- THAO TÁC CHỈNH SỬA ---
                AirSession oldSession = dao.findById(sessionId);
                session.setDeviceSeq((int) (System.currentTimeMillis() % Integer.MAX_VALUE));
                String oldLabel = (oldSession != null && oldSession.getLabelCode() != null) ? oldSession.getLabelCode().trim() : "";

                // CHỈ kiểm tra lý do KHI VÀ CHỈ KHI nhãn mới khác nhãn cũ
                if (!labelCode.equals(oldLabel)) {
                    String editReason = Web.trimmed(req, "editReason");

                    // 1. CHỐT CHẶN BẮT BUỘC >= 5 KÝ TỰ
                    if (editReason == null || editReason.length() < 5) {
                        req.setAttribute("error", "Bắt buộc phải nhập lý do (ít nhất 5 ký tự) khi thay đổi nhãn phân loại!");
                        showForm(req, resp, oldSession);
                        return;
                    }

                    // 2. XỬ LÝ LƯU LỊCH SỬ VÀO THUỘC TÍNH NOTE
                    String oldNote = (oldSession != null && oldSession.getNote() != null) ? oldSession.getNote() : "";
                    String timeNow = java.time.LocalDateTime.now().format(java.time.format.DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm"));

                    String newHistoryLine = String.format("[%s] Đổi từ '%s' sang '%s'.\nLý do: %s\n--------------------------------\n", 
                                                           timeNow, oldLabel, labelCode, editReason);

                    // Gắn lịch sử mới (cộng dồn lịch sử cũ) vào đối tượng đang chuẩn bị update
                    session.setNote(newHistoryLine + oldNote);

                    System.out.println("Cập nhật phiên #" + sessionId + " | Đổi nhãn từ [" + oldLabel + "] sang [" + labelCode + "] | Lý do: " + editReason);
                } else {
                    // Nếu không đổi nhãn, vẫn phải giữ lại lịch sử cũ không cho nó bị mất
                    session.setNote(oldSession != null ? oldSession.getNote() : "");
                }

                dao.update(session);
            }
            
            // Lưu thành công thì chuyển hướng về trang danh sách
            resp.sendRedirect(req.getContextPath() + "/sessions");
            return;
        } 
        else if ("/delete".equals(action)) {
            int id = Web.intParam(req, "id", 0);
            dao.delete(id);
            resp.sendRedirect(req.getContextPath() + "/sessions");
            return;
        }
    } catch (Exception e) {
        e.printStackTrace();
        req.setAttribute("error", "Lỗi xử lý hệ thống: " + e.getMessage());
        resp.sendRedirect(req.getContextPath() + "/sessions");
        return;
    }
    }



    private void exportCsv(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        String label = Web.trimmed(req, "label");
        Integer deviceId = Web.optionalInt(req, "device");
        
        // Lấy toàn bộ dữ liệu (Để size là 999999 để lấy hết mà không cần viết hàm mới trong DAO)
        List<AirSession> list = dao.search(label, deviceId, 1, 999999);
        
        // Thiết lập header để trình duyệt hiểu đây là file tải về
        resp.setContentType("text/csv; charset=UTF-8");
        resp.setHeader("Content-Disposition", "attachment; filename=\"sessions_export.csv\"");
        
        // Ghi mã BOM (Byte Order Mark) để Microsoft Excel hiển thị tiếng Việt có dấu chuẩn xác
        resp.getOutputStream().write(239); // 0xEF
        resp.getOutputStream().write(187); // 0xBB
        resp.getOutputStream().write(191); // 0xBF
        
        java.io.PrintWriter out = new java.io.PrintWriter(new java.io.OutputStreamWriter(resp.getOutputStream(), "UTF-8"));
        
        // 1. In dòng Tiêu đề (Header) của file CSV
        out.println("ID,Thoi gian do,Gas A (raw),Gas B (raw),Gas A (base),Delta,Temp (C),Humid (%),Base Shift,Nhan,Ma thiet bi");
        
        // 2. Duyệt danh sách và in từng dòng dữ liệu
        for (AirSession r : list) {
            String lbl = r.getLabelCode() != null ? r.getLabelCode() : "";
            String dev = r.getDeviceCode() != null ? r.getDeviceCode() : String.valueOf(r.getDeviceId());
            String time = r.getMeasuredAt() != null ? r.getMeasuredAt().toString() : "";
            
            // Format từng cột cách nhau bằng dấu phẩy
            out.printf("%d,%s,%d,%d,%d,%.2f,%.2f,%.2f,%.2f,%s,%s\n",
                r.getSessionId(),
                time,
                r.getGasARaw(),
                r.getGasBRaw(),
                r.getGasABase(),
                r.getGasADelta(),
                r.getTempC(),
                r.getHumidPct(),
                r.getBaseShift(),
                lbl,
                dev
            );
        }
        out.flush();
    }

 }
    
    
    
        
    
    
    

