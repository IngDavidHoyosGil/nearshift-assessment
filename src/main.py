from pathlib import Path

from src.ingest import ingest_raw

PROJECT_ROOT = Path(__file__).resolve().parent.parent
RAW_DIR = PROJECT_ROOT / "data" / "raw"
DB_PATH = PROJECT_ROOT / "data" / "nearshift.duckdb"


def main() -> None:
    results = ingest_raw(RAW_DIR, DB_PATH)

    total_rows = 0

    print("\nRAW INGESTION SUMMARY")
    print("=" * 50)

    for table_name, info in results.items():
        row_count = info["row_count"]
        total_rows += row_count

        print(
            f"{table_name}: "
            f"{row_count:,} rows, "
            f"{len(info['columns'])} columns"
        )

    print("=" * 50)
    print(f"Tables loaded: {len(results)}")
    print(f"Total rows loaded: {total_rows:,}")
    print(f"Database: {DB_PATH}")


if __name__ == "__main__":
    main()