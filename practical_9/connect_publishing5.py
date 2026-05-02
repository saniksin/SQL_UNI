# ================================================================
# Практична 9. Задача 5. Ключові показники (KPI)
# ================================================================
# Розрахунок 4 KPI продажів видавництва: total_orders, total_units,
# total_revenue, avg_order_value. Збереження у kpi.csv + графік.

import pandas as pd
import matplotlib.pyplot as plt

from db import engine, ping

# 1. Перевірка підключення
ping()

# 2. Завантаження таблиць у pandas
books = pd.read_sql("SELECT * FROM Books", engine)
orders = pd.read_sql("SELECT * FROM Orders", engine)
orderitem = pd.read_sql("SELECT * FROM OrderItem", engine)

print(f"Книги: {books.shape}, Замовлення: {orders.shape}, "
      f"Позиції замовлень: {orderitem.shape}")

# 3. Створення аналітичної таблиці df
df = (orderitem
      .merge(orders, on="OrderID", how="left")
      .merge(books, on="BookID", how="left"))

df["Revenue"] = df["Quantity"] * df["UnitPrice"]
df["OrderDate"] = pd.to_datetime(df["OrderDate"])

print("\nПерші рядки аналітичної таблиці:")
print(df.head())

# 4. Розрахунок ключових показників (KPI)
kpi = {
    "total_orders": df["OrderID"].nunique(),                                  # кількість замовлень
    "total_units": int(df["Quantity"].sum()),                                 # кількість проданих книг
    "total_revenue": float(df["Revenue"].sum()),                              # загальна виручка
    "avg_order_value": float(df.groupby("OrderID")["Revenue"].sum().mean()),  # середній чек
}

# Перетворюємо у таблицю pandas і зберігаємо
kpi_series = pd.Series(kpi, name="Value")
kpi_series.to_csv("kpi.csv")

print("\nKPI (ключові показники):")
print(kpi_series)

# 5. Побудова графіка динаміки продажів
sales_by_date = (df.groupby("OrderDate")["Revenue"]
                 .sum()
                 .reset_index()
                 .sort_values("OrderDate"))

plt.figure(figsize=(8, 5))
plt.plot(sales_by_date["OrderDate"], sales_by_date["Revenue"],
         marker="o", color="teal", linewidth=2)
plt.title("Динаміка продажів за датами", fontsize=14)
plt.xlabel("Дата замовлення")
plt.ylabel("Виручка (CHF)")
plt.grid(True, linestyle="--", alpha=0.6)
plt.tight_layout()
plt.show()
