package model;

import java.sql.Timestamp;

public class AirLabel {
    private int labelId;
    private int sessionId;
    private String labelCode;
    private String source;
    private String reason;
    private Integer labeledBy;
    private String username;
    private Timestamp labeledAt;

    public AirLabel() {
    }

    public AirLabel(int labelId, int sessionId, String labelCode, String source, String reason, Integer labeledBy, String username, Timestamp labeledAt) {
        this.labelId = labelId;
        this.sessionId = sessionId;
        this.labelCode = labelCode;
        this.source = source;
        this.reason = reason;
        this.labeledBy = labeledBy;
        this.username = username;
        this.labeledAt = labeledAt;
    }

    public int getLabelId() {
        return labelId;
    }

    public void setLabelId(int labelId) {
        this.labelId = labelId;
    }

    public int getSessionId() {
        return sessionId;
    }

    public void setSessionId(int sessionId) {
        this.sessionId = sessionId;
    }

    public String getLabelCode() {
        return labelCode;
    }

    public void setLabelCode(String labelCode) {
        this.labelCode = labelCode;
    }

    public String getSource() {
        return source;
    }

    public void setSource(String source) {
        this.source = source;
    }

    public String getReason() {
        return reason;
    }

    public void setReason(String reason) {
        this.reason = reason;
    }

    public Integer getLabeledBy() {
        return labeledBy;
    }

    public void setLabeledBy(Integer labeledBy) {
        this.labeledBy = labeledBy;
    }

    public String getUsername() {
        return username;
    }

    public void setUsername(String username) {
        this.username = username;
    }

    public Timestamp getLabeledAt() {
        return labeledAt;
    }

    public void setLabeledAt(Timestamp labeledAt) {
        this.labeledAt = labeledAt;
    }
}
