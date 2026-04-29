WITH borough_totals AS (
    SELECT
        COALESCE(NULLIF(TRIM(l.borough), ''), 'UNSPECIFIED') AS borough,
        COUNT(*) AS borough_total
    FROM fact_311_complaint f
    JOIN dim_location l
      ON f.location_id = l.location_id
    GROUP BY COALESCE(NULLIF(TRIM(l.borough), ''), 'UNSPECIFIED')
)
SELECT
    COALESCE(NULLIF(TRIM(l.borough), ''), 'UNSPECIFIED') AS borough,
    c.complaint_type,
    COUNT(*) AS num_requests,
    ROUND(
        (COUNT(*)::numeric / bt.borough_total::numeric) * 100,
        2
    ) AS pct_of_borough_requests
FROM fact_311_complaint f
JOIN dim_location l
  ON f.location_id = l.location_id
JOIN dim_complaint_type c
  ON f.complaint_type_id = c.complaint_type_id
JOIN borough_totals bt
  ON COALESCE(NULLIF(TRIM(l.borough), ''), 'UNSPECIFIED') = bt.borough
GROUP BY
    COALESCE(NULLIF(TRIM(l.borough), ''), 'UNSPECIFIED'),
    c.complaint_type,
    bt.borough_total
HAVING COUNT(*) >= 10
ORDER BY borough, pct_of_borough_requests DESC, c.complaint_type;