DROP TABLE IF EXISTS raw_311_requests;

CREATE TABLE raw_311_requests (
    unique_key text PRIMARY KEY,
    created_date timestamp,
    closed_date timestamp,
    resolution_action_updated_date timestamp,

    agency text,
    agency_name text,
    complaint_type text,
    descriptor text,
    descriptor_2 text,
    status text,
    resolution_description text,
    open_data_channel_type text,

    incident_address text,
    street_name text,
    cross_street_1 text,
    cross_street_2 text,
    intersection_street_1 text,
    intersection_street_2 text,
    landmark text,
    city text,
    borough text,
    incident_zip text,

    community_board text,
    council_district text,
    police_precinct text,

    park_borough text,
    park_facility_name text,
    taxi_pick_up_location text,

    bbl text,
    x_coordinate_state_plane text,
    y_coordinate_state_plane text,

    latitude double precision,
    longitude double precision,

    location jsonb,
    raw_json jsonb
);