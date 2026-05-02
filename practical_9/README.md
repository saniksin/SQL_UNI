# Практична 9 — Обробка та візуалізація даних засобами Python

Міні-ETL над схемою publishing: підключення до MySQL із Python через `SQLAlchemy + pymysql`, формування єдиної аналітичної таблиці у `pandas`, розрахунок KPI, побудова чотирьох інформативних графіків у `matplotlib` / `seaborn` та інтерактивний веб-інтерфейс на `Streamlit`. Структура файлів — точно за зошитом.

---

## Що всередині

| Файл | Задача за зошитом | Артефакти |
|---|---|---|
| [`db.py`](db.py) | спільне підключення до MySQL (читає `.env`, експонує `engine` + `ping()`) | — |
| [`.env`](.env) / [`.env.example`](.env.example) | секрети підключення (хост, користувач, пароль, база) | — |
| [`connect_publishing.py`](connect_publishing.py) | 1, 2, 3 — імпорт таблиць, `merge` у `df`, бар-чарт «Дохід по книгах». | `sales_data.csv` |
| [`connect_publishing4.py`](connect_publishing4.py) | 4 — динаміка продажів за датами (лінійний графік). | `revenue_by_month.png` |
| [`connect_publishing5.py`](connect_publishing5.py) | 5 — KPI: `total_orders`, `total_units`, `total_revenue`, `avg_order_value` + графік. | `kpi.csv` |
| [`connect_publishing6.py`](connect_publishing6.py) | 6 — топ-жанри за виручкою (горизонтальна стовпчикова діаграма). | `genre_revenue.csv` |
| [`connect_publishing7.py`](connect_publishing7.py) | 7 — правило Парето 80/20 для книг (стовпчики + cumulative %). | `book_pareto.csv` |
| [`connect_publishing8.py`](connect_publishing8.py) | 8 — heatmap «жанр × рік видання» через seaborn. | `genre_year_heatmap.csv` |
| [`publishing_app/app.py`](publishing_app/app.py) | 8 — інтерактивна Streamlit-панель (KPI + 3 графіки). | — |

Менеджер залежностей — `uv`. Декларація і фіксація пакетів — у [`pyproject.toml`](pyproject.toml) і [`uv.lock`](uv.lock).

**Як це влаштовано:** `db.py` один раз будує `engine` з параметрів `.env` і експонує функцію `ping()`. Кожен `connect_publishing*.py` починається з:

```python
from db import engine, ping
ping()  # перевіряє з'єднання, друкує SELECT NOW()
```

Жоден скрипт не повторює рядок підключення і не містить пароля.

---

## Як запустити

### 1. Підготовка середовища

```bash
cd practical_9
uv sync          # створює .venv і встановлює всі залежності з uv.lock
```

### 2. Параметри MySQL — у `.env`

Усі секрети винесено у файл `.env` (gitignored). Скопіюй з шаблону і заповни своїми значеннями:

```bash
cp .env.example .env
# відредагуй .env у будь-якому редакторі
```

Поля у `.env`:

```
MYSQL_USER=root
MYSQL_PASSWORD=NewStrongPassword123!
MYSQL_HOST=192.168.1.94
MYSQL_PORT=3306
MYSQL_DB=mydb
```

Важливо:

- Пароль — як на твоїй MySQL.
- IP `192.168.1.94` — IP Windows-хоста у локальній мережі (для WSL); у самій Windows зазвичай `localhost`.
- База `mydb` — як ти її назвав; методичка використовує `publishing` (якщо у тебе так — поміняй).
- Користувач `root@%` створено через `CREATE USER 'root'@'%' ...; GRANT ALL ...; FLUSH PRIVILEGES;`.

Завдяки `db.py` параметри потрібно змінити тільки в одному місці — `.env`. Усі скрипти автоматично підхоплять нові значення.

### 3. Запуск окремих задач

