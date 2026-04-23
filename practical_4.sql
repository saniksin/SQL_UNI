-- ================================================================
-- Практична робота 4: DDL та DML команди
-- Schema: publishing   |   MySQL 8.0+   |   MySQL Workbench
-- ================================================================
-- Мета: закріпити навички DDL (створення структури) і DML
-- (маніпулювання даними) на прикладі бази видавництва.
-- ================================================================

DROP DATABASE IF EXISTS publishing;

CREATE DATABASE publishing
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_unicode_ci;

USE publishing;

-- ================================================================
-- DDL: створення базових таблиць
-- ================================================================

-- Автори книг
CREATE TABLE Authors (
  AuthorID   INT AUTO_INCREMENT PRIMARY KEY,
  Name       VARCHAR(200) NOT NULL,
  Email      VARCHAR(255) UNIQUE,
  Phone      VARCHAR(50),
  Country    VARCHAR(100)
) ENGINE=InnoDB;

-- Співробітники видавництва
CREATE TABLE Employees (
  EmployeeID INT AUTO_INCREMENT PRIMARY KEY,
  Name       VARCHAR(200) NOT NULL,
  Role       ENUM('Editor','Proofreader','Translator','Designer') NOT NULL,
  Email      VARCHAR(255) UNIQUE
) ENGINE=InnoDB;

-- Книги; ISBN унікальний у межах системи
CREATE TABLE Books (
  BookID       INT AUTO_INCREMENT PRIMARY KEY,
  Title        VARCHAR(300) NOT NULL,
  Genre        VARCHAR(100),
  ISBN         VARCHAR(32) NOT NULL,
  PublishYear  YEAR,
  CONSTRAINT uq_books_isbn UNIQUE (ISBN)
) ENGINE=InnoDB;

-- Замовлення клієнтів
CREATE TABLE Orders (
  OrderID     INT AUTO_INCREMENT PRIMARY KEY,
  OrderDate   DATE NOT NULL,
  ClientName  VARCHAR(200) NOT NULL,
  Status      ENUM('New','InProgress','Completed','Canceled') NOT NULL DEFAULT 'New'
) ENGINE=InnoDB;

-- Контракт належить АБО автору, АБО співробітнику (рівно одному);
-- ексклюзивність власника та відповідність ContractType перевіряються
-- тригерами у практичній роботі 6.
CREATE TABLE Contracts (
  ContractID   INT AUTO_INCREMENT PRIMARY KEY,
  AuthorID     INT NULL,
  EmployeeID   INT NULL,
  ContractType ENUM('Author','Employee') NOT NULL,
  StartDate    DATE NOT NULL,
  EndDate      DATE NULL,
  CONSTRAINT fk_contract_author
    FOREIGN KEY (AuthorID) REFERENCES Authors(AuthorID)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_contract_employee
    FOREIGN KEY (EmployeeID) REFERENCES Employees(EmployeeID)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  INDEX ix_contract_author   (AuthorID),
  INDEX ix_contract_employee (EmployeeID)
) ENGINE=InnoDB;

-- ================================================================
-- DDL: асоціативні (M:N) таблиці
-- ================================================================

