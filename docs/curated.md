# Curated data

## Purpose and execution

The curated layer provides business-facing views over the modeled tables. View definitions are in [`sql/02_curated.sql`](../sql/02_curated.sql); [`src/curate.py`](../src/curate.py) executes that SQL against `data/nearshift.duckdb` and reports each view's row count.

```bash
python -m src.curate
```

Run ingestion and modeling first so the database contains the `raw` and `modeled` schemas. Curated objects are DuckDB views, not materialized tables. The SQL uses `CREATE OR REPLACE VIEW`, so rerunning the command refreshes their definitions.

## Views

| View | Grain | Definition |
|---|---|---|
| `curated.monthly_sales` | One row per purchase month | Distinct orders represented by at least one item, item `price` summed as `product_revenue`, and `freight_value` summed separately. Orders with status `canceled` are excluded. |
| `curated.monthly_order_value` | One row per purchase month | Reuses monthly sales and divides product revenue by its distinct order count. AOV excludes freight and canceled orders. |
| `curated.customer_repeat_rate` | One summary row for the full dataset | Counts customers by `customer_unique_id`; a repeat customer has at least two distinct non-canceled orders. Reports total customers, repeat customers, and their percentage. |
| `curated.category_performance` | One row per product category | Counts items and distinct orders and sums item prices for non-canceled orders. Uses the English translation when available, then the source category name, then `unknown`. |
| `curated.delivery_performance` | One row per purchase month | Among delivered orders with both actual and estimated delivery timestamps, counts orders delivered on or before estimate and reports the on-time percentage. Month is based on purchase date. |

## Metric interpretation

The status filter `order_status <> 'canceled'` excludes canceled and null-status orders. Monthly sales and category performance join order items to orders, so orders without items do not contribute; `total_orders` is the number of distinct orders represented in those item rows. The repeat-rate view joins modeled orders to customers and groups by `customer_unique_id`, allowing multiple `customer_id` values for one customer to count together.

Product revenue uses item prices only. Freight is a separate monthly-sales measure, and payment values are not used as a proxy for revenue. Delivery performance measures delivery timeliness against the estimated date; it does not measure fulfillment time from purchase or approval.

Query a view directly, for example:

```sql
SELECT *
FROM curated.monthly_sales
ORDER BY purchase_month;
```

Customers with no qualifying non-canceled orders are not included in the denominator.