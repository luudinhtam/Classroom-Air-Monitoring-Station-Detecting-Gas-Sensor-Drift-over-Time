package service;

import model.AirSession;

/**
 * The labelling rule engine. It reads one session and returns a label code.
 * Thresholds live in one place so a staff member can tune them later without
 * touching any other class. The order of the checks matters: the narrower
 * cases are tested first and the normal label is the fallback.
 */
public class AirRuleEngine {

    public String classify(AirSession o) {
        if (o.getGasARaw() >= 620
                && o.getGasADelta() >= 300
                && o.getGasBRaw() >= 340) return "HIGH";

        if (o.getBaseShift() >= 14
                && o.getGasABase() >= 300
                && o.getGasARaw() >= 300) return "DRIFTED";

        if (o.getTempC() >= 33
                && o.getGasADelta() >= 30
                && o.getHumidPct() <= 58) return "TEMP_EFFECT";

        if (o.isWarm() == false
                && o.getGasARaw() >= 420
                && o.getGasADelta() >= 150) return "WARMUP";

        if (o.getGasARaw() >= 300
                && o.getGasADelta() >= 60) return "RAISED";

        return "BASE";
    }

    /** Severity shown on the dashboard for a given label. */
    public String severityOf(String label) {
        if ("BASE".equals(label)) return "INFO";
        if ("HIGH".equals(label)) return "CRITICAL";
        if ("DRIFTED".equals(label)) return "CRITICAL";
        if ("TEMP_EFFECT".equals(label)) return "WARN";
        if ("WARMUP".equals(label)) return "WARN";
        if ("RAISED".equals(label)) return "WARN";
        return "INFO";
    }

    /** Text stored on the alert row. Kept in English like the rest of the code. */
    public String messageOf(String label) {
        return "Rule engine classified this session as " + label;
    }
}
