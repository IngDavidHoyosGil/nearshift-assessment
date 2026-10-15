# NearShift e-commerce analytics pipeline

ELT project over the Olist e-commerce CSV data. It loads source files into DuckDB, builds a typed analytics model, creates business-facing views, reconciles modeled values with the raw layer, and prints the requested business insights.

## Requirements

- Python 3.10 or newer
- The nine source CSV files listed below
- Dependencies from `requirements.txt`

Create and activate a virtual environment, then install dependencies:

```bash
python -m venv .venv
source .venv/bin/activate       # Windows PowerShell: .venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
```

## Source data

Place the CSV files in `data/raw/` (create the directory if needed):

```text
olist_customers_dataset.csv
olist_geolocation_dataset.csv
olist_order_items_dataset.csv
olist_order_payments_dataset.csv
olist_order_reviews_dataset.csv
olist_orders_dataset.csv
olist_products_dataset.csv
olist_sellers_dataset.csv
product_category_name_translation.csv
```

The CSV files and generated database are intentionally ignored by Git. Obtain the dataset separately and keep the source filenames unchanged. Ingestion checks that all nine files exist before loading. It creates or replaces matching tables in the DuckDB `raw` schema, reading every field as text to preserve source values and defer type conversion to modeling.

## Run the pipeline

From the project root, run each stage in order:

```bash
python -m src.main       # Load CSV files into data/nearshift.duckdb, schema raw
python -m src.model      # Build typed tables in schema modeled
python -m src.curate     # Create business-facing views in schema curated
python -m src.validate   # Reconcile row counts, monetary totals, and relationships
python -m src.insights   # Print the five requested analyses
```

The database is created at `data/nearshift.duckdb`. The raw and modeled tables are replaced when their respective build steps are rerun; curated objects are views whose definitions are refreshed by the curation step. Run validation after curation because the eligible-revenue check compares against `curated.monthly_sales`. A validation failure exits with a nonzero status.

## Layers and modeling

- **`raw`** contains all nine CSV tables as loaded, with columns retained as text.
- **`modeled`** contains `dim_customers` (one row per `customer_id`), `dim_products` (one per `product_id`), `fact_orders` (one per `order_id`), `fact_order_items` (one per order and item number), and `fact_payments` (one per order and payment sequence).
- **`curated`** contains the views described in [`docs/curated.md`](docs/curated.md). The model grains and design choices are in [`docs/modeling.md`](docs/modeling.md).

Order items and payments remain separate facts because their different grains could multiply monetary values if joined directly. Raw geolocation, review, and seller data are loaded and retained but are not used in the current modeled tables or business metrics.

## Metric definitions

- **Monthly revenue** is the sum of item prices (`product_revenue`) by purchase month. Freight is reported separately; payment value is not treated as revenue. Canceled orders are excluded.
- **Monthly order count and AOV** use distinct orders represented by at least one order-item row. Orders without items therefore do not contribute. AOV is product revenue divided by that order count, excluding freight and canceled orders.
- **Repeat-purchase rate** groups orders by `customer_unique_id`, counting at least two distinct non-canceled orders as a repeat customer. The denominator is customers with at least one qualifying order, not every row in the customer dimension.
- **Category performance** ranks categories by item-price revenue from non-canceled orders.
- **On-time delivery** is the share of delivered orders whose actual delivery timestamp is on or before the estimate. Orders missing either timestamp are excluded; results are grouped by purchase month.

The source timestamps are used as stored, without explicit timezone conversion. Canceled orders are excluded from commercial metrics, and the source data used here has no separate refund ledger. Further validation scope and known data-quality findings are in [`docs/validation.md`](docs/validation.md); the written analysis is in [`docs/insights.md`](docs/insights.md).

## Future improvement

The optional AI metric exposure from the original assignment was not implemented due to time constraints. A future iteration could add a small API endpoint or MCP-style tool that answers questions such as “What was revenue last month?” using only the curated DuckDB views. Any such interface should query modeled data only, define how “last month” is determined, and avoid generating figures that cannot be traced to the curated metrics.

## Tests

Run the ingestion unit tests with:

```bash
python -m pytest
```
