"""Спільне підключення до MySQL для всіх скриптів практичної 9.

Параметри читаються з файлу .env у цій же папці (через python-dotenv).
Ключі: MYSQL_USER, MYSQL_PASSWORD, MYSQL_HOST, MYSQL_PORT, MYSQL_DB.

Використання у скрипті:

    from db import engine, ping
    ping()
    books = pd.read_sql("SELECT * FROM Books", engine)
"""

import os
from pathlib import Path

from dotenv import load_dotenv
from sqlalchemy import create_engine, text

# завантажуємо .env, що лежить поряд з цим файлом
load_dotenv(Path(__file__).parent / ".env")

USER = os.getenv("MYSQL_USER", "root")
PASSWORD = os.getenv("MYSQL_PASSWORD", "")
HOST = os.getenv("MYSQL_HOST", "localhost")
PORT = os.getenv("MYSQL_PORT", "3306")
DB = os.getenv("MYSQL_DB", "publishing")

DATABASE_URL = (
    f"mysql+pymysql://{USER}:{PASSWORD}@{HOST}:{PORT}/{DB}?charset=utf8mb4"
)

engine = create_engine(DATABASE_URL)


def ping() -> None:
    """Перевірочний запит SELECT NOW() — друкує дату MySQL-сервера."""
    with engine.connect() as conn:
        print("Підключення успішне:", conn.execute(text("SELECT NOW()")).scalar())


if __name__ == "__main__":
    ping()
