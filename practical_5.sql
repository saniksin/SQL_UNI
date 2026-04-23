-- ================================================================
-- Практична робота 5: DQL команди (Data Query Language)
-- Schema: publishing   |   MySQL 8.0+
-- Передумова: виконано practical_4.sql (база та тестові дані є).
-- ================================================================
-- У роботі відпрацьовуються:
--   - прості SELECT з WHERE та ORDER BY;
--   - з'єднання таблиць через INNER / LEFT JOIN;
--   - агрегати GROUP BY / HAVING;
--   - підзапити з IN / EXISTS / NOT EXISTS;
--   - віконні функції RANK() та DENSE_RANK().
-- ================================================================

USE publishing;

-- ================================================================
-- Задача 1. Прості вибірки
-- ================================================================

-- Усі автори
SELECT * FROM authors;

-- Автори з України
SELECT Name, Country FROM authors WHERE Country = 'Ukraine';

-- Книги, впорядковані за роком видання (від нових до старих)
SELECT Title, Genre, PublishYear FROM books ORDER BY PublishYear DESC;

-- ================================================================
-- Задача 2. Зв'язки між таблицями (JOIN)
-- ================================================================

-- Автори та їх книги (через асоціативну authorbook)
SELECT a.Name AS Author, b.Title AS Book
  FROM authors a
  JOIN authorbook ab ON a.AuthorID = ab.AuthorID
  JOIN books      b  ON b.BookID   = ab.BookID;

-- ================================================================
-- Задача 3. Фільтрація і сортування
-- ================================================================

-- Книги жанру Technology, від новіших до старіших
SELECT Title, Genre, PublishYear
  FROM books
 WHERE Genre = 'Technology'
 ORDER BY PublishYear DESC;

-- ================================================================
-- Задача 4. Агрегація і групування
-- ================================================================

-- Кількість книг у кожному жанрі
SELECT b.Genre, COUNT(*) AS BooksCount
  FROM books b
 GROUP BY b.Genre
 ORDER BY BooksCount DESC;

-- ================================================================
-- Задача 5. Використання HAVING (фільтр по агрегату)
-- ================================================================

-- Книги з виручкою понад 1000
SELECT b.Title,
       SUM(oi.Quantity * oi.UnitPrice) AS Revenue
  FROM orderitem oi
  JOIN books b ON b.BookID = oi.BookID
 GROUP BY b.Title
HAVING Revenue > 1000
 ORDER BY Revenue DESC;

-- ================================================================
-- Задача 6. Вкладені запити
-- ================================================================

-- Книги, що були хоча б раз у замовленні
SELECT b.Title
  FROM books b
 WHERE b.BookID IN (
         SELECT BookID
           FROM orderitem
       );

-- ================================================================
-- Задача 7. Використання EXISTS
-- ================================================================

-- Автори, чиї книги замовляли хоча б раз
SELECT a.Name
  FROM authors a
 WHERE EXISTS (
         SELECT 1
           FROM authorbook ab
           JOIN orderitem  oi ON oi.BookID = ab.BookID
          WHERE ab.AuthorID = a.AuthorID
       );

-- ================================================================
-- Задача 8. Аналітичні (віконні) функції
-- ================================================================

-- RANK у межах жанру за виручкою
WITH sales AS (
  SELECT b.Title, b.Genre,
         SUM(oi.Quantity * oi.UnitPrice) AS Revenue
    FROM orderitem oi
    JOIN books b ON b.BookID = oi.BookID
   GROUP BY b.Title, b.Genre
)
SELECT *,
       RANK() OVER (PARTITION BY Genre ORDER BY Revenue DESC) AS GenreRank
  FROM sales;

-- ================================================================
-- Задача 9. Базові вибірки (просте читання таблиць для перевірки вмісту)
-- ================================================================

-- всі співробітники
SELECT EmployeeID, Name, Role, Email
  FROM employees;

-- всі автори
SELECT AuthorID, Name, Email, Country
  FROM authors;

-- всі книги
SELECT BookID, Title, Genre, ISBN, PublishYear
  FROM books;

-- ================================================================
-- Задача 10. Фільтрація й сортування (типові WHERE + ORDER BY
-- для тематичних підбірок)
-- ================================================================

-- книги певного жанру, від новіших до старіших
SELECT Title, Genre, PublishYear
  FROM books
 WHERE Genre = 'Technology'
 ORDER BY PublishYear DESC;

-- автори з конкретної країни
SELECT Name, Email
  FROM authors
 WHERE Country = 'Ukraine'
 ORDER BY Name;

-- ================================================================
-- Задача 11. JOIN: автори ↔ книги (через authorbook) —
-- показує головного автора кожної книги
-- ================================================================

-- книги з першим автором (AuthorOrder = 1)
SELECT b.BookID, b.Title, a.AuthorID, a.Name AS Author
  FROM authorbook ab
  JOIN authors a ON a.AuthorID = ab.AuthorID
  JOIN books   b ON b.BookID   = ab.BookID
 WHERE ab.AuthorOrder = 1
 ORDER BY b.Title;

