CREATE SCHEMA IF NOT EXISTS modeled;

-- 1. Customers: one row per customer_id.
CREATE OR REPLACE TABLE modeled.dim_customers AS
SELECT
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state
FROM raw.olist_customers_dataset;

-- 2. Products: one row per product_id.
-- Keep untranslated categories using a LEFT JOIN.
CREATE OR REPLACE TABLE modeled.dim_products AS
SELECT
    p.product_id,
    p.product_category_name,
    t.product_category_name_english,
    TRY_CAST(NULLIF(p.product_name_lenght, '') AS INTEGER)
        AS product_name_length,
    TRY_CAST(NULLIF(p.product_description_lenght, '') AS INTEGER)
        AS product_description_length,
    TRY_CAST(NULLIF(p.product_photos_qty, '') AS INTEGER)
        AS product_photos_quantity,
    TRY_CAST(NULLIF(p.product_weight_g, '') AS DECIMAL(12, 2))
        AS product_weight_g,
    TRY_CAST(NULLIF(p.product_length_cm, '') AS DECIMAL(12, 2))
        AS product_length_cm,
    TRY_CAST(NULLIF(p.product_height_cm, '') AS DECIMAL(12, 2))
        AS product_height_cm,
    TRY_CAST(NULLIF(p.product_width_cm, '') AS DECIMAL(12, 2))
        AS product_width_cm
FROM raw.olist_products_dataset AS p
LEFT JOIN raw.product_category_name_translation AS t
    USING (product_category_name);

-- 3. Orders: one row per order_id.
CREATE OR REPLACE TABLE modeled.fact_orders AS
SELECT
    order_id,
    customer_id,
    order_status,
    TRY_CAST(NULLIF(order_purchase_timestamp, '') AS TIMESTAMP)
        AS order_purchase_timestamp,
    TRY_CAST(NULLIF(order_approved_at, '') AS TIMESTAMP)
        AS order_approved_at,
    TRY_CAST(NULLIF(order_delivered_carrier_date, '') AS TIMESTAMP)
        AS order_delivered_carrier_date,
    TRY_CAST(NULLIF(order_delivered_customer_date, '') AS TIMESTAMP)
        AS order_delivered_customer_date,
    TRY_CAST(NULLIF(order_estimated_delivery_date, '') AS TIMESTAMP)
        AS order_estimated_delivery_date
FROM raw.olist_orders_dataset;

-- 4. Order items: one row per order_id + order_item_id.
CREATE OR REPLACE TABLE modeled.fact_order_items AS
SELECT
    order_id,
    TRY_CAST(NULLIF(order_item_id, '') AS INTEGER)
        AS order_item_id,
    product_id,
    seller_id,
    TRY_CAST(NULLIF(shipping_limit_date, '') AS TIMESTAMP)
        AS shipping_limit_date,
    TRY_CAST(NULLIF(price, '') AS DECIMAL(12, 2))
        AS price,
    TRY_CAST(NULLIF(freight_value, '') AS DECIMAL(12, 2))
        AS freight_value
FROM raw.olist_order_items_dataset;

-- 5. Payments: one row per order_id + payment_sequential.
CREATE OR REPLACE TABLE modeled.fact_payments AS
SELECT
    order_id,
    TRY_CAST(NULLIF(payment_sequential, '') AS INTEGER)
        AS payment_sequential,
    payment_type,
    TRY_CAST(NULLIF(payment_installments, '') AS INTEGER)
        AS payment_installments,
    TRY_CAST(NULLIF(payment_value, '') AS DECIMAL(12, 2))
        AS payment_value
FROM raw.olist_order_payments_dataset;