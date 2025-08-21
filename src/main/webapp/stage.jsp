<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page session="true" %>
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <title>DB 해킹 게임</title>
    <!-- xterm.js CSS -->
    <link rel="stylesheet" href="<%= request.getContextPath() %>/js/xterm.css">
    <style>
        body {
            font-family: monospace;
            background-color: #111;
            color: #0f0;
        }
        #terminal {
            width: 100%;
            height: 500px;
            background: #000;
            color: #0f0;
            padding: 10px;
            overflow-y: auto;
            border: 1px solid #0f0;
        }
        h1 { color: #0f0; }
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

        // xterm.js 초기화
        const term = new Terminal({
            cursorBlink: true,
            rows: 25,
            cols: 80,
            theme: {
                background: '#000000',
                foreground: '#00ff00'
            }
        });
        term.open(document.getElementById('terminal'));
        term.writeln('Welcome ' + username + '!');
        term.writeln('Type your SQL command and press Enter.');
        term.prompt = () => term.write('\r\n$ ');
        term.prompt();

        // 입력 버퍼
        let inputBuffer = '';

        term.onKey(e => {
            const ev = e.domEvent;
            const printable = !ev.altKey && !ev.ctrlKey && !ev.metaKey;

            if(ev.key === "Enter"){
                term.writeln('');
                const sql = inputBuffer.trim();
                inputBuffer = '';

                if(!sql){
                    term.prompt();
                    return;
                }

                // StageServlet POST
                fetch('<%= request.getContextPath() %>/stage', {
                    method: 'POST',
                    headers: { 'Content-Type':'application/x-www-form-urlencoded' },
                    body: `username=${encodeURIComponent(username)}&stageId=${currentStage}&sql=${encodeURIComponent(sql)}`
                })
                .then(res => res.json())
                .then(data => {
                    term.writeln(data.msg);

                    if(data.status === "success") {
                        currentStage++;
                        document.getElementById("stageNum").innerText = currentStage;
                    }
                    term.prompt();
                })
                .catch(err => {
                    term.writeln('Error: ' + err);
                    term.prompt();
                });

            } else if(ev.key === "Backspace"){
                if(inputBuffer.length > 0){
                    inputBuffer = inputBuffer.slice(0, -1);
                    term.write('\b \b'); // 터미널에서 글자 지우기
                }
            } else if(printable){
                inputBuffer += e.key;
                term.write(e.key);
            }
        });
    </script>
</body>
</html>