-- ================================================================
-- Задача 12. JOIN: співробітники ↔ книги (через employeebook) —
-- «робочі зв'язки» працівників із книжками
-- ================================================================

-- хто і що робив по книгах (Task)
SELECT e.Name  AS Employee,
       b.Title AS Book,
       eb.Task
  FROM employeebook eb
  JOIN employees e ON e.EmployeeID = eb.EmployeeID
  JOIN books     b ON b.BookID     = eb.BookID
 ORDER BY e.Name, b.Title;

-- ================================================================
-- Задача 13. Замовлення з позиціями та сумами —
-- «деталізація» та «підсумок» замовлень
-- ================================================================

-- позиції замовлень
SELECT o.OrderID, o.OrderDate, o.ClientName,
       b.Title,
       oi.Quantity, oi.UnitPrice,
       (oi.Quantity * oi.UnitPrice) AS LineTotal
  FROM orders o
  JOIN orderitem oi ON oi.OrderID = o.OrderID
  JOIN books     b  ON b.BookID   = oi.BookID
 ORDER BY o.OrderDate DESC, o.OrderID;

-- підсумок по замовленню
SELECT o.OrderID, o.OrderDate, o.ClientName,
       SUM(oi.Quantity * oi.UnitPrice) AS OrderTotal
  FROM orders o
  JOIN orderitem oi ON oi.OrderID = o.OrderID
 GROUP BY o.OrderID, o.OrderDate, o.ClientName
 ORDER BY o.OrderDate DESC;

-- ================================================================
-- Задача 14. Агрегації та рейтинги —
-- звіти «скільки книжок» і «які продажі»
-- ================================================================

-- топ-автори за кількістю книжок
SELECT a.AuthorID, a.Name, COUNT(*) AS BooksCount
  FROM authorbook ab
  JOIN authors a ON a.AuthorID = ab.AuthorID
 GROUP BY a.AuthorID, a.Name
 ORDER BY BooksCount DESC, a.Name;

-- продажі за книжками (кількість і сума)
SELECT b.BookID, b.Title,
       SUM(oi.Quantity)                AS QtySold,
       SUM(oi.Quantity * oi.UnitPrice) AS Revenue
  FROM orderitem oi
  JOIN books b ON b.BookID = oi.BookID
 GROUP BY b.BookID, b.Title
 ORDER BY Revenue DESC;

-- ================================================================
-- Задача 15. HAVING (фільтр по агрегату) —
-- фільтр не по рядках, а по результатах групування
-- ================================================================

-- книги з виручкою понад 300
SELECT b.Title,
       SUM(oi.Quantity * oi.UnitPrice) AS Revenue
  FROM orderitem oi
  JOIN books b ON b.BookID = oi.BookID
 GROUP BY b.Title
HAVING Revenue > 300
 ORDER BY Revenue DESC;

-- ================================================================
-- Задача 16. Підзапити та EXISTS —
-- перевірки на наявність / відсутність пов'язаних даних
-- ================================================================

-- автори, чиї книги не замовляли (аналітичний зріз)
SELECT a.AuthorID, a.Name
  FROM authors a
 WHERE NOT EXISTS (
         SELECT 1
           FROM authorbook ab
           JOIN orderitem  oi ON oi.BookID = ab.BookID
          WHERE ab.AuthorID = a.AuthorID
       );

-- ================================================================
-- Задача 17. Дати, статуси, фільтри по періоду —
-- «операційні» підбірки за датами / статусами
-- ================================================================

-- замовлення за період + статус
SELECT OrderID, OrderDate, ClientName, Status
  FROM orders
 WHERE OrderDate BETWEEN DATE '2025-05-01' AND DATE '2025-05-31'
   AND Status IN ('New','Completed')  -- фактичні ENUM зі схеми
 ORDER BY OrderDate DESC;

-- ================================================================
-- Задача 18. Контроль зв'язків авторів та співробітників у контрактах
-- ================================================================

SELECT
  c.ContractID,
  a.Name        AS Author,
  e.Name        AS Employee,
  c.ContractType,
  c.StartDate,
  c.EndDate
  FROM contracts c
  LEFT JOIN authors   a ON a.AuthorID   = c.AuthorID
  LEFT JOIN employees e ON e.EmployeeID = c.EmployeeID
 ORDER BY c.StartDate DESC, c.ContractID;

-- ================================================================
-- Задача 19. Вікна (MySQL 8+): ранжування продажів —
-- показує місце книги в жанровому рейтингу
-- ================================================================

-- ранжування книжок за виручкою (в межах жанру)
WITH sales AS (
  SELECT b.BookID, b.Title, b.Genre,
         SUM(oi.Quantity * oi.UnitPrice) AS Revenue
    FROM orderitem oi
    JOIN books b ON b.BookID = oi.BookID
   GROUP BY b.BookID, b.Title, b.Genre
)
SELECT *,
       DENSE_RANK() OVER (PARTITION BY Genre ORDER BY Revenue DESC) AS GenreRank
  FROM sales
 ORDER BY Genre, GenreRank;

-- ================================================================
-- Висновки (Тема 5)
-- ================================================================
-- TODO: вставити висновки з робочого зошиту.
