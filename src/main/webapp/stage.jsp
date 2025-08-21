<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page session="true" %>
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <title>DB 해킹 게임</title>
        <link rel="stylesheet" href="<%= request.getContextPath() %>/js/xterm.css">
        <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/xterm/css/xterm.css" />
        <script src="https://cdn.jsdelivr.net/npm/xterm/lib/xterm.js"></script>
    <link rel="stylesheet" href="<%= request.getContextPath() %>/js/xterm.css">
    <style>
        body { font-family: monospace; background: #111; color: #0f0; }
        #terminal { width: 100%; height: 500px; background: #000; color: #0f0; padding: 10px; overflow-y:auto; border:1px solid #0f0; }
        h1 { color:#0f0; }
    </style>
</head>
<body>
    <h1>DB 해킹 게임 - Stage <span id="stageNum">1</span></h1>
    <div id="terminal"></div>

    <script src="<%= request.getContextPath() %>/js/xterm.js"></script>
    <script>
        const username = '<%= session.getAttribute("username") != null ? session.getAttribute("username") : "Guest" %>';
        let currentStage = 1;
        const term = new Terminal({ cursorBlink: true, rows:25, cols:80, theme:{ background:'#000', foreground:'#0f0' } });
        term.open(document.getElementById('terminal'));
        term.writeln('Welcome ' + username + '!');
        term.writeln('Type your SQL command and press Enter.');

        term.prompt = () => term.write('\r\n$ ');
        term.prompt();

        let inputBuffer = '';

        // 초기 미션 로딩
        function loadMission(stageId){
            fetch('<%= request.getContextPath() %>/stageApi?stageId=' + stageId)
                .then(res => res.json())
                .then(data => {
                    term.writeln("\r\nMission: " + data.description);
                    term.prompt();
                })
                .catch(err => {
                    term.writeln("Error loading mission: " + err);
                    term.prompt();
                });
        }
        loadMission(currentStage);

        term.onKey(e => {
            const ev = e.domEvent;
            const printable = !ev.altKey && !ev.ctrlKey && !ev.metaKey;

            if(ev.key === "Enter"){
                term.writeln('');
                const sql = inputBuffer.trim();
                inputBuffer = '';

                if(!sql){ term.prompt(); return; }

                fetch('<%= request.getContextPath() %>/stage', {
                    method: 'POST',
                    headers: {'Content-Type':'application/x-www-form-urlencoded'},
                    body: `username=${encodeURIComponent(username)}&stageId=${currentStage}&sql=${encodeURIComponent(sql)}`
                })
                .then(res => res.json())
                .then(data => {
                    term.writeln(data.msg);

                    if(data.status === "success") {
                        currentStage = data.nextStage;
                        document.getElementById("stageNum").innerText = currentStage;
                        loadMission(currentStage);
                    } else {
                        term.prompt();
                    }
                })
                .catch(err => {
                    term.writeln("Error: " + err);
                    term.prompt();
                });

            } else if(ev.key === "Backspace"){
                if(inputBuffer.length > 0){
                    inputBuffer = inputBuffer.slice(0, -1);
                    term.write('\b \b');
                }
            } else if(printable){
                inputBuffer += e.key;
                term.write(e.key);
            }
        });
    </script>
</body>
</html>
