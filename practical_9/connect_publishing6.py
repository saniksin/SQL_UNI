# ================================================================
# Практична 9. Задача 6. Топ-жанри за виручкою
# ================================================================
# Горизонтальна стовпчикова діаграма (barh) із сортуванням за
# спаданням виручки. invert_yaxis() ставить найприбутковіший
# жанр зверху. Результат — у genre_revenue.csv.

import pandas as pd
import matplotlib.pyplot as plt

from db import engine, ping

# 1. Перевірка підключення
ping()

# 2. Завантаження таблиць із бази
books = pd.read_sql("SELECT * FROM Books", engine)
orders = pd.read_sql("SELECT * FROM Orders", engine)
orderitem = pd.read_sql("SELECT * FROM OrderItem", engine)

print(f"Таблиці завантажено: Books={books.shape}, "
      f"Orders={orders.shape}, OrderItem={orderitem.shape}")

# 3. Об'єднання таблиць для аналітики
df = (orderitem
      .merge(orders, on="OrderID", how="left")
      .merge(books, on="BookID", how="left"))

df["Revenue"] = df["Quantity"] * df["UnitPrice"]

print("\nПерші рядки аналітичної таблиці:")
print(df.head())

# 4. Аналіз топ-жанрів
genre_revenue = (df.groupby("Genre")["Revenue"]
                 .sum()
                 .sort_values(ascending=False)
                 .reset_index())

print("\nТоп жанри за виручкою:")
print(genre_revenue)

# 5. Побудова стовпчикової діаграми
plt.figure(figsize=(8, 5))
plt.barh(genre_revenue["Genre"], genre_revenue["Revenue"], color="cornflowerblue")
plt.title("Топ-жанри за виручкою", fontsize=14)
plt.xlabel("Виручка (CHF)")
plt.ylabel("Жанр")
plt.gca().invert_yaxis()  # щоб найбільші жанри були зверху
plt.grid(axis='x', linestyle="--", alpha=0.6)
plt.tight_layout()
plt.show()

# 6. Збереження Результату у CSV
genre_revenue.to_csv("genre_revenue.csv", index=False)
print("\nРезультат збережено у файл genre_revenue.csv")
