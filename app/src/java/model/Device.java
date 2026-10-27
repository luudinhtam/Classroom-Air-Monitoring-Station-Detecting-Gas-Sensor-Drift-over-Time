package model;

import java.sql.Timestamp;

public class Device {
    private int deviceId;
    private String deviceCode;
    private String apiKey;
    private String location;
    private String note;
    private Timestamp lastSeen;
    private boolean isActive = true;
    private Integer roomId;

    public Device() {
    }

    public Device(int deviceId, String deviceCode, String apiKey, Timestamp lastSeen, boolean isActive) {
        this(deviceId, deviceCode, apiKey, lastSeen, isActive, null);
    }

    public Device(int deviceId, String deviceCode, String apiKey, Timestamp lastSeen, boolean isActive, Integer roomId) {
        this.deviceId = deviceId;
        this.deviceCode = deviceCode;
        this.apiKey = apiKey;
        this.lastSeen = lastSeen;
        this.isActive = isActive;
        this.roomId = roomId;
    }

    public Device(int deviceId, String deviceCode, String apiKey, String note, Timestamp lastSeen, boolean isActive) {
        this(deviceId, deviceCode, apiKey, lastSeen, isActive, null);
        this.note = note;
        this.location = note;
    }

    public Device(int deviceId, String deviceCode, String apiKey, String note, Timestamp lastSeen, boolean isActive, Integer roomId) {
        this(deviceId, deviceCode, apiKey, lastSeen, isActive, roomId);
        this.note = note;
        this.location = note;
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

    public String getNote() {
        return note != null ? note : location;
    }

    public void setNote(String note) {
        this.note = note;
        this.location = note;
    }

    public String getLocation() {
        return getNote();
    }

    public void setLocation(String location) {
        this.location = location;
        this.note = location;
    }

    public Timestamp getLastSeen() {
        return lastSeen;
    }

    public void setLastSeen(Timestamp lastSeen) {
        this.lastSeen = lastSeen;
    }

    private String roomCode;
    private String roomName;
    private String deviceType;
    private String status;
    private Double temp;
    private Double humidity;

    public boolean isIsActive() {
        return isActive;
    }

    public void setIsActive(boolean isActive) {
        this.isActive = isActive;
    }

    public Integer getRoomId() {
        return roomId;
    }

    public void setRoomId(Integer roomId) {
        this.roomId = roomId;
    }

    public String getRoomCode() {
        return roomCode;
    }

    public void setRoomCode(String roomCode) {
        this.roomCode = roomCode;
    }

    public String getRoomName() {
        return roomName;
    }

    public void setRoomName(String roomName) {
        this.roomName = roomName;
    }

    public String getDeviceType() {
        return deviceType;
    }

    public void setDeviceType(String deviceType) {
        this.deviceType = deviceType;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public Double getTemp() {
        return temp;
    }

    public void setTemp(Double temp) {
        this.temp = temp;
    }

    public Double getHumidity() {
        return humidity;
    }

    public void setHumidity(Double humidity) {
        this.humidity = humidity;
    }
}
