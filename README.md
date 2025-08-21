# SQL Hacker

🎮 SQL Hacker는 SQL 쿼리를 통해 데이터베이스를 해킹하며 스테이지를 클리어해 나가는 웹 기반 게임입니다. 각 스테이지마다 주어지는 미션을 해결하여 다음 단계로 진행하세요.

🔗 게임 바로가기 : https://jdbc-hacking-game.onrender.com

## [PREVIEW]
![미리보기](https://github.com/user-attachments/assets/b5a77f63-d5c3-4850-9991-6d47f20d00d1)



## [주요 기능]
- 단계별 미션 : 각 스테이지 마다 SQL 쿼리를 이용한 문제를 해결합니다.
- 실시간 피드백 : 쿼리 실행 결과를 테이블 형식으로 확인할 수 있습니다.
- 터미널 인터페이스 : `xterm.js`를 활용한 실감나는 터미널 환경을 제공합니다.

## [기술 스택]
- 백엔드 : Java Servlet, JDBC
- 프론트엔드 : HTML, CSS, Javascript, [xterm.js](https://xtermjs.org/)
- 데이터베이스: MySQL
- 라이브러리: Gson(JSON 처리)
- 배포: [render](https://render.com/) with Dockerfile

## [실행 방법]
1. 프로젝트 클론
  ```bash
  git clone https://github.com/pkrystal95/jdbc_hacking_game.git
  cd jdbc_hacking_game
   ```
2. 의존성 설치
  - Maven 동기화를 통해 pom.xml에 정의된 의존성을 설치합니다.
3. 데이터베이스 설정
  - init.sql 파일을 사용하여 MySQL 데이터베이스를 설정합니다.
4. 사버실행
  - Tomcat과 같은 서블릿 컨테이너에 프로젝트를 배포하여 서버를 실행시킵니다.

## [게임 진행 방법]
1. 각 스테이지마다 주어지는 SQL 문제를 해결합니다.
2. 정답을 입력하면 다음 스테이지로 진행하며, 결과는 실시간으로 터미널에 출력됩니다.

## [TODO]
1. 로그인 기능
2. 클리어 타임 기준으로 랭킹
3. 진행 상황 저장
4. UI 개선
