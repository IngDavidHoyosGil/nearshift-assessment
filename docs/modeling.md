# Analytics Data Model

## Overview

The pipeline uses a layered ELT architecture:

- **Raw:** Source CSV files loaded into DuckDB without business transformations.
- **Modeled:** Typed, relational fact and dimension tables built from raw data.
- **Curated:** Business metrics and analytical datasets built on top of the modeled layer.

## Grain and Modeling Decisions

| Table | Grain | Key | Purpose |
|---|---|---|---|
| `fact_orders` | One row per order | `order_id` | Order status and lifecycle timestamps |
| `fact_order_items` | One row per order item | `order_id`, `order_item_id` | Item prices, freight, products, and sellers |
| `fact_payments` | One row per payment record | `order_id`, `payment_sequential` | Payment methods, installments, and payment values |
| `dim_customers` | One row per `customer_id` record | `customer_id` | Customer location and mapping to `customer_unique_id` |
| `dim_products` | One row per `product_id` | `product_id` | Product attributes and translated category names |

## Important Modeling Choices

- Raw tables remain unchanged by the modeling process.
- Data types are explicitly assigned in the modeled layer.
- Order items and payment records are modeled separately to avoid multiplying monetary values when joining tables with different grains.
- `customer_unique_id` is retained to identify repeat customers across multiple `customer_id` records.
- Product category translations are applied through a left join so untranslated categories are not silently discarded.
- Unneeded source tables remain available in the raw layer and can be modeled later if required.

## Metric Considerations

Revenue, freight, and payment values are kept distinct. Business metrics must explicitly define their order-status filters, date basis, and monetary measure before aggregation.