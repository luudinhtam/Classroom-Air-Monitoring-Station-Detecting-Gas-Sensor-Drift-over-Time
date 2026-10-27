package model;

import java.sql.Timestamp;

public class AirSession {

    private int sessionId;
    private int deviceId;
    private int deviceSeq;
    private Timestamp measuredAt;
    private Timestamp ingestedAt;
    private boolean sample;
    private String labelCode; // joined from the label table, latest label wins
    private Double temperature;
    private Double humid;
    private Integer co;
    private Integer co2;
    private String note;
    private String deviceCode;

    // Compatibility fields for legacy controllers/views
    private double tempC;
    private double humidPct;
    private int gasARaw;
    private int gasBRaw;
    private int gasABase;
    private double gasADelta;
    private double baseShift;
    private boolean warm;

    public int getSessionId() { return sessionId; }
    public void setSessionId(int v) { this.sessionId = v; }

    public int getDeviceId() { return deviceId; }
    public void setDeviceId(int v) { this.deviceId = v; }

    public int getDeviceSeq() { return deviceSeq; }
    public void setDeviceSeq(int v) { this.deviceSeq = v; }

    public Timestamp getMeasuredAt() { return measuredAt; }
    public void setMeasuredAt(Timestamp v) { this.measuredAt = v; }

    public Timestamp getIngestedAt() { return ingestedAt != null ? ingestedAt : measuredAt; }
    public void setIngestedAt(Timestamp v) { this.ingestedAt = v; }

    public boolean isSample() { return sample; }
    public void setSample(boolean v) { this.sample = v; }

    public String getLabelCode() { return labelCode; }
    public void setLabelCode(String v) { this.labelCode = v; }

    public Double getTemperature() { return temperature != null ? temperature : (tempC != 0 ? tempC : null); }
    public void setTemperature(Double temperature) { this.temperature = temperature; if (temperature != null) this.tempC = temperature; }

    public Double getHumid() { return humid != null ? humid : (humidPct != 0 ? humidPct : null); }
    public void setHumid(Double humid) { this.humid = humid; if (humid != null) this.humidPct = humid; }

    public Integer getCo() { return co != null ? co : (gasBRaw != 0 ? gasBRaw : null); }
    public void setCo(Integer co) { this.co = co; if (co != null) this.gasBRaw = co; }

    public Integer getCo2() { return co2 != null ? co2 : (gasARaw != 0 ? gasARaw : null); }
    public void setCo2(Integer co2) { this.co2 = co2; if (co2 != null) this.gasARaw = co2; }

    // Compatibility getters & setters
    public double getTempC() { return temperature != null ? temperature : tempC; }
    public void setTempC(double v) { this.tempC = v; this.temperature = v; }

    public double getHumidPct() { return humid != null ? humid : humidPct; }
    public void setHumidPct(double v) { this.humidPct = v; this.humid = v; }

    public int getGasARaw() { return co2 != null ? co2 : gasARaw; }
    public void setGasARaw(int v) { this.gasARaw = v; this.co2 = v; }

    public int getGasBRaw() { return co != null ? co : gasBRaw; }
    public void setGasBRaw(int v) { this.gasBRaw = v; this.co = v; }

    public int getGasABase() { return gasABase; }
    public void setGasABase(int v) { this.gasABase = v; }

    public double getGasADelta() { return gasADelta; }
    public void setGasADelta(double v) { this.gasADelta = v; }

    public double getBaseShift() { return baseShift; }
    public void setBaseShift(double v) { this.baseShift = v; }

    public boolean isWarm() { return warm; }
    public void setWarm(boolean v) { this.warm = v; }

    public String getNote() { return note; }
    public void setNote(String note) { this.note = note; }

    public String getDeviceCode() { return deviceCode; }
    public void setDeviceCode(String deviceCode) { this.deviceCode = deviceCode; }
}
