
from pathlib import Path

import duckdb


PROJECT_ROOT = Path(__file__).resolve().parent.parent
DB_PATH = PROJECT_ROOT / "data" / "nearshift.duckdb"
SQL_PATH = PROJECT_ROOT / "sql" / "02_curated.sql"


def main():
    if not DB_PATH.exists():
        raise FileNotFoundError(
            f"Database not found: {DB_PATH}. Run the ingestion and modeling steps first."
        )

    if not SQL_PATH.exists():
        raise FileNotFoundError(f"Curated SQL file not found: {SQL_PATH}")

    with duckdb.connect(str(DB_PATH)) as con:
        con.execute(SQL_PATH.read_text(encoding="utf-8"))

        views = [
            "monthly_sales",
            "monthly_order_value",
            "customer_repeat_rate",
            "category_performance",
            "delivery_performance",
        ]

        print("Curated views created successfully.")

        for view in views:
            count = con.execute(
                f"SELECT COUNT(*) FROM curated.{view}"
            ).fetchone()[0]
            print(f"curated.{view}: {count} rows")


if __name__ == "__main__":
    main()
