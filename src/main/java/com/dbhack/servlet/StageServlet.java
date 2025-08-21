package com.dbhack.servlet;

import com.dbhack.db.DBUtil;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import java.io.IOException;
import java.sql.*;

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
        // 요청 데이터 인코딩 설정 (UTF-8)
        req.setCharacterEncoding("UTF-8");

        // 클라이언트에서 전달된 파라미터 추출
        String username = req.getParameter("username");
        int stageId = Integer.parseInt(req.getParameter("stageId"));
        String sqlInput = req.getParameter("sql");

        // DB에서 정답 SQL과 스테이지 설명 초기화
        String correctSql = "";
        String description = "";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement("SELECT solution_sql, description FROM stages WHERE id=?")) {

            ps.setInt(1, stageId);
            ResultSet rs = ps.executeQuery();

            if(rs.next()){
                correctSql = rs.getString("solution_sql").trim();
                description = rs.getString("description");
            }
        } catch(Exception e){
            e.printStackTrace();
            resp.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            resp.getWriter().print("{\"status\":\"error\", \"msg\":\"Server error.\"}");
            return;
        }

        // 사용자 입력과 정답 비교
        boolean isCorrect = sqlInput != null && sqlInput.trim().equalsIgnoreCase(correctSql.trim());
        String status = isCorrect ? "success" : "fail";
        String msg = isCorrect ? "Stage " + stageId + " Cleared! ✅" : "Incorrect SQL. ❌ Try again.";

        // JSON 응답
        resp.setContentType("application/json;charset=UTF-8");
        resp.getWriter().print("{"
                + "\"status\":\"" + status + "\","
                + "\"msg\":\"" + msg + "\","
                + "\"description\":\"" + description.replace("\"","\\\"") + "\","
                + "\"nextStage\":" + (isCorrect ? stageId + 1 : stageId)
                + "}");
    }

}
