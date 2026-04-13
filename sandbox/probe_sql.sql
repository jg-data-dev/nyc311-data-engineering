DROP TABLE IF EXISTS raw_311_requests_probe;

CREATE TABLE raw_311_requests_probe
(LIKE raw_311_requests INCLUDING ALL);

-- row count
SELECT COUNT(*) AS row_count
FROM raw_311_requests_probe;

-- date range
SELECT
    MIN(created_date) AS min_created_date,
    MAX(created_date) AS max_created_date,
    COUNT(DISTINCT DATE(created_date)) AS distinct_created_days
FROM raw_311_requests_probe;

-- status mix
SELECT
    status,
    COUNT(*) AS row_count
FROM raw_311_requests_probe
GROUP BY 1
ORDER BY 2 DESC;

-- complaint type mix
SELECT
    complaint_type,
    COUNT(*) AS row_count
FROM raw_311_requests_probe
GROUP BY 1
ORDER BY 2 DESC
LIMIT 20;

-- borough mix
SELECT
    borough,
    COUNT(*) AS row_count
FROM raw_311_requests_probe
GROUP BY 1
ORDER BY 2 DESC;

-- obvious timestamp problem
SELECT COUNT(*) AS invalid_time_order_count
FROM raw_311_requests_probe
WHERE created_date IS NOT NULL
  AND closed_date IS NOT NULL
  AND closed_date < created_date;

-- nulls in key fields
SELECT
    SUM((unique_key IS NULL)::int) AS null_unique_key_count,
    SUM((created_date IS NULL)::int) AS null_created_date_count,
    SUM((complaint_type IS NULL)::int) AS null_complaint_type_count,
    SUM((agency IS NULL)::int) AS null_agency_count,
    SUM((borough IS NULL)::int) AS null_borough_count
FROM raw_311_requests_probe;

-- sample rows
SELECT
    unique_key,
    created_date,
    closed_date,
    agency,
    complaint_type,
    borough,
    status
FROM raw_311_requests_probe
ORDER BY created_date
LIMIT 20;