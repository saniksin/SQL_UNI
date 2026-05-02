# app.py
# Видавництво — аналітика продажів (Streamlit)
import os
from pathlib import Path

import streamlit as st
import pandas as pd
import matplotlib.pyplot as plt
from dotenv import load_dotenv
from sqlalchemy import create_engine

# завантажуємо .env з кореня practical_9/ (на рівень вище від publishing_app/)
load_dotenv(Path(__file__).parent.parent / ".env")

st.set_page_config(page_title="Publishing Analytics", layout="wide")
st.title("Видавництво — аналітика продажів")

# ====================== ПІДКЛЮЧЕННЯ ДО БД ======================
st.sidebar.header("Підключення до MySQL")

# defaults підтягуються з .env, користувач може перевизначити у формі
host = st.sidebar.text_input("Host", value=os.getenv("MYSQL_HOST", "localhost"))
port = st.sidebar.text_input("Port", value=os.getenv("MYSQL_PORT", "3306"))
user = st.sidebar.text_input("User", value=os.getenv("MYSQL_USER", "root"))
password = st.sidebar.text_input("Password", type="password",
                                 value=os.getenv("MYSQL_PASSWORD", ""))
database = st.sidebar.text_input("Database", value=os.getenv("MYSQL_DB", "publishing"))

connect_btn = st.sidebar.button("Підключитись")


def build_conn_str(h, p, u, pw, db):
    return f"mysql+pymysql://{u}:{pw}@{h}:{p}/{db}?charset=utf8mb4"


@st.cache_data(show_spinner=False)
def load_tables(conn_str: str):
    eng = create_engine(conn_str)
    books = pd.read_sql("SELECT * FROM Books", eng)
    # важливо: розпарсити дату ще тут
    orders = pd.read_sql("SELECT * FROM Orders", eng, parse_dates=["OrderDate"])
    orderitem = pd.read_sql("SELECT * FROM OrderItem", eng)
    return books, orders, orderitem


def build_df(books, orders, orderitem):
    df = (orderitem
          .merge(orders, on="OrderID", how="left")
          .merge(books, on="BookID", how="left"))
    df["Revenue"] = df["Quantity"] * df["UnitPrice"]
    # гарантуємо тип дати
    if not pd.api.types.is_datetime64_any_dtype(df["OrderDate"]):
        df["OrderDate"] = pd.to_datetime(df["OrderDate"])
    return df


def apply_date_filter(df, date_from, date_to):
    out = df
    if date_from:
        out = out[out["OrderDate"].dt.date >= date_from]
    if date_to:
        out = out[out["OrderDate"].dt.date <= date_to]
    return out


# Сесійні дані
if connect_btn:
    try:
        conn_str = build_conn_str(host, port, user, password, database)
        b, o, oi = load_tables(conn_str)
        st.session_state["books"] = b
        st.session_state["orders"] = o
        st.session_state["orderitem"] = oi
        st.success("Підключення успішне і дані завантажено")
    except Exception as e:
        st.error(f"Помилка підключення/завантаження: {e}")

with st.expander("Показати перші рядки таблиць"):
    if all(k in st.session_state for k in ("books", "orders", "orderitem")):
        st.write("**Books**"); st.dataframe(st.session_state["books"].head(), width="stretch")
        st.write("**Orders**"); st.dataframe(st.session_state["orders"].head(), width="stretch")
        st.write("**OrderItem**"); st.dataframe(st.session_state["orderitem"].head(), width="stretch")
    else:
        st.info("Спершу натисни «Підключитись» у лівій панелі.")

# якщо даних ще немає — зупиняємо додаток
if not all(k in st.session_state for k in ("books", "orders", "orderitem")):
    st.stop()

# ====================== ФІЛЬТРИ ДАТИ (ГЛОБАЛЬНІ) ======================
st.markdown("---")
f1, f2 = st.columns(2)
with f1:
    date_from = st.date_input("Дата від", value=None)
with f2:
    date_to = st.date_input("Дата до", value=None)

# будуємо єдину аналітичну таблицю та відразу фільтруємо
df = build_df(st.session_state["books"], st.session_state["orders"],
              st.session_state["orderitem"])
df_f = apply_date_filter(df, date_from, date_to)
st.caption(f"Після фільтру: {len(df_f)} рядків | інтервал даних: "
           f"{df_f['OrderDate'].min().date() if len(df_f) else '—'} → "
           f"{df_f['OrderDate'].max().date() if len(df_f) else '—'}")

# ====================== ВКЛАДКИ ======================
tab_kpi, tab_viz = st.tabs(["KPI", "Візуалізації"])

