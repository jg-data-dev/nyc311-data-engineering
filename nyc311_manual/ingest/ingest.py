"""
Usage:
python ingest/ingest.py --target-date 2026-04-25
python ingest/ingest.py --start-date 2026-09-16 --end-date 2026-12-31
python ingest/ingest.py --max-pages 10
python ingest/ingest.py --target-date 2026-04-25 --max-pages 1 (should be ignored)

Next:
--upsert only, consider overwrite/rebuild as options
--target-date → always safe to rerun
--start-date/end-date → safe partial rebuild
"""

import argparse
import os
from datetime import datetime, timedelta

import psycopg
import requests
from psycopg.types.json import Jsonb
from config import DATABASE_URL

API_URL = "https://data.cityofnewyork.us/resource/erm2-nwe9.json"

PAGE_SIZE = 1000
DEFAULT_MAX_PAGES = 3
DEFAULT_TARGET_TABLE = "raw_311_requests_probe"

ALLOWED_TARGET_TABLES = {
    "raw_311_requests",
    "raw_311_requests_probe",
}

UPSERT_SQL_TEMPLATE = """
INSERT INTO {target_table} (
    unique_key,
    created_date,
    closed_date,
    resolution_action_updated_date,
    agency,
    agency_name,
    complaint_type,
    descriptor,
    descriptor_2,
    status,
    resolution_description,
    open_data_channel_type,
    incident_address,
    street_name,
    cross_street_1,
    cross_street_2,
    intersection_street_1,
    intersection_street_2,
    landmark,
    city,
    borough,
    incident_zip,
    community_board,
    council_district,
    police_precinct,
    park_borough,
    park_facility_name,
    taxi_pick_up_location,
    bbl,
    x_coordinate_state_plane,
    y_coordinate_state_plane,
    latitude,
    longitude,
    location,
    raw_json
)
VALUES (
    %(unique_key)s,
    %(created_date)s,
    %(closed_date)s,
    %(resolution_action_updated_date)s,
    %(agency)s,
    %(agency_name)s,
    %(complaint_type)s,
    %(descriptor)s,
    %(descriptor_2)s,
    %(status)s,
    %(resolution_description)s,
    %(open_data_channel_type)s,
    %(incident_address)s,
    %(street_name)s,
    %(cross_street_1)s,
    %(cross_street_2)s,
    %(intersection_street_1)s,
    %(intersection_street_2)s,
    %(landmark)s,
    %(city)s,
    %(borough)s,
    %(incident_zip)s,
    %(community_board)s,
    %(council_district)s,
    %(police_precinct)s,
    %(park_borough)s,
    %(park_facility_name)s,
    %(taxi_pick_up_location)s,
    %(bbl)s,
    %(x_coordinate_state_plane)s,
    %(y_coordinate_state_plane)s,
    %(latitude)s,
    %(longitude)s,
    %(location)s,
    %(raw_json)s
)
ON CONFLICT (unique_key)
DO UPDATE SET
    created_date = EXCLUDED.created_date,
    closed_date = EXCLUDED.closed_date,
    resolution_action_updated_date = EXCLUDED.resolution_action_updated_date,
    agency = EXCLUDED.agency,
    agency_name = EXCLUDED.agency_name,
    complaint_type = EXCLUDED.complaint_type,
    descriptor = EXCLUDED.descriptor,
    descriptor_2 = EXCLUDED.descriptor_2,
    status = EXCLUDED.status,
    resolution_description = EXCLUDED.resolution_description,
    open_data_channel_type = EXCLUDED.open_data_channel_type,
    incident_address = EXCLUDED.incident_address,
    street_name = EXCLUDED.street_name,
    cross_street_1 = EXCLUDED.cross_street_1,
    cross_street_2 = EXCLUDED.cross_street_2,
    intersection_street_1 = EXCLUDED.intersection_street_1,
    intersection_street_2 = EXCLUDED.intersection_street_2,
    landmark = EXCLUDED.landmark,
    city = EXCLUDED.city,
    borough = EXCLUDED.borough,
    incident_zip = EXCLUDED.incident_zip,
    community_board = EXCLUDED.community_board,
    council_district = EXCLUDED.council_district,
    police_precinct = EXCLUDED.police_precinct,
    park_borough = EXCLUDED.park_borough,
    park_facility_name = EXCLUDED.park_facility_name,
    taxi_pick_up_location = EXCLUDED.taxi_pick_up_location,
    bbl = EXCLUDED.bbl,
    x_coordinate_state_plane = EXCLUDED.x_coordinate_state_plane,
    y_coordinate_state_plane = EXCLUDED.y_coordinate_state_plane,
    latitude = EXCLUDED.latitude,
    longitude = EXCLUDED.longitude,
    location = EXCLUDED.location,
    raw_json = EXCLUDED.raw_json;
"""

def validate_target_table(target_table: str) -> None:
    if target_table not in ALLOWED_TARGET_TABLES:
        raise ValueError(
            f"Invalid target table: {target_table}. "
            f"Allowed: {sorted(ALLOWED_TARGET_TABLES)}"
        )


def build_target_date_where_clause(target_date: str, offset_days: int) -> str:
    start_dt = datetime.fromisoformat(target_date)
    end_dt = start_dt + timedelta(days=offset_days)

    return (
        f"created_date >= '{start_dt:%Y-%m-%dT00:00:00}' "
        f"AND created_date < '{end_dt:%Y-%m-%dT00:00:00}'"
    )


