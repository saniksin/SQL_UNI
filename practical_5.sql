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
-- Логіка: вибирає всі записи і всі стовпці з таблиці authors.
-- Результат: показує всю таблицю авторів без фільтрації.
SELECT * FROM authors;

-- Автори з України
-- Логіка: вибирає тільки поля Name і Country для авторів, у яких країна = Ukraine.
-- Результат: показує список українських авторів.
SELECT Name, Country FROM authors WHERE Country = 'Ukraine';

-- Книги, впорядковані за роком видання (від нових до старих)
-- Логіка: вибирає Title, Genre, PublishYear з таблиці books і сортує за роком видання від нових до старих.
-- Результат: список книг у порядку від найновіших до найстаріших.
SELECT Title, Genre, PublishYear FROM books ORDER BY PublishYear DESC;

-- ================================================================
-- Задача 2. Зв'язки між таблицями (JOIN)
-- ================================================================

-- Автори та їх книги (через асоціативну authorbook)
-- Логіка: з'єднує authors → authorbook → books за ключами AuthorID і BookID, вибирає ім'я автора і назву книги.
-- Результат: пари «автор — книга» для всіх записів у authorbook.
SELECT a.Name AS Author, b.Title AS Book
  FROM authors a
  JOIN authorbook ab ON a.AuthorID = ab.AuthorID
  JOIN books      b  ON b.BookID   = ab.BookID;

-- ================================================================
-- Задача 3. Фільтрація і сортування
-- ================================================================

-- Книги жанру Technology, від новіших до старіших
-- Логіка: фільтрує books за Genre = 'Technology' і сортує результат за PublishYear у спадному порядку.
-- Результат: список технологічних книг від найновіших до найстаріших.
SELECT Title, Genre, PublishYear
  FROM books
 WHERE Genre = 'Technology'
 ORDER BY PublishYear DESC;

-- ================================================================
-- Задача 4. Агрегація і групування
-- ================================================================

-- Кількість книг у кожному жанрі
-- Логіка: групує книги за полем Genre і рахує COUNT(*) для кожної групи.
-- Результат: перелік жанрів із кількістю книг у кожному, впорядкований за спаданням.
SELECT b.Genre, COUNT(*) AS BooksCount
  FROM books b
 GROUP BY b.Genre
 ORDER BY BooksCount DESC;

-- ================================================================
-- Задача 5. Використання HAVING (фільтр по агрегату)
-- ================================================================

-- Книги з виручкою понад 1000
-- Логіка: через JOIN з orderitem рахує SUM(Quantity * UnitPrice) по кожній книзі і відсіює через HAVING ті, у яких виручка ≤ 1000.
-- Результат: список книг-лідерів з виручкою понад 1000.
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
-- Логіка: зовнішній запит бере всі книги; підзапит повертає BookID, що зустрічаються в orderitem; IN відсіює решту.
-- Результат: книги, які фактично продавалися (є в позиціях замовлень).
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
-- Логіка: для кожного автора перевіряє, чи існує зв'язок authorbook + orderitem; EXISTS повертає TRUE, якщо знайдено хоч один такий рядок.
-- Результат: автори, у яких продавалася хоча б одна книга.
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
-- Логіка: CTE sales рахує виручку по книзі в розрізі жанру; RANK() OVER (PARTITION BY Genre ORDER BY Revenue DESC) присвоює місце книзі в межах її жанру.
-- Результат: список книг із виручкою і місцем у жанровому рейтингу.
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
-- Логіка: вибирає ключові поля employees без фільтрації.
-- Результат: повний довідник співробітників із роллю та email.
SELECT EmployeeID, Name, Role, Email
  FROM employees;

-- всі автори
-- Логіка: вибирає ключові поля authors без фільтрації.
-- Результат: повний довідник авторів із країною та email.
SELECT AuthorID, Name, Email, Country
  FROM authors;

-- всі книги
-- Логіка: вибирає ключові поля books без фільтрації.
-- Результат: повний каталог книг із жанром, ISBN та роком видання.
SELECT BookID, Title, Genre, ISBN, PublishYear
  FROM books;

-- ================================================================
-- Задача 10. Фільтрація й сортування (типові WHERE + ORDER BY
-- для тематичних підбірок)
-- ================================================================

-- книги певного жанру, від новіших до старіших
-- Логіка: фільтрує books за Genre = 'Technology' і сортує за PublishYear DESC.
-- Результат: тематична підбірка технологічних книг у порядку новіші → старіші.
SELECT Title, Genre, PublishYear
  FROM books
 WHERE Genre = 'Technology'
 ORDER BY PublishYear DESC;

-- автори з конкретної країни
-- Логіка: фільтрує authors за Country = 'Ukraine' і сортує за Name.
-- Результат: алфавітний список українських авторів з email.
SELECT Name, Email
  FROM authors
 WHERE Country = 'Ukraine'
 ORDER BY Name;

-- ================================================================
-- Задача 11. JOIN: автори ↔ книги (через authorbook) —
-- показує головного автора кожної книги
-- ================================================================

