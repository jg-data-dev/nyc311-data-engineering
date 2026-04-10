-- ad hoc queries, commonly used SQL
/*
SELECT 'missing_location_id' AS check_name, COUNT(*) AS missing_count
FROM fact_311_complaint
WHERE location_id IS NULL
nyc311-# ;
     check_name      | missing_count 
---------------------+---------------
 missing_location_id |          2926
(1 row)


 select count(*) from dim_location;
 count 
-------
  2460 */
(1 row)

select count(*) from stg_311_requests s 
LEFT JOIN dim_location l
    ON l.city IS NOT DISTINCT FROM s.city
   AND l.borough IS NOT DISTINCT FROM s.borough
   AND l.landmark IS NOT DISTINCT FROM s.landmark
   AND l.street_name IS NOT DISTINCT FROM s.street_name
   AND l.incident_zip IS NOT DISTINCT FROM s.incident_zip
   AND l.park_borough IS NOT DISTINCT FROM s.park_borough
   AND l.cross_street_1 IS NOT DISTINCT FROM s.cross_street_1
   AND l.cross_street_2 IS NOT DISTINCT FROM s.cross_street_2
   AND l.intersection_street_1 IS NOT DISTINCT FROM s.intersection_street_1
   AND l.intersection_street_2 IS NOT DISTINCT FROM s.intersection_street_2
   AND l.incident_address IS NOT DISTINCT FROM s.incident_address
   AND l.park_facility_name IS NOT DISTINCT FROM s.park_facility_name
   AND l.latitude IS NOT DISTINCT FROM s.latitude
   AND l.longitude IS NOT DISTINCT FROM s.longitude
   AND l.x_coordinate_state_plane IS NOT DISTINCT FROM s.x_coordinate_state_plane
   AND l.y_coordinate_state_plane IS NOT DISTINCT FROM s.y_coordinate_state_plane
   AND l.community_board IS NOT DISTINCT FROM s.community_board
   AND l.council_district IS NOT DISTINCT FROM s.council_district
WHERE l.location_id is null;

UNIQUE (
        city, borough, landmark, street_name, incident_zip, park_borough,
        cross_street_1, cross_street_2, intersection_street_1, intersection_street_2,
        incident_address, park_facility_name, latitude, longitude,
        x_coordinate_state_plane, y_coordinate_state_plane,
        community_board, council_district
    )
/* count 
-------
    74
(1 row)
 */
-- check schema
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'raw_311_requests';
ORDER BY ordinal_position;


-- check schema
\d 'stg_311_requests';

/*
 created_date                   | timestamp without time zone
 closed_date                    | timestamp without time zone
 resolution_action_updated_date | timestamp without time zone
 latitude                       | double precision
 longitude                      | double precision
 location                       | jsonb
 raw_json                       | jsonb
 resolution_description         | text
 open_data_channel_type         | text
 incident_address               | text
 street_name                    | text
 cross_street_1                 | text
 cross_street_2                 | text
 intersection_street_1          | text
 unique_key                     | text
 landmark                       | text
 city                           | text
 borough                        | text
 incident_zip                   | text
 community_board                | text
 council_district               | text
 police_precinct                | text
 park_borough                   | text
 park_facility_name             | text
 taxi_pick_up_location          | text
 bbl                            | text
 x_coordinate_state_plane       | text
 y_coordinate_state_plane       | text
 intersection_street_2          | text
 agency                         | text
 agency_name                    | text
 complaint_type                 | text
 descriptor                     | text
 descriptor_2                   | text
 status                         | text
(35 rows)
*/

-- sanity check ingested raw data
SELECT
  'resolution_action_updated_date' AS column,
  COUNT(*) FILTER (WHERE resolution_action_updated_date IS NULL OR resolution_action_updated_date = '') AS empty_count,
  COUNT(*) AS total
FROM raw_311_requests
UNION ALL
SELECT
  'address_type',
  COUNT(*) FILTER (WHERE address_type IS NULL OR address_type = ''),
  COUNT(*)
FROM raw_311_requests;


/* check if police_precinct is 1:1 with location
which is ambiguous
*/

