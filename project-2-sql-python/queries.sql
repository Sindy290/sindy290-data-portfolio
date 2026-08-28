-- ============================================================
-- Coffee Shop Sales — Analysis Queries
-- Database: coffee_shop.db (SQLite)
-- Schema:  dim_stores, dim_products, fact_transactions
-- ============================================================


-- ------------------------------------------------------------
-- Q1. Company-wide KPIs
-- Basic aggregation — establishes the headline numbers.
-- ------------------------------------------------------------
SELECT
    ROUND(SUM(revenue), 2)                  AS total_revenue,
    COUNT(*)                                AS total_transactions,
    ROUND(SUM(revenue) / COUNT(*), 2)       AS avg_ticket,
    SUM(transaction_qty)                    AS total_units
FROM fact_transactions;


-- ------------------------------------------------------------
-- Q2. Revenue by store (JOIN + GROUP BY)
-- ------------------------------------------------------------
SELECT
    s.store_location,
    ROUND(SUM(f.revenue), 2)                AS revenue,
    COUNT(*)                                AS transactions,
    ROUND(SUM(f.revenue) / COUNT(*), 2)     AS avg_ticket
FROM fact_transactions f
JOIN dim_stores s ON f.store_id = s.store_id
GROUP BY s.store_location
ORDER BY revenue DESC;


-- ------------------------------------------------------------
-- Q3. Month-over-month growth (CTE + LAG window function)
-- Shows the acceleration through spring that the Excel/dashboard
-- projects also surfaced, but now with an exact growth rate
-- attached to each month.
-- ------------------------------------------------------------
WITH monthly_revenue AS (
    SELECT
        strftime('%Y-%m', transaction_date) AS month,
        ROUND(SUM(revenue), 2)              AS revenue
    FROM fact_transactions
    GROUP BY month
)
SELECT
    month,
    revenue,
    ROUND(revenue - LAG(revenue) OVER (ORDER BY month), 2)        AS mom_change,
    ROUND(100.0 * (revenue - LAG(revenue) OVER (ORDER BY month))
          / LAG(revenue) OVER (ORDER BY month), 1)                AS mom_pct_change
FROM monthly_revenue
ORDER BY month;


-- ------------------------------------------------------------
-- Q4. Running (cumulative) revenue by month
-- Window function with a frame — useful for "revenue to date"
-- style reporting.
-- ------------------------------------------------------------
SELECT
    strftime('%Y-%m', transaction_date)                           AS month,
    ROUND(SUM(revenue), 2)                                        AS monthly_revenue,
    ROUND(SUM(SUM(revenue)) OVER (ORDER BY strftime('%Y-%m', transaction_date)), 2)
                                                                   AS cumulative_revenue
FROM fact_transactions
GROUP BY month
ORDER BY month;


-- ------------------------------------------------------------
-- Q5. Top 3 products per store (PARTITION BY + RANK)
-- Answers a real merchandising question: "what should each
-- store's featured menu highlight?" — the answer differs by
-- location, which a single company-wide top-seller list would hide.
-- ------------------------------------------------------------
WITH product_store_rev AS (
    SELECT
        s.store_location,
        p.product_detail,
        p.product_category,
        SUM(f.revenue) AS revenue,
        RANK() OVER (PARTITION BY s.store_location ORDER BY SUM(f.revenue) DESC) AS rnk
    FROM fact_transactions f
    JOIN dim_stores   s ON f.store_id   = s.store_id
    JOIN dim_products p ON f.product_id = p.product_id
    GROUP BY s.store_location, p.product_detail, p.product_category
)
SELECT store_location, rnk, product_detail, product_category, ROUND(revenue, 2) AS revenue
FROM product_store_rev
WHERE rnk <= 3
ORDER BY store_location, rnk;


-- ------------------------------------------------------------
-- Q6. Stores beating the company-wide average ticket (correlated subquery)
-- ------------------------------------------------------------
SELECT
    s.store_location,
    ROUND(AVG(f.revenue), 2) AS avg_ticket
