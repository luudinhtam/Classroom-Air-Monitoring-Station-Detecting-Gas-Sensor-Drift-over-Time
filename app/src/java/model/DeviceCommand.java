package model;

import java.sql.Timestamp;

public class DeviceCommand {
    private int commandId;
    private int deviceId;
    private int roomId;
    private String command = "START";
    private String status = "PENDING";
    private Timestamp createdAt;
    private Timestamp sentAt;
    private Timestamp doneAt;
    private Integer sessionId;

    public DeviceCommand() {
    }

    public DeviceCommand(int commandId, int deviceId, int roomId, String command, String status,
                         Timestamp createdAt, Timestamp sentAt, Timestamp doneAt, Integer sessionId) {
        this.commandId = commandId;
        this.deviceId = deviceId;
        this.roomId = roomId;
        this.command = command;
        this.status = status;
        this.createdAt = createdAt;
        this.sentAt = sentAt;
        this.doneAt = doneAt;
        this.sessionId = sessionId;
    }

    public int getCommandId() {
        return commandId;
    }

    public void setCommandId(int commandId) {
        this.commandId = commandId;
    }

    public int getDeviceId() {
        return deviceId;
    }

    public void setDeviceId(int deviceId) {
        this.deviceId = deviceId;
    }

    public int getRoomId() {
        return roomId;
    }

    public void setRoomId(int roomId) {
        this.roomId = roomId;
    }

    public String getCommand() {
        return command;
    }

    public void setCommand(String command) {
        this.command = command;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public Timestamp getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Timestamp createdAt) {
        this.createdAt = createdAt;
    }

    public Timestamp getSentAt() {
        return sentAt;
    }

    public void setSentAt(Timestamp sentAt) {
        this.sentAt = sentAt;
    }

    public Timestamp getDoneAt() {
        return doneAt;
    }

    public void setDoneAt(Timestamp doneAt) {
        this.doneAt = doneAt;
    }

    public Integer getSessionId() {
        return sessionId;
    }

    public void setSessionId(Integer sessionId) {
        this.sessionId = sessionId;
    }
}
