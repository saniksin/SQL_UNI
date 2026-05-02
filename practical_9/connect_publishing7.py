# ================================================================
# Практична 9. Задача 7. Топ-книги за правилом Парето 80/20
# ================================================================
# Виручка по книгах + накопичувальний відсоток доходу. Стовпчики
# (виручка) суміщені з лінією (cumulative %) і межею 80%.
# Результат — у book_pareto.csv.

import pandas as pd
import matplotlib.pyplot as plt

from db import engine, ping

# 1. Перевірка підключення
ping()

# 2. Завантаження таблиць
books = pd.read_sql("SELECT * FROM Books", engine)
orders = pd.read_sql("SELECT * FROM Orders", engine)
orderitem = pd.read_sql("SELECT * FROM OrderItem", engine)

print(f"Таблиці завантажено: Books={books.shape}, "
      f"Orders={orders.shape}, OrderItem={orderitem.shape}")

# 3. Формуємо аналітичну таблицю
df = (orderitem
      .merge(orders, on="OrderID", how="left")
      .merge(books, on="BookID", how="left"))

df["Revenue"] = df["Quantity"] * df["UnitPrice"]

print("\nПерші рядки аналітичної таблиці:")
print(df.head())

# 4. Аналіз топ-книг
book_revenue = (df.groupby("Title")["Revenue"]
                .sum()
                .sort_values(ascending=False)
                .reset_index())

# Обчислюємо накопичувальний відсоток
book_revenue["CumulativeRevenue"] = book_revenue["Revenue"].cumsum()
book_revenue["CumulativePercent"] = (
    100 * book_revenue["CumulativeRevenue"] / book_revenue["Revenue"].sum()
)

print("\nТоп-книги з накопичувальним % доходу:")
print(book_revenue)

# 5. Побудова графіка Pareto (80/20)
fig, ax1 = plt.subplots(figsize=(8, 5))

# Стовпчики — виручка по книгах
ax1.bar(book_revenue["Title"], book_revenue["Revenue"], color="skyblue")
ax1.set_xlabel("Назва книги")
ax1.set_ylabel("Виручка (CHF)", color="navy")

# Лінія — накопичувальний відсоток доходу
ax2 = ax1.twinx()
ax2.plot(book_revenue["Title"], book_revenue["CumulativePercent"],
         color="orange", marker="o")
ax2.set_ylabel("Накопичувальний відсоток доходу (%)", color="darkorange")
ax2.axhline(80, color="red", linestyle="--", linewidth=1.5, label="80% межа")

# Оформлення
plt.title("Аналіз топ-книг (Pareto 80/20)", fontsize=14)
ax1.tick_params(axis='x', rotation=30, labelsize=9)
ax1.grid(axis='y', linestyle="--", alpha=0.6)
plt.tight_layout()
plt.show()

# 6. Збереження Результату
book_revenue.to_csv("book_pareto.csv", index=False)
print("\nРезультати збережено у файл book_pareto.csv")