FROM fact_transactions f
JOIN dim_stores s ON f.store_id = s.store_id
GROUP BY s.store_location
HAVING AVG(f.revenue) > (SELECT AVG(revenue) FROM fact_transactions);


-- ------------------------------------------------------------
-- Q7. Revenue by hour of day (staffing view)
-- ------------------------------------------------------------
SELECT
    CAST(strftime('%H', transaction_time) AS INTEGER)  AS hour,
    ROUND(SUM(revenue), 2)                              AS revenue,
    COUNT(*)                                            AS transactions
FROM fact_transactions
GROUP BY hour
ORDER BY hour;


-- ------------------------------------------------------------
-- Q8. Category revenue share, with running % of total (window function)
-- Shows how few categories account for most of revenue —
-- an 80/20-style breakdown.
-- ------------------------------------------------------------
WITH category_rev AS (
    SELECT
        p.product_category,
        SUM(f.revenue) AS revenue
    FROM fact_transactions f
    JOIN dim_products p ON f.product_id = p.product_id
    GROUP BY p.product_category
)
SELECT
    product_category,
    ROUND(revenue, 2) AS revenue,
    ROUND(100.0 * revenue / SUM(revenue) OVER (), 1)                          AS pct_of_total,
    ROUND(100.0 * SUM(revenue) OVER (ORDER BY revenue DESC)
          / SUM(revenue) OVER (), 1)                                          AS running_pct
FROM category_rev
ORDER BY revenue DESC;


-- ------------------------------------------------------------
-- Q9. Products with inconsistent pricing (data quality check)
-- A real data-quality finding: some products were recorded at
-- multiple unit prices across the period. Surfacing this is
-- exactly the kind of check a careful analyst runs before
-- trusting downstream numbers.
-- ------------------------------------------------------------
SELECT
    p.product_detail,
    COUNT(DISTINCT f.unit_price) AS distinct_prices,
    MIN(f.unit_price)            AS min_price,
    MAX(f.unit_price)            AS max_price
FROM fact_transactions f
JOIN dim_products p ON f.product_id = p.product_id
GROUP BY p.product_detail
HAVING COUNT(DISTINCT f.unit_price) > 1
ORDER BY (MAX(f.unit_price) - MIN(f.unit_price)) DESC;


-- ------------------------------------------------------------
-- Q10. Weekday vs weekend comparison (CASE + aggregation)
-- ------------------------------------------------------------
SELECT
    CASE
        WHEN strftime('%w', transaction_date) IN ('0','6') THEN 'Weekend'
        ELSE 'Weekday'
    END                                          AS day_type,
    ROUND(SUM(revenue), 2)                       AS revenue,
    COUNT(*)                                     AS transactions,
    ROUND(SUM(revenue) / COUNT(*), 2)            AS avg_ticket
FROM fact_transactions
GROUP BY day_type;


-- ------------------------------------------------------------
-- Q11. Best single day per store (subquery in FROM clause)
-- ------------------------------------------------------------
SELECT store_location, transaction_date, revenue
FROM (
    SELECT
        s.store_location,
        f.transaction_date,
        SUM(f.revenue) AS revenue,
        RANK() OVER (PARTITION BY s.store_location ORDER BY SUM(f.revenue) DESC) AS rnk
    FROM fact_transactions f
    JOIN dim_stores s ON f.store_id = s.store_id
    GROUP BY s.store_location, f.transaction_date
)
WHERE rnk = 1;


-- ------------------------------------------------------------
-- Q12. 7-day moving average of daily revenue (window frame)
-- Smooths daily noise to show the underlying trend — the kind
-- of series you'd actually plot for a stakeholder.
-- ------------------------------------------------------------
WITH daily AS (
    SELECT transaction_date, SUM(revenue) AS revenue
    FROM fact_transactions
    GROUP BY transaction_date
)
SELECT
    transaction_date,
    ROUND(revenue, 2) AS revenue,
    ROUND(AVG(revenue) OVER (
        ORDER BY transaction_date
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ), 2) AS moving_avg_7day
FROM daily
ORDER BY transaction_date;
