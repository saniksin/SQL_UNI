-- ================================================================
-- Практична робота 6: Складні SQL вирази — тригери на таблиці Contracts
-- Schema: publishing   |   MySQL 8.0+
-- Передумова: виконано practical_4.sql (база та дані є).
-- ================================================================
-- Мета: реалізувати бізнес-логіку на рівні БД через тригери
-- BEFORE INSERT / BEFORE UPDATE, сигналізацію помилок
-- SIGNAL SQLSTATE '45000'.
--
-- Бізнес-правила, які перевіряємо у тригерах:
--   1) у контракті рівно один власник (AuthorID АБО EmployeeID);
--   2) ContractType відповідає власнику (Author / Employee);
--   3) EndDate не може бути раніше StartDate (якщо задана).
-- ================================================================

USE publishing;

-- ================================================================
-- Задача 1. Створення тригерів
-- (ексклюзивність власника контракту + контроль дат)
-- ================================================================

DROP TRIGGER IF EXISTS trg_contracts_bi;
DROP TRIGGER IF EXISTS trg_contracts_bu;

DELIMITER $$

CREATE TRIGGER trg_contracts_bi
BEFORE INSERT ON Contracts
FOR EACH ROW
BEGIN
  -- рівно одне з AuthorID/EmployeeID має бути NOT NULL
  IF (NEW.AuthorID IS NULL AND NEW.EmployeeID IS NULL)
    OR (NEW.AuthorID IS NOT NULL AND NEW.EmployeeID IS NOT NULL) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Exactly one of AuthorID or EmployeeID must be set';
  END IF;

  -- ContractType має відповідати встановленому FK
  IF (NEW.AuthorID   IS NOT NULL AND NEW.ContractType <> 'Author')
    OR (NEW.EmployeeID IS NOT NULL AND NEW.ContractType <> 'Employee')
  THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'ContractType must match owner (Author/Employee)';
  END IF;

  -- Перевірка дат
  IF NEW.EndDate IS NOT NULL AND NEW.EndDate < NEW.StartDate THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'EndDate must be >= StartDate';
  END IF;
END$$

CREATE TRIGGER trg_contracts_bu
BEFORE UPDATE ON Contracts
FOR EACH ROW
BEGIN
  IF (NEW.AuthorID IS NULL AND NEW.EmployeeID IS NULL)
    OR (NEW.AuthorID IS NOT NULL AND NEW.EmployeeID IS NOT NULL) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Exactly one of AuthorID or EmployeeID must be set';
  END IF;

  IF (NEW.AuthorID   IS NOT NULL AND NEW.ContractType <> 'Author')
    OR (NEW.EmployeeID IS NOT NULL AND NEW.ContractType <> 'Employee')
  THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'ContractType must match owner (Author/Employee)';
  END IF;

  IF NEW.EndDate IS NOT NULL AND NEW.EndDate < NEW.StartDate THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'EndDate must be >= StartDate';
  END IF;
END$$

DELIMITER ;

-- ---- Висновок студента (Задача 1) ----
-- У ході виконання завдання були створені тригери trg_contracts_bi та
-- trg_contracts_bu для таблиці Contracts у базі даних publishing
-- (у мене назва mydb). Реалізовано перевірки бізнес-правил, які
-- забезпечують наявність лише одного власника контракту (автора або
-- співробітника), відповідність типу контракту його власнику, а також
-- контроль коректності дат (EndDate не може бути раніше StartDate).
-- Використання механізму SIGNAL SQLSTATE дозволяє автоматично блокувати
-- некоректні операції вставки та оновлення, що підвищує цілісність
-- даних у базі.

-- ================================================================
-- Задача 2. Створіть тригери BEFORE INSERT і BEFORE UPDATE
-- (детальніший варіант BEFORE INSERT з покроковими коментарями)
-- ================================================================
-- Нижче — той самий BEFORE INSERT, але з розгорнутими коментарями
-- до кожного кроку перевірки. Перед CREATE знову викликаємо DROP,
-- щоб блок був ідемпотентним.

DROP TRIGGER IF EXISTS trg_contracts_bi;

-- Змінюємо роздільник команд, щоб у тілі тригера можна було
-- використовувати крапку з комою
DELIMITER $$

