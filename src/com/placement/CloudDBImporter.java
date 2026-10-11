package com.placement;

import java.io.BufferedReader;
import java.io.FileReader;
import java.io.InputStreamReader;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.Statement;

public class CloudDBImporter {
    public static void main(String[] args) {
        try {
            BufferedReader reader = new BufferedReader(new InputStreamReader(System.in));
            
            String host = "gateway01.ap-northeast-1.prod.aws.tidbcloud.com";
            String port = "4000";
            String user = "crBRPzL5eXxLnN1.root";
            String db = "smart_placement_db";
            
            System.out.println("=================================================");
            System.out.println("    TiDB Cloud Database Importer (Private)       ");
            System.out.println("=================================================");
            System.out.println("Host: " + host);
            System.out.println("User: " + user);
            System.out.println("Database: " + db);
            System.out.println();
            System.out.print("Please enter your TiDB password: ");
            String password = reader.readLine();
            
            if (password == null || password.trim().isEmpty()) {
                System.out.println("Password cannot be empty.");
                return;
            }
            password = password.trim();
            
            Class.forName("com.mysql.cj.jdbc.Driver");
            String url = "jdbc:mysql://" + host + ":" + port + "/" + db + "?sslMode=VERIFY_IDENTITY&enabledTLSProtocols=TLSv1.2,TLSv1.3&serverTimezone=UTC&characterEncoding=UTF-8";
            
            System.out.println("\nConnecting to TiDB Cloud...");
            try (Connection conn = DriverManager.getConnection(url, user, password);
                 Statement stmt = conn.createStatement();
                 BufferedReader fileReader = new BufferedReader(new FileReader("database_setup.sql"))) {
                
                System.out.println("Connected successfully! Importing tables and questions...\n");
                
                StringBuilder sb = new StringBuilder();
                String line;
                int count = 0;
                
                while ((line = fileReader.readLine()) != null) {
                    line = line.trim();
                    if (line.isEmpty() || line.startsWith("--") || line.startsWith("/*")) {
                        continue;
                    }
                    if (line.toUpperCase().startsWith("CREATE DATABASE") || line.toUpperCase().startsWith("USE ")) {
                        continue;
                    }
                    sb.append(line).append(" ");
                    if (line.endsWith(";")) {
                        String sql = sb.toString().trim();
                        if (sql.endsWith(";")) {
                            sql = sql.substring(0, sql.length() - 1);
                        }
                        try {
                            stmt.execute(sql);
                            count++;
                            if (count % 25 == 0) {
                                System.out.println("Imported " + count + " items...");
                            }
                        } catch (Exception ex) {
                            System.err.println("Notice on item: " + ex.getMessage());
                        }
                        sb.setLength(0);
                    }
                }
                System.out.println("\nSUCCESS! Imported " + count + " tables and records into TiDB Cloud.");
                System.out.println("Your cloud database is now fully populated and ready for Render!");
            }
        } catch (Exception e) {
            System.err.println("\nConnection or Import Failed: " + e.getMessage());
            e.printStackTrace();
        }
    }
}
