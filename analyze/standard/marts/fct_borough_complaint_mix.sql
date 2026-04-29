DROP TABLE IF EXISTS fct_borough_complaint_mix;

CREATE TABLE fct_borough_complaint_mix AS
WITH base AS (
    SELECT
        i.created_at,
        COALESCE(NULLIF(TRIM(l.borough), ''), 'UNSPECIFIED') AS borough,
        COALESCE(c.complaint_type, 'UNSPECIFIED') AS complaint_type
    FROM int_complaints_flagged i
    LEFT JOIN dim_location l
        ON i.location_id = l.location_id
    LEFT JOIN dim_complaint_type c
        ON i.complaint_type_id = c.complaint_type_id
    WHERE i.created_at IS NOT NULL
)

SELECT
    MIN(created_at)::date AS min_created_date,
    MAX(created_at)::date AS max_created_date,

    borough,
    complaint_type,

    COUNT(*) AS total_requests,

    ROUND(
        COUNT(*)::numeric
        / SUM(COUNT(*)) OVER (PARTITION BY borough) * 100,
        2
    ) AS pct_of_borough_requests,

    ROUND(
        COUNT(*)::numeric
        / SUM(COUNT(*)) OVER () * 100,
        2
    ) AS pct_of_all_requests

FROM base
GROUP BY
    borough,
    complaint_type
ORDER BY total_requests DESC;

CREATE INDEX IF NOT EXISTS idx_fct_complaint_mix_borough
    ON fct_borough_complaint_mix(borough);

CREATE INDEX IF NOT EXISTS idx_fct_complaint_mix_complaint_type
    ON fct_borough_complaint_mix(complaint_type);