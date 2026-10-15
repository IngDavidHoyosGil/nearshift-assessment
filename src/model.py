from pathlib import Path

import duckdb


PROJECT_ROOT = Path(__file__).resolve().parent.parent
DB_PATH = PROJECT_ROOT / "data" / "nearshift.duckdb"
SQL_PATH = PROJECT_ROOT / "sql" / "01_model.sql"

MODELED_TABLES = (
    "dim_customers",
    "dim_products",
    "fact_orders",
    "fact_order_items",
    "fact_payments",
)


def main():
    if not DB_PATH.exists():
        raise FileNotFoundError(
            f"Database not found: {DB_PATH}. Run the ingestion first."
        )

    if not SQL_PATH.exists():
        raise FileNotFoundError(f"SQL model not found: {SQL_PATH}")

    sql = SQL_PATH.read_text(encoding="utf-8")

    with duckdb.connect(str(DB_PATH)) as con:
        con.execute(sql)

        print("Modeling completed successfully.")

        for table in MODELED_TABLES:
            row_count = con.execute(
                f"SELECT COUNT(*) FROM modeled.{table}"
            ).fetchone()[0]

            print(f"modeled.{table}: {row_count:,} rows")


if __name__ == "__main__":
    main()