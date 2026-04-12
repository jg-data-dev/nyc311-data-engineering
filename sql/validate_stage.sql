-- validate_stage.sql

-- 1) row count: raw vs stage
SELECT 'row_count_raw' AS check_name, COUNT(*)::text AS result
FROM raw_311_requests

UNION ALL

SELECT 'row_count_stage' AS check_name, COUNT(*)::text AS result
FROM stg_311_requests;


-- 2) duplicate unique_key in stage
SELECT
  'duplicate_unique_key_count' AS check_name,
  COUNT(*)::text AS result
FROM (
  SELECT unique_key
  FROM stg_311_requests
  GROUP BY unique_key
  HAVING COUNT(*) > 1
) t;


-- 3) null / blank checks on important columns
SELECT
  'null_unique_key' AS check_name,
  COUNT(*)::text AS result
FROM stg_311_requests
WHERE unique_key IS NULL

UNION ALL

SELECT
  'null_created_date',
  COUNT(*)::text
FROM stg_311_requests
WHERE created_date IS NULL

UNION ALL

SELECT
  'null_complaint_type',
  COUNT(*)::text
FROM stg_311_requests
WHERE complaint_type IS NULL

UNION ALL

SELECT
  'null_status',
  COUNT(*)::text
FROM stg_311_requests
WHERE status IS NULL

UNION ALL

SELECT
  'null_borough',
  COUNT(*)::text
FROM stg_311_requests
WHERE borough IS NULL;


-- 4) invalid close-before-create rows
SELECT
  'invalid_close_before_create' AS check_name,
  COUNT(*)::text AS result
FROM stg_311_requests
WHERE invalid_close_before_create = true;


-- 5) impossible raw timestamp ordering without flag
SELECT
  'close_before_create_but_flag_false' AS check_name,
  COUNT(*)::text AS result
FROM stg_311_requests
WHERE closed_date IS NOT NULL
  AND created_date IS NOT NULL
  AND closed_date < created_date
  AND invalid_close_before_create = false;


-- 6) valid_lat_long flag consistency
SELECT
  'lat_long_present_but_flag_false' AS check_name,
  COUNT(*)::text AS result
FROM stg_311_requests
WHERE latitude IS NOT NULL
  AND longitude IS NOT NULL
  AND latitude BETWEEN -90 AND 90
  AND longitude BETWEEN -180 AND 180
  AND valid_lat_long = false

UNION ALL

SELECT
  'lat_long_invalid_but_flag_true',
  COUNT(*)::text
FROM stg_311_requests
WHERE (
    latitude IS NULL
    OR longitude IS NULL
    OR latitude NOT BETWEEN -90 AND 90
    OR longitude NOT BETWEEN -180 AND 180
)
AND valid_lat_long = true;


-- 7) uppercase normalization spot checks
SELECT
  'agency_not_uppercase' AS check_name,
  COUNT(*)::text AS result
FROM stg_311_requests
WHERE agency IS NOT NULL
  AND agency <> UPPER(agency)

UNION ALL

SELECT
  'borough_not_uppercase',
  COUNT(*)::text
FROM stg_311_requests
WHERE borough IS NOT NULL
  AND borough <> UPPER(borough)

UNION ALL

SELECT
  'complaint_type_not_uppercase',
  COUNT(*)::text
FROM stg_311_requests
WHERE complaint_type IS NOT NULL
  AND complaint_type <> UPPER(complaint_type);


-- 8) blank strings that should have been converted to NULL
SELECT
  'blank_agency_remaining' AS check_name,
  COUNT(*)::text AS result
FROM stg_311_requests
WHERE agency = ''

UNION ALL

SELECT
  'blank_borough_remaining',
  COUNT(*)::text
FROM stg_311_requests
WHERE borough = ''

UNION ALL

SELECT
  'blank_complaint_type_remaining',
  COUNT(*)::text
FROM stg_311_requests
WHERE complaint_type = '';


-- 9) useful profiling summaries
SELECT
  invalid_close_before_create,
  COUNT(*) AS row_count
FROM stg_311_requests
GROUP BY invalid_close_before_create
ORDER BY invalid_close_before_create;

SELECT
  valid_lat_long,
  COUNT(*) AS row_count
FROM stg_311_requests
GROUP BY valid_lat_long
ORDER BY valid_lat_long;


-- 10) inspect suspicious rows if any exist
SELECT
  unique_key,
  complaint_type,
  status,
  created_date,
  closed_date
FROM stg_311_requests
WHERE invalid_close_before_create = true
ORDER BY created_date
LIMIT 3;