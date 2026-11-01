"""Run a .sql file against product_analytics.db and print each result set.

Usage:  python scripts/run_query.py sql/03_onboarding_funnel.sql [max_rows]
Statements are split on ';' so files with several SELECTs work.
"""
import os
import sqlite3
import sys

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
path = sys.argv[1]
limit = int(sys.argv[2]) if len(sys.argv) > 2 else 25
con = sqlite3.connect(os.path.join(ROOT, "product_analytics.db"))
with open(path, encoding="utf-8") as f:
    text = f.read()
for stmt in [s.strip() for s in text.split(";") if s.strip()]:
    if not any(line.strip() and not line.strip().startswith("--") for line in stmt.splitlines()):
        continue
    cur = con.execute(stmt)
    cols = [c[0] for c in cur.description]
    rows = cur.fetchall()
    print(" | ".join(cols))
    for r in rows[:limit]:
        print(" | ".join(str(v) for v in r))
    if len(rows) > limit:
        print(f"... ({len(rows)} rows total)")
    print()
