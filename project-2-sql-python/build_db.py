"""
Builds coffee_shop.db from the raw Coffee Shop Sales.xlsx transaction export.

Splits the single flat file into a star schema:
    dim_stores          — one row per store
    dim_products         — one row per product (category/type/detail)
    fact_transactions    — one row per transaction, referencing both dimensions

See schema.sql for the DDL and a note on why unit_price lives on the fact
table rather than dim_products.

Usage:
    python build_db.py path/to/"Coffee Shop Sales.xlsx"
"""
import sys
import sqlite3
import pandas as pd


def build(source_xlsx: str, db_path: str = "coffee_shop.db"):
    df = pd.read_excel(source_xlsx, sheet_name="Transactions")

    dim_stores = (
        df[["store_id", "store_location"]]
        .drop_duplicates()
        .sort_values("store_id")
        .reset_index(drop=True)
    )

    dim_products = (
        df[["product_id", "product_category", "product_type", "product_detail"]]
        .drop_duplicates()
        .sort_values("product_id")
        .reset_index(drop=True)
    )

    fact = df[[
        "transaction_id", "transaction_date", "transaction_time", "store_id",
        "product_id", "transaction_qty", "unit_price",
    ]].copy()
    fact["transaction_date"] = pd.to_datetime(fact["transaction_date"]).dt.strftime("%Y-%m-%d")
    fact["transaction_time"] = fact["transaction_time"].astype(str)
    fact["revenue"] = fact["transaction_qty"] * fact["unit_price"]

    conn = sqlite3.connect(db_path)
    with open("schema.sql") as f:
        conn.executescript(f.read())

    dim_stores.to_sql("dim_stores", conn, if_exists="append", index=False)
    dim_products.to_sql("dim_products", conn, if_exists="append", index=False)
    fact.to_sql("fact_transactions", conn, if_exists="append", index=False)
    conn.commit()

    # integrity check
    cur = conn.cursor()
    cur.execute("PRAGMA foreign_key_check")
    issues = cur.fetchall()
    if issues:
        raise RuntimeError(f"Foreign key issues found: {issues}")

    print(f"Built {db_path}: "
          f"{len(dim_stores)} stores, {len(dim_products)} products, "
          f"{len(fact)} transactions.")
    conn.close()


if __name__ == "__main__":
    source = sys.argv[1] if len(sys.argv) > 1 else "Coffee Shop Sales.xlsx"
    build(source)
