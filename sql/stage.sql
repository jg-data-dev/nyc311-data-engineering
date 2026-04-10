/*
Clean / standardize data into staging tables
renaming confusing columns
parsing timestamps
normalizing text values
dropping obvious junk
standardizing nulls / blanks
selecting the subset of fields you care about
*/
DROP TABLE IF EXISTS stg_311_requests;

CREATE TABLE stg_311_requests AS
SELECT
    unique_key,

    created_date,
    closed_date,
    resolution_action_updated_date,

    NULLIF(BTRIM(UPPER(agency)), '') AS agency,
    NULLIF(BTRIM(UPPER(agency_name)), '') AS agency_name,
    NULLIF(BTRIM(UPPER(complaint_type)), '') AS complaint_type,
    NULLIF(BTRIM(UPPER(descriptor)), '') AS descriptor,
    NULLIF(BTRIM(UPPER(descriptor_2)), '') AS descriptor_2,
    NULLIF(BTRIM(UPPER(status)), '') AS status,
    NULLIF(BTRIM(resolution_description), '') AS resolution_description,
    NULLIF(BTRIM(UPPER(open_data_channel_type)), '') AS open_data_channel_type,

    NULLIF(BTRIM(UPPER(incident_address)), '') AS incident_address,
    NULLIF(BTRIM(UPPER(street_name)), '') AS street_name,
    NULLIF(BTRIM(UPPER(cross_street_1)), '') AS cross_street_1,
    NULLIF(BTRIM(UPPER(cross_street_2)), '') AS cross_street_2,
    NULLIF(BTRIM(UPPER(intersection_street_1)), '') AS intersection_street_1,
    NULLIF(BTRIM(UPPER(intersection_street_2)), '') AS intersection_street_2,
    NULLIF(BTRIM(UPPER(landmark)), '') AS landmark,
    NULLIF(BTRIM(UPPER(city)), '') AS city,
    NULLIF(BTRIM(UPPER(borough)), '') AS borough,
    NULLIF(BTRIM(incident_zip), '') AS incident_zip,

    NULLIF(BTRIM(UPPER(community_board)), '') AS community_board,
    NULLIF(BTRIM(council_district), '') AS council_district,
    NULLIF(BTRIM(UPPER(police_precinct)), '') AS police_precinct,

    NULLIF(BTRIM(UPPER(park_borough)), '') AS park_borough,
    NULLIF(BTRIM(UPPER(park_facility_name)), '') AS park_facility_name,
    NULLIF(BTRIM(taxi_pick_up_location), '') AS taxi_pick_up_location,

    NULLIF(BTRIM(bbl), '') AS bbl,
    NULLIF(BTRIM(x_coordinate_state_plane), '') AS x_coordinate_state_plane,
    NULLIF(BTRIM(y_coordinate_state_plane), '') AS y_coordinate_state_plane,

    -- bug fix
    CAST(latitude AS NUMERIC) AS latitude,
    CAST(longitude AS NUMERIC) AS longitude,
    location,

    -- keep raw json for debugging / fallback, may later remove for performance
    raw_json,

    created_date::date AS created_day,
    closed_date::date AS closed_day,

    CASE
        WHEN closed_date IS NOT NULL AND closed_date < created_date THEN true
        ELSE false
    END AS invalid_close_before_create,

    CASE
        WHEN latitude IS NOT NULL
         AND longitude IS NOT NULL
         AND latitude BETWEEN -90 AND 90
         AND longitude BETWEEN -180 AND 180
        THEN true
        ELSE false
    END AS valid_lat_long

FROM raw_311_requests;