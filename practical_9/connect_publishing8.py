# ================================================================
# Практична 9. Задача 8. Heatmap "жанр × рік видання"
# ================================================================
# Pivot Genre × PublishYear із сумою виручки. Теплова карта
# через seaborn (потрібен пакет seaborn у залежностях).
# Результат — у genre_year_heatmap.csv.

import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns  # для heatmap

from db import engine, ping

# 1. Перевірка підключення
ping()

# 2. Завантаження таблиць
books = pd.read_sql("SELECT * FROM Books", engine)
orders = pd.read_sql("SELECT * FROM Orders", engine)
orderitem = pd.read_sql("SELECT * FROM OrderItem", engine)

print(f"Завантажено: Books={books.shape}, "
      f"Orders={orders.shape}, OrderItem={orderitem.shape}")

# 3. Формуємо аналітичну таблицю
df = (orderitem
      .merge(orders, on="OrderID", how="left")
      .merge(books, on="BookID", how="left"))

df["Revenue"] = df["Quantity"] * df["UnitPrice"]

print("\nПерші рядки об'єднаної таблиці:")
print(df.head())

# 4. Агрегація за жанром і роком видання
pivot = (df.groupby(["Genre", "PublishYear"])["Revenue"]
         .sum()
         .unstack(fill_value=0))

print("\nЗведена таблиця жанр × рік видання:")
print(pivot)

# 5. Побудова теплової карти
plt.figure(figsize=(8, 5))
sns.heatmap(pivot, annot=True, fmt=".0f", cmap="YlGnBu")
plt.title("Жанр × Рік видання (виручка)", fontsize=14)
plt.xlabel("Рік видання")
plt.ylabel("Жанр")
plt.tight_layout()
plt.show()

# 6. Збереження Результату
pivot.to_csv("genre_year_heatmap.csv")
print("\nРезультати збережено у файл genre_year_heatmap.csv")
