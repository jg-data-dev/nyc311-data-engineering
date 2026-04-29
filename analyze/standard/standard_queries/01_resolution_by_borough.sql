WITH complaint_times AS (
    SELECT
        COALESCE(NULLIF(TRIM(l.borough), ''), 'UNSPECIFIED') AS borough,
        EXTRACT(EPOCH FROM (f.closed_at - f.created_at)) / 3600.0 AS resolution_hours
    FROM fact_311_complaint f
    JOIN dim_location l
      ON f.location_id = l.location_id
    WHERE f.created_at IS NOT NULL
      AND f.closed_at IS NOT NULL
      AND f.closed_at >= f.created_at
)
SELECT
    borough,
    COUNT(*) AS num_requests,
    ROUND(AVG(resolution_hours)::numeric, 2) AS avg_resolution_hours,
    ROUND(
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY resolution_hours)::numeric,
        2
    ) AS median_resolution_hours,
    ROUND(MIN(resolution_hours)::numeric, 2) AS min_resolution_hours,
    ROUND(MAX(resolution_hours)::numeric, 2) AS max_resolution_hours
FROM complaint_times
GROUP BY borough
ORDER BY avg_resolution_hours DESC;
