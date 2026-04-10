"""
Rebuild staging table from raw 311 data
"""

import psycopg
from config import DB_CONFIG

def run_sql_file(conn, file_path: str) -> None:
    with open(file_path, "r") as f:
        sql = f.read()

    with conn.cursor() as cur:
        cur.execute(sql)

    conn.commit()


def main() -> None:
    with psycopg.connect(**DB_CONFIG) as conn:
        run_sql_file(conn, "sql/stage.sql")
        print("Staging table rebuilt successfully.")


if __name__ == "__main__":
    main()