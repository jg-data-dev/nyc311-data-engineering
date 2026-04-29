-- psql -d nyc311 -f sql/validate_stage.sql

\echo '== Stage null & unique key check =='
\set table_name 'stg_311_requests'
\i sql/validate_common.sql


\echo '== Stage row count vs raw =='
SELECT 'row_count_raw' AS check_name, COUNT(*) AS result
FROM raw_311_requests

UNION ALL

SELECT 'row_count_stage' AS check_name, COUNT(*) AS result
FROM stg_311_requests;

SELECT
  'stage_vs_raw' AS check_name,
  COUNT(*) - (SELECT COUNT(*) FROM raw_311_requests) AS diff
FROM stg_311_requests;


\echo '== Stage logical date checks =='
SELECT
  'invalid_close_before_create' AS check_name,
  COUNT(*) AS issue_count
FROM stg_311_requests
WHERE invalid_close_before_create = true;

SELECT
  'close_before_create_but_flag_false' AS check_name,
  COUNT(*) AS issue_count
FROM stg_311_requests
WHERE closed_date IS NOT NULL
  AND created_date IS NOT NULL
  AND closed_date < created_date
  AND invalid_close_before_create = false;

SELECT
  'flag_true_but_close_not_before_create' AS check_name,
  COUNT(*) AS issue_count
FROM stg_311_requests
WHERE invalid_close_before_create = true
  AND NOT (
    closed_date IS NOT NULL
    AND created_date IS NOT NULL
    AND closed_date < created_date
  );


\echo '== Stage lat/long logic checks =='
SELECT
  'lat_long_present_but_flag_false' AS check_name,
  COUNT(*) AS issue_count
FROM stg_311_requests
WHERE latitude IS NOT NULL
  AND longitude IS NOT NULL
  AND latitude BETWEEN -90 AND 90
  AND longitude BETWEEN -180 AND 180
  AND valid_lat_long = false

UNION ALL

SELECT
  'lat_long_invalid_but_flag_true',
  COUNT(*) AS issue_count
FROM stg_311_requests
WHERE (
    latitude IS NULL
    OR longitude IS NULL
    OR latitude NOT BETWEEN -90 AND 90
    OR longitude NOT BETWEEN -180 AND 180
)
AND valid_lat_long = true;


\echo '== Stage normalization checks =='
SELECT
  'agency_not_uppercase' AS check_name,
  COUNT(*) AS issue_count
FROM stg_311_requests
WHERE agency IS NOT NULL
  AND agency <> UPPER(agency)

UNION ALL

SELECT
  'borough_not_uppercase',
  COUNT(*) AS issue_count
FROM stg_311_requests
WHERE borough IS NOT NULL
  AND borough <> UPPER(borough)

UNION ALL

SELECT
  'complaint_type_not_uppercase',
  COUNT(*) AS issue_count
FROM stg_311_requests
WHERE complaint_type IS NOT NULL
  AND complaint_type <> UPPER(complaint_type);


\echo '== Stage blank-string checks =='
SELECT
  'blank_agency_remaining' AS check_name,
  COUNT(*) AS issue_count
FROM stg_311_requests
WHERE agency = ''

UNION ALL

SELECT
  'blank_borough_remaining',
  COUNT(*) AS issue_count
FROM stg_311_requests
WHERE borough = ''

UNION ALL

SELECT
  'blank_complaint_type_remaining',
  COUNT(*) AS issue_count
FROM stg_311_requests
WHERE complaint_type = '';


\echo '== Stage profiling summaries =='
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


\echo '== Suspicious close-before-create rows =='
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