package com.dbhack.servlet;

import com.dbhack.db.DBUtil;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

@WebServlet("/ranking")
public class RankingServlet extends HttpServlet {
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        resp.setContentType("application/json");
        PrintWriter out = resp.getWriter();

        try (Connection conn = DBUtil.getConnection();
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery("SELECT username, MAX(cleared_stage) AS stage, MIN(cleared_time) AS time FROM ranking GROUP BY username ORDER BY stage DESC, time ASC")) {

            StringBuilder sb = new StringBuilder("[");
            boolean first = true;
            while(rs.next()){
                if(!first) sb.append(",");
                sb.append("{\"username\":\"").append(rs.getString("username"))
                        .append("\",\"stage\":").append(rs.getInt("stage"))
                        .append(",\"time\":\"").append(rs.getTimestamp("time")).append("\"}");
                first = false;
            }
            sb.append("]");
            out.print(sb.toString());
        } catch(SQLException e){
            e.printStackTrace();
            out.print("[]");
        }
    }
}
