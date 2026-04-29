/* analyze/tests/test_daily_metrics.sql

Purpose:
Reusable tests for fct_daily_metrics after ingest/stage/mart refresh.

How to read:
- HARD tests: should return 0 rows. Any returned rows mean failure.
- WARN tests: may return rows. They surface patterns worth monitoring.

Run:
psql -d nyc311 -f analyze/tests/test_daily_metrics.sql
*/


/* =========================================================
   HARD TESTS
   ========================================================= */


/* HARD 1: one row per metric_date */
SELECT
    metric_date,
    COUNT(*) AS row_count
FROM fct_daily_metrics
GROUP BY metric_date
HAVING COUNT(*) > 1;


/* HARD 2: daily_net_case_flow matches definition */
SELECT
    metric_date,
    created_count,
    closed_count,
    daily_net_case_flow,
    (created_count - closed_count) AS expected_daily_net_case_flow
FROM fct_daily_metrics
WHERE daily_net_case_flow != (created_count - closed_count);


/* HARD 3: time buckets sum to created_count */
SELECT
    metric_date,
    created_count,
    created_morning_count,
    created_afternoon_count,
    created_evening_count,
    created_overnight_count,
    (
        created_morning_count
        + created_afternoon_count
        + created_evening_count
        + created_overnight_count
    ) AS recomputed_created_count
FROM fct_daily_metrics
WHERE created_count != (
    created_morning_count
    + created_afternoon_count
    + created_evening_count
    + created_overnight_count
);


/* HARD 4: counts should not be negative */
SELECT
    metric_date,
    created_count,
    closed_count,
    daily_net_case_flow,
    invalid_time_order_count,
    missing_critical_fields_count,
    missing_location_id_count,
    missing_complaint_type_id_count,
    missing_agency_id_count,
    created_morning_count,
    created_afternoon_count,
    created_evening_count,
    created_overnight_count
FROM fct_daily_metrics
WHERE created_count < 0
   OR closed_count < 0
   OR daily_net_case_flow < 0
   OR invalid_time_order_count < 0
   OR missing_critical_fields_count < 0
   OR missing_location_id_count < 0
   OR missing_complaint_type_id_count < 0
   OR missing_agency_id_count < 0
   OR created_morning_count < 0
   OR created_afternoon_count < 0
   OR created_evening_count < 0
   OR created_overnight_count < 0;


/* HARD 5: percentile ordering must be sane */
SELECT
    metric_date,
    avg_resolution_hours,
    median_resolution_hours,
    p90_resolution_hours,
    p95_resolution_hours
FROM fct_daily_metrics
WHERE median_resolution_hours > p90_resolution_hours
   OR p90_resolution_hours > p95_resolution_hours;


/* HARD 6: missing counts cannot exceed created_count */
SELECT
    metric_date,
    created_count,
    invalid_time_order_count,
    missing_critical_fields_count,
    missing_location_id_count,
    missing_complaint_type_id_count,
    missing_agency_id_count
FROM fct_daily_metrics
WHERE invalid_time_order_count > created_count
   OR missing_critical_fields_count > created_count
   OR missing_location_id_count > created_count
   OR missing_complaint_type_id_count > created_count
   OR missing_agency_id_count > created_count;


/* HARD 7: no duplicate complaint keys in fact table */
SELECT
    unique_key,
    COUNT(*) AS row_count
FROM fact_311_complaint
GROUP BY unique_key
HAVING COUNT(*) > 1;


/* =========================================================
   WARN TESTS
   ========================================================= */


/* WARN 1: avg vs median gap (large gap suggests skew / long tail) */
SELECT
    metric_date,
    avg_resolution_hours,
    median_resolution_hours,
    ROUND(
        avg_resolution_hours - median_resolution_hours,
        2
    ) AS avg_median_gap
FROM fct_daily_metrics
ORDER BY avg_median_gap DESC;


/* WARN 2: p95 vs p90 gap (large jump suggests extreme tail) */
SELECT
    metric_date,
    p90_resolution_hours,
    p95_resolution_hours,
    ROUND(
        p95_resolution_hours - p90_resolution_hours,
        2
    ) AS p95_p90_gap
FROM fct_daily_metrics
ORDER BY p95_p90_gap DESC;


/* WARN 3: invalid time percentage by day */
SELECT
    metric_date,
    created_count,
    invalid_time_order_count,
    ROUND(
        (invalid_time_order_count * 100.0) / NULLIF(created_count, 0),
        2
    ) AS pct_invalid_time
FROM fct_daily_metrics
ORDER BY pct_invalid_time DESC, metric_date;


/* WARN 4: instant closures by created day */
SELECT
    DATE(created_at) AS metric_date,
    COUNT(*) AS instant_close_count
FROM fact_311_complaint
WHERE created_at IS NOT NULL
  AND closed_at = created_at
GROUP BY 1
ORDER BY instant_close_count DESC, metric_date;


/* WARN 5: same-day closures by created day */
SELECT
    DATE(created_at) AS metric_date,
    COUNT(*) AS same_day_close_count
FROM fact_311_complaint
WHERE created_at IS NOT NULL
  AND closed_at IS NOT NULL
  AND closed_at > created_at
  AND DATE(closed_at) = DATE(created_at)
GROUP BY 1
ORDER BY same_day_close_count DESC, metric_date;


/* WARN 6: daily close rate */
SELECT
    metric_date,
    created_count,
    closed_count,
    ROUND(
        (closed_count * 100.0) / NULLIF(created_count, 0),
        2
    ) AS pct_close_rate
FROM fct_daily_metrics
ORDER BY pct_close_rate ASC, metric_date;


/* WARN 7: distribution of created counts by day */
SELECT
    metric_date,
    created_count,
    ROUND(
        (created_count * 100.0) / SUM(created_count) OVER (),
        2
    ) AS pct_of_total_created
FROM fct_daily_metrics
ORDER BY pct_of_total_created DESC, metric_date;


/* WARN 8: created time-bucket percentages by day */
SELECT
    metric_date,
    ROUND(
        (created_morning_count * 100.0) / NULLIF(created_count, 0),
        2
    ) AS pct_morning,
    ROUND(
        (created_afternoon_count * 100.0) / NULLIF(created_count, 0),
        2
    ) AS pct_afternoon,
    ROUND(
        (created_evening_count * 100.0) / NULLIF(created_count, 0),
        2
    ) AS pct_evening,
    ROUND(
        (created_overnight_count * 100.0) / NULLIF(created_count, 0),
        2
    ) AS pct_overnight
FROM fct_daily_metrics
ORDER BY metric_date;