from pathlib import Path
import duckdb
from src.ingest import ingest_raw, RAW_FILES

def test_ingest_loads_all_csv_files_as_raw_tables(tmp_path):
    raw_dir = tmp_path / "raw"
    raw_dir.mkdir()

    # Create small CSV fixtures instead of using the full dataset.
    for filename in RAW_FILES:
        (raw_dir / filename).write_text(
            "id,amount\n001,10.50\n002,20.00\n",
            encoding="utf-8",
        )

    db_path = tmp_path / "test.duckdb"

    results = ingest_raw(raw_dir, db_path)

    assert len(results) == len(RAW_FILES)
    assert all(result["row_count"] == 2 for result in results.values())

    with duckdb.connect(str(db_path),read_only=True) as con:
        tables = con.execute(
            """
            SELECT table_name
            FROM information_schema.tables
            WHERE table_schema = 'raw'
            """
        ).fetchall()

        assert len(tables) == len(RAW_FILES)

        #Raw identifiers must remain strings, preserving leading zeros.
        value = con.execute(
            f'SELECT id FROM raw."{RAW_FILES[0].removesuffix(".csv")}" LIMIT 1'
        ).fetchone()[0]

        assert value == "001"

def test_ingest_fails_if_a_required_csv_is_missing(tmp_path):
    raw_dir = tmp_path / "raw"
    raw_dir.mkdir()

    # Create every required file except the last one.
    for filename in RAW_FILES[:-1]:
        (raw_dir / filename).write_text(
            "id,amount\n001,10.50\n",
            encoding="utf-8",
        )

    db_path = tmp_path / "test.duckdb"

    import pytest

    with pytest.raises(FileNotFoundError, match=RAW_FILES[-1]):
        ingest_raw(raw_dir, db_path)