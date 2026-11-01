"""Build product_analytics.db (SQLite) from sql/00_schema_and_views.sql and the CSV files.

Run:  python scripts/load_db.py
"""
import csv
import os
import sqlite3

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
DB = os.path.join(ROOT, "product_analytics.db")

if os.path.exists(DB):
    os.remove(DB)
con = sqlite3.connect(DB)
with open(os.path.join(ROOT, "sql", "00_schema_and_views.sql"), encoding="utf-8") as f:
    con.executescript(f.read())

for table in ["users", "events", "subscriptions", "experiment_assignments"]:
    with open(os.path.join(ROOT, "data", f"{table}.csv"), newline="", encoding="utf-8") as f:
        reader = csv.reader(f)
        header = next(reader)
        marks = ",".join("?" * len(header))
        con.executemany(f"INSERT INTO {table} ({','.join(header)}) VALUES ({marks})", reader)
    print(f"loaded {table}")
con.commit()
con.close()
print(f"Database created: {DB}")
