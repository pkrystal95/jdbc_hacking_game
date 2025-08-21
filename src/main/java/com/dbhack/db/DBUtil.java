package com.dbhack.db;// DB 연결, .env 읽기

import io.github.cdimascio.dotenv.Dotenv;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class DBUtil {
    private static final Dotenv dotenv = Dotenv.load(); // 루트, .env 로드

    public static Connection getConnection() throws SQLException {
        String url = dotenv.get("DB_URL");
        String user = dotenv.get("DB_USER");
        String password = dotenv.get("DB_PASSWORD");

        System.out.println("DB_URL: " + url);
        System.out.println("DB_USER: " + user);
        System.out.println("DB_PASSWORD: " + password);


        return DriverManager.getConnection(url, user, password);
    }
}