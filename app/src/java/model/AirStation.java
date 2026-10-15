package model;

import java.sql.Timestamp;


public class AirStation {
    private int stationId;
    private String code;
    private String name;
    private String location;
    
    private float coWarningThreshold;
    private float co2WarningThreshold;
    
    private float maxBaselineDrift;
    
    private String deviceCode;
    
    private String note;
    private boolean active;
    private Timestamp createdAt;

    public AirStation() {
    }

    public AirStation(int stationId, String code, String name, String location, float coWarningThreshold, float co2WarningThreshold, float maxBaselineDrift, String deviceCode, String note, boolean active, Timestamp createdAt) {
        this.stationId = stationId;
        this.code = code;
        this.name = name;
        this.location = location;
        this.coWarningThreshold = coWarningThreshold;
        this.co2WarningThreshold = co2WarningThreshold;
        this.maxBaselineDrift = maxBaselineDrift;
        this.deviceCode = deviceCode;
        this.deviceCode = deviceCode;
        this.note = note;
        this.active = active;
        this.createdAt = createdAt;
    }

    public int getStationId() {
        return stationId;
    }

    public void setStationId(int stationId) {
        this.stationId = stationId;
    }

    public String getCode() {
        return code;
    }
    public void setCode(String code) {
        this.code = code;
    }

    public String getName() {
        return name;
    }
    public void setName(String name) {
        this.name = name;
    }

    public String getNote() {
        return note;
    }
    public void setNote(String note) {
        this.note = note;
    }

    public boolean isActive() {
        return active;
    }

    public void setActive(boolean active) {
        this.active = active;
    }

    public Timestamp getCreatedAt() {
        return createdAt;
    }
    public void setCreatedAt(Timestamp createdAt) {
        this.createdAt = createdAt;
    }

    public String getLocation() {
        return location;
    }

    public void setLocation(String location) {
        this.location = location;
    }

    public float getCoWarningThreshold() {
        return coWarningThreshold;
    }

    public void setCoWarningThreshold(float coWarningThreshold) {
        this.coWarningThreshold = coWarningThreshold;
    }

    public float getCo2WarningThreshold() {
        return co2WarningThreshold;
    }

    public void setCo2WarningThreshold(float co2WarningThreshold) {
        this.co2WarningThreshold = co2WarningThreshold;
    }

    public float getMaxBaselineDrift() {
        return maxBaselineDrift;
    }

    public void setMaxBaselineDrift(float maxBaselineDrift) {
        this.maxBaselineDrift = maxBaselineDrift;
    }

    public String getDeviceCode() {
        return deviceCode;
    }

    public void setDeviceCode(String deviceCode) {
        this.deviceCode = deviceCode;
    }
    
    
    
}
