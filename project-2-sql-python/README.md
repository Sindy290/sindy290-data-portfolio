# Coffee Shop Sales — SQL + Python Analysis

Project 2 in a data analyst portfolio. Builds on the flat-file analysis in
Project 1 (Excel) by properly normalizing the same transaction data into a
relational database, then using SQL — joins, CTEs, window functions,
subqueries — to answer deeper business questions than a spreadsheet
comfortably can.

## Business question
How should the business staff its stores, prioritize its menu, and plan for
the rest of the year, based on six months of transaction history across
3 NYC locations?

## What's in this folder

| File | What it is |
|---|---|
| `schema.sql` | Database DDL — table definitions, keys, and a documented design decision |
| `build_db.py` | Reproducible script: raw Excel export → normalized SQLite database |
| `coffee_shop.db` | The built database (star schema: 1 fact table, 2 dimension tables) |
| `queries.sql` | 12 documented SQL queries, from basic aggregation to window functions |
| `coffee_sales_sql_analysis.ipynb` | Notebook: runs the queries via `pandas.read_sql`, charts the results, and narrates the findings |

## Database design

```
dim_stores (store_id PK, store_location)
dim_products (product_id PK, product_category, product_type, product_detail)
fact_transactions (transaction_id PK, transaction_date, transaction_time,
                    store_id FK, product_id FK, transaction_qty,
                    unit_price, revenue)
```

`unit_price` is stored on the fact table, not on `dim_products`. During
normalization, 15 of 80 products turned out to have been recorded at more
than one unit price across the 6-month period — treating price as a stable
product attribute would have silently hidden that. See the comment at the
top of `schema.sql` and Section 6 of the notebook for the full finding.

## SQL techniques demonstrated (`queries.sql`)

- Joins across fact/dimension tables
- CTEs (`WITH`)
- Window functions: `LAG`, `RANK`, running totals, 7-day moving average
- Correlated subqueries and subqueries in `FROM`
- `HAVING`, `CASE`, date functions (`strftime`)

## Key findings

1. Revenue is evenly split across all three stores (within 1.5 points) —
   performance isn't a single-location problem.
2. Four consecutive months of double-digit revenue growth (Mar–May),
   easing in June — a real trend worth validating against Q3 data.
3. Two products rank top-3 at every store (safe to feature company-wide),
   but Hell's Kitchen has a genuine local top-seller no other store shares.
4. 36.7% of daily revenue happens in just 3 of ~15 operating hours
   (8–10am) — the clearest staffing lever in the data.
5. 15 of 80 products show inconsistent historical pricing — flagged as a
   data-quality issue to confirm with the business before any
   pricing/margin analysis is built on top of it.

## How to reproduce

```bash
pip install pandas openpyxl
python build_db.py "Coffee Shop Sales.xlsx"
sqlite3 coffee_shop.db < queries.sql   # or open coffee_shop.db in any SQLite client
jupyter notebook coffee_sales_sql_analysis.ipynb
```

## Related projects
- Project 1: Excel pivot-table analysis of the same dataset
- Project 3: Interactive HTML sales dashboard
