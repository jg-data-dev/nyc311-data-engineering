DROP TABLE IF EXISTS fct_monthly_metrics;

CREATE TABLE fct_monthly_metrics AS
SELECT
    metric_month AS month_start,

    COUNT(*) AS created_count,

    COUNT(*) FILTER (
        WHERE closed_at IS NOT NULL
          AND created_at IS NOT NULL
          AND is_invalid_time_order = 0
    ) AS closed_count,

    COUNT(*) - COUNT(*) FILTER (
        WHERE closed_at IS NOT NULL
          AND created_at IS NOT NULL
          AND is_invalid_time_order = 0
    ) AS net_case_flow,

    ROUND(AVG(resolution_hours) FILTER (
        WHERE closed_at IS NOT NULL
          AND created_at IS NOT NULL
          AND is_invalid_time_order = 0
    )::numeric, 2) AS avg_resolution_hours,

    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY resolution_hours) FILTER (
        WHERE closed_at IS NOT NULL
          AND created_at IS NOT NULL
          AND is_invalid_time_order = 0
    )::numeric, 2) AS median_resolution_hours,

    ROUND(PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY resolution_hours) FILTER (
        WHERE closed_at IS NOT NULL
          AND created_at IS NOT NULL
          AND is_invalid_time_order = 0
    )::numeric, 2) AS p90_resolution_hours,

    ROUND(PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY resolution_hours) FILTER (
        WHERE closed_at IS NOT NULL
          AND created_at IS NOT NULL
          AND is_invalid_time_order = 0
    )::numeric, 2) AS p95_resolution_hours,

    SUM(is_invalid_time_order) AS invalid_time_order_count,
    SUM(is_missing_critical_fields) AS missing_critical_fields_count,
    SUM(is_missing_location_id) AS missing_location_id_count,
    SUM(is_missing_complaint_type_id) AS missing_complaint_type_id_count,
    SUM(is_missing_agency_id) AS missing_agency_id_count,
    SUM(is_missing_status_id) AS missing_status_id_count,
    SUM(is_closed_at_status_mismatch) AS closed_at_status_mismatch_count

FROM int_complaints_flagged
WHERE metric_month IS NOT NULL
GROUP BY metric_month
ORDER BY metric_month;