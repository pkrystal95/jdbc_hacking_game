<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page session="true" %>
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <title>SQL Hacker - 몰입형 SQL 해킹 게임</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/xterm/css/xterm.css" />
    <script src="https://cdn.jsdelivr.net/npm/xterm/lib/xterm.js"></script>

    <link rel="icon" type="image/x-icon" href="./static/favicon.ico">
    <!-- Open Graph 메타데이터 -->
    <meta property="og:title" content="SQL Hacker - 몰입형 SQL 해킹 게임" />
    <meta property="og:description" content="단계별 SQL 도전을 통해 DB 해킹 미션을 클리어하세요! 실시간 피드백과 몰입형 스테이지 제공" />
    <meta property="og:image" content="./static/thumbnail.png" />
    <meta property="og:url" content="https://jdbc-hacking-game.onrender.com" />
    <meta property="og:type" content="website" />

    <style>
        body {
            font-family: 'Menlo', 'Monaco', 'Consolas', 'Courier New', monospace;
            background-color: #3a3a3a;
            color: #dcdcdc;
            margin: 0;
            padding: 20px;
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
            box-sizing: border-box;
        }

        /* iTerm 스타일의 메인 윈도우 프레임 */
        .iterm-window {
            width: 60vw;
            max-width: 900px;
            height: 60vh;
            background-color: #282c34;
            border-radius: 8px;
            box-shadow: 0 10px 30px rgba(0, 0, 0, 0.5);
            display: flex;
            flex-direction: column;
            overflow: hidden;
        }

        /* 상단 타이틀 바 */
        .title-bar {
            background-color: #3c4048;
            padding: 8px 12px;
            display: flex;
            align-items: center;
            user-select: none;
        }

        /* 신호등 컨트롤 버튼 */
        .controls {
            display: flex;
            gap: 8px;
        }
        .controls span {
            display: block;
            width: 12px;
            height: 12px;
            border-radius: 50%;
        }
        .close { background-color: #ff5f56; }
        .minimize { background-color: #ffbd2e; }
        .maximize { background-color: #27c93f; }

        /* 타이틀 텍스트 */
        .title {
            color: #abb2bf;
            font-size: 14px;
            text-align: center;
            flex-grow: 1;
            margin-right: 60px;
        }

        /* 윈도우 컨텐츠 영역 (터미널) */
        #window-content {
            flex-grow: 1;
            display: flex;
            padding: 10px;
            box-sizing: border-box;
        }

        /* 터미널 스타일 */
        #terminal {
            background-color: transparent;
            border: none;
            padding: 10px;
            flex: 1; /* 컨텐츠 영역을 모두 차지 */
        }

        /* xterm.js 터미널의 스크롤바 스타일링 */
        .xterm-viewport::-webkit-scrollbar {
            width: 8px;
        }
        .xterm-viewport::-webkit-scrollbar-track {
            background: #282c34;
        }
        .xterm-viewport::-webkit-scrollbar-thumb {
            background-color: #4b5263;
            border-radius: 4px;
        }
    </style>
</head>
<body>

<div class="iterm-window">
    <div class="title-bar">
        <div class="controls">
            <span class="close"></span>
            <span class="minimize"></span>
            <span class="maximize"></span>
        </div>
        <div class="title">DB 해킹 게임 - Stage <span id="stageNum">1</span></div>
    </div>

    <div id="window-content">
        <div id="terminal"></div>
    </div>
</div>

<script>
const username = '<%= session.getAttribute("username") != null ? session.getAttribute("username") : "Guest" %>';
let currentStage = 1;

// xterm.js 터미널 초기화
const term = new Terminal({
    cursorBlink: true,
    fontFamily: `'Menlo', 'Monaco', 'Consolas', 'Courier New', monospace`,
    fontSize: 14,
    theme: {
        background: '#282c34',
        foreground: '#00ff00',
        cursor: '#00ff00',
        selectionBackground: '#4b5263'
    }
});
term.open(document.getElementById('terminal'));
term.writeln('Welcome ' + username + '!');
term.writeln('Type your SQL command and press Enter.');
term.prompt = () => term.write('\r\n$ ');
term.prompt();

let inputBuffer = '';

// 서버에서 테이블 결과를 콘솔에 출력
function printTable(rows){
    if(!rows || rows.length===0){ term.writeln("Empty result."); return; }
    const headers = Object.keys(rows[0]);
    const colWidths = headers.map(h => h.length);

    rows.forEach(r=>{
        headers.forEach((h,i)=>{ colWidths[i] = Math.max(colWidths[i], String(r[h] || '').length); });
    });

    const headerLine = headers.map((h,i)=>h.padEnd(colWidths[i])).join(" | ");
    term.writeln(headerLine);
    term.writeln(headers.map((h,i)=>"-".repeat(colWidths[i])).join("-+-"));

    rows.forEach(r=>{
        const line = headers.map((h,i)=>String(r[h]||'').padEnd(colWidths[i])).join(" | ");
        term.writeln(line);
    });
}

// 미션 로딩 (터미널에만 출력)
function loadMission(stageId){
    fetch('<%= request.getContextPath() %>/stageApi?stageId=' + stageId)
        .then(res=>res.json())
        .then(data=>{
            term.writeln("\r\n\u001b[36m" + "Mission loaded: " + data.description + "\u001b[0m"); // 청록색으로 미션 출력
            term.prompt();
        })
        .catch(err=>{
            term.writeln("\u001b[31m" + "Error loading mission: " + err + "\u001b[0m"); // 빨간색으로 에러 출력
            term.prompt();
        });
}

loadMission(currentStage);

// 터미널 입력 이벤트
term.onKey(e=>{
    const ev = e.domEvent;
    const printable = !ev.altKey && !ev.ctrlKey && !ev.metaKey;

    if(ev.key==="Enter"){
        term.writeln('');
        const sql = inputBuffer.trim();
        inputBuffer = '';

        if(!sql){ term.prompt(); return; }

        fetch('<%= request.getContextPath() %>/stage', {
            method:'POST',
            headers:{'Content-Type':'application/x-www-form-urlencoded'},
            body:`username=${encodeURIComponent(username)}&stageId=${currentStage}&sql=${encodeURIComponent(sql)}`
        })
        .then(res=>res.json())
        .then(data=>{
            // 응답 상태에 따라 텍스트 색상 변경
            const color = data.status === "success" ? "\u001b[32m" : "\u001b[31m"; // 성공: 녹색, 실패: 빨간색
            term.writeln(color + data.msg + "\u001b[0m");

            if(data.table) printTable(data.table);

            if(data.status==="success"){
                currentStage = data.nextStage;
                document.getElementById("stageNum").innerText = currentStage;
                loadMission(currentStage);
            } else {
                term.prompt();
            }
        })
        .catch(err=>{
            term.writeln("\u001b[31m" + "Error: " + err + "\u001b[0m");
            term.prompt();
        });

    } else if(ev.key==="Backspace"){
        if(inputBuffer.length>0){
            inputBuffer = inputBuffer.slice(0,-1);
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