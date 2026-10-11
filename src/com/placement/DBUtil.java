package com.placement;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.sql.Statement;

public class DBUtil {
    private static String getEnvOrProp(String key, String defaultValue) {
        String val = System.getenv(key);
        if (val != null && !val.trim().isEmpty()) {
            return val.trim();
        }
        val = System.getProperty(key);
        if (val != null && !val.trim().isEmpty()) {
            return val.trim();
        }
        return defaultValue;
    }

    private static final String DB_NAME = getEnvOrProp("DB_NAME", "smart_placement_db");
    private static final String DB_USER = getEnvOrProp("DB_USER", "root");
    private static final String DB_PASSWORD = getEnvOrProp("DB_PASSWORD", "");
    private static final String DB_HOST = getEnvOrProp("DB_HOST", "localhost");
    private static final String DB_PORT = getEnvOrProp("DB_PORT", "3306");

    private static String getDbUrl() {
        String customUrl = System.getenv("DB_URL");
        if (customUrl != null && !customUrl.trim().isEmpty()) {
            return customUrl.trim();
        }
        return "jdbc:mysql://" + DB_HOST + ":" + DB_PORT + "/" + DB_NAME + "?allowPublicKeyRetrieval=true&serverTimezone=UTC&characterEncoding=UTF-8";
    }

    private static final String BASE_URL = "jdbc:mysql://" + DB_HOST + ":" + DB_PORT + "/?allowPublicKeyRetrieval=true&serverTimezone=UTC&characterEncoding=UTF-8";
    private static final String DB_URL = getDbUrl();

    static {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
        } catch (ClassNotFoundException e) {
            e.printStackTrace();
        }
    }

    public static Connection getConnection() throws SQLException {
        try {
            return DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD);
        } catch (SQLException e) {
            // If the database doesn't exist yet, attempt to create it automatically
            try (Connection rootConn = DriverManager.getConnection(BASE_URL, DB_USER, DB_PASSWORD);
                 Statement stmt = rootConn.createStatement()) {
                stmt.executeUpdate("CREATE DATABASE IF NOT EXISTS " + DB_NAME + " CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;");
            } catch (Exception ex) {
                // If auto-create fails, throw original exception
                throw e;
            }
            return DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD);
        }
    }

    public static void close(AutoCloseable... resources) {
        for (AutoCloseable res : resources) {
            if (res != null) {
                try {
                    res.close();
                } catch (Exception ignored) {
                }
            }
        }
    }
}
