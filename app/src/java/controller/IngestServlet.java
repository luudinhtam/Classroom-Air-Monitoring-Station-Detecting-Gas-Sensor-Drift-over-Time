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
            o.setDeviceCode(code);

            Double seqVal = optNum(body, "seq");
            if (seqVal == null) seqVal = optNum(body, "device_seq");
            o.setDeviceSeq(seqVal != null ? seqVal.intValue() : 0);

            Double timeVal = optNum(body, "measured_at");
            Timestamp measuredAt = (timeVal != null && timeVal > 0)
                    ? new Timestamp((long) (timeVal * 1000L))
                    : new Timestamp(System.currentTimeMillis());
            o.setMeasuredAt(measuredAt);

            // CO2 (hoặc gas_a_raw)
            Double co2Val = optNum(body, "co2");
            if (co2Val == null) co2Val = optNum(body, "gas_a_raw");
            int co2 = co2Val != null ? co2Val.intValue() : 0;
            o.setCo2(co2);
            o.setGasARaw(co2);

            // CO (hoặc gas_b_raw)
            Double coVal = optNum(body, "co");
            if (coVal == null) coVal = optNum(body, "gas_b_raw");
            int co = coVal != null ? coVal.intValue() : 0;
            o.setCo(co);
            o.setGasBRaw(co);

            // Temperature (hoặc temp_c)
            Double tempVal = optNum(body, "temperature");
            if (tempVal == null) tempVal = optNum(body, "temp_c");
            double temp = tempVal != null ? tempVal : 0.0;
            o.setTemperature(temp);
            o.setTempC(temp);

            // Humid (hoặc humid_pct)
            Double humidVal = optNum(body, "humid");
            if (humidVal == null) humidVal = optNum(body, "humid_pct");
            double hum = humidVal != null ? humidVal : 0.0;
            o.setHumid(hum);
            o.setHumidPct(hum);

            // Optional fields nếu có
            Double gasABase = optNum(body, "gas_a_base");
            if (gasABase != null) o.setGasABase(gasABase.intValue());
            Double gasADelta = optNum(body, "gas_a_delta");
            if (gasADelta != null) o.setGasADelta(gasADelta);
            Double baseShift = optNum(body, "base_shift");
            if (baseShift != null) o.setBaseShift(baseShift);
            o.setWarm("1".equals(str(body, "warm")));
            o.setSample(true);
            
            // Luu vao table Air_Session
            int id = dao.insert(o);
            if (id == -1) { // same sequence number arrived twice
                resp.getWriter().write("{\"ok\":true,\"duplicate\":true}");
                return;
            }
            o.setSessionId(id);
            
            // Cap nhat gia tri Last Seen cho thiet bi
            devices.touch(deviceId.intValue());
            
            // Phan loai rule engine
            String label = engine.classify(o);
            o.setLabelCode(label);

            // Kiem tra nguong an toan de tao Air_Alert (alert_code IN ('TEMPERATURE', 'HUMID', 'CO2', 'CO'))
            if (temp >= 32.0) {
                alerts.insert(id, "TEMPERATURE", "Room temperature exceeded warning threshold: " + temp + "°C");
            }
            if (hum >= 80.0) {
                alerts.insert(id, "HUMID", "Room humidity exceeded warning threshold: " + hum + "%");
            }
            if (co2 >= 1000 || "HIGH".equals(label) || "DRIFTED".equals(label)) {
                alerts.insert(id, "CO2", "Room CO2 level exceeded warning threshold: " + co2 + " ppm");
            }
            if (co >= 9) {
                alerts.insert(id, "CO", "Room CO concentration exceeded safety threshold: " + co + " ppm");
            }

            resp.getWriter().write("{\"ok\":true,\"session_id\":" + id
                    + ",\"label\":\"" + label + "\"}");

        } catch (Exception e) {
            devices.logRejected(body, code, "bad payload: " + e.getMessage());
            resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            resp.getWriter().write("{\"ok\":false,\"error\":\"payload\"}");
        }
    }

    private Double optNum(String json, String field) {
        try {
            return num(json, field);
        } catch (Exception e) {
            return null;
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
