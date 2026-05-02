# Практична 9. Задачі 1, 2, 3.
# Імпорт таблиць у pandas, об'єднання у єдину аналітичну таблицю
# та побудова бар-чарту "Дохід по книгах".

import pandas as pd
import matplotlib.pyplot as plt

from db import engine, ping

# Перевірка підключення (параметри беруться з .env)
ping()


# ================================================================
# Задача 1. Імпорт таблиць у pandas
# ================================================================
books = pd.read_sql("SELECT * FROM Books", engine)
orders = pd.read_sql("SELECT * FROM Orders", engine)
orderitem = pd.read_sql("SELECT * FROM OrderItem", engine)

print("Книги:", books.shape)
print("Замовлення:", orders.shape)
print("Позиції замовлень:", orderitem.shape)


# # ================================================================
# # Задача 2. Об'єднання таблиць (єдина аналітична df + збереження CSV)
# # ================================================================
df = (orderitem
      .merge(orders, on="OrderID", how="left")
      .merge(books, on="BookID", how="left"))

df["Revenue"] = df["Quantity"] * df["UnitPrice"]
print(df.head())

df.to_csv("sales_data.csv", index=False)
print("Файл збережено: sales_data.csv")


# # ================================================================
# # Задача 3. Побудова простого графіка (дохід по книгах)
# # ================================================================
top_books = (df.groupby("Title")["Revenue"]
             .sum()
             .sort_values(ascending=False)
             .reset_index())

plt.figure(figsize=(8, 5))
plt.bar(top_books["Title"], top_books["Revenue"], color="skyblue")
plt.title("Дохід по книгах", fontsize=14)
plt.xlabel("Назва книги")
plt.ylabel("Дохід (CHF)")
plt.xticks(rotation=30, ha='right')
plt.tight_layout()
plt.show()
