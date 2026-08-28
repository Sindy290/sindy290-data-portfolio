-- ============================================================
-- Coffee Shop Sales — Database Schema
-- Star-schema design: one fact table (transactions) referencing
-- two dimension tables (stores, products).
--
-- Design note: unit_price was NOT included in dim_products.
-- During data prep, 15 of 80 products showed multiple distinct
-- unit_price values across the period (e.g. product_id 9,
-- "Organic Decaf Blend", was recorded at $28.00, $22.50, $23.00,
-- and $12.00). Because price is not stable per product, it
-- belongs to the transaction (fact) grain, not the product
-- (dimension) grain — treating it as a dimension attribute would
-- silently overwrite/average away a real data quality signal
-- worth flagging to stakeholders.
-- ============================================================

DROP TABLE IF EXISTS fact_transactions;
DROP TABLE IF EXISTS dim_products;
DROP TABLE IF EXISTS dim_stores;

CREATE TABLE dim_stores (
    store_id        INTEGER PRIMARY KEY,
    store_location   TEXT NOT NULL
);

CREATE TABLE dim_products (
    product_id        INTEGER PRIMARY KEY,
    product_category  TEXT NOT NULL,
    product_type      TEXT NOT NULL,
    product_detail    TEXT NOT NULL
);

CREATE TABLE fact_transactions (
    transaction_id    INTEGER PRIMARY KEY,
    transaction_date  TEXT NOT NULL,      -- ISO 'YYYY-MM-DD'
    transaction_time  TEXT NOT NULL,      -- 'HH:MM:SS'
    store_id          INTEGER NOT NULL,
    product_id        INTEGER NOT NULL,
    transaction_qty   INTEGER NOT NULL,
    unit_price        REAL NOT NULL,
    revenue           REAL NOT NULL,      -- transaction_qty * unit_price
    FOREIGN KEY (store_id)   REFERENCES dim_stores(store_id),
    FOREIGN KEY (product_id) REFERENCES dim_products(product_id)
);

CREATE INDEX idx_fact_store   ON fact_transactions(store_id);
CREATE INDEX idx_fact_product ON fact_transactions(product_id);
CREATE INDEX idx_fact_date    ON fact_transactions(transaction_date);
