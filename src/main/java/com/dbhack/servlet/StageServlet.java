package com.dbhack.servlet;

import com.dbhack.db.DBUtil;

import com.google.gson.Gson;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import java.io.IOException;
import java.sql.*;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

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
        String sqlInput = req.getParameter("sql");

        String correctSql = "";
        String description = "";

        try(Connection conn = DBUtil.getConnection();
            PreparedStatement ps1 = conn.prepareStatement("SELECT solution_sql, description FROM stages WHERE id=?")) {
            ps1.setInt(1, stageId);
            ResultSet rs = ps1.executeQuery();
            if(rs.next()){
                correctSql = rs.getString("solution_sql").trim();
                description = rs.getString("description");
            }
        } catch(Exception e){
            e.printStackTrace();
        }

        String status, msg;
        List<Map<String, String>> table = new ArrayList<>();
        if(sqlInput.trim().equalsIgnoreCase(correctSql)) {
            status = "success";
            msg = "Stage " + stageId + " Cleared! ✅";

            // 실제 SQL 실행 결과 가져오기
            try(Connection conn = DBUtil.getConnection();
                Statement st = conn.createStatement();
                ResultSet rs = st.executeQuery(correctSql)) {

                ResultSetMetaData meta = rs.getMetaData();
                int colCount = meta.getColumnCount();
                while(rs.next()) {
                    Map<String, String> row = new LinkedHashMap<>();
                    for(int i=1; i<=colCount; i++){
                        row.put(meta.getColumnLabel(i), rs.getString(i));
                    }
                    table.add(row);
                }

            } catch(Exception e){
                e.printStackTrace();
            }

        } else {
            status = "fail";
            msg = "Incorrect SQL. ❌ Try again.";
        }

        // JSON 응답
        resp.setContentType("application/json;charset=UTF-8");
        resp.getWriter().print("{"
                + "\"status\":\"" + status + "\","
                + "\"msg\":\"" + msg + "\","
                + "\"description\":\"" + description.replace("\"","\\\"") + "\","
                + "\"nextStage\":" + (status.equals("success") ? stageId+1 : stageId) + ","
                + "\"table\":" + new Gson().toJson(table)
                + "}");
    }

}
