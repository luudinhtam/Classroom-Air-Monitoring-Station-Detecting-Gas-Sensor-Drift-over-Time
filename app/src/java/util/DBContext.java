package util;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

/**
 * One connection helper for the whole project. DriverManager is used on purpose:
 * it needs nothing but the JDBC jar, so the project opens and runs on the exam
 * machine without any extra install.
 */
public class DBContext {

    private static final String URL = "jdbc:sqlserver://localhost:1433;databaseName=AirroomDB;encrypt=false";
    private static final String USER = "sa";
    private static final String PASS = "12345";

    static {
        try {
            Class.forName("com.microsoft.sqlserver.jdbc.SQLServerDriver");
        } catch (ClassNotFoundException e) {
            throw new RuntimeException("JDBC driver not found on the classpath", e);
        }
    }

    public static Connection getConnection() throws SQLException {
        return DriverManager.getConnection(URL, USER, PASS);
    }
}
