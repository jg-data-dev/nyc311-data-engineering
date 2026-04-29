"""
python analyze/analyze.py --export-csv
"""

from __future__ import annotations

import argparse
import csv
from pathlib import Path
from typing import Iterable

import psycopg
from config import DATABASE_URL


BASE_DIR = Path(__file__).resolve().parent
STANDARD_DIR = BASE_DIR / "standard"
INTERMEDIATE_DIR = STANDARD_DIR / "intermediate"
MARTS_DIR = STANDARD_DIR / "marts"
OUTPUTS_DIR = BASE_DIR / "outputs"


def read_sql_file(path: Path) -> str:
    if not path.exists():
        raise FileNotFoundError(f"SQL file not found: {path}")
    return path.read_text(encoding="utf-8")


def run_sql_file(conn: psycopg.Connection, path: Path) -> None:
    sql = read_sql_file(path)
    print(f"Running: {path.relative_to(BASE_DIR)}")
    with conn.cursor() as cur:
        cur.execute(sql)
    conn.commit()


def export_query_to_csv(
    conn: psycopg.Connection,
    query: str,
    output_path: Path,
) -> None:
    output_path.parent.mkdir(parents=True, exist_ok=True)

    with conn.cursor() as cur:
        cur.execute(query)
        rows = cur.fetchall()
        headers = [desc.name for desc in cur.description]

    with output_path.open("w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow(headers)
        writer.writerows(rows)

    print(f"Exported: {output_path.relative_to(BASE_DIR)}")


def get_sql_files(paths: Iterable[Path]) -> list[Path]:
    return sorted([p for p in paths if p.suffix == ".sql"])


def get_mart_table_names() -> list[str]:
    """
    Infer mart table names from SQL filenames.

    Example:
        analyze/standard/marts/fct_daily_metrics.sql
        -> fct_daily_metrics
    """
    mart_files = get_sql_files(MARTS_DIR.glob("*.sql"))
    return [path.stem for path in mart_files]


def materialize_standard_models(conn: psycopg.Connection) -> None:
    intermediate_files = get_sql_files(INTERMEDIATE_DIR.glob("*.sql"))
    mart_files = get_sql_files(MARTS_DIR.glob("*.sql"))

    for path in intermediate_files:
        run_sql_file(conn, path)

    for path in mart_files:
        run_sql_file(conn, path)


def export_table_to_csv(conn: psycopg.Connection, table_name: str) -> None:
    query = f"SELECT * FROM {table_name};"
    output_path = OUTPUTS_DIR / f"{table_name}.csv"
    export_query_to_csv(conn, query, output_path)


def export_standard_outputs(conn: psycopg.Connection) -> None:
    for table_name in get_mart_table_names():
        export_table_to_csv(conn, table_name)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Materialize standard analysis models and optionally export CSV outputs."
    )
    parser.add_argument(
        "--export-csv",
        action="store_true",
        help="Export mart tables to CSV after materialization.",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()

    OUTPUTS_DIR.mkdir(parents=True, exist_ok=True)

    with psycopg.connect(DATABASE_URL) as conn:
        materialize_standard_models(conn)

        if args.export_csv:
            export_standard_outputs(conn)


if __name__ == "__main__":
    main()