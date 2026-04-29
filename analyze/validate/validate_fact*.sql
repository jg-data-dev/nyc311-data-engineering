/* DATA VALIDITY CHECKS
Add:
Freshness / timeliness (you haven’t touched yet)
 */
-- 1. Duplicate source records
SELECT
    'duplicate_unique_key' AS check_name,
    COUNT(*) AS issue_count
FROM (
    SELECT unique_key
    FROM fact_311_complaint
    GROUP BY unique_key
    HAVING COUNT(*) > 1
) t;


-- 2. Null created_at
SELECT
    'null_created_at' AS check_name,
    COUNT(*) AS issue_count
FROM fact_311_complaint
WHERE created_at IS NULL;


-- 3. Invalid timestamps (closed before created)
SELECT
    'invalid_time_order' AS check_name,
    COUNT(*) AS issue_count
FROM fact_311_complaint
WHERE closed_at < created_at;



-- 4. Missing closed_at (open or incomplete cases)
SELECT
    'missing_closed_at' AS check_name,
    COUNT(*) AS issue_count
FROM fact_311_complaint
WHERE closed_at IS NULL;
/*     check_name     | issue_count 
-------------------+-------------
 missing_closed_at |          17
(1 row)

 */

-- 5. Extreme duration (> 30 days = 720 hours)
SELECT
    'extreme_duration_gt_30d' AS check_name,
    COUNT(*) AS issue_count
FROM fact_311_complaint
WHERE closed_at IS NOT NULL
  AND created_at IS NOT NULL
  AND EXTRACT(EPOCH FROM (closed_at - created_at)) / 3600 > 720;

/*        check_name        | issue_count 
-------------------------+-------------
 extreme_duration_gt_30d |         135
(1 row)
 */

-- 6. Missing location dimension
SELECT
    'missing_location_fk' AS check_name,
    COUNT(*) AS issue_count
FROM fact_311_complaint f
LEFT JOIN dim_location l
  ON f.location_id = l.location_id
WHERE f.location_id IS NOT NULL
  AND l.location_id IS NULL;


-- 7. Missing complaint_type dimension
SELECT
    'missing_complaint_type_fk' AS check_name,
    COUNT(*) AS issue_count
FROM fact_311_complaint f
LEFT JOIN dim_complaint_type c
  ON f.complaint_type_id = c.complaint_type_id
WHERE f.complaint_type_id IS NOT NULL
  AND c.complaint_type_id IS NULL;

-- Check the distribution of date
SELECT
    DATE(created_at) AS date,
    COUNT(*) AS row_count,
    ROUND(
        COUNT(*)::numeric
        / SUM(COUNT(*)) OVER (),
        2
    ) AS pct_of_total
FROM fact_311_complaint
GROUP BY 1
ORDER BY row_count DESC;
/*     date    | row_count | pct_of_total 
------------+-----------+--------------
 2020-01-01 |      3000 |         1.00
(1 row)
 */

-- coverage
SELECT
    MIN(created_at),
    MAX(created_at),
    COUNT(DISTINCT DATE(created_at)) AS distinct_days,
    COUNT(*) AS total_rows
FROM fact_311_complaint;