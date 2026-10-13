
package model;

import java.time.LocalDateTime;


public class EmptyWindow {
    private int emptyWindowId;
    private String code;
    private String name;
    private int stationId;
    private LocalDateTime startAt;
    private LocalDateTime endAt;
    private int markedBy;
    private String note;
    private LocalDateTime createdAt;
    
    // De hien thi
    private String markedByUsername;

    public EmptyWindow() {
    }

    public EmptyWindow(int emptyWindowId, String code, String name, int stationId, LocalDateTime startAt, LocalDateTime endAt, int markedBy, String note, LocalDateTime createdAt) {
        this.emptyWindowId = emptyWindowId;
        this.code = code;
        this.name = name;
        this.stationId = stationId;
        this.startAt = startAt;
        this.endAt = endAt;
        this.markedBy = markedBy;
        this.note = note;
        this.createdAt = createdAt;
    }

    public String getMarkedByUsername() {
        return markedByUsername;
    }

    public void setMarkedByUsername(String markedByUsername) {
        this.markedByUsername = markedByUsername;
    }
    
    

    public int getEmptyWindowId() {
        return emptyWindowId;
    }

    public void setEmptyWindowId(int emptyWindowId) {
        this.emptyWindowId = emptyWindowId;
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

    public int getStationId() {
        return stationId;
    }

    public void setStationId(int stationId) {
        this.stationId = stationId;
    }

    public LocalDateTime getStartAt() {
        return startAt;
    }

    public void setStartAt(LocalDateTime startAt) {
        this.startAt = startAt;
    }

    public LocalDateTime getEndAt() {
        return endAt;
    }

    public void setEndAt(LocalDateTime endAt) {
        this.endAt = endAt;
    }

    public int getMarkedBy() {
        return markedBy;
    }

    public void setMarkedBy(int markedBy) {
        this.markedBy = markedBy;
    }

    public String getNote() {
        return note;
    }

    public void setNote(String note) {
        this.note = note;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
    
    
}
