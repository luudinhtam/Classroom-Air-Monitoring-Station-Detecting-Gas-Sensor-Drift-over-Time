
package model;

import java.sql.Timestamp;


public class Calibration {
    
    private int calibrationId;
    private String code;
    private String name;
    private String note;
    
    
    private float coBaseLine;
    private float co2BaseLine;
    
    private Timestamp calibratedAt;
    
    // Tham chieu den model AirStation.java
    private int stationId;
    // Tham chieu den model AppUser.java
    private int performedBy;
    
    // Hien thi
    private String performedByUsername;

    public String getPerformedByUsername() {
        return performedByUsername;
    }

    public void setPerformedByUsername(String performedByUsername) {
        this.performedByUsername = performedByUsername;
    }
    
    

    public Calibration() {
    }

    public Calibration(int calibrationId, String code, String name, String note, float coBaseLine, float co2BaseLine, boolean active, Timestamp calibratedAt, Timestamp createdAt, int stationId, int performedBy) {
        this.calibrationId = calibrationId;
        this.code = code;
        this.name = name;
        this.note = note;
        this.coBaseLine = coBaseLine;
        this.co2BaseLine = co2BaseLine;
        
        this.calibratedAt = calibratedAt;
        
        this.stationId = stationId;
        this.performedBy = performedBy;
    }

    public int getCalibrationId() {
        return calibrationId;
    }

    public void setCalibrationId(int calibrationId) {
        this.calibrationId = calibrationId;
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

    public float getCoBaseLine() {
        return coBaseLine;
    }

    public void setCoBaseLine(float coBaseLine) {
        this.coBaseLine = coBaseLine;
    }

    public float getCo2BaseLine() {
        return co2BaseLine;
    }

    public void setCo2BaseLine(float co2BaseLine) {
        this.co2BaseLine = co2BaseLine;
    }

    

    public Timestamp getCalibratedAt() {
        return calibratedAt;
    }

    public void setCalibratedAt(Timestamp calibratedAt) {
        this.calibratedAt = calibratedAt;
    }

    

    public int getStationId() {
        return stationId;
    }

    public void setStationId(int stationId) {
        this.stationId = stationId;
    }

    public int getPerformedBy() {
        return performedBy;
    }

    public void setPerformedBy(int performedBy) {
        this.performedBy = performedBy;
    }
    
    

    

    

    
    
    
    
    
}