SELECT
    ROUND(latitude::numeric, 5) AS lat_r,
    ROUND(longitude::numeric, 5) AS lon_r,
    COUNT(*) AS complaint_rows,
    COUNT(DISTINCT police_precinct) AS precinct_count
FROM stg_311_requests
WHERE latitude IS NOT NULL
  AND longitude IS NOT NULL
  AND police_precinct IS NOT NULL
  AND police_precinct <> ''
GROUP BY ROUND(latitude::numeric, 5), ROUND(longitude::numeric, 5)
HAVING COUNT(*) > 1
   AND COUNT(DISTINCT police_precinct) > 1
ORDER BY precinct_count DESC, complaint_rows DESC;


-- Brooklyn investigation

SELECT
    l.borough,
    c.complaint_type,
    COUNT(*) AS num_requests,
    AVG(EXTRACT(EPOCH FROM (f.closed_at - f.created_at)) / 3600) AS avg_resolution_hours
FROM fact_311_complaint f
JOIN dim_location l
    ON f.location_id = l.location_id
JOIN dim_complaint_type c
    ON f.complaint_type_id = c.complaint_type_id
WHERE
    f.closed_at IS NOT NULL
    AND f.created_at IS NOT NULL
    AND f.closed_at >= f.created_at
GROUP BY
    l.borough,
    c.complaint_type
ORDER BY
    l.borough,
    avg_resolution_hours DESC;

SELECT
    l.borough,
    COUNT(*) AS num_requests,
    AVG(EXTRACT(EPOCH FROM (f.closed_at - f.created_at)) / 3600) AS avg_resolution_hours
FROM fact_311_complaint f
JOIN dim_location l
    ON f.location_id = l.location_id
WHERE
    f.closed_at IS NOT NULL
    AND f.created_at IS NOT NULL
    AND f.closed_at >= f.created_at
GROUP BY
    l.borough
ORDER BY
  avg_resolution_hours,
    l.borough DESC;


select l.borough, count(distinct police_precinct) as cnt from fact_311_complaint f
  join dim_location l
    ON f.location_id = l.location_id
  group by l.borough
  order by cnt desc;

select l.borough, f.police_precinct from fact_311_complaint f
  join dim_location l
    ON f.location_id = l.location_id
  group by l.borough, f.police_precinct
  order by borough desc;


SELECT
    l.borough,
    COUNT(*) AS noise_complaints_count
FROM fact_311_complaint f
JOIN dim_location l
    ON f.location_id = l.location_id
JOIN dim_complaint_type c
    ON f.complaint_type_id = c.complaint_type_id
WHERE
    c.complaint_type ILIKE 'Noise%'   -- matches all noise categories
GROUP BY
    l.borough
ORDER BY
    noise_complaints_count DESC;



SELECT 
  l.borough,
  c.complaint_type,
  AVG(resolution_hours) as avg_time,
  COUNT(*) as cnt
FROM fact_311_complaint f
JOIN dim_location l ON f.location_id = l.location_id
JOIN dim_complaint_type c ON f.complaint_type_id = c.complaint_type_id
GROUP BY borough, complaint_type
ORDER BY borough, avg_time DESC;



-- Today
SELECT
COALESCE(NULLIF(TRIM(l.borough), ''), 'UNSPECIFIED') AS borough,
c.complaint_type,
ROUND(AVG(EXTRACT(EPOCH FROM (f.closed_at - f.created_at)) / 3600.0
  )::numeric, 2) AS avg_resolution_hours,
ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (
  ORDER BY 
  EXTRACT(EPOCH FROM (f.closed_at - f.created_at)) / 3600.0
  )::numeric, 2)
AS median_resolution_hours,
ROUND(PERCENTILE_CONT(0.95) WITHIN GROUP (
  ORDER BY 
  EXTRACT(EPOCH FROM (f.closed_at - f.created_at)) / 3600.0
  )::numeric, 2)
AS ninety_resolution_hours
FROM fact_311_complaint f
    JOIN dim_location l
      ON f.location_id = l.location_id
    JOIN dim_complaint_type c
      ON f.complaint_type_id = c.complaint_type_id
    WHERE f.created_at IS NOT NULL
      AND f.closed_at IS NOT NULL
      AND f.closed_at >= f.created_at
GROUP BY 1, 2
ORDER BY avg_resolution_hours DESC;

