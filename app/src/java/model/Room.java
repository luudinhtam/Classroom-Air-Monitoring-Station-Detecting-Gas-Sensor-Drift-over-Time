package model;

import java.sql.Timestamp;

public class Room {

    private int roomId;
    private String code;
    private String name;
    private String location;

    private float tempWarningThreshold = 32.0f;
    private float humidWarningThreshold = 80.0f;
    private float coWarningThreshold = 9.0f;
    private float co2WarningThreshold = 1000.0f;

    private float maxBaselineDrift;

    private String deviceCode;

    private String note;
    private boolean active;
    private Timestamp createdAt;

    private Double latitude;
    private Double longitude;

    public Room() {
    }

    public Room(int roomId, String code, String name, String location, float coWarningThreshold,
            float co2WarningThreshold, float maxBaselineDrift, String deviceCode, String note, boolean active,
            Timestamp createdAt) {
        this(roomId, code, name, location, coWarningThreshold, co2WarningThreshold, maxBaselineDrift, deviceCode, note, active, createdAt, null, null);
    }

    public Room(int roomId, String code, String name, String location, float coWarningThreshold,
            float co2WarningThreshold, float maxBaselineDrift, String deviceCode, String note, boolean active,
            Timestamp createdAt, Double latitude, Double longitude) {
        this.roomId = roomId;
        this.code = code;
        this.name = name;
        this.location = location;
        this.coWarningThreshold = coWarningThreshold;
        this.co2WarningThreshold = co2WarningThreshold;
        this.maxBaselineDrift = maxBaselineDrift;
        this.deviceCode = deviceCode;
        this.note = note;
        this.active = active;
        this.createdAt = createdAt;
        this.latitude = latitude;
        this.longitude = longitude;
    }

    public int getRoomId() {
        return roomId;
    }

    public void setRoomId(int roomId) {
        this.roomId = roomId;
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

    public float getTempWarningThreshold() {
        return tempWarningThreshold;
    }

    public void setTempWarningThreshold(float tempWarningThreshold) {
        this.tempWarningThreshold = tempWarningThreshold;
    }

    public float getHumidWarningThreshold() {
        return humidWarningThreshold;
    }

    public void setHumidWarningThreshold(float humidWarningThreshold) {
        this.humidWarningThreshold = humidWarningThreshold;
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

    public Double getLatitude() {
        return latitude;
    }

    public void setLatitude(Double latitude) {
        this.latitude = latitude;
    }

    public Double getLongitude() {
        return longitude;
    }

    public void setLongitude(Double longitude) {
        this.longitude = longitude;
    }

    private Double temp;
    private Double humidity;
    private Double co2;
    private Double co;
    private Boolean sensorOnline;
    private Integer openAlertsCount;
    private Timestamp lastMeasuredAt;

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

    public Double getCo2() {
        return co2;
    }

    public void setCo2(Double co2) {
        this.co2 = co2;
    }

    public Double getCo() {
        return co;
    }

    public void setCo(Double co) {
        this.co = co;
    }

    public Boolean isSensorOnline() {
        return sensorOnline;
    }

    public void setSensorOnline(Boolean sensorOnline) {
        this.sensorOnline = sensorOnline;
    }

    public Integer getOpenAlertsCount() {
        return openAlertsCount;
    }

    public void setOpenAlertsCount(Integer openAlertsCount) {
        this.openAlertsCount = openAlertsCount;
    }

    public Timestamp getLastMeasuredAt() {
        return lastMeasuredAt;
    }

    public void setLastMeasuredAt(Timestamp lastMeasuredAt) {
        this.lastMeasuredAt = lastMeasuredAt;
    }
}