-- книги з першим автором (AuthorOrder = 1)
-- Логіка: з'єднує authorbook з authors і books, але залишає тільки рядки з AuthorOrder = 1 — головного автора; сортує за назвою книги.
-- Результат: кожна книга з її головним автором.
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
-- Логіка: з'єднує employeebook з employees і books, щоб показати роль кожного співробітника у проєкті кожної книги.
-- Результат: таблиця «співробітник — книга — Task (Edit/Proofread/Translate/Design)».
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
-- Логіка: з'єднує orders, orderitem і books, обчислює LineTotal = Quantity × UnitPrice для кожної позиції.
-- Результат: «деталізація» — по одному рядку на кожну книгу в замовленні з її вартістю.
SELECT o.OrderID, o.OrderDate, o.ClientName,
       b.Title,
       oi.Quantity, oi.UnitPrice,
       (oi.Quantity * oi.UnitPrice) AS LineTotal
  FROM orders o
  JOIN orderitem oi ON oi.OrderID = o.OrderID
  JOIN books     b  ON b.BookID   = oi.BookID
 ORDER BY o.OrderDate DESC, o.OrderID;

-- підсумок по замовленню
-- Логіка: групує за OrderID / OrderDate / ClientName і рахує SUM(Quantity * UnitPrice) по кожному замовленню.
-- Результат: «підсумок» — одна підсумкова сума (OrderTotal) на кожне замовлення.
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
-- Логіка: групує authorbook за AuthorID і рахує кількість книг у кожного автора.
-- Результат: рейтинг авторів за кількістю написаних книг (від більшого до меншого).
SELECT a.AuthorID, a.Name, COUNT(*) AS BooksCount
  FROM authorbook ab
  JOIN authors a ON a.AuthorID = ab.AuthorID
 GROUP BY a.AuthorID, a.Name
 ORDER BY BooksCount DESC, a.Name;

-- продажі за книжками (кількість і сума)
-- Логіка: групує orderitem за книгою і одночасно рахує SUM(Quantity) та SUM(Quantity * UnitPrice).
-- Результат: по кожній книзі — скільки екземплярів продано і на яку суму.
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
-- Логіка: групує orderitem по книзі, рахує Revenue = SUM(Quantity * UnitPrice), HAVING лишає тільки групи з Revenue > 300.
-- Результат: книги, які принесли понад 300 виручки.
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
-- Логіка: для кожного автора перевіряє відсутність зв'язку authorbook + orderitem; NOT EXISTS залишає лише тих, для кого підзапит порожній.
-- Результат: автори, чиї книги жодного разу не з'являлися в позиціях замовлень.
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
-- Логіка: фільтрує orders за діапазоном BETWEEN '2025-05-01' AND '2025-05-31' і списком Status IN ('New','Completed'); сортує за OrderDate DESC.
-- Результат: операційний зріз замовлень за травень 2025 зі статусами New або Completed.
SELECT OrderID, OrderDate, ClientName, Status
  FROM orders
 WHERE OrderDate BETWEEN DATE '2025-05-01' AND DATE '2025-05-31'
   AND Status IN ('New','Completed')  -- фактичні ENUM зі схеми
 ORDER BY OrderDate DESC;

-- ================================================================
-- Задача 18. Контроль зв'язків авторів та співробітників у контрактах
-- ================================================================

-- Логіка: LEFT JOIN з authors і employees за nullable FK у contracts — для кожного контракту підтягується ім'я власника (або автора, або співробітника).
-- Результат: повний реєстр контрактів зі зрозумілими іменами власників, відсортований за StartDate DESC.
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
-- Логіка: CTE sales рахує виручку по книзі з її жанром; DENSE_RANK() OVER (PARTITION BY Genre ORDER BY Revenue DESC) призначає щільний ранг у межах жанру (без пропусків при рівних значеннях).
-- Результат: кожна книга зі своїм рангом у жанрі — 1 у лідера, 2 у наступного і так далі.
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
-- У ході виконання практичної роботи було відпрацьовано весь базовий
-- набір команд мови запитів DQL на схемі publishing. Виконано 19 задач,
-- що охоплюють: прості вибірки з WHERE та ORDER BY (задачі 1, 3, 9, 10),
-- різні види з'єднань INNER та LEFT JOIN (задачі 2, 11, 12, 18),
-- агрегатні функції COUNT та SUM з групуванням за GROUP BY
-- (задачі 4, 14), фільтрацію результатів групування через HAVING
-- (задачі 5, 15), вкладені запити з IN (задача 6), перевірку наявності
-- через EXISTS та NOT EXISTS (задачі 7, 16), а також віконні функції
-- RANK та DENSE_RANK з OVER (PARTITION BY ...) для ранжування у межах
-- жанру (задачі 8, 19).
--
-- Окремо розглянуто задачі 13 і 14, у яких один запит декомпозовано
-- на два пов'язані — деталізація (позиції замовлень, продажі по
-- книжках) та агрегат (підсумок замовлення, топ-автори) — що
-- демонструє типовий підхід до побудови звітів у видавничому бізнесі.
--
-- Запити покривають усі 8 таблиць схеми та розкривають її бізнес-сенс:
-- виручка за книгами і жанрами, топ-автори, активні контракти,
-- аналіз замовлень за періодом і статусом. Таким чином, нормалізована
-- структура, спроєктована в практичних 3 і 4, дозволяє засобами DQL
-- отримувати всі необхідні управлінські зрізи без зміни самої бази
-- даних.
