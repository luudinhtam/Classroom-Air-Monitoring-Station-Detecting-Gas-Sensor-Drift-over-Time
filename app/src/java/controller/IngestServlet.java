package controller;

import java.io.*;
import java.sql.Timestamp;
import javax.servlet.*;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import dao.*;
import model.AirSession;
import service.AirRuleEngine;

/**
 * The only endpoint the board talks to. It checks the device key, drops a
 * packet it has already stored, saves the session, asks the rule engine for a
 * label and raises an alert when the label is not the normal one.
 *
 * The body is flat JSON, parsed by hand so the project needs no extra library:
 * {"device":"Air-01","seq":12,"measured_at":1750000000,"gas_a_raw":0,"gas_b_raw":0}
 */



@WebServlet("/api/ingest")
public class IngestServlet extends HttpServlet {

    private final AirSessionDAO dao = new AirSessionDAO();
    private final AirRuleEngine engine = new AirRuleEngine();
    private final DeviceDAO devices = new DeviceDAO();
    private final LabelDAO labels = new LabelDAO();
    private final AlertDAO alerts = new AlertDAO();

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        resp.setContentType("application/json;charset=UTF-8");
        String body = readBody(req);
        String key = req.getHeader("X-API-Key");
        String code = str(body, "device");

        // Kiem tra thiet bi hop le
        Integer deviceId = devices.findIdByCodeAndKey(code, key);
        if (deviceId == null) {
            devices.logRejected(body, code, "unknown device or wrong key");
            resp.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            resp.getWriter().write("{\"ok\":false,\"error\":\"auth\"}");
            return;
        }
        
        // Neu thiet bi hop le, tien hanh giai goi tin va luu vao 1 object Session
        try {
            AirSession o = new AirSession();
            o.setDeviceId(deviceId.intValue());
            o.setDeviceSeq((int) num(body, "seq"));
            o.setMeasuredAt(new Timestamp((long) num(body, "measured_at") * 1000L));
            o.setGasARaw((int) num(body, "gas_a_raw"));
            o.setGasBRaw((int) num(body, "gas_b_raw"));
            o.setGasABase((int) num(body, "gas_a_base"));
            o.setGasADelta(num(body, "gas_a_delta"));
            o.setTempC(num(body, "temp_c"));
            o.setHumidPct(num(body, "humid_pct"));
            o.setBaseShift(num(body, "base_shift"));
            o.setWarm("1".equals(str(body, "warm")));
            
            // Luu vao table Session
            int id = dao.insert(o);
            if (id == -1) { // same sequence number arrived twice
                resp.getWriter().write("{\"ok\":true,\"duplicate\":true}");
                return;
            }
            o.setSessionId(id);
            
            // Gan nhan cho Session, luu vao table Label
            String label = engine.classify(o);
            labels.insert(id, label, "RULE", null, null);
            
            // Cap nhat gia tri Last Seen cho object Device
            devices.touch(deviceId.intValue());
            
            // Khai bao tinh trang/muc do nghiem trong cua object Label
            String sev = engine.severityOf(label);
            // Kiem tra tinh trang/muc do nghiem cua object Label
            if (!"INFO".equals(sev)) {
                alerts.insert(id, label, sev, engine.messageOf(label));
            }
            resp.getWriter().write("{\"ok\":true,\"session_id\":" + id
                    + ",\"label\":\"" + label + "\"}");

        } catch (Exception e) {
            devices.logRejected(body, code, "bad payload: " + e.getMessage());
            resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            resp.getWriter().write("{\"ok\":false,\"error\":\"payload\"}");
        }
    }

    private String readBody(HttpServletRequest req) throws IOException {
        StringBuilder sb = new StringBuilder();
        BufferedReader r = req.getReader();
        String line;
        while ((line = r.readLine()) != null) sb.append(line);
        return sb.toString();
    }

    /** Reads a string field out of flat JSON without any library. */
    private String str(String json, String field) {
        String needle = "\"" + field + "\"";
        int i = json.indexOf(needle);
        if (i < 0) return null;
        int c = json.indexOf(':', i + needle.length());
        if (c < 0) return null;
        int a = json.indexOf('"', c);
        if (a < 0) return null;
        int b = json.indexOf('"', a + 1);
        return b < 0 ? null : json.substring(a + 1, b);
    }

    /** Reads a numeric field out of flat JSON. */
    
/** Reads a numeric field out of flat JSON. */
    private double num(String json, String field) {
        String needle = "\"" + field + "\"";
        int i = json.indexOf(needle);

        if (i < 0) {
            throw new IllegalArgumentException("missing field " + field);
        }

        int c = json.indexOf(':', i + needle.length());

        if (c < 0) {
            throw new IllegalArgumentException("invalid field " + field);
        }

        int s = c + 1;

        // Skip whitespace before the number
        while (s < json.length() && Character.isWhitespace(json.charAt(s))) {
            s++;
        }

        int e = s;

        // Read the number
        while (e < json.length()
                && "-+.0123456789eE".indexOf(json.charAt(e)) >= 0) {
            e++;
        }

        if (s == e) {
            throw new IllegalArgumentException("empty String: " + field);
        }

        return Double.parseDouble(json.substring(s, e));
    }

}