-- Створюємо тригер, який спрацьовує перед вставкою нового запису
-- у таблицю Contracts
CREATE TRIGGER trg_contracts_bi
BEFORE INSERT ON Contracts
FOR EACH ROW
BEGIN
  ------------------------------------------------------------
  -- Крок 1. Перевірка власника контракту
  ------------------------------------------------------------
  -- Контракт повинен належати або автору, або співробітнику,
  -- але не обом одночасно.
  IF (NEW.AuthorID IS NULL AND NEW.EmployeeID IS NULL)
    OR (NEW.AuthorID IS NOT NULL AND NEW.EmployeeID IS NOT NULL) THEN

    -- SIGNAL SQLSTATE '45000' — створює користувацьку помилку
    -- (зупиняє виконання INSERT)
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Exactly one of AuthorID or EmployeeID must be set';
  END IF;

  ------------------------------------------------------------
  -- Крок 2. Перевірка правильності типу контракту
  ------------------------------------------------------------
  -- Якщо контракт належить автору, ContractType має бути 'Author'.
  -- Якщо контракт належить співробітнику — 'Employee'.
  IF (NEW.AuthorID IS NOT NULL AND NEW.ContractType <> 'Author')
    OR (NEW.EmployeeID IS NOT NULL AND NEW.ContractType <> 'Employee')
  THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'ContractType must match owner (Author/Employee)';
  END IF;

  ------------------------------------------------------------
  -- Крок 3. Перевірка послідовності дат
  ------------------------------------------------------------
  -- Кінцева дата (EndDate) не може бути раніше дати початку (StartDate).
  IF NEW.EndDate IS NOT NULL AND NEW.EndDate < NEW.StartDate THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'EndDate must be >= StartDate';
  END IF;

END$$

-- Повертаємо стандартний роздільник команд
DELIMITER ;

-- ---- Висновок студента (Задача 2) ----
-- У ході виконання завдання було створено тригер trg_contracts_bi типу
-- BEFORE INSERT для таблиці Contracts у базі даних publishing (у мене
-- назва mydb). Тригер реалізує перевірку бізнес-логіки перед додаванням
-- нового запису: контролює, щоб контракт мав лише одного власника
-- (автора або співробітника), перевіряє відповідність типу контракту
-- його власнику та забезпечує коректність дат (EndDate не може бути
-- менше StartDate). Завдяки використанню умовних операторів та механізму
-- SIGNAL SQLSTATE некоректні дані автоматично відхиляються на рівні бази
-- даних, що підвищує цілісність і надійність збереженої інформації.

-- ================================================================
-- Задача 3. Перевірка роботи тригерів
-- ================================================================
-- УВАГА: запускати кожен INSERT окремо — Workbench зупиняється
-- на першій помилці й далі не виконує наступні команди.

-- Коректна вставка — має виконатись успішно
INSERT INTO Contracts (AuthorID, ContractType, StartDate, EndDate)
VALUES (1, 'Author', '2025-06-01', '2025-12-31');

-- Помилка 1: два власники
-- Очікується: 'Exactly one of AuthorID or EmployeeID must be set'
INSERT INTO Contracts (AuthorID, EmployeeID, ContractType, StartDate)
VALUES (1, 1, 'Author', '2025-06-01');

-- Помилка 2: неправильний тип
-- Очікується: 'ContractType must match owner (Author/Employee)'
INSERT INTO Contracts (AuthorID, ContractType, StartDate)
VALUES (1, 'Employee', '2025-06-01');

-- Помилка 3: неправильні дати
-- Очікується: 'EndDate must be >= StartDate'
INSERT INTO Contracts (AuthorID, ContractType, StartDate, EndDate)
VALUES (1, 'Author', '2025-12-01', '2025-01-01');

-- ---- Висновок студента (Задача 3) ----
-- 1) Коректна вставка: Запит виконано успішно, запис додано до таблиці
--    Contracts без помилок. Це підтверджує, що тригер дозволяє збереження
--    даних, які відповідають усім бізнес-правилам (один власник,
--    правильний тип контракту та коректні дати).
--
-- 2) Помилка: два власники: Операція була відхилена тригером, оскільки
--    одночасно було вказано AuthorID та EmployeeID. Це порушує правило,
--    що контракт може належати лише одному власнику. База даних повернула
--    помилку і не дозволила вставку.
--
-- 3) Помилка: неправильний тип контракту: Вставка була заблокована,
--    оскільки значення ContractType не відповідає типу власника контракту.
--    Тригер перевірив відповідність і відхилив некоректний запис,
--    забезпечуючи цілісність даних.
--
-- 4) Помилка: неправильні дати: Запит не виконано через порушення логіки
--    дат: EndDate менша за StartDate. Тригер автоматично зупинив операцію
--    та повернув помилку, що гарантує правильну послідовність дат у базі
--    даних.

-- ================================================================
-- Задача 4. Аналітична перевірка
-- ================================================================

SELECT ContractID, ContractType, StartDate, EndDate
  FROM Contracts
 ORDER BY StartDate DESC;

-- ---- Висновок студента (Задача 4) ----
-- У результаті виконання запиту було отримано список актуальних контрактів
-- із таблиці Contracts із відображенням їх ідентифікаторів, типів, дат
-- початку та завершення. Сортування за датою початку у спадному порядку
-- дозволило проаналізувати найновіші контракти першими. Отримані дані
-- підтверджують коректність роботи бази даних після застосування тригерів
-- та цілісність збереженої інформації.
