package controller;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import javax.net.ssl.HttpsURLConnection;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

@WebServlet(name = "ChatbotServlet", urlPatterns = {"/api/chat"})
public class ChatbotServlet extends HttpServlet {

    
    private static final String GEMINI_API_KEY = "";

    // Danh sách các model thử nghiệm theo thứ tự ưu tiên
    private static final String[] CANDIDATE_MODELS = {
        "gemini-flash-latest",
        "gemini-pro-latest"
    };

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        req.setCharacterEncoding("UTF-8");
        resp.setCharacterEncoding("UTF-8");
        resp.setContentType("application/json; charset=UTF-8");

        String userMessage = req.getParameter("message");
        if (userMessage == null || userMessage.trim().isEmpty()) {
            resp.getWriter().write("{\"reply\": \"Please enter your question.\"}");
            return;
        }

        userMessage = userMessage.trim();

        // 1. Lấy API Key
        String apiKey = System.getenv("GEMINI_API_KEY");
        if (apiKey == null || apiKey.trim().isEmpty()) {
            apiKey = System.getProperty("GEMINI_API_KEY");
        }
        if (apiKey == null || apiKey.trim().isEmpty()) {
            apiKey = GEMINI_API_KEY;
        }

        String botAnswer = null;

        // 2. Thử gọi Google Gemini API nếu có key
        if (apiKey != null && !apiKey.trim().isEmpty() && !"YOUR_GEMINI_API_KEY_HERE".equals(apiKey)) {
            for (String model : CANDIDATE_MODELS) {
                try {
                    botAnswer = callGeminiAPI(apiKey, model, userMessage);
                    if (botAnswer != null && !botAnswer.trim().isEmpty()) {
                        break; // Gọi thành công
                    }
                } catch (Exception e) {
                    // Tiếp tục thử model kế tiếp hoặc chuyển sang fallback
                }
            }
        }

        // 3. Nếu Gemini API không khả dụng (hết quota 429, nghẽn mạng 503, lỗi 404),
        // tự động kích hoạt Bộ tri thức chuyên sâu AirRoom (Built-in Knowledge Engine)
        if (botAnswer == null || botAnswer.trim().isEmpty()) {
            botAnswer = getAirRoomSmartReply(userMessage);
        }

