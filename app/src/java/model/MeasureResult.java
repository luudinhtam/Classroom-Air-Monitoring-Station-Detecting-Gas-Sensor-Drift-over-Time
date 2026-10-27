package model;

import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.List;

/**
 * Doi tuong ket qua do tra ve cho web hoac service.
 */
public class MeasureResult {
    private int commandId;
    private String status;
    private Integer sessionId;
    private Timestamp measuredAt;
    private Double temperature;
    private Double humid;
    private Integer co;
    private Integer co2;
    private List<AirAlert> alerts = new ArrayList<>();

    public MeasureResult() {
    }

    public MeasureResult(int commandId, String status) {
        this.commandId = commandId;
        this.status = status;
    }

    public int getCommandId() {
        return commandId;
    }

    public void setCommandId(int commandId) {
        this.commandId = commandId;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public Integer getSessionId() {
        return sessionId;
    }

    public void setSessionId(Integer sessionId) {
        this.sessionId = sessionId;
    }

    public Timestamp getMeasuredAt() {
        return measuredAt;
    }

    public void setMeasuredAt(Timestamp measuredAt) {
        this.measuredAt = measuredAt;
    }

    public Double getTemperature() {
        return temperature;
    }

    public void setTemperature(Double temperature) {
        this.temperature = temperature;
    }

    public Double getHumid() {
        return humid;
    }

    public void setHumid(Double humid) {
        this.humid = humid;
    }

    public Integer getCo() {
        return co;
    }

    public void setCo(Integer co) {
        this.co = co;
    }

    public Integer getCo2() {
        return co2;
    }

    public void setCo2(Integer co2) {
        this.co2 = co2;
    }

    public List<AirAlert> getAlerts() {
        return alerts;
    }

    public void setAlerts(List<AirAlert> alerts) {
        this.alerts = alerts != null ? alerts : new ArrayList<AirAlert>();
    }
}
