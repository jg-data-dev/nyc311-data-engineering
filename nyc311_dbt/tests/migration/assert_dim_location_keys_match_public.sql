-- tests/migration/assert_dim_location_keys_match_public.sql

WITH public_keys AS (
    SELECT
        city,
        borough,
        landmark,
        street_name,
        incident_zip,
        park_borough,
        cross_street_1,
        cross_street_2,
        intersection_street_1,
        intersection_street_2,
        incident_address,
        park_facility_name,
        latitude,
        longitude,
        x_coordinate_state_plane,
        y_coordinate_state_plane,
        community_board,
        council_district
    FROM public.dim_location
),

dbt_keys AS (
    SELECT
        city,
        borough,
        landmark,
        street_name,
        incident_zip,
        park_borough,
        cross_street_1,
        cross_street_2,
        intersection_street_1,
        intersection_street_2,
        incident_address,
        park_facility_name,
        latitude,
        longitude,
        x_coordinate_state_plane,
        y_coordinate_state_plane,
        community_board,
        council_district
    FROM {{ ref('dim_location') }}
),

missing_from_dbt AS (
    SELECT
        'missing_from_dbt' AS issue,
        city,
        borough,
        landmark,
        street_name,
        incident_zip,
        park_borough,
        cross_street_1,
        cross_street_2,
        intersection_street_1,
        intersection_street_2,
        incident_address,
        park_facility_name,
        latitude,
        longitude,
        x_coordinate_state_plane,
        y_coordinate_state_plane,
        community_board,
        council_district
    FROM public_keys

    EXCEPT

    SELECT
        'missing_from_dbt' AS issue,
        city,
        borough,
        landmark,
        street_name,
        incident_zip,
        park_borough,
        cross_street_1,
        cross_street_2,
        intersection_street_1,
        intersection_street_2,
        incident_address,
        park_facility_name,
        latitude,
        longitude,
        x_coordinate_state_plane,
        y_coordinate_state_plane,
        community_board,
        council_district
    FROM dbt_keys
),

extra_in_dbt AS (
    SELECT
        'extra_in_dbt' AS issue,
        city,
        borough,
        landmark,
        street_name,
        incident_zip,
        park_borough,
        cross_street_1,
        cross_street_2,
        intersection_street_1,
        intersection_street_2,
        incident_address,
        park_facility_name,
        latitude,
        longitude,
        x_coordinate_state_plane,
        y_coordinate_state_plane,
        community_board,
        council_district
    FROM dbt_keys

    EXCEPT

    SELECT
        'extra_in_dbt' AS issue,
        city,
        borough,
        landmark,
        street_name,
        incident_zip,
        park_borough,
        cross_street_1,
        cross_street_2,
        intersection_street_1,
        intersection_street_2,
        incident_address,
        park_facility_name,
        latitude,
        longitude,
        x_coordinate_state_plane,
        y_coordinate_state_plane,
        community_board,
        council_district
    FROM public_keys
)

SELECT * FROM missing_from_dbt
UNION ALL
SELECT * FROM extra_in_dbt