        resp.getWriter().write("{\"reply\": \"" + escapeJson(botAnswer) + "\"}");
    }

    /**
     * Gửi request POST tới Google Gemini generateContent REST API
     */
    private String callGeminiAPI(String apiKey, String modelName, String userQuestion) throws Exception {
        String endpoint = "https://generativelanguage.googleapis.com/v1beta/models/" 
                + modelName + ":generateContent?key=" + apiKey;

        URL url = new URL(endpoint);
        HttpsURLConnection conn = (HttpsURLConnection) url.openConnection();
        conn.setRequestMethod("POST");
        conn.setRequestProperty("Content-Type", "application/json; charset=UTF-8");
        conn.setRequestProperty("Accept", "application/json");
        conn.setDoOutput(true);
        conn.setConnectTimeout(2500);
        conn.setReadTimeout(4000);

        String systemContext = "Bạn là trợ lý AI của dự án AirRoom - Trạm giám sát không khí và phát hiện trôi dạt cảm biến (Sensor Drift) tại các phòng học trường Đại học FPT TP.HCM. "
                + "Hãy trả lời ngắn gọn (dưới 100 từ), lịch sự, chính xác bằng tiếng Việt.\\n\\n";

        String prompt = systemContext + "Câu hỏi: " + escapeJson(userQuestion);
        String jsonPayload = "{\"contents\": [{\"parts\": [{\"text\": \"" + prompt + "\"}]}]}";

        try (OutputStream os = conn.getOutputStream()) {
            byte[] input = jsonPayload.getBytes(StandardCharsets.UTF_8);
            os.write(input, 0, input.length);
        }

        int statusCode = conn.getResponseCode();
        if (statusCode < 200 || statusCode >= 300) {
            throw new IOException("HTTP " + statusCode);
        }

        BufferedReader br = new BufferedReader(new InputStreamReader(conn.getInputStream(), StandardCharsets.UTF_8));
        StringBuilder responseSb = new StringBuilder();
        String line;
        while ((line = br.readLine()) != null) {
            responseSb.append(line);
        }
        br.close();

        return extractTextFromGeminiJson(responseSb.toString());
    }

    /**
     * Bộ tri thức chuyên sâu về đề tài AirRoom (Fallback thông minh đảm bảo hệ thống luôn mượt mà)
     */
    private String getAirRoomSmartReply(String q) {
        String query = " " + q.toLowerCase() + " ";

        if (query.contains("co2") || query.contains("carbon dioxide")) {
            return "Trong phòng học đóng kín có máy lạnh của ĐH FPT, nồng độ CO2 tiêu chuẩn là dưới 1000 ppm. Khi CO2 vượt ngưỡng 1000 - 1200 ppm (thường do phòng đông sinh viên thở trong phòng kín), hệ thống sẽ kích hoạt cảnh báo vì không khí bị ngột ngạt, gây buồn ngủ và giảm tập trung.";
        }

        if (query.contains("khí co") || query.contains("khi co") || query.contains("nồng độ co") || query.contains("nong do co") || query.contains("carbon monoxide") || query.contains(" co ")) {
            return "Khí CO là khí độc không màu, không mùi. Trong môi trường phòng học bình thường, nồng độ CO an toàn ở mức 0 - 9 ppm. Khi nồng độ CO vượt ngưỡng 15 - 25 ppm, trạm đo AirRoom sẽ kích hoạt cảnh báo nguy hiểm mức độ WARN hoặc CRITICAL để nhân viên kiểm tra.";
        }

        if (query.contains("chào") || query.contains("chao") || query.contains("hello") || query.contains(" hi ") || query.contains("bạn là ai") || query.contains("ban la ai") || query.contains("ai tư vấn")) {
            return "Xin chào! Tôi là trợ lý AI của trạm giám sát không khí AirRoom (Đại học FPT). Tôi có thể hỗ trợ giải đáp về các chỉ số CO, CO2, độ trôi cảm biến (Sensor Drift), chu kỳ hiệu chuẩn và tình trạng các phòng học. Bạn muốn hỏi gì? 😊";
        }

        if (query.contains("độ trôi") || query.contains("do troi") || query.contains("drift") || query.contains("trôi") || query.contains("troi") || query.contains("sensor drift") || query.contains("mức nền") || query.contains("muc nen")) {
            return "Độ trôi cảm biến (Sensor Drift) là hiện tượng mức đo nền (Baseline) của cảm biến bị lệch dần theo thời gian dù nồng độ khí thực tế không đổi. Trong phòng học ĐH FPT, việc bật/tắt máy lạnh liên tục giữa các ca học gây sốc nhiệt/ẩm (TEMP_EFFECT), khiến cảm biến bị trôi nhanh hơn (chu kỳ giữ dung sai ±15% chỉ từ 30 - 45 ngày).";
        }

        if (query.contains("hiệu chuẩn") || query.contains("hieu chuan") || query.contains("calibration")) {
            return "Hiệu chuẩn (Calibration) là thao tác căn chỉnh lại mức nền chuẩn (Baseline) cho cảm biến sau một thời gian hoạt động. Đối với phòng học tại trường FPT, cảm biến khí cần được hiệu chuẩn định kỳ sau mỗi 30 - 45 ngày để đảm bảo độ chính xác.";
        }

        if (query.contains("cửa sổ") || query.contains("cua so") || query.contains("empty window") || query.contains("phòng trống") || query.contains("phong trong")) {
            return "Cửa sổ phòng trống (Empty Window) là khung giờ phòng học không có sinh viên (thường là ban đêm từ 21:00 đến 06:00 sáng hoặc giờ nghỉ trưa). Đây là thời điểm không khí ổn định nhất, không bị nhiễu bởi hơi thở con người, giúp hệ thống tự động xác định mức nền thực (Baseline) và phát hiện trôi dạt cảm biến.";
        }

        if (query.contains("trạm") || query.contains("tram") || query.contains("station") || query.contains("phòng") || query.contains("phong") || query.contains("tọa độ") || query.contains("toa do") || query.contains("vị trí") || query.contains("vi tri")) {
            return "Hệ thống AirRoom quản lý các trạm đo đặt tại các phòng học trong khuôn viên ĐH FPT TP.HCM (Tòa Alpha, Beta, Innovation...). Tài khoản ADMIN và STATION_MANAGER có thể xem và chỉnh sửa tọa độ các phòng trực tiếp trên mục Map (Bản đồ) bằng cách click vào trạm và chọn 'Change Coordinates'.";
        }

        if (query.contains("nhiệt độ") || query.contains("nhiet do") || query.contains("độ ẩm") || query.contains("do am") || query.contains("temp") || query.contains("sốc nhiệt") || query.contains("soc nhiet")) {
            return "Nhiệt độ và độ ẩm ảnh hưởng rất lớn đến độ nhạy của cảm biến bán dẫn. Khi phòng học tắt máy lạnh, nhiệt độ và độ ẩm tăng đột ngột kích hoạt nhãn 'TEMP_EFFECT' trên hệ thống. Thuật toán AirRuleEngine sẽ phân biệt rõ giữa việc nồng độ khí tăng thật hay chỉ do sốc nhiệt.";
        }

        return "Cảm ơn câu hỏi của bạn về hệ thống quan trắc không khí AirRoom (ĐH FPT). Bạn có thể hỏi tôi chi tiết hơn về: nồng độ khí CO, CO2, hiện tượng trôi cảm biến (Sensor Drift), cửa sổ phòng trống (Empty Window) hoặc cách hiệu chuẩn trạm đo nhé! 😊";
    }

    private String extractTextFromGeminiJson(String json) {
        Pattern pattern = Pattern.compile("\"text\":\\s*\"((?:[^\"\\\\]|\\\\.)*)\"");
        Matcher matcher = pattern.matcher(json);
        if (matcher.find()) {
            String rawText = matcher.group(1);
            return unescapeJson(rawText);
        }
        return null;
    }

    private static String escapeJson(String raw) {
        if (raw == null) return "";
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < raw.length(); i++) {
            char ch = raw.charAt(i);
            switch (ch) {
                case '"': sb.append("\\\""); break;
                case '\\': sb.append("\\\\"); break;
                case '\b': sb.append("\\b"); break;
                case '\f': sb.append("\\f"); break;
                case '\n': sb.append("\\n"); break;
                case '\r': sb.append("\\r"); break;
                case '\t': sb.append("\\t"); break;
                default:
                    if (ch < ' ') {
                        sb.append(String.format("\\u%04x", (int) ch));
                    } else {
                        sb.append(ch);
                    }
            }
        }
        return sb.toString();
    }

    private static String unescapeJson(String text) {
        if (text == null) return "";
        return text.replace("\\n", "\n")
                   .replace("\\r", "\r")
                   .replace("\\t", "\t")
                   .replace("\\\"", "\"")
                   .replace("\\\\", "\\");
    }
}