def build_range_where_clause(start_date: str, end_date: str) -> str:
    start_dt = datetime.fromisoformat(start_date)
    end_dt = datetime.fromisoformat(end_date)

    return (
        f"created_date >= '{start_dt:%Y-%m-%dT00:00:00}' "
        f"AND created_date <= '{end_dt:%Y-%m-%dT23:59:59}'"
    )


def fetch_page(*, offset: int, where_clause: str | None) -> list[dict]:
    params = {
        "$limit": PAGE_SIZE,
        "$offset": offset,
        "$order": "created_date",
    }

    if where_clause:
        params["$where"] = where_clause

    response = requests.get(API_URL, params=params, timeout=60)
    response.raise_for_status()
    return response.json()


def normalize_row(row: dict) -> dict:
    return {
        "unique_key": row.get("unique_key"),
        "created_date": row.get("created_date"),
        "closed_date": row.get("closed_date"),
        "resolution_action_updated_date": row.get("resolution_action_updated_date"),
        "agency": row.get("agency"),
        "agency_name": row.get("agency_name"),
        "complaint_type": row.get("complaint_type"),
        "descriptor": row.get("descriptor"),
        "descriptor_2": row.get("descriptor_2"),
        "status": row.get("status"),
        "resolution_description": row.get("resolution_description"),
        "open_data_channel_type": row.get("open_data_channel_type"),
        "incident_address": row.get("incident_address"),
        "street_name": row.get("street_name"),
        "cross_street_1": row.get("cross_street_1"),
        "cross_street_2": row.get("cross_street_2"),
        "intersection_street_1": row.get("intersection_street_1"),
        "intersection_street_2": row.get("intersection_street_2"),
        "landmark": row.get("landmark"),
        "city": row.get("city"),
        "borough": row.get("borough"),
        "incident_zip": row.get("incident_zip"),
        "community_board": row.get("community_board"),
        "council_district": row.get("council_district"),
        "police_precinct": row.get("police_precinct"),
        "park_borough": row.get("park_borough"),
        "park_facility_name": row.get("park_facility_name"),
        "taxi_pick_up_location": row.get("taxi_pick_up_location"),
        "bbl": row.get("bbl"),
        "x_coordinate_state_plane": row.get("x_coordinate_state_plane"),
        "y_coordinate_state_plane": row.get("y_coordinate_state_plane"),
        "latitude": row.get("latitude"),
        "longitude": row.get("longitude"),
        "location": Jsonb(row.get("location")) if row.get("location") is not None else None,
        "raw_json": Jsonb(row),
    }

def upsert_rows(conn, rows: list[dict], *, target_table: str) -> int:
    if not rows:
        return 0

    validate_target_table(target_table)

    sql = UPSERT_SQL_TEMPLATE.format(target_table=target_table)
    normalized_rows = [normalize_row(row) for row in rows]

    with conn.cursor() as cur:
        cur.executemany(sql, normalized_rows)

    conn.commit()
    return len(normalized_rows)


def run_ingest(
    *,
    target_table: str,
    where_clause: str | None,
    max_pages: int | None,
) -> int:
    validate_target_table(target_table)

    total = 0
    page_num = 0

    print(f"Target table: {target_table}")

    if where_clause:
        print(f"WHERE: {where_clause}")
        print("Date-filtered ingest: max_pages ignored.")
    else:
        print(f"No date filter. max_pages={max_pages}")

    with psycopg.connect(DATABASE_URL) as conn:
        while True:
            if where_clause is None and max_pages is not None and page_num >= max_pages:
                break

            offset = page_num * PAGE_SIZE
            print(f"Fetching page {page_num + 1}, offset={offset} ...")

            rows = fetch_page(offset=offset, where_clause=where_clause)

            if not rows:
                print("No more rows returned.")
                break

            loaded = upsert_rows(conn, rows, target_table=target_table)
            total += loaded

            print(f"Inserted/updated {loaded} rows.")

            page_num += 1

    print(f"Ingest finished. Total inserted/updated: {total}")
    return total


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()

    parser.add_argument(
        "--target-table",
        default=DEFAULT_TARGET_TABLE,
        choices=sorted(ALLOWED_TARGET_TABLES),
    )

    parser.add_argument("--target-date")

    parser.add_argument(
        "--offset-days",
        type=int,
        default=1,
    )

    parser.add_argument("--start-date")
    parser.add_argument("--end-date")

    parser.add_argument(
        "--max-pages",
        type=int,
        default=DEFAULT_MAX_PAGES,
    )

    return parser.parse_args()


def main() -> None:
    args = parse_args()

    where_clause = None

    if args.target_date:
        where_clause = build_target_date_where_clause(
            target_date=args.target_date,
            offset_days=args.offset_days,
        )

    elif args.start_date and args.end_date:
        where_clause = build_range_where_clause(
            start_date=args.start_date,
            end_date=args.end_date,
        )

    elif args.start_date or args.end_date:
        raise ValueError("Use both --start-date and --end-date, or neither.")

    run_ingest(
        target_table=args.target_table,
        where_clause=where_clause,
        max_pages=args.max_pages,
    )


if __name__ == "__main__":
    main()