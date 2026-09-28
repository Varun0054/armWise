import sqlite3
import os
import pathlib
from typing import Optional

DB_FILE = os.path.join(os.path.dirname(os.path.dirname(__file__)), "data", "armwise.db")

def get_db_path() -> str:
    os.makedirs(os.path.dirname(DB_FILE), exist_ok=True)
    return DB_FILE

def get_connection(db_path: Optional[str] = None) -> sqlite3.Connection:
    path = db_path or get_db_path()
    conn = sqlite3.connect(path)
    conn.row_factory = sqlite3.Row
    return conn

def init_db(db_path: Optional[str] = None) -> None:
    conn = get_connection(db_path)
    cursor = conn.cursor()
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS compatibility_cases (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        application TEXT NOT NULL,
        architecture TEXT NOT NULL CHECK(architecture IN ('x86','x64','ARM64','ARM64EC')),
        native_arm64 BOOLEAN NOT NULL,
        driver_indicators BOOLEAN NOT NULL,
        anti_cheat_indicators BOOLEAN NOT NULL,
        category TEXT NOT NULL,
        observed_result TEXT NOT NULL CHECK(observed_result IN ('works','works_with_limitations','fails','unknown')),
        source TEXT NOT NULL,
        source_date TEXT NOT NULL,
        embedding BLOB NOT NULL
    );
    """)
    conn.commit()
    conn.close()

if __name__ == "__main__":
    init_db()
    print("Database initialized successfully at", get_db_path())
