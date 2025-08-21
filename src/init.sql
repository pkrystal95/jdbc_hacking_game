-- =====================================
-- DATABASE & TABLES
-- =====================================
CREATE DATABASE IF NOT EXISTS dbhack;
USE dbhack;

-- ===== members 테이블 =====
CREATE TABLE IF NOT EXISTS members (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(50),
  age INT,
  country VARCHAR(50),
  role VARCHAR(20) DEFAULT 'user'
);

INSERT INTO members (name, age, country, role) VALUES
('Alice', 25, 'USA', 'user'),
('Bob', 30, 'Korea', 'user'),
('Carol', 18, 'Japan', 'user'),
('Dave', 40, 'USA', 'admin'),
('Eve', 35, 'Korea', 'user');

-- ===== orders 테이블 =====
CREATE TABLE IF NOT EXISTS orders (
  id INT AUTO_INCREMENT PRIMARY KEY,
  member_id INT,
  product VARCHAR(50),
  amount INT,
  FOREIGN KEY (member_id) REFERENCES members(id)
);

INSERT INTO orders (member_id, product, amount) VALUES
(1, 'Laptop', 1500),
(2, 'Phone', 800),
(2, 'Headset', 200),
(3, 'Keyboard', 100),
(4, 'Server', 5000),
(5, 'Monitor', 300);

-- ===== logins 테이블 =====
CREATE TABLE IF NOT EXISTS logins (
  id INT AUTO_INCREMENT PRIMARY KEY,
  member_id INT,
  login_date DATE,
  FOREIGN KEY (member_id) REFERENCES members(id)
);

INSERT INTO logins (member_id, login_date) VALUES
(1, '2025-01-10'),
(2, '2025-03-15'),
(3, '2024-12-20'),
(4, '2025-04-01'),
(5, '2025-02-25');

-- ===== credentials 테이블 =====
CREATE TABLE IF NOT EXISTS credentials (
  id INT AUTO_INCREMENT PRIMARY KEY,
  member_id INT,
  password_hash VARCHAR(255),
  FOREIGN KEY (member_id) REFERENCES members(id)
);

INSERT INTO credentials (member_id, password_hash) VALUES
(4, 'hash_admin123'),
(1, 'hash_alice'),
(2, 'hash_bob');

-- ===== root_password 테이블 =====
CREATE TABLE IF NOT EXISTS root_password (
  id INT AUTO_INCREMENT PRIMARY KEY,
  password_hash VARCHAR(255)
);

INSERT INTO root_password (password_hash) VALUES
('hash_root_secret');

-- ===== stages 테이블 (정답 SQL 저장) =====
CREATE TABLE IF NOT EXISTS stages (
  id INT PRIMARY KEY,
  description TEXT NOT NULL,
  solution_sql TEXT NOT NULL
);

-- Stage 1~20 초기화
INSERT INTO stages (id, description, solution_sql) VALUES
(1, '첫 번째 방! DB 서버에 접속했다. members 테이블 구조를 확인해 계정 정보를 파악하라.', 'DESCRIBE members;'),
(2, '서버 내부 계정을 수집해야 한다. members 테이블의 모든 사용자 데이터를 출력하라.', 'SELECT * FROM members;'),
(3, '탐지 시스템을 피하려면 20세 이상 사용자만 조사해야 한다. 필터링하라.', 'SELECT name, age FROM members WHERE age >= 20;'),
(4, '국내 사용자를 우선 조사하라. country="Korea"인 사용자만 출력하라.', 'SELECT * FROM members WHERE country = ''Korea'';'),
(5, '공격 우선순위를 정하려면 나이가 많은 순으로 정렬하라.', 'SELECT * FROM members ORDER BY age DESC;'),
(6, '국가별 분포를 파악하여 전략을 수립하라. 중복 없이 모든 국가를 출력하라.', 'SELECT DISTINCT country FROM members;'),
(7, '전체 DB 규모를 확인하라. 사용자 수를 계산하라.', 'SELECT COUNT(*) FROM members;'),
(8, '국가별 계정 수를 확인하여 침투 우선순위를 정하라.', 'SELECT country, COUNT(*) AS cnt FROM members GROUP BY country;'),
(9, '계정이 2명 이상인 국가를 출력하여 집중 공격 지역을 파악하라.', 'SELECT country, COUNT(*) AS cnt FROM members GROUP BY country HAVING COUNT(*) >= 2;'),
(10, '사용자별 주문 내역을 확인하라. members와 orders를 결합하라.', 'SELECT m.name, o.product FROM members m JOIN orders o ON m.id = o.member_id;'),
(11, '각 사용자의 주문 수를 확인하여 구매 패턴을 분석하라.', 'SELECT m.name, COUNT(o.id) AS order_count FROM members m JOIN orders o ON m.id = o.member_id GROUP BY m.name;'),
(12, '금액이 가장 높은 주문을 추적하라.', 'SELECT m.name FROM members m JOIN orders o ON m.id = o.member_id WHERE o.amount = (SELECT MAX(amount) FROM orders);'),
(13, '각 사용자별 총 구매 금액을 계산하라.', 'SELECT m.name, SUM(o.amount) AS total FROM members m JOIN orders o ON m.id = o.member_id GROUP BY m.name;'),
(14, '총 구매액 1000 이상인 VIP 사용자를 확인하라.', 'SELECT m.name, SUM(o.amount) AS total FROM members m JOIN orders o ON m.id = o.member_id GROUP BY m.name HAVING total >= 1000;'),
(15, 'Laptop 구매자를 찾고, 장비 집중 공격 목표를 선정하라.', 'SELECT m.name FROM members m JOIN orders o ON m.id = o.member_id WHERE o.product = ''Laptop'';'),
(16, '평균 구매액 이상 사용자만 출력하여 전략을 조정하라.', 'SELECT m.name, SUM(o.amount) AS total FROM members m JOIN orders o ON m.id = o.member_id GROUP BY m.name HAVING total > (SELECT AVG(amount) FROM orders);'),
(17, '최근 로그인한 사용자를 추적하라 (2025-01-01 이후).', 'SELECT m.name, l.login_date FROM members m JOIN logins l ON m.id = l.member_id WHERE l.login_date >= ''2025-01-01'';'),
(18, '관리자 계정을 찾아라.', 'SELECT name FROM members WHERE role = ''admin'';'),
(19, '관리자 계정의 비밀번호 해시를 확인하라.', 'SELECT m.name, c.password_hash FROM members m JOIN credentials c ON m.id = c.member_id WHERE m.role = ''admin'';'),
(20, '마지막 단계! root 패스워드를 확인하여 DB 최고 권한을 확보하라.', 'SELECT password_hash FROM root_password;');


-- ===== ranking 테이블 (사용자 진행 기록) =====
CREATE TABLE IF NOT EXISTS ranking (
  id INT AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(50) NOT NULL,
  cleared_stage INT NOT NULL,
  cleared_time DATETIME NOT NULL
);
