-- =========================================================
-- VALIDATE STAR SCHEMA
-- =========================================================

-- -------------------------
-- Row count parity
-- -------------------------
SELECT 'stg_311_requests' AS table_name, COUNT(*) AS row_count
FROM stg_311_requests

UNION ALL

SELECT 'fact_311_complaint' AS table_name, COUNT(*) AS row_count
FROM fact_311_complaint

UNION ALL

SELECT 'fact_311_complaint_text' AS table_name, COUNT(*) AS row_count
FROM fact_311_complaint_text;

-- -------------------------
-- Unique key duplication check
-- -------------------------
SELECT
    unique_key,
    COUNT(*) AS cnt
FROM fact_311_complaint
GROUP BY unique_key
HAVING COUNT(*) > 1
ORDER BY cnt DESC, unique_key;

-- -------------------------
-- Missing foreign keys
-- -------------------------
SELECT 'missing_location_id' AS check_name, COUNT(*) AS missing_count
FROM fact_311_complaint
WHERE location_id IS NULL

UNION ALL

SELECT 'missing_agency_id' AS check_name, COUNT(*) AS missing_count
FROM fact_311_complaint
WHERE agency_id IS NULL

UNION ALL

SELECT 'missing_complaint_type_id' AS check_name, COUNT(*) AS missing_count
FROM fact_311_complaint
WHERE complaint_type_id IS NULL

UNION ALL

SELECT 'missing_status_id' AS check_name, COUNT(*) AS missing_count
FROM fact_311_complaint
WHERE status_id IS NULL

UNION ALL

SELECT 'missing_channel_id' AS check_name, COUNT(*) AS missing_count
FROM fact_311_complaint
WHERE channel_id IS NULL
  AND EXISTS (
      SELECT 1
      FROM stg_311_requests s
      WHERE s.unique_key = fact_311_complaint.unique_key
        AND s.open_data_channel_type IS NOT NULL
  );

-- -------------------------
-- Date key consistency
-- -------------------------
SELECT
    COUNT(*) AS bad_created_date_key_count
FROM fact_311_complaint
WHERE created_at IS NOT NULL
  AND created_date_id IS DISTINCT FROM TO_CHAR(created_at::date, 'YYYYMMDD')::INTEGER;

SELECT
    COUNT(*) AS bad_closed_date_key_count
FROM fact_311_complaint
WHERE closed_at IS NOT NULL
  AND closed_date_id IS DISTINCT FROM TO_CHAR(closed_at::date, 'YYYYMMDD')::INTEGER;

SELECT
    COUNT(*) AS bad_resolution_action_date_key_count
FROM fact_311_complaint
WHERE resolution_action_updated_at IS NOT NULL
  AND resolution_action_date_id IS DISTINCT FROM TO_CHAR(resolution_action_updated_at::date, 'YYYYMMDD')::INTEGER;

-- -------------------------
-- Fact/text join coverage
-- -------------------------
SELECT
    COUNT(*) AS fact_rows_missing_text_row
FROM fact_311_complaint f
LEFT JOIN fact_311_complaint_text t
    ON f.unique_key = t.unique_key
WHERE t.unique_key IS NULL;

SELECT COUNT(*) AS text_rows_missing_fact_row
FROM fact_311_complaint_text t
LEFT JOIN fact_311_complaint f
  ON t.unique_key = f.unique_key
WHERE f.unique_key IS NULL;

-- -------------------------
-- Dimension cardinalities
-- -------------------------
SELECT 'dim_date' AS dimension_name, COUNT(*) AS row_count FROM dim_date
UNION ALL
SELECT 'dim_location' AS dimension_name, COUNT(*) AS row_count FROM dim_location
UNION ALL
SELECT 'dim_agency' AS dimension_name, COUNT(*) AS row_count FROM dim_agency
UNION ALL
SELECT 'dim_complaint_type' AS dimension_name, COUNT(*) AS row_count FROM dim_complaint_type
UNION ALL
SELECT 'dim_status' AS dimension_name, COUNT(*) AS row_count FROM dim_status
UNION ALL
SELECT 'dim_channel' AS dimension_name, COUNT(*) AS row_count FROM dim_channel;

-- -------------------------
-- Sample analytic query
-- -------------------------
SELECT
    d.year,
    d.month,
    l.borough,
    ct.complaint_type,
    COUNT(*) AS complaint_cnt
FROM fact_311_complaint f
JOIN dim_date d
    ON f.created_date_id = d.date_id
JOIN dim_location l
    ON f.location_id = l.location_id
JOIN dim_complaint_type ct
    ON f.complaint_type_id = ct.complaint_type_id
GROUP BY
    d.year, d.month, l.borough, ct.complaint_type
ORDER BY complaint_cnt DESC
LIMIT 25;