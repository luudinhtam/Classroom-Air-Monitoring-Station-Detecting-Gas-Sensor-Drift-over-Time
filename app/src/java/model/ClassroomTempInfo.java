package model;

import java.util.ArrayList;
import java.util.List;

/**
 * Model chứa dữ liệu nhiệt độ, độ ẩm và lịch sử quan trắc tức thời của phòng học
 * phục vụ giao diện Dashboard "Classroom Temp – Monitoring System".
 */
public class ClassroomTempInfo {
    private int roomId;
    private String roomCode;
    private String roomName;
    private String building;
    private int floor;
    private String location;
    private Double temperature;
    private Double humidity;
    private Integer co2;
    private Double co;
    private boolean hasData;
    private String deviceCode;
    private String status; // NORMAL | WARNING | DANGER | NO_DATA
    private String imageUrl;
    private List<Double> tempHistory = new ArrayList<>();

    public ClassroomTempInfo() {}

    public int getRoomId() { return roomId; }
    public void setRoomId(int roomId) { this.roomId = roomId; }

    public String getRoomCode() { return roomCode; }
    public void setRoomCode(String roomCode) { this.roomCode = roomCode; }

    public String getRoomName() { return roomName; }
    public void setRoomName(String roomName) { this.roomName = roomName; }

    public String getBuilding() { return building; }
    public void setBuilding(String building) { this.building = building; }

    public int getFloor() { return floor; }
    public void setFloor(int floor) { this.floor = floor; }

    public String getLocation() { return location; }
    public void setLocation(String location) { this.location = location; }

    public Double getTemperature() { return temperature; }
    public void setTemperature(Double temperature) { this.temperature = temperature; }

    public Double getHumidity() { return humidity; }
    public void setHumidity(Double humidity) { this.humidity = humidity; }

    public Integer getCo2() { return co2; }
    public void setCo2(Integer co2) { this.co2 = co2; }

    public Double getCo() { return co; }
    public void setCo(Double co) { this.co = co; }

    public boolean isHasData() { return hasData; }
    public void setHasData(boolean hasData) { this.hasData = hasData; }

    public String getDeviceCode() { return deviceCode; }
    public void setDeviceCode(String deviceCode) { this.deviceCode = deviceCode; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public String getImageUrl() { return imageUrl; }
    public void setImageUrl(String imageUrl) { this.imageUrl = imageUrl; }

    public List<Double> getTempHistory() { return tempHistory; }
    public void setTempHistory(List<Double> tempHistory) { this.tempHistory = tempHistory; }
}
