
from pathlib import Path

import duckdb


PROJECT_ROOT = Path(__file__).resolve().parent.parent
DB_PATH = PROJECT_ROOT / "data" / "nearshift.duckdb"
SQL_PATH = PROJECT_ROOT / "sql" / "03_validation.sql"


def main():
    if not DB_PATH.exists():
        raise FileNotFoundError(f"Database not found: {DB_PATH}")

    if not SQL_PATH.exists():
        raise FileNotFoundError(f"Validation SQL not found: {SQL_PATH}")

    with duckdb.connect(str(DB_PATH), read_only=True) as con:
        results = con.execute(
            SQL_PATH.read_text(encoding="utf-8")
        ).df()

    print("Validation results")
    print(results.to_string(index=False))

    failures = results[results["status"] == "FAIL"]

    if not failures.empty:
        raise SystemExit(
            f"\nValidation failed: {len(failures)} check(s) did not pass."
        )

    print(f"\nAll {len(results)} validation checks passed.")


if __name__ == "__main__":
    main()