# ---------------- KPI ----------------
with tab_kpi:
    st.subheader("Основні показники продажів")

    total_orders = int(df_f["OrderID"].nunique()) if len(df_f) else 0
    total_units = int(df_f["Quantity"].sum()) if len(df_f) else 0
    total_revenue = float(df_f["Revenue"].sum()) if len(df_f) else 0.0
    avg_order_value = (float(df_f.groupby("OrderID")["Revenue"].sum().mean())
                       if total_orders > 0 else 0.0)

    c1, c2, c3, c4 = st.columns(4)
    c1.metric("Кількість замовлень", f"{total_orders}")
    c2.metric("Продано одиниць", f"{total_units}")
    c3.metric("Загальна виручка, CHF", f"{total_revenue:,.2f}")
    c4.metric("Середній чек, CHF", f"{avg_order_value:,.2f}")

    st.markdown("#### Зведена таблиця по замовленнях")
    order_rollup = (df_f.groupby("OrderID")
                    .agg(OrderDate=("OrderDate", "first"),
                         Client=("ClientName", "first"),
                         Lines=("OrderItemID", "count"),
                         Units=("Quantity", "sum"),
                         Revenue=("Revenue", "sum"))
                    .sort_values("OrderDate", ascending=False)
                    .reset_index())
    st.dataframe(order_rollup, width="stretch")

    # Експорт KPI
    kpi_df = pd.DataFrame({
        "metric": ["total_orders", "total_units", "total_revenue", "avg_order_value"],
        "value": [total_orders, total_units, total_revenue, avg_order_value]
    })
    st.download_button(
        "Export KPI (CSV)",
        data=kpi_df.to_csv(index=False).encode("utf-8"),
        file_name="kpi.csv",
        mime="text/csv"
    )

# ---------------- ВІЗУАЛІЗАЦІЇ ----------------
with tab_viz:
    st.subheader("Графіки")

    chart_type = st.selectbox(
        "Оберіть візуалізацію",
        ["Топ жанри (виручка)",
         "Динаміка продажів по місяцях",
         "Правило Парето 80/20 по книгах"]
    )
    build_btn = st.button("Побудувати")

    if build_btn:
        if chart_type == "Топ жанри (виручка)":
            genre_rev = (df_f.groupby("Genre")["Revenue"]
                         .sum()
                         .sort_values(ascending=False)
                         .reset_index())
            fig, ax = plt.subplots(figsize=(8, 5))
            ax.barh(genre_rev["Genre"], genre_rev["Revenue"])
            ax.set_xlabel("Виручка (CHF)")
            ax.set_ylabel("Жанр")
            ax.invert_yaxis()
            ax.grid(axis="x", linestyle="--", alpha=0.6)
            st.pyplot(fig)
            st.download_button(
                "Завантажити CSV",
                data=genre_rev.to_csv(index=False).encode("utf-8"),
                file_name="genre_revenue.csv",
                mime="text/csv"
            )

        elif chart_type == "Динаміка продажів по місяцях":
            df_f = df_f.copy()
            df_f["YearMonth"] = df_f["OrderDate"].dt.to_period("M").astype(str)
            rev_month = (df_f.groupby("YearMonth")["Revenue"]
                         .sum()
                         .reset_index()
                         .sort_values("YearMonth"))
            fig, ax = plt.subplots(figsize=(9, 5))
            ax.plot(rev_month["YearMonth"], rev_month["Revenue"], marker="o")
            ax.set_xlabel("Місяць")
            ax.set_ylabel("Виручка (CHF)")
            ax.grid(True, linestyle="--", alpha=0.6)
            plt.xticks(rotation=45, ha="right")
            st.pyplot(fig)
            st.download_button(
                "Завантажити CSV",
                data=rev_month.to_csv(index=False).encode("utf-8"),
                file_name="revenue_by_month.csv",
                mime="text/csv"
            )

        elif chart_type == "Правило Парето 80/20 по книгах":
            book_rev = (df_f.groupby("Title")["Revenue"]
                        .sum()
                        .sort_values(ascending=False)
                        .reset_index())
            book_rev["CumRevenue"] = book_rev["Revenue"].cumsum()
            book_rev["CumPercent"] = 100 * book_rev["CumRevenue"] / book_rev["Revenue"].sum()
            fig, ax1 = plt.subplots(figsize=(10, 5))
            ax1.bar(book_rev["Title"], book_rev["Revenue"])
            ax1.set_xlabel("Книга")
            ax1.set_ylabel("Виручка (CHF)")
            ax1.tick_params(axis="x", rotation=30)
            ax2 = ax1.twinx()
            ax2.plot(book_rev["Title"], book_rev["CumPercent"], marker="o")
            ax2.set_ylabel("Накопичувальний %")
            ax2.axhline(80, linestyle="--")
            ax1.grid(axis="y", linestyle="--", alpha=0.6)
            st.pyplot(fig)
            st.download_button(
                "Завантажити CSV",
                data=book_rev.to_csv(index=False).encode("utf-8"),
                file_name="book_pareto.csv",
                mime="text/csv"
            )
