-- int_complaints_flagged.sql

DROP TABLE IF EXISTS int_complaints_flagged;

CREATE TABLE int_complaints_flagged AS
SELECT
    f.complaint_key,
    f.unique_key,

    f.created_at,
    f.closed_at,

    -- optional but useful downstream
    DATE(f.created_at) AS metric_date,
    DATE_TRUNC('month', f.created_at)::date AS metric_month,

    f.location_id,
    f.complaint_type_id,
    f.agency_id,
    f.status_id,

    -- resolution metric (may be NULL if closed_at is NULL)
    EXTRACT(EPOCH FROM (f.closed_at - f.created_at)) / 3600.0
        AS resolution_hours,

    -- ===== data quality flags =====

    -- invalid time order
    CASE
        WHEN f.closed_at IS NOT NULL
         AND f.created_at IS NOT NULL
         AND f.closed_at < f.created_at
        THEN 1 ELSE 0
    END AS is_invalid_time_order,

    -- missing dimensions
    CASE WHEN f.location_id IS NULL THEN 1 ELSE 0 END AS is_missing_location_id,
    CASE WHEN f.complaint_type_id IS NULL THEN 1 ELSE 0 END AS is_missing_complaint_type_id,
    CASE WHEN f.agency_id IS NULL THEN 1 ELSE 0 END AS is_missing_agency_id,
    CASE WHEN f.status_id IS NULL THEN 1 ELSE 0 END AS is_missing_status_id,

    -- combined critical fields
    CASE
        WHEN f.location_id IS NULL
          OR f.complaint_type_id IS NULL
          OR f.agency_id IS NULL
          OR f.status_id IS NULL
        THEN 1 ELSE 0
    END AS is_missing_critical_fields,

    -- status mismatch: closed_at exists but status not CLOSED
    CASE
        WHEN f.closed_at IS NOT NULL
         AND f.created_at IS NOT NULL
         AND f.closed_at >= f.created_at
         AND s.status <> 'CLOSED'
        THEN 1 ELSE 0
    END AS is_closed_at_status_mismatch

FROM fact_311_complaint f
LEFT JOIN dim_status s
  ON f.status_id = s.status_id;