package com.dbhack.db;

import io.github.cdimascio.dotenv.Dotenv;
import jakarta.servlet.Servlet;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class DBUtil {
    private static final Dotenv dotenv = Dotenv.configure().ignoreIfMissing().load(); // 이거 주의하세요... (배포 의식)
    public static final String URL = dotenv.get("DB_URL");
    public static final String USER = dotenv.get("DB_USER");
    public static final String PASSWORD = dotenv.get("DB_PASSWORD");

    public static Connection getConnection() throws SQLException {
        if (URL == null || USER == null || PASSWORD == null) {
            throw new RuntimeException("환경변수 에러 (.env 세팅해주세요!)");
        }
        try {
            // 드라이버를 명시적으로 표기
            Class.forName("com.mysql.cj.jdbc.Driver");
            return DriverManager.getConnection(URL, USER, PASSWORD);
        } catch (Exception e) {
            System.err.println("커넥션 연결 실패");
            System.err.println(e.getMessage());
            throw new SQLException(e);
        }
    }
}