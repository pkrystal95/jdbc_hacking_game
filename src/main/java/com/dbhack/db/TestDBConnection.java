package com.dbhack.db;

import java.sql.Connection;
import java.sql.SQLException;

public class TestDBConnection {
    public static void main(String[] args) {
        try (Connection conn = DBUtil.getConnection()) {
            if (conn != null && !conn.isClosed()) {
                System.out.println("✅ DB 연결 성공!");
            } else {
                System.out.println("❌ DB 연결 실패!");
            }
        } catch (SQLException e) {
            System.err.println("DB 연결 중 예외 발생:");
            e.printStackTrace();
        }
    }
}
