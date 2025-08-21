<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page session="true" %>
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <title>DB 해킹 게임</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/xterm/css/xterm.css" />
    <script src="https://cdn.jsdelivr.net/npm/xterm/lib/xterm.js"></script>
    <style>
        body { font-family: monospace; background: #111; color: #0f0; }
        #terminal { width: 100%; height: 500px; background: #000; color: #0f0; padding: 10px; overflow-y:auto; border:1px solid #0f0; }
        h1 { color:#0f0; }
    </style>
</head>
<body>
<h1>DB 해킹 게임 - Stage <span id="stageNum">1</span></h1>
<div id="terminal"></div>

<script>
const username = '<%= session.getAttribute("username") != null ? session.getAttribute("username") : "Guest" %>';
let currentStage = 1;

const term = new Terminal({ cursorBlink:true, rows:25, cols:80, theme:{ background:'#000', foreground:'#0f0' }});
term.open(document.getElementById('terminal'));
term.writeln('Welcome ' + username + '!');
term.writeln('Type your SQL command and press Enter.');
term.prompt = () => term.write('\r\n$ ');
term.prompt();

let inputBuffer = '';

// 서버에서 테이블 결과를 콘솔에 표시하는 함수
function printTable(rows){
    if(!rows || rows.length===0){ term.writeln("Empty result."); return; }
    const headers = Object.keys(rows[0]);
    const colWidths = headers.map(h => h.length);

    rows.forEach(r=>{
        headers.forEach((h,i)=>{ colWidths[i] = Math.max(colWidths[i], (r[h]||'').length); });
    });

    const headerLine = headers.map((h,i)=>h.padEnd(colWidths[i])).join(" | ");
    term.writeln(headerLine);
    term.writeln(headers.map((h,i)=>"-".repeat(colWidths[i])).join("-+-"));

    rows.forEach(r=>{
        const line = headers.map((h,i)=>(r[h]||'').padEnd(colWidths[i])).join(" | ");
        term.writeln(line);
    });
}

// 초기 미션 로딩
function loadMission(stageId){
    fetch('<%= request.getContextPath() %>/stageApi?stageId=' + stageId)
    .then(res=>res.json())
    .then(data=>{
        term.writeln("\r\nMission: " + data.description);
        term.prompt();
    })
    .catch(err=>{
        term.writeln("Error loading mission: " + err);
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
            term.writeln(data.msg);
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
            term.writeln("Error: " + err);
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
