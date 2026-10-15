from pathlib import Path

import duckdb

PROJECT_ROOT = Path(__file__).resolve().parent.parent
DB_PATH = PROJECT_ROOT / "data" / "nearshift.duckdb"

QUERIES = {
    "Monthly revenue": """
        SELECT *
        FROM curated.monthly_sales
        ORDER BY purchase_month
    """,
    "Monthly average order value": """
        SELECT *
        FROM curated.monthly_order_value
        ORDER BY purchase_month
    """,
    "Customer repeat rate": """
        SELECT *
        FROM curated.customer_repeat_rate
    """,
    "Top 10 product categories": """
        SELECT *
        FROM curated.category_performance
        ORDER BY product_revenue DESC
        LIMIT 10
    """,
    "Monthly on-time delivery": """
        SELECT *
        FROM curated.delivery_performance
        ORDER BY purchase_month
    """,
}


def main():
    if not DB_PATH.exists():
        raise FileNotFoundError(f"Database not found: {DB_PATH}")

    with duckdb.connect(str(DB_PATH), read_only=True) as con:
        for title, query in QUERIES.items():
            results = con.execute(query).df()
            print(f"\n{'=' * 72}")
            print(title)
            print("=" * 72)
            print(results.to_string(index=False))


if __name__ == "__main__":
    main()