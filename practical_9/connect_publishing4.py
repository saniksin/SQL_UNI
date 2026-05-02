# ================================================================
# Практична 9. Задача 4. Побудова графіка динаміки продажів
# ================================================================
# Лінійний графік суми виручки за датами замовлень + збереження
# результату у revenue_by_month.png.

import pandas as pd
import matplotlib.pyplot as plt

from db import engine, ping

# 1. Перевірка підключення
ping()

# 2. Завантаження таблиць із бази
books = pd.read_sql("SELECT * FROM Books", engine)
orders = pd.read_sql("SELECT * FROM Orders", engine)
orderitem = pd.read_sql("SELECT * FROM OrderItem", engine)

# 3. Створення аналітичної таблиці df
df = (orderitem
      .merge(orders, on="OrderID", how="left")
      .merge(books, on="BookID", how="left"))

df["Revenue"] = df["Quantity"] * df["UnitPrice"]
df["OrderDate"] = pd.to_datetime(df["OrderDate"])  # перетворення у формат дати

print(df.head())

# 4. Групування по датах
sales_by_date = (df.groupby("OrderDate")["Revenue"]
                 .sum()
                 .reset_index()
                 .sort_values("OrderDate"))

print(sales_by_date)

# 5. Побудова графіка
plt.figure(figsize=(8, 5))
plt.plot(sales_by_date["OrderDate"], sales_by_date["Revenue"],
         marker="o", color="teal", linewidth=2)
plt.title("Динаміка продажів за датами", fontsize=14)
plt.xlabel("Дата замовлення")
plt.ylabel("Виручка (CHF)")
plt.grid(True, linestyle="--", alpha=0.6)
plt.tight_layout()

# 6. Збереження графіка (до plt.show — інакше figure буде порожнім)
plt.savefig("revenue_by_month.png", dpi=200)
print("Графік збережено: revenue_by_month.png")

plt.show()