-- Автор ↔ Книга (M:N). AuthorOrder — порядковий номер автора у виданні.
CREATE TABLE AuthorBook (
  AuthorID    INT NOT NULL,
  BookID      INT NOT NULL,
  AuthorOrder INT NULL,
  PRIMARY KEY (AuthorID, BookID),
  CONSTRAINT fk_ab_author FOREIGN KEY (AuthorID) REFERENCES Authors(AuthorID)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_ab_book   FOREIGN KEY (BookID)   REFERENCES Books(BookID)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

-- Співробітник ↔ Книга (M:N). Task — роль працівника у проєкті книги.
CREATE TABLE EmployeeBook (
  EmployeeID INT NOT NULL,
  BookID     INT NOT NULL,
  Task       ENUM('Edit','Proofread','Translate','Design') NOT NULL,
  PRIMARY KEY (EmployeeID, BookID),
  CONSTRAINT fk_eb_employee FOREIGN KEY (EmployeeID) REFERENCES Employees(EmployeeID)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_eb_book     FOREIGN KEY (BookID)     REFERENCES Books(BookID)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

-- Замовлення ↔ Книга (M:N). Quantity і UnitPrice — на момент замовлення.
CREATE TABLE OrderItem (
  OrderItemID INT           AUTO_INCREMENT PRIMARY KEY,
  OrderID     INT           NOT NULL,
  BookID      INT           NOT NULL,
  Quantity    INT           NOT NULL,
  UnitPrice   DECIMAL(10,2) NOT NULL,
  CONSTRAINT fk_oi_order FOREIGN KEY (OrderID) REFERENCES Orders(OrderID)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_oi_book  FOREIGN KEY (BookID)  REFERENCES Books(BookID)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  INDEX ix_oi_order (OrderID),
  INDEX ix_oi_book  (BookID),
  CONSTRAINT chk_oi_qty   CHECK (Quantity  >= 1),
  CONSTRAINT chk_oi_price CHECK (UnitPrice >= 0)
) ENGINE=InnoDB;

-- ================================================================
-- DML: INSERT — по 10 записів у кожну таблицю
-- ================================================================

START TRANSACTION;

-- ---- Authors (10) ----
INSERT INTO Authors (Name, Email, Phone, Country) VALUES
  ('Ірина Савчук',  'iryna.savchuk@ex.com', '+380501111111', 'Ukraine'),
  ('Олег Петренко', 'oleg.petrenko@ex.com', '+380671111112', 'Ukraine'),
  ('Maria Rossi',   'm.rossi@ex.com',       '+39061111111',  'Italy'),
  ('Jean Martin',   'jean.martin@ex.com',   '+33111111111',  'France'),
  ('Anna Müller',   'anna.mueller@ex.com',  '+41441111111',  'Switzerland'),
  ('Lukas Steiner', 'lukas.steiner@ex.com', '+41441111112',  'Switzerland'),
  ('Sofia Garcia',  'sofia.garcia@ex.com',  '+34911111111',  'Spain'),
  ('Noah Johnson',  'noah.johnson@ex.com',  '+12025550111',  'USA'),
  ('Akira Tanaka',  'akira.tanaka@ex.com',  '+81311111111',  'Japan'),
  ('Eva Novak',     'eva.novak@ex.com',     '+42021111111',  'Czechia');

-- ---- Employees (10) ----
INSERT INTO Employees (Name, Role, Email) VALUES
  ('Alice Novak',     'Editor',      'alice@pub.ch'),
  ('Bohdan Petrenko', 'Proofreader', 'bohdan@pub.ch'),
  ('Chloe Martin',    'Translator',  'chloe@pub.ch'),
  ('Dmytro Savchuk',  'Designer',    'dmytro@pub.ch'),
  ('Emma Rossi',      'Editor',      'emma@pub.ch'),
  ('Felix Weber',     'Proofreader', 'felix@pub.ch'),
  ('Hanna Kovalenko', 'Translator',  'hanna@pub.ch'),
  ('Ivan Horak',      'Designer',    'ivan@pub.ch'),
  ('Julia Novakova',  'Editor',      'julia@pub.ch'),
  ('Karl Meier',      'Proofreader', 'karl@pub.ch');

-- ---- Books (10). ISBN унікальний. ----
INSERT INTO Books (Title, Genre, ISBN, PublishYear) VALUES
  ('Python для початківців', 'Навчальна',   '978-0-100000-001', 2023),
  ('SQL на практиці',        'Навчальна',   '978-0-100000-002', 2024),
  ('Data Analytics 101',     'Навчальна',   '978-0-100000-003', 2025),
  ('Story Craft',            'Fiction',     '978-0-100000-004', 2022),
  ('Mountains & Lakes',      'Travel',      '978-0-100000-005', 2021),
  ('AI for Editors',         'Technology',  '978-0-100000-006', 2025),
  ('Clean Data',             'Non-Fiction', '978-0-100000-007', 2020),
  ('Sci-Fi Tales',           'Sci-Fi',      '978-0-100000-008', 2019),
  ('Business Blue',          'Business',    '978-0-100000-009', 2024),
  ('Creative SQL',           'Technology',  '978-0-100000-010', 2023);

-- ---- Orders (10) ----
INSERT INTO Orders (OrderDate, ClientName, Status) VALUES
  ('2025-01-10', 'TechBooks GmbH', 'New'),
  ('2025-01-15', 'EduLab SA',      'Completed'),
  ('2025-02-01', 'DataWorks AG',   'InProgress'),
  ('2025-02-18', 'Libra LLC',      'Completed'),
  ('2025-03-03', 'Orion Labs',     'New'),
  ('2025-03-20', 'Pixel Media',    'InProgress'),
  ('2025-04-05', 'QuickLearn',     'Completed'),
  ('2025-04-22', 'Read&Co',        'New'),
  ('2025-05-09', 'Star Books',     'Completed'),
  ('2025-05-25', 'Nova Print',     'Canceled');

-- ---- AuthorBook (10) — зв'язок авторів і книг ----
INSERT INTO AuthorBook (AuthorID, BookID, AuthorOrder) VALUES
  (1,  1, 1),   -- Ірина Савчук   ← Python для початківців
  (2,  2, 1),   -- Олег Петренко  ← SQL на практиці
  (3,  3, 1),   -- Maria Rossi    ← Data Analytics 101
  (4,  4, 1),   -- Jean Martin    ← Story Craft
  (5,  5, 1),   -- Anna Müller    ← Mountains & Lakes
  (6,  6, 1),   -- Lukas Steiner  ← AI for Editors
  (7,  7, 1),   -- Sofia Garcia   ← Clean Data
  (8,  8, 1),   -- Noah Johnson   ← Sci-Fi Tales
  (9,  9, 1),   -- Akira Tanaka   ← Business Blue
  (10, 10, 1);  -- Eva Novak      ← Creative SQL

-- ---- EmployeeBook (10) — робочі зв'язки співробітників із книгами ----
INSERT INTO EmployeeBook (EmployeeID, BookID, Task) VALUES
  (1,  1, 'Edit'),
  (2,  1, 'Proofread'),
  (3,  2, 'Translate'),
  (4,  2, 'Design'),
  (5,  3, 'Edit'),
  (6,  4, 'Proofread'),
  (7,  5, 'Translate'),
  (8,  6, 'Design'),
  (9,  7, 'Edit'),
  (10, 8, 'Proofread');

-- ---- Contracts (10) — рівно один власник у кожного ----
INSERT INTO Contracts (AuthorID, EmployeeID, ContractType, StartDate, EndDate) VALUES
  (1,    NULL, 'Author',   '2024-01-15', '2025-12-31'),
  (2,    NULL, 'Author',   '2024-03-01', '2025-12-31'),
  (3,    NULL, 'Author',   '2024-05-10', '2026-05-10'),
  (4,    NULL, 'Author',   '2024-06-01', NULL),
  (5,    NULL, 'Author',   '2024-07-15', '2025-12-31'),
  (NULL, 1,    'Employee', '2023-09-01', NULL),
  (NULL, 2,    'Employee', '2023-10-01', NULL),
  (NULL, 3,    'Employee', '2024-01-15', NULL),
  (NULL, 4,    'Employee', '2024-02-01', '2025-12-31'),
  (NULL, 5,    'Employee', '2024-03-10', NULL);

-- ---- OrderItem (10) — позиції замовлень ----
INSERT INTO OrderItem (OrderID, BookID, Quantity, UnitPrice) VALUES
  (1,  1,   5, 350.00),
  (1,  2,   3, 420.00),
  (2,  3,  10, 400.00),
  (3,  4,   2, 280.00),
  (4,  5,   7, 310.00),
  (5,  6,   4, 520.00),
  (6,  7,   6, 290.00),
  (7,  8,   8, 230.00),
  (8,  9,   1, 610.00),
  (9, 10,  12, 380.00),
  (10, 1,  2, 350.00);  -- ця позиція видалиться каскадом після DELETE Orders(10)

COMMIT;

-- ================================================================
-- DML: UPDATE — оновлення записів
-- ================================================================

-- Змінити статус замовлення 5 з 'New' на 'InProgress'
UPDATE Orders
   SET Status = 'InProgress'
 WHERE OrderID = 5;

-- Оновити рік видання книги 1 (перевидання)
UPDATE Books
   SET PublishYear = 2024
 WHERE BookID = 1;

-- Закрити контракт співробітника 3 (встановити EndDate)
UPDATE Contracts
   SET EndDate = '2025-12-31'
 WHERE EmployeeID = 3 AND ContractType = 'Employee';

-- ================================================================
-- DML: DELETE — видалення з каскадним ефектом
-- ================================================================

-- Видалити скасоване замовлення 10 — каскадом видаляється й OrderItem (10, 1)
DELETE FROM Orders WHERE OrderID = 10;

-- ================================================================
-- SELECT + JOIN: перевірка коректності даних
-- ================================================================

-- Книги разом з їхніми авторами
SELECT b.BookID, b.Title, a.Name AS Author
  FROM Books b
  JOIN AuthorBook ab ON ab.BookID = b.BookID
  JOIN Authors    a  ON a.AuthorID = ab.AuthorID
 ORDER BY b.BookID;

-- Замовлення з позиціями та підсумковою сумою
SELECT o.OrderID,
       o.ClientName,
       o.Status,
       SUM(oi.Quantity * oi.UnitPrice) AS OrderTotal
  FROM Orders o
  JOIN OrderItem oi ON oi.OrderID = o.OrderID
 GROUP BY o.OrderID, o.ClientName, o.Status
 ORDER BY o.OrderID;

-- Контракти з іменем власника (автор або співробітник)
SELECT c.ContractID,
       c.ContractType,
       COALESCE(a.Name, e.Name) AS OwnerName,
       c.StartDate,
       c.EndDate
  FROM Contracts c
  LEFT JOIN Authors   a ON a.AuthorID   = c.AuthorID
  LEFT JOIN Employees e ON e.EmployeeID = c.EmployeeID
 ORDER BY c.StartDate DESC;

-- ================================================================
-- Підрахунок рядків у всіх таблицях (очікувані значення — див. README)
-- ================================================================

SELECT 'Authors'      AS Tbl, COUNT(*) AS Cnt FROM Authors
UNION ALL SELECT 'Employees',   COUNT(*) FROM Employees
UNION ALL SELECT 'Books',       COUNT(*) FROM Books
UNION ALL SELECT 'Orders',      COUNT(*) FROM Orders
UNION ALL SELECT 'AuthorBook',  COUNT(*) FROM AuthorBook
UNION ALL SELECT 'EmployeeBook',COUNT(*) FROM EmployeeBook
UNION ALL SELECT 'Contracts',   COUNT(*) FROM Contracts
UNION ALL SELECT 'OrderItem',   COUNT(*) FROM OrderItem;

-- ================================================================
-- Висновки (заповни/відкоригуй)
-- ================================================================
-- У практичній роботі створено схему `publishing` з 8 таблиць, що відповідає
-- ER-моделі з практичної роботи 3. Усі первинні та зовнішні ключі,
-- обмеження UNIQUE і CHECK задані в DDL; складніші бізнес-правила
-- (ексклюзивний власник контракту, узгодженість дат) винесено в тригери
-- (практична 6). Тестові DML-операції (INSERT по 10 записів у кожну
-- таблицю, UPDATE, DELETE, SELECT з JOIN) підтверджують коректну роботу
-- зв'язків: каскадне видалення позицій замовлення, UNIQUE на ISBN/Email,
-- посилання у FK. База готова до виконання DQL-запитів (практична 5).
