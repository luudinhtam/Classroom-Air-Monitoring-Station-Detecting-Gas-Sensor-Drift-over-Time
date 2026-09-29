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
    private int gasARaw;      // column gas_a_raw
    private int gasBRaw;      // column gas_b_raw
    private int gasABase;     // column gas_a_base
    private double gasADelta; // column gas_a_delta
    private double tempC;     // column temp_c
    private double humidPct;  // column humid_pct
    private double baseShift; // column base_shift
    private boolean warm;     // column warm

    public int getSessionId() { return sessionId; }
    public void setSessionId(int v) { this.sessionId = v; }

    public int getDeviceId() { return deviceId; }
    public void setDeviceId(int v) { this.deviceId = v; }

    public int getDeviceSeq() { return deviceSeq; }
    public void setDeviceSeq(int v) { this.deviceSeq = v; }

    public Timestamp getMeasuredAt() { return measuredAt; }
    public void setMeasuredAt(Timestamp v) { this.measuredAt = v; }

    public Timestamp getIngestedAt() { return ingestedAt; }
    public void setIngestedAt(Timestamp v) { this.ingestedAt = v; }

    public boolean isSample() { return sample; }
    public void setSample(boolean v) { this.sample = v; }

    public String getLabelCode() { return labelCode; }
    public void setLabelCode(String v) { this.labelCode = v; }

    public int getGasARaw() { return gasARaw; }
    public void setGasARaw(int v) { this.gasARaw = v; }

    public int getGasBRaw() { return gasBRaw; }
    public void setGasBRaw(int v) { this.gasBRaw = v; }

    public int getGasABase() { return gasABase; }
    public void setGasABase(int v) { this.gasABase = v; }

    public double getGasADelta() { return gasADelta; }
    public void setGasADelta(double v) { this.gasADelta = v; }

    public double getTempC() { return tempC; }
    public void setTempC(double v) { this.tempC = v; }

    public double getHumidPct() { return humidPct; }
    public void setHumidPct(double v) { this.humidPct = v; }

    public double getBaseShift() { return baseShift; }
    public void setBaseShift(double v) { this.baseShift = v; }

    public boolean isWarm() { return warm; }
    public void setWarm(boolean v) { this.warm = v; }
}
