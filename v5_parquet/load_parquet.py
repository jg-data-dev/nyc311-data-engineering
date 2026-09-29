import io

import pyarrow.parquet as pq
import psycopg2
import pandas as pd


PARQUET_FILE = "yellow_tripdata_2026-01.parquet"

DB_CONFIG = {
    "port": 5432,
    "dbname": "postgres",
    "user": "janeguo",
}

TABLE_NAME = "raw_tlc_yellow_trips"

BATCH_SIZE = 100_000


CREATE_TABLE_SQL = f"""
CREATE TABLE IF NOT EXISTS {TABLE_NAME} (
    vendor_id SMALLINT,
    tpep_pickup_datetime TIMESTAMP,
    tpep_dropoff_datetime TIMESTAMP,
    passenger_count INTEGER,
    trip_distance DOUBLE PRECISION,
    ratecode_id SMALLINT,
    store_and_fwd_flag TEXT,
    pu_location_id INTEGER,
    do_location_id INTEGER,
    payment_type SMALLINT,
    fare_amount DOUBLE PRECISION,
    extra DOUBLE PRECISION,
    mta_tax DOUBLE PRECISION,
    tip_amount DOUBLE PRECISION,
    tolls_amount DOUBLE PRECISION,
    improvement_surcharge DOUBLE PRECISION,
    total_amount DOUBLE PRECISION,
    congestion_surcharge DOUBLE PRECISION,
    airport_fee DOUBLE PRECISION,
    cbd_congestion_fee DOUBLE PRECISION
);
"""


SOURCE_COLUMNS = [
    "VendorID",
    "tpep_pickup_datetime",
    "tpep_dropoff_datetime",
    "passenger_count",
    "trip_distance",
    "RatecodeID",
    "store_and_fwd_flag",
    "PULocationID",
    "DOLocationID",
    "payment_type",
    "fare_amount",
    "extra",
    "mta_tax",
    "tip_amount",
    "tolls_amount",
    "improvement_surcharge",
    "total_amount",
    "congestion_surcharge",
    "Airport_fee",
    "cbd_congestion_fee",
]


TARGET_COLUMNS = [
    "vendor_id",
    "tpep_pickup_datetime",
    "tpep_dropoff_datetime",
    "passenger_count",
    "trip_distance",
    "ratecode_id",
    "store_and_fwd_flag",
    "pu_location_id",
    "do_location_id",
    "payment_type",
    "fare_amount",
    "extra",
    "mta_tax",
    "tip_amount",
    "tolls_amount",
    "improvement_surcharge",
    "total_amount",
    "congestion_surcharge",
    "airport_fee",
    "cbd_congestion_fee",
]


def main():
    parquet = pq.ParquetFile(PARQUET_FILE)

    print("Parquet file:")
    print(PARQUET_FILE)
    print()

    print("Rows:", f"{parquet.metadata.num_rows:,}")
    print("Row groups:", parquet.metadata.num_row_groups)
    print()

    print("Schema:")
    print(parquet.schema)
    print()

    conn = psycopg2.connect(**DB_CONFIG)

    try:
        with conn.cursor() as cur:
            cur.execute(CREATE_TABLE_SQL)

        conn.commit()

        total_loaded = 0

        for batch_number, batch in enumerate(
            parquet.iter_batches(
                batch_size=BATCH_SIZE,
                columns=SOURCE_COLUMNS,
            ),
            start=1,
        ):
            df = batch.to_pandas()
            # Preserve nullable integer columns as integers rather than floats.
            integer_columns = [
                "VendorID",
                "passenger_count",
                "RatecodeID",
                "PULocationID",
                "DOLocationID",
                "payment_type",
            ]

            for col in integer_columns:
                df[col] = df[col].astype("Int64")

            # PostgreSQL COPY understands blank fields as NULL when
            # we explicitly specify NULL '' below.
            csv_buffer = io.StringIO()

            df.to_csv(
                csv_buffer,
                index=False,
                header=False,
                na_rep="",
            )

            csv_buffer.seek(0)

            column_list = ", ".join(TARGET_COLUMNS)

            copy_sql = f"""
                COPY {TABLE_NAME} ({column_list})
                FROM STDIN
                WITH (
                    FORMAT CSV,
                    NULL ''
                )
            """

            with conn.cursor() as cur:
                cur.copy_expert(copy_sql, csv_buffer)

            conn.commit()

            total_loaded += len(df)

            print(
                f"Batch {batch_number}: "
                f"{len(df):,} rows | "
                f"total loaded: {total_loaded:,}"
            )

    except Exception:
        conn.rollback()
        raise

    finally:
        conn.close()

    print()
    print(f"Finished loading {total_loaded:,} rows into {TABLE_NAME}.")


if __name__ == "__main__":
    main()