```bash
uv run connect_publishing.py            # Задачі 1, 2, 3
uv run connect_publishing4.py           # Задача 4
uv run connect_publishing5.py           # Задача 5 (KPI)
uv run connect_publishing6.py           # Задача 6 (топ-жанри)
uv run connect_publishing7.py           # Задача 7 (Pareto 80/20)
uv run connect_publishing8.py           # Задача 8 (heatmap)
```

### 4. Запуск Streamlit-панелі

```bash
cd publishing_app
uv run --project .. streamlit run app.py
```

Або з кореня `practical_9/`:

```bash
uv run streamlit run publishing_app/app.py
```

Браузер відкриється автоматично на `http://localhost:8501`. У сайдбарі поля Host/Port/User/Password/Database вже заповнено значеннями з `.env` — натисни «Підключитись» і користуйся вкладками **KPI** і **Візуалізації**.

---

## Висновки студента (по задачах)

- **Задача 1.** Налаштовано підключення до MySQL через `SQLAlchemy + pymysql` і завантажено три ключові таблиці (`Books`, `Orders`, `OrderItem`) у `pandas.DataFrame`. `pd.read_sql` дозволяє писати звичайні SQL-запити і одразу отримувати таблицю в Python — це усуває потребу в окремому шарі ORM для аналітики.
- **Задача 2.** Через два послідовних `merge` побудовано єдину аналітичну таблицю (`OrderItem ← Orders ← Books`) з обчисленим полем `Revenue = Quantity * UnitPrice`. Експорт у `sales_data.csv` робить дані придатними до читання у Excel/Google Sheets без повторного запиту до бази.
- **Задача 3.** Стовпчикова діаграма `plt.bar` з агрегатом `groupby('Title')` показує, які книги приносять найбільше виручки. Сортування за спаданням робить «передовиків» візуально очевидними у першу секунду.
- **Задача 4.** Лінійний графік `plt.plot` за полем `OrderDate` (попередньо приведеним до `datetime`) демонструє динаміку продажів у часі. `plt.savefig('revenue_by_month.png')` зберігає графік у вигляді PNG для використання у звітах.
- **Задача 5.** Розраховано 4 KPI продажів: загальна кількість замовлень, проданих одиниць, сумарна виручка та середній чек. KPI зберігаються у `kpi.csv` як `pd.Series` — компактний формат для подальшого імпорту в дашборди або BI-системи.
- **Задача 6.** Горизонтальна діаграма `plt.barh` з `invert_yaxis()` ставить найприбутковіші жанри зверху — це канонічний формат для рейтингів. На відміну від вертикальної, вона добре працює з довгими підписами.
- **Задача 7.** Аналіз Парето 80/20: на одній осі — виручка по книгах (стовпчики), на другій — накопичувальний відсоток доходу (лінія) з межею 80 %. Перетин лінії з межею вказує, скільки книг забезпечують 80 % обороту — типовий інструмент бізнес-аналізу.
- **Задача 8 (heatmap).** Pivot-таблиця `Genre × PublishYear` із сумою виручки візуалізована через `sns.heatmap`. Колір клітинки показує силу жанру у конкретному році видання.
- **Задача 8 (Streamlit).** Створено інтерактивну веб-панель: підключення до MySQL із сайдбару, фільтри по даті, вкладки KPI (4 метрики + зведена таблиця по замовленнях) та Візуалізації (3 типи графіків + експорт CSV). Streamlit дозволив зробити повноцінний дашборд без складної фронтенд-розробки — буквально на тих самих pandas + matplotlib, що вже використовувались у попередніх задачах.

---

## Загальний висновок

На прикладі бази publishing відпрацьовано весь стандартний цикл аналітики на Python: **Read → Clean → Transform → Analyze → Visualize → Save**. Складні аналітичні питання, що їх громіздко виражати у чистому SQL (Pareto-аналіз, KPI-блок, heatmap, інтерактивний дашборд), елегантно вирішуються 30–80 рядками коду. Pandas виступає природним продовженням SQL-частини курсу: одна й та сама `df` живить і `matplotlib`, і `seaborn`, і `Streamlit` — без проміжних експортів. Експорт у CSV/PNG робить результати портативними для LMS, email або BI-інструментів.
