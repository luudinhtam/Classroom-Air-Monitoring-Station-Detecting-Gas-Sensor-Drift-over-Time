package service;

/**
 * Exception rieng cho nghiep vu Measure (do thu cong).
 * Giup tang Servlet de dang map ra cac HTTP status code tuong ung.
 */
public class MeasureException extends RuntimeException {

    public enum ErrorCode {
        NO_DEVICE,         // Phong chua co thiet bi hoat dong (400 / 404)
        DEVICE_BUSY,       // Thiet bi dang trong tien trinh do (409 Conflict)
        NOT_FOUND,         // Khong tim thay lenh do hoac sai phong (404 Not Found)
        INVALID_COMMAND,   // Lenh khong ton tai, sai thiet bi hoac da ket thuc (400 Bad Request)
        INVALID_DATA,      // So do khong hop le hoac nam ngoai nguong cho phep (400 Bad Request)
        SYSTEM_ERROR       // Loi he thong / Transaction database (500 Internal Server Error)
    }

    private final ErrorCode code;

    public MeasureException(ErrorCode code, String message) {
        super(message);
        this.code = code;
    }

    public MeasureException(ErrorCode code, String message, Throwable cause) {
        super(message, cause);
        this.code = code;
    }

    public ErrorCode getCode() {
        return code;
    }
}
