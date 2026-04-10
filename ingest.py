import os
import requests
import psycopg
from datetime import datetime
from config import DB_CONFIG


API_URL = "https://data.cityofnewyork.us/resource/erm2-nwe9.json"
PAGE_SIZE = 1000
MAX_PAGES = 3

RAW_COLUMNS = [
    "unique_key",
    "created_date",
    "closed_date",
    "resolution_action_updated_date",
    "agency",
    "agency_name",
    "complaint_type",
    "descriptor",
    "descriptor_2",
    "status",
    "resolution_description",
    "open_data_channel_type",
    "incident_address",
    "street_name",
    "cross_street_1",
    "cross_street_2",
    "intersection_street_1",
    "intersection_street_2",
    "landmark",
    "city",
    "borough",
    "incident_zip",
    "community_board",
    "council_district",
    "police_precinct",
    "park_borough",
    "park_facility_name",
    "taxi_pick_up_location",
    "bbl",
    "x_coordinate_state_plane",
    "y_coordinate_state_plane",
    "latitude",
    "longitude",
    "location",
    "raw_json",
]

INSERT_SQL = """
INSERT INTO raw_311_requests (
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
ON CONFLICT (unique_key) DO UPDATE SET
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
    raw_json = EXCLUDED.raw_json
"""

def parse_timestamp(value: str | None):
    if not value:
        return None
    return datetime.fromisoformat(value)

def parse_float(value: str | None):
    if value in (None, ""):
        return None
    return float(value)

def clean_text(value):
    if value is None:
        return None
    if isinstance(value, str):
        value = value.strip()
        return value if value != "" else None
    return value

def normalize_record(row: dict) -> dict:
    return {
        "unique_key": clean_text(row.get("unique_key")),
        "created_date": parse_timestamp(row.get("created_date")),
        "closed_date": parse_timestamp(row.get("closed_date")),
        "resolution_action_updated_date": parse_timestamp(row.get("resolution_action_updated_date")),
        "agency": clean_text(row.get("agency")),
        "agency_name": clean_text(row.get("agency_name")),
        "complaint_type": clean_text(row.get("complaint_type")),
        "descriptor": clean_text(row.get("descriptor")),
        "descriptor_2": clean_text(row.get("descriptor_2")),
        "status": clean_text(row.get("status")),
        "resolution_description": clean_text(row.get("resolution_description")),
        "open_data_channel_type": clean_text(row.get("open_data_channel_type")),
        "incident_address": clean_text(row.get("incident_address")),
        "street_name": clean_text(row.get("street_name")),
        "cross_street_1": clean_text(row.get("cross_street_1")),
        "cross_street_2": clean_text(row.get("cross_street_2")),
        "intersection_street_1": clean_text(row.get("intersection_street_1")),
        "intersection_street_2": clean_text(row.get("intersection_street_2")),
        "landmark": clean_text(row.get("landmark")),
        "city": clean_text(row.get("city")),
        "borough": clean_text(row.get("borough")),
        "incident_zip": clean_text(row.get("incident_zip")),
        "community_board": clean_text(row.get("community_board")),
        "council_district": clean_text(row.get("council_district")),
        "police_precinct": clean_text(row.get("police_precinct")),
        "park_borough": clean_text(row.get("park_borough")),
        "park_facility_name": clean_text(row.get("park_facility_name")),
        "taxi_pick_up_location": clean_text(row.get("taxi_pick_up_location")),
        "bbl": clean_text(row.get("bbl")),
        "x_coordinate_state_plane": clean_text(row.get("x_coordinate_state_plane")),
        "y_coordinate_state_plane": clean_text(row.get("y_coordinate_state_plane")),
        "latitude": parse_float(row.get("latitude")),
        "longitude": parse_float(row.get("longitude")),
        "location": psycopg.types.json.Jsonb(row.get("location")) if row.get("location") is not None else None,
        "raw_json": psycopg.types.json.Jsonb(row),
    }

def fetch_page(offset: int, limit: int = PAGE_SIZE):
    params = {
        "$limit": limit,
        "$offset": offset,
        "$order": "created_date ASC",
    }
    resp = requests.get(API_URL, params=params, timeout=30)
    resp.raise_for_status()
    return resp.json()

def main(max_pages: int = MAX_PAGES):
    with psycopg.connect(**DB_CONFIG) as conn:
        with conn.cursor() as cur:
            total = 0
            for page_num in range(max_pages):
                offset = page_num * PAGE_SIZE
                print(f"Fetching page {page_num + 1}, offset={offset}...")
                rows = fetch_page(offset)

                if not rows:
                    print("No more rows returned.")
                    break

                cleaned_rows = []
                for row in rows:
                    normalized = normalize_record(row)
                    if normalized["unique_key"] is None:
                        continue
                    cleaned_rows.append(normalized)

                cur.executemany(INSERT_SQL, cleaned_rows)
                conn.commit()

                total += len(cleaned_rows)
                print(f"Inserted/updated {len(cleaned_rows)} rows.")

            print(f"Finished. Total inserted/updated: {total}")

if __name__ == "__main__":
    main()