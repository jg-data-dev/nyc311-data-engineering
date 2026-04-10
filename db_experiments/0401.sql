EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM stg_311_requests
WHERE unique_key = '45337895';

EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM stg_311_requests
WHERE complaint_type = 'Noise - Residential';

EXPLAIN (ANALYZE, BUFFERS)
SELECT count(*)
FROM stg_311_requests
WHERE created_date >= '2025-01-01'
  AND created_date < '2025-02-01';

EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM stg_311_requests
ORDER BY created_date DESC
LIMIT 100;