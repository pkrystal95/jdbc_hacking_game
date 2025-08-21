<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <title>DB 해킹 게임</title>
    <!-- xterm.js CSS -->
    <link rel="stylesheet" href="<%= request.getContextPath() %>/js/xterm.css">
    <style>
        #terminal { width: 100%; height: 500px; background: #000; color: #0f0; padding: 10px; }
    </style>
</head>
<body>
    <h1>DB 해킹 게임 - Stage <span id="stageNum">1</span></h1>

    <!-- 터미널 영역 -->
    <div id="terminal"></div>

    <!-- xterm.js 라이브러리 -->
    <script src="<%= request.getContextPath() %>/js/xterm.js"></script>
    <script>
        // 로그인 세션에서 username 가져오기
        const username = '<%= session.getAttribute("username") != null ? session.getAttribute("username") : "Guest" %>';
        let currentStage = 1;

        // xterm.js 터미널 초기화
        const term = new Terminal();
        term.open(document.getElementById('terminal'));
        term.write('Welcome ' + username + '!\r\n');
        term.prompt = () => term.write('\r\n$ ');
        term.prompt();

        term.onKey(e => {
            if(e.domEvent.key === "Enter"){
                // 커서 줄에서 입력 추출
                let sqlLine = term.buffer.active.getLine(term.buffer.active.cursorY).translateToString();
                let sql = sqlLine.trim().slice(2); // '$ ' 제거
                if(!sql) { term.prompt(); return; }

                // POST 요청
                fetch('<%= request.getContextPath() %>/stage', {
                    method: 'POST',
                    headers: { 'Content-Type':'application/x-www-form-urlencoded' },
                    body: `username=${username}&stageId=${currentStage}&sql=${encodeURIComponent(sql)}`
                })
                .then(res => res.json())
                .then(data => {
                    term.writeln("\r\n" + data.msg);
                    if(data.status === "success") {
                        currentStage++;
                        document.getElementById("stageNum").innerText = currentStage;
                    }
                    term.prompt();
                })
                .catch(err => {
                    term.writeln("\r\nError: " + err);
                    term.prompt();
                });
            }
        });
    </script>
</body>
</html>
