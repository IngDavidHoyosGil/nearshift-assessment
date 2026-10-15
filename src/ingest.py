from pathlib import Path

import duckdb

RAW_FILES = (
    "olist_customers_dataset.csv",
    "olist_geolocation_dataset.csv",
    "olist_order_items_dataset.csv",
    "olist_order_payments_dataset.csv",
    "olist_order_reviews_dataset.csv",
    "olist_orders_dataset.csv",
    "olist_products_dataset.csv",
    "olist_sellers_dataset.csv",
    "product_category_name_translation.csv",    
)

def ingest_raw(raw_dir: Path, db_path: Path) -> dict:
    """Load source CSV files into DuckDB raw tables without inferring data types"""
    raw_dir = Path(raw_dir)
    db_path = Path(db_path)

    missing_files = [
        filename for filename in RAW_FILES
        if not (raw_dir / filename).is_file()
    ]

    if missing_files:
        raise FileNotFoundError(
            f"Missing required CSV files in {raw_dir}: "
            f"{', '.join(missing_files)}"
        )

    results = {}

    with duckdb.connect(str(db_path)) as con:
        con.execute("CREATE SCHEMA IF NOT EXISTS raw")

        for filename in RAW_FILES:
            csv_path = raw_dir / filename 
            table_name = Path(filename).stem

            # Read every column as VARCHAR to defer type casting to later stages.

            relation = con.read_csv(
                str(csv_path),
                header=True,
                all_varchar=True
            )

            relation.create_view("_raw_source", replace=True)

            con.execute(
                f'CREATE OR REPLACE TABLE raw."{table_name}" '
                "AS SELECT * FROM _raw_source"
            )

            row_count = con.execute(
                f'SELECT COUNT(*) FROM raw."{table_name}"'
            ).fetchone()[0]

            columns = [
                row[0]
                for row in con.execute(
                    f'DESCRIBE raw."{table_name}"'
                ).fetchall()
            ]

            results[table_name] = {
                "source_file": filename,
                "row_count": row_count,
                "columns": columns,
            }

            con.execute("DROP VIEW IF EXISTS _raw_source")

    return results
