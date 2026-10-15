
-- Reconciliation and integrity checks for the NearShift assessment.
-- Monetary comparisons allow a tolerance of 0.01.

WITH checks AS (

    SELECT
        'Orders row count' AS check_name,
        CAST((SELECT COUNT(*) FROM raw.olist_orders_dataset) AS VARCHAR)
            AS expected_value,
        CAST((SELECT COUNT(*) FROM modeled.fact_orders) AS VARCHAR)
            AS actual_value,
        (SELECT COUNT(*) FROM raw.olist_orders_dataset)
            = (SELECT COUNT(*) FROM modeled.fact_orders) AS passed

    UNION ALL

    SELECT
        'Customers row count',
        CAST((SELECT COUNT(*) FROM raw.olist_customers_dataset AS r) AS VARCHAR),
        CAST((SELECT COUNT(*) FROM modeled.dim_customers AS m) AS VARCHAR),
        (SELECT COUNT(*) FROM raw.olist_customers_dataset)
            = (SELECT COUNT(*) FROM modeled.dim_customers)

    UNION ALL

    SELECT
        'Products row count',
        CAST((SELECT COUNT(*) FROM raw.olist_products_dataset) AS VARCHAR),
        CAST((SELECT COUNT(*) FROM modeled.dim_products) AS VARCHAR),
        (SELECT COUNT(*) FROM raw.olist_products_dataset)
            = (SELECT COUNT(*) FROM modeled.dim_products)

    UNION ALL

    SELECT
        'Order items row count',
        CAST((SELECT COUNT(*) FROM raw.olist_order_items_dataset) AS VARCHAR),
        CAST((SELECT COUNT(*) FROM modeled.fact_order_items) AS VARCHAR),
        (SELECT COUNT(*) FROM raw.olist_order_items_dataset)
            = (SELECT COUNT(*) FROM modeled.fact_order_items)

    UNION ALL

    SELECT
        'Payments row count',
        CAST((SELECT COUNT(*) FROM raw.olist_order_payments_dataset) AS VARCHAR),
        CAST((SELECT COUNT(*) FROM modeled.fact_payments) AS VARCHAR),
        (SELECT COUNT(*) FROM raw.olist_order_payments_dataset)
            = (SELECT COUNT(*) FROM modeled.fact_payments)

    UNION ALL

    SELECT
        'Raw vs modeled item value',
        CAST(ROUND((
            SELECT SUM(TRY_CAST(price AS DECIMAL(18,2)))
            FROM raw.olist_order_items_dataset
        ), 2) AS VARCHAR),
        CAST(ROUND((
            SELECT SUM(price)
            FROM modeled.fact_order_items
        ), 2) AS VARCHAR),
        ABS(
            (SELECT SUM(TRY_CAST(price AS DECIMAL(18,2)))
             FROM raw.olist_order_items_dataset)
            -
            (SELECT SUM(price) FROM modeled.fact_order_items)
        ) < 0.01

    UNION ALL

    SELECT
        'Raw vs modeled payment value',
        CAST(ROUND((
            SELECT SUM(TRY_CAST(payment_value AS DECIMAL(18,2)))
            FROM raw.olist_order_payments_dataset
        ), 2) AS VARCHAR),
        CAST(ROUND((
            SELECT SUM(payment_value)
            FROM modeled.fact_payments
        ), 2) AS VARCHAR),
        ABS(
            (SELECT SUM(TRY_CAST(payment_value AS DECIMAL(18,2)))
             FROM raw.olist_order_payments_dataset)
            -
            (SELECT SUM(payment_value) FROM modeled.fact_payments)
        ) < 0.01

    UNION ALL

    SELECT
        'Raw vs curated eligible product revenue',
        CAST(ROUND((
            SELECT SUM(TRY_CAST(i.price AS DECIMAL(18,2)))
            FROM raw.olist_order_items_dataset AS i
            JOIN raw.olist_orders_dataset AS o USING (order_id)
            WHERE o.order_status <> 'canceled'
        ), 2) AS VARCHAR),
        CAST(ROUND((
            SELECT SUM(product_revenue)
            FROM curated.monthly_sales
        ), 2) AS VARCHAR),
        ABS(
            (SELECT SUM(TRY_CAST(i.price AS DECIMAL(18,2)))
             FROM raw.olist_order_items_dataset AS i
             JOIN raw.olist_orders_dataset AS o USING (order_id)
             WHERE o.order_status <> 'canceled')
            -
            (SELECT SUM(product_revenue)
             FROM curated.monthly_sales)
        ) < 0.01

    UNION ALL

    SELECT
        'Orders without a customer',
        '0',
        CAST((
            SELECT COUNT(*)
            FROM modeled.fact_orders AS o
            LEFT JOIN modeled.dim_customers AS c
                ON o.customer_id = c.customer_id
            WHERE c.customer_id IS NULL
        ) AS VARCHAR),
        (
            SELECT COUNT(*)
            FROM modeled.fact_orders AS o
            LEFT JOIN modeled.dim_customers AS c
                ON o.customer_id = c.customer_id
            WHERE c.customer_id IS NULL
        ) = 0

    UNION ALL

    SELECT
        'Items without an order',
        '0',
        CAST((
            SELECT COUNT(*)
            FROM modeled.fact_order_items AS i
            LEFT JOIN modeled.fact_orders AS o
                ON i.order_id = o.order_id
            WHERE o.order_id IS NULL
        ) AS VARCHAR),
        (
            SELECT COUNT(*)
            FROM modeled.fact_order_items AS i
            LEFT JOIN modeled.fact_orders AS o
                ON i.order_id = o.order_id
            WHERE o.order_id IS NULL
        ) = 0

    UNION ALL

    SELECT
        'Items without a product',
        '0',
        CAST((
            SELECT COUNT(*)
            FROM modeled.fact_order_items AS i
            LEFT JOIN modeled.dim_products AS p
                ON i.product_id = p.product_id
            WHERE p.product_id IS NULL
        ) AS VARCHAR),
        (
            SELECT COUNT(*)
            FROM modeled.fact_order_items AS i
            LEFT JOIN modeled.dim_products AS p
                ON i.product_id = p.product_id
            WHERE p.product_id IS NULL
        ) = 0

    UNION ALL

    SELECT
        'Payments without an order',
        '0',
        CAST((
            SELECT COUNT(*)
            FROM modeled.fact_payments AS p
            LEFT JOIN modeled.fact_orders AS o
                ON p.order_id = o.order_id
            WHERE o.order_id IS NULL
        ) AS VARCHAR),
        (
            SELECT COUNT(*)
            FROM modeled.fact_payments AS p
            LEFT JOIN modeled.fact_orders AS o
                ON p.order_id = o.order_id
            WHERE o.order_id IS NULL
        ) = 0
)

SELECT
    check_name,
    expected_value,
    actual_value,
    CASE WHEN passed THEN 'PASS' ELSE 'FAIL' END AS status
FROM checks
ORDER BY check_name;
