-- validate_coommon.sql
-- Usage:
-- psql -d nyc311 -v table_name=raw_311_requests -f sql/validate_common.sql
-- psql -d nyc311 -v table_name=stg_311_requests -f sql/validate_common.sql

\echo 'Running checks on table:' :table_name

WITH base AS (
  SELECT COUNT(*)::numeric AS total_rows
  FROM :table_name
),

null_counts AS (

  -- ===== critical fields (ordered) =====
  SELECT 'unique_key' AS column_name, COUNT(*)::numeric AS null_count FROM :table_name WHERE unique_key IS NULL
  UNION ALL
  SELECT 'created_date', COUNT(*) FROM :table_name WHERE created_date IS NULL
  UNION ALL
  SELECT 'closed_date', COUNT(*) FROM :table_name WHERE closed_date IS NULL
  UNION ALL
  SELECT 'complaint_type', COUNT(*) FROM :table_name WHERE complaint_type IS NULL
  UNION ALL
  SELECT 'borough', COUNT(*) FROM :table_name WHERE borough IS NULL
  UNION ALL
  SELECT 'agency', COUNT(*) FROM :table_name WHERE agency IS NULL
  UNION ALL
  SELECT 'status', COUNT(*) FROM :table_name WHERE status IS NULL

  -- ===== rest (alphabetical) =====
  UNION ALL
  SELECT 'agency_name', COUNT(*) FROM :table_name WHERE agency_name IS NULL
  UNION ALL
  SELECT 'bbl', COUNT(*) FROM :table_name WHERE bbl IS NULL
  UNION ALL
  SELECT 'city', COUNT(*) FROM :table_name WHERE city IS NULL
  UNION ALL
  SELECT 'community_board', COUNT(*) FROM :table_name WHERE community_board IS NULL
  UNION ALL
  SELECT 'council_district', COUNT(*) FROM :table_name WHERE council_district IS NULL
  UNION ALL
  SELECT 'cross_street_1', COUNT(*) FROM :table_name WHERE cross_street_1 IS NULL
  UNION ALL
  SELECT 'cross_street_2', COUNT(*) FROM :table_name WHERE cross_street_2 IS NULL
  UNION ALL
  SELECT 'descriptor', COUNT(*) FROM :table_name WHERE descriptor IS NULL
  UNION ALL
  SELECT 'descriptor_2', COUNT(*) FROM :table_name WHERE descriptor_2 IS NULL
  UNION ALL
  SELECT 'incident_address', COUNT(*) FROM :table_name WHERE incident_address IS NULL
  UNION ALL
  SELECT 'incident_zip', COUNT(*) FROM :table_name WHERE incident_zip IS NULL
  UNION ALL
  SELECT 'intersection_street_1', COUNT(*) FROM :table_name WHERE intersection_street_1 IS NULL
  UNION ALL
  SELECT 'intersection_street_2', COUNT(*) FROM :table_name WHERE intersection_street_2 IS NULL
  UNION ALL
  SELECT 'landmark', COUNT(*) FROM :table_name WHERE landmark IS NULL
  UNION ALL
  SELECT 'latitude', COUNT(*) FROM :table_name WHERE latitude IS NULL
  UNION ALL
  SELECT 'longitude', COUNT(*) FROM :table_name WHERE longitude IS NULL
  UNION ALL
  SELECT 'open_data_channel_type', COUNT(*) FROM :table_name WHERE open_data_channel_type IS NULL
  UNION ALL
  SELECT 'park_borough', COUNT(*) FROM :table_name WHERE park_borough IS NULL
  UNION ALL
  SELECT 'park_facility_name', COUNT(*) FROM :table_name WHERE park_facility_name IS NULL
  UNION ALL
  SELECT 'police_precinct', COUNT(*) FROM :table_name WHERE police_precinct IS NULL
  UNION ALL
  SELECT 'resolution_action_updated_date', COUNT(*) FROM :table_name WHERE resolution_action_updated_date IS NULL
  UNION ALL
  SELECT 'resolution_description', COUNT(*) FROM :table_name WHERE resolution_description IS NULL
  UNION ALL
  SELECT 'street_name', COUNT(*) FROM :table_name WHERE street_name IS NULL
  UNION ALL
  SELECT 'taxi_pick_up_location', COUNT(*) FROM :table_name WHERE taxi_pick_up_location IS NULL
  UNION ALL
  SELECT 'x_coordinate_state_plane', COUNT(*) FROM :table_name WHERE x_coordinate_state_plane IS NULL
  UNION ALL
  SELECT 'y_coordinate_state_plane', COUNT(*) FROM :table_name WHERE y_coordinate_state_plane IS NULL
)

SELECT
  n.column_name,
  n.null_count::bigint,
  ROUND((n.null_count / b.total_rows) * 100, 2) AS null_pct
FROM null_counts n
CROSS JOIN base b

ORDER BY
  CASE n.column_name
    WHEN 'unique_key' THEN 1
    WHEN 'created_date' THEN 2
    WHEN 'closed_date' THEN 3
    WHEN 'complaint_type' THEN 4
    WHEN 'borough' THEN 5
    WHEN 'agency' THEN 6
    WHEN 'status' THEN 7
    ELSE 100
  END,
  n.column_name;


SELECT
  :'table_name' AS table_name,
  'duplicate_unique_key_count' AS check_name,
  COUNT(*) AS issue_count
FROM (
  SELECT unique_key
  FROM :table_name
  GROUP BY unique_key
  HAVING COUNT(*) > 1
) t;

SELECT
  :'table_name' AS table_name,
  'null_unique_key_count' AS check_name,
  COUNT(*) AS issue_count
FROM :table_name
WHERE unique_key IS NULL;