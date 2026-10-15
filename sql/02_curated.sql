
CREATE SCHEMA IF NOT EXISTS curated;

-- 1. Monthly sales: product revenue and freight are kept separate.
-- Grain: one row per purchase month.
CREATE OR REPLACE VIEW curated.monthly_sales AS
SELECT
    DATE_TRUNC('month', o.order_purchase_timestamp)::DATE AS purchase_month,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(i.price) AS product_revenue,
    SUM(i.freight_value) AS freight_value
FROM modeled.fact_orders AS o
JOIN modeled.fact_order_items AS i
    ON o.order_id = i.order_id
WHERE o.order_status <> 'canceled'
GROUP BY 1;


-- 2. Monthly average order value (AOV).
-- Grain: one row per purchase month.
-- AOV excludes freight and canceled orders.
CREATE OR REPLACE VIEW curated.monthly_order_value AS
SELECT
    purchase_month,
    total_orders,
    product_revenue,
    product_revenue / NULLIF(total_orders, 0) AS average_order_value
FROM curated.monthly_sales;


-- 3. Overall repeat-purchase rate.
-- A customer is identified by customer_unique_id.
-- Grain: one summary row for the full dataset.
CREATE OR REPLACE VIEW curated.customer_repeat_rate AS
WITH customer_orders AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS order_count
    FROM modeled.fact_orders AS o
    JOIN modeled.dim_customers AS c
        ON o.customer_id = c.customer_id
    WHERE o.order_status <> 'canceled'
    GROUP BY c.customer_unique_id
)
SELECT
    COUNT(*) AS total_customers,
    SUM(CASE WHEN order_count >= 2 THEN 1 ELSE 0 END)
        AS repeat_customers,
    100.0 * SUM(CASE WHEN order_count >= 2 THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0) AS repeat_purchase_rate_pct
FROM customer_orders;


-- 4. Product category performance.
-- Grain: one row per product category.
-- Missing English translations fall back to the original category name.
CREATE OR REPLACE VIEW curated.category_performance AS
SELECT
    COALESCE(
        p.product_category_name_english,
        p.product_category_name,
        'unknown'
    ) AS product_category,
    COUNT(*) AS items_sold,
    COUNT(DISTINCT i.order_id) AS total_orders,
    SUM(i.price) AS product_revenue
FROM modeled.fact_order_items AS i
JOIN modeled.fact_orders AS o
    ON i.order_id = o.order_id
JOIN modeled.dim_products AS p
    ON i.product_id = p.product_id
WHERE o.order_status <> 'canceled'
GROUP BY 1;


-- 5. Monthly delivery performance.
-- Grain: one row per purchase month.
-- Only delivered orders with both actual and estimated dates are eligible.
CREATE OR REPLACE VIEW curated.delivery_performance AS
WITH eligible_deliveries AS (
    SELECT
        DATE_TRUNC('month', order_purchase_timestamp)::DATE
            AS purchase_month,
        order_id,
        order_delivered_customer_date,
        order_estimated_delivery_date
    FROM modeled.fact_orders
    WHERE order_status = 'delivered'
      AND order_delivered_customer_date IS NOT NULL
      AND order_estimated_delivery_date IS NOT NULL
)
SELECT
    purchase_month,
    COUNT(*) AS eligible_delivered_orders,
    SUM(
        CASE
            WHEN order_delivered_customer_date
                 <= order_estimated_delivery_date
            THEN 1
            ELSE 0
        END
    ) AS on_time_deliveries,
    100.0 * SUM(
        CASE
            WHEN order_delivered_customer_date
                 <= order_estimated_delivery_date
            THEN 1
            ELSE 0
        END
    ) / NULLIF(COUNT(*), 0) AS on_time_delivery_rate_pct
FROM eligible_deliveries
GROUP BY 1;
