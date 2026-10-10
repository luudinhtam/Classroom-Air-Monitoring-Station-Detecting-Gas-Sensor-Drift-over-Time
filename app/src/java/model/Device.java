package model;

import java.sql.Timestamp;

public class Device {
    private int deviceId;
    private String deviceCode;
    private String apiKey;
    private String location;
    private Timestamp lastSeen;
    private boolean isActive = true;

    public Device() {
    }

    public Device(int deviceId, String deviceCode, String apiKey, String location, Timestamp lastSeen, boolean isActive) {
        this.deviceId = deviceId;
        this.deviceCode = deviceCode;
        this.apiKey = apiKey;
        this.location = location;
        this.lastSeen = lastSeen;
        this.isActive = isActive;
    }

    public int getDeviceId() {
        return deviceId;
    }

    public void setDeviceId(int deviceId) {
        this.deviceId = deviceId;
    }

    public String getDeviceCode() {
        return deviceCode;
    }

    public void setDeviceCode(String deviceCode) {
        this.deviceCode = deviceCode;
    }

    public String getApiKey() {
        return apiKey;
    }

    public void setApiKey(String apiKey) {
        this.apiKey = apiKey;
    }

    public String getLocation() {
        return location;
    }

    public void setLocation(String location) {
        this.location = location;
    }

    public Timestamp getLastSeen() {
        return lastSeen;
    }

    public void setLastSeen(Timestamp lastSeen) {
        this.lastSeen = lastSeen;
    }

    public boolean isIsActive() {
        return isActive;
    }

    public void setIsActive(boolean isActive) {
        this.isActive = isActive;
    }
}
