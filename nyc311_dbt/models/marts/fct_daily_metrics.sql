-- models/marts/fct_daily_metrics.sql

WITH created_by_day AS (
    SELECT
        created_at::date AS metric_date,

        COUNT(*) AS created_count,

        COUNT(*) FILTER (
            WHERE EXTRACT(HOUR FROM created_at) BETWEEN 6 AND 11
        ) AS created_morning_count,

        COUNT(*) FILTER (
            WHERE EXTRACT(HOUR FROM created_at) BETWEEN 12 AND 17
        ) AS created_afternoon_count,

        COUNT(*) FILTER (
            WHERE EXTRACT(HOUR FROM created_at) BETWEEN 18 AND 23
        ) AS created_evening_count,

        COUNT(*) FILTER (
            WHERE EXTRACT(HOUR FROM created_at) BETWEEN 0 AND 5
        ) AS created_overnight_count,

        COUNT(*) FILTER (
            WHERE is_invalid_time_order = 1
        ) AS invalid_time_order_count,

        COUNT(*) FILTER (
            WHERE is_missing_critical_fields = 1
        ) AS missing_critical_fields_count,

        COUNT(*) FILTER (
            WHERE is_missing_location_id = 1
        ) AS missing_location_id_count,

        COUNT(*) FILTER (
            WHERE is_missing_complaint_type_id = 1
        ) AS missing_complaint_type_id_count,

        COUNT(*) FILTER (
            WHERE is_missing_agency_id = 1
        ) AS missing_agency_id_count,

        COUNT(*) FILTER (
            WHERE is_missing_status_id = 1
        ) AS missing_status_id_count,

        COUNT(*) FILTER (
            WHERE is_closed_at_status_mismatch = 1
        ) AS closed_at_status_mismatch_count

    FROM {{ ref('int_complaints_flagged') }}
    WHERE created_at IS NOT NULL
    GROUP BY created_at::date
),

closed_by_day AS (
    SELECT
        closed_at::date AS metric_date,

        COUNT(*) AS closed_count,

        AVG(resolution_hours) AS avg_resolution_hours,

        PERCENTILE_CONT(0.5) WITHIN GROUP (
            ORDER BY resolution_hours
        )::numeric AS median_resolution_hours,

        PERCENTILE_CONT(0.9) WITHIN GROUP (
            ORDER BY resolution_hours
        )::numeric AS p90_resolution_hours,

        PERCENTILE_CONT(0.95) WITHIN GROUP (
            ORDER BY resolution_hours
        )::numeric AS p95_resolution_hours

    FROM {{ ref('int_complaints_flagged') }}
    WHERE closed_at IS NOT NULL
      AND created_at IS NOT NULL
      AND is_invalid_time_order = 0
    GROUP BY closed_at::date
)

SELECT
    c.metric_date,

    c.created_count,

    COALESCE(cl.closed_count, 0) AS closed_count,

    c.created_count - COALESCE(cl.closed_count, 0) AS daily_net_case_flow,

    cl.avg_resolution_hours,
    cl.median_resolution_hours,
    cl.p90_resolution_hours,
    cl.p95_resolution_hours,

    c.created_morning_count,
    c.created_afternoon_count,
    c.created_evening_count,
    c.created_overnight_count,

    c.invalid_time_order_count,
    c.missing_critical_fields_count,
    c.missing_location_id_count,
    c.missing_complaint_type_id_count,
    c.missing_agency_id_count,
    c.missing_status_id_count,
    c.closed_at_status_mismatch_count

FROM created_by_day c
LEFT JOIN closed_by_day cl
    ON c.metric_date = cl.metric_date