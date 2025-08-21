package com.dbhack.servlet;

import com.dbhack.db.DBUtil;

import com.google.gson.Gson;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import java.io.IOException;
import java.sql.*;
import java.util.*;

@WebServlet({"/stage", "/stageApi"})
public class StageServlet extends HttpServlet {

    // GET: Stage 설명 조회
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        String servletPath = req.getServletPath(); // 요청 URL 경로 예: /stage, /stageApi

        if(servletPath.equals("/stage")) {
            // 브라우저에서 접속 → JSP UI 보여주기
            req.getRequestDispatcher("/stage.jsp").forward(req, resp);
            return;
        }

        if(servletPath.equals("/stageApi")) {
            // JSON 응답 (mission description 등)
            int stageId = Integer.parseInt(req.getParameter("stageId"));
            String description = "";

            try(Connection conn = DBUtil.getConnection();
                PreparedStatement ps = conn.prepareStatement("SELECT description FROM stages WHERE id=?")) {
                ps.setInt(1, stageId);
                ResultSet rs = ps.executeQuery();
                if(rs.next()) description = rs.getString("description");
            } catch(Exception e){ e.printStackTrace(); }

            resp.setContentType("application/json;charset=UTF-8");
            resp.getWriter().print("{\"description\":\"" + description.replace("\"","\\\"") + "\"}");
            return;
        }

        // 그 외 경로 처리
        resp.sendError(HttpServletResponse.SC_NOT_FOUND);
    }


    // POST: SQL 입력 검증
    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");
        String username = req.getParameter("username");
        int stageId = Integer.parseInt(req.getParameter("stageId"));
        String sqlInput = req.getParameter("sql").trim();

        String correctSql = "";
        String description = "";

        // 정답 SQL과 description 조회
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps1 = conn.prepareStatement("SELECT solution_sql, description FROM stages WHERE id=?")) {
            ps1.setInt(1, stageId);
            try (ResultSet rs = ps1.executeQuery()) {
                if (rs.next()) {
                    correctSql = rs.getString("solution_sql").trim();
                    description = rs.getString("description");
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        String status, msg;
        List<Map<String, String>> table = new ArrayList<>();
        boolean isCorrect = false;

        try (Connection conn = DBUtil.getConnection();
             Statement stUser = conn.createStatement();
             Statement stCorrect = conn.createStatement()) {

            // ===== 사용자 SQL 실행 =====
            List<Map<String, String>> userTable = new ArrayList<>();
            boolean userHasResultSet = stUser.execute(sqlInput);
            if (userHasResultSet) {
                try (ResultSet rsUser = stUser.getResultSet()) {
                    userTable = resultSetToList(rsUser);
                }
            }

            // ===== 정답 SQL 실행 =====
            List<Map<String, String>> correctTable = new ArrayList<>();
            boolean correctHasResultSet = stCorrect.execute(correctSql);
            if (correctHasResultSet) {
                try (ResultSet rsCorrect = stCorrect.getResultSet()) {
                    correctTable = resultSetToList(rsCorrect);
                }
            }

            // ===== 결과 비교 =====
            isCorrect = compareResultTables(userTable, correctTable); // 값 중심 비교
            table = userTable; // 틀려도 결과 보여주기

        } catch (Exception e) {
            e.printStackTrace();
            isCorrect = false; // SQL 오류면 틀린 것으로 처리
        }

        if (isCorrect) {
            status = "success";
            msg = "Stage " + stageId + " Cleared! ✅";
        } else {
            status = "fail";
            msg = "Incorrect SQL. Try again.";
        }

        // JSON 응답
        resp.setContentType("application/json;charset=UTF-8");
        resp.getWriter().print("{"
                + "\"status\":\"" + status + "\","
                + "\"msg\":\"" + msg + "\","
                + "\"description\":\"" + description.replace("\"", "\\\"") + "\","
                + "\"nextStage\":" + (status.equals("success") ? stageId + 1 : stageId) + ","
                + "\"table\":" + new Gson().toJson(table)
                + "}");
    }

    // ResultSet → List<Map> 변환
    private List<Map<String, String>> resultSetToList(ResultSet rs) throws SQLException {
        List<Map<String, String>> list = new ArrayList<>();
        ResultSetMetaData meta = rs.getMetaData();
        int colCount = meta.getColumnCount();

        while (rs.next()) {
            Map<String, String> row = new TreeMap<>(); // TreeMap으로 컬럼 이름 정렬
            for (int i = 1; i <= colCount; i++) {
                row.put(meta.getColumnLabel(i), rs.getString(i));
            }
            list.add(row);
        }
        return list;
    }

    // 값 중심 비교 (컬럼 이름, 순서 무시)
    private boolean compareResultTables(List<Map<String, String>> a, List<Map<String, String>> b) {
        if (a.size() != b.size()) return false;

        // 각 행을 문자열로 변환 후 정렬해서 비교
        List<String> rowsA = new ArrayList<>();
        for (Map<String, String> row : a) {
            rowsA.add(row.values().toString());
        }
        List<String> rowsB = new ArrayList<>();
        for (Map<String, String> row : b) {
            rowsB.add(row.values().toString());
        }
        Collections.sort(rowsA);
        Collections.sort(rowsB);

        return rowsA.equals(rowsB);
    }


}
