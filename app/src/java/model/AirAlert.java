package model;

import java.sql.Timestamp;

public class AirAlert {
    private int alertId;
    private Integer sessionId;
    private String alertCode;
    private String alertType;
    private String ruleCode;
    private String message;
    private String status;
    private Integer handledBy;
    private String handledByName;
    private String note;
    private Timestamp createdAt;
    private String deviceCode;
    private String severity;

    public AirAlert() {}

    public int getAlertId() { return alertId; }
    public void setAlertId(int alertId) { this.alertId = alertId; }

    public Integer getSessionId() { return sessionId; }
    public void setSessionId(Integer sessionId) { this.sessionId = sessionId; }

    public String getAlertCode() { return alertCode; }
    public void setAlertCode(String alertCode) { this.alertCode = alertCode; }

    public String getAlertType() { return alertType; }
    public void setAlertType(String alertType) { this.alertType = alertType; }

    public String getType() { return alertType != null ? alertType : ruleCode; }
    public void setType(String type) { this.alertType = type; }

    public String getRuleCode() { return ruleCode != null ? ruleCode : (alertType != null ? alertType : alertCode); }
    public void setRuleCode(String ruleCode) { this.ruleCode = ruleCode; }

    public String getSeverity() { return severity != null ? severity : (alertType != null ? alertType : "WARNING"); }
    public void setSeverity(String severity) { this.severity = severity; }

    public String getMessage() { return message; }
    public void setMessage(String message) { this.message = message; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public Integer getHandledBy() { return handledBy; }
    public void setHandledBy(Integer handledBy) { this.handledBy = handledBy; }

    public String getHandledByName() { return handledByName; }
    public void setHandledByName(String handledByName) { this.handledByName = handledByName; }

    public String getNote() { return note; }
    public void setNote(String note) { this.note = note; }

    public String getHandledNote() { return note; }
    public void setHandledNote(String handledNote) { this.note = handledNote; }

    public Timestamp getCreatedAt() { return createdAt; }
    public void setCreatedAt(Timestamp createdAt) { this.createdAt = createdAt; }

    public String getDeviceCode() { return deviceCode; }
    public void setDeviceCode(String deviceCode) { this.deviceCode = deviceCode; }

    private String roomCode;
    private Integer roomId;

    public String getRoomCode() { return roomCode; }
    public void setRoomCode(String roomCode) { this.roomCode = roomCode; }

    public Integer getRoomId() { return roomId; }
    public void setRoomId(Integer roomId) { this.roomId = roomId; }
}
