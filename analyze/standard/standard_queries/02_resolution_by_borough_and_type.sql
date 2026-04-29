WITH complaint_times AS (
    SELECT
        COALESCE(NULLIF(TRIM(l.borough), ''), 'UNSPECIFIED') AS borough,
        c.complaint_type,
        EXTRACT(EPOCH FROM (f.closed_at - f.created_at)) / 3600.0 AS resolution_hours
    FROM fact_311_complaint f
    JOIN dim_location l
      ON f.location_id = l.location_id
    JOIN dim_complaint_type c
      ON f.complaint_type_id = c.complaint_type_id
    WHERE f.created_at IS NOT NULL
      AND f.closed_at IS NOT NULL
      AND f.closed_at >= f.created_at
)
SELECT
    borough,
    complaint_type,
    COUNT(*) AS num_requests,
    ROUND(AVG(resolution_hours)::numeric, 2) AS avg_resolution_hours,
    ROUND(
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY resolution_hours)::numeric,
        2
    ) AS median_resolution_hours
FROM complaint_times
GROUP BY borough, complaint_type
HAVING COUNT(*) >= 10
ORDER BY avg_resolution_hours DESC;