package com.dbhack.servlet;  // 반드시 src/main/java 기준 패키지 맞추기

import com.dbhack.db.DBUtil;

import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.*;

@WebServlet("/stage")
public class StageServlet extends HttpServlet {

    // POST 요청: 터미널에서 SQL 실행
    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        resp.setContentType("application/json; charset=UTF-8");
        PrintWriter out = resp.getWriter();

        String username = req.getParameter("username");
        String stageIdStr = req.getParameter("stageId");
        String userSql = req.getParameter("sql");

        if(username == null || stageIdStr == null || userSql == null) {
            out.print("{\"status\":\"fail\",\"msg\":\"필수 파라미터 누락\"}");
            return;
        }

        int stageId;
        try {
            stageId = Integer.parseInt(stageIdStr);
        } catch(NumberFormatException e) {
            out.print("{\"status\":\"fail\",\"msg\":\"stageId는 숫자여야 합니다.\"}");
            return;
        }

        try (Connection conn = DBUtil.getConnection()) {

            // 1️⃣ 정답 SQL 가져오기
            String stageSql = "";
            try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT solution_sql FROM stages WHERE id = ?")) {
                ps.setInt(1, stageId);
                ResultSet rs = ps.executeQuery();
                if(rs.next()) stageSql = rs.getString("solution_sql");
                else {
                    out.print("{\"status\":\"error\",\"msg\":\"Stage not found\"}");
                    return;
                }
            }

            // 2️⃣ 사용자 SQL 실행 및 비교
            boolean userCorrect = false;
            try (Statement stmt = conn.createStatement()) {
                ResultSet userRs = stmt.executeQuery(userSql);
                ResultSet answerRs = stmt.executeQuery(stageSql);
                userCorrect = compareResultSets(userRs, answerRs);
            } catch(SQLException e){
                out.print("{\"status\":\"fail\",\"msg\":\"SQL 실행 오류: " + e.getMessage().replace("\"","'") + "\"}");
                return;
            }

            // 3️⃣ 랭킹 등록 및 응답
            if(userCorrect){
                try (PreparedStatement ps = conn.prepareStatement(
                        "INSERT INTO ranking(username, cleared_stage, cleared_time) VALUES(?,?,NOW())")) {
                    ps.setString(1, username);
                    ps.setInt(2, stageId);
                    ps.executeUpdate();
                }
                out.print("{\"status\":\"success\",\"msg\":\"Stage Cleared!\"}");
            } else {
                out.print("{\"status\":\"fail\",\"msg\":\"결과가 정답과 일치하지 않습니다.\"}");
            }

        } catch(SQLException e){
            e.printStackTrace();
            out.print("{\"status\":\"error\",\"msg\":\"DB 연결 오류\"}");
        }
    }

    // GET 요청: stage.jsp로 리다이렉트
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        resp.sendRedirect("stage.jsp");
    }

    // ResultSet 비교
    private boolean compareResultSets(ResultSet rs1, ResultSet rs2) throws SQLException {
        ResultSetMetaData meta1 = rs1.getMetaData();
        ResultSetMetaData meta2 = rs2.getMetaData();

        if(meta1.getColumnCount() != meta2.getColumnCount()) return false;

        int colCount = meta1.getColumnCount();
        for(int i=1;i<=colCount;i++){
            if(!meta1.getColumnName(i).equalsIgnoreCase(meta2.getColumnName(i))) return false;
        }

        while(rs1.next()){
            if(!rs2.next()) return false;
            for(int i=1;i<=colCount;i++){
                String val1 = rs1.getString(i);
                String val2 = rs2.getString(i);
                if(val1 == null && val2 != null) return false;
                if(val1 != null && !val1.equals(val2)) return false;
            }
        }
        return !rs2.next();
    }
}
